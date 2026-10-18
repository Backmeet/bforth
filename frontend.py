"""bforth front end: preprocessor, tokenizer and parser.

preprocess(path, include_dirs, defines) -> source text
lex(text)                               -> [(kind, text, line), ...]
Parser(tokens).parse()                  -> (tokens, funcs, extern_vars, extern_funcs, structs, typedefs)
"""
import re
import sys
from enum import IntEnum
from typing import NamedTuple, NoReturn
from pathlib import Path


_enum_counter = 0


def enum(reset: bool = False):
    global _enum_counter
    if reset:
        _enum_counter = 0
    old = _enum_counter
    _enum_counter += 1
    return old


class OP(IntEnum):
    PUSH = enum(True)
    STR = enum()
    ARRAY = enum()
    WORD = enum()
    ADD = enum()
    SUB = enum()
    MUL = enum()
    DIV = enum()
    MOD = enum()
    AND = enum()
    OR = enum()
    XOR = enum()
    SHL = enum()
    SHR = enum()
    NOT = enum()
    NEG = enum()
    EQ = enum()
    NE = enum()
    LT = enum()
    GT = enum()
    LE = enum()
    GE = enum()
    DUP = enum()
    DROP = enum()
    DUMP = enum()
    DUMPC = enum()
    DUMPS = enum()
    WRITE = enum()
    READ = enum()
    SET = enum()
    WHILE = enum()
    IF = enum()
    CALL = enum()
    RET = enum()
    DOT = enum()
    ARROW = enum()
    STRUCT_DECL = enum()
    SIZEOF = enum()
    OFFSETOF = enum()
    ADDR = enum()
    SWAP = enum()
    NIP = enum()
    OVER = enum()
    DOT_SET = enum()
    ARROW_SET = enum()
    DEREF = enum()
    STORE = enum()
    INDEX = enum()
    INDEX_SET = enum()
    INDEX_ADDR = enum()
    ADDROF = enum()
    STRUCT_LIT = enum()
    COUNT = enum()


class Token(NamedTuple):
    type: OP
    value: object = None
    size: int = 8
    signed: bool = False
    line: int = 0


class Mods(NamedTuple):
    """Pending modifiers (sized / signed / unsigned / typedef names)."""
    size: int | None = None
    signed: bool | None = None


def merge_mods(old: Mods | None, new: Mods) -> Mods:
    if old is None:
        return new
    return Mods(
        new.size if new.size is not None else old.size,
        new.signed if new.signed is not None else old.signed,
    )


class FuncDef(NamedTuple):
    name: str
    params: list
    body: list
    returns: bool
    variadic: bool = False
    ret_size: int = 8


class ExternFunc(NamedTuple):
    name: str
    params: list
    returns: bool
    variadic: bool = False
    ret_size: int = 8


class StructDef(NamedTuple):
    name: str
    members: dict  # member name -> (offset, size)
    size: int      # total size in bytes, rounded up to 8



def error(message: str) -> NoReturn:
    print(f"\033[0;31m[Error]: {message}\033[0m", file=sys.stderr)
    sys.exit(1)


def warning(warn: str):
    print("\033[0;35m[Warn]:", warn, "\033[0m", file=sys.stderr)



# ---------------------------------------------------------------- lexer

LEX = re.compile(r"""
    (?P<ws>\s+|//[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*")
  | (?P<chr>'(?:\\.|[^'\\])')
  | (?P<num>-?(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|\d[\d_]*))
  | (?P<call>[A-Za-z_]\w*)\(
  | (?P<word>[A-Za-z_]\w*)
  | (?P<punct>->=|\.=|->|[\[\](){},=.:&])
""", re.X)

ESC = {
    "n": 10,
    "t": 9,
    "r": 13,
    "0": 0,
    "\\": 92,
    "'": 39,
    '"': 34,
}


def parse_num(text: str) -> int:
    t = text.replace("_", "")
    neg = t.startswith("-")

    if neg:
        t = t[1:]

    if t[:2].lower() in ("0x", "0b"):
        value = int(t, 0)
    else:
        value = int(t, 10)

    return -value if neg else value


