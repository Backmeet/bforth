bits 64
default rel

extern $printf
extern $malloc
extern $calloc
extern $realloc
extern $free
extern $memcpy
extern $memmove
extern $memset
extern $memcmp
extern $strlen
extern $strcmp
extern $strncmp
extern $strcpy
extern $strncpy
extern $strcat
extern $strchr
extern $strrchr
extern $strstr
extern $strdup
extern $atoi
extern $atoll
extern $strtoll
extern $abs
extern $llabs
extern $toupper
extern $tolower
extern $isdigit
extern $isalpha
extern $isspace
extern $exit
extern $abort
extern $rand
extern $srand
extern $time
extern $getenv
extern $system
extern $getcwd
extern $sprintf
extern $snprintf
extern $puts
extern $putchar
extern $getchar
extern $fopen
extern $fclose
extern $fgets
extern $fputs
extern $fread
extern $fwrite
extern $remove
extern $get_children
extern $free_children
extern $ensure_directory
extern $get_builder_root
extern $is_canonical_builder
global main

section .rdata
fmt_llu db "%llu", 10, 0
fmt_lld db "%lld", 10, 0
fmt_c   db "%c", 0
fmt_s   db "%s", 10, 0
str_1: db 46,0
str_2: db 47,0
str_3: db 37,115,0
str_4: db 47,0
str_5: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,97,108,108,111,99,97,116,101,32,99,119,100,32,98,117,102,102,101,114,0
str_6: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,108,111,99,97,116,101,32,116,104,101,32,112,114,111,106,101,99,116,32,102,114,111,109,32,116,104,101,32,101,120,101,99,117,116,97,98,108,101,32,112,97,116,104,0
str_7: db 101,120,97,109,112,108,101,115,0
str_8: db 98,117,105,108,100,115,0
str_9: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,97,108,108,111,99,97,116,101,32,112,97,116,104,115,0
str_10: db 97,115,109,0
str_11: db 101,120,101,115,0
str_12: db 116,109,112,0
str_13: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,97,108,108,111,99,97,116,101,32,111,117,116,112,117,116,32,100,105,114,101,99,116,111,114,105,101,115,0
str_14: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,99,114,101,97,116,101,32,111,117,116,112,117,116,32,100,105,114,101,99,116,111,114,105,101,115,0
str_15: db 98,117,105,108,100,47,98,117,105,108,100,46,98,102,0
str_16: db 98,117,105,108,100,47,104,101,108,112,101,114,46,99,0
str_17: db 98,117,105,108,100,46,111,0
str_18: db 98,117,105,108,100,46,101,120,101,0
str_19: db 67,58,47,85,115,101,114,115,47,65,115,117,115,47,65,112,112,68,97,116,97,47,76,111,99,97,108,47,80,121,116,104,111,110,47,98,105,110,47,112,121,116,104,111,110,46,101,120,101,0
str_20: db 37,115,32,34,37,115,47,98,102,111,114,116,104,46,112,121,34,32,34,37,115,34,32,45,116,32,119,105,110,100,111,119,115,32,45,99,32,45,111,32,34,37,115,34,0
str_21: db 67,58,47,85,115,101,114,115,47,65,115,117,115,47,65,112,112,68,97,116,97,47,76,111,99,97,108,47,80,121,116,104,111,110,47,98,105,110,47,112,121,116,104,111,110,46,101,120,101,0
str_22: db 98,117,105,108,100,58,32,99,111,109,112,105,108,101,114,32,102,97,105,108,101,100,32,116,111,32,98,117,105,108,100,32,98,117,105,108,100,46,98,102,32,97,115,32,97,110,32,111,98,106,101,99,116,0
str_23: db 103,99,99,32,34,37,115,34,32,34,37,115,34,32,45,111,32,34,37,115,34,0
str_24: db 98,117,105,108,100,58,32,71,67,67,32,102,97,105,108,101,100,32,116,111,32,108,105,110,107,32,98,117,105,108,100,46,98,102,0
str_25: db 98,117,105,108,116,32,98,117,105,108,100,101,114,32,37,115,10,0
str_26: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,101,110,117,109,101,114,97,116,101,32,101,120,97,109,112,108,101,115,0
str_27: db 46,98,102,0
str_28: db 0
str_29: db 110,111,115,97,102,101,46,98,102,0
str_30: db 32,45,45,110,111,45,115,97,102,101,45,115,108,111,116,0
str_31: db 46,115,0
str_32: db 46,101,120,101,0
str_33: db 46,111,0
str_34: db 98,117,105,108,100,58,32,99,111,117,108,100,32,110,111,116,32,97,108,108,111,99,97,116,101,32,97,110,32,111,117,116,112,117,116,32,112,97,116,104,0
str_35: db 67,58,47,85,115,101,114,115,47,65,115,117,115,47,65,112,112,68,97,116,97,47,76,111,99,97,108,47,80,121,116,104,111,110,47,98,105,110,47,112,121,116,104,111,110,46,101,120,101,0
str_36: db 37,115,32,34,37,115,47,98,102,111,114,116,104,46,112,121,34,32,34,37,115,34,32,45,79,32,45,115,32,45,116,32,119,105,110,100,111,119,115,32,45,111,32,34,37,115,34,37,115,0
str_37: db 67,58,47,85,115,101,114,115,47,65,115,117,115,47,65,112,112,68,97,116,97,47,76,111,99,97,108,47,80,121,116,104,111,110,47,98,105,110,47,112,121,116,104,111,110,46,101,120,101,0
str_38: db 98,117,105,108,100,58,32,98,102,111,114,116,104,32,102,97,105,108,101,100,32,102,111,114,32,37,115,10,0
str_39: db 67,58,47,85,115,101,114,115,47,65,115,117,115,47,65,112,112,68,97,116,97,47,76,111,99,97,108,47,80,121,116,104,111,110,47,98,105,110,47,112,121,116,104,111,110,46,101,120,101,0
str_40: db 37,115,32,34,37,115,47,98,102,111,114,116,104,46,112,121,34,32,34,37,115,34,32,45,79,32,45,116,32,119,105,110,100,111,119,115,32,45,99,32,45,111,32,34,37,115,34,37,115,0
str_41: db 67,58,47,85,115,101,114,115,47,65,115,117,115,47,65,112,112,68,97,116,97,47,76,111,99,97,108,47,80,121,116,104,111,110,47,98,105,110,47,112,121,116,104,111,110,46,101,120,101,0
str_42: db 98,117,105,108,100,58,32,111,98,106,101,99,116,32,103,101,110,101,114,97,116,105,111,110,32,102,97,105,108,101,100,32,102,111,114,32,37,115,10,0
str_43: db 103,99,99,32,34,37,115,34,32,45,111,32,34,37,115,34,0
str_44: db 98,117,105,108,100,58,32,71,67,67,32,102,97,105,108,101,100,32,102,111,114,32,37,115,10,0
str_45: db 98,117,105,108,116,32,37,115,10,0

