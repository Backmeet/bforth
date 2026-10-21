"""Shared x86-64 / back-end machinery for the bforth code generators.

CodegenBase  - target independent: static stack tracking, --no-safe-slot warnings,
               struct / typedef lookups, frame variables.  The LLVM back end derives
               from this.
Codegen      - complete x86-64 NASM generator.  codegen/win.py and codegen/linux.py
               derive from it and only supply the calling convention, how externals
               are reached and the object format.
"""
import re
import sys
from enum import IntEnum
from typing import NamedTuple

from frontend import (
    OP, Token, Mods, FuncDef, ExternFunc, StructDef,
    enum, error, warning,
)


class Var(NamedTuple):
    disp: int            # displacement from rbp (negative = local, positive = stack/shadow arg)
    size: int            # element size in bytes (for scalars)
    struct: str | None   # struct name if this variable points at a struct instance
    nbytes: int          # bytes of storage
    storage: int | None = None  # struct instances: rbp displacement of the backing bytes



class REGISTOR(IntEnum):
    RAX = enum(True); EAX = enum(); AX = enum(); AL = enum(); AH = enum()
    RBX = enum(); EBX = enum(); BX = enum(); BL = enum(); BH = enum()
    RCX = enum(); ECX = enum(); CX = enum(); CL = enum(); CH = enum()
    RDX = enum(); EDX = enum(); DX = enum(); DL = enum(); DH = enum()
    RSI = enum(); ESI = enum(); SI = enum(); SIL = enum()
    RDI = enum(); EDI = enum(); DI = enum(); DIL = enum()
    RBP = enum(); EBP = enum(); BP = enum(); BPL = enum()
    RSP = enum(); ESP = enum(); SP = enum(); SPL = enum()
    R8 = enum(); R8D = enum(); R8W = enum(); R8B = enum()
    R9 = enum(); R9D = enum(); R9W = enum(); R9B = enum()
    R10 = enum(); R10D = enum(); R10W = enum(); R10B = enum()
    R11 = enum(); R11D = enum(); R11W = enum(); R11B = enum()
    R12 = enum(); R12D = enum(); R12W = enum(); R12B = enum()
    R13 = enum(); R13D = enum(); R13W = enum(); R13B = enum()
    R14 = enum(); R14D = enum(); R14W = enum(); R14B = enum()
    R15 = enum(); R15D = enum(); R15W = enum(); R15B = enum()


REGISTOR_GROUPS = [
    ("RAX", "EAX", "AX", "AL", "AH"),
    ("RBX", "EBX", "BX", "BL", "BH"),
    ("RCX", "ECX", "CX", "CL", "CH"),
    ("RDX", "EDX", "DX", "DL", "DH"),
    ("RSI", "ESI", "SI", "SIL"),
    ("RDI", "EDI", "DI", "DIL"),
    ("RBP", "EBP", "BP", "BPL"),
    ("RSP", "ESP", "SP", "SPL"),
    ("R8", "R8D", "R8W", "R8B"),
    ("R9", "R9D", "R9W", "R9B"),
    ("R10", "R10D", "R10W", "R10B"),
    ("R11", "R11D", "R11W", "R11B"),
    ("R12", "R12D", "R12W", "R12B"),
    ("R13", "R13D", "R13W", "R13B"),
    ("R14", "R14D", "R14W", "R14B"),
    ("R15", "R15D", "R15W", "R15B"),
]

REGISTOR_SIZE = {}
REGISTOR_GROUP = {}

for _group in REGISTOR_GROUPS:
    _sizes = (8, 4, 2, 1, 1) if len(_group) == 5 else (8, 4, 2, 1)
    for _name, _size in zip(_group, _sizes):
        _reg = REGISTOR[_name]
        REGISTOR_SIZE[_reg] = _size
        REGISTOR_GROUP[_reg] = _group

StackPointer: REGISTOR = REGISTOR.RSP
FramePointer: REGISTOR = REGISTOR.RBP

NONVOLATILE = {
    "RBX", "RSI", "RDI", "RBP", "RSP",
    "R12", "R13", "R14", "R15",
}
HIGH8 = {"AH", "BH", "CH", "DH"}

USED_REGISTORS: set[REGISTOR] = set()

# group index of the register name for a given width in bytes
SIZE_IDX = {8: 0, 4: 1, 2: 2, 1: 3}
R11_NAMES = {8: "r11", 4: "r11d", 2: "r11w", 1: "r11b"}


def getFreeReg(size: int) -> REGISTOR | None:
    if size not in (1, 2, 4, 8):
        return None

    for group in REGISTOR_GROUPS:
        if group[0] in NONVOLATILE:
            continue

        if any(REGISTOR[name] in USED_REGISTORS for name in group):
            continue

        for name in reversed(group):
            if name in HIGH8:
                continue

            reg = REGISTOR[name]
            if REGISTOR_SIZE[reg] >= size:
                USED_REGISTORS.add(reg)
                return reg

    return None


def release(reg: REGISTOR):
    if reg in (StackPointer, FramePointer):
        return

    for name in REGISTOR_GROUP[reg]:
        USED_REGISTORS.discard(REGISTOR[name])


def rn(reg: REGISTOR) -> str:
    return reg.name.lower()


def rname(group, size: int) -> str:
    return group[SIZE_IDX[size]].lower()



VALUE_OPS = (OP.PUSH, OP.STR, OP.ARRAY, OP.ARRAY_UNINIT, OP.CALL, OP.SIZEOF, OP.OFFSETOF, OP.ADDR, OP.FUNC_REF)

ARITH = {
    OP.ADD: "add",
    OP.SUB: "sub",
    OP.AND: "and",
    OP.OR: "or",
    OP.XOR: "xor",
}

# op -> (unsigned condition, signed condition)
COMPARE = {
    OP.EQ: ("e", "e"),
    OP.NE: ("ne", "ne"),
    OP.LT: ("b", "l"),
    OP.GT: ("a", "g"),
    OP.LE: ("be", "le"),
    OP.GE: ("ae", "ge"),
}


# ------------------------------------------------- assembly commentary

REGNAMES = {n.lower() for g in REGISTOR_GROUPS for n in g}
SIZE_WORDS = {"qword": "8-byte", "dword": "4-byte", "word": "2-byte", "byte": "1-byte"}
CONDITIONS = {
    "e": "equal", "ne": "not equal",
    "b": "below (unsigned <)", "a": "above (unsigned >)",
    "be": "below or equal (unsigned <=)", "ae": "above or equal (unsigned >=)",
    "l": "less (signed <)", "g": "greater (signed >)",
    "le": "less or equal (signed <=)", "ge": "greater or equal (signed >=)",
}


def describe_operand(op: str) -> str:
    """Put an assembly operand into words."""
    op = op.strip()
    prefix = ""
    match = re.fullmatch(r"(qword|dword|word|byte)\s+(\[.*\])", op)

    if match:
        prefix = SIZE_WORDS[match.group(1)] + " "
        op = match.group(2)

    if not op.startswith("["):
        return op

    inner = op[1:-1].strip()

    if inner.startswith("rel "):
        return f"{prefix}global '{inner[4:].strip().lstrip('$')}'"

    inner = inner.replace(" ", "")

    if inner == "rsp":
        return f"{prefix}top of the value stack"

    if (m := re.fullmatch(r"rsp\+(\d+)", inner)):
        return f"{prefix}stack slot rsp+{m.group(1)}"

    if (m := re.fullmatch(r"rbp-@F@-(\d+)", inner)):
        return f"{prefix}the value-stack floor minus {m.group(1)} byte(s)"

    if (m := re.fullmatch(r"rbp-(\d+)", inner)):
        return f"{prefix}local slot rbp-{m.group(1)}"

    if (m := re.fullmatch(r"rbp\+(\d+)", inner)):
        return f"{prefix}argument slot rbp+{m.group(1)}"

    if (m := re.fullmatch(r"(\w+)\+(\d+)", inner)) and m.group(1) in REGNAMES:
        return f"{prefix}memory at {m.group(1)}+{m.group(2)}"

    if inner in REGNAMES:
        return f"{prefix}memory pointed to by {inner}"

    return f"{prefix}label {inner}"


