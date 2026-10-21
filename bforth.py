#!/usr/bin/env python3
"""bforth: a small stack based language.

    python bforth.py program.bf                       build for this machine
    python bforth.py program.bf -t linux -s           NASM assembly for Linux
    python bforth.py program.bf -t llvm  -s           LLVM IR

This file only parses the command line and runs the stages:

    frontend.py            preprocess -> tokenize -> parse
    codegen/win.py         Windows x64  (NASM text)
    codegen/linux.py       Linux x86-64 (NASM text)
    codegen/llvm.py        LLVM IR
    codegen/base.py        shared by all code generators
    codegen/asmoptimizer.py  optional peephole optimizer for the NASM text
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from frontend import Parser, error, lex, optimize_tokens, preprocess  # noqa: E402, dam you pyright

SAMPLE = r"""
typedef char sized 8
typedef int signed sized 32
typedef long sized 64

struct point
    sized 64 x
    sized 64 y
end

variadic sum(first)
    total 0
    total first add set total
    i 0
    while i variadic_len lt do
        total variadic_arr i add read add set total
        i 8 add set i
    end
    total ret
end

sum(10, 1, 2, 3, 4, 5, 6) dump          // 31
0xFF dump                               // 255
int -7 int 2 int div int dump           // -3

p point {x = 3, y = 4}                  // p is a point*
p -> x nip dump                         // 3   (-> keeps p, nip drops it)
10 p ->= x drop                         // ->= keeps p too
p -> x nip dump                         // 10
p read as point . y nip nip dump        // read as: pointer -> struct bytes
p point {x = 7, y = 8} write as point   // write as: struct bytes -> pointer
p -> y nip dump                         // 8

buf [10, 20, 30]
buf [1: long] dump                      // 20
buf [2: long]= 99
buf [2: long] dump                      // 99
& buf 0 write                           // & name = address of a variable
"""



TARGETS = {"win": "win", "windows": "win", "linux": "linux", "llvm": "llvm"}


def host_target() -> str:
    return "win" if os.name == "nt" else "linux"


def load_backend(target: str):
    if target == "win":
        from codegen.win import WindowsCodegen
        return WindowsCodegen

    if target == "linux":
        from codegen.linux import LinuxCodegen
        return LinuxCodegen

    from codegen.llvm import LLVMCodegen
    return LLVMCodegen


def run_tool(command: list[str], what: str):
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError as exc:
        error(f"Required tool not found: {exc.filename} (needed to {what})")
    except subprocess.CalledProcessError as exc:
        error(f"{command[0]} failed with exit code {exc.returncode}")


def build(target: str, text: str, output_path: Path, freestanding: bool = False):
    """Turn the generated text into an executable with the external tools."""
    suffix = ".ll" if target == "llvm" else ".asm"
    work = Path(tempfile.mkdtemp(prefix="bforth_"))
    source_file = work / ("prog" + suffix)
    object_file = work / "prog.o"
    source_file.write_text(text, encoding="utf-8")

    try:
        if target == "llvm":
            compiler = shutil.which("clang") or shutil.which("cc")

            if compiler is None:
                error("Required tool not found: clang (needed to compile the LLVM IR)")

            command = [compiler, "-Wno-override-module", str(source_file), "-o", str(output_path)]
            if freestanding:
                command[1:1] = ["-ffreestanding", "-nostdlib", "-nodefaultlibs", "-nostartfiles"]
                command.extend(["-Wl,-e,main"])
            run_tool(command, "compile the LLVM IR")
        else:
            fmt = "win64" if target == "win" else "elf64"
            run_tool(["nasm", "-f", fmt, "-o", str(object_file), str(source_file)], "assemble")
            command = ["gcc", str(object_file), "-o", str(output_path)]
            if freestanding:
                command[1:1] = ["-ffreestanding", "-nostdlib", "-nodefaultlibs", "-nostartfiles"]
                command.append("-Wl,-e,main")
            run_tool(command, "link")
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print(f"Built {output_path}")


def emit_object(target: str, text: str, output_path: Path):
    """Write a native object file without leaving intermediate assembly behind."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="bforth_obj_", dir=str(output_path.parent)))
    suffix = ".ll" if target == "llvm" else ".asm"
    source_file = work / ("prog" + suffix)
    source_file.write_text(text, encoding="utf-8")
    try:
        if target == "llvm":
            compiler = shutil.which("clang") or shutil.which("cc")
            if compiler is None:
                error("Required tool not found: clang (needed to compile LLVM IR)")
            run_tool([compiler, "-Wno-override-module", "-c", str(source_file), "-o", str(output_path)], "compile the LLVM IR to an object")
        else:
            fmt = "win64" if target == "win" else "elf64"
            run_tool(["nasm", "-f", fmt, "-o", str(output_path), str(source_file)], "assemble to an object")
    finally:
        shutil.rmtree(work, ignore_errors=True)
    print(f"Generated object {output_path}")


