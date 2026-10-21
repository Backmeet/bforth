// =====================================================================
//  test.bf -- exercises every feature of the language and every
//  function of std.bf.  Prints a line only for failures, then a summary;
//  the process exit code is 1 if anything failed.
// =====================================================================
#include "std.bf"
#include "std.bf"          // #pragma once: the second include is empty
#pragma requires_safe_slot

#define TEN 10
#define MASK 0xFF
#define DOUBLE(x) x x add
#define COMPILE_TIME(x) consteval(x)
#define CHECK check(results,

struct point
    sized 64 x
    sized 64 y
end

struct mix
    byte a
    int b
    short c
    sized 64 d
end

struct ida
    sized 64 id
    sized 64 pad
end

struct idb
    byte id
    sized 64 extra
end

// ---- test helpers (results[0] = passed, results[1] = failed) ----------

check(r, name, got, want)
    if got want eq do
        n 0
        r [0: long] set n
        n 1 add set n
        r [0: long]= n
    else
        m 0
        r [1: long] set m
        m 1 add set m
        r [1: long]= m
        printf("FAIL %s: got %lld, want %lld\n", name, got, want) drop
    end
end

checkstr(r, name, got, want)
    check(r, name, strcmp(got, want) 0 eq, 1)
end

// ---- functions used by the tests --------------------------------------

add3(a, b, c) a b c add add ret end
answer() 42 ret end
square(n) n n mul ret end
constant_argument()
    constant_value 7
    square(constant_value) ret
end

fact(n)
    if n 2 lt do 1 ret end
    n fact(n 1 sub) mul ret
end

six(a, b, c, d, e, f) a b sub c sub d sub e sub f sub ret end

eight(a, b, c, d, e, f, g, h) a b sub c sub d sub e sub f sub g sub h sub ret end

small(sized 8 a, sized 32 b, c, d, e) a b add c add d add e add ret end

bump(ptr) ptr ptr read 1 add write end

bump2(ptr) bump(ptr) bump(ptr) end

firstsq(limit)
    i 0
    while i limit lt do
        if i i mul 50 gt do i ret end
        i 1 add set i
    end
    0 ret
end

getx(p) p -> x from point nip ret end

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

variadic countv(a) variadic_len 8 div ret end

variadic lastv(a, b)
    if variadic_len 0 eq do 0 ret end
    variadic_arr variadic_len add 8 sub read ret
end

// =====================================================================
results [0, 0]
sb0 malloc(64)

"-- dump family --" dumps
42 dump
int -5 int dump
char 200 dump
-1 signed dump
'!' dumpc
10 dumpc
"dumps ok" dumps

// ---- literals ----------------------------------------------------------
CHECK "callable macro", DOUBLE(9), 18)
bool boolean_value 1
CHECK "bool byte type", boolean_value, 1)
checkstr(results, "string join", string_join("bf", "orth"), "bforth")
checkstr(results, "path basename", path_basename(r"C:\\work/example.bf"), "example.bf")
checkstr(results, "path dirname", path_dirname(r"C:\work\example.bf"), r"C:\work")
checkstr(results, "path join", path_join("folder", "file.bf"), "folder/file.bf")
print("printf macro: %d\n", 7) drop
CHECK "consteval arithmetic", consteval(2 3 add 4 mul), 20)
CHECK "consteval through macro", COMPILE_TIME(5 6 mul), 30)
checkstr(results, "consteval string", consteval("folded"), "folded")
CHECK "consteval array", consteval([7, 8, 9]) [2: long], 9)
CHECK "dec", 42, 42)
CHECK "hex lower", 0xff, 255)
CHECK "hex mixed", 0xdeadBEEF, 3735928559)
CHECK "bin", 0b1010, 10)
CHECK "underscores", 1_000_000, 1000000)
CHECK "bin underscores", 0b1111_0000, 240)
CHECK "hex underscores", 0xFF_FF, 65535)
CHECK "char", 'A', 65)
CHECK "char escape n", '\n', 10)
CHECK "char escape quote", '\'', 39)
CHECK "char escape nul", '\0', 0)
CHECK "neg 64", -1, 0xFFFFFFFFFFFFFFFF)
CHECK "neg 32", int -1, 0xFFFFFFFF)
CHECK "neg 8", char -1, 255)
CHECK "max u64", 18446744073709551615, 0xFFFFFFFFFFFFFFFF)
CHECK "define", TEN, 10)
CHECK "define hex", MASK, 255)
CHECK "string first byte", "hello" sized 8 read, 104)
CHECK "string escape", "a\tb" 1 add sized 8 read, 9)
CHECK "string length", strlen("hello\n"), 6)

