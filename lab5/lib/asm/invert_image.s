section .data
; No data

section .text
global invert_image

invert_image:
    ; Calculate pixel_count
    mov r8, rsi   ; r8 = width
    imul r8, rdx  ; r8 = width * height
    
    ; Loop counter
    xor r9, r9
    
invert_loop:
    ; Calculate image_data index
    mov rax, r9  ; rax = loop_counter
    imul rax, rcx  ; rax = loop_counter * channels
    
    ; Invert the color channels
    xor byte [rdi + rax], 0xFF
    xor byte [rdi + rax + 1], 0xFF
    xor byte [rdi + rax + 2], 0xFF
    
    ; Increment loop counter
    inc r9
    cmp r9, r8  ; Compare loop_counter with pixel_count
    jl invert_loop

    ret