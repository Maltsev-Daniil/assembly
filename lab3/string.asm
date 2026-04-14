BITS 64

global _start

section .rodata
    BUFF_SIZE equ 4096
    LINE_SIZE equ 65536

    SYS_READ equ 0
    SYS_WRITE equ 1
    SYS_OPEN equ 2
    SYS_CLOSE equ 3
    SYS_EXIT equ 60

section .data
    ; запишем сюда индекс
    ; файлового дескриптора
    input_fd dq 0
    newline db 10
    buffer db BUFF_SIZE dup(0)
    line_buffer db LINE_SIZE dup(0)
    result_buffer db LINE_SIZE dup(0)

_start:
    call parse_args
    call open_file
    xor r13, r13 ; for line length
    ; так же внутри и выводим
    call read_loop
    call close_file
    
    ; завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

parse_args:
    mov rax, [rsp]
    cmp rax, 2
    jl error_exit

    mov rdi, [rsp + 16] ; filename
    ret

open_file:
    ; TODO разобраться как работает этот
    ; сискол
    mov rax, SYS_OPEN
    xor rsi, rsi
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl error_exit

    mov [input_fd], rax
    ret

read_loop:
    ; заполняем буфер данными из файла
    mov rax, SYS_READ
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFF_SIZE
    syscall

    ; в rax кол-во прочитанных байт
    ; buffer содержит эти байты

    cmp rax, 0
    je eof
    jl error_exit

    mov r14, rax
    xor rcx, rcx

    jmp process_buffer

; обрабатываем буфер
process_buffer:
    cmp rcx, r14
    ; обработали весь буфер, нужно
    ; считывать дальше
    jge read_loop

    ; кладем символ в al
    mov al, [buffer + rcx]

    cmp al, 10 ; \n
    je line_done

    cmp r13, LINE_SIZE
    jge error_exit ; строка слишком длинная

    mov [line_buffer + r13], al ; записываем символ в начало буфера
    inc r13 ; увеличиваем длину строки

    inc rcx
    jmp process_buffer

line_done:

    call process_line
    call print_result

    xor r13, r13
    inc rcx
    jmp process_buffer

eof:
    cmp r13, 0
    je finish

    ; мы дошли до конца файла
    ; но в буфере есть данные
    ; которые нужно обработать
    call process_line
    call print_result

finish:
    ret

; rsi - i in line_buffer
; rdi - j in result_buffer
; r13 - length of line
; rdi - length of result
process_line:
    xor rsi, rsi
    xor rdi, rdi
    xor r10, r10 ; need space = false

next:
    cmp rsi, r13
    jge process_line_done

skip_spaces:
    cmp rsi, r13
    jge process_line_done

    mov al, [line_buffer + rsi]
    cmp al, ' '
    je inc_i
    cmp al, 9 ; \t
    je inc_i
    jmp word_start

inc_i:
    inc rsi
    jmp skip_spaces

word_start:
    mov rbx, rsi ; start of word
    xor r8, r8 ; length of word

    mov al, [line_buffer + rsi]
    call is_vowel
    mov r9, rax ; is_vowel

word_loop:
    cmp rsi, r13
    jge word_end

    mov al, [line_buffer + rsi]
    cmp al, ' '
    je word_end
    cmp al, 9 ; \t
    je word_end

    inc r8
    inc rsi
    jmp word_loop

word_end:
    ; проверяем тут, тк
    ; нам нужен индекс следующего слова
    cmp r9, 1
    je next

    cmp r10, 0
    je no_space

    mov byte [result_buffer + rdi], ' '
    inc rdi

no_space:
    ; это надо чтобы мы занулили счетчик
    xor rcx, rcx

copy_loop:
    ; r8 - length of word
    cmp rcx, r8
    jge copy_done

    ; rbx - start of word
    mov al, [line_buffer + rbx + rcx]
    mov [result_buffer + rdi], al

    inc rcx
    inc rdi
    jmp copy_loop

copy_done:
    mov r10, 1 ; need space = true
    jmp next

process_line_done:
    mov r13, rdi ; length of result
    ret

print_result:
    mov rax, SYS_WRITE
    mov rdi, 1 ; stdout
    mov rsi, result_buffer
    mov rdx, r13 ; length of result
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1 ; stdout
    mov rsi, newline ; \n
    mov rdx, 1 ; lenght
    syscall

    ret

; A  = 0100 0001
; a =  0110 0001
; 32 = 0010 0000
is_vowel:
    ; al - char
    ; возвращаем 1 если гласная, 0 иначе
    or al, 32 ; переводим в нижний регистр
    cmp al, 'a'
    je vowel
    cmp al, 'e'
    je vowel
    cmp al, 'i'
    je vowel
    cmp al, 'o'
    je vowel
    cmp al, 'u'
    je vowel
    xor rax, rax
    ret

vowel:
    mov rax, 1
    ret

close_file:
    mov rax, SYS_CLOSE
    mov rdi, [input_fd]
    syscall

error_exit:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall