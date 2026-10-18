// fibanachi.bf -- Fibonacci numbers three ways: recursion, a loop and a dynamic array.
//
//   python bforth.py examples/fibanachi.bf -o fib
//
// Uses std.bf for printf and the darr dynamic array.
#include "std.bf"

// fib(n) by plain recursion: slow for big n, but it shows recursion working
fibrec(n)
    if n 2 lt do n ret end
    fibrec(n 1 sub) fibrec(n 2 sub) add ret
end

// fib(n) with a loop: (a, b) -> (b, a + b), n times
fibiter(n)
    a 0
    b 1
    i 0
    while i n lt do
        t 0
        a b add set t
        b set a
        t set b
        i 1 add set i
    end
    a ret
end

"== the first 16 Fibonacci numbers (loop) =="  dumps
i 0
while i 16 lt do
    printf("fib(%2lld) = %lld\n", i, fibiter(i)) drop
    i 1 add set i
end

"== recursion vs loop ==" dumps
printf("recursive fib(20) = %lld\n", fibrec(20)) drop
printf("loop      fib(20) = %lld\n", fibiter(20)) drop

"== 64-bit range ==" dumps
printf("fib(90)  = %llu\n", fibiter(90)) drop

"== a table built in a darr ==" dumps
table darr {}
initdarr(table, 8, 4) drop
adddarr(table, 0) drop
adddarr(table, 1) drop
k 2
while k 30 lt do
    adddarr(table, indexdarr(table, k 1 sub) indexdarr(table, k 2 sub) add) drop
    k 1 add set k
end
printf("table holds %lld numbers, the last is %lld\n", lendarr(table), indexdarr(table, 29)) drop

// check the table against the loop version
bad 0
k 0
while k 30 lt do
    if indexdarr(table, k) fibiter(k) ne do bad 1 add set bad end
    k 1 add set k
end

if bad 0 eq do
    "table and loop agree" dumps
else
    "MISMATCH" dumps
end

freedarr(table)