// ---- 64-bit arithmetic -------------------------------------------------
CHECK "add", 7 3 add, 10)
CHECK "sub", 7 3 sub, 4)
CHECK "sub wraps", 3 7 sub, -4)
CHECK "mul", 7 3 mul, 21)
CHECK "div", 7 3 div, 2)
CHECK "mod", 7 3 mod, 1)
CHECK "and", 12 10 and, 8)
CHECK "or", 12 10 or, 14)
CHECK "xor", 12 10 xor, 6)
CHECK "shl", 1 10 shl, 1024)
CHECK "shr", 1024 3 shr, 128)
CHECK "not", 0 not, -1)
CHECK "neg", 5 neg, -5)
CHECK "mul overflow", 4294967296 4294967296 mul, 0)
CHECK "unsigned div", 0xFFFFFFFFFFFFFFFF 2 div, 0x7FFFFFFFFFFFFFFF)
CHECK "signed div", -9 2 signed div, -4)
CHECK "signed mod", -9 2 signed mod, -1)
CHECK "signed mul", -3 5 signed mul, -15)
CHECK "signed shr", -16 2 signed shr, -4)
CHECK "unsigned shr", -16 2 shr, 0x3FFFFFFFFFFFFFFC)

// ---- sized / signed arithmetic ----------------------------------------
CHECK "u8 add wraps", char 200 char 100 char add, char 44)
CHECK "u8 sub wraps", char 5 char 10 char sub, char 251)
CHECK "u8 mul", char 20 char 20 char mul, char 144)
CHECK "u8 div", char 200 char 7 div, char 28)
CHECK "u8 mod", char 200 char 7 mod, char 4)
CHECK "i8 div", signed char -7 signed char 2 signed char div, char -3)
CHECK "i8 mod", signed char -7 signed char 2 signed char mod, char -1)
CHECK "i8 mul", signed char -7 signed char 3 signed char mul, char -21)
CHECK "i16 mul", short -2 short 3 short mul, short -6)
CHECK "u16 div", ushort 65535 ushort 2 ushort div, ushort 32767)
CHECK "i32 div", int -7 int 2 int div, int -3)
CHECK "i32 mod", int -7 int 2 int mod, int -1)
CHECK "u32 div of -7", int -7 int 2 uint div, uint 2147483644)
CHECK "i32 sar", int -16 2 int shr, int -4)
CHECK "u32 shr", int -16 2 uint shr, uint 1073741820)
CHECK "u8 shl", char 129 1 char shl, char 2)
CHECK "i8 sar", signed char -128 1 signed char shr, char -64)
CHECK "u16 shl", ushort 1 15 ushort shl, ushort 32768)
CHECK "u8 and", char 0xF0 char 0x3C and, char 0x30)
CHECK "u8 or", char 0xF0 char 0x3C or, char 0xFC)
CHECK "u8 xor", char 0xF0 char 0x3C xor, char 0xCC)
CHECK "u8 not", char 0 char not, char 255)
CHECK "u8 neg", char 1 char neg, char 255)
CHECK "i32 neg", int 1 int neg, int -1)

// ---- comparisons ---------------------------------------------------------
CHECK "eq", 5 5 eq, 1)
CHECK "ne", 5 6 ne, 1)
CHECK "lt", 3 5 lt, 1)
CHECK "gt", 5 3 gt, 1)
CHECK "le equal", 5 5 le, 1)
CHECK "ge equal", 5 5 ge, 1)
CHECK "lt false", 5 3 lt, 0)
CHECK "ge false", 3 5 ge, 0)
CHECK "i32 -1 < 1", int -1 int 1 int lt, 1)
CHECK "u32 -1 < 1", int -1 int 1 uint lt, 0)
CHECK "i64 -1 < 1", -1 1 signed lt, 1)
CHECK "u64 -1 < 1", -1 1 lt, 0)
CHECK "i8 gt", signed char -1 char 1 signed char gt, 0)
CHECK "i16 le", short -5 short -5 short le, 1)
CHECK "i32 ge", int -2 int -3 int ge, 1)
CHECK "u8 ne", char 255 char 255 ne, 0)

