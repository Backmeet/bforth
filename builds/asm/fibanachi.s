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
extern $fflush
extern $fopen
extern $fclose
extern $fgets
extern $fputs
extern $fread
extern $fwrite
extern $remove
global main

section .rdata
fmt_llu db "%llu", 10, 0
fmt_lld db "%lld", 10, 0
fmt_c   db "%c", 0
fmt_s   db "%s", 10, 0
str_1: db 46,0
str_2: db 47,0
str_3: db 37,115,0
str_4: db 61,61,32,116,104,101,32,102,105,114,115,116,32,49,54,32,70,105,98,111,110,97,99,99,105,32,110,117,109,98,101,114,115,32,40,108,111,111,112,41,32,61,61,0
str_5: db 102,105,98,40,37,50,108,108,100,41,32,61,32,37,108,108,100,10,0
str_6: db 61,61,32,114,101,99,117,114,115,105,111,110,32,118,115,32,108,111,111,112,32,61,61,0
str_7: db 114,101,99,117,114,115,105,118,101,32,102,105,98,40,50,48,41,32,61,32,37,108,108,100,10,0
str_8: db 108,111,111,112,32,32,32,32,32,32,102,105,98,40,50,48,41,32,61,32,37,108,108,100,10,0
str_9: db 61,61,32,54,52,45,98,105,116,32,114,97,110,103,101,32,61,61,0
str_10: db 102,105,98,40,57,48,41,32,32,61,32,37,108,108,117,10,0
str_11: db 61,61,32,97,32,116,97,98,108,101,32,98,117,105,108,116,32,105,110,32,97,32,100,97,114,114,32,61,61,0
str_12: db 116,97,98,108,101,32,104,111,108,100,115,32,37,108,108,100,32,110,117,109,98,101,114,115,44,32,116,104,101,32,108,97,115,116,32,105,115,32,37,108,108,100,10,0
str_13: db 116,97,98,108,101,32,97,110,100,32,108,111,111,112,32,97,103,114,101,101,0
str_14: db 77,73,83,77,65,84,67,72,0

section .data

section .text
fn_streq:
    push rbp
    mov rbp, rsp
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
    push 0
    mov eax, [rsp]
    add rsp, 8
    mov ecx, [rsp]
    add rsp, 8
    cmp ecx, eax
    sete cl
    movzx ecx, cl
    mov rax, rcx
ret_fn_streq:
    mov rsp, rbp
    pop rbp
    ret

fn_string_copy:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strdup
    add rsp, 48
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
    xor eax, eax
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
    pop rcx
    add rcx, rax
    add rcx, 1
    mov rax, rcx
    mov [rbp-8], rax
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    mov [rbp-16], rax
    mov rcx, qword [rbp-16]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L2
    xor eax, eax
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
    mov rax, qword [rbp-16]
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
    mov eax, 47
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    mov [rbp-8], rax
    push qword [rbp+16]
    mov eax, 92
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    mov [rbp-16], rax
    mov rcx, qword [rbp-8]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L4
    mov rcx, qword [rbp-16]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L6
    mov rax, qword [rbp+16]
    jmp ret_fn_path_basename
L6:
L5:
    mov rcx, qword [rbp-16]
    add rcx, 1
    mov rax, rcx
    jmp ret_fn_path_basename
L4:
L3:
    mov rcx, qword [rbp-16]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L8
    mov rcx, qword [rbp-8]
    add rcx, 1
    mov rax, rcx
    jmp ret_fn_path_basename
L8:
L7:
    push qword [rbp-8]
    mov rax, qword [rbp-16]
    pop rcx
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L10
    mov rcx, qword [rbp-8]
    add rcx, 1
    mov rax, rcx
    jmp ret_fn_path_basename
L10:
L9:
    mov rcx, qword [rbp-16]
    add rcx, 1
    mov rax, rcx
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
    mov eax, 47
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    mov [rbp-8], rax
    push qword [rbp+16]
    mov eax, 92
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $strrchr
    add rsp, 48
    mov [rbp-16], rax
    mov qword [rbp-24], 0
    mov rcx, qword [rbp-8]
    cmp rcx, 0
    setne cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L12
    mov rax, qword [rbp-8]
    mov [rbp-24], rax
