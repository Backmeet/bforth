"""Peephole optimizer for the NASM text written by codegen/win.py and codegen/linux.py.

It looks at the instruction stream one instruction at a time and makes it smaller
without changing what the program does:

  * dead code       an instruction whose only effect is a value nobody reads is removed
                    (register liveness and flag liveness are tracked)
  * direct writes   `mov rax, 5` + `mov [rbp-8], rax`   ->  `mov qword [rbp-8], 5`
                    `mov rax, [x]` + `push rax`          ->  `push qword [x]`
                    `pop rax` + `mov [x], rax`           ->  `pop qword [x]`
  * immediates      `mov rcx, 5` + `add rax, rcx`        ->  `add rax, 5`
  * memory operands `mov rcx, [x]` + `add rax, rcx`      ->  `add rax, [x]`
  * stack traffic   `mov rax, [rsp]` + `add rsp, 8`      ->  `pop rax`
                    `push rax` + `pop rcx`               ->  `mov rcx, rax`
                    `add rsp, 8` + `add rsp, 16`         ->  `add rsp, 24`;  `sub rsp, 8` + `add rsp, 8` vanish
  * small encodings `mov rax, 0` -> `xor eax, eax`,  `mov rax, 7` -> `mov eax, 7`
  * control flow    `jmp L` right before `L:`, and unreachable code after `jmp` / `ret`

What it assumes (true for the code this compiler generates, so it is only meant
for that):
  * at the end of a basic block (label, jump, return) every register except rax is
    dead and the flags are dead; the only values that cross a block boundary are the
    stack and rax (the return value)
  * a `call` reads the argument registers and rax and destroys every caller-saved
    register
  * jumps to `*_stack_fault` stubs (--no-safe-slot guards) keep every register alive

Registers that are used in an unusual way make the optimizer give up on that
instruction instead of guessing: any instruction it does not know is treated as
reading and writing everything.
"""
import re

# ------------------------------------------------------------------ registers

_GROUPS = [
    ("rax", "eax", "ax", "al", "ah"),
    ("rbx", "ebx", "bx", "bl", "bh"),
    ("rcx", "ecx", "cx", "cl", "ch"),
    ("rdx", "edx", "dx", "dl", "dh"),
    ("rsi", "esi", "si", "sil"),
    ("rdi", "edi", "di", "dil"),
    ("rbp", "ebp", "bp", "bpl"),
    ("rsp", "esp", "sp", "spl"),
] + [(f"r{i}", f"r{i}d", f"r{i}w", f"r{i}b") for i in range(8, 16)]

REG = {}      # name -> (canonical 64-bit name, width in bytes)
for _g in _GROUPS:
    _widths = (8, 4, 2, 1, 1)
    for _name, _width in zip(_g, _widths):
        REG[_name] = (_g[0], _width)

R64 = {g[0] for g in _GROUPS}
BY_WIDTH = {g[0]: {8: g[0], 4: g[1], 2: g[2], 1: g[3]} for g in _GROUPS}

CALL_READS = {"rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9"}
CALL_CLOBBERS = {"rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11"}

REG_RE = re.compile(r"\b(" + "|".join(sorted(REG, key=len, reverse=True)) + r")\b")

COND_JUMPS = {
    "ja", "jae", "jb", "jbe", "jc", "jnc", "je", "jz", "jne", "jnz",
    "jg", "jge", "jl", "jle", "js", "jns", "jo", "jno", "jp", "jnp",
}
FLAG_READERS = COND_JUMPS | {"adc", "sbb"} | {
    "seta", "setae", "setb", "setbe", "sete", "setne", "setg", "setge", "setl", "setle",
    "setz", "setnz", "sets", "setns", "setc", "setnc",
}
FLAG_WRITERS = {
    "add", "sub", "and", "or", "xor", "cmp", "test", "neg", "shl", "shr", "sar",
    "imul", "mul", "div", "idiv", "inc", "dec", "adc", "sbb",
}
RMW2 = {"add", "sub", "and", "or", "xor", "shl", "shr", "sar", "adc", "sbb"}
ARITH_FOLD = {"add", "sub", "and", "or", "xor", "cmp"}
MOVES = {"mov", "movzx", "movsx", "movsxd", "lea"}


# ------------------------------------------------------------------ lines

class Node:
    """One line of assembly."""
    __slots__ = ("kind", "op", "args", "comment", "text")

    def __init__(self, kind, text="", op="", args=None, comment=""):
        self.kind = kind          # ins | label | comment | other
        self.text = text          # raw text (non-instructions)
        self.op = op
        self.args = args or []
        self.comment = comment    # text after ';' (without the ';')

    def ins_text(self):
        return f"{self.op} {', '.join(self.args)}" if self.args else self.op


INS_RE = re.compile(r"^\s+([a-z][a-z0-9]*)\b\s*(.*?)\s*(?:;(.*))?$")
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):\s*(?:;(.*))?$")


def split_args(rest):
    args, cur, depth = [], "", 0

    for ch in rest:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1

        if ch == "," and depth == 0:
            args.append(cur.strip())
            cur = ""
        else:
            cur += ch

    if cur.strip():
        args.append(cur.strip())

    return args


def parse(lines):
    nodes = []
    in_text = False

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("section"):
            in_text = stripped.split()[1] == ".text"
            nodes.append(Node("other", line))
            continue

        if not stripped:
            nodes.append(Node("other", line))
            continue

        if stripped.startswith(";"):
            nodes.append(Node("comment", line))
            continue

        m = LABEL_RE.match(stripped)

        if m and in_text:
            nodes.append(Node("label", line, op=m.group(1), comment=(m.group(2) or "").strip()))
            continue

        m = INS_RE.match(line)

        if in_text and m and not line.startswith(("extern", "global", "bits", "default")):
            nodes.append(Node("ins", op=m.group(1), args=split_args(m.group(2)), comment=(m.group(3) or "").strip()))
            continue

        nodes.append(Node("other", line))

    return nodes


COLUMN = 34


def render(node, comments):
    if node.kind != "ins":
        return node.text

    text = node.ins_text()

    if comments and node.comment:
        return f"    {text:<{COLUMN}}; {node.comment}"

    return f"    {text}"


# ------------------------------------------------------------------ operands

def is_mem(arg):
    return "[" in arg


def reg_of(arg):
    """('rax', width) if `arg` is exactly a register."""
    return REG.get(arg.strip())


def mem_regs(arg):
    return {REG[n][0] for n in REG_RE.findall(arg)} if is_mem(arg) else set()


def imm_of(arg):
    try:
        return int(arg.strip(), 0)
    except ValueError:
        return None


def mem_core(arg):
    """`qword [rbp-8]` -> `[rbp-8]`"""
    m = re.fullmatch(r"(?:(?:qword|dword|word|byte)\s+)?(\[.*\])", arg.strip())
    return m.group(1) if m else None


def fits(value, width, signed_imm32=True):
    """Can `value` be written as an immediate of an instruction with this operand width?"""
    if value is None:
        return False

    if width == 8:
        return -(1 << 31) <= value <= (1 << 31) - 1
    return -(1 << (width * 8 - 1)) <= value < (1 << (width * 8))


# ------------------------------------------------------------------ effects

