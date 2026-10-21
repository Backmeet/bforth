"""bforth front end: preprocessor, tokenizer and parser.

preprocess(path, include_dirs, defines) -> source text
lex(text)                               -> [(kind, text, line), ...]
Parser(tokens).parse()                  -> (tokens, funcs, extern_vars, extern_funcs, structs, typedefs)
"""
import re
import sys
import unicodedata
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
    ARRAY_UNINIT = enum()
    ROT = enum()
    ANTIROT = enum()
    FUNC_REF = enum()
    CALL_INDIRECT = enum()
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
  | (?P<raw>r"[^"]*")
  | (?P<str>"(?:\\[\s\S]|[^"\\])*")
  | (?P<chr>'(?:\\.|[^'\\])')
  | (?P<num>-?(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|\d[\d_]*))
  | (?P<call>[A-Za-z_]\w*)\(
  | (?P<word>[A-Za-z_]\w*)
  | (?P<punct>->=|\.=|->|[\[\](){},=.:&])
""", re.X)

ESC = {
    "a": 7,
    "b": 8,
    "f": 12,
    "n": 10,
    "t": 9,
    "r": 13,
    "0": 0,
    "v": 11,
    "?": 63,
    "e": 27,
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
            if i >= len(body):
                error(f"Line {line}: bad escape sequence")
            esc = body[i]
            if esc == "\n":
                pass
            elif esc == "N" and i + 1 < len(body) and body[i + 1] == "{":
                close = body.find("}", i + 2)
                if close < 0:
                    error(f"Line {line}: unterminated \\N Unicode escape")
                try:
                    out.extend(unicodedata.lookup(body[i + 2:close]).encode("utf-8"))
                except KeyError:
                    error(f"Line {line}: unknown Unicode character name")
                i = close
            elif esc in "01234567" and (esc != "0" or (i + 1 < len(body) and body[i + 1] in "01234567")):
                digits = esc
                while len(digits) < 3 and i + 1 < len(body) and body[i + 1] in "01234567":
                    i += 1
                    digits += body[i]
                out.append(int(digits, 8) & 0xff)
            elif esc in ESC:
                out.append(ESC[esc])
            elif esc == "x":
                digits = body[i + 1:i + 3]
                if len(digits) != 2 or not re.fullmatch(r"[0-9a-fA-F]{2}", digits):
                    error(f"Line {line}: \\x escape needs exactly two hex digits")
                out.append(int(digits, 16))
                i += 2
            elif esc in ("u", "U"):
                width = 4 if esc == "u" else 8
                digits = body[i + 1:i + 1 + width]
                if len(digits) != width or not re.fullmatch(rf"[0-9a-fA-F]{{{width}}}", digits):
                    error(f"Line {line}: \\{esc} escape needs {width} hex digits")
                try:
                    out.extend(chr(int(digits, 16)).encode("utf-8"))
                except ValueError:
                    error(f"Line {line}: invalid Unicode escape")
                i += width
            else:
                error(f"Line {line}: bad escape sequence \\{esc}")
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
    "rot": OP.ROT,
    "antirot": OP.ANTIROT,
}

KEYWORDS = set(SIMPLE) | {
    "sized", "signed", "unsigned", "mutable", "while", "for", "do",
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
                out.extend(result if isinstance(result, list) else [result])

    def token(self, kind, text, line, size, signed):
        if kind == "num":
            return Token(OP.PUSH, parse_num(text), size, signed, line)

        if kind == "chr":
            data = decode(text[1:-1], line)

            if len(data) != 1:
                error(f"Line {line}: bad character literal")

            return Token(OP.PUSH, data[0], 1, False, line)

        if kind in ("str", "raw"):
            if kind == "raw":
                return Token(OP.STR, (text[2:-1].encode("utf-8"), False), 8, False, line)
            return Token(OP.STR, (decode(text[1:-1], line), False), 8, False, line)

        if kind == "punct":
            if text == "(":
                if not self.is_punct(")"):
                    error(f"Line {line}: indirect calls use empty '()' syntax")
                self.take()
                return Token(OP.CALL_INDIRECT, None, size, signed, line)

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
            if text in ("rot", "antirot"):
                group = 3
                if self.is_word("with"):
                    self.take()
                    if not self.is_word("group"):
                        error(f"Line {line}: expected 'group N' after {text} with")
                    self.take()
                    group_kind, group_text, group_line = self.take()
                    if group_kind != "num":
                        error(f"Line {group_line}: rotation group must be an integer literal")
                    group = parse_num(group_text)
                    if not 3 <= group <= 64:
                        error(f"Line {group_line}: rotation group must be between 3 and 64")
                return Token(SIMPLE[text], group, size, signed, line)
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

            case "for":
                return self.for_loop(line, size, signed)

            case "if":
                return self.parse_if(line, size, signed)

            case "do" | "elif" | "else" | "end" | "void" | "from" | "as":
                error(f"Line {line}: unexpected '{text}'")

        if text in self.structs:
            return Token(OP.STRUCT_LIT, (text, self.parse_fields()), 8, False, line)

        if text in self.funcs:
            return Token(OP.FUNC_REF, text, 8, False, line)

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

    def for_loop(self, line, size, signed):
        """Lower both for syntaxes to an initialization and a while loop."""
        init, pending = self.block({",", "do"})
        self.no_pending(pending, line)
        _, separator, sep_line = self.take()
        if separator != ",":
            error(f"Line {sep_line}: expected ',' after for initializer")

        second, pending = self.block({",", "do"})
        self.no_pending(pending, line)
        _, separator, sep_line = self.take()

        if separator == ",":
            # C-like form: for init, cond, step do ... end
            cond = second
            step, pending = self.block({"do"})
            self.no_pending(pending, line)
            _, _, _ = self.take()
        elif separator == "do":
            # Counter form: for name start, end do ... end
            if len(init) < 2 or init[0].type != OP.WORD:
                error(f"Line {line}: counter form is 'for name start, end do'")
            name = init[0].value
            cond = [Token(OP.WORD, name, 0, False, line), *second,
                    Token(OP.LT, None, size, signed, line)]
            step = [Token(OP.WORD, name, 0, False, line),
                    Token(OP.PUSH, 1, size, signed, line),
                    Token(OP.ADD, None, size, signed, line),
                    Token(OP.SET, name, size, signed, line)]
        else:
            error(f"Line {sep_line}: expected ',' or 'do' in for loop")

        body, pending = self.block({"end"})
        self.no_pending(pending, line)
        self.take()
        return [*init, Token(OP.WHILE, (cond, [*body, *step]), size, signed, line)]

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

        if kind in ("num", "chr", "str", "raw", "call", "word"):
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

        # Repeated-element literal: [:: count : value].  An omitted value
        # initializes the array to zero, which is also the useful spelling
        # [:: count:].  Expand this in the AST so every backend gets the same
        # storage and initialization semantics as an ordinary literal.
        if self.is_punct(":"):
            self.take()
            if not self.is_punct(":"):
                error(f"Line {line}: expected '[:: count : value]'")
            self.take()
            count_kind, count_text, count_line = self.take()
            if count_kind != "num":
                error(f"Line {count_line}: array repeat count must be an integer literal")
            count = parse_num(count_text)
            if count < 0 or count > 1_000_000:
                error(f"Line {count_line}: array repeat count must be between 0 and 1000000")
            has_value_separator = self.is_punct(":")
            if has_value_separator:
                self.take()
            if self.is_punct("]"):
                self.take()
                if not has_value_separator:
                    return Token(OP.ARRAY_UNINIT, count, size, signed, line)
                value = Token(OP.PUSH, 0, size, signed, line)
            else:
                if not has_value_separator:
                    error(f"Line {count_line}: expected ']' or ':' after array repeat count")
                value = self.operand()
                if not self.is_punct("]"):
                    error(f"Line {line}: expected ']' after repeated array value")
                self.take()
            return Token(OP.ARRAY, [[value] for _ in range(count)], size, signed, line)

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
        if name == "consteval":
            expression, pending = self.block({")"})
            self.no_pending(pending, line)
            _, close, close_line = self.take()
            if close != ")":
                error(f"Line {close_line}: expected ')' after consteval expression")
            return self.consteval(expression, line)

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

    def consteval(self, expression: list[Token], line: int) -> Token:
        """Fold a pure, literal-only expression while parsing the source."""
        stack: list[Token] = []

        def integer(token: Token) -> int:
            if token.type != OP.PUSH:
                error(f"Line {token.line}: consteval operator needs integer literals")
            bits = token.size * 8
            value = int(token.value) & ((1 << bits) - 1)
            if token.signed and value & (1 << (bits - 1)):
                value -= 1 << bits
            return value

        binary = {
            OP.ADD, OP.SUB, OP.MUL, OP.DIV, OP.MOD,
            OP.AND, OP.OR, OP.XOR, OP.SHL, OP.SHR,
            OP.EQ, OP.NE, OP.LT, OP.GT, OP.LE, OP.GE,
        }
        for token in expression:
            if token.type in (OP.PUSH, OP.STR):
                stack.append(token)
                continue
            if token.type == OP.ARRAY:
                packed = bytearray()
                elem_size = token.size
                for element in token.value:
                    if len(element) != 1 or element[0].type != OP.PUSH:
                        error(f"Line {line}: consteval arrays currently require integer literal elements")
                    value = integer(element[0]) & ((1 << (elem_size * 8)) - 1)
                    packed.extend(value.to_bytes(elem_size, "little", signed=False))
                # A constant array is emitted as read-only static bytes.
                stack.append(Token(OP.STR, (bytes(packed), False), 8, False, line))
                continue
            if token.type in (OP.NEG, OP.NOT):
                if not stack:
                    error(f"Line {line}: consteval expression has too few operands")
                operand = integer(stack.pop())
                bits = token.size * 8
                mask = (1 << bits) - 1
                value = -operand if token.type == OP.NEG else ~operand
                value &= mask
                if token.signed and value & (1 << (bits - 1)):
                    value -= 1 << bits
                stack.append(Token(OP.PUSH, value, token.size, token.signed, line))
                continue
            if token.type not in binary:
                error(f"Line {line}: '{token.type.name.lower()}' is not allowed in consteval")
            if len(stack) < 2:
                error(f"Line {line}: consteval expression has too few operands")
            b, a = integer(stack.pop()), integer(stack.pop())
            bits = token.size * 8
            mask = (1 << bits) - 1
            signed_a, signed_b = a, b
            unsigned_a, unsigned_b = a & mask, b & mask
            if token.type == OP.ADD: value = a + b
            elif token.type == OP.SUB: value = a - b
            elif token.type == OP.MUL: value = a * b
            elif token.type == OP.DIV:
                if b == 0: error(f"Line {line}: division by zero in consteval")
                if token.signed:
                    value = (abs(a) // abs(b)) * (-1 if (a < 0) != (b < 0) else 1)
                else: value = unsigned_a // unsigned_b
            elif token.type == OP.MOD:
                if b == 0: error(f"Line {line}: division by zero in consteval")
                if token.signed:
                    q = (abs(a) // abs(b)) * (-1 if (a < 0) != (b < 0) else 1)
                    value = a - q * b
                else: value = unsigned_a % unsigned_b
            elif token.type == OP.AND: value = unsigned_a & unsigned_b
            elif token.type == OP.OR: value = unsigned_a | unsigned_b
            elif token.type == OP.XOR: value = unsigned_a ^ unsigned_b
            elif token.type == OP.SHL: value = unsigned_a << (unsigned_b & (bits - 1))
            elif token.type == OP.SHR: value = a >> (unsigned_b & (bits - 1)) if token.signed else unsigned_a >> (unsigned_b & (bits - 1))
            elif token.type == OP.EQ: value = int(a == b)
            elif token.type == OP.NE: value = int(a != b)
            elif token.type == OP.LT: value = int(signed_a < signed_b) if token.signed else int(unsigned_a < unsigned_b)
            elif token.type == OP.GT: value = int(signed_a > signed_b) if token.signed else int(unsigned_a > unsigned_b)
            elif token.type == OP.LE: value = int(signed_a <= signed_b) if token.signed else int(unsigned_a <= unsigned_b)
            else: value = int(signed_a >= signed_b) if token.signed else int(unsigned_a >= unsigned_b)
            if token.type not in (OP.EQ, OP.NE, OP.LT, OP.GT, OP.LE, OP.GE):
                value &= mask
                if token.signed and value & (1 << (bits - 1)):
                    value -= 1 << bits
            stack.append(Token(OP.PUSH, value, token.size, token.signed, line))

        if len(stack) != 1:
            error(f"Line {line}: consteval expression must produce exactly one value")
        return stack[0]


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



def optimize_tokens(tokens: list[Token], known_names=(), safe: bool = True) -> list[Token]:
    """Propagate immutable integer locals through a parsed token tree.

    This deliberately handles only literal integers and only variables that
    are never assigned or addressed. It is a small, semantics-preserving
    optimization suitable for the existing -O pipeline.
    """
    constants: dict[str, tuple[Token, int]] = {}
    declaration_ids: set[int] = set()
    assigned: set[str] = set()
    addressed: set[str] = set()
    declared: set[str] = set(known_names) | {"variadic_arr", "variadic_len"}

    def visit_lists(items):
        for seq in items:
            if not isinstance(seq, list):
                continue
            for i, token in enumerate(seq):
                if token.type == OP.WORD and i + 1 < len(seq) and seq[i + 1].type in (
                    OP.PUSH, OP.STR, OP.ARRAY, OP.ARRAY_UNINIT, OP.CALL,
                    OP.SIZEOF, OP.OFFSETOF, OP.ADDR, OP.FUNC_REF,
                ):
                    if token.value not in declared:
                        if seq[i + 1].type == OP.PUSH:
                            constants[token.value] = (seq[i + 1], token.size or 8)
                            declaration_ids.add(id(token))
                        declared.add(token.value)
                elif token.type == OP.SET:
                    assigned.add(token.value)
                elif token.type == OP.ADDR:
                    addressed.add(token.value)
                elif token.type == OP.CALL:
                    visit_lists(token.value[1])
                elif token.type == OP.IF:
                    for cond, _, body in token.value:
                        visit_lists([cond, body])
                elif token.type == OP.WHILE:
                    visit_lists(token.value)
                elif token.type in (OP.STRUCT_DECL, OP.STRUCT_LIT):
                    fields = token.value[-1]
                    visit_lists([toks for _, toks, _ in fields])

    visit_lists([tokens])
    constants = {name: value for name, value in constants.items()
                 if name not in assigned and name not in addressed}

    def transform(seq: list[Token]) -> list[Token]:
        out = []
        i = 0
        while i < len(seq):
            token = seq[i]
            if id(token) in declaration_ids:
                # Keep the declaration and its storage; only replace reads.
                out.append(token)
                i += 1
                continue
            if token.type == OP.WORD and token.value in constants:
                value, declared_size = constants[token.value]
                result_size = token.size or declared_size
                # Keep the literal's signed value and signedness exactly as
                # parsed. Masking it here changes signed narrow locals (e.g.
                # `int x -5`) into a different value before code generation.
                literal = Token(OP.PUSH, value.value, result_size,
                                value.signed, token.line)
                out.append(literal)
            elif token.type == OP.CALL:
                name, args = token.value
                out.append(token._replace(value=(name, [transform(arg) for arg in args])))
            elif token.type == OP.IF:
                branches = [(transform(cond) if cond is not None else None, size, transform(body))
                            for cond, size, body in token.value]
                out.append(token._replace(value=branches))
            elif token.type == OP.WHILE:
                cond, body = token.value
                out.append(token._replace(value=(transform(cond), transform(body))))
            elif token.type == OP.ARRAY:
                out.append(token._replace(value=[transform(element) for element in token.value]))
            elif token.type == OP.INDEX:
                operand, type_name = token.value
                out.append(token._replace(value=(transform([operand])[0], type_name)))
            elif token.type == OP.INDEX_SET:
                operand, type_name, value = token.value
                out.append(token._replace(value=(transform([operand])[0], type_name, transform([value])[0])))
            elif token.type == OP.INDEX_ADDR:
                operand, type_name = token.value
                out.append(token._replace(value=(transform([operand])[0], type_name)))
            elif token.type in (OP.STRUCT_DECL, OP.STRUCT_LIT):
                value = token.value
                fields = [(name, transform(toks), line) for name, toks, line in value[-1]]
                out.append(token._replace(value=(*value[:-1], fields)))
            else:
                out.append(token)
            i += 1
        return out

    return transform(tokens)


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
        def expand_callable(name: str, params: list[str], replacement: str, source: str, end: int):
            if end >= len(source) or source[end] != "(":
                return None
            depth = 0
            quote = None
            escaped = False
            start = end + 1
            pieces = []
            arg_start = start
            close = None
            for pos in range(start, len(source)):
                ch = source[pos]
                if quote:
                    if escaped:
                        escaped = False
                    elif ch == "\\":
                        escaped = True
                    elif ch == quote:
                        quote = None
                    continue
                if ch in "\"'":
                    quote = ch
                elif ch == "(":
                    depth += 1
                elif ch == ")":
                    if depth == 0:
                        pieces.append(source[arg_start:pos].strip())
                        close = pos
                        break
                    depth -= 1
                elif ch == "," and depth == 0:
                    pieces.append(source[arg_start:pos].strip())
                    arg_start = pos + 1
            if close is None:
                error(f"unterminated invocation of macro '{name}'")
            if len(pieces) == 1 and not pieces[0] and not params:
                pieces = []
            if len(pieces) != len(params):
                error(f"macro '{name}' expects {len(params)} argument(s), got {len(pieces)}")
            values = dict(zip(params, pieces))
            expanded = pattern.sub(lambda m: values.get(m.group(), m.group()), replacement)
            return expanded, close + 1

        def replace(match):
            token = match.group()

            if token[0] in "\"'/" or token[0].isdigit():
                return token

            value = defines.get(token, token)
            if isinstance(value, tuple):
                invoked = expand_callable(token, value[0], value[1], line, match.end())
                if invoked is not None:
                    expansion, end = invoked
                    return expansion + "\x00" + str(end)
            return value

        # Expand function-like invocations with balanced arguments, then object macros.
        cursor = 0
        out = []
        while cursor < len(line):
            match = pattern.match(line, cursor)
            if not match:
                out.append(line[cursor])
                cursor += 1
                continue
            token = match.group()
            if token[0] in "\"'/" or token[0].isdigit():
                out.append(token)
                cursor = match.end()
                continue
            value = defines.get(token)
            if isinstance(value, tuple):
                invocation = expand_callable(token, value[0], value[1], line, match.end())
                if invocation is not None:
                    expansion, cursor = invocation
                    out.append(expand(expansion))
                    continue
                out.append(token)
                cursor = match.end()
                continue
            out.append(str(value) if value is not None else token)
            cursor = match.end()
        return "".join(out)

    for line_number, line in enumerate(source.splitlines(keepends=True), 1):
        directive = re.match(r"^\s*#\s*(\w+)(.*)$", line)

        if not directive:
            output.append(expand(line))
            continue

        command, argument = directive.groups()
        argument = re.sub(r"\s*//.*$", "", argument).strip()

        if command == "define":
            match = re.fullmatch(r"([A-Za-z_]\w*)(?:\(([^)]*)\))?(?:\s+(.*))?", argument)

            if not match:
                error(f"{path}:{line_number}: invalid #define")

            name, params_text, value = match.groups()

            if name in defines:
                warning(f"{path}:{line_number}: redefining '{name}'")

            if params_text is None:
                defines[name] = value if value is not None else ""
            else:
                params = [part.strip() for part in params_text.split(",")] if params_text.strip() else []
                if any(not re.fullmatch(r"[A-Za-z_]\w*", item) for item in params) or len(set(params)) != len(params):
                    error(f"{path}:{line_number}: invalid callable macro parameters")
                defines[name] = (params, value if value is not None else "")

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
            if argument == "requires_no_safe_slot":
                output.append("// __bforth_requires_no_safe_slot__\n")
            elif argument == "requires_safe_slot":
                output.append("// __bforth_requires_safe_slot__\n")
            elif argument != "once":
                error(
                    f"{path}:{line_number}: "
                    f"unsupported #pragma '{argument}'"
                )

        else:
            error(f"{path}:{line_number}: unknown directive '#{command}'")

    active.remove(path)
    return "".join(output)