L12:
L11:
    mov rcx, qword [rbp-16]
    cmp rcx, 0
    setne cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L14
    mov rcx, qword [rbp-24]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    push rcx
    push qword [rbp-16]
    mov rax, qword [rbp-24]
    pop rcx
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    mov rax, rcx
    pop rcx
    or rcx, rax
    mov rax, rcx
    test rax, rax
    jz L16
    mov rax, qword [rbp-16]
    mov [rbp-24], rax
L16:
L15:
L14:
L13:
    mov rcx, qword [rbp-24]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L18
    lea rax, [str_1]
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strdup
    add rsp, 48
    jmp ret_fn_path_dirname
L18:
L17:
    mov qword [rbp-32], 0
    push qword [rbp-24]
    mov rax, qword [rbp+16]
    pop rcx
    sub rcx, rax
    mov [rbp-32], rcx
    mov rcx, qword [rbp-32]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L20
    mov eax, 1
    mov [rbp-32], rax
L20:
L19:
    mov rcx, qword [rbp-32]
    add rcx, 1
    push rcx
    mov eax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    mov [rbp-40], rax
    mov rcx, qword [rbp-40]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L22
    xor eax, eax
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
    mov rax, qword [rbp-40]
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
    xor eax, eax
    mov [rbp-8], rax
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    mov [rbp-8], rax
    xor eax, eax
    mov [rbp-16], rax
    push qword [rbp+24]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $strlen
    add rsp, 48
    mov [rbp-16], rax
    mov qword [rbp-24], 1
    mov rcx, qword [rbp-8]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L24
    xor eax, eax
    mov [rbp-24], rax
L24:
L23:
    push qword [rbp-8]
    mov rax, qword [rbp-16]
    pop rcx
    add rcx, rax
    push rcx
    mov rax, qword [rbp-24]
    pop rcx
    add rcx, rax
    add rcx, 1
    push rcx
    mov eax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    mov [rbp-32], rax
    mov rcx, qword [rbp-32]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L26
    xor eax, eax
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
    mov rcx, qword [rbp-24]
    cmp rcx, 0
    setne cl
    movzx ecx, cl
    mov rax, rcx
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
    mov rax, qword [rbp-32]
ret_fn_path_join:
    mov rsp, rbp
    pop rbp
    ret

fn_input:
    push rbp
    mov rbp, rsp
    sub rsp, 64
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
    xor eax, eax
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $fflush
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    mov qword [rbp-8], 64
    push qword [rbp-8]
    mov eax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $calloc
    add rsp, 48
    mov [rbp-16], rax
    mov rcx, qword [rbp-16]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L30
    xor eax, eax
    jmp ret_fn_input
L30:
L29:
    mov qword [rbp-24], 0
    xor eax, eax
    mov [rbp-32], rax
L31:
    mov rcx, qword [rbp-32]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L32
    sub rsp, 32
    call $getchar
    add rsp, 32
    mov eax, eax
    mov [rbp-40], rax
    mov rcx, qword [rbp-40]
    cmp rcx, 10
    sete cl
    movzx ecx, cl
    push rcx
    mov rcx, qword [rbp-40]
    cmp rcx, 13
    sete cl
    movzx ecx, cl
    mov rax, rcx
    pop rcx
    or rcx, rax
    mov rax, rcx
    test rax, rax
    jz L34
    mov eax, 1
    mov [rbp-32], rax
    jmp L33
L34:
    mov rcx, qword [rbp-40]
    cmp rcx, 0
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L36
    mov eax, 1
    mov [rbp-32], rax
    jmp L35