section .data

section .text
fn_streq:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcmp
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov eax, [rsp]
    add rsp, 8
    mov ecx, [rsp]
    add rsp, 8
    cmp ecx, eax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_streq
    xor eax, eax
ret_fn_streq:
    mov rsp, rbp
    pop rbp
    ret

fn_string_copy:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strdup
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_string_copy
    xor eax, eax
ret_fn_string_copy:
    mov rsp, rbp
    pop rbp
    ret

fn_string_join:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp+24]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L2
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_string_join
L2:
L1:
    push qword [rbp-16]
    push qword [rbp+16]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcpy
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcat
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-16]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_string_join
    xor eax, eax
ret_fn_string_join:
    mov rsp, rbp
    pop rbp
    ret

fn_path_basename:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, 47
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rax, 92
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L4
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L6
    push qword [rbp+16]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_basename
L6:
L5:
    push qword [rbp-16]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_basename
L4:
L3:
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L8
    push qword [rbp-8]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_basename
L8:
L7:
    push qword [rbp-8]
    push qword [rbp-16]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L10
    push qword [rbp-8]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_basename
L10:
L9:
    push qword [rbp-16]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_basename
    xor eax, eax
ret_fn_path_basename:
    mov rsp, rbp
    pop rbp
    ret

fn_path_dirname:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, 47
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rax, 92
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L12
    push qword [rbp-8]
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
L12:
L11:
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L14
    push qword [rbp-24]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-16]
    push qword [rbp-24]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L16
    push qword [rbp-16]
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
L16:
L15:
L14:
L13:
    push qword [rbp-24]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L18
    lea rax, [str_1]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strdup
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_dirname
L18:
L17:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    push qword [rbp-24]
    push qword [rbp+16]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    push qword [rbp-32]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L20
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
L20:
L19:
    push qword [rbp-32]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-40], rax
    push qword [rbp-40]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L22
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_dirname
L22:
L21:
    push qword [rbp-40]
    push qword [rbp+16]
    push qword [rbp-32]
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp-40]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_dirname
    xor eax, eax