// ---- stack operators -----------------------------------------------------
CHECK "dup", 5 dup mul, 25)
CHECK "drop", 1 2 drop, 1)
CHECK "swap", 1 2 swap sub, 1)
CHECK "over", 1 2 over add add, 4)
CHECK "nip", 1 2 nip, 2)
CHECK "rot reverses three", 1 2 3 rot drop drop, 3)
CHECK "antirot three", 1 2 3 antirot drop drop, 2)
CHECK "rot group five", 1 2 3 4 5 rot with group 5 drop drop drop drop, 5)
CHECK "antirot group five", 1 2 3 4 5 antirot with group 5 drop drop drop drop, 2)

// ---- variables -------------------------------------------------------------
v1 5
v1 3 add set v1
CHECK "var set", v1, 8)
byte v2 250
v2 10 add set v2
CHECK "byte var wraps", v2, 4)
sized 16 v3 65535
v3 1 add set v3
CHECK "16-bit var wraps", v3, 0)
int v4 -5
CHECK "int var", v4, 0xFFFFFFFB)
v5 add3(1, 2, 3)
CHECK "var from call", v5, 6)
v6 "text"
checkstr(results, "var from string", v6, "text")
& v1 99 write
CHECK "& var", v1, 99)
CHECK "bare &", 7 & read nip, 7)
CHECK "bare & write", 1 & 9 write, 9)

// ---- control flow ------------------------------------------------------------
for_sum 0
for for_counter 0, 5 do
    for_sum for_counter add set for_sum
end
CHECK "counter for loop", for_sum, 10)
for_c_sum 0
for for_c_init 0, for_c_init 5 lt, for_c_init 1 add set for_c_init do
    for_c_sum for_c_init add set for_c_sum
end
CHECK "three-part for loop", for_c_sum, 10)
f1 0
if 5 3 gt do 1 set f1 end
CHECK "if true", f1, 1)
f2 0
if 3 5 gt do 1 set f2 end
CHECK "if false", f2, 0)
f3 0
if 1 0 eq do 1 set f3 elif 2 2 eq do 2 set f3 else 3 set f3 end
CHECK "elif", f3, 2)
f4 0
if 1 0 eq do 1 set f4 elif 2 3 eq do 2 set f4 else 3 set f4 end
CHECK "else", f4, 3)
f5 0
if 1 do if 0 do 1 set f5 else 2 set f5 end end
CHECK "nested if", f5, 2)
w1 0
w2 0
while w1 10 lt do
    w2 w1 add set w2
    w1 1 add set w1
end
CHECK "while", w2, 45)
w3 0
w4 0
while w3 3 lt do
    w5 0
    while w5 3 lt do w4 1 add set w4 w5 1 add set w5 end
    w3 1 add set w3
end
CHECK "nested while", w4, 9)
sized 8 w6 3
w7 0
while w6 do w7 1 add set w7 w6 1 sub set w6 end
CHECK "while on byte", w7, 3)

// ---- functions -----------------------------------------------------------------
CHECK "call", add3(1, 2, 3), 6)
CHECK "function pointer call", answer (), 42)
answer_ptr answer
CHECK "function pointer variable", answer_ptr () , 42)
CHECK "constant propagation into call", constant_argument(), 49)
CHECK "nested calls", add3(add3(1, 2, 3), add3(4, 5, 6), add3(7, 8, 9)), 45)
CHECK "recursion", fact(5), 120)
CHECK "recursion big", fact(10), 3628800)
CHECK "ret inside loops", firstsq(100), 8)
CHECK "ret fallthrough", firstsq(5), 0)
CHECK "6 params", six(100, 1, 2, 3, 4, 5), 85)
CHECK "8 params", eight(100, 1, 2, 3, 4, 5, 6, 7), 72)
CHECK "param truncation", small(0x1FF, 0x100000001, 0, 0, 0), 256)
CHECK "small params", small(255, 1, 1, 1, 1), 259)
cnt 5
bump(& cnt)
CHECK "void function", cnt, 6)
bump2(& cnt)
CHECK "void calls void", cnt, 8)
CHECK "call with stack depth", 1 2 3 add3(1, 2, 3) add add add, 12)
CHECK "variadic 0 extra", sum(1), 1)
CHECK "variadic 1 extra", sum(1, 2), 3)
CHECK "variadic 2 extra", sum(1, 2, 3), 6)
CHECK "variadic spills to stack", sum(1, 2, 3, 4), 10)
CHECK "variadic many", sum(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 55)
CHECK "variadic call args", sum(add3(1, 2, 3), fact(4), 10), 40)
CHECK "variadic_len none", countv(0), 0)
CHECK "variadic_len", countv(0, 1, 2, 3), 3)
CHECK "variadic last", lastv(0, 1, 9, 8, 7), 7)
CHECK "variadic last none", lastv(0, 1), 0)
CHECK "extern variadic", printf("printf: %s %d\n", "ok", 7), int 13)
CHECK "extern variadic 8 args", sprintf(sb0, "%d%d%d%d%d%d", 1, 2, 3, 4, 5, 6), int 6)