L36:
    mov rcx, qword [rbp-24]
    add rcx, 1
    push rcx
    mov rax, qword [rbp-8]
    pop rcx
    cmp rcx, rax
    setae cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L38
    mov qword [rbp-48], 0
    push qword [rbp-8]
    push 2
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    pop qword [rbp-48]
    xor eax, eax
    mov [rbp-56], rax
    push qword [rbp-16]
    push qword [rbp-48]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $realloc
    add rsp, 48
    mov [rbp-56], rax
    mov rcx, qword [rbp-56]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L40
    push qword [rbp-16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    xor eax, eax
    jmp ret_fn_input
L40:
L39:
    mov rax, qword [rbp-56]
    mov [rbp-16], rax
    mov rax, qword [rbp-48]
    mov [rbp-8], rax
L38:
L37:
    push qword [rbp-16]
    mov rax, qword [rbp-24]
    pop rcx
    add rcx, rax
    push rcx
    mov rax, qword [rbp-40]
    pop rcx
    mov byte [rcx], al
    mov rcx, qword [rbp-24]
    add rcx, 1
    mov rax, rcx
    mov [rbp-24], rax
L35:
L33:
    jmp L31
L32:
    push qword [rbp-16]
    mov rax, qword [rbp-24]
    pop rcx
    add rcx, rax
    push rcx
    xor eax, eax
    pop rcx
    mov byte [rcx], al
    mov rax, qword [rbp-16]
ret_fn_input:
    mov rsp, rbp
    pop rbp
    ret

fn_keypressed:
    push rbp
    mov rbp, rsp
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
    mov rax, rcx
ret_fn_keypressed:
    mov rsp, rbp
    pop rbp
    ret

fn_lendarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rax
ret_fn_lendarr:
    mov rsp, rbp
    pop rbp
    ret

fn_ptrdarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+0]
    mov qword [rsp], r11
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+8]
    mov qword [rsp], r11
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    pop rax
    pop rcx
    add rcx, rax
    mov rax, rcx
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+24]
    mov qword [rsp], r11
    pop rax
    pop rcx
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L42
    mov eax, 1
    jmp ret_fn_growdarr
L42:
L41:
    mov qword [rbp-8], 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+24]
    mov qword [rsp], r11
    push 2
    mov rcx, qword [rsp+8]
    mov r8, qword [rsp+0]
    mov rax, rcx
    mul r8
    mov [rsp+8], rax
    add rsp, 8
    pop qword [rbp-8]
    mov rcx, qword [rbp-8]
    cmp rcx, 4
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L44
    mov eax, 4
    mov [rbp-8], rax
L44:
L43:
    mov qword [rbp-16], 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+0]
    mov qword [rsp], r11
    push qword [rbp-8]
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+8]
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
    mov [rbp-16], rax
    mov rcx, qword [rbp-16]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L46
    xor eax, eax
    jmp ret_fn_growdarr
L46:
L45:
    push qword [rbp-16]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 16
    push qword [rbp-8]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+24], rcx
    mov [rsp+8], rax
    add rsp, 16
    mov eax, 1
ret_fn_growdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_initdarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+8], rcx
    mov [rsp+8], rax
    add rsp, 16
    push 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 16
    push qword [rbp+32]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+24], rcx
    mov [rsp+8], rax
    add rsp, 16
    push 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 16
    mov rcx, qword [rbp+32]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L48
    mov eax, 1
    jmp ret_fn_initdarr
L48:
L47:
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
    add rsp, 16
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+0]
    mov qword [rsp], r11
    pop rcx
    cmp rcx, 0
    setne cl
    movzx ecx, cl
    mov rax, rcx
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
    mov eax, 32
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    mov [rbp-8], rax
    mov rcx, qword [rbp-8]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L50
    xor eax, eax
    jmp ret_fn_newdarr
L50:
L49:
    push qword [rbp-8]
    push qword [rbp+16]
    push qword [rbp+24]
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call fn_initdarr
    add rsp, 64
    mov rcx, rax
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L52
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    xor eax, eax
    jmp ret_fn_newdarr
L52:
L51:
    mov rax, qword [rbp-8]
ret_fn_newdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_freedarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+0]
    mov qword [rsp], rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $free
    add rsp, 48
    push 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 16
    push 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 16
    push 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+24], rcx
    mov [rsp+8], rax
    add rsp, 16
    xor eax, eax
ret_fn_freedarr:
    mov rsp, rbp
    pop rbp
    ret

fn_deletedarr:
    push rbp
    mov rbp, rsp
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
    mov [rbp+16], rcx
    push 0
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 16
    xor eax, eax
ret_fn_cleardarr:
    mov rsp, rbp
    pop rbp
    ret

fn_adddarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_growdarr
    add rsp, 48
    mov rcx, rax
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L54
    xor eax, eax
    jmp ret_fn_adddarr
L54:
L53:
    push qword [rbp+16]
    push qword [rbp+16]
    mov rax, [rsp]
    mov rax, qword [rax+16]
    mov qword [rsp], rax
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
    mov qword [rsp], rax
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rcx
    add rcx, 1
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 16
    mov eax, 1
