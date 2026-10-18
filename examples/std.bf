#pragma once
// =====================================================================
//  std.bf  --  C standard library bindings + dynamic array (darr)
//
//  * "extern int f(...)" truncates the C return value to 32 bits (the
//    upper half of RAX is undefined for a C `int`).  Put `int` (or
//    `signed sized 32`) in front of an operator to compare such a
//    result as signed:   strcmp(a, b) int 0 int lt
//  * extern variadic functions (printf ...) take any number of
//    arguments; the first four go in registers, the rest on the stack.
// =====================================================================

typedef byte sized 8
typedef char sized 8
typedef short signed sized 16
typedef ushort sized 16
typedef int signed sized 32
typedef uint sized 32
typedef long signed sized 64
typedef ulong sized 64

// ---- memory ----------------------------------------------------------
extern malloc(sized 64 size)
extern calloc(sized 64 count, sized 64 size)
extern realloc(sized 64 ptr, sized 64 size)
extern void free(sized 64 ptr)
extern memcpy(sized 64 dst, sized 64 src, sized 64 n)
extern memmove(sized 64 dst, sized 64 src, sized 64 n)
extern memset(sized 64 dst, sized 32 value, sized 64 n)
extern int memcmp(sized 64 a, sized 64 b, sized 64 n)

// ---- strings ---------------------------------------------------------
extern strlen(sized 64 s)
extern int strcmp(sized 64 a, sized 64 b)
extern int strncmp(sized 64 a, sized 64 b, sized 64 n)
extern strcpy(sized 64 dst, sized 64 src)
extern strncpy(sized 64 dst, sized 64 src, sized 64 n)
extern strcat(sized 64 dst, sized 64 src)
extern strchr(sized 64 s, sized 32 c)
extern strrchr(sized 64 s, sized 32 c)
extern strstr(sized 64 haystack, sized 64 needle)
extern strdup(sized 64 s)

// ---- conversion / ctype ----------------------------------------------
extern int atoi(sized 64 s)
extern long atoll(sized 64 s)
extern long strtoll(sized 64 s, sized 64 endptr, sized 32 base)
extern int abs(sized 32 x)
extern long llabs(sized 64 x)
extern int toupper(sized 32 c)
extern int tolower(sized 32 c)
extern int isdigit(sized 32 c)
extern int isalpha(sized 32 c)
extern int isspace(sized 32 c)

// ---- process / misc --------------------------------------------------
extern void exit(sized 32 code)
extern void abort()
extern int rand()
extern void srand(sized 32 seed)
extern long time(sized 64 out)
extern getenv(sized 64 name)
extern int system(sized 64 cmd)

// ---- I/O -------------------------------------------------------------
extern variadic int printf(sized 64 fmt)
extern variadic int sprintf(sized 64 buf, sized 64 fmt)
extern variadic int snprintf(sized 64 buf, sized 64 n, sized 64 fmt)
extern int puts(sized 64 s)
extern int putchar(sized 32 c)
extern int getchar()
extern fopen(sized 64 path, sized 64 mode)
extern int fclose(sized 64 file)
extern fgets(sized 64 buf, sized 32 n, sized 64 file)
extern int fputs(sized 64 s, sized 64 file)
extern fread(sized 64 buf, sized 64 size, sized 64 count, sized 64 file)
extern fwrite(sized 64 buf, sized 64 size, sized 64 count, sized 64 file)
extern int remove(sized 64 path)

// ---- small helpers written in the language itself ----------------------

// 1 if the two C strings are equal (returns an int)
streq(a, b)
    strcmp(a, b) int 0 int eq int ret
end

// =====================================================================
//  darr: dynamic array.  Every function takes a darr*.
//
//  Items of up to 8 bytes are passed and returned by value; only the
//  low `itemsize` bytes are stored.  Failure is reported as 0 (the
//  functions that return an item return 0 when the index is invalid).
//
//      list darr {}                    // a darr in this function's frame
//      initdarr(list, 8, 4) drop       // itemsize 8, room for 4
//      adddarr(list, 42) drop
//      indexdarr(list, 0) dump
//      freedarr(list)
// =====================================================================

