BITS 64

section .data
    cols	db 3
    rows	db 5

matrix:
    dq  233,    142,    101	
    dq  222,	93,	    20	
    dq  170,	25,	    137	
    dq  23,	    119,	62	
    dq  216,	149,	235

section .bss
    min_array       resq 3
    indexes_array   resq 3
    result_matrix   resq 15

section .text
    global _start

_start:

main:
    call    setup_indexes_array
    call    find_min
    call    sort_prepare
    call    sort
    .end:
    jmp     _exit_normal


; Actually sort
sort:
    mov     rax, 0               ; init local counter
    movzx   ecx, byte [cols]    ; counter
    .iterate_indexes_array:
        lea     rbx, [indexes_array + rax * 8]    ; calculate the address of next element in indexes_array
        mov     rbx, qword [rbx]                  ; load the current element

        push    rcx
        call    add_result_column                 ; add `rbx`-th column to result column
        pop     rcx

        inc     rax                               ; increment counter
        loop     .iterate_indexes_array            ; loop
    .end_loop:
    ret

; Add i-th column in result matrix
add_result_column:
    lea     rsi, [result_matrix + rax * 8] ; calculate the address of the `rbx`-th matrix column
    lea     rdi, [matrix + rbx * 8]        ; calculate the address of the `rax`-th column

    ; Iterate over each row of the two columns.
    movzx   ecx, byte [rows]   ; rcx = number of rows

    .iterate_row:
        mov     r8, [rdi]
        mov     qword [rsi], r8    ; store element in result_matrix
        
        ; Move to the next element in each column.
        movzx   r8, byte [cols]             ; r8 = columns number
        lea     rsi, [rsi + r8 * 8]         ; move to the next element in the result matrix column
        lea     rdi, [rdi + r8 * 8]         ; move to the next element in the matrix column

        ; Continue iterating over the rows while there are still elements left.
        loop    .iterate_row
    
     ; Return to the caller.
    ret

; Sort min_array and indexes_array
sort_prepare:
    movzx   eax, byte [cols]   ; rax = len
    dec     rax                ; rax = right = len - 1
    mov     rbx, 0             ; rbx = left
    .shaker_loop:
        cmp     rbx, rax
        jg     .end_sort        ; if left > right, done
        mov     rcx, rbx        ; rcx = j
        .forward_loop:
            mov     r10, -1     ; gap = -1
            call    compare     ; compare min[j] ? min[j+1]
            cmp     rbp, 1
            je      .swap_forward_loop      ; if no need to swap (min[j], min[j+1])
            inc     rcx                     ; j++
            cmp     rcx, rax
            jge      .forward_done          ; if j >= right, done
            jmp     .forward_loop
        .swap_forward_loop:
            call    perform_swap_indexes_array_and_min_array   ; swap(min[j], min[j+1])
            inc     rcx                    ; j++
            cmp     rcx, rax
            jge      .forward_done          ; if j >= right, done
            jmp     .forward_loop
        .forward_done:
        mov     rcx, rax                   ; rcx = j
        .backward_loop:
            mov     r10, 1     ; gap = 1
            call    compare                ; compare min[j] ? min[j - 1]
            cmp     rbp, 0
            je      .swap_backward_loop
            dec     rcx                    ; j--
            cmp     rcx, rbx               ; if j =< left, done
            jle     .backward_done
            jmp     .backward_loop
        .swap_backward_loop:
            call    perform_swap_indexes_array_and_min_array   ; swap(min[j-1], min[j])
            dec     rcx                    ; j--
            cmp     rcx, rbx               ; if j =< left, done
            jle      .backward_done
            jmp     .backward_loop
        .backward_done:
        inc     rbx              ; left++
        dec     rax              ; right--
        jmp     .shaker_loop
    .end_sort:
    ret

; Initialize indexes array with indexes
setup_indexes_array:
    mov r12, indexes_array      ; load the address of the indexes_array
    mov rax, 0                  ; init first element
    movzx   ecx, byte [cols]    ; counter
    .initialize_array:
        mov     qword [r12], rax        ; load the current element
        lea     r12, [r12 + 8]             ; move to the next element in the min array
        inc     rax                     ; increment counter
        loop     .initialize_array      ; loop
    ret

