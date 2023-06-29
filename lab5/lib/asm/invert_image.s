section .data
; No data section is required for this function

section .text
global invert_image

invert_image:
    ; Function prologue
    push rbp
    mov rbp, rsp
    
    ; Saving non-volatile registers
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Extract function parameters
    mov rdi, rdi ; image_data
    mov esi, esi ; width
    mov edx, edx ; height
    mov ecx, ecx ; channels
    
    ; Calculate pixel_count
    mov r8, esi   ; r8 = width
    imul r8, edx  ; r8 = width * height
    
    ; Loop counter
    xor r9d, r9d
    
invert_loop:
    ; Calculate image_data index
    mov rax, r9  ; rax = loop_counter
    imul rax, ecx  ; rax = loop_counter * channels
    
    ; Invert the color channels
    xor byte [rdi + rax], 0xFF
    xor byte [rdi + rax + 1], 0xFF
    xor byte [rdi + rax + 2], 0xFF
    
    ; Increment loop counter
    inc r9d
    cmp r9d, r8d  ; Compare loop_counter with pixel_count
    jl invert_loop
    
    ; Function epilogue
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    
    ; Return from the function
    ret