// ---- raw memory: read / write -----------------------------------------------------
buf malloc(32)
buf 0x1122334455667788 write
CHECK "write/read 64", buf read, 0x1122334455667788)
CHECK "read 32", buf sized 32 read, 0x55667788)
CHECK "read 16", buf sized 16 read, 0x7788)
CHECK "read 8", buf sized 8 read, 0x88)
CHECK "read offset", buf 7 add sized 8 read, 0x11)
buf 0xAB sized 8 write
CHECK "write 8 keeps rest", buf read, 0x11223344556677AB)
buf 0xBEEF sized 16 write
CHECK "write 16", buf read, 0x112233445566BEEF)
buf 0xCAFEBABE sized 32 write
CHECK "write 32", buf read, 0x11223344CAFEBABE)
ms mutable "Hello"
ms sized 8 [0]= 'J'
checkstr(results, "mutable string", ms, "Jello")
mutable "Hello, World" dup 'J' sized 8 write dumps

// ---- arrays ------------------------------------------------------------------------
a1 [10, 20, 30]
CHECK "array [0]", a1 [0], 10)
CHECK "array [8]", a1 [8], 20)
CHECK "array [1: long]", a1 [1: long], 20)
CHECK "array [2: long]", a1 [2: long], 30)
bv 2
CHECK "index by var", a1 [bv: long], 30)
CHECK "index by call", a1 [add3(0, 1, 0): long], 20)
a2 [bv, add3(1, 2, 3), bv 1 add, fact(3)]
CHECK "array of var", a2 [0: long], 2)
CHECK "array of call", a2 [1: long], 6)
CHECK "array of expr", a2 [2: long], 3)
CHECK "array of recursion", a2 [3: long], 6)
a3 [7,]
CHECK "one element array", a3 [0: long], 7)
sized 8 a4 [1, 2, 3]
CHECK "byte array", a4 [2: byte], 3)
CHECK "byte read, no type", a4 sized 8 [1], 2)
sized 8 a5 [72 105 0]
checkstr(results, "legacy array", a5, "Hi")
int a6 [1, -2, 3]
CHECK "int array", a6 [1: int], int -2)
CHECK "int array neighbour", a6 [2: int], 3)
sized 8 zeros [:: 1000 :]
CHECK "zero repeat array first", zeros sized 8 [0], 0)
CHECK "zero repeat array last", zeros sized 8 [999], 0)
sized 8 tens [:: 1000 : 10]
CHECK "value repeat array first", tens sized 8 [0], 10)
CHECK "value repeat array last", tens sized 8 [999], 10)
sized 8 uninitialized [:: 32]
CHECK "uninitialized repeat array pointer", uninitialized 0 ne, 1)
CHECK "raw string backslash", strlen(r"a\nb"), 4)
CHECK "raw string slash byte", r"a\nb" 1 add sized 8 read, 92)
CHECK "C escape alert", "\a" sized 8 read, 7)
CHECK "C escape backspace", "\b" sized 8 read, 8)
CHECK "C escape form feed", "\f" sized 8 read, 12)
CHECK "C escape vertical tab", "\v" sized 8 read, 11)
CHECK "hex escape", "\x41" sized 8 read, 65)
CHECK "unicode escape", "\u0042" sized 8 read, 66)
CHECK "wide unicode escape", "\U00000043" sized 8 read, 67)
CHECK "named unicode escape", "\N{LATIN SMALL LETTER D}" sized 8 read, 100)