def decode(body: str, line: int) -> bytes:
    out = bytearray()
    i = 0

    while i < len(body):
        c = body[i]

        if c == "\\":
            i += 1
            if i >= len(body) or body[i] not in ESC:
                error(f"Line {line}: bad escape sequence")
            out.append(ESC[body[i]])
        else:
            out.extend(c.encode())

        i += 1

    return bytes(out)


def lex(src: str):
    toks = []
    pos = 0
    line = 1

    while pos < len(src):
        match = LEX.match(src, pos)

        if not match:
            error(f"Line {line}: unexpected character {src[pos]!r}")

        kind = match.lastgroup

        if kind != "ws":
            toks.append((kind, match.group(kind), line))

        line += match.group().count("\n")
        pos = match.end()

    return toks


SIMPLE = {
    "add": OP.ADD,
    "sub": OP.SUB,
    "mul": OP.MUL,
    "div": OP.DIV,
    "mod": OP.MOD,
    "and": OP.AND,
    "or": OP.OR,
    "xor": OP.XOR,
    "shl": OP.SHL,
    "shr": OP.SHR,
    "not": OP.NOT,
    "neg": OP.NEG,
    "eq": OP.EQ,
    "ne": OP.NE,
    "lt": OP.LT,
    "gt": OP.GT,
    "le": OP.LE,
    "ge": OP.GE,
    "dup": OP.DUP,
    "swap": OP.SWAP,
    "nip": OP.NIP,
    "over": OP.OVER,
    "drop": OP.DROP,
    "dump": OP.DUMP,
    "dumpc": OP.DUMPC,
    "dumps": OP.DUMPS,
    "write": OP.WRITE,
    "read": OP.READ,
    "ret": OP.RET,
}

KEYWORDS = set(SIMPLE) | {
    "sized", "signed", "unsigned", "mutable", "while", "do",
    "if", "elif", "else", "end",
    "set", "extern", "void", "variadic",
    "typedef", "struct", "from",
    "as",
}

SIZES = (8, 16, 32, 64)


# --------------------------------------------------------------- parser