def explain(text: str) -> str:
    """What a single assembly instruction does, in plain words."""
    parts = text.split(None, 1)
    op = parts[0]
    args = [a.strip() for a in parts[1].split(",")] if len(parts) > 1 else []
    d = describe_operand
    a0 = args[0] if args else ""
    a1 = args[1] if len(args) > 1 else ""

    if op == "push":
        return f"push {d(a0)} (rsp -= 8)"

    if op == "pop":
        return f"pop the stack top into {d(a0)} (rsp += 8)"

    if op == "mov":
        if a0 == "rbp" and a1 == "rsp":
            return "rbp = rsp: this function's frame pointer"
        if a0 == "rsp" and a1 == "rbp":
            return "rsp = rbp: throw away locals and temporaries"
        if a1 == "rsp":
            return f"{a0} = rsp (address of the stack top)"
        return f"copy {d(a1)} into {d(a0)}"

    if op == "movzx":
        return f"zero-extend {d(a1)} into {a0}"

    if op in ("movsx", "movsxd"):
        return f"sign-extend {d(a1)} into {a0}"

    if op == "lea":
        return f"{a0} = address of {d(a1)} (no memory is read)"

    if op in ("add", "sub"):
        if a0 == "rsp":
            if op == "add":
                return f"release {a1} byte(s) of stack (rsp += {a1})"
            return f"reserve {a1} byte(s) of stack (rsp -= {a1})"
        return f"{a0} = {a0} {'+' if op == 'add' else '-'} {d(a1)}"

    if op == "imul":
        if len(args) == 3:
            return f"{a0} = {a1} * {args[2]}"
        if len(args) == 2:
            return f"{a0} = {a0} * {a1} (low half, same for signed and unsigned)"
        return f"rdx:rax = rax * {a0} (signed)"

    if op == "mul":
        return f"rdx:rax = rax * {a0} (unsigned)"

    if op == "idiv":
        return f"rax = rdx:rax / {a0}, rdx = remainder (signed)"

    if op == "div":
        return f"rax = rdx:rax / {a0}, rdx = remainder (unsigned)"

    if op == "cqo":
        return "sign-extend rax into rdx:rax"

    if op == "cdq":
        return "sign-extend eax into edx:eax"

    if op == "xor":
        if a0 == a1:
            return f"zero {a0}"
        return f"{a0} = {a0} xor {d(a1)}"

    if op in ("and", "or"):
        return f"{a0} = {a0} {'&' if op == 'and' else '|'} {d(a1)}"

    if op == "not":
        return f"{a0} = bitwise NOT of {a0}"

    if op == "neg":
        return f"{a0} = -{a0} (two's complement)"

    if op in ("shl", "shr", "sar"):
        how = {"shl": "left", "shr": "right (zero fill)", "sar": "right (sign fill)"}[op]
        count = "the count in cl" if a1 == "cl" else a1
        return f"shift {a0} {how} by {count}"

    if op == "cmp":
        return f"compare {a0} with {a1} (only sets flags)"

    if op == "test":
        if a0 == a1:
            return f"set flags from {a0} (zero or not)"
        return f"{a0} AND {a1} (only sets flags)"

    if op.startswith("set") and op[3:] in CONDITIONS:
        return f"{a0} = 1 if '{CONDITIONS[op[3:]]}' held, else 0"

    if op == "jz":
        return f"jump to {a0} if the last result was zero"

    if op == "jmp":
        return f"jump to {a0}"

    if op == "call":
        return f"call {a0.lstrip('$')}"

    if op == "ret":
        return "return to the caller"

    return text


def sz(token) -> str:
    return f"{token.size * 8}-bit {'signed' if token.signed else 'unsigned'}"


def _binary(name, symbol):
    return lambda t: f"{name} [{sz(t)}]: pop b, pop a, push a {symbol} b"


OP_DESC = {
    OP.PUSH: lambda t: f"push the literal {t.value} [{t.size * 8}-bit]",
    OP.STR: lambda t: "push the address of a string literal",
    OP.ARRAY: lambda t: "array literal: evaluate each element, pack them in memory, push a pointer to them",
    OP.ARRAY_UNINIT: lambda t: "uninitialized array literal: reserve storage and push a pointer",
    OP.ROT: lambda t: f"rotate the top {t.value} stack values clockwise",
    OP.ANTIROT: lambda t: f"rotate the top {t.value} stack values counterclockwise",
    OP.FUNC_REF: lambda t: f"push the address of function '{t.value}'",
    OP.CALL_INDIRECT: lambda t: "call the function whose address is on top of the stack",
    OP.ADD: _binary("add", "+"),
    OP.SUB: _binary("sub", "-"),
    OP.MUL: _binary("mul", "*"),
    OP.DIV: _binary("div", "/"),
    OP.MOD: _binary("mod", "%"),
    OP.AND: _binary("and", "&"),
    OP.OR: _binary("or", "|"),
    OP.XOR: _binary("xor", "^"),
    OP.SHL: lambda t: f"shl [{sz(t)}]: pop count, pop value, push value << count",
    OP.SHR: lambda t: f"shr [{sz(t)}]: pop count, pop value, push value >> count ({'arithmetic' if t.signed else 'logical'})",
    OP.NOT: lambda t: f"not [{sz(t)}]: pop a, push ~a",
    OP.NEG: lambda t: f"neg [{sz(t)}]: pop a, push -a",
    OP.EQ: lambda t: f"eq [{sz(t)}]: pop b, pop a, push 1 if a == b else 0",
    OP.NE: lambda t: f"ne [{sz(t)}]: pop b, pop a, push 1 if a != b else 0",
    OP.LT: lambda t: f"lt [{sz(t)}]: pop b, pop a, push 1 if a < b else 0",
    OP.GT: lambda t: f"gt [{sz(t)}]: pop b, pop a, push 1 if a > b else 0",
    OP.LE: lambda t: f"le [{sz(t)}]: pop b, pop a, push 1 if a <= b else 0",
    OP.GE: lambda t: f"ge [{sz(t)}]: pop b, pop a, push 1 if a >= b else 0",
    OP.DUP: lambda t: "dup: duplicate the top value",
    OP.DROP: lambda t: "drop: discard the top value",
    OP.SWAP: lambda t: "swap: exchange the top two values",
    OP.NIP: lambda t: "nip: remove the second value, keep the top",
    OP.OVER: lambda t: "over: copy the second value onto the top",
    OP.DUMP: lambda t: f"dump [{sz(t)}]: pop a value and print it with printf",
    OP.DUMPC: lambda t: "dumpc: pop a value and print it as a character",
    OP.DUMPS: lambda t: "dumps: pop a pointer and print the C string it points to",
    OP.WRITE: lambda t: f"write [{t.size * 8}-bit]: pop value, pop pointer, store value at pointer",
    OP.READ: lambda t: f"read [{t.size * 8}-bit]: pop pointer, push the value stored there",
    OP.SET: lambda t: f"set {t.value}: pop a value into variable '{t.value}'",
    OP.WHILE: lambda t: "while loop: re-evaluate the condition, run the body while it is non-zero",
    OP.IF: lambda t: "if / elif / else chain: run the first branch whose condition is non-zero",
    OP.CALL: lambda t: f"call {t.value[0]}() with {len(t.value[1])} argument(s)",
    OP.RET: lambda t: "ret: pop the return value and leave the function",
    OP.DOT: lambda t: f"'. {t.value[0]}': the struct's bytes stay on the stack, push a copy of member '{t.value[0]}'",
    OP.ARROW: lambda t: f"'-> {t.value[0]}': the struct pointer stays on the stack, push a copy of member '{t.value[0]}'",
    OP.DOT_SET: lambda t: f"'.= {t.value[0]}': write the value below the struct bytes into member '{t.value[0]}'; the bytes stay",
    OP.ARROW_SET: lambda t: f"'->= {t.value[0]}': write the value below the pointer into member '{t.value[0]}'; the pointer stays",
    OP.DEREF: lambda t: f"read as {t.value}: pop a pointer, push the struct's bytes",
    OP.STORE: lambda t: f"write as {t.value}: copy the struct bytes on top to the pointer below them",
    OP.STRUCT_DECL: lambda t: f"declare '{t.value[0]}' as a pointer to a {t.value[1]} that lives in this function's frame",
    OP.STRUCT_LIT: lambda t: f"struct literal: push the bytes of a {t.value[0]}",
    OP.SIZEOF: lambda t: f"sizeof({t.value}): push its size in bytes",
    OP.OFFSETOF: lambda t: f"offsetof({t.value[1]}, {t.value[0]}): push the member's byte offset",
    OP.ADDR: lambda t: f"& {t.value}: push the address of variable '{t.value}'",
    OP.ADDROF: lambda t: "&: push the address of the top stack slot",
    OP.INDEX: lambda t: "[i]: pop a pointer, push the value at pointer + i * sizeof(type)",
    OP.INDEX_SET: lambda t: "[i]= v: store v at pointer + i * sizeof(type); the pointer is consumed",
    OP.INDEX_ADDR: lambda t: "&[i]: pop a pointer, push pointer + i * sizeof(type)",
}


def describe_token(token) -> str:
    fn = OP_DESC.get(token.type)
    return fn(token) if fn else token.type.name.lower()


# -------------------------------------------------------------- codegen