ret_fn_adddarr:
    mov rsp, rbp
    pop rbp
    ret

fn_insertdarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rax
    pop rcx
    cmp rcx, rax
    seta cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L56
    xor eax, eax
    jmp ret_fn_insertdarr
L56:
L55:
    push qword [rbp+16]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_growdarr
    add rsp, 48
    mov rcx, rax
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L58
    xor eax, eax
    jmp ret_fn_insertdarr
L58:
L57:
    push qword [rbp+16]
    push qword [rbp+24]
    mov eax, 1
    pop rcx
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    mov rax, qword [rbp+24]
    pop rcx
    sub rcx, rax
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+8]
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
    mov qword [rsp], rax
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rcx
    add rcx, 1
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 16
    mov eax, 1
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rax
    pop rcx
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L60
    xor eax, eax
    jmp ret_fn_removedarr
L60:
L59:
    mov qword [rbp-8], 0
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
    mov qword [rsp], rax
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
    mov eax, 1
    pop rcx
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    mov rax, qword [rbp+24]
    pop rcx
    sub rcx, rax
    sub rcx, 1
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+8]
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rcx
    sub rcx, 1
    push rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+16], rcx
    mov [rsp+8], rax
    add rsp, 16
    mov rax, qword [rbp-8]
ret_fn_removedarr:
    mov rsp, rbp
    pop rbp
    ret

fn_popdarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rcx
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L62
    xor eax, eax
    jmp ret_fn_popdarr
L62:
L61:
    push qword [rbp+16]
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    mov eax, 1
    pop rcx
    sub rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_removedarr
    add rsp, 48
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
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rax
    pop rcx
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L64
    xor eax, eax
    jmp ret_fn_indexdarr
L64:
L63:
    mov qword [rbp-8], 0
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
    mov qword [rsp], rax
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    mov rax, qword [rbp-8]
ret_fn_indexdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_setdarr:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+24]
    push qword [rbp+16]
    mov rax, [rsp]
    mov r11, qword [rax+16]
    mov qword [rsp], r11
    pop rax
    pop rcx
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L66
    xor eax, eax
    jmp ret_fn_setdarr
L66:
L65:
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
    mov qword [rsp], rax
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $memcpy
    add rsp, 64
    push rax
    add rsp, 8
    mov eax, 1
ret_fn_setdarr:
    mov rsp, rbp
    pop rbp
    ret

fn_fibrec:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov rcx, qword [rbp+16]
    cmp rcx, 2
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L68
    mov rax, qword [rbp+16]
    jmp ret_fn_fibrec
L68:
L67:
    push qword [rbp+16]
    mov eax, 1
    pop rcx
    sub rcx, rax
    push rcx
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_fibrec
    add rsp, 48
    push rax
    push qword [rbp+16]
    mov eax, 2
    pop rcx
    sub rcx, rax
    push rcx
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call fn_fibrec
    add rsp, 40
    pop rcx
    add rcx, rax
    mov rax, rcx
ret_fn_fibrec:
    mov rsp, rbp
    pop rbp
    ret

fn_fibiter:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp+16], rcx
    mov qword [rbp-8], 0
    mov qword [rbp-16], 1
    xor eax, eax
    mov [rbp-24], rax
L69:
    push qword [rbp-24]
    mov rax, qword [rbp+16]
    pop rcx
    cmp rcx, rax
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L70
    mov qword [rbp-32], 0
    push qword [rbp-8]
    mov rax, qword [rbp-16]
    pop rcx
    add rcx, rax
    mov [rbp-32], rcx
    mov rax, qword [rbp-16]
    mov [rbp-8], rax
    mov rax, qword [rbp-32]
    mov [rbp-16], rax
    mov rcx, qword [rbp-24]
    add rcx, 1
    mov rax, rcx
    mov [rbp-24], rax
    jmp L69
L70:
    mov rax, qword [rbp-8]
ret_fn_fibiter:
    mov rsp, rbp
    pop rbp
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    lea rax, [str_4]
    push rax
    lea rcx, [rel fmt_s]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    xor eax, eax
    mov [rbp-8], rax
