"""Linux x86-64 back end (NASM `-f elf64`, System V AMD64 calling convention).

System V in short:
  * integer arguments 1-6 in RDI, RSI, RDX, RCX, R8, R9; the rest on the stack
  * no shadow space
  * RAX returns the result; calling a C variadic function needs AL = number of
    vector registers used (0 for us)
  * RBX RBP R12-R15 are callee-saved
  * externals are reached through the PLT / GOT so the result links as a PIE

bforth functions are only ever called by bforth code, so they may use any internal
convention.  Normal ones use System V.  Variadic ones receive *every* argument on
the stack so that named parameters, the hidden count and the extra arguments are
contiguous at [rbp + 16 + 8*i], the same layout the Windows back end builds by
homing registers.
"""
from codegen.base import Codegen, Var

ARG_REGISTERS = [
    ("RDI", "EDI", "DI", "DIL"),
    ("RSI", "ESI", "SI", "SIL"),
    ("RDX", "EDX", "DX", "DL"),
    ("RCX", "ECX", "CX", "CL"),
    ("R8", "R8D", "R8W", "R8B"),
    ("R9", "R9D", "R9W", "R9B"),
]


class LinuxCodegen(Codegen):
    ABI_NAME = "System V"
    ARG_REGS = ARG_REGISTERS
    SHADOW = 0
    FRAME_WHY = "reserve the stack arguments (+8 pad) so rsp is 16-byte aligned at the call"
    USER_VARIADIC_ON_STACK = True
    FAULT_LINE_REG = "edx"
    RODATA = ".rodata"
    OBJECT_FORMAT = "elf64"

    # ---- reaching externals --------------------------------------------------

    def ext_call(self, name):
        return f"${name} wrt ..plt"

    def ext_var_mem(self, name):
        self.emit(
            f"mov r11, [rel ${name} wrt ..got]",
            why=f"extern variable '{name}': load its address from the global offset table",
        )
        return "[r11]"

    def ext_var_addr(self, group, name):
        from codegen.base import rname

        self.emit(
            f"mov {rname(group, 8)}, [rel ${name} wrt ..got]",
            why=f"address of extern variable '{name}' (from the global offset table)",
        )

    def before_variadic_call(self):
        self.emit("xor eax, eax", why="System V: calling a variadic C function needs al = number of vector registers used (none)")

    # ---- parameters -----------------------------------------------------------

    def setup_params(self, params, variadic):
        nparams = len(params)

        if variadic:
            # every argument is on the stack: argument i is at [rbp+16+8*i]
            for index, (name, size) in enumerate(params):
                self.vars[name] = Var(16 + 8 * index, size, None, 8)

            self.canonicalise_stack_params(params, 0)
            return

        nregs = len(self.ARG_REGS)

        for index, (name, size) in enumerate(params):
            if index < nregs:
                # register arguments are not homed: spill them into locals
                var = self.declare(name, size)
                self.trunc(self.ARG_REGS[index], size)
                self.emit(
                    f"mov {self.mem(var.disp)}, {self.ARG_REGS[index][0].lower()}",
                    why=f"spill register argument {index} ({self.ARG_REGS[index][0].lower()}) into a local slot so it can be read and assigned like any variable",
                )
            else:
                self.vars[name] = Var(16 + 8 * (index - nregs), size, None, 8)

        self.canonicalise_stack_params(
            [p for i, p in enumerate(params) if i >= nregs],
            0,
        ) if nparams > nregs else None

    def fault_handler(self, name_label):
        return [
            ("lea rdi, [rel fmt_stack_fault]", "printf argument 1: the error message"),
            (f"lea rsi, [rel {name_label}]", "printf argument 2: the function's name (argument 3, the line, is in edx)"),
            ("and rsp, -16", "rsp may be anything here: align it for the call"),
            ("xor eax, eax", "variadic call: no vector registers used"),
            ("call $printf wrt ..plt", "print the error"),
            ("mov edi, 1", "exit code 1"),
            ("call $exit wrt ..plt", "crash: the function would have corrupted its caller's stack"),
        ]

    def trailer_lines(self):
        # tell the linker the stack does not need to be executable
        return ["", "section .note.GNU-stack noexec"]