// ---- index operators -----------------------------------------------------------------
a1 [0: long]= 0x1122
CHECK "[i: type]=", a1 [0: long], 0x1122)
a1 [8]= 222
CHECK "[i]=", a1 [1: long], 222)
a1 sized 8 [1]= 0xFF
CHECK "[i]= sized", a1 [0: long], 0xFF22)
idx 2
a1 [idx: long]= bv
CHECK "[var: type]= var", a1 [2: long], 2)
a1 [add3(0, 0, 2): long]= add3(5, 5, 5)
CHECK "[call: type]= call", a1 [2: long], 15)
a1 [1: long]= 30
CHECK "&[i]", a1 &[16] read, 15)
CHECK "&[i] addr", a1 &[16] a1 sub, 16)
CHECK "&[i: type]", a1 &[2: long] read, 15)
CHECK "&[i: type] addr", a1 &[2: long] a1 sub, 16)
CHECK "&[i: byte] addr", a4 &[2: byte] a4 sub, 2)
CHECK "&[var: type]", a1 &[idx: long] a1 sub, 16)

// ---- typedef / sizeof / offsetof -----------------------------------------------------------
CHECK "sizeof char", sizeof(char), 1)
CHECK "sizeof short", sizeof(short), 2)
CHECK "sizeof int", sizeof(int), 4)
CHECK "sizeof long", sizeof(long), 8)
CHECK "sizeof point", sizeof(point), 16)
CHECK "sizeof mix", sizeof(mix), 24)
CHECK "sizeof darr", sizeof(darr), 32)
CHECK "offsetof point.y", offsetof(point, y), 8)
CHECK "offsetof mix.a", offsetof(mix, a), 0)
CHECK "offsetof mix.b", offsetof(mix, b), 4)
CHECK "offsetof mix.c", offsetof(mix, c), 8)
CHECK "offsetof mix.d", offsetof(mix, d), 16)
CHECK "offsetof idb.extra", offsetof(idb, extra), 8)

// ---- structs: pointers, -> and ->= ----------------------------------------------------------------
p point {x = 3, y = 4}
CHECK "struct init x", p -> x nip, 3)
CHECK "struct init y", p -> y nip, 4)
q point {y = 9}
CHECK "partial init zero", q -> x nip, 0)
CHECK "partial init y", q -> y nip, 9)
CHECK "instances independent", p -> x nip, 3)
CHECK "-> keeps pointer", p -> x drop p eq, 1)
10 p ->= x drop
CHECK "->=", p -> x nip, 10)
CHECK "->= keeps other member", p -> y nip, 4)
CHECK "->= keeps pointer", 7 p ->= y p eq, 1)
CHECK "struct param", getx(p), 10)

// ---- structs: raw bytes, . and .=, read as / write as ---------------------------------------------------
CHECK ". reads", p read as point . y nip nip, 7)
CHECK ". keeps struct", p read as point . x drop . y nip nip, 7)
CHECK ".=", 99 p read as point .= y . y nip nip, 99)
CHECK ".= works on a copy", p -> y nip, 7)
CHECK ".= keeps other member", 99 p read as point .= y . x nip nip, 10)
p point {x = 7, y = 8} write as point
CHECK "write as x", p -> x nip, 7)
CHECK "write as y", p -> y nip, 8)
hp malloc(sizeof(point))
hp point {x = 1, y = 2} write as point
CHECK "write as heap x", hp -> x nip, 1)
CHECK "write as heap y", hp -> y nip, 2)
hq malloc(16)
hq p read as point write as point
CHECK "struct copy x", hq -> x nip, 7)
CHECK "struct copy y", hq -> y nip, 8)
CHECK "struct literal", point {x = 5, y = 6} . y nip nip, 6)
CHECK "empty struct literal", point . x nip nip, 0)
CHECK "struct literal exprs", point {x = add3(1, 1, 1), y = 2 3 mul} . x nip nip, 3)
CHECK "struct literal exprs 2", point {x = add3(1, 1, 1), y = 2 3 mul} . y nip nip, 6)

