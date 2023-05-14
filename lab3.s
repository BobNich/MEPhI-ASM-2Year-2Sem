BITS 64

; r8 - first word length (if 0 - no first word found)
; r9 - tmp, i-th word length

section .data

err_file db "Error: invalid file", 0x0a, 0
err_no_argv db "Usage: ./lab.out <filename>", 0x0a, 0
filename db 0
data db 0

section .text
    global _start

_start:

main:
    mov     rax, [rsp]
    cmp     eax, 1
    je      _argv_not_passed
    mov     rdi, [rsp + 0x10]
    mov     rdi, [rdi]
    mov     [filename], rdi
    call    scan_file
    mov     edi, data
    call    iterate_lines
    mov     edi, data
    call    print
    .end:
    jmp     _exit_normal

iterate_lines:
    .loop:
        cmp     byte [edi], 0
        je      .end
        mov     r8, 0
        call    process_line
        inc     edi
        jmp     .loop
    .end:
    ret

process_line:
    .loop:
        cmp     byte [edi], 0x0a
        je      .end
        cmp     byte [edi], 0
        je      .end

        push    rdi
        push    rsi
        call    delete_dividers
        pop     rsi
        pop     rdi

        call    get_bounds_and_word_length

        push    rdi
        push    rsi
        call    check_len_equals_first_word_len
        pop     rsi
        pop     rdi

        inc     esi
        sub     esi, edi
        cmp     eax, 1
        je .skip

            push    rdi
            call    delete_characters
            pop     rdi

            mov     esi, 0
            jmp     .continue
        .skip:
            add     edi, esi
            cmp     byte [edi], 0
            mov     esi, 0
            je      .continue
            inc     edi
        .continue:
        push    rdi
        push    rsi
        call    delete_dividers
        pop     rsi
        pop     rdi

        add     edi, esi
        jmp     .loop
    .end:
    cmp     byte [rdi], 0x0a
    je      .dont_clean
    dec     rdi

    push    rdi
    push    rsi
    call    delete_dividers
    pop     rsi
    pop     rdi

    .dont_clean:
    ret

check_len_equals_first_word_len:
    .check_if_first_word:
        cmp     r8, 0
        je      .init_first_word_length
        jmp     .check_if_current_word_len_equals_first_word_len
    .init_first_word_length:
        mov     r8, r9
        jmp    .true
    .check_if_current_word_len_equals_first_word_len:
        cmp     r8, r9
        je      .true
        jmp     .false
    .false:
        mov     eax, 0
        ret
    .true:
        mov     eax, 1
        ret

delete_dividers:
    .loop:
        cmp     byte [edi], 0x20    ; check if space
        jne     .no_space
        jmp     .delete
        .no_space:
        cmp     byte [edi], 0x09    ; check if tab
        jne     .end
        .delete:
        mov     esi, 1

        push    rdi
        call    delete_characters
        pop     rdi

        jmp     .loop
    .end:
    ret

delete_characters:
    mov     ecx, esi
    .loop:
        cmp     ecx, 0
        jle     .end
        mov     ebx, edi
        .inner:
            cmp     byte [ebx], 0
            je      .continue
            movzx   eax, byte [ebx + 1]
            mov     byte [ebx], al
            inc     ebx
            jmp     .inner
        .continue:
        loop    .loop
    .end:
    ret

get_bounds_and_word_length:
    mov     esi, edi
    mov     r9,  0                  ; i-th word_len = 0
    .loop:
        cmp     byte [esi], 0x20    ; check if space
        je      .end
        cmp     byte [esi], 0x09    ; check if tab
        je      .end
        cmp     byte [esi], 0x0a    ; check if \n
        je      .end
        cmp     byte [esi], 0       ; check if \0
        je      .end
        inc     esi
        inc     r9                  ; i-th word_len++
        jmp     .loop
    .end:
    dec esi
    ret

print:
    mov     esi, edi
    mov     edi, 1      ; File descriptor for stdout
    mov     edx, 1
    .loop:
        mov     eax, 1          ; System call for write
        syscall
        cmp     byte [esi], 0
        je      .end
        inc     esi
        jmp     .loop
    .end:
    ret

scan_file:
    ; Open the file for reading
    mov     eax, 2
    mov     edi, filename
    xor     esi, esi        ; No flags
    mov     edx, 0644       ; rw-r--r--
    syscall
    cmp     eax, 0
    jl      _file_invalid
    mov     ebp, eax        ; Save the file descriptor in ebp

    mov esi, data
    mov edx, 1
    .loop:
        mov     eax, 0      ; system call read
        mov     edi, ebp
        syscall
        test    eax, eax    ; check for ctrl+D
        je      .end
        add     esi, eax
        jmp     .loop
    .end:
    mov     byte [esi], 0

    ; Close the file
    mov eax, 3
    mov edi, ebp
    syscall
    ret

_exit_normal:
    ; Exit program normally
    mov     rdi, 0
    jmp     _exit

_argv_not_passed:
    push err_no_argv
    jmp _exit_error

_file_invalid:
    push err_file
    jmp _exit_error

_exit_error:
    ; Exit program with error code 1
    pop     rdi
    call    print
    mov     rdi, 1
    jmp     _exit

_exit:
    mov     rax, 60     ; Syscall for exit
    syscall
