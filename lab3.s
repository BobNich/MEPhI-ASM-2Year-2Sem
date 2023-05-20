BITS 64
section .data

; r8 - first word in sentence length
; r9 - current word in sentence length
; r10 - is [size(data_buffer) < buffer_size] flag

err_file db "Error: invalid file or not available for reading", 0x0a, 0
err_no_argv db "Error: no arguments. Please, use ./lab <filename> to run program properly", 0x0a, 0
err_too_many_argv db "Error: too many arguments. Please, use ./lab <filename> to run program properly", 0x0a, 0

buffer_size dq 100

filename dq 0
data_buffer dq 0
output_buffer dq 0

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
        call    get_filename
        call    task
    .end:
        jmp     _exit_normal

task:
    ; Run lab task
    .start:
        .loop:
            call    get_input_data
            call    process_buffer
            call    put_output_data
    .end:
        ret
 
process_buffer:
    mov     rdi, data_buffer
    ret

get_bounds_and_word_length:
    ; Get bounds and current word length
    mov     rsi, rdi                ; Get current character position
    mov     r9,  0                  ; Reset current word length to 0
    .loop:
        cmp     byte [rsi], 0x20    ; Compare current character to "space"
        je      .end                ; Stop, if the character is a "space"
        cmp     byte [rsi], 0x09    ; Compare current character to "tab"
        je      .end                ; Stop, if the character is a "tab"
        cmp     byte [rsi], 0x0a    ; Compare current character to "newline"
        je      .end                ; Stop, if the character is a "newline"
        cmp     byte [rsi], 0       ; Compare current character to "end of data"
        je      .end                ; Stop, if the character is a "end of data"
        inc     rsi                 ; Move to the next character
        inc     r9                  ; Increment current word length
        jmp     .loop               ; Continue checking next characters
    .end:
        dec rsi                     ; Get last valid character position
        ret

check_len_equals_first_word_len:
    ; Check task condition (First word length equals 'i'-th word length)
    .check_if_first_word:
        cmp     r8, 0                                               ; Compare first word length to 0
        je      .init_first_word_length                             ; If 0 -> jump to initializing first word length
        jmp     .check_if_current_word_len_equals_first_word_len    ; Otherwise, check whether 1st word length = 'i'-word length
    .init_first_word_length:
        mov     r8, r9                                              ; Current word length = first word length
        jmp    .true                                                ; Jump to "don't delete this word" condition maker
    .check_if_current_word_len_equals_first_word_len:
        cmp     r8, r9                                              ; Compare first word length to current word length
        je      .true                                               ; Jump to "Don't delete this word" if the lengths are equal
        jmp     .false                                              ; Otherwise, jump to "Delete this word"
    .false:
        mov     eax, 0                                              ; Don't delete current word flag
        ret
    .true:
        mov     eax, 1                                              ; Delete current word flag
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

get_input_data:
    ; Read input data (from file) to buffer
    .open_file:
        mov     rax, 2                  ; System call number for file open
        mov     rdi, filename           ; File name
        xor     rsi, rsi                ; No flags
        syscall                         ; Open the file
        .check_open_status:
            cmp     rax, 0              ; Compare return value to 0
            jl      _file_invalid       ; Jump to _file_invalid if the return value is negative (indicating an error)
            cmp     rax, [buffer_size]
            jl      .buffer_size_less
            je      .buffer_size_equal
            .buffer_size_less:
                mov     r10, 1
                jmp     .success
            .buffer_size_equal:
                mov     r10, 0
                jmp     .success    
        .success:
            mov     rbp, rax            ; Move the file descriptor to ebp for later use
    .prepare_data_buffer:
        mov rsi, data_buffer            ; Buffer for reading
        mov rdx, qword [buffer_size]    ; Number of bytes to read
    .read_data:
        mov     rax, 0                  ; System call number for file read
        mov     rdi, rbp                ; File descriptor
        syscall                         ; Read the file's data
        add     rsi, rax                ; Move the buffer pointer forward by the number of bytes read
        mov     byte [rsi], 0           ; Set the byte at esi to 0 (null-terminate the data)
    .close_file:
        mov rax, 3                      ; System call number for file close
        mov rdi, rbp                    ; Move the file descriptor to edi
        syscall                         ; Close file
        ret

put_output_data:
    ; Print output into stdout
    mov     rsi, rdi                ; Move edi to esi (current character position)
    mov     rdi, 1                  ; Move 1 to edi (file descriptor for stdout)
    mov     rdx, 1                  ; Move 1 to edx (number of bytes to write)
    .loop:
        mov     rax, 1              ; Move 1 to eax (system call for write)
        syscall                     ; Call the system to write the byte at esi to stdout
        cmp     byte [rsi], 0       ; Compare the byte at esi to 0
        je      .end                ; Jump to .end if the byte is 0 (end of line)
        inc     rsi                 ; Move to the next character
        jmp     .loop
    .end:
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
