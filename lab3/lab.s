BITS 64
section .data

; r8 - first word in sentence length
; r9 - current word in sentence length
; r10 - counter for input_buffer
; r12 - current output_buffer size

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

; ADDITIONAL CONSTANTS
    NULL  equ 0

; CONSTANT ERROR MSGS
    err_file                db "Error: invalid file or not available for reading", 0x0a, 0
    err_no_argv             db "Error: no arguments. Please, use ./lab <filename> to run program properly", 0x0a, 0
    err_too_many_argv       db "Error: too many arguments. Please, use ./lab <filename> to run program properly", 0x0a, 0

; SIZES
    buffer_size dq 10
    output_size dq 0

; FILE
    fd dq 0
    file_offset dq 0

; FLAGS
    first_word_completed db 0
    last_word_undone db 0
    is_last_line db 0

section .bss
    ; DATA (INPUT/OUTPUT)
    filename resb 256
    data_buffer resq 10
    output_buffer resq 10

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
    mov     rsi, output_buffer
    mov     rdi, data_buffer
    push    rdi
    call    check_buffer
    pop     rdi
    push    rdi
    call    work_with_data
    pop     rdi
    ret

check_buffer:
    .setup_counters:
        mov     r10, [output_size]
        add     qword [file_offset], r10
        xor     r12, r12
        xor     r9, r9
        xor     r13, r13
    .check_buffer_word_undone:
        add     rdi, r10
        dec     rdi
        cmp     byte [rdi], SPACE
        je      .word_done
        cmp     byte [rdi], TAB
        je      .word_done
        cmp     byte [rdi], NEWLINE
        je      .word_done
        cmp     byte [rdi], END_STRING
        je      .last_line
        .word_undone:
            mov     byte [last_word_undone], TRUE
            xor     r10, r10
            cmp     byte [rdi], END_STRING
            je      .last_line
            ret
        .word_done:
            mov     byte [last_word_undone], FALSE
            xor     r10, r10
            cmp     byte [rdi], END_STRING
            je      .last_line
            ret
        .last_line:
            mov     byte [is_last_line], TRUE
            xor     r10, r10
            ret

work_with_data:
    ; Loop througth every symbol in buffer
    .loop:
        cmp     qword [output_size], r10
        je      .done_loop
        cmp     byte [rdi], SPACE
        je      .character_handling
        cmp     byte [rdi], TAB
        je      .character_handling
        cmp     byte [rdi], NEWLINE
        je      .character_handling
        cmp     byte [rdi], END_STRING
        je      .done_loop
        call    calculate_word_length
    .character_handling:
        call    check_character
    .done_loop:
        ret

calculate_word_length:
    ; Calculate current word length and save needed data for future processing
    call    handle_word_pointer
    inc     r9
    cmp     byte [first_word_completed], FALSE
    je      .first_word
    ret
    .first_word:
        inc     r8
        ret

handle_word_pointer:
    ; Save pointer of current word from input_buffer if needed
    cmp     r13, NULL
    je      .save_word_pointer
    ret
    .save_word_pointer:
        mov     r13, rdi
        ret

check_character:
    ; Handle current character from input_buffer
    inc     r10
    cmp     byte [rdi], NEWLINE
    je      .newline
    jmp     .continue
    .newline:
        cmp     r13, NULL
        jne     .write_word
        jmp     .add_newline_symbol
        .write_word:
            call    put_word_into_output_buffer
        .add_newline_symbol:
            mov     byte [first_word_completed], FALSE
            xor     r8, r8
            mov     byte [rsi + r12], NEWLINE
            inc     r12
            cmp     r10, qword [output_size]
            je      .newline_buffer_end
            jmp     .newline_buffer_not_end
        .newline_buffer_end:
            call    work_with_data
            ret
        .newline_buffer_not_end:
            inc     rdi
            call    work_with_data
            ret
    .continue:
        cmp     r10, qword [output_size]
        je      .buffer_end
        jmp     .buffer_not_end
    .buffer_end:
        cmp     byte [last_word_undone], TRUE
        je     .word_undone
        jmp     .word_done
        .word_undone:
            sub     qword [file_offset], r9
            cmp     byte [first_word_completed], FALSE
            je      .complete
            jmp     .not_complete
            .complete:
                xor     r8, r8
            .not_complete:
                call    work_with_data
                ret
        .word_done:
            call    put_word_into_output_buffer
            call    work_with_data
            ret
    .buffer_not_end:
        cmp     r13, NULL
        je      .skip_word
        cmp     byte [rdi], SPACE
        je      .add_word
        cmp     byte [rdi], TAB
        je      .add_word
        jmp     .skip_word
        .add_word:
            call    put_word_into_output_buffer
        .skip_word:
            inc     rdi
            call    work_with_data
            ret

put_word_into_output_buffer:
    ; Put word into output_buffer variable
    .check_word_condition:
        cmp     r9, 0
        je      .end
        cmp     r8, r9
        je      .write_word
        jmp     .end
    .write_word:
        cmp     byte [first_word_completed], FALSE
        mov     byte [first_word_completed], TRUE
        je      .add_word
        .add_space:
            mov     byte [rsi + r12], SPACE
            inc     r12
        .add_word:
            xor     rcx, rcx
            .loop:
                cmp     r9, 0
                je      .end
                mov     al, byte [r13 + rcx]
                mov     [rsi + r12], al
                dec     r9
                inc     r12
                inc     rcx
                jmp     .loop
    .end:
        xor     r13, r13
        xor     r9, r9
        ret

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
    mov     rdi, 1                      ; File descriptor for stdout
    mov     rdx, r12                    ; Number of bytes to write
    mov     rax, 1                      ; System call for write
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
    push    err_no_argv
    jmp     _exit_error

_argv_to_many_passed:
    ; Exit program with printing error msg (too many arguments)
    push    err_too_many_argv
    jmp     _exit_error

_file_invalid:
    ; Exit program with printing error msg (invalid file)
    push    err_file
    jmp     _exit_error

_exit_normal:
    ; Exit program with error code 0 (OK)
    mov     rdi, 0                      ; Exit status (0)
    jmp     _exit

_exit_error:
    ; Exit program with error code 1
    pop     rsi                         ; Pop the address of the error message into rdi
    xor     r12, r12
    .calculate_length:
        mov al, byte [rsi + r12]
        cmp al, 0
        je .print_error
        inc r12
        jmp .calculate_length
    .print_error:
        call    put_output_data             ; Print the error message
        mov     rdi, 1                      ; Exit status (1)
        jmp     _exit

_exit:
    ; Exit program
    mov     rax, 60
    syscall