ret_fn_path_dirname:
    mov rsp, rbp
    pop rbp
    ret

fn_path_join:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp+24]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L24
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
L24:
L23:
    push qword [rbp-8]
    push qword [rbp-16]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-24]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    push qword [rbp-32]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L26
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_join
L26:
L25:
    push qword [rbp-32]
    push qword [rbp+16]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcpy
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-24]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L28
    push qword [rbp-32]
    lea rax, [str_2]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcat
    add rsp, 48
    push rax
    add rsp, 8
L28:
L27:
    push qword [rbp-32]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcat
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-32]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_path_join
    xor eax, eax
ret_fn_path_join:
    mov rsp, rbp
    pop rbp
    ret

fn_input:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rbp+16], rcx
    lea rax, [str_3]
    push rax
    push qword [rbp+16]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 64
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L30
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_input
L30:
L29:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
L31:
    push qword [rbp-32]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L32
    sub rsp, 32
    call $getchar
    add rsp, 32
    mov eax, eax
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-40], rax
    push qword [rbp-40]
    mov rax, 10
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-40]
    mov rax, 13
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L34
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    jmp L33
L34:
    push qword [rbp-40]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L36
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    jmp L35
L36:
    push qword [rbp-24]
    mov rax, 1048576
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setae cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L38
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_input
L38:
L37:
    push qword [rbp-24]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-8]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setae cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L40
    push qword [rbp-8]
    mov rax, 2
    push rax
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-16]
    push qword [rbp-8]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $realloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-48], rax
    push qword [rbp-48]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L42
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_input
L42:
L41:
    push qword [rbp-48]
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
L40:
L39:
    push qword [rbp-16]
    push qword [rbp-24]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-40]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    mov [rcx], rax
    movzx eax, byte [rbp-24]
    push rax
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
L35:
L33:
    jmp L31
L32:
    push qword [rbp-16]
    push qword [rbp-24]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    mov [rcx], rax
    movzx eax, byte [rbp-16]
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_input
    xor eax, eax
ret_fn_input:
    mov rsp, rbp
    pop rbp
    ret

fn_keypressed:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    movzx ecx, cl
    mov [rbp+16], rcx
    sub rsp, 32
    call $getchar
    add rsp, 32
    mov eax, eax
    push rax
    mov eax, dword [rbp+16]
    push rax
    mov eax, [rsp]
    add rsp, 8
    mov ecx, [rsp]
    add rsp, 8
    cmp ecx, eax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_keypressed
    xor eax, eax
ret_fn_keypressed:
    mov rsp, rbp
    pop rbp
    ret

fn_lendarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_lendarr
    xor eax, eax
ret_fn_lendarr:
    mov rsp, rbp
    pop rbp
    ret

fn_ptrdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+0]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_ptrdarr
    xor eax, eax
ret_fn_ptrdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_growdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+24]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L44
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_growdarr
L44:
L43:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+24]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 2
    push rax
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rax, 4
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L46
    mov rax, 4
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
L46:
L45:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+0]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    push qword [rbp-8]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $realloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L48
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_growdarr
L48:
L47:
    push qword [rbp-16]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    push qword [rbp-8]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+24], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_growdarr
    xor eax, eax
ret_fn_growdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_initdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+8], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 0
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    push qword [rbp+32]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+24], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 0
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    push qword [rbp+32]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L50
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_initdarr
L50:
L49:
    push qword [rbp+24]
    push qword [rbp+32]
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+0]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_initdarr
    xor eax, eax
ret_fn_initdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_newdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov rax, 32
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L52
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_newdarr
L52:
L51:
    push qword [rbp-8]
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call fn_initdarr
    add rsp, 64
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L54
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_newdarr
L54:
L53:
    push qword [rbp-8]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_newdarr
    xor eax, eax
ret_fn_newdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_freedarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+0]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 0
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 0
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 0
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+24], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    xor eax, eax
ret_fn_freedarr:
    mov rsp, rbp
    pop rbp
    ret

fn_deletedarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_freedarr
    add rsp, 48
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    xor eax, eax
ret_fn_deletedarr:
    mov rsp, rbp
    pop rbp
    ret

