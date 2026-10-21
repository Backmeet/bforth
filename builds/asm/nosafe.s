bits 64
default rel

extern $printf
extern $exit
extern $malloc
global main

section .rdata
fmt_llu db "%llu", 10, 0
fmt_lld db "%lld", 10, 0
fmt_c   db "%c", 0
fmt_s   db "%s", 10, 0
fmt_stack_fault db "runtime error: stack underflow in function %s (line %d): the function popped more than it pushed and went below its own frame (the home rbp / the stack pointer it was called with)", 10, 0
fn_add3_name: db "add3", 0
fn_getc_name: db "getc", 0
fn_twice_name: db "twice", 0
main_name: db "main", 0

section .data

section .text
fn_add3:
    push rbp
    mov rbp, rsp
    mov [rbp+16], rcx
    mov [rbp+24], rdx
    mov [rbp+32], r8
    push qword [rbp+16]
    push qword [rbp+24]
    mov rax, qword [rbp+32]
    push rax
    lea r11, [rbp-0-8]
    cmp rsp, r11
    ja fn_add3_sf0
    pop rax
    lea r11, [rbp-0-8]
    cmp rsp, r11
    ja fn_add3_sf0
    pop rcx
    add rcx, rax
    push rcx
    lea r11, [rbp-0-8]
    cmp rsp, r11
    ja fn_add3_sf0
    pop rax
    lea r11, [rbp-0-8]
    cmp rsp, r11
    ja fn_add3_sf0
    pop rcx
    add rcx, rax
    push rcx
    lea r11, [rbp-0-8]
    cmp rsp, r11
    ja fn_add3_sf0
    pop rax
ret_fn_add3:
    mov rsp, rbp
    pop rbp
    ret
fn_add3_sf0:
fn_add3_stack_fault:
    lea rcx, [rel fmt_stack_fault]
    lea rdx, [rel fn_add3_name]
    and rsp, -16
    sub rsp, 32
    call $printf
    mov ecx, 1
    call $exit

fn_getc:
    push rbp
    mov rbp, rsp
    mov eax, 65
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-0-1]
    cmp rsp, r11
    ja fn_getc_sf0
    movzx eax, byte [rsp]
    add rsp, 1
ret_fn_getc:
    mov rsp, rbp
    pop rbp
    ret
fn_getc_sf0:
fn_getc_stack_fault:
    lea rcx, [rel fmt_stack_fault]
    lea rdx, [rel fn_getc_name]
    and rsp, -16
    sub rsp, 32
    call $printf
    mov ecx, 1
    call $exit

fn_twice:
    push rbp
    mov rbp, rsp
    mov ecx, ecx
    mov [rbp+16], rcx
    mov eax, dword [rbp+16]
    sub rsp, 4
    mov dword [rsp], eax
    lea r11, [rbp-0-4]
    cmp rsp, r11
    ja fn_twice_sf0
    mov eax, dword [rsp]
    sub rsp, 4
    mov dword [rsp], eax
    lea r11, [rbp-0-4]
    cmp rsp, r11
    ja fn_twice_sf0
    mov eax, [rsp]
    add rsp, 4
    lea r11, [rbp-0-4]
    cmp rsp, r11
    ja fn_twice_sf0
    mov ecx, [rsp]
    add rsp, 4
    add ecx, eax
    sub rsp, 4
    mov dword [rsp], ecx
    lea r11, [rbp-0-4]
    cmp rsp, r11
    ja fn_twice_sf0
    mov eax, dword [rsp]
    add rsp, 4
ret_fn_twice:
    mov rsp, rbp
    pop rbp
    ret
fn_twice_sf0:
fn_twice_stack_fault:
    lea rcx, [rel fmt_stack_fault]
    lea rdx, [rel fn_twice_name]
    and rsp, -16
    sub rsp, 32
    call $printf
    mov ecx, 1
    call $exit

main:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    mov eax, 200
    sub rsp, 1
    mov byte [rsp], al
    mov eax, 100
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf0
    mov al, [rsp]
    add rsp, 1
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf0
    mov cl, [rsp]
    add rsp, 1
    add cl, al
    sub rsp, 1
    mov byte [rsp], cl
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf0
    lea rcx, [rel fmt_llu]
    movzx edx, byte [rsp]
    sub rsp, 31
    call $printf
    add rsp, 32
    mov eax, 4294967289
    sub rsp, 4
    mov dword [rsp], eax
    mov eax, 2
    sub rsp, 4
    mov dword [rsp], eax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf1
    mov ecx, dword [rsp+4]
    mov r8d, dword [rsp+0]
    mov eax, ecx
    cdq
    idiv r8d
    mov dword [rsp+4], eax
    add rsp, 4
    lea r11, [rbp-96-4]
    cmp rsp, r11
    ja main_sf1
    lea rcx, [rel fmt_lld]
    movsxd rdx, dword [rsp]
    sub rsp, 28
    call $printf
    add rsp, 32
    mov eax, 5
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf2
    pop qword [rbp-8]
    push qword [rbp-8]
    mov eax, 3
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf3
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf3
    pop rcx
    add rcx, rax
    push rcx
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf3
    pop qword [rbp-8]
    mov rax, qword [rbp-8]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf4
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    mov eax, 250
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf5
    movzx eax, byte [rsp]
    add rsp, 1
    movzx eax, al
    mov [rbp-16], rax
    movzx eax, byte [rbp-16]
    sub rsp, 1
    mov byte [rsp], al
    mov eax, 10
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf6
    mov al, [rsp]
    add rsp, 1
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf6
    mov cl, [rsp]
    add rsp, 1
    add cl, al
    sub rsp, 1
    mov byte [rsp], cl
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf6
    movzx eax, byte [rsp]
    add rsp, 1
    movzx eax, al
    mov [rbp-16], rax
    movzx eax, byte [rbp-16]
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf7
    lea rcx, [rel fmt_llu]
    movzx edx, byte [rsp]
    sub rsp, 31
    call $printf
    add rsp, 32
    push 1
    push 2
    mov eax, 3
    push rax
    mov rcx, qword [rsp+16]
    mov rdx, qword [rsp+8]
    mov r8, qword [rsp+0]
    sub rsp, 40
    call fn_add3
    add rsp, 64
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf8
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    call fn_getc
    add rsp, 31
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf9
    lea rcx, [rel fmt_llu]
    movzx edx, byte [rsp]
    sub rsp, 31
    call $printf
    add rsp, 32
    mov eax, 4294967275
    sub rsp, 4
    mov dword [rsp], eax
    mov ecx, dword [rsp+0]
    sub rsp, 44
    call fn_twice
    add rsp, 44
    mov dword [rsp], eax
    lea r11, [rbp-96-4]
    cmp rsp, r11
    ja main_sf10
    lea rcx, [rel fmt_lld]
    movsxd rdx, dword [rsp]
    sub rsp, 28
    call $printf
    add rsp, 32
    mov eax, 7
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf11
    movzx eax, byte [rsp]
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf11
    mov al, [rsp]
    add rsp, 1
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf11
    mov cl, [rsp]
    add rsp, 1
    add cl, al
    sub rsp, 1
    mov byte [rsp], cl
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf11
    lea rcx, [rel fmt_llu]
    movzx edx, byte [rsp]
    sub rsp, 31
    call $printf
    add rsp, 32
    push 1
    mov eax, 2
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf12
    mov rax, qword [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rsp], rcx
    mov qword [rsp+8], rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf12
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf12
    pop rcx
    sub rcx, rax
    push rcx
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf12
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    push 1
    mov eax, 2
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf13
    pop r11
    mov qword [rsp], r11
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf13
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    push 1
    mov eax, 2
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf14
    mov rax, qword [rsp+8]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf14
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf14
    pop rcx
    add rcx, rax
    push rcx
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf14
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf14
    pop rcx
    add rcx, rax
    push rcx
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf14
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    mov qword [rbp-32], 0
    mov qword [rbp-24], 0
    lea rax, [rbp-32]
    mov [rbp-40], rax
    mov eax, 3
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf15
    pop qword [rbp-32]
    mov eax, 4
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf15
    pop qword [rbp-24]
    mov rax, qword [rbp-40]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf16
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf16
    pop r11
    mov qword [rsp], r11
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf16
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    push 10
    mov rax, qword [rbp-40]
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf17
    mov rax, [rsp]
    mov rcx, qword [rsp+8]
    mov qword [rax+0], rcx
    mov [rsp+8], rax
    add rsp, 8
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf17
    add rsp, 8
    mov rax, qword [rbp-40]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf18
    mov rax, [rsp]
    mov rax, qword [rax+0]
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf18
    pop r11
    mov qword [rsp], r11
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf18
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    mov qword [rbp-56], 0
    mov qword [rbp-48], 0
    lea rax, [rbp-56]
    mov [rbp-64], rax
    mov eax, 200
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf19
    movzx eax, byte [rsp]
    add rsp, 1
    mov byte [rbp-56], al
    mov eax, 4294967291
    sub rsp, 4
    mov dword [rsp], eax
    lea r11, [rbp-96-4]
    cmp rsp, r11
    ja main_sf19
    mov eax, dword [rsp]
    add rsp, 4
    mov dword [rbp-52], eax
    mov eax, 9
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf19
    pop qword [rbp-48]
    xor eax, eax
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf20
    movzx eax, byte [rsp]
    add rsp, 1
    movzx eax, al
    mov [rbp-72], rax
    mov rax, qword [rbp-64]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf21
    mov rax, [rsp]
    movzx eax, byte [rax+0]
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf21
    movzx eax, byte [rsp]
    add rsp, 1
    movzx eax, al
    mov [rbp-72], rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf22
    add rsp, 8
    movzx eax, byte [rbp-72]
    sub rsp, 1
    mov byte [rsp], al
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf23
    lea rcx, [rel fmt_llu]
    movzx edx, byte [rsp]
    sub rsp, 31
    call $printf
    add rsp, 32
    mov rax, qword [rbp-64]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf24
    mov rax, [rsp]
    mov rax, qword [rax+8]
    push rax
    lea r11, [rbp-96-16]
    cmp rsp, r11
    ja main_sf24
    pop r11
    mov qword [rsp], r11
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf24
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 32
    call $printf
    add rsp, 32
    push 10
    push 20
    push 30
    sub rsp, 24
    mov r11, qword [rsp+40]
    mov [rsp+0], r11
    mov r11, qword [rsp+32]
    mov [rsp+8], r11
    mov r11, qword [rsp+24]
    mov [rsp+16], r11
    mov r11, [rsp+16]
    mov [rsp+40], r11
    mov r11, [rsp+8]
    mov [rsp+32], r11
    mov r11, [rsp+0]
    mov [rsp+24], r11
    add rsp, 24
    mov rax, rsp
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf25
    pop qword [rbp-80]
    mov rax, qword [rbp-80]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf26
    mov eax, 1
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf26
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf26
    pop rcx
    imul rax, rax, 8
    add rcx, rax
    push qword [rcx]
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf26
    lea rcx, [rel fmt_llu]
    pop rdx
    sub rsp, 40
    call $printf
    add rsp, 40
    mov eax, 1
    sub rsp, 1
    mov byte [rsp], al
    mov eax, 2
    sub rsp, 1
    mov byte [rsp], al
    mov eax, 3
    sub rsp, 1
    mov byte [rsp], al
    sub rsp, 8
    mov qword [rsp+0], 0
    movzx r11d, byte [rsp+10]
    mov [rsp+0], r11b
    movzx r11d, byte [rsp+9]
    mov [rsp+1], r11b
    movzx r11d, byte [rsp+8]
    mov [rsp+2], r11b
    mov r11, [rsp+0]
    mov [rsp+3], r11
    add rsp, 3
    mov rax, rsp
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf27
    pop qword [rbp-88]
    mov rax, qword [rbp-88]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf28
    mov eax, 2
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf28
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf28
    pop rcx
    add rcx, rax
    movzx ecx, byte [rcx]
    sub rsp, 1
    mov byte [rsp], cl
    lea r11, [rbp-96-1]
    cmp rsp, r11
    ja main_sf28
    lea rcx, [rel fmt_llu]
    movzx edx, byte [rsp]
    sub rsp, 31
    call $printf
    add rsp, 32
    mov eax, 16
    push rax
    mov rcx, qword [rsp+0]
    sub rsp, 40
    call $malloc
    add rsp, 48
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf29
    pop qword [rbp-96]
    push qword [rbp-96]
    mov rax, 1234605616436508552
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf30
    pop rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf30
    pop rcx
    mov [rcx], rax
    mov rax, qword [rbp-96]
    push rax
    lea r11, [rbp-96-8]
    cmp rsp, r11
    ja main_sf31
    pop rax
    mov eax, dword [rax]
    sub rsp, 4
    mov dword [rsp], eax
    lea r11, [rbp-96-4]
    cmp rsp, r11
    ja main_sf31
    lea rcx, [rel fmt_lld]
    movsxd rdx, dword [rsp]
    sub rsp, 28
    call $printf
    add rsp, 32
    xor eax, eax
