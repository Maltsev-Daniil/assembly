BITS 64

global _start

section .data
    EL_SIZE equ 4

    ROWS equ 2
    COLUMNS equ 3

    align EL_SIZE
    matrix dd 1, 6, 4
           dd 9, 4, 1

    col_ptrs times COLUMNS dq 0
    array_max times COLUMNS dd 0

    temp_matr times ROWS*COLUMNS dd 0

    MIN equ -2147483648

section .text

_start:
    mov r8d, COLUMNS
    xor edi, edi

for_cols:
    cmp edi, r8d
    ; sf == of
    jge cols_end

    ; jg checks
    ; zf = 0 || sf == of

    mov r9d, ROWS
    xor esi, esi

    ; создание массива указателей
    lea rdx, [matrix + rdi*EL_SIZE]
    mov [col_ptrs + rdi*8], rdx

    ; сохраним сюда макс столбца
    mov r10d, MIN
    ; указатель на i столбец
    mov rbx, [col_ptrs + rdi*8]

for_rows:
    cmp esi, r9d
    jge rows_end

    ; проходимся по строкам в столбце
    mov edx, [rbx]

    ; обновляем максимум
    cmp edx, r10d
    ; sf != of || zf == 1
    jle skip_update
    ; jl checks sf != of
    mov r10d, edx
skip_update:

    add rbx, COLUMNS*EL_SIZE

    inc esi
    jmp for_rows

rows_end:
    mov [array_max + edi * EL_SIZE], r10d

    inc edi
    jmp for_cols

cols_end:

    xor edi, edi
    inc edi

sort_loop:
    cmp edi, r8d
    jge sort_done

    ; ключ для bin_search and shift_loop
    mov r11d, [array_max + rdi*EL_SIZE]
    ; указатель на столбец для shift_loop
    mov r10, [col_ptrs + rdi*8]

    ; грузим диапазон для поиска
    mov r12d, edi
    call binary_search

    ; сколько элементов сдвинуть
    mov ecx, edi

shift_loop:
    ; esi - insert pos
    cmp ecx, esi
    jle shift_done

    ; сдвигаем
    mov eax, [array_max + rcx*EL_SIZE - EL_SIZE]
    mov [array_max + rcx*EL_SIZE], eax

    mov rax, [col_ptrs + rcx*8 - 8]
    mov [col_ptrs + rcx*8], rax

    dec ecx
    jmp shift_loop

shift_done:
    ; вставляем на нужную pos
    mov [array_max + rsi*EL_SIZE], r11d
    mov [col_ptrs + rsi*8], r10

    inc edi
    jmp sort_loop

binary_search:
    xor esi, esi
    mov edx, r12d

binary_loop:
    cmp esi, edx
    jge binary_done

    ; ecx += left
    mov ecx, esi
    ; ecx += right
    add ecx, edx
    ; ecx /= 2
    shr ecx, 1

    mov eax, [array_max + rcx*EL_SIZE]
    cmp eax, r11d
    jle move_left
    jmp move_right

move_left:
    lea esi, [rcx + 1]
    jmp binary_loop

move_right:
    mov edx, ecx
    jmp binary_loop

binary_done:
    ret

sort_done:

    ; теперь соберем temp матрицу
    ; по col_ptrs
    mov r8d, COLUMNS
    xor edi, edi

for_cols_temp:
    cmp edi, r8d
    jge cols_end_temp

    mov r9d, ROWS
    xor esi, esi

    ; rbx = col_ptrs[i]
    mov rbx, [col_ptrs + rdi*8]

for_rows_temp:
    cmp esi, r9d
    jge rows_end_temp

    ; eax = *rbx
    mov eax, [rbx]

    ; edx = i*COLS + j
    ; умножаем на COLS
    ; тк у нас в памяти ячейки лежат
    ; по столбикам
    mov edx, esi
    imul edx, COLUMNS
    add edx, edi
    mov [temp_matr + rdx*EL_SIZE], eax

    add rbx, COLUMNS*EL_SIZE

    inc esi
    jmp for_rows_temp

rows_end_temp:

    inc edi
    jmp for_cols_temp

cols_end_temp:

    ; последовательно копируем
    ; n*m элемнтов из отсортированной
    ; матрицы в нашу исходную
    mov ecx, COLUMNS*ROWS
    xor esi, esi

copy_loop:
    mov eax, [temp_matr + rsi*EL_SIZE]
    mov [matrix + rsi*EL_SIZE], eax
    inc esi

    dec ecx
    jnz copy_loop

    mov rdi, 0
    mov rax, 60
    syscall