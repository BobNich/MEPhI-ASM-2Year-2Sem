
BITS 64

; (a^3 + b^3) / (a^2 * c - b^2 * d + e)

section .data
    ; Input variables
    a       dw  32768    ; 16-bit
    b       db  128       ;  8-bit
    c       dd  10       ; 32-bit
    d       dd  200      ; 32-bit
    e       dd  2147483648       ; 32-bit

    ; Output variable
    result  dq  0       ; 64-bit

section .text
    global _start

_start:
    ; Load input variables
    movzx   eax, word[a]
    movzx   ebx, byte[b]
    mov     ecx, [c]
    mov     edi, [d]
    mov     esi, [e]

_numerator:
    ; Compute r9 = a^3
    mov    r8, rax      ; r8 = rax = a
    mul    r8           ; rax = a^2
    mul    r8           ; rax = a^3
    mov    r9, rax      ; r9 = a^3

    ; Compute rax = b^3
    mov    rax, rbx     ; rax = rbx = b
    mul    rbx          ; rax = b^2
    mul    rbx          ; rax = b^3
    
    ; Compute r9 = a^3 + b^3
    add    r9, rax      ; r9 = a^3 + b^3

_denominator:
    ; Compute rcx = a^2 * c
    mov     rax, r8     ; rax = a
    mul     r8          ; rax = a^2
    mul     rcx         ; rax = a^2 * c
    mov     rcx, rax    ; rcx = rax = a^2 * c

    ; Compute rdi = b^2 * d
    mov     rax, rbx        ; rax = b
    mul     rbx             ; rax = b^2
    mul     rdi             ; rax = b^2 * d
    mov     rdi, rax        ; rdi = rax = b^2 * d

    ; Compute rcx = a^2 * c - b^2 * d
    sbb     rcx, rdi        ; rcx = a^2 * c - b^2 * d
    jc      _exit_error     ; b^2 * d is bigger than a^2 * c

    ; Compute rcx = a^2 * c - b^2 * d + e
    add     rcx, rsi
    jc      _exit_error

    ; Check the denominator for zero
    cmp     rcx, 0
    je      _exit_error

    _result:
    ; Compute rax = (a^3 + b^3) / (a^2 * c - b^2 * d + e)
    mov     rax, r9     ; rax = (a^3 + b^3)
    div     rcx         ; rax = (a^3 + b^3) / (a^2 * c - b^2 * d + e)
    mov     qword[result], rax ; result = rax 
    jmp     _exit_normal

_exit_normal:
    ; Exit program normally
    mov     rdi, 0
    jmp     _exit

_exit_error:
    ; Exit program with error code 1
    mov     rdi, 1
    jmp     _exit

_exit:
    ; Exit program
    mov     rax, 60     ; Syscall
    syscall