fn_cleardarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov rax, 0
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    xor eax, eax
ret_fn_cleardarr:
    mov rsp, rbp
    pop rbp
    ret

fn_adddarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_growdarr
    add rsp, 48
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L56
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_adddarr
L56:
L55:
    push qword [rbp+16]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_ptrdarr
    add rsp, 48
    push rax
    lea rax, [rbp+24]
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_adddarr
    xor eax, eax
ret_fn_adddarr:
    mov rsp, rbp
    pop rbp
    ret

fn_insertdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L58
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_insertdarr
L58:
L57:
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_growdarr
    add rsp, 48
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L60
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_insertdarr
L60:
L59:
    push qword [rbp+16]
    push qword [rbp+24]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_ptrdarr
    add rsp, 48
    push rax
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 40
    call fn_ptrdarr
    add rsp, 56
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    push qword [rbp+24]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memmove
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_ptrdarr
    add rsp, 48
    push rax
    lea rax, [rbp+32]
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_insertdarr
    xor eax, eax
ret_fn_insertdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_removedarr:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    push rcx
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L62
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_removedarr
L62:
L61:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    lea rax, [rbp-8]
    push rax
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 40
    call fn_ptrdarr
    add rsp, 56
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_ptrdarr
    add rsp, 48
    push rax
    push qword [rbp+16]
    push qword [rbp+24]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 40
    call fn_ptrdarr
    add rsp, 56
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    push qword [rbp+24]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memmove
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 8
    add rsp, 8
    push qword [rbp-8]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_removedarr
    xor eax, eax
ret_fn_removedarr:
    mov rsp, rbp
    pop rbp
    ret

fn_popdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L64
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_popdarr
L64:
L63:
    push qword [rbp+16]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_removedarr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_popdarr
    xor eax, eax
ret_fn_popdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_indexdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    push rcx
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L66
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_indexdarr
L66:
L65:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    lea rax, [rbp-8]
    push rax
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 40
    call fn_ptrdarr
    add rsp, 56
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp-8]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_indexdarr
    xor eax, eax
ret_fn_indexdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_setdarr:
    push rbp
    mov rbp, rsp
    sub rsp, 0
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    push rcx
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L68
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_setdarr
L68:
L67:
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_ptrdarr
    add rsp, 48
    push rax
    lea rax, [rbp+32]
    push rax
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    mov r11, qword [rsp]
    add rsp, 8
    mov qword [rsp], r11
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_setdarr
    xor eax, eax
ret_fn_setdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_join_paths:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp+24]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 2
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L70
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_join_paths
L70:
L69:
    push qword [rbp-16]
    push qword [rbp+16]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcpy
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-16]
    lea rax, [str_4]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcat
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-16]
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcat
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-16]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_join_paths
    xor eax, eax
ret_fn_join_paths:
    mov rsp, rbp
    pop rbp
    ret

fn_basename:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, 92
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rax, 47
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L72
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L74
    push qword [rbp+16]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_basename
L74:
L73:
    push qword [rbp-16]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_basename
L72:
L71:
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L76
    push qword [rbp-8]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_basename
L76:
L75:
    push qword [rbp-8]
    push qword [rbp-16]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L78
    push qword [rbp-8]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_basename
L78:
L77:
    push qword [rbp-16]
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_basename
    xor eax, eax
ret_fn_basename:
    mov rsp, rbp
    pop rbp
    ret

fn_replace_extension:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+16]
    mov rax, 46
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L80
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    jmp L79
L80:
    push qword [rbp-8]
    push qword [rbp+16]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    sub rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
L79:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
    push qword [rbp-16]
    push qword [rbp+24]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 1
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
    push qword [rbp-24]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    push qword [rbp-32]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L82
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_replace_extension
L82:
L81:
    push qword [rbp-32]
    push qword [rbp+16]
    push qword [rbp-16]
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp-32]
    push qword [rbp-16]
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp+24]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcpy
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-32]
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_fn_replace_extension
    xor eax, eax
ret_fn_replace_extension:
    mov rsp, rbp
    pop rbp
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 208
    mov rax, 4096
    push rax
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L84
    lea rax, [str_5]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L84:
L83:
    push qword [rbp-8]
    mov rax, 4096
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $get_builder_root
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L86
    lea rax, [str_6]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L86:
L85:
    push qword [rbp-8]
    lea rax, [str_7]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-16], rax
    push qword [rbp-8]
    lea rax, [str_8]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-24], rax
    push qword [rbp-16]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-24]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L88
    lea rax, [str_9]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-24]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L88:
L87:
    push qword [rbp-24]
    lea rax, [str_10]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-32], rax
    push qword [rbp-24]
    lea rax, [str_11]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-40], rax
    push qword [rbp-24]
    lea rax, [str_12]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-48], rax
    push qword [rbp-32]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-40]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    push qword [rbp-48]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L90
    lea rax, [str_13]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L90:
L89:
    push qword [rbp-32]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $ensure_directory
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-40]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $ensure_directory
    add rsp, 40
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    push qword [rbp-48]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $ensure_directory
    add rsp, 40
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L92
    lea rax, [str_14]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L92:
L91:
    push qword [rbp-24]
    lea rax, [str_15]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-56], rax
    push qword [rbp-24]
    lea rax, [str_16]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-64], rax
    push qword [rbp-48]
    lea rax, [str_17]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-72], rax
    push qword [rbp-40]
    lea rax, [str_18]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-80], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-88], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-96], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-104], rax
    sub rsp, 32
    call $is_canonical_builder
    add rsp, 32
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L94
    lea rax, [str_19]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-56]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-72]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 96
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-88], rax
    push qword [rbp-88]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-96], rax
    push qword [rbp-96]
    push qword [rbp-88]
    lea rax, [str_20]
    push rax
    lea rax, [str_21]
    push rax
    push qword [rbp-8]
    push qword [rbp-56]
    push qword [rbp-72]
    mov rcx, qword [rsp+48]
    mov rdx, qword [rsp+40]
    mov r8, qword [rsp+32]
    mov r9, qword [rsp+24]
    sub rsp, 56
    mov r11, qword [rsp+72]
    mov [rsp+32], r11
    mov r11, qword [rsp+64]
    mov [rsp+40], r11
    mov r11, qword [rsp+56]
    mov [rsp+48], r11
    call $snprintf
    add rsp, 112
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $system
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-104], rax
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-104]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L96
    lea rax, [str_22]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L96:
L95:
    push qword [rbp-72]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp-64]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-80]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 80
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-88], rax
    push qword [rbp-88]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-96], rax
    push qword [rbp-96]
    push qword [rbp-88]
    lea rax, [str_23]
    push rax
    push qword [rbp-72]
    push qword [rbp-64]
    push qword [rbp-80]
    mov rcx, qword [rsp+40]
    mov rdx, qword [rsp+32]
    mov r8, qword [rsp+24]
    mov r9, qword [rsp+16]
    sub rsp, 48
    mov r11, qword [rsp+56]
    mov [rsp+32], r11
    mov r11, qword [rsp+48]
    mov [rsp+40], r11
    call $snprintf
    add rsp, 96
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $system
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-104], rax
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-72]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $remove
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-104]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L98
    lea rax, [str_24]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L98:
L97:
    lea rax, [str_25]
    push rax
    push qword [rbp-80]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
L94:
L93:
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $get_children
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-112], rax
    push qword [rbp-112]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L100
    lea rax, [str_26]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-24]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L100:
L99:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-120], rax
    push qword [rbp-112]
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-120], rax
L101:
    push qword [rbp-120]
    mov rax, [rsp]
    add rsp, 8
    mov rax, qword [rax]
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L102
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-128], rax
    push qword [rbp-120]
    mov rax, [rsp]
    add rsp, 8
    mov rax, qword [rax]
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-128], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-136], rax
    push qword [rbp-128]
    mov rax, 46
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-136], rax
    push qword [rbp-136]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L104
    push qword [rbp-136]
    lea rax, [str_27]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcmp
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L106
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-144], rax
    push qword [rbp-128]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_basename
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-144], rax
    lea rax, [str_28]
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-152], rax
    push qword [rbp-144]
    lea rax, [str_29]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strcmp
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L108
    lea rax, [str_30]
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-152], rax
L108:
L107:
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-160], rax
    push qword [rbp-144]
    lea rax, [str_31]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_replace_extension
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-160], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-168], rax
    push qword [rbp-144]
    lea rax, [str_32]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_replace_extension
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-168], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-176], rax
    push qword [rbp-32]
    push qword [rbp-160]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-176], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-184], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-192], rax
    push qword [rbp-144]
    lea rax, [str_33]
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_replace_extension
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-192], rax
    push qword [rbp-48]
    push qword [rbp-192]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-184], rax
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-200], rax
    push qword [rbp-40]
    push qword [rbp-168]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_join_paths
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-200], rax
    push qword [rbp-176]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-184]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    push qword [rbp-200]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    sete cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    or rcx, rax
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L110
    lea rax, [str_34]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $puts
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L110:
L109:
    lea rax, [str_35]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-128]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-176]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-152]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 112
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-88], rax
    push qword [rbp-88]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-96], rax
    push qword [rbp-96]
    push qword [rbp-88]
    lea rax, [str_36]
    push rax
    lea rax, [str_37]
    push rax
    push qword [rbp-8]
    push qword [rbp-128]
    push qword [rbp-176]
    push qword [rbp-152]
    mov rcx, qword [rsp+56]
    mov rdx, qword [rsp+48]
    mov r8, qword [rsp+40]
    mov r9, qword [rsp+32]
    sub rsp, 64
    mov r11, qword [rsp+88]
    mov [rsp+32], r11
    mov r11, qword [rsp+80]
    mov [rsp+40], r11
    mov r11, qword [rsp+72]
    mov [rsp+48], r11
    mov r11, qword [rsp+64]
    mov [rsp+56], r11
    call $snprintf
    add rsp, 128
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $system
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-104], rax
    push qword [rbp-104]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L112
    lea rax, [str_38]
    push rax
    push qword [rbp-128]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L112:
L111:
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    lea rax, [str_39]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-128]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    push qword [rbp-184]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 112
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-88], rax
    push qword [rbp-88]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-96], rax
    push qword [rbp-96]
    push qword [rbp-88]
    lea rax, [str_40]
    push rax
    lea rax, [str_41]
    push rax
    push qword [rbp-8]
    push qword [rbp-128]
    push qword [rbp-184]
    push qword [rbp-152]
    mov rcx, qword [rsp+56]
    mov rdx, qword [rsp+48]
    mov r8, qword [rsp+40]
    mov r9, qword [rsp+32]
    sub rsp, 64
    mov r11, qword [rsp+88]
    mov [rsp+32], r11
    mov r11, qword [rsp+80]
    mov [rsp+40], r11
    mov r11, qword [rsp+72]
    mov [rsp+48], r11
    mov r11, qword [rsp+64]
    mov [rsp+56], r11
    call $snprintf
    add rsp, 128
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $system
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-104], rax
    push qword [rbp-104]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L114
    lea rax, [str_42]
    push rax
    push qword [rbp-128]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L114:
L113:
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-200]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    push rax
    push qword [rbp-184]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call $strlen
    add rsp, 40
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, 64
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-88], rax
    push qword [rbp-88]
    mov rax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-96], rax
    push qword [rbp-96]
    push qword [rbp-88]
    lea rax, [str_43]
    push rax
    push qword [rbp-184]
    push qword [rbp-200]
    mov rcx, qword [rsp+32]
    mov rdx, qword [rsp+24]
    mov r8, qword [rsp+16]
    mov r9, qword [rsp+8]
    sub rsp, 40
    mov r11, qword [rsp+40]
    mov [rsp+32], r11
    call $snprintf
    add rsp, 80
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $system
    add rsp, 48
    mov eax, eax
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-104], rax
    push qword [rbp-184]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $remove
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-104]
    mov rax, 0
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    push rcx
    mov rax, [rsp]
    add rsp, 8
    test rax, rax
    jz L116
    lea rax, [str_44]
    push rax
    push qword [rbp-128]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov rax, 1
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $exit
    add rsp, 48
L116:
L115:
    push qword [rbp-96]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    lea rax, [str_45]
    push rax
    push qword [rbp-200]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    push qword [rbp-160]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-192]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-168]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-176]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-184]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-200]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
L106:
L105:
L104:
L103:
    push qword [rbp-120]
    mov rax, 8
    push rax
    mov rax, [rsp]
    add rsp, 8
    mov rcx, [rsp]
    add rsp, 8
    add rcx, rax
    push rcx
    mov rax, qword [rsp]
    add rsp, 8
    mov [rbp-120], rax
    jmp L101
L102:
    push qword [rbp-112]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free_children
    add rsp, 48
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-24]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-32]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-40]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-48]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-56]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-64]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-72]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-80]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    mov rax, 0
    push rax
    mov rax, qword [rsp]
    add rsp, 8
    jmp ret_main
    xor eax, eax
ret_main:
    mov rsp, rbp
    pop rbp
    ret

