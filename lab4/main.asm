global main

bits 64

extern printf
extern expf
extern scanf
extern fopen
extern fclose
extern fprintf

section .data
    fmt_input db "%f %f", 0
    fmt_res_lhs db "sh(x) = %f", 10, 0
    fmt_res_rhs db "series = %f", 10, 0
    fmt_file db "n=%d term=%f", 10, 0

    fmt_usage db "Usage: program <filename>", 10, 0
    fmt_file_err db "Error opening file", 10, 0

    mode db "w", 0

    two dd 2.0
    minus_one dd -1.0
    zero dd 0.0

section .bss
    x resd 1
    eps resd 1
    file resq 1

    tmp1 resd 1
    tmp2 resd 1

    argv_ptr resq 1

    term resd 1
    sum resd 1
    n resd 1

section .text

main:
    ; явное выравнивание стека
    sub rsp, 8

    cmp rdi, 2
    jl usage_error

    mov [argv_ptr], rsi

    mov rdi, fmt_input
    ; кладем адреса
    lea rsi, [x]
    lea rdx, [eps]
    xor rax, rax
    call scanf

    ; проверяем что прочитали 2 числа
    cmp rax, 2
    jne usage_error

    ; exp(x)
    movss xmm0, [x]
    call expf
    movss [tmp1], xmm0

    ; exp(-x)
    movss xmm0, [x]
    mulss xmm0, [minus_one]
    call expf
    movss [tmp2], xmm0

    ; (exp(x) - exp(-x)) / 2
    movss xmm0, [tmp1]
    subss xmm0, [tmp2]
    movss xmm1, [two]
    divss xmm0, xmm1

    ; вывод
    mov rdi, fmt_res_lhs
    cvtss2sd xmm0, xmm0
    mov rax, 1
    call printf

    ; открываем файл
    mov rbx, [argv_ptr]
    mov rdi, [rbx + 8]
    mov rsi, mode
    call fopen

    test rax, rax
    jz file_error

    mov [file], rax

    ; term = x
    movss xmm0, [x]
    movss [term], xmm0

    ; sum = 0
    xorps xmm0, xmm0
    movss [sum], xmm0

    mov dword [n], 0

; term(+1) = term * x^2 / ((2n+2)(2n+3))
loop_start:

    ; обработка знака
    movss xmm0, [term]
    movss xmm1, [zero]
    comiss xmm0, xmm1
    jae abs_ok

    mulss xmm0, [minus_one]

abs_ok:

    ; проверка на епсилон
    movss xmm1, xmm0
    movss xmm2, [eps]
    comiss xmm1, xmm2
    jb loop_end

    ; sum += term
    movss xmm0, [sum]
    addss xmm0, [term]
    movss [sum], xmm0

    ; fprintf(file, ...)
    mov rdi, [file]
    mov rsi, fmt_file
    mov edx, [n]
    movss xmm0, [term]
    cvtss2sd xmm0, xmm0
    mov rax, 1
    call fprintf

    ; следующий term

    ; term = term * x^2
    movss xmm0, [term]
    movss xmm1, [x]
    mulss xmm1, [x]
    mulss xmm0, xmm1

    ; (2n+2)
    mov eax, [n]
    lea rbx, [rax*2 + 2]

    ; (2n+3)
    lea rcx, [rax*2 + 3]

    ; в double
    cvtsi2sd xmm1, rbx
    cvtsi2sd xmm2, rcx

    ; знаменатель
    mulsd xmm1, xmm2

    ; деление
    cvtss2sd xmm0, xmm0
    divsd xmm0, xmm1
    cvtsd2ss xmm0, xmm0

    movss [term], xmm0

    inc dword [n]

    jmp loop_start

loop_end:

    ; вывод суммы ряда
    mov rdi, fmt_res_rhs
    movss xmm0, [sum]
    cvtss2sd xmm0, xmm0
    mov rax, 1
    call printf

    mov rdi, [file]
    call fclose

    xor eax, eax
    add rsp, 8
    ret

usage_error:
    mov rdi, fmt_usage
    xor rax, rax
    call printf
    mov eax, 1
    add rsp, 8
    ret

file_error:
    mov rdi, fmt_file_err
    xor rax, rax
    call printf
    mov eax, 1
    add rsp, 8
    ret