def effects(n):
    """(reads, writes, partial_writes, reads_flags, writes_flags, barrier) of an instruction.
    Registers are canonical 64-bit names.  `writes` are full overwrites."""
    op, a = n.op, n.args
    reads, writes, partial = set(), set(), set()
    rf = op in FLAG_READERS
    wf = op in FLAG_WRITERS

    def src(arg):
        r = reg_of(arg)

        if r:
            reads.add(r[0])
        else:
            reads.update(mem_regs(arg))

    def dst(arg, also_read=False):
        r = reg_of(arg)

        if r:
            if r[1] >= 4 and not also_read:
                writes.add(r[0])
            else:
                reads.add(r[0])
                partial.add(r[0])
        else:
            reads.update(mem_regs(arg))

    if op in ("mov", "movzx", "movsx", "movsxd") and len(a) == 2:
        src(a[1])
        dst(a[0])
    elif op == "lea" and len(a) == 2:
        reads.update(mem_regs(a[1]))
        dst(a[0])
    elif op == "xor" and len(a) == 2 and a[0] == a[1] and reg_of(a[0]):
        dst(a[0])
    elif op in RMW2 and len(a) == 2:
        src(a[1])
        dst(a[0], also_read=True)
    elif op == "imul" and len(a) == 3:
        src(a[1])
        dst(a[0])
    elif op == "imul" and len(a) == 2:
        src(a[1])
        dst(a[0], also_read=True)
    elif op in ("cmp", "test") and len(a) == 2:
        src(a[0])
        src(a[1])
    elif op in ("neg", "not") and len(a) == 1:
        dst(a[0], also_read=True)
    elif op.startswith("set") and len(a) == 1:
        dst(a[0], also_read=True)
    elif op == "push" and len(a) == 1:
        src(a[0])
        reads.add("rsp")
        writes.add("rsp")
    elif op == "pop" and len(a) == 1:
        dst(a[0])
        reads.add("rsp")
        writes.add("rsp")
    elif op in ("mul", "imul") and len(a) == 1:
        src(a[0])
        reads.add("rax")
        writes.update({"rax", "rdx"})
    elif op in ("div", "idiv") and len(a) == 1:
        src(a[0])
        reads.update({"rax", "rdx"})
        writes.update({"rax", "rdx"})
    elif op == "cqo" or op == "cdq":
        reads.add("rax")
        writes.add("rdx")
    elif op in ("call", "jmp", "ret") or op in COND_JUMPS:
        pass
    else:
        return set(R64), set(), set(), True, True, True   # unknown: touch everything

    # rsp is only ever used for addressing here: never treat it as removable
    return reads, writes, partial, rf, wf, False


# ------------------------------------------------------------------ liveness

def next_ins(nodes, i):
    """Index of the next instruction/label after i, skipping comments and blanks."""
    j = i + 1

    while j < len(nodes) and (nodes[j].kind in ("comment",) or (nodes[j].kind == "other" and not nodes[j].text.strip())):
        j += 1

    return j


def reg_dead_after(nodes, i, group, _depth=0):
    """True if the value in `group` is not needed after node i."""
    if group == "rsp" or group == "rbp":
        return False

    j = next_ins(nodes, i)

    while j < len(nodes):
        n = nodes[j]

        if n.kind == "other":
            return group != "rax"

        if n.kind == "label":
            return group != "rax"            # block boundary: only rax survives

        if n.kind == "ins":
            op = n.op

            if op == "ret":
                return group != "rax"

            if op == "jmp":
                target = n.args[0] if n.args else ""
                return False if target.endswith("_stack_fault") else group != "rax"

            if op in COND_JUMPS:
                if group == "rax":
                    return False

                j = next_ins(nodes, j)       # the branch path is dead, check the fall-through
                continue

            if op == "call":
                if group in CALL_READS:
                    return False

                if group in CALL_CLOBBERS:
                    return True

                return False

            reads, writes, partial, _, _, barrier = effects(n)

            if barrier or group in reads:
                return False

            if group in writes:
                return True

        j = next_ins(nodes, j)

    return group != "rax"


def flags_dead_after(nodes, i):
    j = next_ins(nodes, i)

    while j < len(nodes):
        n = nodes[j]

        if n.kind != "ins":
            return True

        op = n.op

        if op in FLAG_READERS:
            return False

        if op in FLAG_WRITERS or op in ("call", "ret", "jmp"):
            return True

        _, _, _, _, _, barrier = effects(n)

        if barrier:
            return False

        j = next_ins(nodes, j)

    return True


