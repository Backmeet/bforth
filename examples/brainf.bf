// brainfuckinterpreter.bf -- a Brainfuck interpreter written in bforth.
//
//   > <   move the pointer        + -   change the cell      . ,   output / input a byte
//   [ ]   loop while the cell is not zero
//
// 30000 byte tape, cells wrap at 256.  The program is a C string.
#include "std.bf"

// run one Brainfuck program
bfrun(ptr_t code)
    tape calloc(30000, 1)
    ptr 0                       // tape position
    pc 0                        // position in the program
    len strlen(code)
    c 0                         // current instruction
    v 0                         // current cell
    depth 0                     // bracket nesting while skipping

    while pc len lt do
        code [pc: byte] set c

        if c '>' eq do
            ptr 1 add set ptr
        elif c '<' eq do
            ptr 1 sub set ptr
        elif c '+' eq do
            tape [ptr: byte] set v
            v 1 add set v
            tape [ptr: byte]= v
        elif c '-' eq do
            tape [ptr: byte] set v
            v 1 sub set v
            tape [ptr: byte]= v
        elif c '.' eq do
            putchar(tape [ptr: byte]) drop
        elif c ',' eq do
            getchar() set v
            if v 0xFFFFFFFF eq do 0 set v end      // end of input reads as 0
            tape [ptr: byte]= v
        elif c '[' eq do
            tape [ptr: byte] set v
            if v 0 eq do
                // cell is zero: skip forward to the matching ]
                1 set depth
                while depth 0 gt do
                    pc 1 add set pc
                    code [pc: byte] set c
                    if c '[' eq do depth 1 add set depth end
                    if c ']' eq do depth 1 sub set depth end
                end
            end
        elif c ']' eq do
            tape [ptr: byte] set v
            if v 0 ne do
                // cell is not zero: jump back to the matching [
                1 set depth
                while depth 0 gt do
                    pc 1 sub set pc
                    code [pc: byte] set c
                    if c ']' eq do depth 1 add set depth end
                    if c '[' eq do depth 1 sub set depth end
                end
            end
        end

        pc 1 add set pc
    end

    free(tape)
end

to_run input(">>")
bfrun(to_run)
free(to_run)

