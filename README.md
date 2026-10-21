# bforth

bforth is a small Forth-like language, It was made by me because I never have written a compiler ever,
and want to!

A little taste

```bf
#include "std.bf"

"Hello, World!" dumps

6 7 mul dump
```

## 1. The stack and postfix expressions

bforth keeps values on a stack. An operation takes the values it needs from the top, does its work, and usually puts the result back.
In the examples below, the rightmost value is the top of the stack.

```bf
3 4 add dump       // prints 7
10 3 sub dump      // prints 7
6 7 mul dump       // prints 42
20 5 div dump      // prints 4
20 6 mod dump      // prints 2
```

For example, `3 4 add` leaves `7` on the stack. `add` takes the two values at the top and replaces them with their sum.

There is no boundry of what a operation is, a single operation could be 4 diffrent keywords.

```bf
2 3 add 4 mul dump     // (2 + 3) * 4 = 20
```

Order matters, `a b sub` means `a - b`, and `a b div` means `a / b`.
```
so 
1 0 sub drop // 1
0 1 sub drop // -1
0 1 div drop // 0
1 0 div drop // error! 
```

Note: `3 4 add` is not one singleton, `3` and `4` are operations them self which push `3` and `4` 
`add` just pops off two values from the stack and adds them and puts them back

### Stack operations

| Word | Effect | Example |
|---|---|---|
| `dup` | Duplicate the top value | `5 dup add` leaves `10` |
| `drop` | Remove the top value | `5 drop` |
| `swap` | Swap the top two values | `1 2 swap` leaves `2 1` |
| `over` | Copy the second value to the top | `1 2 over` leaves `1 2 1` |
| `nip` | Remove the second value, keeping the top | `1 2 nip` leaves `2` |
| `rot` | Reverse the top three values | `1 2 3 rot` leaves `3 2 1` |
| `antirot` | Rotate the top three left | `1 2 3 antirot` leaves `2 3 1` |

Use `rot with group N` or `antirot with group N` to rotate more than three
values. Groups of four or more rotate one place right or left, respectively.

```bf
65 dumpc
"Done" dumps
```

Also there exist some langauge commands to do output text, these are built into the language
| Word | What it does | Example |
|---|---|---|
| `dump` | Prints a number from the stack | `10 dump` |
| `dumpc` | Prints a byte from stack as a char | `'A' dump` |
| `dumps` | Prints a Cstring pointer from stack | `"Hello, World" dumps` |

## 2. Values, sizes, and signed numbers

Integer literals can be decimal, hexadecimal, binary, or written with digit separators:

```bf
42
0xFF
0b1010
1_000_000
-25
```

By default, most keywords use 64-bit values and treat them as unsigned. Add a modifier when you need a different width or signed arithmetic.
Modifiers apply to the next token only, so put them before the value or operation they should affect.

| Modifier | Meaning |
|---|---|
| `sized 8` | 8-bit value |
| `sized 16` | 16-bit value |
| `sized 32` | 32-bit value |
| `sized 64` | 64-bit value |
| `signed` | Signed operation |
| `unsigned` | Unsigned operation |

For example:

```bf
sized 8 200 sized 8 100 sized 8 add dump  // 44: result wraps to 8 bits

signed sized 32 -7
signed sized 32 2
signed sized 32 div
signed sized 32 dump                     // -3
```

Remember to size the operation as well as the inputs. A value does keep its original width for later operations.

```bf
sized 8 200 sized 8 100 add dump          // 300: add defaults to 64 bits
sized 8 200 sized 8 100 sized 8 add dump  // 44
```

Note: while for normal mode all values are actualy 64 bit no matter what, so sized 8 10 is the same memory footprint as 10
but its the operation / keywords which cares more, unless your writeing code in --no-safe-slot then everything is the exact size
you specify it to be, so even droping needs to be carfull as for instance
```
10 sized 8 drop
// 7 bytes are still on stack and hence the program has a desynced stack 
```
The compiler tries it best to see where a desync has happend and does warn you in --no-safe-slot mode, but you can still compile and run.
FYI in normal mode it just throws a error at you and stope compileing whenever the stack has too less or too many values 