def main(argv=None):
    argp = argparse.ArgumentParser(
        description="bforth compiler: .bf source -> Windows / Linux executables or LLVM IR."
    )
    argp.add_argument("source", nargs="?", help="Input source file")
    argp.add_argument("-o", metavar="FILE", help="Output file")
    argp.add_argument("-s", action="store_true", help="Generate assembly / LLVM IR only")
    argp.add_argument("-c", "--object", action="store_true",
                      help="Generate an unlinked native .o object file (may contain unresolved externals)")
    argp.add_argument("--freestanding", action="store_true",
                      help="Link without startup files or default libraries (-ffreestanding -nostdlib)")
    argp.add_argument("-t", "--target", choices=sorted(TARGETS), default=None,
                      help="win | linux | llvm (default: the machine you run on)")
    argp.add_argument("-C", "--comments", action="store_true",
                      help="Annotate the output: what every instruction does and why it is there")
    argp.add_argument("-O", "--optimize", action="store_true",
                      help="Run the assembly optimizer (win / linux targets)")
    argp.add_argument("--no-safe-slot", dest="no_safe_slot", action="store_true",
                      help="Give every stack value its real size instead of a full 8-byte slot; "
                           "stack imbalances become warnings and underflows are caught at run time")
    argp.add_argument("-I", dest="include_dirs", action="append", default=[], metavar="DIR",
                      help="Add an include directory")
    argp.add_argument("-D", dest="defines", action="append", default=[], metavar="NAME[=VALUE]",
                      help="Define a preprocessor constant")
    args = argp.parse_args(argv)

    if args.s and args.object:
        argp.error("-s and -c/--object cannot be used together")

    if args.source is None and args.o is not None:
        argp.error("an input source file is required when using -o")

    target = TARGETS[args.target] if args.target else host_target()
    source_path = Path(args.source).resolve() if args.source else None

    # ---- stage 1: preprocess, tokenize, parse ---------------------------------
    if source_path is None:
        source = SAMPLE
    else:
        defines = {}

        for definition in args.defines:
            name, separator, value = definition.partition("=")

            if not re.fullmatch(r"[A-Za-z_]\w*", name):
                argp.error(f"invalid definition: {definition}")

            defines[name] = value if separator else "1"

        try:
            source = preprocess(
                source_path,
                [Path(directory).resolve() for directory in args.include_dirs],
                defines,
            )
        except RecursionError:
            error("Preprocessor recursion limit exceeded")

    requires_unsafe = "__bforth_requires_no_safe_slot__" in source
    requires_safe = "__bforth_requires_safe_slot__" in source
    if requires_unsafe and requires_safe:
        error("source includes conflicting safe-slot requirements")
    if requires_unsafe and not args.no_safe_slot:
        error("this source requires --no-safe-slot (#pragma requires_no_safe_slot)")
    if requires_safe and args.no_safe_slot:
        error("this source requires safe slots (#pragma requires_safe_slot)")

    main_tokens, funcs, extern_vars, extern_funcs, structs, typedefs = Parser(lex(source)).parse()

    if args.optimize:
        known_names = set(extern_vars) | set(extern_funcs) | set(funcs)
        main_tokens = optimize_tokens(main_tokens, known_names, safe=not args.no_safe_slot)
        for name, function in list(funcs.items()):
            if function is not None:
                params = {parameter for parameter, _ in function.params}
                funcs[name] = function._replace(body=optimize_tokens(
                    function.body, known_names | params, safe=not args.no_safe_slot
                ))

    # ---- stage 2: code generation ------------------------------------------------
    backend = load_backend(target)
    generator = backend(
        funcs, extern_vars, extern_funcs, structs, typedefs,
        comments=args.comments, safe=not args.no_safe_slot,
    )
    text = generator.generate(main_tokens)

    # ---- stage 3: optional assembly optimization -------------------------------------
    if args.optimize and target != "llvm":
        from codegen.asmoptimizer import optimize
        stats = {}
        text = optimize(text, comments=args.comments, stats=stats)
        print(f"optimizer: {stats['before']} -> {stats['after']} instructions "
              f"({stats['before'] - stats['after']} removed)", file=sys.stderr)
    elif args.optimize:
        print("note: -O only applies to the assembly targets; run LLVM's own optimizer (opt / clang -O2) on the IR",
              file=sys.stderr)

    # ---- stage 4: write / build ------------------------------------------------------
    asm_suffix = ".ll" if target == "llvm" else ".asm"
    exe_suffix = ".exe" if target == "win" else ""

    if args.o:
        output_path = Path(args.o)
    elif source_path:
        output_path = source_path.with_suffix(asm_suffix if args.s else exe_suffix)
    else:
        output_path = Path("output" + (asm_suffix if args.s else exe_suffix))

    if args.object:
        if args.o:
            object_path = Path(args.o)
        elif source_path:
            object_path = source_path.with_suffix(".o")
        else:
            object_path = Path("output.o")
        emit_object(target, text, object_path)
        return 0

    if args.s:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(text, encoding="utf-8")
        print(f"Generated {output_path}")
        return 0

    build(target, text, output_path, freestanding=args.freestanding)
    return 0


if __name__ == "__main__":
    sys.exit(main())
