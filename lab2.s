BITS 64

section .data
asc     db ASCENDING
rows	db 10
cols	db 9
matrix:
    db 0xe9, 0x8e, 0x65, 0x94, 0x60, 0xc2, 0x08, 0x5c, 0x87
	db 0xde, 0x5d, 0x14, 0x68, 0x29, 0xc8, 0xe3, 0x1a, 0xfe
	db 0xaa, 0x19, 0x89, 0xc9, 0xe1, 0xf5, 0xb7, 0xf4, 0x01
	db 0x17, 0x77, 0x3e, 0x4e, 0xc1, 0xf5, 0x3b, 0xe2, 0xbe
	db 0xd8, 0x95, 0xeb, 0x68, 0x87, 0x20, 0x89, 0x87, 0x99
	db 0x3e, 0x28, 0x24, 0x2a, 0xb4, 0x84, 0x44, 0xa0, 0xe2
	db 0x56, 0xa1, 0x38, 0xfb, 0x71, 0x24, 0x00, 0xf3, 0x3c
	db 0x40, 0x3c, 0xbb, 0x1f, 0xf9, 0x4f, 0x5e, 0xbd, 0x6b
	db 0x90, 0x15, 0xeb, 0x18, 0x63, 0x49, 0xd0, 0x1e, 0x1a
	db 0xa3, 0x19, 0xed, 0x2b, 0xcc, 0x89, 0x62, 0x74, 0x45


section .bss
    min      resb 10

section .text
    global _start

_start:

main:
    call    find_min_columns
    call    sort
    .end:
    jmp     _exit_normal

sort:
    ret

find_min_columns:
    mov     esi, matrix       ; load the address of the matrix
    mov     edi, min          ; load the address of the min array
    movzx   ecx, byte [cols]  ; load the number of columns
    .iterate_cols:
        xor     ebx, ebx      ; reset the minimum value to 0
        push    rcx           ; save the outer loop counter
        movzx   ecx, byte [rows]  ; load the number of rows
        .iterate_rows:
            movzx   eax, byte [esi]  ; load the current element
            cmp     eax, ebx         ; compare it with the minimum value
            jge     .skip_update     ; if greater or equal, skip updating the minimum value
            mov     ebx, eax         ; otherwise, update the minimum value
            .skip_update:
            add     esi, cols        ; move to the next element in the column
            loop    .iterate_rows    ; loop for all rows
        pop     rcx                ; restore the outer loop counter
        mov     byte [edi], bl     ; store the minimum value in the min array
        inc     edi                ; move to the next element in the min array
        mov     esi, matrix       ; reset the matrix pointer to the beginning of the column
        add     esi, ecx          ; move to the next column
        loop    .iterate_cols      ; loop for all columns
    ret   

; Swaps the values of two columns in the matrix and updates the corresponding
; values in the "min" array.

swap_columns:
    ; Move the indices of the two columns into registers.
    mov     eax, esi   ; eax = index of the first column to be swapped
    mov     ebx, edi   ; ebx = index of the second column to be swapped

    ; Calculate the memory addresses of the two columns.
    ; The size of each element is assumed to be 1 byte.
    lea     eax, [eax*2+eax] ; multiply the index of the first column by 3 (3 bytes per column)
    add     eax, matrix    ; add the result to the base address of the matrix
    lea     ebx, [ebx*2+ebx] ; multiply the index of the second column by 3 (3 bytes per column)
    add     ebx, matrix    ; add the result to the base address of the matrix

    ; Iterate over each row of the two columns.
    movzx   ecx, byte [rows]    ; ecx = number of rows
    .swap_max:
        ; Calculate the memory addresses of the corresponding elements in the "min" array.
        mov     edx, esi    ; edx = index of the first column
        add     edx, ecx    ; add the current row index
        add     edx, min    ; add the base address of the "min" array
        mov     esi, edi    ; esi = index of the second column
        add     esi, ecx    ; add the current row index
        add     esi, min    ; add the base address of the "min" array

        ; Swap the values of the corresponding elements in the "min" array.
        movzx   edx, byte [esi]  ; edx = value of the second element in the "min" array
        xchg    dl, byte [edx]   ; swap the values of the two elements in the "min" array
        mov     byte [esi], dl   ; store the new value of the second element in the "min" array

    .iterate_rows:
        ; Swap the values of the corresponding elements in the two columns.
        movzx   edx, byte [eax]  ; edx = value of the current element in the first column
        xchg    dl, byte [ebx]   ; swap the values of the corresponding elements in the two columns
        mov     byte [eax], dl   ; store the new value of the current element in the first column

        ; Move to the next element in each column.
        add     eax, byte [cols] ; add the number of columns to the address of the current element in the first column
        add     ebx, byte [cols] ; add the number of columns to the address of the current element in the second column

        ; Continue iterating over the rows while there are still elements left.
        loop    .iterate_rows

    ; Return to the caller.
    ret