ret_main:
    mov rsp, rbp
    pop rbp
    ret
main_sf0:
    mov r8d, 31
    jmp main_stack_fault
main_sf1:
    mov r8d, 32
    jmp main_stack_fault
main_sf2:
    mov r8d, 33
    jmp main_stack_fault
main_sf3:
    mov r8d, 34
    jmp main_stack_fault
main_sf4:
    mov r8d, 35
    jmp main_stack_fault
main_sf5:
    mov r8d, 36
    jmp main_stack_fault
main_sf6:
    mov r8d, 37
    jmp main_stack_fault
main_sf7:
    mov r8d, 38
    jmp main_stack_fault
main_sf8:
    mov r8d, 39
    jmp main_stack_fault
main_sf9:
    mov r8d, 40
    jmp main_stack_fault
main_sf10:
    mov r8d, 41
    jmp main_stack_fault
main_sf11:
    mov r8d, 42
    jmp main_stack_fault
main_sf12:
    mov r8d, 43
    jmp main_stack_fault
main_sf13:
    mov r8d, 44
    jmp main_stack_fault
main_sf14:
    mov r8d, 45
    jmp main_stack_fault
main_sf15:
    mov r8d, 46
    jmp main_stack_fault
main_sf16:
    mov r8d, 47
    jmp main_stack_fault
main_sf17:
    mov r8d, 48
    jmp main_stack_fault
main_sf18:
    mov r8d, 49
    jmp main_stack_fault
main_sf19:
    mov r8d, 50
    jmp main_stack_fault
main_sf20:
    mov r8d, 51
    jmp main_stack_fault
main_sf21:
    mov r8d, 52
    jmp main_stack_fault
main_sf22:
    mov r8d, 53
    jmp main_stack_fault
main_sf23:
    mov r8d, 54
    jmp main_stack_fault
main_sf24:
    mov r8d, 55
    jmp main_stack_fault
main_sf25:
    mov r8d, 56
    jmp main_stack_fault
main_sf26:
    mov r8d, 57
    jmp main_stack_fault
main_sf27:
    mov r8d, 58
    jmp main_stack_fault
main_sf28:
    mov r8d, 59
    jmp main_stack_fault
main_sf29:
    mov r8d, 60
    jmp main_stack_fault
main_sf30:
    mov r8d, 61
    jmp main_stack_fault
main_sf31:
main_stack_fault:
    lea rcx, [rel fmt_stack_fault]
    lea rdx, [rel main_name]
    and rsp, -16
    sub rsp, 32
    call $printf
    mov ecx, 1
    call $exit