L71:
    mov rcx, qword [rbp-8]
    cmp rcx, 16
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L72
    lea rax, [str_5]
    push rax
    push qword [rbp-8]
    push qword [rbp-8]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_fibiter
    add rsp, 48
    push rax
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $printf
    add rsp, 64
    mov eax, eax
    push rax
    add rsp, 8
    mov rcx, qword [rbp-8]
    add rcx, 1
    mov rax, rcx
    mov [rbp-8], rax
    jmp L71
L72:
    lea rax, [str_6]
    push rax
    lea rcx, [rel fmt_s]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    lea rax, [str_7]
    push rax
    mov eax, 20
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call fn_fibrec
    add rsp, 40
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    lea rax, [str_8]
    push rax
    mov eax, 20
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call fn_fibiter
    add rsp, 40
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    lea rax, [str_9]
    push rax
    lea rcx, [rel fmt_s]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    lea rax, [str_10]
    push rax
    mov eax, 90
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call fn_fibiter
    add rsp, 40
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call $printf
    add rsp, 48
    mov eax, eax
    push rax
    add rsp, 8
    lea rax, [str_11]
    push rax
    lea rcx, [rel fmt_s]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    mov qword [rbp-40], 0
    mov qword [rbp-32], 0
    mov qword [rbp-24], 0
    mov qword [rbp-16], 0
    lea rax, [rbp-40]
    mov [rbp-48], rax
    push qword [rbp-48]
    push 8
    mov eax, 4
    push rax
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call fn_initdarr
    add rsp, 64
    push rax
    add rsp, 8
    push qword [rbp-48]
    xor eax, eax
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_adddarr
    add rsp, 48
    push rax
    add rsp, 8
    push qword [rbp-48]
    mov eax, 1
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_adddarr
    add rsp, 48
    push rax
    add rsp, 8
    mov eax, 2
    mov [rbp-56], rax
L73:
    mov rcx, qword [rbp-56]
    cmp rcx, 30
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L74
    push qword [rbp-48]
    push qword [rbp-48]
    push qword [rbp-56]
    mov eax, 1
    pop rcx
    sub rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 40
    call fn_indexdarr
    add rsp, 56
    push rax
    push qword [rbp-48]
    push qword [rbp-56]
    mov eax, 2
    pop rcx
    sub rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_indexdarr
    add rsp, 48
    pop rcx
    add rcx, rax
    push rcx
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_adddarr
    add rsp, 48
    push rax
    add rsp, 8
    mov rcx, qword [rbp-56]
    add rcx, 1
    mov rax, rcx
    mov [rbp-56], rax
    jmp L73
L74:
    lea rax, [str_12]
    push rax
    push qword [rbp-48]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call fn_lendarr
    add rsp, 40
    push rax
    push qword [rbp-48]
    mov eax, 29
    push rax
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_indexdarr
    add rsp, 48
    push rax
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call $printf
    add rsp, 64
    mov eax, eax
    push rax
    add rsp, 8
    mov qword [rbp-64], 0
    push qword [rbp-56]
    xor eax, eax
    push rax
L75:
    mov rcx, qword [rbp-56]
    cmp rcx, 30
    setb cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L76
    push qword [rbp-48]
    push qword [rbp-56]
    mov rcx, qword [rsp+8]
    mov rdx, qword [rsp+0]
    sub rsp, 32
    call fn_indexdarr
    add rsp, 48
    push rax
    push qword [rbp-56]
    mov rcx, qword [rsp+0]
    sub rsp, 32
    call fn_fibiter
    add rsp, 40
    pop rcx
    cmp rcx, rax
    setne cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L78
    mov rcx, qword [rbp-64]
    add rcx, 1
    mov rax, rcx
    mov [rbp-64], rax
L78:
L77:
    mov rcx, qword [rbp-56]
    add rcx, 1
    mov rax, rcx
    mov [rbp-56], rax
    jmp L75
L76:
    mov rcx, qword [rbp-64]
    cmp rcx, 0
    sete cl
    movzx ecx, cl
    mov rax, rcx
    test rax, rax
    jz L80
    lea rax, [str_13]
    push rax
    lea rcx, [rel fmt_s]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    jmp L79
L80:
    lea rax, [str_14]
    push rax
    lea rcx, [rel fmt_s]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
L79:
    push qword [rbp-48]
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call fn_freedarr
    add rsp, 48
    xor eax, eax
ret_main:
    mov rsp, rbp
    pop rbp
    ret