### Type aliases

If you keep using the same width and signedness, give that combination a name with `typedef`:

```bf
typedef byte sized 8
typedef char sized 8
typedef short signed sized 16
typedef int signed sized 32
typedef uint unsigned sized 32
typedef long signed sized 64
typedef ulong unsigned sized 64

char 65 dumpc
int -12 int 5 int add int dump // -7
```

The standard library `std.bf` defines common aliases such as `byte`, `char`, `short`, `ushort`, `int`, `uint`, `long`, and `ulong`.

## 3. Variables

To make a variable, write its name followed by its initial value.
Writing the variable's name later pushes its current value onto the stack. To write to a variable put the new value on the stack and use `set`:

```bf
x 10
y 20

x y add dump             // 30

x x 1 add set x dump     // increment x, then print 11
```

The initial value must come from one value-producing expression, such as a literal, string, array, function call, `sizeof(...)`, or address.
If you need to calculate the value first, declare the variable with a 0 or something and `set` it afterwards:

```bf
result 0
10 20 add set result
result dump              // 30
```

A variable's width is fixed when you declare it. If you store a value that doesn't fit, it is truncated to that width.
Note: in no safe slot mode, the compiler does not care 

```bf
sized 8 small 250
small dump
small 10 add set small
small dump
```

Variables belong to the function where they're declared. Code outside a function runs as `main`.
For external variables, use `extern`; bforth doesn't have ordinary global variable declarations, kida like lua.

## 4. Operators and comparisons

Arithmetic and bitwise operators:

```bf
a 12
b 5

a b add dump
a b sub dump
a b mul dump
a b div dump
a b mod dump

a b and dump
a b or dump
a b xor dump
a 1 shl dump
a 1 shr dump
```

Available arithmetic and bitwise words are `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor`, `shl`, `shr`, `not`, and `neg`.

Comparisons leave `1` on the stack when the condition is true, and `0` when it isn't:

```bf
5 5 eq dump       // 1
5 3 ne dump       // 1
3 5 lt dump       // 1
5 3 gt dump       // 1
5 5 le dump       // 1
6 5 ge dump       // 1
```

Comparison words are `eq`, `ne`, `lt`, `gt`, `le`, and `ge`. Use `signed` before a comparison when signed comparison is required.

## 5. Conditions and loops

There is `if ... do ... end` for if blocks kida like lua again! Any non-zero value counts as true. Add `elif` or `else` if you need other branches:

```bf
score 85

if score 90 ge do
    "A" dumps
elif score 75 ge do
    "B" dumps
else
    "Keep practising" dumps
end
```

A `while` loop:

```bf
i 0

while i 5 lt do
    i dump
    i 1 add set i
end
```

prints `0` through `4`.

`for` loops have a counter form and a three-part form:

```bf
for i 0, 5 do
    i dump
end

for i 0, i 5 lt, i 1 add set i do
    i dump
end
```

The three-part form is `for init, condition, step do ... end`. A counter loop
uses `for name start, end do ... end` and increments `name` by one.

Keep the stack balanced inside the all conditions.
bforth doesn't have `break` or `continue` (because I am lazy), so use the loop condition to decide when to stop.

## 6. Functions

A Functions is defined outside other functions, like c, using `name(parameters) ... end`.:
Note: The language does'nt really care or have return types

```bf
add3(a, b, c)
    a b add c add ret
end

add3(10, 20, 12) dump       // 42
```

Arguments are evaluated from left to right. Inside the function, parameters are local variables.
`ret` returns the value at the top of the stack.

```bf
square(x)
    x x mul ret
end

square(9) dump              // 81
```

Recurstion is supported.

Writing a defined function's name without parentheses pushes its address.
Follow it with an empty `()` to call that pointer; indirect calls take no
arguments and produce a 64-bit result:

```bf
get_answer()
    42 ret
end

get_answer () dump
```

If a function reaches the end without `ret`, it doesn't return a stack value. At top level, `ret` exits the program and uses the returned value as the exit code.

### Variadic functions

A function can accept extra arguments by starting its definition with `variadic`:

```bf
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

sum(10, 1, 2, 3) dump       // 16
```

Inside a variadic function, `variadic_arr` points to the extra arguments. Each argument takes 8 bytes, and `variadic_len` gives their total size in bytes, not the number of arguments.

## 7. Strings and memory

A string literal is stored as UTF-8 text ending in a NUL byte. Using it pushes its address onto the stack:

```bf
message "Hello from bforth"
message dumps
```

Prefix a string with `r` to keep backslashes literal. Escaped strings support
the common C escapes (`\n`, `\t`, `\r`, `\0`, `\a`, `\b`, `\f`, `\v`,
`\\`, quotes, octal bytes, `\xHH`, `\uHHHH`, and `\UHHHHHHHH`).

String literals are read-only by default. Add `mutable` when you need to change the text:

```bf
buffer mutable "hello"
```

### Pointers, `read`, and `write`

Use `read` to load a value from memory and `write` to store one. Both use 8 bytes by default; add a size modifier when you need a smaller read or write.

```bf
x 10
& x 42 write             // set x through its address
x dump                   // 42

buffer [10, 20, 30]
buffer 8 add sized 64 read dump  // read the second 8-byte element: 20
```

For `write`, push the address first and the value second:

```bf
ptr 0x1000
ptr 65 sized 8 write
```

`& name` gives you the address of a variable. A bare `&` gives you the address of the top stack slot instead. That slot's address is temporary, so don't keep it after the slot is removed or overwritten.

### Arrays

An array literal creates storage for the current function and leaves a pointer to its first element on the stack. Its elements are evaluated from left to right.

```bf
numbers [10, 20, 30, 40]
numbers [2] dump             // 30
numbers [1]= 99
numbers [1] dump             // 99
```

Each element is 8 bytes by default. Put a size modifier before the array when you want smaller elements:

```bf
sized 8 bytes [65, 66, 67, 0]
sized 8 bytes [1] dump
```

Repeat one initializer with `[:: count : value]`; `[:: count :]` zero-fills,
while `[:: count]` reserves uninitialized storage. A size modifier controls
each element's width:

```bf
sized 8 zeroes [:: 1000 :]
sized 8 tens [:: 1000 : 10]
```

Indexing supports reads, writes, and addresses:

```bf
numbers [2]          // read element 2
numbers [2]= 50      // write element 2
numbers &[2]         // address of element 2
```

Use `: type` to specify the element type. The type can be a typedef or a struct name; its size determines the offset and access width:

```bf
typedef item sized 64
numbers [1: item] dump
numbers [1: item]= 77
numbers &[1: item]
```

This is also suger for

```bf
typedef item sized 64
item numbers [1] dump
item numbers [1]= 77
item numbers &[1]

// but in this format you can put raw sized N or unsigned or signed or a struct name

```bf

Array storage is valid until the current function returns.

## 8. Structs

You can define a struct outside functions. Each member can be 1, 2, 4, or 8 bytes; if you don't specify a size, it uses 8 bytes.

```bf
struct point
    sized 64 x
    sized 64 y
end

p point {x = 3, y = 4}
```

This creates a variable `p` that points to the struct's storage. Any members you leave out of the initializer start at zero.

Use `->` to access a member through a pointer. Use `->=` to assign to a member:

```bf
p -> x nip dump             // 3
p -> y nip dump             // 4

10 p ->= x drop             // p->x = 10
p -> x nip dump             // 10
```

Both `->` and `->=` leave the pointer on the stack. Use `nip` or `drop` if you don't need it anymore. If different structs use the same member name, you may need to specify which struct it comes `from`.

