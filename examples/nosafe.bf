// nosafe.bf -- a program written for --no-safe-slot
//
//   python bforth.py nosafe.bf -o nosafe.exe --no-safe-slot
//
// With --no-safe-slot every value on the stack has its real width, so the
// width modifiers must agree between the code that pushes a value and the
// code that pops it:  `char 1 char 2 char add char dump`.
// Expected output is written after each line.
// exact-width program for --no-safe-slot
#pragma requires_no_safe_slot
typedef char sized 8
typedef int signed sized 32
typedef long signed sized 64
extern malloc(sized 64 n)

struct point
    sized 64 x
    sized 64 y
end

struct mix
    char a
    int b
    sized 64 d
end

add3(a, b, c) a b c add add ret end
getc() 'A' char ret end
twice(sized 32 v) v int dup int add int ret end

char 200 char 100 char add char dump              // 44
int -7 int 2 int div int dump                     // -3
x 5
x 3 add set x
x dump                                            // 8
char b 250
b char 10 char add set b
b char dump                                       // 4
add3(1, 2, 3) dump                                // 6
getc() char dump                                  // 65
twice(int -21) int dump                           // -42
char 7 char dup char add char dump                // 14
1 2 swap sub dump                                 // 1
1 2 nip dump                                      // 2
1 2 over add add dump                             // 4
p point {x = 3, y = 4}
p -> y nip dump                                   // 4
10 p ->= x drop
p -> x nip dump                                   // 10
mp mix {a = 200, b = -5, d = 9}
char ma 0
mp -> a set ma
drop
ma char dump                                      // 200
mp -> d nip dump                                  // 9
arr [10, 20, 30]
arr [1: long] dump
sized 8 a2 [1, 2, 3]
a2 [2: char] char dump                            // 3
buf malloc(16)
buf 0x1122334455667788 write
buf sized 32 read int dump