; Finds the minimum elements in the columns and adds them to the min array
find_min:
    mov     rsi, matrix       ; load the address of the matrix
    mov     rdi, min_array    ; load the address of the min_array
    movzx   ecx, byte [cols]  ; load the number of columns
    mov     r11, 0            ; local row number counter
    .iterate_cols:
        mov     rbx, qword [rsi]  ; reset the minimum value first one in column
        push    rcx               ; save the outer loop counter
        movzx   ecx, byte [rows]  ; load the number of rows
        .iterate_rows:
            mov    rax, qword [rsi] ; load the current element
            cmp    rax, rbx         ; compare it with the minimum value
            jge    .skip_update     ; if greater or equal, skip updating the minimum value
            mov    rbx, rax         ; otherwise, update the minimum value
            .skip_update:
            movzx   r8 , byte [cols]       ; r8 = columns number
            lea     rsi, [rsi + r8 * 8]    ; move to the next element in the column
            loop    .iterate_rows          ; loop for all rows
        pop     rcx                        ; restore the outer loop counter    
        mov     qword [rdi], rbx           ; store the minimum value in the min array
        lea     rdi, [rdi + 8]             ; move to the next element in the min array
        add     r11, 1                     ; increment row number counter
        lea     rsi, [matrix + r11 * 8]    ; reset 'rsi' and move to the next column
        loop    .iterate_cols              ; loop for all columns
    ret   

; Compare `j`-th and `j - gap`-th element of min_aray and "raise" the need_swap flag according to the sort type
compare:
    ; Load the address of the `j`-th element of min_array into 'rsi' register
    lea     rsi, [min_array + rcx * 8]

    ; Load the value of `min[j]` into the `rdi` register
    mov   rdi, qword [rsi]

    ; Calculate the address of `min[j - gap]` and load its value into the `rsi` register
    lea     r8, [r10 * 8]    ; calculate the offset to get the address of the `j - gap`-th element
    sub     rsi, r8          ; get the address of the `j - gap`-th element

    ; Load the value of `min[j - gap]` into the `rsi` register
    mov   rsi, qword [rsi]


    .sort_condition:
        %ifdef UPWARD
        cmp     rsi, rdi
        jg      .need_swap
        jge     .no_swap
        %endif

        %ifdef BACKWARD
        cmp     rsi, rdi
        jl      .need_swap
        jge     .no_swap
        %endif

    .need_swap:
        ; Set the return value to 1 indicating that a swap is needed
        mov     rbp, 1
        ret
    .no_swap:
        ; Set the return value to 0 indicating that no swap is needed
        mov     rbp, 0
        ret

swap_indexes_array_and_min_array:
    ; Calculate the memory addresses of the two corresponing elements in "indexes_array".
    lea     rax, [indexes_array + rsi * 8] ; calculate the address of the first column
    lea     rbx, [indexes_array + rdi * 8] ; calculate the address of the second column

    ; Calculate the memory addresses of the two corresponing elements in "min" array.
    lea     rdx, [min_array + rsi * 8] ; calculate the address of the corresponing first column element
    lea     rsi, [min_array + rdi * 8] ; calculate the address of the corresponing second column element

    .swap_min:
        ; Swap the values of the corresponding elements in the "min" array.
        mov r8, [rdx]
        xchg r8, [rsi]
        mov [rdx], r8

    .swap_indexes_array:
        ; Swap the values of the corresponding elements in the two columns.
        mov     r8, [rax]
        xchg    r8, [rbx]
        mov     [rax], r8

    ; Return to the caller.
    ret

perform_swap_indexes_array_and_min_array:
    push    rax
    push    rbx
    push    rcx
    mov     rbp, rcx
    sub     rbp, r10
    mov     rsi, rbp
    mov     rdi, rcx
    call    swap_indexes_array_and_min_array        ; swap(rcx, rcx - r10)
    pop     rcx
    pop     rbx
    pop     rax
    ret

; Exit program normally
_exit_normal:
    mov     rdi, 0
    jmp     _exit

; Exit program with error code 1
_exit_error:
    mov     rdi, 1
    jmp     _exit

_exit:
    mov     rax, 60     ; Syscall for exit
    syscall