# ------------------------------------------------------------------ rewriting

class Optimizer:
    def __init__(self, nodes, comments):
        self.nodes = nodes
        self.comments = comments
        self.removed = 0

    def set(self, node, op, args, why):
        node.op = op
        node.args = args

        if self.comments:
            from codegen.base import explain
            node.comment = f"{explain(node.ins_text())}  -- optimized: {why}"

    def delete(self, node):
        node.kind = "dead"
        self.removed += 1

    def live_ins(self, i):
        """Index of the next live instruction after i (None across labels)."""
        j = i + 1
        nodes = self.nodes

        while j < len(nodes):
            k = nodes[j].kind

            if k == "ins":
                return j

            if k in ("comment", "dead"):
                j += 1
                continue

            if k == "other" and not nodes[j].text.strip():
                j += 1
                continue

            return None

        return None

    # -- individual patterns -----------------------------------------------------

    def step(self, i):
        nodes = self.nodes
        n = nodes[i]

        if n.kind != "ins":
            return False

        j = self.live_ins(i)
        m = nodes[j] if j is not None else None
        op, a = n.op, n.args

        # mov R, R
        if op == "mov" and len(a) == 2 and a[0] == a[1] and reg_of(a[0]) and reg_of(a[0])[1] == 8:
            self.delete(n)
            return True

        # jmp L ; L:
        if op == "jmp" and a:
            k = i + 1

            while k < len(nodes) and (nodes[k].kind in ("comment", "dead") or (nodes[k].kind == "other" and not nodes[k].text.strip())):
                k += 1

            if k < len(nodes) and nodes[k].kind == "label" and nodes[k].op == a[0]:
                self.delete(n)
                return True

        # add/sub rsp, 0
        if op in ("add", "sub") and len(a) == 2 and a[0] == "rsp" and imm_of(a[1]) == 0 and flags_dead_after(nodes, i):
            self.delete(n)
            return True

        if self.fold_source(i):
            return True

        if m is None:
            return False

        op2, a2 = m.op, m.args

        # mov R,[rsp] ; add rsp, 8   ->   pop R
        if (
            op == "mov" and len(a) == 2 and reg_of(a[0]) and reg_of(a[0])[1] == 8
            and reg_of(a[0])[0] not in ("rsp",) and mem_core(a[1]) == "[rsp]"
            and op2 == "add" and a2 == ["rsp", "8"] and flags_dead_after(nodes, j)
        ):
            self.set(n, "pop", [a[0]], "one pop instead of a load and an add")
            self.delete(m)
            return True

        # push X ; pop Y
        if op == "push" and op2 == "pop" and reg_of(a2[0]) and reg_of(a2[0])[1] == 8:
            x, y = a[0], a2[0]

            if x == y:
                self.delete(n)
                self.delete(m)
                return True

            if not (is_mem(x) and is_mem(y)):
                self.set(n, "mov", [y, x], "push followed by pop is a plain move")
                self.delete(m)
                return True

        # mov R, [mem] ; push R   ->   push qword [mem]
        if (
            op == "mov" and len(a) == 2 and reg_of(a[0]) and reg_of(a[0])[1] == 8 and mem_core(a[1])
            and op2 == "push" and a2 == [a[0]] and reg_dead_after(nodes, j, reg_of(a[0])[0])
        ):
            self.set(n, "push", [f"qword {mem_core(a[1])}"], "push straight from memory")
            self.delete(m)
            return True

        # pop R ; mov [mem], R   ->   pop qword [mem]
        if (
            op == "pop" and reg_of(a[0]) and op2 == "mov" and len(a2) == 2 and a2[1] == a[0]
            and mem_core(a2[0]) and "rsp" not in mem_core(a2[0])
            and (not re.match(r"(dword|word|byte)", a2[0].strip()))
            and reg_dead_after(nodes, j, reg_of(a[0])[0])
        ):
            self.set(n, "pop", [f"qword {mem_core(a2[0])}"], "pop straight into memory")
            self.delete(m)
            return True

        # mov R, [mem] ; OP D, R   ->   OP D, [mem]
        if (
            op == "mov" and len(a) == 2 and reg_of(a[0]) and mem_core(a[1]) and reg_of(a[0])[1] in (4, 8)
            and op2 in ARITH_FOLD and len(a2) == 2 and a2[1] == a[0] and reg_of(a2[0])
            and reg_of(a2[0])[1] == reg_of(a[0])[1] and reg_of(a2[0])[0] != reg_of(a[0])[0]
            and reg_dead_after(nodes, j, reg_of(a[0])[0])
        ):
            self.set(n, op2, [a2[0], mem_core(a[1])], "read the operand straight from memory")
            self.delete(m)
            return True

        # mov Y, X ; mov X, Y  -> second is redundant
        if (
            op == "mov" and op2 == "mov" and len(a) == 2 and len(a2) == 2
            and reg_of(a[0]) and reg_of(a[1]) and a2 == [a[1], a[0]] and reg_of(a[0])[1] == 8
        ):
            self.delete(m)
            return True

        # rsp arithmetic
        if op in ("add", "sub") and len(a) == 2 and a[0] == "rsp" and imm_of(a[1]) is not None \
                and op2 in ("add", "sub") and len(a2) == 2 and a2[0] == "rsp" and imm_of(a2[1]) is not None \
                and flags_dead_after(nodes, j):
            v1 = imm_of(a[1]) * (1 if op == "sub" else -1)       # amount rsp moves down
            v2 = imm_of(a2[1]) * (1 if op2 == "sub" else -1)
            net = v1 + v2

            if net == 0:
                self.delete(n)
                self.delete(m)
            elif net > 0:
                self.set(n, "sub", ["rsp", str(net)], "merged stack adjustments")
                self.delete(m)
            else:
                self.set(n, "add", ["rsp", str(-net)], "merged stack adjustments")
                self.delete(m)

            return True

        return False

    # -- propagate constants and register copies into their single use -------------------

    def fold_source(self, i):
        """`mov R, S` (S an immediate or another 64-bit register) followed, a few
        instructions later, by the only use of R: use S there and drop the move."""
        nodes = self.nodes
        n = nodes[i]
        a = n.args

        if n.op != "mov" or len(a) != 2:
            return False

        r = reg_of(a[0])

        if not r or r[1] != 8 or r[0] in ("rsp", "rbp"):
            return False

        imm = imm_of(a[1])
        sreg = reg_of(a[1])

        if imm is None:
            if not (sreg and sreg[1] == 8 and sreg[0] != r[0] and sreg[0] not in ("rsp", "rbp")):
                return False
        elif not fits(imm, 8):
            return False

        R = r[0]
        j = i
        gap = 0

        while True:
            j = self.live_ins(j)

            if j is None:
                return False

            m = nodes[j]
            op2, a2 = m.op, m.args
            uses = R in {x for x in effects(m)[0]} and not effects(m)[5]

            if uses:
                break

            reads, writes, partial, _, _, barrier = effects(m)

            if barrier or op2 in ("call", "jmp", "ret") or op2 in COND_JUMPS:
                return False

            if R in writes or R in partial:
                return False

            if sreg and (sreg[0] in writes or sreg[0] in partial):
                return False

            gap += 1

            if gap > 3:
                return False

        new = None
        src = a[1]

        if op2 == "push" and a2 == [a[0]]:
            new = ("push", [src], "push the source directly")
        elif (
            op2 == "mov" and len(a2) == 2 and a2[1] == a[0] and mem_core(a2[0])
            and not re.match(r"(dword|word|byte)", a2[0].strip()) and R not in mem_regs(a2[0])
        ):
            dest = a2[0] if sreg else f"qword {mem_core(a2[0])}"
            new = ("mov", [dest, src], "store the source directly")
        elif (
            op2 in ARITH_FOLD and len(a2) == 2 and a2[1] == a[0] and reg_of(a2[0])
            and reg_of(a2[0])[1] == 8 and reg_of(a2[0])[0] != R
        ):
            new = (op2, [a2[0], src], "use the source directly")
        elif op2 == "test" and a2 == [a[0], a[0]] and sreg:
            new = ("test", [src, src], "test the source directly")

        if new is None:
            return False

        saved = (m.op, m.args)
        m.op, m.args = new[0], new[1]

        if not reg_dead_after(nodes, j, R):
            m.op, m.args = saved
            return False

        m.op, m.args = saved
        self.set(m, new[0], new[1], new[2])
        self.delete(n)
        return True

    # -- dead register writes ---------------------------------------------------------

    def dead_writes(self):
        changed = False
        nodes = self.nodes

        for i, n in enumerate(nodes):
            if n.kind != "ins":
                continue

            if n.op not in MOVES and not (n.op == "xor" and len(n.args) == 2 and n.args[0] == n.args[1]):
                continue

            if len(n.args) < 2:
                continue

            r = reg_of(n.args[0])

            if not r or r[0] in ("rsp", "rbp") or r[1] < 4:
                continue

            if n.op == "xor" and not flags_dead_after(nodes, i):
                continue

            if reg_dead_after(nodes, i, r[0]):
                self.delete(n)
                changed = True

        return changed

    # -- smaller encodings (run last: the patterns above want `mov R64, imm`) -------------------

    def shrink_immediates(self):
        changed = False
        nodes = self.nodes

        for i, n in enumerate(nodes):
            if n.kind != "ins" or n.op != "mov" or len(n.args) != 2:
                continue

            r = reg_of(n.args[0])
            value = imm_of(n.args[1])

            if not r or r[1] != 8 or value is None or r[0] in ("rsp", "rbp"):
                continue

            r32 = BY_WIDTH[r[0]][4]

            if value == 0 and flags_dead_after(nodes, i):
                self.set(n, "xor", [r32, r32], "zeroing idiom: shorter than loading 0")
                changed = True
            elif 0 <= value <= 0xFFFFFFFF:
                self.set(n, "mov", [r32, n.args[1]], "a 32-bit move zero-extends: no 64-bit immediate needed")
                changed = True

        return changed

    # -- unreachable code ----------------------------------------------------------------

    def unreachable(self):
        changed = False
        dead = False

        for n in self.nodes:
            if n.kind == "label":
                dead = False
            elif n.kind == "ins":
                if dead:
                    self.delete(n)
                    changed = True
                elif n.op in ("jmp", "ret"):
                    dead = True
            elif n.kind == "other" and n.text.strip().startswith("section"):
                dead = False

        return changed

    def run(self):
        for _ in range(12):
            changed = False
            i = 0

            while i < len(self.nodes):
                if self.step(i):
                    changed = True
                    i = max(0, i - 3)
                    continue

                i += 1

            changed |= self.dead_writes()
            changed |= self.unreachable()

            if not changed:
                break

        self.shrink_immediates()


def optimize(text: str, comments: bool = False, stats: dict | None = None) -> str:
    lines = text.split("\n")
    nodes = parse(lines)
    before = sum(1 for n in nodes if n.kind == "ins")

    opt = Optimizer(nodes, comments)
    opt.run()

    out = [render(n, comments) for n in nodes if n.kind != "dead"]
    after = sum(1 for n in nodes if n.kind == "ins")

    if stats is not None:
        stats["before"], stats["after"] = before, after

    return "\n".join(out)
