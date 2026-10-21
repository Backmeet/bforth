#include "../../examples/std.bf"

extern ptr_t get_children(ptr_t path)
extern void free_children(ptr_t children)
extern int ensure_directory(ptr_t path)
extern int get_builder_root(ptr_t buffer, size_t capacity)
extern int is_canonical_builder()

#define BUILD_MAX_PATH 4096
#define PYTHON "C:/Users/Asus/AppData/Local/Python/bin/python.exe"

join_paths(ptr_t directory, ptr_t name)
    size 0
    strlen(directory) strlen(name) add 2 add set size
    result calloc(size, 1)
    if result 0 eq do 0 ret end
    strcpy(result, directory) ptr_t drop
    strcat(result, "/") ptr_t drop
    strcat(result, name) ptr_t drop
    result ret
end

// Return the final path component, accepting either Windows or POSIX separators.
basename(ptr_t path)
    backslash strrchr(path, '\\')
    slash strrchr(path, '/')
    if backslash 0 eq do
        if slash 0 eq do path ret end
        slash 1 add ret
    end
    if slash 0 eq do backslash 1 add ret end
    if backslash slash gt do backslash 1 add ret end
    slash 1 add ret
end

replace_extension(ptr_t path, ptr_t new_extension)
    dot strrchr(path, '.')
    prefix 0
    if dot 0 eq do
        strlen(path) set prefix
    else
        dot path sub set prefix
    end
    length 0
    prefix strlen(new_extension) add 1 add set length
    output calloc(length, 1)
    if output 0 eq do 0 ret end
    memcpy(output, path, prefix) drop
    strcpy(output prefix add, new_extension) ptr_t drop
    output ret
end

cwd calloc(BUILD_MAX_PATH, 1)
if cwd 0 eq do
    puts("build: could not allocate cwd buffer") drop
    exit(1)
end

if get_builder_root(cwd, BUILD_MAX_PATH) 0 eq do
    puts("build: could not locate the project from the executable path") drop
    free(cwd)
    exit(1)
end

examples join_paths(cwd, "examples")
builds join_paths(cwd, "builds")
if examples 0 eq builds 0 eq or do
    puts("build: could not allocate paths") drop
    free(examples)
    free(builds)
    free(cwd)
    exit(1)
end

asm_dir join_paths(builds, "asm")
exe_dir join_paths(builds, "exes")
temp_dir join_paths(builds, "tmp")
if asm_dir 0 eq exe_dir 0 eq or temp_dir 0 eq or do
    puts("build: could not allocate output directories") drop
    exit(1)
end
if ensure_directory(asm_dir) 0 eq ensure_directory(exe_dir) 0 eq or
   ensure_directory(temp_dir) 0 eq or do
    puts("build: could not create output directories") drop
    exit(1)
end

// Bootstrap this builder from its own source using the compiler's object mode.
builder_source join_paths(builds, "build/build.bf")
builder_helper join_paths(builds, "build/helper.c")
builder_object join_paths(temp_dir, "build.o")
builder_exe join_paths(exe_dir, "build.exe")
command_size 0
command 0
status 0
if is_canonical_builder() 0 eq do
strlen(PYTHON) strlen(cwd) add strlen(builder_source) add
strlen(builder_object) add 96 add set command_size
calloc(command_size, 1) set command
snprintf(command, command_size,
    "%s \"%s/bforth.py\" \"%s\" -t windows -c -o \"%s\"",
    PYTHON, cwd, builder_source, builder_object) drop
system(command) set status
free(command)
if status 0 ne do
    puts("build: compiler failed to build build.bf as an object") drop
    exit(1)
end

strlen(builder_object) strlen(builder_helper) add strlen(builder_exe) add 80 add set command_size
calloc(command_size, 1) set command
snprintf(command, command_size, "gcc \"%s\" \"%s\" -o \"%s\"",
    builder_object, builder_helper, builder_exe) drop
system(command) set status
free(command)
remove(builder_object) drop
if status 0 ne do
    puts("build: GCC failed to link build.bf") drop
    exit(1)
end
printf("built builder %s\n", builder_exe) drop
end

children_base get_children(examples)
if children_base 0 eq do
    puts("build: could not enumerate examples") drop
    free(examples)
    free(builds)
    free(cwd)
    exit(1)
end

children 0
children_base set children
while children sized 64 read 0 ne do
    source 0
    children sized 64 read set source
    extension 0
    strrchr(source, '.') set extension

    if extension 0 ne do
        if strcmp(extension, ".bf") 0 eq do
            filename 0
            basename(source) set filename
            options ""
            if strcmp(filename, "nosafe.bf") 0 eq do
                " --no-safe-slot" set options
            end
            assembly_name 0
            replace_extension(filename, ".s") set assembly_name
            exe_name 0
            replace_extension(filename, ".exe") set exe_name
            assembly 0
            join_paths(asm_dir, assembly_name) set assembly
            object 0
            object_name 0
            replace_extension(filename, ".o") set object_name
            join_paths(temp_dir, object_name) set object
            executable 0
            join_paths(exe_dir, exe_name) set executable

            if assembly 0 eq object 0 eq or executable 0 eq or do
                puts("build: could not allocate an output path") drop
                exit(1)
            end

            strlen(PYTHON) strlen(cwd) add strlen(source) add
            strlen(assembly) add strlen(options) add 112 add set command_size
            calloc(command_size, 1) set command
            snprintf(command, command_size,
                "%s \"%s/bforth.py\" \"%s\" -O -s -t windows -o \"%s\"%s",
                PYTHON, cwd, source, assembly, options) drop
            system(command) set status
            if status 0 ne do
                printf("build: bforth failed for %s\n", source) drop
                exit(1)
            end
            free(command)

            strlen(PYTHON) strlen(cwd) add strlen(source) add strlen(object) add 112 add set command_size
            calloc(command_size, 1) set command
            snprintf(command, command_size,
                "%s \"%s/bforth.py\" \"%s\" -O -t windows -c -o \"%s\"%s",
                PYTHON, cwd, source, object, options) drop
            system(command) set status
            if status 0 ne do
                printf("build: object generation failed for %s\n", source) drop
                exit(1)
            end
            free(command)

            strlen(executable) strlen(object) add 64 add set command_size
            calloc(command_size, 1) set command
            snprintf(command, command_size,
                "gcc \"%s\" -o \"%s\"", object, executable) drop
            system(command) set status
            remove(object) drop
            if status 0 ne do
                printf("build: GCC failed for %s\n", source) drop
                exit(1)
            end
            free(command)

            printf("built %s\n", executable) drop
            free(assembly_name)
            free(object_name)
            free(exe_name)
            free(assembly)
            free(object)
            free(executable)
        end
    end
    children 8 add set children
end

free_children(children_base)
free(examples)
free(builds)
free(asm_dir)
free(exe_dir)
free(temp_dir)
free(builder_source)
free(builder_helper)
free(builder_object)
free(builder_exe)
free(cwd)
0 ret
