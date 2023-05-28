BITS 64
section .data

; r8 - first word in sentence length
; r9 - current word in sentence length

; SYSCALLS
    SYS_OPEN    equ 0x02
    SYS_READ    equ 0
    SYS_CLOSE   equ 0x03
    SYS_LSEEK   equ 8

; ASCII
    SPACE       equ 0x20
    TAB         equ 0x09
    NEWLINE     equ 0x0a
    END_STRING  equ 0

; BOOLEAN REPRESENTATION
    TRUE  equ 1
    FALSE equ 0

; CONSTANT ERROR MSGS
    err_file db "Error: invalid file or not available for reading", 0x0a, 0
    err_no_argv db "Error: no arguments. Please, use ./lab <filename> to run program properly", 0x0a, 0
    err_too_many_argv db "Error: too many arguments. Please, use ./lab <filename> to run program properly", 0x0a, 0

; SIZES
    buffer_size dq 10
    output_size dq 0

; FILE
    filename dq 0
    fd dq 0
    file_offset dq 0

; DATA (INPUT/OUTPUT)
    data_buffer dq 0
    output_buffer dq 0

; FLAGS
    first_word_handle_done db 0
    is_last_line db 0
    is_last_symbol_transition db 0


section .text
    global _start

_start:

main:
    .handle_arguments:
        mov     rax, [rsp]              ; Move the first argument (argc) to rax
        cmp     rax, 1                  ; Compare argc to 1
        je      _argv_not_passed        ; Jump to _argv_not_passed if argc = 1
        cmp     rax, 2                  ; Compare argc to 2
        jg      _argv_to_many_passed    ; Jump to _argv_not_passed if argc > 2
        mov     rdi, [rsp + 0x10]       ; Move the second argument (argv) to rdi
    .start:
        call    task
    .end:
        jmp     _exit_normal

task:
    ; Run lab task
    .get_filename:
        call    get_filename
    .open_file:
        call    open_file
    .process_data:
        .loop:
            cmp     byte [is_last_line], TRUE
            je      .end
            call    get_input_data
            call    process_buffer
            call    put_output_data
            jmp     .loop
    .end:
        call close_file
        ret

process_buffer:
    mov     rdi, data_buffer    
    mov     rsi, output_buffer

    push    rdi
    push    rsi
    call    check_buffer
    pop     rsi
    pop     rdi

    push    rdi
    push    rsi
    call    work_with_data
    pop     rsi
    pop     rdi

    ret

check_buffer:
    mov     rcx, [output_size]
    .check_is_file_end:
        cmp     rcx, [buffer_size]
        jl      .file_end
    .check_buffer_word_undone:
        add     rdi, rcx
        dec     rdi
        cmp     byte [rdi], SPACE
        je      .word_done
        cmp     byte [rdi], TAB
        je      .word_done
        cmp     byte [rdi], NEWLINE
        je      .word_done
        .word_undone:
            mov     byte [is_last_symbol_transition], FALSE
            ret
        .word_done:
            mov     byte [is_last_symbol_transition], TRUE
            ret
        .file_end:
            mov     byte [is_last_line], TRUE
            ret

work_with_data:
    .loop:
        cmp    byte [rdi], SPACE
        je      .transition
        cmp     byte [rdi], TAB
        je      .transition
        cmp     byte [rdi], NEWLINE
        je      .transition
        cmp     byte [rdi], END_STRING
        je      .done_work
        jmp     .letter
        .transition:
            inc     rdi
            jmp     .loop
        .letter:
            cmp     r8, 0
            je      .first_word_handle
            .first_word_handle:
                cmp    byte [rdi], SPACE
                je      .done_first_word_handle
                cmp     byte [rdi], TAB
                je      .done_first_word_handle
                cmp     byte [rdi], NEWLINE
                je      .done_first_word_handle
                cmp     byte [rdi], END_STRING
                je      .done_work
                inc     rdi
                inc     r8
                jmp     .first_word_handle
            .done_first_word_handle:
                mov byte [first_word_handle_done], TRUE
    .done_work:
        add    qword [file_offset], rcx

get_filename:
    ; Get filename
    xor rcx, rcx                        ; Reset filename length counter to 0
    .copy_filename_loop:
        mov al, byte [rdi + rcx]        ; Read one character from the argument
        mov [filename + rcx], al        ; Store the character in the filename buffer
        cmp al, 0                       ; Check if it's the end of the string
        je .done_filename_copying       ; If so, exit the loop
        inc rcx                         ; Move to the next character
        jmp .copy_filename_loop
    .done_filename_copying:
        mov [filename + rcx], al        ; Store the /0 in the end of filename
        ret

open_file:
    ; Open file
    mov     rax, SYS_OPEN           ; System call number for file open
    mov     rdi, filename           ; File name
    xor     rsi, rsi                ; No flags
    syscall                         ; Open the file
    .check_open_status:
        cmp     rax, 0              ; Compare return value to 0
        jl      _file_invalid       ; Jump to _file_invalid if the return value is negative (indicating an error)
    .success_open:
        mov     [fd], rax           ; Init file descriptor (fd)
    ret

get_input_data:
    ;Read data from file to buffer with constant size
    .offset:
        mov rax, SYS_LSEEK     ; sys_lseek system call
        mov rdi, [fd]          ; File descriptor
        mov rsi, [file_offset] ; Offset
        mov rdx, 0             ; Whence (SEEK_SET)
        syscall
    .prepare_data_buffer:
        mov rsi, data_buffer            ; Buffer for reading
        mov rdx, qword [buffer_size]    ; Number of bytes to read
    .read_data_with_offset:
        mov rax, SYS_READ               ; Read from file system call
        mov rdi, [fd]                   ; File descriptor
        syscall                         ; Read the file's data
    .handle_read_size:
        mov     [output_size], rax      ; Save output size  
    .end:
        ret

put_output_data:
    ; Print output into stdout
    mov     rsi, rdi                ; Move edi to esi (current character position)
    mov     rdi, 1                  ; File descriptor for stdout
    mov     rdx, [output_size]      ; Number of bytes to write
    mov     rax, 1                  ; System call for write
    syscall
    ret

close_file:
    ; Close file
    mov rax, SYS_CLOSE              ; System call number for file close
    mov rdi, [fd]                   ; Move the file descriptor to edi
    syscall                         ; Close file
    ret

_argv_not_passed:
    ; Exit program with printing error msg (no needed argument)
    push err_no_argv
    jmp _exit_error

_argv_to_many_passed:
    ; Exit program with printing error msg (too many arguments)
    push err_too_many_argv
    jmp _exit_error

_file_invalid:
    ; Exit program with printing error msg (invalid file)
    push err_file
    jmp _exit_error

_exit_normal:
    ; Exit program with error code 0 (OK)
    mov     rdi, 0                      ; Exit status (0)
    jmp     _exit

_exit_error:
    ; Exit program with error code 1
    pop     rdi                         ; Pop the address of the error message into rdi
    call    put_output_data             ; Print the error message
    mov     rdi, 1                      ; Exit status (1)
    jmp     _exit

_exit:
    ; Exit program
    mov     rax, 60
    syscall
