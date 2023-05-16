BITS 64

; r8 - first word length (if 0 - no first word found)
; r9 - tmp, i-th word length

; For professor: 

; the value at [rsp] typically represents the first argument passed to a function, which is often the argc (argument count) value.
; The jump is taken if the number of command-line arguments (argc) is equal to 1, indicating that no additional arguments were passed.

; In the x86-64 calling convention, the value at [rsp + 0x10] typically represents the second argument passed to a function,
; which is often the argv (argument vector) value. The 0x10 offset corresponds to the size of the argc value stored on the stack.


; Comments:
; 1) Buffer
; DONE 2) Add argc check
; DONE 3) FILE OPENING ERROR HANDLING
; ALMOST DONE 4) Pointer size and filename 
; 5) tab/..


section .data

err_file db "Error: invalid file or not available for reading", 0x0a, 0
err_no_argv db "Please, use ./lab.out <filename> to run program properly", 0x0a, 0
filename dq 0   ; Variable to store the filename
data db 0       ; Variable to store the file data

section .text
    global _start

_start:

main:
    mov     rax, [rsp]          ; Move the first argument (argc) to rax
    cmp     eax, 1              ; Compare argc to 1
    je      _argv_not_passed    ; Jump to _argv_not_passed if argc = 1
    cmp     eax, 2              ; Compare argc to 2
    jg      _argv_not_passed    ; Jump to _argv_not_passed if argc > 2
    mov     rdi, [rsp + 0x10]   ; Move the second argument (argv) to rdi

    ; Copy the filename to the variable
    xor rcx, rcx                    ; Reset filename legth counter to 0
    .copy_filename_loop:
        mov al, byte [rdi + rcx]    ; Read one character from the argument
        cmp al, 0                   ; Check if it's the end of the string
        je .done_filename_copying   ; If so, exit the loop
        mov [filename + rcx], al    ; Store the character in the filename buffer
        inc rcx                     ; Move to the next character
        jmp .copy_filename_loop

    .done_filename_copying:
        call    scan_file           ; Call the scan_file function to read the file
        mov     edi, data           ; Move the address of the data variable to edi
        call    iterate_lines       ; Call the iterate_lines function to process each line
        mov     edi, data           ; Move the address of the data variable to edi
        call    print               ; Call the print function to output the processed data
    .end:
    jmp     _exit_normal        ; Jump to _exit_normal to exit the program

iterate_lines:
    .loop:
        cmp     byte [edi], 0   ; Compare the byte at edi to 0
        je      .end            ; Jump to .end if the byte is 0 (end of data)
        mov     r8, 0           ; Initialize r8 to 0 (first word length)
        call    process_line    ; Call the process_line function to process the current line
        inc     edi             ; Increment edi to move to the next character
        jmp     .loop           ; Jump back to .loop to process the next line
    .end:
    ret                         ; Return from the iterate_lines function

process_line:
    .loop:
        cmp     byte [edi], 0x0a     ; Compare the byte at edi to 0x0a (newline)
        je      .end                 ; Jump to .end if the byte is 0x0a (end of line)
        cmp     byte [edi], 0        ; Compare the byte at edi to 0
        je      .end                 ; Jump to .end if the byte is 0 (end of data)

        push    rdi
        push    rsi
        call    delete_dividers                  ; Call the delete_dividers function to remove dividers
        pop     rsi
        pop     rdi

        call    get_bounds_and_word_length       ; Call the get_bounds_and_word_length function to get word length

        push    rdi
        push    rsi
        call    check_len_equals_first_word_len  ; Call the check_len_equals_first_word_len function to check if word length = first word length
        pop     rsi
        pop     rdi

        inc     esi                              ; Increment esi to move to the next character
        sub     esi, edi                         ; Calculate the length of the current word
        cmp     eax, 1                           ; Compare the result of check_len_equals_first_word_len to 1
        je .skip

            push    rdi
            call    delete_characters            ; Call the delete_characters function to remove unwanted characters
            pop     rdi

            mov     esi, 0                       ; Reset esi to 0
            jmp     .continue
        .skip:
            add     edi, esi                     ; Move edi forward by the length of the current word
            cmp     byte [edi], 0                ; Compare the byte at edi to 0
            mov     esi, 0                       ; Reset esi to 0
            je      .continue                    ; Jump to .continue if the byte is 0 (end of data)
            inc     edi                          ; Increment edi to move to the next character
        .continue:
        push    rdi
        push    rsi
        call    delete_dividers                  ; Call the delete_dividers function to remove dividers
        pop     rsi
        pop     rdi

        add     edi, esi                         ; Move edi forward by the length of the current word
        jmp     .loop                            ; Jump back to .loop to process the next character
    .end:
    cmp     byte [rdi], 0x0a                     ; Compare the byte at rdi to 0x0a (newline)
    je      .dont_clean                          ; Jump to .dont_clean if the byte is 0x0a
    dec     rdi                                  ; Decrement rdi to remove the trailing newline

    push    rdi
    push    rsi
    call    delete_dividers                      ; Call the delete_dividers function to remove dividers
    pop     rsi
    pop     rdi

    .dont_clean:
    ret

check_len_equals_first_word_len:
    .check_if_first_word:
        cmp     r8, 0                                               ; Compare r8 (first word length) to 0
        je      .init_first_word_length                             ; Jump to .init_first_word_length if r8 is 0
        jmp     .check_if_current_word_len_equals_first_word_len    ; Otherwise, jump to .check_if_current_word_len_equals_first_word_len
    .init_first_word_length:
        mov     r8, r9                                              ; Move r9 (current word length) to r8 (first word length)
        jmp    .true                                                ; Jump to .true
    .check_if_current_word_len_equals_first_word_len:
        cmp     r8, r9                                              ; Compare r8 (first word length) to r9 (current word length)
        je      .true                                               ; Jump to .true if the lengths are equal
        jmp     .false                                              ; Otherwise, jump to .false
    .false:
        mov     eax, 0                                              ; Set eax to 0 (false)
        ret
    .true:
        mov     eax, 1                                              ; Set eax to 1 (true)
        ret