struct darr
    sized 64 data
    sized 64 itemsize
    sized 64 size
    sized 64 capacity
end

// number of items
lendarr(d)
    d -> size from darr nip ret
end

// address of item `index` (no bounds check)
ptrdarr(d, index)
    d -> data from darr nip
    index d -> itemsize from darr nip mul add
    ret
end

// make room for at least one more item.  1 = ok, 0 = out of memory
growdarr(d)
    if d -> size from darr nip  d -> capacity from darr nip  lt do
        1 ret
    end

    newcap 0
    d -> capacity from darr nip 2 mul set newcap
    if newcap 4 lt do 4 set newcap end

    p 0
    realloc(d -> data from darr nip, newcap d -> itemsize from darr nip mul) set p
    if p 0 eq do 0 ret end

    p d ->= data from darr drop
    newcap d ->= capacity from darr drop
    1 ret
end

// set up a darr that already exists in memory.  1 = ok, 0 = out of memory
initdarr(d, itemsize, capacity)
    itemsize d ->= itemsize from darr drop
    0 d ->= size from darr drop
    capacity d ->= capacity from darr drop
    0 d ->= data from darr drop

    if capacity 0 eq do 1 ret end

    malloc(itemsize capacity mul) d ->= data from darr drop
    d -> data from darr nip 0 ne ret
end

// heap allocate a darr (header + items).  0 on failure
newdarr(itemsize, capacity)
    d malloc(sizeof(darr))
    if d 0 eq do 0 ret end

    if initdarr(d, itemsize, capacity) 0 eq do
        free(d)
        0 ret
    end

    d ret
end

// free the items; the darr stays valid and empty
freedarr(d)
    free(d -> data from darr nip)
    0 d ->= data from darr drop
    0 d ->= size from darr drop
    0 d ->= capacity from darr drop
end

// free the items and the darr itself (use with newdarr)
deletedarr(d)
    freedarr(d)
    free(d)
end

// forget all items, keep the memory
cleardarr(d)
    0 d ->= size from darr drop
end

// append.  1 = ok
adddarr(d, value)
    if growdarr(d) 0 eq do 0 ret end

    memcpy(ptrdarr(d, d -> size from darr nip), & value, d -> itemsize from darr nip) drop
    d -> size from darr nip 1 add d ->= size from darr drop
    1 ret
end

// insert before `index` (index == size appends).  1 = ok
insertdarr(d, index, value)
    if index d -> size from darr nip gt do 0 ret end
    if growdarr(d) 0 eq do 0 ret end

    memmove(ptrdarr(d, index 1 add), ptrdarr(d, index), d -> size from darr nip index sub d -> itemsize from darr nip mul) drop
    memcpy(ptrdarr(d, index), & value, d -> itemsize from darr nip) drop
    d -> size from darr nip 1 add d ->= size from darr drop
    1 ret
end

// remove item `index` and return it (0 if out of range)
removedarr(d, index)
    if index d -> size from darr nip lt 0 eq do 0 ret end

    out 0
    memcpy(& out, ptrdarr(d, index), d -> itemsize from darr nip) drop
    memmove(ptrdarr(d, index), ptrdarr(d, index 1 add), d -> size from darr nip index sub 1 sub d -> itemsize from darr nip mul) drop
    d -> size from darr nip 1 sub d ->= size from darr drop
    out ret
end

// remove and return the last item (0 if empty)
popdarr(d)
    if d -> size from darr nip 0 eq do 0 ret end
    removedarr(d, d -> size from darr nip 1 sub) ret
end

// read item `index` (0 if out of range)
indexdarr(d, index)
    if index d -> size from darr nip lt 0 eq do 0 ret end

    out 0
    memcpy(& out, ptrdarr(d, index), d -> itemsize from darr nip) drop
    out ret
end

// overwrite item `index`.  1 = ok
setdarr(d, index, value)
    if index d -> size from darr nip lt 0 eq do 0 ret end

    memcpy(ptrdarr(d, index), & value, d -> itemsize from darr nip) drop
    1 ret
end