// ---- structs with mixed member sizes ----------------------------------------------------------------------
mp mix {a = 200, b = -5, c = 65535, d = 0xFFFFFFFFFF}
CHECK "mix a", mp -> a nip, 200)
CHECK "mix b", mp -> b nip, int -5)
CHECK "mix c", mp -> c nip, 65535)
CHECK "mix d", mp -> d nip, 0xFFFFFFFFFF)
0x1FF mp ->= a drop
CHECK "->= byte", mp -> a nip, 255)
CHECK "->= byte keeps b", mp -> b nip, int -5)
7 mp ->= c from mix drop
CHECK "->= short", mp -> c nip, 7)
CHECK "->= short keeps d", mp -> d nip, 0xFFFFFFFFFF)
CHECK "mix read as", mp read as mix . d nip nip nip, 0xFFFFFFFFFF)
CHECK "mix .= byte", 300 mp read as mix .= a . a nip nip nip, 44)
hm malloc(24)
hm mp read as mix write as mix
CHECK "mix write as", hm -> d nip, 0xFFFFFFFFFF)
CHECK "mix write as b", hm -> b nip, int -5)

// ---- 'from' resolves members shared by several structs -------------------------------------------------------
ip ida {id = 5, pad = 6}
jp idb {id = 200, extra = 7}
CHECK "from ->", ip -> id from ida nip, 5)
CHECK "from -> byte", jp -> id from idb nip, 200)
CHECK "from -> other member", jp -> extra nip, 7)
CHECK "from .", ida {id = 9} . id from ida nip nip, 9)
1 ip ->= id from ida drop
CHECK "from ->=", ip -> id from ida nip, 1)
CHECK "from .=", 3 ida {id = 1} .= id from ida . id from ida nip nip, 3)

// ---- structs inside raw memory ------------------------------------------------------------------------------------
pts calloc(4, sizeof(point))
42 pts &[2: point] ->= x drop
CHECK "&[i: struct] ->", pts &[2: point] -> x nip, 42)
CHECK "calloc zeroed", pts &[1: point] -> y nip, 0)
CHECK "&[i: struct] offset", pts &[2: point] pts sub, 32)

// ---- std: memory ----------------------------------------------------------------------------------------------------
m1 malloc(16)
m1 0x0102030405060708 write
m2 calloc(2, 8)
CHECK "calloc zero 1", m2 read, 0)
CHECK "calloc zero 2", m2 8 add read, 0)
memcpy(m2, m1, 8) drop
CHECK "memcpy", m2 read, 0x0102030405060708)
memset(m2, 0xAB, 4) drop
CHECK "memset", m2 read, 0x01020304ABABABAB)
CHECK "memcmp equal", memcmp(m1, m1, 8) 0 eq, 1)
CHECK "memcmp differ", memcmp(m1, m2, 8) 0 ne, 1)
memmove(m2 1 add, m2, 6) drop
CHECK "memmove overlap", m2 read, 0x010304ABABABABAB)
m3 malloc(8)
m3 77 write
m3 realloc(m3, 64) set m3
CHECK "realloc keeps data", m3 read, 77)
free(m1)
free(m2)
free(m3)

// ---- std: strings ----------------------------------------------------------------------------------------------------
sh "hello"
CHECK "strlen", strlen(sh), 5)
CHECK "streq yes", streq("abc", "abc"), 1)
CHECK "streq no", streq("abc", "abd"), 0)
CHECK "strcmp eq", strcmp("abc", "abc") 0 eq, 1)
CHECK "strcmp lt", strcmp("abc", "abd") int 0 int lt, 1)
CHECK "strcmp gt", strcmp("b", "a") int 0 int gt, 1)
CHECK "strncmp equal prefix", strncmp("abcX", "abcY", 3) 0 eq, 1)
CHECK "strncmp differs", strncmp("abcX", "abcY", 4) 0 ne, 1)
sb malloc(64)
strcpy(sb, "foo") drop
checkstr(results, "strcpy", sb, "foo")
strcat(sb, "bar") drop
checkstr(results, "strcat", sb, "foobar")
strncpy(sb, "xyz123", 3) drop
checkstr(results, "strncpy", sb, "xyzbar")
CHECK "strchr", strchr(sh, 'l') sh sub, 2)
CHECK "strchr missing", strchr(sh, 'z'), 0)
CHECK "strrchr", strrchr(sh, 'l') sh sub, 3)
CHECK "strstr", strstr(sh, "llo") sh sub, 2)
CHECK "strstr missing", strstr(sh, "zzz"), 0)
sd strdup(sh)
checkstr(results, "strdup", sd, "hello")
CHECK "strdup copies", sd sh ne, 1)
free(sd)
free(sb)