class CodegenBase:
    """Everything a back end shares, whatever it emits: the statically tracked
    value stack, --no-safe-slot bookkeeping, struct/typedef lookups, frame variables."""

    def __init__(self, funcs, extern_vars, extern_funcs, structs, typedefs, comments=False, safe=True):
        self.comments = comments      # annotate the output (-C)
        self.safe = safe              # False = --no-safe-slot
        self.funcs = funcs
        self.extern_vars = extern_vars
        self.extern_funcs = extern_funcs
        self.structs = structs
        self.typedefs = typedefs

        self.note = ""
        self.cur_line = 0
        self.labels = 0
        self.lines: list[str] = []
        self.stack_size = 0           # bytes currently on the value stack (static)
        self.vars: dict[str, Var] = {}
        self.frame_bytes = 0

    def runtime_guard(self, n: int):
        """--no-safe-slot: emit a run-time check that `n` bytes are on the stack."""

    def comment_line(self, text: str):
        """Emit a comment line into the instruction stream."""

    def generate(self, main_tokens) -> str:
        raise NotImplementedError

    def header(self, text: str, line: int = 0):
        """Start of a source-level operation: a comment line that also becomes
        the default 'why' of the instructions that follow."""
        self.note = text

        if line:
            self.cur_line = line

        if self.comments:
            where = f"line {line}: " if line else ""
            self.comment_line(f"---- {where}{text}")

    def new_label(self) -> str:
        self.labels += 1
        return f"L{self.labels}"

    def check(self, expected: int, message: str):
        if self.stack_size == expected:
            return

        if self.safe:
            error(
                f"{message} (stack depth is {self.stack_size // 8}, "
                f"expected {expected // 8})"
            )

        self.desync(expected, message)

    def slot(self, size: int) -> int:
        """Bytes a value of `size` bytes takes on the value stack: always a full
        8-byte slot, unless --no-safe-slot was given (then exactly `size`)."""
        return 8 if self.safe else size

    def desync(self, expected: int, message: str):
        """--no-safe-slot: the static stack tracking disagrees with what the
        program does.  Only warn, then carry on as if the stack were as expected."""
        got = self.stack_size
        diff = got - expected
        warning(
            f"Line {self.cur_line}: stack desynced: "
            f"{'+' if diff > 0 else '-'}{abs(diff)} bytes, "
            f"expected: {expected} got: {got} ({message.rstrip('.')})"
        )
        self.stack_size = expected

    def need(self, n: int, message: str = "Stack underflow."):
        """The next operation reads/pops `n` bytes from the top of the value stack.
        Safe mode: compile-time error if the tracked depth is smaller.
        --no-safe-slot: compile-time warning, plus a run-time guard."""
        if self.stack_size < n:
            if self.safe:
                error(message)

            self.desync(n, message)

        if not self.safe:
            self.runtime_guard(n)

    def eval_one(self, tokens, what: str) -> int:
        """Evaluate a token list that must leave exactly one value.  Returns
        the number of bytes that value occupies (8 unless --no-safe-slot)."""
        before = self.stack_size
        self.block(tokens)
        line = tokens[0].line if tokens else 0

        if self.safe:
            self.check(before + 8, f"Line {line}: {what} must produce exactly one 8-byte value")
            return 8

        delta = self.stack_size - before

        if delta in (1, 2, 4, 8):
            return delta

        self.cur_line = line or self.cur_line
        self.desync(before + 8, f"{what} must produce exactly one value of 1, 2, 4 or 8 bytes")
        return 8

    def declare(self, name: str, size: int, struct=None, nbytes=8, storage=None) -> Var:
        self.frame_bytes += nbytes
        var = Var(-self.frame_bytes, size, struct, nbytes, storage)
        self.vars[name] = var
        return var

    def alloc_frame(self, nbytes: int) -> int:
        """Reserve anonymous frame bytes, returns the rbp displacement."""
        self.frame_bytes += nbytes
        return -self.frame_bytes

    def resolve(self, member: str, struct_name, line: int) -> StructDef:
        if struct_name is not None:
            struct = self.structs.get(struct_name)

            if struct is None:
                error(f"Line {line}: unknown struct '{struct_name}'")

            if member not in struct.members:
                error(
                    f"Line {line}: struct '{struct_name}' "
                    f"has no member '{member}'"
                )

            return struct

        found = [s for s in self.structs.values() if member in s.members]

        if not found:
            error(f"Line {line}: no struct has a member named '{member}'")

        if len(found) > 1:
            names = ", ".join(s.name for s in found)
            error(
                f"Line {line}: member '{member}' is ambiguous "
                f"(found in: {names}); use '. {member} from <struct>'"
            )

        return found[0]

    def type_size(self, name: str, line: int):
        """-> (size in bytes, is_struct)"""
        if name in self.typedefs:
            return self.typedefs[name].size, False

        if name in self.structs:
            return self.structs[name].size, True

        error(f"Line {line}: unknown type '{name}'")


