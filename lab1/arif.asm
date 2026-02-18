BITS 64

global _start

section .data
    a dq 0 ; 8
    b dd 0 ; 4
    c dd 0 ; 4
    d db 0 ; 1
    e dw 0 ; 2

section .text

_start:
    ; делим a / b
    mov rax, [a] ; загружаем обращаясь по адресу a и кладем что по адресу в регистр rax
    cqo ; тк idiv делает rdx:rax то нам надо инициализировать их обоих
    mov ebx, [b]
    movsxd rbx, ebx ; расширяем тк делимое 64 бита

    ; проверка
    cmp rbx, 0
    je subz_err

    idiv rbx
    ; сохраняем
    mov r8, rax


    ; делим с / d
    mov eax, [c]
    cdq
    mov bl, [d]
    movsx ebx, bl

    ; проверка
    cmp ebx, 0
    je subz_err

    idiv ebx
    ; сохраняем
    mov r9d, eax


    ; умножение a*b*c
    mov eax, [b]
    mov ebx, [c]
    imul ebx ; b*c

    ; проверка
    mov ecx, eax
    ; sar сдвигает старшим битом
    sar ecx, 31 ; получаем маску знака
    cmp edx, ecx
    jne ovf_err

    shl rdx, 32 ; сдвигаем старшие биты налево внутри регистра rdx
    or rax, rdx ; получаем целиком число внутри rax

    mov rbx, [a]
    imul rbx ; a * (b*c)

    ; проверка
    mov rcx, rax
    sar rcx, 63
    cmp rdx, rcx
    jne ovf_err

    mov r10, rdx ; старшие биты
    mov r11, rax ; младшие биты
    

    ; умножение c*d
    mov eax, [c]
    movsx ebx, byte [d]
    imul ebx

    ; проверка
    mov ecx, eax
    ; sar сдвигает старшим битом
    sar ecx, 31 ; получаем маску знака
    cmp edx, ecx
    jne ovf_err

    shl rdx, 32
    or rax, rdx

    ; умножение (c*d)*e
    movsx rbx, word [e]
    imul rbx

    ; проверка
    mov rcx, rax
    sar rcx, 63
    cmp rdx, rcx
    jne ovf_err

    mov r12, rdx
    mov r13, rax


    ; числитель = a*b*c - c*d*e
    sub r11, r13
    sbb r10, r12

    ; проверка
    jo ovf_err


    ; знаменатель
    movsxd r9, r9d
    add r8, r9

    ; проверка
    jo ovf_err


    ; делим финал
    mov rax, r11
    mov rdx, r10

    ; проверка
    cmp r8, 0
    je subz_err
    
    idiv r8


    jmp exit_suc

exit_suc:
    mov rdi, 0 ; код завершения что все гуд
    jmp exit

subz_err:
    mov rdi, 2
    jmp exit

ovf_err:
    mov rdi, 2
    jmp exit

exit:
    mov rax, 60 ; помещаем в регистр код завершения программы
    ; через системный вызов
    syscall