delete_dividers:
    .loop:
        cmp     byte [edi], 0x20    ; Compare the byte at edi to 0x20 (space)
        jne     .no_space
        jmp     .delete
        .no_space:
        cmp     byte [edi], 0x09    ; Compare the byte at edi to 0x09 (tab)
        jne     .end
        .delete:
        mov     esi, 1              ; Set esi to 1 (flag indicating deletion)

        push    rdi
        call    delete_characters   ; Call the delete_characters function to remove unwanted characters
        pop     rdi 

        jmp     .loop               ; Jump back to .loop to continue processing
    .end:
    ret

delete_characters:
    mov     ecx, esi                        ; Move esi (number of characters to delete) to ecx
    .loop:
        cmp     ecx, 0                      ; Compare ecx to 0
        jle     .end                        ; Jump to .end if ecx is less than or equal to 0
        mov     ebx, edi                    ; Move edi to ebx (current character position)
        .inner:
            cmp     byte [ebx], 0           ; Compare the byte at ebx to 0
            je      .continue               ; Jump to .continue if the byte is 0 (end of data)
            movzx   eax, byte [ebx + 1]     ; Move the next byte to eax
            mov     byte [ebx], al          ; Move the next byte to the current position
            inc     ebx                     ; Increment ebx to move to the next character
            jmp     .inner                  ; Jump back to .inner to continue moving characters
        .continue:
        loop    .loop                       ; Decrement ecx and loop back to .loop
    .end:
    ret

get_bounds_and_word_length:
    mov     esi, edi                ; Move edi to esi (current character position)
    mov     r9,  0                  ; Reset r9 (current word length) to 0
    .loop:
        cmp     byte [esi], 0x20    ; Compare the byte at esi to 0x20 (space)
        je      .end                ; Jump to .end if the byte is a space
        cmp     byte [esi], 0x09    ; Compare the byte at esi to 0x09 (tab)
        je      .end                ; Jump to .end if the byte is a tab
        cmp     byte [esi], 0x0a    ; Compare the byte at esi to 0x0a (newline)
        je      .end                ; Jump to .end if the byte is a newline
        cmp     byte [esi], 0       ; Compare the byte at esi to 0
        je      .end                ; Jump to .end if the byte is 0 (end of data)
        inc     esi                 ; Increment esi to move to the next character
        inc     r9                  ; Increment r9 (current word length)
        jmp     .loop               ; Jump back to .loop to continue checking characters
    .end:
    dec esi                         ; Decrement esi to the last valid character position
    ret

print:
    mov     esi, edi                ; Move edi to esi (current character position)
    mov     edi, 1                  ; Move 1 to edi (file descriptor for stdout)
    mov     edx, 1                  ; Move 1 to edx (number of bytes to write)
    .loop:
        mov     eax, 1              ; Move 1 to eax (system call for write)
        syscall                     ; Call the system to write the byte at esi to stdout
        cmp     byte [esi], 0       ; Compare the byte at esi to 0
        je      .end                ; Jump to .end if the byte is 0 (end of line)
        inc     esi                 ; Move to the next character
        jmp     .loop
    .end:
    ret

scan_file:
    ; Open the file for reading
    mov     eax, 2                  ; Move 2 to eax (system call number for open)
    mov     rdi, filename           ; Move the address of filename to edi (file name)
    xor     esi, esi                ; Set esi to 0 (no flags)
    syscall                         ; Call the system to open the file
    cmp     eax, 0                  ; Compare eax (return value) to 0
    jl      _file_invalid           ; Jump to _file_invalid if the return value is negative (indicating an error)
    mov     ebp, eax                ; Move the file descriptor to ebp for later use

    mov esi, data                   ; Move the address of data to esi (buffer for reading)
    mov edx, 1                      ; Move 1 to edx (number of bytes to read)
    .loop:
        mov     eax, 0              ; Move 0 to eax (system call number for read)
        mov     edi, ebp            ; Move the file descriptor to edi
        syscall                     ; Call the system to read from the file
        test    eax, eax            ; Perform a bitwise AND of eax with itself
        je      .end                ; Jump to .end if eax is zero (indicating end of file)
        add     esi, eax            ; Move the buffer pointer forward by the number of bytes read
        jmp     .loop               ; Jump back to .loop to continue reading
    .end:
    mov     byte [esi], 0           ; Set the byte at esi to 0 (null-terminate the data)

    ; Close the file
    mov eax, 3                      ; Move 3 to eax (system call number for close)
    mov edi, ebp                    ; Move the file descriptor to edi
    syscall                         ; Call (close file)
    ret

_exit_normal:
    ; Exit program normally
    mov     rdi, 0                  ; Move 0 to rdi (exit status)
    jmp     _exit

_argv_not_passed:
    push err_no_argv                ; Push the address of err_no_argv onto the stack
    jmp _exit_error

_argv_to_many_passed:
    push err_no_argv                ; Push the address of err_no_argv onto the stack
    jmp _exit_error

_file_invalid:
    push err_file
    jmp _exit_error

_exit_error:
    ; Exit program with error code 1
    pop     rdi                    ; Pop the address of the error message into rdi
    call    print                  ; Call the print function to print the error message
    mov     rdi, 1                 ; Move 1 to rdi (exit status)
    jmp     _exit

_exit:
    mov     rax, 60     ; Syscall for exit
    syscall