// ---- std: conversion / ctype ---------------------------------------------------------------------------------------------
CHECK "atoi", atoi("1234"), 1234)
CHECK "atoi negative", atoi("-42"), int -42)
CHECK "atoll", atoll("123456789012"), 123456789012)
CHECK "atoll negative", atoll("-5"), -5)
CHECK "strtoll hex", strtoll("ff", 0, 16), 255)
CHECK "strtoll dec", strtoll("77", 0, 10), 77)
CHECK "strtoll bin", strtoll("101", 0, 2), 5)
CHECK "abs", abs(int -5), int 5)
CHECK "llabs", llabs(-5), 5)
CHECK "toupper", toupper('a'), 'A')
CHECK "tolower", tolower('Q'), 'q')
CHECK "isdigit yes", isdigit('7') 0 ne, 1)
CHECK "isdigit no", isdigit('x') 0 eq, 1)
CHECK "isalpha yes", isalpha('x') 0 ne, 1)
CHECK "isalpha no", isalpha('1') 0 eq, 1)
CHECK "isspace yes", isspace(' ') 0 ne, 1)
CHECK "isspace no", isspace('a') 0 eq, 1)

// ---- std: misc ------------------------------------------------------------------------------------------------------------
srand(7)
rv rand()
srand(7)
CHECK "srand makes rand repeatable", rand() rv eq, 1)
CHECK "time", time(0) 0 ne, 1)
CHECK "getenv missing", getenv("BF_SURELY_NOT_SET_12345"), 0)

// ---- std: I/O ---------------------------------------------------------------------------------------------------------------
ob malloc(64)
CHECK "sprintf length", sprintf(ob, "%d-%s", 42, "x"), int 4)
checkstr(results, "sprintf", ob, "42-x")
CHECK "sprintf 5 args", sprintf(ob, "%d %d %d %d %d", 1, 2, 3, 4, 5), int 9)
checkstr(results, "sprintf 5 args out", ob, "1 2 3 4 5")
CHECK "snprintf length", snprintf(ob, 8, "%s", "abcdefghijkl"), int 12)
checkstr(results, "snprintf truncates", ob, "abcdefg")
CHECK "puts", puts("puts line") int 0 int ge, 1)
CHECK "putchar", putchar('Z'), 'Z')
putchar(10) drop
fh fopen("bf_test.tmp", "wb")
CHECK "fopen write", fh 0 ne, 1)
CHECK "fputs", fputs("line one\n", fh) int 0 int ge, 1)
CHECK "fwrite", fwrite("abcdef", 1, 6, fh), 6)
CHECK "fclose", fclose(fh), 0)
fh2 fopen("bf_test.tmp", "rb")
fb malloc(64)
CHECK "fgets returns buffer", fgets(fb, 64, fh2) fb eq, 1)
checkstr(results, "fgets", fb, "line one\n")
CHECK "fread", fread(fb, 1, 6, fh2), 6)
fb sized 8 [6]= 0
checkstr(results, "fread", fb, "abcdef")
CHECK "fclose read", fclose(fh2), 0)
CHECK "remove", remove("bf_test.tmp"), 0)