```
struct vec2
    int x
    int y
end

p -> x from point nip dump // now it knows its the x of point not of vec2
```

Note: same syntax exists for .

To check a struct's size or find where a member sits in memory, use `sizeof(type)` and `offsetof(type, member)`:

```bf
sizeof(point) dump
offsetof(point, y) dump
```

`read as point` and `write as point` copy the whole struct representation to or from the stack. Prefer member access (`->` and `->=`) when working with C structs, because bforth rounds struct storage to a multiple of 8 bytes.


```
p 0
set p point {x = 10, y = 3}

p read as point . x nip dump
// here as p = &struct point {x = 10, y = 3}
// pushing p gives us the pointer (struct name {...} pushes a pointer)
// now if we read that pointer we get the actual struct point {x = 10, y = 3}
// and we can now use . on it

// write is pretty much the same

```
## 9. Using C functions and variables

`std.bf` gives you bindings for common C library functions and useful type aliases, including byte-sized `bool`. It also provides `string_copy`, `string_join`, `path_basename`, `path_dirname`, `path_join`, and `input(prompt)`; heap-returning helpers transfer ownership to the caller, who should call `free`. `input` reads a line from stdin. `keypressed(character)` reads and consumes one stdin character and compares it; this portable implementation blocks while waiting. `#define print printf` makes `print(...)` an alias for the variadic C `printf`.

Use `-c` / `--object` to produce an unlinked native object file. `--freestanding` applies GCC/Clang's freestanding mode and disables startup files and default libraries when linking (`-ffreestanding -nostdlib -nodefaultlibs -nostartfiles`). Such a program must provide its own entry/runtime needs and any referenced external functions.

```bf
extern malloc(sized 64 size)
extern void free(sized 64 ptr)
extern int strcmp(sized 64 a, sized 64 b)
```

Give each parameter a name in the declaration, even though bforth only uses the number of parameters.
Arguments are passed as 64-bit values. The type modifier after `extern` sets the return width; use `void` when the function returns nothing.

Many examples exist in the standard library:

Some C functions, including `printf`, return a value even when you don't need it. Use `drop` to discard that result and keep the stack balanced.

External variables behave like normal varibles:

```bf
extern sized 32 errno_like
errno_like dump
```

A C `int` is 32 bits. If a function returns an `int`, apply `int` before a signed comparison so bforth interprets the result correctly:

```bf
strcmp("a", "b") int 0 int lt if do
    "a sorts before b" dumps
end
```

The `std.bf` file also defines `darr`, a dynamic array. Have a look at its definition if you want to see how to build a struct, work with its members, and write functions that use it.

## 10. Preprocessor and comments

Comments start with `//` and continue to the end of the line.

```bf
// Calculate and print a result.
6 7 mul dump
```

Preprocessor directives include:

```bf
#define LIMIT 10
#include "std.bf"
#pragma once
#define SQUARE(x) x x mul
```

- `#define NAME value` replaces `NAME` with the rest of the line. Callable macros accept comma-separated arguments, for example `#define SQUARE(x) x x mul`.
- `#include "file"` reads another file. bforth looks beside the file doing the include first, then checks directories passed with `-I`.
- `#pragma once` makes sure a file is only included once.
- `#pragma requires_no_safe_slot` and `#pragma requires_safe_slot` require the matching compiler mode.

`examples/windows.bf` provides common Win32 bindings; `examples/posix.bf`
provides common POSIX bindings. Include the one for your target after `std.bf`.

Use `-I` to add include directories and `-D` to define a value from the command line:

```sh
python bforth.py program.bf -I include -D LIMIT=10 -o program.exe
python bforth.py program.bf -c -t windows -o program.o
python bforth.py program.bf --freestanding -o program.exe
```

The example builder in `builds/build/build.bf` builds itself and places generated assembly under `builds/asm/` and executables under `builds/exes/`. Intermediate object files are written to `builds/tmp/` and removed after linking.