class Parser:
    def __init__(self, toks):
        self.toks = toks
        self.i = 0
        self.funcs: dict[str, FuncDef | None] = {}
        self.extern_vars: dict[str, int] = {}
        self.extern_funcs: dict[str, ExternFunc] = {}
        self.typedefs: dict[str, Mods] = {}
        self.structs: dict[str, StructDef] = {}

        self.in_func = False
        self.saw_ret = False
        self.ret_size = None
        self.explicit_size = False

    def peek(self):
        return self.toks[self.i] if self.i < len(self.toks) else None

    def at(self, index):
        if index < len(self.toks):
            return self.toks[index]
        return (None, None, None)

    def take(self):
        token = self.peek()

        if token is None:
            error("Unexpected end of file")

        self.i += 1
        return token

    def no_pending(self, pending, line):
        if pending:
            error(f"Line {line}: modifier (sized/signed/typedef) has nothing to apply to")

    @staticmethod
    def size_of(pending) -> int:
        return pending.size if pending and pending.size else 8

    def is_punct(self, text) -> bool:
        token = self.peek()
        return token is not None and token[0] == "punct" and token[1] == text

    def is_word(self, text) -> bool:
        token = self.peek()
        return token is not None and token[0] == "word" and token[1] == text

    def parse(self):
        tokens, _ = self.block(set())
        return (
            tokens, self.funcs, self.extern_vars,
            self.extern_funcs, self.structs, self.typedefs,
        )

    def modifier(self, kind, text, line) -> Mods | None:
        """If this token is a modifier, consume what it needs and return it."""
        if kind != "word":
            return None

        if text == "sized":
            number_kind, number, _ = self.take()

            if number_kind != "num" or parse_num(number) not in SIZES:
                error(f"Line {line}: sized needs 8, 16, 32 or 64")

            return Mods(parse_num(number) // 8, None)

        if text == "signed":
            return Mods(None, True)

        if text == "unsigned":
            return Mods(None, False)

        if text in self.typedefs:
            return self.typedefs[text]

        return None

    def block(self, stop: set):
        out: list[Token] = []
        pending: Mods | None = None

        while True:
            token = self.peek()

            if token is None:
                if stop:
                    error(
                        f"Unexpected end of file, expected "
                        f"{' or '.join(sorted(stop))}"
                    )
                return out, pending

            kind, text, line = token

            if kind in ("word", "punct") and text in stop:
                return out, pending

            self.i += 1

            mod = self.modifier(kind, text, line)

            if mod is not None:
                pending = merge_mods(pending, mod)
                continue

            size = self.size_of(pending)
            signed = bool(pending and pending.signed)
            self.explicit_size = bool(pending and pending.size)
            pending = None

            result = self.token(kind, text, line, size, signed)

            if result is not None:
                out.append(result)

    def token(self, kind, text, line, size, signed):
        if kind == "num":
            return Token(OP.PUSH, parse_num(text), size, signed, line)

        if kind == "chr":
            data = decode(text[1:-1], line)

            if len(data) != 1:
                error(f"Line {line}: bad character literal")

            return Token(OP.PUSH, data[0], 1, False, line)

        if kind == "str":
            return Token(OP.STR, (decode(text[1:-1], line), False), 8, False, line)

        if kind == "punct":
            if text == "[":
                return self.array(line, size, signed)

            if text in (".", "->", ".=", "->="):
                return self.member_access(text, line, size, signed)

            if text == "&":
                if self.is_punct("["):
                    self.take()
                    result = self.array(line, size, signed)

                    if result.type != OP.INDEX:
                        error(f"Line {line}: '&[...]' needs a single index, e.g. &[i] or &[i: type]")

                    return Token(OP.INDEX_ADDR, result.value, 8, False, line)

                nxt = self.peek()

                if (
                    nxt is not None and nxt[0] == "word"
                    and nxt[1] not in KEYWORDS
                    and nxt[1] not in self.typedefs
                    and nxt[1] not in self.structs
                ):
                    self.take()
                    return Token(OP.ADDR, nxt[1], 8, False, line)

                return Token(OP.ADDROF, None, 8, False, line)

            error(f"Line {line}: unexpected {text!r}")

        if kind == "call":
            return self.call_or_def(text, line, size, signed)

        if text in SIMPLE:
            if text == "ret":
                self.saw_ret = True

                if self.ret_size is None:
                    self.ret_size = size

            if text in ("read", "write") and self.is_word("as"):
                self.take()
                name_kind, name, name_line = self.take()

                if name_kind != "word" or name not in self.structs:
                    error(f"Line {name_line}: '{text} as' needs a struct name")

                return Token(
                    OP.DEREF if text == "read" else OP.STORE,
                    name, 8, False, line,
                )

            return Token(SIMPLE[text], None, size, signed, line)

        match text:
            case "mutable":
                string_kind, string, string_line = self.take()

                if string_kind != "str":
                    error(
                        f"Line {string_line}: "
                        "'mutable' must be followed by a string"
                    )

                return Token(
                    OP.STR,
                    (decode(string[1:-1], string_line), True),
                    8, False, line,
                )

            case "set":
                name_kind, name, name_line = self.take()

                if name_kind != "word" or name in KEYWORDS:
                    error(
                        f"Line {name_line}: "
                        "'set' must be followed by a variable name"
                    )

                return Token(OP.SET, name, size, signed, line)

            case "extern":
                self.extern(size, line)
                return None

            case "typedef":
                self.typedef(line)
                return None

            case "struct":
                self.struct_def(line)
                return None

            case "variadic":
                if self.in_func:
                    error(f"Line {line}: function definitions cannot be nested")

                name_kind, name, name_line = self.take()

                if name_kind != "call":
                    error(
                        f"Line {line}: 'variadic' must be followed by "
                        "a function definition, e.g. variadic f(sized 64 x)"
                    )

                self.define(name, name_line, variadic=True)
                return None

            case "while":
                cond, pending = self.block({"do"})
                self.no_pending(pending, line)
                self.take()

                body, pending = self.block({"end"})
                self.no_pending(pending, line)
                self.take()

                return Token(OP.WHILE, (cond, body), size, signed, line)

            case "if":
                return self.parse_if(line, size, signed)

            case "do" | "elif" | "else" | "end" | "void" | "from" | "as":
                error(f"Line {line}: unexpected '{text}'")

        if text in self.structs:
            return Token(OP.STRUCT_LIT, (text, self.parse_fields()), 8, False, line)

        nxt = self.peek()

        if nxt and nxt[0] == "word" and nxt[1] in self.structs:
            return self.struct_decl(text, line)

        return Token(OP.WORD, text, size if self.explicit_size else 0, signed, line)

    # ---- typedef / struct ------------------------------------------------

    def typedef(self, line):
        if self.in_func:
            error(f"Line {line}: typedef must be at file scope")

        name_kind, name, name_line = self.take()

        if name_kind != "word" or name in KEYWORDS:
            error(f"Line {name_line}: expected a type name after 'typedef'")

        if name in self.structs:
            error(f"Line {name_line}: type '{name}' already exists")

        mods = None

        while True:
            kind, text, mod_line = self.take()
            mod = self.modifier(kind, text, mod_line)

            if mod is None:
                error(f"Line {mod_line}: typedef needs 'sized 8/16/32/64'")

            mods = merge_mods(mods, mod)

            if mods.size is not None:
                break

        new = Mods(mods.size, mods.signed)

        if name in self.typedefs and self.typedefs[name] != new:
            error(f"Line {name_line}: typedef '{name}' redefined differently")

        self.typedefs[name] = new

    def struct_def(self, line):
        if self.in_func:
            error(f"Line {line}: struct must be defined at file scope")

        name_kind, name, name_line = self.take()

        if name_kind != "word" or name in KEYWORDS:
            error(f"Line {name_line}: expected a struct name")

        if name in self.structs or name in self.typedefs:
            error(f"Line {name_line}: type '{name}' already exists")

        members: dict[str, tuple[int, int]] = {}
        offset = 0
        pending = None

        while True:
            kind, text, member_line = self.take()

            if kind == "word" and text == "end":
                self.no_pending(pending, member_line)
                break

            mod = self.modifier(kind, text, member_line)

            if mod is not None:
                pending = merge_mods(pending, mod)
                continue

            if kind != "word" or text in KEYWORDS:
                error(f"Line {member_line}: expected a member name in struct {name}")

            if text in members:
                error(f"Line {member_line}: duplicate member '{text}' in struct {name}")

            member_size = self.size_of(pending)
            pending = None

            offset = (offset + member_size - 1) // member_size * member_size
            members[text] = (offset, member_size)
            offset += member_size

        if not members:
            error(f"Line {line}: struct {name} has no members")

        self.structs[name] = StructDef(name, members, (offset + 7) // 8 * 8)

    def parse_fields(self):
        """Optional { member = value, ... } after a struct name."""
        fields = []

        if not self.is_punct("{"):
            return fields

        self.take()

        if self.is_punct("}"):
            self.take()
            return fields

        while True:
            field_kind, field, field_line = self.take()

            if field_kind != "word":
                error(f"Line {field_line}: expected a member name")

            eq_kind, eq, eq_line = self.take()

            if eq_kind != "punct" or eq != "=":
                error(f"Line {eq_line}: expected '=' after '{field}'")

            toks, pending = self.block({",", "}"})
            self.no_pending(pending, field_line)

            if not toks:
                error(f"Line {field_line}: missing value for '{field}'")

            fields.append((field, toks, field_line))

            _, sep, _ = self.take()

            if sep == "}":
                return fields

    def struct_decl(self, var_name, line):
        """<var> <struct> [{ member = value, ... }]"""
        _, struct_name, _ = self.take()
        fields = self.parse_fields()
        return Token(OP.STRUCT_DECL, (var_name, struct_name, fields), 8, False, line)

    def member_and_from(self, line):
        member_kind, member, member_line = self.take()

        if member_kind != "word" or member in KEYWORDS:
            error(f"Line {member_line}: expected a member name")

        struct_name = None

        if self.is_word("from"):
            self.take()
            struct_kind, struct_name, struct_line = self.take()

            if struct_kind != "word":
                error(f"Line {struct_line}: expected a struct name after 'from'")

        return member, struct_name

    def member_access(self, text, line, size, signed):
        member, struct_name = self.member_and_from(line)
        op = {
            ".": OP.DOT,
            "->": OP.ARROW,
            ".=": OP.DOT_SET,
            "->=": OP.ARROW_SET,
        }[text]
        return Token(op, (member, struct_name), size, signed, line)

    # ---- control flow ----------------------------------------------------

    def parse_if(self, line, size, signed):
        branches = []

        while True:
            cond, pending = self.block({"do"})
            self.no_pending(pending, line)
            self.take()

            body, pending = self.block({"elif", "else", "end"})
            branches.append((cond, size, body))

            _, term, _ = self.take()

            if term == "elif":
                size = self.size_of(pending)
                continue

            self.no_pending(pending, line)

            if term == "else":
                body, pending = self.block({"end"})
                self.no_pending(pending, line)
                self.take()
                branches.append((None, 8, body))

            return Token(OP.IF, branches, 8, False, line)

    # ---- arrays ----------------------------------------------------------

    def operand(self):
        """One number / character / string / variable / function call."""
        pending = None

        while True:
            kind, text, line = self.take()
            mod = self.modifier(kind, text, line)

            if mod is None:
                break

            pending = merge_mods(pending, mod)

        result = None
        self.explicit_size = bool(pending and pending.size)

        if kind in ("num", "chr", "str", "call", "word"):
            result = self.token(
                kind, text, line,
                self.size_of(pending), bool(pending and pending.signed),
            )

        if result is None or result.type not in (OP.PUSH, OP.STR, OP.WORD, OP.CALL):
            error(f"Line {line}: expected a number, variable or function call")

        return result

    def index_token(self, operand, type_name, line, size, signed):
        if self.is_punct("="):
            self.take()
            value = self.operand()
            return Token(OP.INDEX_SET, (operand, type_name, value), size, signed, line)

        return Token(OP.INDEX, (operand, type_name), size, signed, line)

    def array(self, line, size, signed):
        """Called after '['.

        [a, b, 3, f(x)]   array literal (every element is an expression)
        [x]  [x: type]    index into the pointer on top of the stack
        [x]= v            index assignment
        A one element array literal needs a trailing comma: [x,]
        The old form [1 2 3] (only plain numbers) is still accepted."""
        elems = []
        commas = 0

        while True:
            toks, pending = self.block({",", "]", ":"})
            self.no_pending(pending, line)
            _, sep, _ = self.take()

            if sep == ":":
                type_kind, type_name, type_line = self.take()
                end_kind, end_text, end_line = self.take()

                if type_kind != "word" or end_text != "]":
                    error(f"Line {line}: expected [index: type]")

                if (
                    elems or len(toks) != 1
                    or toks[0].type not in (OP.PUSH, OP.WORD, OP.CALL)
                ):
                    error(
                        f"Line {line}: the index in [index: type] must be "
                        "a number, variable or function call"
                    )

                return self.index_token(toks[0], type_name, line, size, signed)

            if toks:
                if len(toks) > 1 and all(t.type == OP.PUSH for t in toks):
                    elems.extend([t] for t in toks)
                else:
                    elems.append(toks)
            elif not (sep == "]" and elems):
                error(f"Line {line}: empty array element")

            if sep == ",":
                commas += 1

            if sep == "]":
                break

        if (
            len(elems) == 1 and commas == 0 and len(elems[0]) == 1
            and elems[0][0].type in (OP.PUSH, OP.WORD, OP.CALL)
        ):
            return self.index_token(elems[0][0], None, line, size, signed)

        return Token(OP.ARRAY, elems, size, signed, line)

    # ---- functions -------------------------------------------------------

    def mod_width(self, j) -> int:
        kind, text, _ = self.at(j)

        if kind != "word":
            return 0

        if text == "sized":
            return 2

        if text in ("signed", "unsigned") or text in self.typedefs:
            return 1

        return 0

    def looks_like_def(self) -> bool:
        j = self.i

        if self.at(j)[0] == "punct" and self.at(j)[1] == ")":
            j += 1
        else:
            while True:
                while True:
                    width = self.mod_width(j)

                    if not width:
                        break

                    j += width

                kind, text, _ = self.at(j)

                if kind != "word" or text in KEYWORDS:
                    return False

                j += 1
                kind, text, _ = self.at(j)

                if kind == "punct" and text == ")":
                    j += 1
                    break

                if kind == "punct" and text == ",":
                    j += 1
                    continue

                return False

        depth = 0
        n = len(self.toks)

        while j < n:
            kind, text, _ = self.toks[j]
            j += 1

            if kind == "word":
                if text in ("while", "if"):
                    depth += 1
                elif text == "end":
                    if depth == 0:
                        return True
                    depth -= 1

        return False

    def parse_params(self, name: str, line: int):
        params = []

        if self.is_punct(")"):
            self.take()
            return params

        while True:
            pending = None

            while True:
                kind, text, param_line = self.take()
                mod = self.modifier(kind, text, param_line)

                if mod is None:
                    break

                pending = merge_mods(pending, mod)

            if kind != "word" or text in KEYWORDS:
                error(
                    f"Line {param_line}: "
                    f"expected a parameter name in {name}()"
                )

            if any(existing[0] == text for existing in params):
                error(f"Line {param_line}: duplicate parameter '{text}'")

            params.append((text, self.size_of(pending)))

            separator_kind, separator, separator_line = self.take()

            if separator_kind != "punct" or separator not in (",", ")"):
                error(
                    f"Line {separator_line}: "
                    f"expected ',' or ')' in {name}() parameters"
                )

            if separator == ")":
                break

        return params

    def call_or_def(self, name, line, size, signed):
        if name == "sizeof":
            type_kind, type_name, type_line = self.take()
            close_kind, close, _ = self.take()

            if type_kind != "word" or close != ")":
                error(f"Line {line}: expected sizeof(type)")

            return Token(OP.SIZEOF, type_name, 8, False, line)

        if name == "offsetof":
            struct_kind, struct_name, _ = self.take()
            comma_kind, comma, _ = self.take()
            member_kind, member, _ = self.take()
            close_kind, close, _ = self.take()

            if (
                struct_kind != "word" or comma != ","
                or member_kind != "word" or close != ")"
            ):
                error(f"Line {line}: expected offsetof(struct, member)")

            return Token(OP.OFFSETOF, (member, struct_name), 8, False, line)

        if (
            not self.in_func
            and name not in self.funcs
            and name not in self.extern_funcs
            and self.looks_like_def()
        ):
            self.define(name, line)
            return None

        args = []

        if self.is_punct(")"):
            self.take()
        else:
            while True:
                arg, pending = self.block({",", ")"})
                self.no_pending(pending, line)

                if not arg:
                    error(f"Line {line}: empty argument in call to {name}()")

                args.append(arg)
                _, separator, _ = self.take()

                if separator == ")":
                    break

        return Token(OP.CALL, (name, args), size, signed, line)

    def define(self, name, line, variadic=False):
        if name in self.extern_vars or name in self.extern_funcs:
            error(f"Line {line}: '{name}' was already declared extern")

        if name in self.funcs and self.funcs[name] is not None:
            error(f"Line {line}: duplicate function definition '{name}'")

        params = self.parse_params(name, line)

        self.funcs[name] = None

        saved = (self.in_func, self.saw_ret, self.ret_size)
        self.in_func, self.saw_ret, self.ret_size = True, False, None

        body, pending = self.block({"end"})
        self.no_pending(pending, line)
        self.take()

        self.funcs[name] = FuncDef(
            name, params, body, self.saw_ret, variadic, self.ret_size or 8
        )

        self.in_func, self.saw_ret, self.ret_size = saved

    def extern(self, size, line):
        if self.in_func:
            error(f"Line {line}: extern declarations must be at file scope")

        returns = True
        variadic = False
        ret_size = size

        while True:
            kind, name, name_line = self.take()

            mod = self.modifier(kind, name, name_line)

            if mod is not None:
                if mod.size is not None:
                    ret_size = mod.size

                continue

            if kind == "word" and name == "void":
                returns = False
                continue

            if kind == "word" and name == "variadic":
                variadic = True
                continue

            break

        if kind == "call":
            params = self.parse_params(name, line)

            if self.is_word("void"):
                self.take()
                returns = False

            if (
                name in self.funcs
                or name in self.extern_funcs
                or name in self.extern_vars
            ):
                error(f"Line {line}: duplicate external declaration '{name}'")

            if name == "main":
                error(
                    f"Line {line}: 'main' is reserved for "
                    "the generated program entry point"
                )

            self.extern_funcs[name] = ExternFunc(
                name, params, returns, variadic, ret_size
            )
            return

        if kind != "word" or name in KEYWORDS:
            error(
                f"Line {name_line}: "
                "expected an external variable or function name"
            )

        if not returns or variadic:
            error(
                f"Line {line}: 'void'/'variadic' can only be used "
                "with an external function"
            )

        if (
            name in self.funcs
            or name in self.extern_funcs
            or name in self.extern_vars
        ):
            error(f"Line {line}: duplicate external declaration '{name}'")

        self.extern_vars[name] = ret_size



def preprocess(
    path: Path,
    include_dirs: list[Path],
    defines: dict[str, str],
    once: set[Path] | None = None,
    active: set[Path] | None = None,
) -> str:
    if once is None:
        once = set()

    if active is None:
        active = set()

    path = path.resolve()

    if path in once:
        return ""

    if path in active:
        error(f"Include cycle involving '{path}'")

    try:
        source = path.read_text(encoding="utf-8")
    except OSError as exc:
        error(f"Cannot read '{path}': {exc}")

    if re.search(r"(?m)^\s*#\s*pragma\s+once\s*(?://.*)?$", source):
        once.add(path)

    active.add(path)
    output = []

    pattern = re.compile(
        r'"(?:\\.|[^"\\])*"|'
        r"'(?:\\.|[^'\\])*'|"
        r"//.*|"
        r"\d\w*|"
        r"[A-Za-z_]\w*"
    )

    def expand(line: str) -> str:
        def replace(match):
            token = match.group()

            if token[0] in "\"'/" or token[0].isdigit():
                return token

            return defines.get(token, token)

        return pattern.sub(replace, line)

    for line_number, line in enumerate(source.splitlines(keepends=True), 1):
        directive = re.match(r"^\s*#\s*(\w+)(.*)$", line)

        if not directive:
            output.append(expand(line))
            continue

        command, argument = directive.groups()
        argument = re.sub(r"\s*//.*$", "", argument).strip()

        if command == "define":
            match = re.fullmatch(r"([A-Za-z_]\w*)(?:\s+(.*))?", argument)

            if not match:
                error(f"{path}:{line_number}: invalid #define")

            name, value = match.groups()

            if name in defines:
                warning(f"{path}:{line_number}: redefining '{name}'")

            defines[name] = value if value is not None else ""

        elif command == "include":
            match = re.fullmatch(r'["<]([^">]+)[">]', argument)

            if not match:
                error(f"{path}:{line_number}: invalid #include")

            name = match.group(1)
            target = path.parent / name

            if not target.is_file():
                target = None

                for directory in include_dirs:
                    candidate = directory / name

                    if candidate.is_file():
                        target = candidate
                        break

            if target is None:
                error(
                    f"{path}:{line_number}: "
                    f"include file '{name}' not found"
                )

            output.append(
                preprocess(target, include_dirs, defines, once, active)
            )

        elif command == "pragma":
            if argument != "once":
                error(
                    f"{path}:{line_number}: "
                    f"unsupported #pragma '{argument}'"
                )

        else:
            error(f"{path}:{line_number}: unknown directive '#{command}'")

    active.remove(path)
    return "".join(output)