// ---- std: darr ----------------------------------------------------------------------------------------------------------------
da darr {}
CHECK "initdarr", initdarr(da, 8, 2), 1)
CHECK "lendarr empty", lendarr(da), 0)
CHECK "popdarr empty", popdarr(da), 0)
CHECK "indexdarr empty", indexdarr(da, 0), 0)
CHECK "removedarr empty", removedarr(da, 0), 0)
CHECK "adddarr", adddarr(da, 10), 1)
adddarr(da, 20) drop
adddarr(da, 30) drop
adddarr(da, 40) drop
adddarr(da, 50) drop
CHECK "lendarr", lendarr(da), 5)
CHECK "capacity doubled twice", da -> capacity from darr nip, 8)
CHECK "indexdarr 0", indexdarr(da, 0), 10)
CHECK "indexdarr 4", indexdarr(da, 4), 50)
CHECK "indexdarr out of range", indexdarr(da, 5), 0)
CHECK "insertdarr middle", insertdarr(da, 2, 25), 1)
CHECK "insertdarr front", insertdarr(da, 0, 5), 1)
CHECK "insertdarr end", insertdarr(da, lendarr(da), 60), 1)
CHECK "insertdarr out of range", insertdarr(da, 99, 1), 0)
CHECK "lendarr after inserts", lendarr(da), 8)
CHECK "insertdarr grows", insertdarr(da, 1, 7), 1)
CHECK "capacity after insert", da -> capacity from darr nip, 16)
CHECK "list[0]", indexdarr(da, 0), 5)
CHECK "list[1]", indexdarr(da, 1), 7)
CHECK "list[2]", indexdarr(da, 2), 10)
CHECK "list[3]", indexdarr(da, 3), 20)
CHECK "list[4]", indexdarr(da, 4), 25)
CHECK "list[8]", indexdarr(da, 8), 60)
CHECK "removedarr middle", removedarr(da, 2), 10)
CHECK "removedarr first", removedarr(da, 0), 5)
CHECK "removedarr last", removedarr(da, lendarr(da) 1 sub), 60)
CHECK "removedarr out of range", removedarr(da, 100), 0)
CHECK "popdarr", popdarr(da), 50)
CHECK "lendarr after removes", lendarr(da), 5)
CHECK "setdarr", setdarr(da, 0, 99), 1)
CHECK "setdarr out of range", setdarr(da, 100, 1), 0)
CHECK "after set [0]", indexdarr(da, 0), 99)
CHECK "after set [1]", indexdarr(da, 1), 20)
CHECK "after set [2]", indexdarr(da, 2), 25)
CHECK "after set [3]", indexdarr(da, 3), 30)
CHECK "after set [4]", indexdarr(da, 4), 40)
CHECK "ptrdarr distance", ptrdarr(da, 2) ptrdarr(da, 0) sub, 16)
CHECK "ptrdarr read", ptrdarr(da, 1) read, 20)
cleardarr(da)
CHECK "cleardarr", lendarr(da), 0)
CHECK "cleardarr keeps capacity", da -> capacity from darr nip, 16)
adddarr(da, 1) drop
CHECK "add after clear", indexdarr(da, 0), 1)
freedarr(da)
CHECK "freedarr size", lendarr(da), 0)
CHECK "freedarr capacity", da -> capacity from darr nip, 0)
CHECK "freedarr data", da -> data from darr nip, 0)
CHECK "add after free", adddarr(da, 5), 1)
CHECK "re-grown", indexdarr(da, 0), 5)
CHECK "growdarr no-op", growdarr(da), 1)
freedarr(da)

db darr {}
initdarr(db, 1, 2) drop
adddarr(db, 65) drop
adddarr(db, 66) drop
adddarr(db, 67) drop
adddarr(db, 0) drop
checkstr(results, "byte darr as string", db -> data from darr nip, "ABC")
CHECK "byte darr item", indexdarr(db, 2), 67)
CHECK "byte darr truncates", adddarr(db, 0x1FF), 1)
CHECK "byte darr truncated item", indexdarr(db, 4), 255)
freedarr(db)

d4 darr {}
initdarr(d4, 4, 1) drop
adddarr(d4, int -5) drop
adddarr(d4, 0x100000001) drop
CHECK "int darr item", indexdarr(d4, 0), int -5)
CHECK "int darr truncates", indexdarr(d4, 1), 1)
CHECK "int darr stride", ptrdarr(d4, 1) ptrdarr(d4, 0) sub, 4)
freedarr(d4)

hd newdarr(8, 0)
CHECK "newdarr", hd 0 ne, 1)
CHECK "newdarr empty capacity", hd -> capacity from darr nip, 0)
CHECK "adddarr grows from 0", adddarr(hd, 11), 1)
CHECK "min capacity", hd -> capacity from darr nip, 4)
CHECK "heap darr item", indexdarr(hd, 0), 11)
deletedarr(hd)
hd2 newdarr(8, 3)
CHECK "newdarr capacity", hd2 -> capacity from darr nip, 3)
deletedarr(hd2)

// ---- summary ----------------------------------------------------------------------------------------------------------------------
printf("%lld passed, %lld failed\n", results [0: long], results [1: long]) drop
exit(results [1: long] 0 ne)
