"""LLVM IR back end (textual IR, opaque pointers: LLVM 15 or newer).

How a bforth program maps onto IR
---------------------------------
* The value stack of every function is a byte array (`%stk`, an alloca).  The
  depth of the stack is known statically at every point (the front end already
  tracks it), so a push or a pop is just a load / store at a constant offset:
  there is no run-time stack pointer.
* Local variables, struct instances and spilled parameters live in a second
  alloca (`%frame`).  `Var.disp` is the same negative offset the x86 back ends use,
  taken from `%fp` (the end of the frame).
* Every value is an `i64` in SSA form while an operation works on it.  In the
  default mode a stack slot always holds a canonical, zero-extended 8-byte value;
  with --no-safe-slot a value is stored with its real width.
* Operations narrower than 64 bits are done at 32 bits (like the x86 back ends)
  and truncated again, so results are bit-for-bit the same on every back end.
* bforth functions take and return `i64`.  A variadic bforth function gets two
  extra arguments after its named ones: the number of extra arguments and a pointer
  to an array of 8-byte slots that the caller builds in its own frame.
* Externs are declared with `i64` parameters (pointers travel as integers) and the
  return width given by `extern int ...`, `extern sized 32 ...`; C variadics use `...`.
* The --no-safe-slot run-time guard is an x86 feature; here only the compile-time
  warnings exist.

Use `clang prog.ll -o prog` (or `llc` + a linker) to build the output.
"""
from codegen.base import CodegenBase, Var
from frontend import OP, error, warning

MASK64 = (1 << 64) - 1


def c_int(value: int, bits: int) -> int:
    """An integer constant in the signed form LLVM always accepts."""
    value &= (1 << bits) - 1
    return value - (1 << bits) if value >= (1 << (bits - 1)) else value


def ity(size: int) -> str:
    return f"i{8 * size}"


def llvm_bytes(data: bytes) -> str:
    out = []

    for byte in data:
        if 32 <= byte < 127 and byte not in (34, 92):
            out.append(chr(byte))
        else:
            out.append(f"\\{byte:02X}")

    return "".join(out)


ARITH = {
    OP.ADD: "add", OP.SUB: "sub", OP.MUL: "mul",
    OP.AND: "and", OP.OR: "or", OP.XOR: "xor",
}

PRED = {  # op -> (unsigned predicate, signed predicate)
    OP.EQ: ("eq", "eq"), OP.NE: ("ne", "ne"),
    OP.LT: ("ult", "slt"), OP.GT: ("ugt", "sgt"),
    OP.LE: ("ule", "sle"), OP.GE: ("uge", "sge"),
}


