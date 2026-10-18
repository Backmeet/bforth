"""Windows x64 back end (NASM `-f win64`, Microsoft x64 calling convention).

Microsoft x64 in short:
  * integer arguments 1-4 in RCX, RDX, R8, R9; the rest on the stack
  * the caller always reserves 32 bytes of "shadow space" above the return address
  * RAX returns the result; RBX RSI RDI RBP R12-R15 are callee-saved
  * variadic C functions take their arguments exactly like normal ones
"""
from codegen.base import Codegen

ARG_REGISTERS = [
    ("RCX", "ECX", "CX", "CL"),
    ("RDX", "EDX", "DX", "DL"),
    ("R8", "R8D", "R8W", "R8B"),
    ("R9", "R9D", "R9W", "R9B"),
]


class WindowsCodegen(Codegen):
    ABI_NAME = "Win64"
    ARG_REGS = ARG_REGISTERS
    SHADOW = 32
    FRAME_WHY = ("reserve {shadow} bytes of shadow space (required by Win64) + stack "
                 "arguments (+8 pad) so rsp is 16-byte aligned at the call")
    USER_VARIADIC_ON_STACK = False
    FAULT_LINE_REG = "r8d"
    RODATA = ".rdata"
    OBJECT_FORMAT = "win64"

    def setup_params(self, params, variadic):
        """The caller reserves 32 bytes of shadow space, so register arguments are
        homed there and every argument i lives at [rbp + 16 + 8*i]: named parameters,
        the hidden variadic count and the variadic arguments are all contiguous."""
        from codegen.base import Var

        nparams = len(params)
        homed = 4 if variadic else min(4, nparams)

        for i in range(homed):
            if i < nparams:
                self.trunc(self.ARG_REGS[i], params[i][1])

            self.emit(
                f"mov [rbp+{16 + 8 * i}], {self.ARG_REGS[i][0].lower()}",
                why=f"home register argument {i} in the caller-reserved shadow space so every argument is contiguous at [rbp+16+8*i]",
            )

        for index, (param_name, param_size) in enumerate(params):
            self.vars[param_name] = Var(16 + 8 * index, param_size, None, 8)

        self.canonicalise_stack_params(params, 4)

    def fault_handler(self, name_label):
        return [
            ("lea rcx, [rel fmt_stack_fault]", "printf argument 1: the error message"),
            (f"lea rdx, [rel {name_label}]", "printf argument 2: the function's name (argument 3, the line, is in r8d)"),
            ("and rsp, -16", "rsp may be anything here: align it for the call"),
            ("sub rsp, 32", "Win64 shadow space"),
            ("call $printf", "print the error"),
            ("mov ecx, 1", "exit code 1"),
            ("call $exit", "crash: the function would have corrupted its caller's stack"),
        ]