perform_swap_columns:
    push    rax
    push    rbx
    push    rcx
    mov     ebp, ecx
    sub     ebp, eax
    mov     esi, ebp
    mov     edi, ecx
    call    swap_columns        ; swap(ecx, ecx - eax)
    pop     rcx
    pop     rbx
    pop     rax
    ret


find_min_rows:
    mov     esi, matrix  ; load the address of the matrix
    mov     edi, min     ; load the address of the min array
    movzx   ecx, byte [rows]  ; load the number of rows
    .iterate_rows:
        xor     ebx, ebx  ; reset the minimum value to 0
        push    rcx       ; save the outer loop counter
        movzx   ecx, byte [cols]  ; load the number of columns
        .iterate_cols:
            movzx   eax, byte [esi]  ; load the current element
            cmp     eax, ebx         ; compare it with the minimum value
            jge     .skip_update     ; if greater or equal, skip updating the minimum value
            mov     ebx, eax         ; otherwise, update the minimum value
            .skip_update:
            inc     esi              ; move to the next element
            loop    .iterate_cols    ; loop for all columns
        pop     rcx           ; restore the outer loop counter
        mov     byte [edi], bl  ; store the minimum value in the min array
        inc     edi            ; move to the next element in the min array
        loop    .iterate_rows  ; loop for all rows
    ret

; Swaps the values of two rows in the matrix and updates the corresponding
; values in the "min" array.

swap_rows:
    ; Move the indices of the two rows into registers.
    mov     eax, esi   ; eax = index of the first row to be swapped
    mov     ebx, edi   ; ebx = index of the second row to be swapped

    ; Calculate the memory addresses of the two rows.
    ; The size of each element is assumed to be 1 byte.
    mul     byte [cols]    ; multiply the index of the first row by the number of columns
    add     eax, matrix    ; add the result to the base address of the matrix
    xchg    eax, ebx       ; swap the two addresses
    mul     byte [cols]    ; multiply the index of the second row by the number of columns
    add     eax, matrix    ; add the result to the base address of the matrix

    ; Iterate over each column of the two rows.
    movzx   ecx, byte [cols]    ; ecx = number of columns
    .swap_max:
        ; Calculate the memory addresses of the corresponding elements in the "min" array.
        add     esi, min    ; add the index of the first row to the base address of the "min" array
        add     edi, min    ; add the index of the second row to the base address of the "min" array

        ; Swap the values of the corresponding elements in the "min" array.
        movzx   edx, byte [edi]  ; edx = value of the second element in the "min" array
        xchg    dl, byte [esi]   ; swap the values of the two elements in the "min" array
        mov     byte [edi], dl   ; store the new value of the second element in the "min" array

    .iterate_cols:
        ; Swap the values of the corresponding elements in the two rows.
        movzx   edx, byte [eax]  ; edx = value of the current element in the first row
        xchg    dl, byte [ebx]   ; swap the values of the corresponding elements in the two rows
        mov     byte [eax], dl   ; store the new value of the current element in the first row

        ; Move to the next element in each row.
        inc     eax             ; increment the address of the current element in the first row
        inc     ebx             ; increment the address of the current element in the second row

        ; Continue iterating over the columns while there are still elements left.
        loop    .iterate_cols

    ; Return to the caller.
    ret

perform_swap_rows:
    push    rax
    push    rbx
    push    rcx
    mov     ebp, ecx
    sub     ebp, eax
    mov     esi, ebp
    mov     edi, ecx
    call    swap_rows        ; swap(ecx, ecx - eax)
    pop     rcx
    pop     rbx
    pop     rax
    ret

compare:
    ; Load the base address of the `min` array into the `esi` register
    mov     esi, min
    ; Add `ecx` to `esi` to get the address of the `j`-th element
    add     esi, ecx
    ; Load the value of `min[j]` into the `edi` register
    movzx   edi, byte [esi]
    ; Calculate the address of `min[j - gap]` and load its value into the `esi` register
    sub     esi, eax
    movzx   esi, byte [esi]
    ; Compare the values in ascending or descending order based on the `asc` flag
    cmp     byte [asc], 1
    je      .asc
    jmp     .descending
    .asc:
        ; Swap if `min[j - gap] > min[j]`
        cmp     esi, edi
        jg      .need_swap
        jmp     .no_swap
    .descending:
        ; Swap if `min[j - gap] < min[j]`
        cmp     esi, edi
        jl      .need_swap
        jmp     .no_swap
    .need_swap:
        ; Set the return value to 1 indicating that a swap is needed
        mov     rbp, 1
        ret
    .no_swap:
        ; Set the return value to 0 indicating that no swap is needed
        mov     rbp, 0
        ret

_exit_normal:
    ; Exit program normally
    mov     rdi, 0
    jmp     _exit

_exit_error:
    ; Exit program with error code 1
    mov     rdi, 1
    jmp     _exit

_exit:
    mov     rax, 60     ; Syscall for exit
    syscall