class Codegen(CodegenBase):
    """x86-64 generator that writes NASM text.  Everything that is the same on
    every x86-64 target lives here; the calling convention, the object format and
    the way externals are reached are supplied by codegen/win.py and codegen/linux.py."""

    # ---- target description (overridden by the subclasses) ----------------
    ABI_NAME = "x86-64"
    ARG_REGS: list = []              # integer argument registers, as register groups
    SHADOW = 0                       # bytes of shadow space the caller reserves
    FRAME_WHY = "reserve the outgoing arguments (+8 pad) so rsp is 16-byte aligned at the call"
    USER_VARIADIC_ON_STACK = False   # pass every argument of a bforth variadic function on the stack
    FAULT_LINE_REG = "r8d"
    RODATA = ".rodata"
    OBJECT_FORMAT = "elf64"

    def __init__(self, funcs, extern_vars, extern_funcs, structs, typedefs, comments=False, safe=True):
        super().__init__(funcs, extern_vars, extern_funcs, structs, typedefs, comments, safe)
        self.fn_label = ""
        self.fault_stubs: dict[int, str] = {}
        self.text: list[str] = []
        self.rdata: list[str] = []
        self.data: list[str] = []
        self.strings = 0
        self.ret_label = ""

    # ---- target hooks ---------------------------------------------------------

    def ext_call(self, name: str) -> str:
        """The operand of `call` for an external function."""
        return f"${name}"

    def ext_var_mem(self, name: str) -> str:
        """A memory operand for an external variable (may emit set-up code)."""
        return f"[rel ${name}]"

    def ext_var_addr(self, group, name: str):
        self.emit(f"lea {rname(group, 8)}, [rel ${name}]", why=f"address of extern variable '{name}'")

    def before_variadic_call(self):
        """Called right before `call` of a C variadic function."""

    def setup_params(self, params, variadic):
        raise NotImplementedError

    def fault_handler(self, name_label: str) -> list:
        raise NotImplementedError

    def prelude_lines(self, external_names) -> list:
        return ["bits 64", "default rel", ""] + [f"extern ${n}" for n in external_names] + ["global main", ""]

    def trailer_lines(self) -> list:
        return []

    def comment_line(self, text: str):
        self.lines.append(f"    ; {text}")

    def comment_text(self, text: str):
        if self.comments:
            self.text.append(f"; {text}")

    def fmt_line(self, text: str, why: str) -> str:
        if not self.comments:
            return "    " + text

        return f"    {text:<{self.COMMENT_COLUMN}}; {explain(text)}  -- {why}"

    def setup_variadic(self, nparams: int):
        """Every argument i of a variadic bforth function is at [rbp+16+8*i]."""
        arr = self.declare("variadic_arr", 8)
        length = self.declare("variadic_len", 8)

        self.emit(f"lea rax, [rbp+{16 + 8 * (nparams + 1)}]", why="variadic_arr = address of the first variadic argument (after the named parameters and the hidden count)")
        self.emit(f"mov {self.mem(arr.disp)}, rax", why="keep it in the local variable variadic_arr")
        self.emit(f"mov rax, [rbp+{16 + 8 * nparams}]", why="the caller passes the number of variadic arguments as a hidden argument right after the named ones")
        self.emit("shl rax, 3", why="convert the count to bytes: each variadic argument takes 8 bytes")
        self.emit(f"mov {self.mem(length.disp)}, rax", why="keep it in the local variable variadic_len")

    def canonicalise_stack_params(self, params, first):
        """Stack parameters narrower than 8 bytes: clear the garbage above them."""
        for index, (_, param_size) in enumerate(params):
            if index >= first and param_size < 8:
                disp = self.vars[params[index][0]].disp
                self.load_sized(REGISTOR_GROUPS[0], self.mem(disp), param_size)
                self.emit(f"mov {self.mem(disp)}, rax", why="stack parameter narrower than 8 bytes: store it back canonicalised (zero-extended)")

    def generate(self, main_tokens) -> str:
        for name, function in self.funcs.items():
            if function is not None:
                self.function(f"fn_{name}", function.params, function.body, function.variadic)

        self.function("main", [], main_tokens)
        return self.assemble()

    def assemble(self) -> str:
        c = self.comments
        external_names = ["printf"] + ([] if self.safe else ["exit"])
        external_names.extend(self.extern_vars)
        external_names.extend(self.extern_funcs)
        external_names = list(dict.fromkeys(external_names))

        def note(text):
            return f"    ; {text}" if c else ""

        output = [
            *self.prelude_lines(external_names),
            f"section {self.RODATA}",
            'fmt_llu db "%llu", 10, 0' + note("printf format used by dump (unsigned)"),
            'fmt_lld db "%lld", 10, 0' + note("printf format used by signed dump"),
            'fmt_c   db "%c", 0' + note("printf format used by dumpc"),
            'fmt_s   db "%s", 10, 0' + note("printf format used by dumps"),
            *(
                []
                if self.safe
                else [
                    'fmt_stack_fault db "runtime error: stack underflow in function %s (line %d): '
                    'the function popped more than it pushed and went below its own frame '
                    '(the home rbp / the stack pointer it was called with)", 10, 0'
                ]
            ),
            *self.rdata,
            "",
            "section .data",
            *self.data,
            "",
            "section .text",
            *self.text,
            *self.trailer_lines(),
        ]

        return "\n".join(output) + "\n"

    # ---- basic helpers ---------------------------------------------------

    COMMENT_COLUMN = 34

    def emit(self, text: str, why: str | None = None):
        """Emit one instruction.  The comment says what the instruction does
        (derived from the instruction itself) and why it is there."""
        if not self.comments:
            self.lines.append("    " + text)
            return

        reason = why if why is not None else self.note
        comment = explain(text)

        if reason:
            comment += f"  -- {reason}"

        self.lines.append(f"    {text:<{self.COMMENT_COLUMN}}; {comment}")

    def label(self, name: str, why: str | None = None):
        if self.comments and (why or self.note):
            self.lines.append(f"{name + ':':<{self.COMMENT_COLUMN + 4}}; {why or self.note}")
        else:
            self.lines.append(name + ":")













    def fault_label(self) -> str:
        line = self.cur_line

        if line not in self.fault_stubs:
            self.fault_stubs[line] = f"{self.fn_label}_sf{len(self.fault_stubs)}"

        return self.fault_stubs[line]

    def runtime_guard(self, n: int):
        self.floor_check(n)

    def floor_check(self, n: int):
        """Run-time guard (--no-safe-slot): the value stack of a function lives
        below its locals, between rsp and rbp-frame.  If rsp + n would reach above
        that floor, the function is about to pop its own locals, the saved rbp,
        the return address or its caller's stack: crash with a message instead."""
        label = self.fault_label()
        self.emit(f"lea r11, [rbp-@F@-{n}]", why=f"run-time guard: the value stack must keep {n} byte(s) below the frame's floor for this operation")
        self.emit("cmp rsp, r11", why="rsp above that limit means the function popped more than it pushed (below its home rbp / the rsp it was called with)")
        self.emit(f"ja {label}", why="stack underflow: jump to the run-time error that stops the program")

    def nasmtype(self, size: int) -> str:
        return {1: "byte", 2: "word", 4: "dword", 8: "qword"}[size]

    @staticmethod
    def mem(disp: int) -> str:
        return f"[rbp{disp:+d}]"

    def getreg(self, size: int) -> REGISTOR:
        reg = getFreeReg(size)

        if reg is None:
            error("Out of free registers.")

        return reg

    def trunc(self, group, size: int):
        """Zero-extend the low `size` bytes of the register to 64 bits."""
        r32 = group[1].lower()
        r16 = group[2].lower()
        r8 = group[3].lower()

        if size == 4:
            self.emit(f"mov {r32}, {r32}", why="canonicalise: clear the bits above the value's width so stack slots always hold zero-extended values")
        elif size == 2:
            self.emit(f"movzx {r32}, {r16}", why="canonicalise: clear the bits above the value's width so stack slots always hold zero-extended values")
        elif size == 1:
            self.emit(f"movzx {r32}, {r8}", why="canonicalise: clear the bits above the value's width so stack slots always hold zero-extended values")

    def extend(self, group, size: int, signed: bool, width: int):
        """Extend a canonical (zero-extended) value to `width` bytes (4 or 8)."""
        if size >= width:
            return

        self.emit(
            f"{'movsx' if signed else 'movzx'} "
            f"{rname(group, 4)}, {rname(group, size)}", why="widen the narrow operand to 32 bits so the full-width instruction sees its real signed/unsigned value")

    def load_sized(self, group, addr: str, size: int, why=None):
        """Load `size` bytes from addr into the register, zero-extended."""
        if size == 8:
            self.emit(f"mov {rname(group, 8)}, qword {addr}", why=why)
        elif size == 4:
            self.emit(f"mov {rname(group, 4)}, dword {addr}", why=why)
        else:
            self.emit(
                f"movzx {rname(group, 4)}, {self.nasmtype(size)} {addr}", why=why
            )

    def store_sized(self, addr: str, group, size: int, why=None):
        self.emit(f"mov {self.nasmtype(size)} {addr}, {rname(group, size)}", why=why)

    def push_group(self, group, size: int = 8):
        """Push a register.  8-byte slots normally; with --no-safe-slot exactly
        `size` bytes."""
        if self.safe or size == 8:
            self.trunc(group, size)
            self.emit(f"push {group[0].lower()}", why="push the value so the next operation can pop it from the top of the value stack")
            self.stack_size += 8
        else:
            self.emit(f"sub rsp, {size}", why=f"--no-safe-slot: reserve exactly {size} byte(s), the width of this value")
            self.store_sized("[rsp]", group, size, why="store the value into the bytes just reserved")
            self.stack_size += size

    def pushreg(self, reg: REGISTOR):
        self.push_group(REGISTOR_GROUP[reg], REGISTOR_SIZE[reg])

    def popreg(self, size: int) -> REGISTOR:
        slot = self.slot(size)
        self.need(slot)

        reg = self.getreg(size)

        self.emit(f"mov {rn(reg)}, [rsp]", why="pop: copy the top of the value stack into a register to work on it")
        self.emit(f"add rsp, {slot}", why="pop: release the bytes that were just consumed")
        self.stack_size -= slot

        return reg

    def pop64(self, size: int) -> REGISTOR:
        """Pop a `size`-byte value into a full 64-bit register, zero-extended."""
        slot = self.slot(size)
        self.need(slot)

        reg = self.getreg(8)

        self.load_sized(REGISTOR_GROUP[reg], "[rsp]", slot, why="pop: copy the top of the value stack into a register, zero-extended to 64 bits")
        self.emit(f"add rsp, {slot}", why="pop: release the bytes that were just consumed")
        self.stack_size -= slot

        return reg

    def push_imm(self, value: int, size: int):
        bits = size * 8

        if value >= (1 << bits) or value < -(1 << (bits - 1)):
            error(f"Value {value} does not fit in {size} bytes.")

        value &= (1 << bits) - 1

        reg = self.getreg(8)
        self.emit(f"mov {rn(reg)}, {value}", why="put the literal in a register first: push cannot take a 64-bit immediate")
        self.push_group(REGISTOR_GROUP[reg], self.slot(size))
        release(reg)



    # ---- temporarily claiming fixed registers -------------------------------

    def claim(self, names):
        """Reserve fixed registers (e.g. RAX/RDX for mul/div, RCX for shifts).
        Any of them that are currently in use are pushed and restored later."""
        prev = set(USED_REGISTORS)
        saved = []

        for name in names:
            group = next(g for g in REGISTOR_GROUPS if g[0] == name)

            if any(REGISTOR[x] in USED_REGISTORS for x in group):
                self.emit(f"push {name.lower()}", why=f"{name} is needed as a fixed register here but holds a live value: save it")
                saved.append(name)

            for x in group:
                USED_REGISTORS.add(REGISTOR[x])

        return prev, saved

    def unclaim(self, prev, saved):
        for name in reversed(saved):
            self.emit(f"pop {name.lower()}", why=f"restore {name}, saved earlier because it held a live value")

        USED_REGISTORS.clear()
        USED_REGISTORS.update(prev)

    def finish2(self, out_group, size: int, n: int, saved, prev):
        """Write the result over the 'a' operand, restore saved regs,
        and drop the 'b' operand."""
        slot = self.slot(size)

        if self.safe:
            self.trunc(out_group, size)
            self.emit(f"mov [rsp+{n + slot}], {out_group[0].lower()}", why="the result replaces operand a's slot: it is this operation's output on the value stack")
        else:
            self.store_sized(f"[rsp+{n + slot}]", out_group, size, why="the result replaces operand a: it is this operation's output on the value stack")

        self.unclaim(prev, saved)
        self.emit(f"add rsp, {slot}", why="operand b was consumed: drop it (two inputs became one output)")
        self.stack_size -= slot

    def muldiv(self, op: OP, size: int, signed: bool):
        slot = self.slot(size)
        self.need(2 * slot)

        width = 8 if size == 8 else 4

        prev, saved = self.claim(["RAX", "RDX"])
        n = 8 * len(saved)

        a = self.getreg(8)
        b = self.getreg(8)
        ga, gb = REGISTOR_GROUP[a], REGISTOR_GROUP[b]

        # operands still live on the stack (above any saved registers)
        self.load_sized(ga, f"[rsp+{n + slot}]", slot, why="read operand a (second from top) in place so any saved registers above it stay untouched")
        self.load_sized(gb, f"[rsp+{n}]", slot, why="read operand b (top of stack) in place")

        self.extend(ga, size, signed, width)
        self.extend(gb, size, signed, width)

        A = rname(ga, width)
        B = rname(gb, width)
        rax = "rax" if width == 8 else "eax"

        self.emit(f"mov {rax}, {A}", why="x86 mul/div take their first operand in rax")

        if op == OP.MUL:
            self.emit(f"{'imul' if signed else 'mul'} {B}", why="multiply: the one-operand form computes rdx:rax = rax * operand")
            out = REGISTOR_GROUPS[0]
        else:
            if signed:
                self.emit("cqo" if width == 8 else "cdq", why="signed divide: sign-extend rax into rdx so idiv sees the whole dividend")
            else:
                self.emit("xor edx, edx", why="unsigned divide: rdx is the upper half of the dividend, so zero it")

            self.emit(f"{'idiv' if signed else 'div'} {B}", why="divide rdx:rax by the divisor: quotient -> rax, remainder -> rdx")
            out = REGISTOR_GROUPS[0] if op == OP.DIV else REGISTOR_GROUPS[3]

        self.finish2(out, size, n, saved, prev)

    def shift(self, op: OP, size: int, signed: bool):
        slot = self.slot(size)
        self.need(2 * slot)

        width = 8 if size == 8 else 4

        prev, saved = self.claim(["RCX"])
        n = 8 * len(saved)

        a = self.getreg(8)
        ga = REGISTOR_GROUP[a]

        self.load_sized(ga, f"[rsp+{n + slot}]", slot, why="read the value to shift (second from top) in place")
        self.load_sized(REGISTOR_GROUPS[2], f"[rsp+{n}]", slot, why="x86 variable shifts take their count in cl, so load it into rcx")

        if op == OP.SHR and signed:
            self.extend(ga, size, True, width)

        mnemonic = "shl" if op == OP.SHL else ("sar" if signed else "shr")
        self.emit(f"{mnemonic} {rname(ga, width)}, cl", why="do the shift: sar keeps the sign (signed shr), shr/shl fill with zeros")

        self.finish2(ga, size, n, saved, prev)

    # ---- calls -----------------------------------------------------------

    def do_call(self, target: str, sizes: list, stack_only: bool = False, variadic_ext: bool = False):
        """The arguments are on the stack (first deepest, last on top); `sizes`
        gives the bytes each one occupies (8 each unless --no-safe-slot).

        The first len(ARG_REGS) arguments go in registers (zero-extended), the
        rest in 8-byte stack slots above SHADOW bytes of shadow space.  With
        `stack_only` every argument goes on the stack (used for variadic functions
        written in bforth on targets that do not home registers).  The arguments
        are popped afterwards."""
        nargs = len(sizes)
        total = sum(sizes)
        offsets = [sum(sizes[i + 1:]) for i in range(nargs)]
        nregs = 0 if stack_only else len(self.ARG_REGS)
        extra = max(0, nargs - nregs)

        for i in range(min(nargs, nregs)):
            self.load_sized(
                self.ARG_REGS[i], f"[rsp+{offsets[i]}]", sizes[i],
                why=f"load argument {i} into its {self.ABI_NAME} register ({', '.join(g[0].lower() for g in self.ARG_REGS)})",
            )

        frame = self.SHADOW + 8 * extra
        frame += (-(self.stack_size + frame)) % 16

        self.emit(f"sub rsp, {frame}", why=self.FRAME_WHY.format(shadow=self.SHADOW))

        for k in range(extra):
            i = nregs + k
            self.load_sized(
                REGISTOR_GROUPS[11], f"[rsp+{frame + offsets[i]}]", sizes[i],
                why="stack argument: read it from the temporary argument slots (via r11, a scratch register)",
            )
            self.emit(f"mov [rsp+{self.SHADOW + 8 * k}], r11", why="copy it into the outgoing argument area where the callee expects it")

        if variadic_ext:
            self.before_variadic_call()

        self.emit(f"call {target}", why="call the function; an integer result comes back in rax")
        self.emit(f"add rsp, {frame + total}", why="pop the call frame and the temporary argument values in one go")
        self.stack_size -= total

    def dump(self, fmt: str, size: int, signed: bool):
        slot = self.slot(size)
        self.need(slot)

        a0, a1 = self.ARG_REGS[0], self.ARG_REGS[1]
        r0, r1_64, r1_32 = rname(a0, 8), rname(a1, 8), rname(a1, 4)

        self.emit(f"lea {r0}, [rel {fmt}]", why=f"printf argument 1 ({r0}): the address of the format string")

        why2 = f"printf argument 2 ({r1_64}): load the value, widened to 64 bits"

        if size == 8:
            self.emit(f"mov {r1_64}, [rsp]", why=why2)
        elif size == 4:
            self.emit(
                f"movsxd {r1_64}, dword [rsp]" if signed
                else f"mov {r1_32}, dword [rsp]", why=why2)
        else:
            self.emit(
                f"movsx {r1_64}, {self.nasmtype(size)} [rsp]" if signed
                else f"movzx {r1_32}, {self.nasmtype(size)} [rsp]", why=why2)

        self.emit(f"add rsp, {slot}", why="the value was consumed by the dump: drop it")
        self.stack_size -= slot

        self.do_call(self.ext_call("printf"), [], variadic_ext=True)

    # ---- variables -------------------------------------------------------





    def load_var(self, name: str, size: int):
        var = self.vars[name]

        if size == 0:   # no width written at the use: 8 bytes, or the declared width
            size = 8 if self.safe else var.size

        if self.safe and size == 8:
            self.emit(f"push qword {self.mem(var.disp)}")
            self.stack_size += 8
        else:
            reg = self.getreg(8)
            group = REGISTOR_GROUP[reg]
            self.load_sized(group, self.mem(var.disp), size)
            self.push_group(group, self.slot(size))
            release(reg)

    def store_var(self, name: str):
        var = self.vars[name]

        reg = self.pop64(var.size)
        group = REGISTOR_GROUP[reg]

        self.trunc(group, var.size)
        self.emit(f"mov {self.mem(var.disp)}, {group[0].lower()}")
        release(reg)

    def load_external(self, name: str):
        size = self.extern_vars[name]
        reg = self.getreg(8)
        group = REGISTOR_GROUP[reg]

        if size not in (1, 2, 4, 8):
            error(f"Unsupported external variable size for '{name}'")

        self.load_sized(group, self.ext_var_mem(name), size)
        self.push_group(group, self.slot(size))
        release(reg)

    def store_external(self, name: str):
        size = self.extern_vars[name]
        reg = self.pop64(size)
        group = REGISTOR_GROUP[reg]

        if size not in (1, 2, 4, 8):
            error(f"Unsupported external variable size for '{name}'")

        self.emit(f"mov {self.ext_var_mem(name)}, {rname(group, size)}", why=f"write the extern variable '{name}' (it lives in another module)")
        release(reg)

    # ---- structs ---------------------------------------------------------





    def index_address(self, operand, type_name, line):
        """stack: ... ptr  ->  (register holding ptr + index * elemsize,
        type size or None). The pointer slot is consumed."""
        self.need(8, f"Line {line}: indexing needs a pointer on the stack")

        elem = 1
        tsize = None

        if type_name is not None:
            elem, is_struct = self.type_size(type_name, line)
            tsize = None if is_struct else elem

        delta = self.eval_one([operand], "index")

        i = self.pop64(delta)
        p = self.popreg(8)

        if elem != 1:
            self.emit(f"imul {rn(i)}, {rn(i)}, {elem}", why="scale the index by the element size: index * sizeof(type)")

        self.emit(f"add {rn(p)}, {rn(i)}", why="pointer + scaled index = address of the element")
        release(i)

        return p, tsize

    def struct_literal(self, struct_name: str, fields, line: int):
        """Push a struct's raw bytes (zero filled, then the given members)."""
        struct = self.structs[struct_name]

        self.emit(f"sub rsp, {struct.size}", why="reserve stack space for the struct's bytes")
        self.stack_size += struct.size

        for off in range(0, struct.size, 8):
            self.emit(f"mov qword [rsp+{off}], 0", why="zero the struct first so members not named in the initialiser read as 0")

        for field, toks, field_line in fields:
            if field not in struct.members:
                error(
                    f"Line {field_line}: struct '{struct_name}' "
                    f"has no member '{field}'"
                )

            offset, member_size = struct.members[field]

            if len(toks) == 1 and toks[0].type == OP.PUSH:
                toks = [toks[0]._replace(size=member_size)]

            delta = self.eval_one(toks, f"value of member '{field}'")

            reg = self.pop64(delta)
            self.store_sized(f"[rsp+{offset}]", REGISTOR_GROUP[reg], member_size)
            release(reg)

    # ---- arrays ----------------------------------------------------------

    def array(self, token: Token):
        elems = token.value
        size = token.size
        n = len(elems)
        total = (n * size + 7) // 8 * 8

        # 1. evaluate every element, in source order, one value each
        sizes = []

        for element in elems:
            toks = element

            if len(element) == 1 and element[0].type == OP.PUSH:
                toks = [element[0]._replace(size=size)]

            sizes.append(self.eval_one(toks, "array element"))

        temps = sum(sizes)           # bytes the evaluated elements occupy
        r11 = REGISTOR_GROUPS[11]

        # 2. build the packed array below the temporaries
        self.emit(f"sub rsp, {total}", why="reserve the packed array region below the element temporaries")
        self.stack_size += total

        if (n * size) % 8:
            self.emit(f"mov qword [rsp+{total - 8}], 0", why="zero the last 8-byte slot so padding bytes are deterministic")

        for i in range(n):
            self.load_sized(
                r11, f"[rsp+{total + sum(sizes[i + 1:])}]", sizes[i],
                why="read element i's temporary (evaluated in source order, so the first element is deepest)",
            )
            self.emit(f"mov [rsp+{i * size}], {R11_NAMES[size]}", why="store it packed at its final offset, narrowed to the element size")

        # 3. slide the packed array up over the temporaries, freeing them
        for q in reversed(range(total // 8)):
            self.emit(f"mov r11, [rsp+{8 * q}]", why="slide the packed array up over the now-consumed temporaries...")
            self.emit(f"mov [rsp+{temps + 8 * q}], r11", why="...copying from the highest slot down so overlapping source and destination stay correct")

        self.emit(f"add rsp, {temps}", why="free the temporaries: rsp now points at the array start")
        self.stack_size -= temps

        pointer = self.getreg(8)
        self.emit(f"mov {rn(pointer)}, rsp", why="the value this literal produces is a pointer to its first byte, i.e. the current rsp")
        self.pushreg(pointer)
        release(pointer)

    # ---- main walker -----------------------------------------------------

    def block(self, tokens: list[Token]):
        i = 0
        outer_note = self.note

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
                error(
                    f"Line {token.line}: External function '{name}' "
                    "must be called with parentheses"
                )

            elif i < len(tokens) and tokens[i].type in VALUE_OPS:
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

        self.note = outer_note

    def token(self, token: Token):
        size = token.size
        signed = token.signed

        self.header(describe_token(token), token.line)

        match token.type:
            case OP.PUSH:
                self.push_imm(token.value, size)

            case OP.STR:
                data, mutable = token.value

                self.strings += 1
                label = f"str_{self.strings}"
                body = ",".join(str(byte) for byte in data + b"\x00")

                shown = repr(data.decode("utf-8", "replace"))
                (self.data if mutable else self.rdata).append(
                    f"{label}: db {body}"
                    + (f"    ; {'mutable ' if mutable else ''}string {shown}" if self.comments else "")
                )

                reg = self.getreg(8)
                self.emit(f"lea {rn(reg)}, [{label}]", why="strings are static data: push the label's address (rip-relative)")
                self.pushreg(reg)
                release(reg)

            case OP.FUNC_REF:
                reg = self.getreg(8)
                self.emit(f"lea {rn(reg)}, [rel fn_{token.value}]", why="function values are pointers to the generated function entry")
                self.pushreg(reg)
                release(reg)

            case OP.CALL_INDIRECT:
                target = self.pop64(8)
                self.do_call(rn(target), [])
                release(target)
                if self.safe:
                    self.emit("push rax", why="indirect calls return a 64-bit value")
                    self.stack_size += 8
                else:
                    self.push_group(REGISTOR_GROUPS[0], 8)

            case OP.ARRAY:
                self.array(token)

            case OP.ARRAY_UNINIT:
                total = (token.value * token.size + 7) // 8 * 8
                if total:
                    self.emit(f"sub rsp, {total}", why="reserve uninitialized array storage on the stack")
                    self.stack_size += total
                pointer = self.getreg(8)
                self.emit(f"mov {rn(pointer)}, rsp", why="push a pointer to the first uninitialized array byte")
                self.pushreg(pointer)
                release(pointer)

            case OP.ROT | OP.ANTIROT:
                count = token.value
                slot = self.slot(size)
                self.need(count * slot, f"{token.type.name.lower()} needs {count} stack values")
                temp = self.alloc_frame(count * slot)
                # Snapshot the group because the stack representation is packed
                # differently in safe-slot and exact-size modes.
                for index in range(count):
                    reg = self.getreg(8)
                    group = REGISTOR_GROUP[reg]
                    self.load_sized(group, f"[rsp+{index * slot}]", slot)
                    self.store_sized(self.mem(temp + index * slot), group, slot)
                    release(reg)
                if token.type == OP.ROT and count == 3:
                    order = [2, 1, 0]
                elif token.type == OP.ROT:
                    order = [*range(1, count), 0]
                else:
                    order = [count - 1, *range(count - 1)]
                for index, source in enumerate(order):
                    reg = self.getreg(8)
                    group = REGISTOR_GROUP[reg]
                    self.load_sized(group, self.mem(temp + source * slot), slot)
                    self.store_sized(f"[rsp+{index * slot}]", group, slot)
                    release(reg)

            case OP.ADD | OP.SUB | OP.AND | OP.OR | OP.XOR:
                b = self.popreg(size)
                a = self.popreg(size)

                self.emit(f"{ARITH[token.type]} {rn(a)}, {rn(b)}", why="a = a op b on the sized registers (the 8/16/32/64-bit width comes from the operator)")

                self.pushreg(a)
                release(a)
                release(b)

            case OP.MUL | OP.DIV | OP.MOD:
                self.muldiv(token.type, size, signed)

            case OP.SHL | OP.SHR:
                self.shift(token.type, size, signed)

            case OP.NOT | OP.NEG:
                a = self.popreg(size)
                self.emit(f"{'not' if token.type == OP.NOT else 'neg'} {rn(a)}", why="unary operation applied in place")
                self.pushreg(a)
                release(a)

            case OP.EQ | OP.NE | OP.LT | OP.GT | OP.LE | OP.GE:
                b = self.popreg(size)
                a = self.popreg(size)
                group = REGISTOR_GROUP[a]

                condition = COMPARE[token.type][1 if signed else 0]

                self.emit(f"cmp {rn(a)}, {rn(b)}", why="compare a with b: only sets the flags")
                self.emit(f"set{condition} {group[3].lower()}", why="turn the flag into a byte: unsigned uses b/a/be/ae, signed uses l/g/le/ge")
                self.emit(f"movzx {group[1].lower()}, {group[3].lower()}", why="setcc only writes 8 bits: zero-extend to a full 0/1 value")
                self.push_group(group, self.slot(size))

                release(a)
                release(b)

            case OP.DUP:
                slot = self.slot(size)
                self.need(slot)

                reg = self.getreg(8)
                group = REGISTOR_GROUP[reg]
                self.load_sized(group, "[rsp]", slot, why="dup: read the top value")
                self.push_group(group, slot)
                release(reg)
            case OP.DROP:
                slot = self.slot(size)
                self.need(slot)

                self.emit(f"add rsp, {slot}", why="drop: discard the top value")
                self.stack_size -= slot
            case OP.DUMP:
                self.dump("fmt_lld" if signed else "fmt_llu", size, signed)

            case OP.DUMPC:
                self.dump("fmt_c", 1, False)

            case OP.DUMPS:
                self.dump("fmt_s", 8, False)

            case OP.WRITE:
                value = self.popreg(size)
                pointer = self.popreg(8)

                self.emit(f"mov [{rn(pointer)}], {rn(value)}", why="write: store the popped value through the popped pointer, at the value's size")

                release(value)
                release(pointer)

            case OP.READ:
                pointer = self.popreg(8)
                group = REGISTOR_GROUP[pointer]

                self.load_sized(group, f"[{group[0].lower()}]", size)
                self.push_group(group, self.slot(size))
                release(pointer)
            case OP.SET:
                if token.value in self.vars:
                    self.store_var(token.value)
                elif token.value in self.extern_vars:
                    self.store_external(token.value)
                else:
                    error(f"Line {token.line}: Undefined variable '{token.value}'")

            case OP.WHILE:
                condition, body = token.value
                top, end = self.new_label(), self.new_label()
                depth = self.stack_size

                self.label(top, why="loop top: the condition is re-evaluated every time we get back here")
                self.block(condition)

                self.check(
                    depth + self.slot(size),
                    "while condition must leave exactly one value",
                )

                reg = self.popreg(size)
                self.emit(f"test {rn(reg)}, {rn(reg)}", why="loop condition: set the zero flag from the popped value")
                release(reg)

                self.emit(f"jz {end}", why="condition false (zero): leave the loop")
                self.block(body)

                self.check(
                    depth,
                    "while body must leave the stack unchanged",
                )

                self.emit(f"jmp {top}", why="end of body: jump back and re-test the condition")
                self.label(end, why="loop exit: reached when the condition is false")

            case OP.IF:
                end = self.new_label()
                depth = self.stack_size
                branches = token.value

                for index, (condition, condition_size, body) in enumerate(branches):
                    next_label = None

                    if condition is not None:
                        next_label = self.new_label()

                        self.block(condition)
                        self.check(
                            depth + self.slot(condition_size),
                            "if/elif condition must leave exactly one value",
                        )

                        reg = self.popreg(condition_size)
                        self.emit(f"test {rn(reg)}, {rn(reg)}", why="if/elif condition: set the zero flag from the popped value")
                        release(reg)

                        self.emit(f"jz {next_label}", why="condition false (zero): skip to the next branch")

                    self.block(body)
                    self.check(
                        depth,
                        "if/elif/else branch must leave the stack unchanged",
                    )

                    if next_label is not None:
                        if index != len(branches) - 1:
                            self.emit(f"jmp {end}", why="branch done: skip the remaining elif/else branches")

                        self.label(next_label, why="next branch: reached when the condition above was false")

                self.label(end, why="end of the if/elif/else chain")

            case OP.CALL:
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
                        error(
                            f"Line {token.line}: {name}() takes at least "
                            f"{nparams} argument(s), got {len(args)}"
                        )
                elif len(args) != nparams:
                    error(
                        f"Line {token.line}: {name}() takes {nparams} "
                        f"argument(s), got {len(args)}"
                    )

                # functions defined in this language receive a hidden
                # "number of variadic arguments" right after the named ones
                hidden = function.variadic and not external
                sizes = []

                for index, argument in enumerate(args):
                    if hidden and index == nparams:
                        self.header(f"hidden argument: how many variadic arguments follow ({len(args) - nparams}); {name}() reads it to fill variadic_len", token.line)
                        self.push_imm(len(args) - nparams, 8)
                        sizes.append(self.slot(8))

                    sizes.append(self.eval_one(argument, f"argument {index + 1} of {name}()"))
                    self.note = f"call {name}(): marshal the arguments"

                if hidden and len(args) == nparams:
                    self.header(f"hidden argument: no variadic arguments follow, so the count is 0", token.line)
                    self.push_imm(0, 8)
                    sizes.append(self.slot(8))

                self.do_call(
                    self.ext_call(name) if external else f"fn_{name}",
                    sizes,
                    stack_only=hidden and self.USER_VARIADIC_ON_STACK,
                    variadic_ext=external and function.variadic,
                )

                if function.returns:
                    if self.safe:
                        if external and function.ret_size < 8:
                            self.trunc(REGISTOR_GROUPS[0], function.ret_size)

                        self.emit("push rax", why="the callee's return value (rax) becomes this expression's result")
                        self.stack_size += 8
                    else:
                        self.push_group(REGISTOR_GROUPS[0], function.ret_size)

            case OP.RET:
                slot = self.slot(size)
                self.need(slot, "Stack underflow (ret needs a value).")

                self.load_sized(REGISTOR_GROUPS[0], "[rsp]", slot, why="ret: the return value is the top of the value stack, move it to rax")
                self.emit(f"add rsp, {slot}", why="pop it")
                self.stack_size -= slot
                self.emit(f"jmp {self.ret_label}", why="leave through the common epilogue (restores rsp and rbp)")
            case OP.DOT:
                # struct bytes on top of the stack; they stay, a copy of
                # the member is pushed on top
                member, struct_name = token.value
                struct = self.resolve(member, struct_name, token.line)
                offset, member_size = struct.members[member]

                self.need(
                    struct.size,
                    f"Line {token.line}: '. {member}' needs a "
                    f"{struct.name} ({struct.size} bytes) on the stack",
                )

                reg = self.getreg(8)
                group = REGISTOR_GROUP[reg]

                self.load_sized(group, f"[rsp+{offset}]", member_size)
                self.push_group(group, self.slot(member_size))
                release(reg)
            case OP.ARROW:
                # pointer to a struct on top of the stack; it stays, a copy
                # of the member is pushed on top
                member, struct_name = token.value
                struct = self.resolve(member, struct_name, token.line)
                offset, member_size = struct.members[member]

                self.need(8, f"Line {token.line}: '-> {member}' needs a struct pointer")

                reg = self.getreg(8)
                group = REGISTOR_GROUP[reg]
                base = rname(group, 8)

                self.emit(f"mov {base}, [rsp]", why="read the struct pointer from the top of the stack (it stays there)")
                self.load_sized(group, f"[{base}+{offset}]", member_size)
                self.push_group(group, self.slot(member_size))
                release(reg)
            case OP.DOT_SET:
                # stack: value, struct bytes (top).  The value is consumed,
                # the struct bytes stay.
                member, struct_name = token.value
                struct = self.resolve(member, struct_name, token.line)
                offset, member_size = struct.members[member]
                vs = self.slot(member_size)

                self.need(
                    struct.size + vs,
                    f"Line {token.line}: '.= {member}' needs a value "
                    f"below a {struct.name} ({struct.size} bytes)",
                )

                reg = self.getreg(8)
                group = REGISTOR_GROUP[reg]

                self.load_sized(group, f"[rsp+{struct.size}]", vs, why="load the value being assigned: it sits below the struct bytes")
                self.store_sized(f"[rsp+{offset}]", group, member_size)
                release(reg)

                # slide the struct up over the value
                for q in reversed(range(struct.size // 8)):
                    self.emit(f"mov r11, [rsp+{8 * q}]", why="slide the struct up over the value (highest slot first: the regions overlap)")
                    self.emit(f"mov [rsp+{8 * q + vs}], r11", why="slide the struct up over the value (highest slot first: the regions overlap)")

                self.emit(f"add rsp, {vs}", why="drop the freed bytes so the struct bytes are on top again")
                self.stack_size -= vs
            case OP.ARROW_SET:
                # stack: value, struct pointer (top).  The value is consumed,
                # the pointer stays.
                member, struct_name = token.value
                struct = self.resolve(member, struct_name, token.line)
                offset, member_size = struct.members[member]
                vs = self.slot(member_size)

                self.need(
                    8 + vs,
                    f"Line {token.line}: '->= {member}' needs a value "
                    "below a struct pointer",
                )

                pointer = self.getreg(8)
                value = self.getreg(8)
                gp, gv = REGISTOR_GROUP[pointer], REGISTOR_GROUP[value]

                self.emit(f"mov {rname(gp, 8)}, [rsp]", why="read the struct pointer (top of stack; it stays)")
                self.load_sized(gv, "[rsp+8]", vs, why="read the value (just below the pointer)")
                self.store_sized(f"[{rname(gp, 8)}+{offset}]", gv, member_size)
                self.emit(f"mov [rsp+{vs}], {rname(gp, 8)}", why="overwrite the value with the pointer so only the pointer remains")
                self.emit(f"add rsp, {vs}", why="drop the now-duplicate bytes on top")
                self.stack_size -= vs

                release(pointer)
                release(value)
            case OP.DEREF:
                # pointer -> copy of the struct's bytes on the stack
                struct = self.structs[token.value]
                pointer = self.popreg(8)
                base = rname(REGISTOR_GROUP[pointer], 8)

                for off in range(struct.size - 8, -8, -8):
                    self.emit(f"push qword [{base}+{off}]", why="push the struct's bytes, highest 8-byte slot first so they end up in memory order")

                self.stack_size += struct.size
                release(pointer)

            case OP.STORE:
                # stack: pointer, struct bytes (top) -> copies bytes to pointer
                struct = self.structs[token.value]

                self.need(
                    struct.size + 8,
                    f"Line {token.line}: 'write as {struct.name}' needs a "
                    "pointer below the struct bytes",
                )

                pointer = self.getreg(8)
                base = rname(REGISTOR_GROUP[pointer], 8)

                self.emit(f"mov {base}, [rsp+{struct.size}]", why="load the destination pointer (it sits below the struct bytes)")

                for off in range(0, struct.size, 8):
                    self.emit(f"mov r11, [rsp+{off}]", why="copy the struct bytes to the destination, one 8-byte slot at a time (via r11)")
                    self.emit(f"mov [{base}+{off}], r11", why="copy the struct bytes to the destination, one 8-byte slot at a time (via r11)")

                self.emit(f"add rsp, {struct.size + 8}", why="consume the struct bytes and the pointer")
                self.stack_size -= struct.size + 8
                release(pointer)

            case OP.STRUCT_LIT:
                struct_name, fields = token.value
                self.struct_literal(struct_name, fields, token.line)

            case OP.STRUCT_DECL:
                name, struct_name, fields = token.value
                struct = self.structs[struct_name]

                if name in self.vars:
                    # "x point {..}" with an existing x is x followed by a
                    # struct literal, e.g.  x point {x = 4, y = 2} write as point
                    self.load_var(name, 8)
                    self.struct_literal(struct_name, fields, token.line)
                    return

                if name in self.extern_vars or name in self.extern_funcs:
                    error(f"Line {token.line}: '{name}' is declared extern")

                # name becomes a *pointer* to struct bytes that live in the frame
                storage = self.alloc_frame(struct.size)
                var = self.declare(name, 8, struct_name, 8, storage)

                for off in range(0, struct.size, 8):
                    self.emit(f"mov qword {self.mem(storage + off)}, 0", why="zero the struct's storage in the frame")

                reg = self.getreg(8)
                self.emit(f"lea {rn(reg)}, [rbp{storage:+d}]", why="address of that frame storage...")
                self.emit(f"mov {self.mem(var.disp)}, {rn(reg)}", why="...is the value of the variable, so the variable is a pointer to the struct")
                release(reg)

                for field, toks, field_line in fields:
                    if field not in struct.members:
                        error(
                            f"Line {field_line}: struct '{struct_name}' "
                            f"has no member '{field}'"
                        )

                    offset, member_size = struct.members[field]

                    if len(toks) == 1 and toks[0].type == OP.PUSH:
                        toks = [toks[0]._replace(size=member_size)]

                    delta = self.eval_one(toks, f"value of member '{field}'")

                    reg = self.pop64(delta)
                    self.store_sized(
                        self.mem(storage + offset),
                        REGISTOR_GROUP[reg],
                        member_size,
                    )
                    release(reg)

            case OP.SWAP:
                slot = self.slot(size)
                self.need(2 * slot)

                a, b = self.getreg(8), self.getreg(8)
                ga, gb = REGISTOR_GROUP[a], REGISTOR_GROUP[b]
                self.load_sized(ga, "[rsp]", slot, why="swap: read the top value")
                self.load_sized(gb, f"[rsp+{slot}]", slot, why="swap: read the second value")
                self.store_sized("[rsp]", gb, slot, why="swap: write them back exchanged")
                self.store_sized(f"[rsp+{slot}]", ga, slot, why="swap: write them back exchanged")
                release(a)
                release(b)
            case OP.NIP:
                slot = self.slot(size)
                self.need(2 * slot)

                r11 = REGISTOR_GROUPS[11]
                self.load_sized(r11, "[rsp]", slot, why="nip: keep the top value in r11")
                self.emit(f"add rsp, {slot}", why="drop the top value")
                self.store_sized("[rsp]", r11, slot, why="overwrite the second value (now on top) with the kept one")
                self.stack_size -= slot
            case OP.OVER:
                slot = self.slot(size)
                self.need(2 * slot)

                reg = self.getreg(8)
                group = REGISTOR_GROUP[reg]
                self.load_sized(group, f"[rsp+{slot}]", slot, why="over: read the second value")
                self.push_group(group, slot)
                release(reg)
            case OP.ADDROF:
                # address of the top stack slot
                self.need(1)

                reg = self.getreg(8)
                self.emit(f"mov {rn(reg)}, rsp", why="& : the address of the top value is the current stack pointer")
                self.pushreg(reg)
                release(reg)
            case OP.INDEX | OP.INDEX_ADDR:
                operand, type_name = token.value

                pointer, tsize = self.index_address(operand, type_name, token.line)
                group = REGISTOR_GROUP[pointer]
                pushed = 8

                if token.type == OP.INDEX:
                    if type_name is not None and tsize is None:
                        error(
                            f"Line {token.line}: [i: {type_name}] cannot read a whole "
                            f"struct; use &[i: {type_name}] to get its address"
                        )

                    read_size = tsize if tsize is not None else size
                    self.load_sized(group, f"[{rname(group, 8)}]", read_size)
                    pushed = read_size

                self.push_group(group, self.slot(pushed))
                release(pointer)
            case OP.INDEX_SET:
                operand, type_name, value_token = token.value

                pointer, tsize = self.index_address(operand, type_name, token.line)

                if type_name is not None and tsize is None:
                    error(
                        f"Line {token.line}: [i: {type_name}]= cannot assign a "
                        "whole struct; use store/->= instead"
                    )

                write_size = tsize if tsize is not None else size

                self.push_group(REGISTOR_GROUP[pointer])
                release(pointer)

                delta = self.eval_one([value_token], "value of an index assignment")

                value = self.pop64(delta)
                pointer = self.popreg(8)

                self.store_sized(f"[{rn(pointer)}]", REGISTOR_GROUP[value], write_size, why="index write: store the value through the computed element address")

                release(value)
                release(pointer)

            case OP.SIZEOF:
                name = token.value

                if name in self.structs:
                    value = self.structs[name].size
                elif name in self.typedefs:
                    value = self.typedefs[name].size
                else:
                    error(f"Line {token.line}: unknown struct or typedef '{name}'")

                self.push_imm(value, 8)

            case OP.OFFSETOF:
                member, struct_name = token.value
                struct = self.resolve(member, struct_name, token.line)
                self.push_imm(struct.members[member][0], 8)

            case OP.ADDR:
                name = token.value

                reg = self.getreg(8)

                if name in self.vars:
                    self.emit(
                        f"lea {rn(reg)}, [rbp{self.vars[name].disp:+d}]", why=f"address of variable '{name}' in the frame")
                elif name in self.extern_vars:
                    self.ext_var_addr(REGISTOR_GROUP[reg], name)
                else:
                    error(f"Line {token.line}: Undefined variable '{name}'")

                self.pushreg(reg)
                release(reg)

            case _:
                error(f"Unhandled op {token.type!r}")

    def function(self, label: str, params, body, variadic=False):
        self.lines = []
        self.stack_size = 0
        self.vars = {}
        self.frame_bytes = 0
        self.ret_label = f"ret_{label}"
        self.fn_label = label
        self.fault_stubs = {}
        self.cur_line = 0

        nparams = len(params)
        self.note = f"function entry ({label}): set up arguments"

        self.setup_params(params, variadic)

        if variadic:
            self.setup_variadic(nparams)

        self.note = f"body of {label}"
        self.block(body)

        frame_size = (self.frame_bytes + 15) // 16 * 16
        self.lines = [l.replace("@F@", str(frame_size)) for l in self.lines]

        line = self.fmt_line

        shown = ", ".join(name for name, _ in params) + (", ..." if variadic else "")
        banner = [f"; ======== function {label}({shown}) ========"] if self.comments else []

        self.text += banner + [
            f"{label}:",
            line("push rbp", "prologue: save the caller's frame pointer"),
            line("mov rbp, rsp", "locals live at negative offsets from rbp, arguments at positive ones"),
            line(f"sub rsp, {frame_size}", "reserve the locals; rounded up to 16 so rsp stays 16-byte aligned for calls"),
        ]

        self.text += self.lines

        self.text += [
            line("xor eax, eax", "falling off the end of a function returns 0"),
            (f"{self.ret_label}:" if not self.comments else
             f"{self.ret_label + ':':<{self.COMMENT_COLUMN + 4}}; every 'ret' jumps here"),
            line("mov rsp, rbp", "epilogue: discard locals and any leftover temporaries"),
            line("pop rbp", "restore the caller's frame pointer"),
            line("ret", "back to the caller (return value, if any, is in rax)"),
        ]

        if self.fault_stubs:
            # --no-safe-slot: run-time stack underflow reporting for this function
            display = label[3:] if label.startswith("fn_") else label
            common = f"{label}_stack_fault"
            name_label = f"{label}_name"
            self.rdata.append(f'{name_label}: db "{display}", 0')

            self.comment_text(f"---- {label}: run-time stack underflow handler (--no-safe-slot)")

            for stub_line, stub in self.fault_stubs.items():
                self.text += [
                    f"{stub}:",
                    line(f"mov {self.FAULT_LINE_REG}, {stub_line}", "report the source line of the operation that underflowed"),
                    line(f"jmp {common}", "share one handler per function"),
                ]

            self.text.append(f"{common}:")
            self.text += [line(t, w) for t, w in self.fault_handler(name_label)]

        self.text.append("")