class LLVMCodegen(CodegenBase):
    def __init__(self, funcs, extern_vars, extern_funcs, structs, typedefs, comments=False, safe=True):
        super().__init__(funcs, extern_vars, extern_funcs, structs, typedefs, comments, safe)
        self.temps = 0
        self.max_stack = 0
        self.entry_allocas: list[str] = []
        self.globals: list[str] = []
        self.functions: list[str] = []
        self.strings = 0
        self.dead = 0
        self.ret_ty = "i64"
        self.fn_label = ""

    # ------------------------------------------------------------ emission helpers

    def tmp(self) -> str:
        self.temps += 1
        return f"%t{self.temps}"

    def e(self, text: str):
        self.lines.append("  " + text)

    def label(self, name: str):
        self.lines.append(f"{name}:")

    def comment_line(self, text: str):
        self.lines.append(f"  ; {text}")

    def gep(self, base: str, offset) -> str:
        t = self.tmp()
        self.e(f"{t} = getelementptr inbounds i8, ptr {base}, i64 {offset}")
        return t

    def stk(self, offset: int) -> str:
        return self.gep("%stk", offset)

    def var_ptr(self, disp: int) -> str:
        return self.gep("%fp", disp)

    def load(self, ty: str, ptr: str) -> str:
        t = self.tmp()
        self.e(f"{t} = load {ty}, ptr {ptr}, align 1")
        return t

    def store(self, ty: str, value, ptr: str):
        self.e(f"store {ty} {value}, ptr {ptr}, align 1")

    def conv(self, kind: str, value, frm: int, to: int) -> str:
        t = self.tmp()
        self.e(f"{t} = {kind} i{frm} {value} to i{to}")
        return t

    def to_bits(self, value, bits: int) -> str:
        """i64 -> iN (truncate)."""
        return value if bits == 64 else self.conv("trunc", value, 64, bits)

    def i2p(self, value) -> str:
        t = self.tmp()
        self.e(f"{t} = inttoptr i64 {value} to ptr")
        return t

    def p2i(self, ptr: str) -> str:
        t = self.tmp()
        self.e(f"{t} = ptrtoint ptr {ptr} to i64")
        return t

    def binop(self, name: str, ty: str, a, b) -> str:
        t = self.tmp()
        self.e(f"{t} = {name} {ty} {a}, {b}")
        return t

    def icmp(self, pred: str, ty: str, a, b) -> str:
        t = self.tmp()
        self.e(f"{t} = icmp {pred} {ty} {a}, {b}")
        return t

    def canon(self, value, bits: int) -> str:
        """iN -> canonical (zero-extended) i64."""
        return value if bits == 64 else self.conv("zext", value, bits, 64)

    # ------------------------------------------------------------ the value stack

    def push_val(self, value, size: int):
        """Push an i64 (SSA name or Python int); stored with its width in unsafe mode."""
        slot = self.slot(size)
        addr = self.stk(self.stack_size)

        if self.safe or size == 8:
            if isinstance(value, int):
                value = c_int(value, 64)

            self.store("i64", value, addr)
        else:
            bits = size * 8

            if isinstance(value, int):
                self.store(ity(size), c_int(value, bits), addr)
            else:
                self.store(ity(size), self.to_bits(value, bits), addr)

        self.stack_size += slot
        self.max_stack = max(self.max_stack, self.stack_size)

    def pop_val(self, size: int) -> str:
        """Pop a value; the result is a zero-extended i64."""
        slot = self.slot(size)
        self.need(slot)
        self.stack_size -= slot
        addr = self.stk(self.stack_size)

        if self.safe or size == 8:
            return self.load("i64", addr)

        return self.canon(self.load(ity(size), addr), size * 8)

    def raw_load(self, offset: int, slot: int) -> str:
        return self.load(ity(slot), self.stk(offset))

    def raw_store(self, offset: int, slot: int, value):
        self.store(ity(slot), value, self.stk(offset))

    # ------------------------------------------------------------ width helpers

    @staticmethod
    def work_bits(size: int) -> int:
        return 64 if size == 8 else 32

    def to_work(self, value, size: int, signed: bool) -> str:
        """canonical i64 holding a `size`-byte value -> iW (W = 32 or 64), extended."""
        w = self.work_bits(size)

        if size == 8:
            return value

        narrow = self.to_bits(value, size * 8)

        if size * 8 == w:
            return narrow

        return self.conv("sext" if signed else "zext", narrow, size * 8, w)

    def from_work(self, value, size: int) -> str:
        """iW result -> canonical i64 of `size` bytes."""
        w = self.work_bits(size)

        if size == 8:
            return value

        narrow = value if size * 8 == w else self.conv("trunc", value, w, size * 8)
        return self.canon(narrow, size * 8)

    # ------------------------------------------------------------ variables

    def load_var(self, name: str, size: int):
        var = self.vars[name]

        if size == 0:
            size = 8 if self.safe else var.size

        value = self.load(ity(size), self.var_ptr(var.disp))
        self.push_val(self.canon(value, size * 8), size)

    def store_var(self, name: str):
        var = self.vars[name]
        value = self.pop_val(var.size)

        if var.size != 8:
            value = self.canon(self.to_bits(value, var.size * 8), var.size * 8)

        self.store("i64", value, self.var_ptr(var.disp))

    def global_name(self, name: str) -> str:
        return f"@{name}"

    def load_external(self, name: str):
        size = self.extern_vars[name]

        if size not in (1, 2, 4, 8):
            error(f"Unsupported external variable size for '{name}'")

        value = self.load(ity(size), self.global_name(name))
        self.push_val(self.canon(value, size * 8), size)

    def store_external(self, name: str):
        size = self.extern_vars[name]
        value = self.pop_val(size)
        self.store(ity(size), self.to_bits(value, size * 8), self.global_name(name))

    # ------------------------------------------------------------ pieces shared by several ops

    def index_address(self, operand, type_name, line):
        """pop (pointer, index) -> i64 address and the type's size (None for structs)."""
        self.need(8, f"Line {line}: indexing needs a pointer on the stack")

        elem, tsize = 1, None

        if type_name is not None:
            elem, is_struct = self.type_size(type_name, line)
            tsize = None if is_struct else elem

        delta = self.eval_one([operand], "index")
        index = self.pop_val(delta)
        pointer = self.pop_val(8)

        if elem != 1:
            index = self.binop("mul", "i64", index, elem)

        return self.binop("add", "i64", pointer, index), tsize

    def struct_literal(self, struct_name: str, fields, line: int):
        struct = self.structs[struct_name]
        base = self.stack_size

        self.stack_size += struct.size
        self.max_stack = max(self.max_stack, self.stack_size)

        for off in range(0, struct.size, 8):
            self.raw_store(base + off, 8, 0)

        for field, toks, field_line in fields:
            if field not in struct.members:
                error(f"Line {field_line}: struct '{struct_name}' has no member '{field}'")

            offset, member_size = struct.members[field]

            if len(toks) == 1 and toks[0].type == OP.PUSH:
                toks = [toks[0]._replace(size=member_size)]

            delta = self.eval_one(toks, f"value of member '{field}'")
            value = self.pop_val(delta)
            self.store(ity(member_size), self.to_bits(value, member_size * 8), self.stk(base + offset))

    def array(self, token):
        elems, size = token.value, token.size
        n = len(elems)
        total = (n * size + 7) // 8 * 8
        base = self.stack_size
        sizes = []

        for element in elems:
            toks = element

            if len(element) == 1 and element[0].type == OP.PUSH:
                toks = [element[0]._replace(size=size)]

            sizes.append(self.eval_one(toks, "array element"))

        # read every element first (they are SSA values), then pack them over the temporaries
        values = []
        position = base

        for delta in sizes:
            values.append(self.load(ity(delta), self.stk(position)))
            values[-1] = self.canon(values[-1], delta * 8)
            position += delta

        self.stack_size = base + total
        self.max_stack = max(self.max_stack, self.stack_size, position)

        for off in range(0, total, 8):
            self.raw_store(base + off, 8, 0)

        for i, value in enumerate(values):
            self.store(ity(size), self.to_bits(value, size * 8), self.stk(base + i * size))

        self.push_val(self.p2i(self.stk(base)), 8)

    # ------------------------------------------------------------ walking tokens

    def block(self, tokens):
        i = 0
        outer = self.note

        while i < len(tokens):
            token = tokens[i]
            i += 1

            if token.type != OP.WORD:
                self.token(token)
                continue

            name = token.value

            if name in self.vars:
                self.header(f"push the value of variable '{name}'", token.line)
                self.load_var(name, token.size)

            elif name in self.extern_vars:
                self.header(f"push the value of extern variable '{name}'", token.line)
                self.load_external(name)

            elif name in self.extern_funcs:
                error(f"Line {token.line}: External function '{name}' must be called with parentheses")

            elif i < len(tokens) and tokens[i].type in (OP.PUSH, OP.STR, OP.ARRAY, OP.ARRAY_UNINIT, OP.CALL, OP.SIZEOF, OP.OFFSETOF, OP.ADDR, OP.FUNC_REF):
                value = tokens[i]
                i += 1
                tsize = token.size or 8

                if value.type in (OP.ARRAY, OP.ARRAY_UNINIT):
                    value_size, value = 8, value._replace(size=tsize)
                elif value.type == OP.STR:
                    value_size = 8
                else:
                    value_size, value = tsize, value._replace(size=tsize)

                self.declare(name, value_size)
                before = self.stack_size
                self.token(value)

                if self.stack_size <= before:
                    error(f"Line {token.line}: Variable '{name}' got no value")

                self.header(f"declare variable '{name}': pop the value just computed into its frame slot", token.line)
                self.store_var(name)

            else:
                error(f"Line {token.line}: Undefined word '{name}'")

        self.note = outer

    def new_block(self, prefix="B") -> str:
        self.dead += 1
        return f"{prefix}{self.dead}"

    def token(self, token):
        size, signed = token.size, token.signed
        self.header(self.describe(token), token.line)
        t = token.type

        if t == OP.PUSH:
            bits = size * 8
            value = token.value

            if value >= (1 << bits) or value < -(1 << (bits - 1)):
                error(f"Value {value} does not fit in {size} bytes.")

            self.push_val(value & ((1 << bits) - 1), size)

        elif t == OP.STR:
            data, mutable = token.value
            self.strings += 1
            name = f"@str_{self.strings}"
            body = llvm_bytes(data + b"\x00")
            kind = "global" if mutable else "private unnamed_addr constant"
            self.globals.append(f'{name} = {kind} [{len(data) + 1} x i8] c"{body}"')
            self.push_val(self.p2i(name), 8)

        elif t == OP.FUNC_REF:
            self.push_val(self.p2i(f"@fn_{token.value}"), 8)

        elif t == OP.CALL_INDIRECT:
            pointer = self.i2p(self.pop_val(8))
            result = self.tmp()
            self.e(f"{result} = call i64 {pointer}()")
            self.push_val(result, 8)

        elif t == OP.ARRAY:
            self.array(token)

        elif t == OP.ARRAY_UNINIT:
            total = (token.value * token.size + 7) // 8 * 8
            base = self.stack_size
            self.stack_size += total
            self.max_stack = max(self.max_stack, self.stack_size)
            self.push_val(self.p2i(self.stk(base)), 8)

        elif t in (OP.ROT, OP.ANTIROT):
            count = token.value
            slot = self.slot(size)
            self.need(count * slot, f"{t.name.lower()} needs {count} stack values")
            base = self.stack_size - count * slot
            values = [self.raw_load(base + i * slot, slot) for i in range(count)]
            if t == OP.ROT and count == 3:
                order = [2, 1, 0]
            elif t == OP.ROT:
                order = [*range(1, count), 0]
            else:
                order = [count - 1, *range(count - 1)]
            for i, source in enumerate(order):
                self.raw_store(base + i * slot, slot, values[source])

        elif t in ARITH or t in (OP.DIV, OP.MOD, OP.SHL, OP.SHR):
            self.arith(t, size, signed)

        elif t in (OP.NOT, OP.NEG):
            a = self.pop_val(size)
            bits = size * 8
            narrow = self.to_bits(a, bits)
            r = self.binop("xor", ity(size), narrow, -1) if t == OP.NOT else self.binop("sub", ity(size), 0, narrow)
            self.push_val(self.canon(r, bits), size)

        elif t in PRED:
            b = self.pop_val(size)
            a = self.pop_val(size)
            bits = size * 8
            pred = PRED[t][1 if signed else 0]
            c = self.icmp(pred, ity(size), self.to_bits(a, bits), self.to_bits(b, bits))
            self.push_val(self.conv("zext", c, 1, 64), size)

        elif t == OP.DUP:
            slot = self.slot(size)
            self.need(slot)
            value = self.raw_load(self.stack_size - slot, slot)
            self.raw_store(self.stack_size, slot, value)
            self.stack_size += slot
            self.max_stack = max(self.max_stack, self.stack_size)

        elif t == OP.DROP:
            slot = self.slot(size)
            self.need(slot)
            self.stack_size -= slot

        elif t == OP.SWAP:
            slot = self.slot(size)
            self.need(2 * slot)
            top = self.raw_load(self.stack_size - slot, slot)
            second = self.raw_load(self.stack_size - 2 * slot, slot)
            self.raw_store(self.stack_size - slot, slot, second)
            self.raw_store(self.stack_size - 2 * slot, slot, top)

        elif t == OP.NIP:
            slot = self.slot(size)
            self.need(2 * slot)
            top = self.raw_load(self.stack_size - slot, slot)
            self.raw_store(self.stack_size - 2 * slot, slot, top)
            self.stack_size -= slot

        elif t == OP.OVER:
            slot = self.slot(size)
            self.need(2 * slot)
            second = self.raw_load(self.stack_size - 2 * slot, slot)
            self.raw_store(self.stack_size, slot, second)
            self.stack_size += slot
            self.max_stack = max(self.max_stack, self.stack_size)

        elif t in (OP.DUMP, OP.DUMPC, OP.DUMPS):
            self.dump(t, size, signed)

        elif t == OP.WRITE:
            value = self.pop_val(size)
            pointer = self.i2p(self.pop_val(8))
            self.store(ity(size), self.to_bits(value, size * 8), pointer)

        elif t == OP.READ:
            pointer = self.i2p(self.pop_val(8))
            value = self.load(ity(size), pointer)
            self.push_val(self.canon(value, size * 8), size)

        elif t == OP.SET:
            if token.value in self.vars:
                self.store_var(token.value)
            elif token.value in self.extern_vars:
                self.store_external(token.value)
            else:
                error(f"Line {token.line}: Undefined variable '{token.value}'")

        elif t == OP.WHILE:
            self.while_loop(token)

        elif t == OP.IF:
            self.if_chain(token)

        elif t == OP.CALL:
            self.call(token)

        elif t == OP.RET:
            value = self.pop_val(size)

            if self.ret_ty == "i32":
                value = self.to_bits(value, 32)

            self.e(f"ret {self.ret_ty} {value}")
            self.label(self.new_block("after_ret"))

        elif t in (OP.DOT, OP.ARROW, OP.DOT_SET, OP.ARROW_SET, OP.DEREF, OP.STORE):
            self.struct_op(token)

        elif t == OP.STRUCT_LIT:
            struct_name, fields = token.value
            self.struct_literal(struct_name, fields, token.line)

        elif t == OP.STRUCT_DECL:
            self.struct_decl(token)

        elif t == OP.SIZEOF:
            name = token.value

            if name in self.structs:
                value = self.structs[name].size
            elif name in self.typedefs:
                value = self.typedefs[name].size
            else:
                error(f"Line {token.line}: unknown struct or typedef '{name}'")

            self.push_val(value, 8)

        elif t == OP.OFFSETOF:
            member, struct_name = token.value
            struct = self.resolve(member, struct_name, token.line)
            self.push_val(struct.members[member][0], 8)

        elif t == OP.ADDR:
            name = token.value

            if name in self.vars:
                self.push_val(self.p2i(self.var_ptr(self.vars[name].disp)), 8)
            elif name in self.extern_vars:
                self.push_val(self.p2i(self.global_name(name)), 8)
            else:
                error(f"Line {token.line}: Undefined variable '{name}'")

        elif t == OP.ADDROF:
            slot = self.slot(token.size)
            self.need(slot)
            self.push_val(self.p2i(self.stk(self.stack_size - slot)), 8)

        elif t in (OP.INDEX, OP.INDEX_ADDR):
            operand, type_name = token.value
            address, tsize = self.index_address(operand, type_name, token.line)

            if t == OP.INDEX_ADDR:
                self.push_val(address, 8)
            else:
                if type_name is not None and tsize is None:
                    error(
                        f"Line {token.line}: [i: {type_name}] cannot read a whole struct; "
                        f"use &[i: {type_name}] to get its address"
                    )

                read_size = tsize if tsize is not None else size
                value = self.load(ity(read_size), self.i2p(address))
                self.push_val(self.canon(value, read_size * 8), read_size)

        elif t == OP.INDEX_SET:
            operand, type_name, value_token = token.value
            address, tsize = self.index_address(operand, type_name, token.line)

            if type_name is not None and tsize is None:
                error(f"Line {token.line}: [i: {type_name}]= cannot assign a whole struct; use write as / ->= instead")

            write_size = tsize if tsize is not None else size
            delta = self.eval_one([value_token], "value of an index assignment")
            value = self.pop_val(delta)
            self.store(ity(write_size), self.to_bits(value, write_size * 8), self.i2p(address))

        else:
            error(f"Unhandled op {t!r}")

    # ------------------------------------------------------------ operators

    def arith(self, op, size: int, signed: bool):
        b = self.pop_val(size)
        a = self.pop_val(size)
        w = self.work_bits(size)
        ty = f"i{w}"

        if op in ARITH:
            r = self.binop(ARITH[op], ty, self.to_work(a, size, signed), self.to_work(b, size, signed))
        elif op in (OP.DIV, OP.MOD):
            name = {(OP.DIV, True): "sdiv", (OP.DIV, False): "udiv", (OP.MOD, True): "srem", (OP.MOD, False): "urem"}[(op, signed)]
            r = self.binop(name, ty, self.to_work(a, size, signed), self.to_work(b, size, signed))
        else:
            count = self.binop("and", ty, self.to_bits(b, w), w - 1)

            if op == OP.SHL:
                r = self.binop("shl", ty, self.to_work(a, size, False), count)
            elif signed:
                r = self.binop("ashr", ty, self.to_work(a, size, True), count)
            else:
                r = self.binop("lshr", ty, self.to_work(a, size, False), count)

        self.push_val(self.from_work(r, size), size)

    def dump(self, op, size: int, signed: bool):
        if op == OP.DUMP:
            fmt, vsize = ("fmt_lld" if signed else "fmt_llu"), size
        elif op == OP.DUMPC:
            fmt, vsize, signed = "fmt_c", 1, False
        else:
            fmt, vsize, signed = "fmt_s", 8, False

        value = self.pop_val(vsize)

        if signed and vsize != 8:
            narrow = self.to_bits(value, vsize * 8)
            value = self.conv("sext", narrow, vsize * 8, 64)

        self.declare_extern_raw("printf", "i32", 1, True)
        t = self.tmp()
        self.e(f"{t} = call i32 (i64, ...) @printf(i64 {self.fmt_ptr(fmt)}, i64 {value})")

    def fmt_ptr(self, name: str) -> str:
        return self.p2i(f"@{name}")

    # ------------------------------------------------------------ control flow

    def while_loop(self, token):
        condition, body = token.value
        size = token.size
        top, ok, end = self.new_block("while_top"), self.new_block("while_body"), self.new_block("while_end")
        depth = self.stack_size

        self.e(f"br label %{top}")
        self.label(top)
        self.block(condition)
        self.check(depth + self.slot(size), "while condition must leave exactly one value")

        value = self.pop_val(size)
        flag = self.icmp("ne", ity(size), self.to_bits(value, size * 8), 0)
        self.e(f"br i1 {flag}, label %{ok}, label %{end}")

        self.label(ok)
        self.block(body)
        self.check(depth, "while body must leave the stack unchanged")
        self.e(f"br label %{top}")
        self.label(end)

    def if_chain(self, token):
        end = self.new_block("if_end")
        depth = self.stack_size
        branches = token.value

        for index, (condition, condition_size, body) in enumerate(branches):
            if condition is not None:
                then, other = self.new_block("then"), self.new_block("else")

                self.block(condition)
                self.check(depth + self.slot(condition_size), "if/elif condition must leave exactly one value")

                value = self.pop_val(condition_size)
                flag = self.icmp("ne", ity(condition_size), self.to_bits(value, condition_size * 8), 0)
                self.e(f"br i1 {flag}, label %{then}, label %{other}")
                self.label(then)
            else:
                other = None

            self.block(body)
            self.check(depth, "if/elif/else branch must leave the stack unchanged")
            self.e(f"br label %{end}")

            if other is not None:
                self.label(other)

        if branches[-1][0] is not None:
            # no `else`: the block that follows the last failed condition continues after the chain
            self.e(f"br label %{end}")

        self.label(end)

    # ------------------------------------------------------------ calls

    def declare_extern_raw(self, name, ret, nfixed, variadic):
        params = ", ".join(["i64"] * nfixed + (["..."] if variadic else []))
        self.decls.setdefault(name, f"declare {ret} @{name}({params})")

    def call(self, token):
        name, args = token.value
        function = self.funcs.get(name)
        external = False

        if function is None:
            function = self.extern_funcs.get(name)
            external = function is not None

        if function is None:
            error(f"Line {token.line}: Call to undefined function '{name}'")

        nparams = len(function.params)

        if function.variadic:
            if len(args) < nparams:
                error(f"Line {token.line}: {name}() takes at least {nparams} argument(s), got {len(args)}")
        elif len(args) != nparams:
            error(f"Line {token.line}: {name}() takes {nparams} argument(s), got {len(args)}")

        sizes = [self.eval_one(argument, f"argument {i + 1} of {name}()") for i, argument in enumerate(args)]
        values = [None] * len(args)

        for i in reversed(range(len(args))):
            values[i] = self.pop_val(sizes[i])

        hidden = function.variadic and not external

        if external:
            ret = {1: "i8", 2: "i16", 4: "i32", 8: "i64"}[function.ret_size] if function.returns else "void"
            self.declare_extern_raw(name, ret, nparams, function.variadic)
            fixed = ", ".join(f"i64 {v}" for v in values)
            callee = f"{ret} (" + ", ".join(["i64"] * nparams + ["..."]) + f") @{name}" if function.variadic else f"{ret} @{name}"
            result = self.tmp()

            if function.returns:
                self.e(f"{result} = call {callee}({fixed})")
                value = self.canon(result, function.ret_size * 8)
                self.push_val(value, function.ret_size)
            else:
                self.e(f"call {callee}({fixed})")

            return

        call_args = [f"i64 {v}" for v in values[:nparams]]

        if hidden:
            extras = values[nparams:]
            array = self.tmp()
            self.entry_allocas.append(f"{array} = alloca [{max(len(extras), 1)} x i64], align 16")

            for i, extra in enumerate(extras):
                self.store("i64", extra, self.gep(array, 8 * i))

            call_args += [f"i64 {len(extras)}", f"i64 {self.p2i(array)}"]

        result = self.tmp()
        self.e(f"{result} = call i64 @fn_{name}({', '.join(call_args)})")

        if function.returns:
            self.push_val(result if self.safe else result, function.ret_size if not self.safe else 8)

    # ------------------------------------------------------------ structs

    def struct_decl(self, token):
        name, struct_name, fields = token.value
        struct = self.structs[struct_name]

        if name in self.vars:
            self.load_var(name, 8)
            self.struct_literal(struct_name, fields, token.line)
            return

        if name in self.extern_vars or name in self.extern_funcs:
            error(f"Line {token.line}: '{name}' is declared extern")

        storage = self.alloc_frame(struct.size)
        var = self.declare(name, 8, struct_name, 8, storage)

        for off in range(0, struct.size, 8):
            self.store("i64", 0, self.var_ptr(storage + off))

        self.store("i64", self.p2i(self.var_ptr(storage)), self.var_ptr(var.disp))

        for field, toks, field_line in fields:
            if field not in struct.members:
                error(f"Line {field_line}: struct '{struct_name}' has no member '{field}'")

            offset, member_size = struct.members[field]

            if len(toks) == 1 and toks[0].type == OP.PUSH:
                toks = [toks[0]._replace(size=member_size)]

            delta = self.eval_one(toks, f"value of member '{field}'")
            value = self.pop_val(delta)
            self.store(ity(member_size), self.to_bits(value, member_size * 8), self.var_ptr(storage + offset))

    def struct_op(self, token):
        t = token.type

        if t == OP.DEREF:
            struct = self.structs[token.value]
            pointer = self.pop_val(8)
            base = self.stack_size

            for off in range(0, struct.size, 8):
                addr = self.binop("add", "i64", pointer, off)
                self.raw_store(base + off, 8, self.load("i64", self.i2p(addr)))

            self.stack_size += struct.size
            self.max_stack = max(self.max_stack, self.stack_size)
            return

        if t == OP.STORE:
            struct = self.structs[token.value]
            self.need(
                struct.size + 8,
                f"Line {token.line}: 'write as {struct.name}' needs a pointer below the struct bytes",
            )
            start = self.stack_size - struct.size
            pointer = self.raw_load(start - 8, 8)

            for off in range(0, struct.size, 8):
                addr = self.binop("add", "i64", pointer, off)
                self.store("i64", self.raw_load(start + off, 8), self.i2p(addr))

            self.stack_size -= struct.size + 8
            return

        member, struct_name = token.value
        struct = self.resolve(member, struct_name, token.line)
        offset, member_size = struct.members[member]

        if t == OP.DOT:
            self.need(struct.size, f"Line {token.line}: '. {member}' needs a {struct.name} ({struct.size} bytes) on the stack")
            value = self.load(ity(member_size), self.stk(self.stack_size - struct.size + offset))
            self.push_val(self.canon(value, member_size * 8), member_size)

        elif t == OP.ARROW:
            self.need(8, f"Line {token.line}: '-> {member}' needs a struct pointer")
            pointer = self.raw_load(self.stack_size - 8, 8)
            addr = self.binop("add", "i64", pointer, offset)
            value = self.load(ity(member_size), self.i2p(addr))
            self.push_val(self.canon(value, member_size * 8), member_size)

        elif t == OP.DOT_SET:
            vs = self.slot(member_size)
            self.need(struct.size + vs, f"Line {token.line}: '.= {member}' needs a value below a {struct.name} ({struct.size} bytes)")
            start = self.stack_size - struct.size
            value = self.raw_load(start - vs, vs)

            if vs != member_size:
                value = self.to_bits(value, member_size * 8)

            self.store(ity(member_size), value, self.stk(start + offset))

            words = [self.raw_load(start + 8 * q, 8) for q in range(struct.size // 8)]

            for q, word in enumerate(words):
                self.raw_store(start - vs + 8 * q, 8, word)

            self.stack_size -= vs

        elif t == OP.ARROW_SET:
            vs = self.slot(member_size)
            self.need(8 + vs, f"Line {token.line}: '->= {member}' needs a value below a struct pointer")
            pointer = self.raw_load(self.stack_size - 8, 8)
            value = self.raw_load(self.stack_size - 8 - vs, vs)

            if vs != member_size:
                value = self.to_bits(value, member_size * 8)

            addr = self.binop("add", "i64", pointer, offset)
            self.store(ity(member_size), value, self.i2p(addr))
            self.raw_store(self.stack_size - 8 - vs, 8, pointer)
            self.stack_size -= vs

    # ------------------------------------------------------------ functions and the module

    def describe(self, token) -> str:
        from codegen.base import describe_token
        return describe_token(token)

    def function(self, name: str, params, body, variadic=False, is_main=False):
        self.lines = []
        self.stack_size = 0
        self.vars = {}
        self.frame_bytes = 0
        self.max_stack = 0
        self.entry_allocas = []
        self.temps = 0
        self.dead = 0
        self.cur_line = 0
        self.ret_ty = "i32" if is_main else "i64"
        self.fn_label = name

        arg_names = [f"%p{i}" for i in range(len(params))]
        signature = [f"i64 {a}" for a in arg_names]

        if variadic:
            signature += ["i64 %va_count", "i64 %va_ptr"]

        if is_main:
            head = "define i32 @main() {"
        else:
            head = f"define i64 @{name}({', '.join(signature)}) {{"

        self.lines.append(head)
        self.lines.append("entry:")
        self.e("%frame = alloca [@F@ x i8], align 16")
        self.e("%stk = alloca [@S@ x i8], align 16")
        self.lines.append(";@ALLOCAS@")
        self.e("%fp = getelementptr inbounds i8, ptr %frame, i64 @F@")

        self.note = f"function entry ({name}): copy the arguments into frame slots"

        for index, (pname, psize) in enumerate(params):
            var = self.declare(pname, psize)
            value = arg_names[index]

            if psize != 8:
                value = self.canon(self.to_bits(value, psize * 8), psize * 8)

            self.store("i64", value, self.var_ptr(var.disp))

        if variadic:
            arr = self.declare("variadic_arr", 8)
            length = self.declare("variadic_len", 8)
            self.store("i64", "%va_ptr", self.var_ptr(arr.disp))
            scaled = self.binop("shl", "i64", "%va_count", 3)
            self.store("i64", scaled, self.var_ptr(length.disp))

        self.note = f"body of {name}"
        self.block(body)

        self.e(f"ret {self.ret_ty} 0")
        self.lines.append("}")

        frame = (self.frame_bytes + 15) // 16 * 16
        text = "\n".join(self.lines)
        text = text.replace(";@ALLOCAS@", "\n".join("  " + a for a in self.entry_allocas))
        text = text.replace("@F@", str(max(frame, 16))).replace("@S@", str(max(self.max_stack, 16)))
        self.functions.append(text)

    def generate(self, main_tokens) -> str:
        self.decls: dict[str, str] = {}

        for name, function in self.funcs.items():
            if function is not None:
                self.function(f"fn_{name}", function.params, function.body, function.variadic)

        self.function("main", [], main_tokens, is_main=True)

        for name, function in self.extern_funcs.items():
            ret = {1: "i8", 2: "i16", 4: "i32", 8: "i64"}[function.ret_size] if function.returns else "void"
            self.declare_extern_raw(name, ret, len(function.params), function.variadic)

        out = ["; generated by bforth (LLVM back end): needs LLVM 15 or newer (opaque pointers)", ""]

        for fmt, text in (("fmt_llu", "%llu\n"), ("fmt_lld", "%lld\n"), ("fmt_c", "%c"), ("fmt_s", "%s\n")):
            data = text.encode() + b"\x00"
            out.append(f'@{fmt} = private unnamed_addr constant [{len(data)} x i8] c"{llvm_bytes(data)}"')

        out += self.globals
        out.append("")

        for name, size in self.extern_vars.items():
            out.append(f"@{name} = external global {ity(size)}")

        out += list(self.decls.values())
        out.append("")
        out += self.functions
        return "\n".join(out) + "\n"
