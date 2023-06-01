BITS 64

section .data
    filename        db 'output.txt', 0
    aInputX         db 'Input x: ',0
    aFloatFormat    db '%f',0
    aStringFormat   db '%f', 0
    aFileOpenFailed db 'Error: File open failed.', 0
    aInputPrecision db 'Input precision: ',0
    aLibResultF     db 'Lib result: %f',0Ah,0
    aCustomResultF  db 'Custom result: %f',0Ah,0
    three_double    dq 4008000000000000h
    one             dd 3F800000h
    minus_one       dd 0BF800000h
    three           dd 40400000h
    mask            dd 7FFFFFFFh
    four            dd 40800000h

section .text
    extern  scanf
    extern  printf
    extern  pow
    extern  fprintf
    extern  fopen
    extern  fclose
    extern  fabs
    extern  sin
    global  main

main:
    push    rbp
    mov     rbp, rsp
    push    rbx
    sub     rsp, 18h
    mov     [rbp - 18h], rax
    xor     eax, eax
    lea     rdx, [rbp - 1Ch]
    lea     rax, [rbp - 20h]
    mov     rsi, rdx        ; precision
    mov     rdi, rax        ; x
    call    scan
    movss   xmm0, [rbp - 1Ch]
    mov     eax, [rbp - 20h]
    movaps  xmm1, xmm0      ; precision
    movd    xmm0, eax       ; x
    call    custom
    movd    ebx, xmm0
    mov     eax, [rbp - 20h]
    movd    xmm0, eax       ; x
    call    lib
    movd    eax, xmm0
    movd    xmm1, ebx       ; result_custom
    movd    xmm0, eax       ; result_lib
    call    print
    mov     eax, 0
    mov     rdx, [rbp - 18h]
    mov     rbx, [rbp - 8h]
    leave
    retn

lib:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 20h
    movss   [rbp - 14h], xmm0
    pxor    xmm2, xmm2
    cvtss2sd xmm2, [rbp - 14h]
    movq    rax, xmm2
    movq    xmm0, rax       ; x
    call    sin
    cvtsd2ss xmm0, xmm0
    movss   [rbp - 4h], xmm0
    pxor    xmm3, xmm3
    cvtss2sd xmm3, [rbp - 4h]
    movq    rax, xmm3
    movsd   xmm0, [three_double]
    movapd  xmm1, xmm0      ; three_double
    movq    xmm0, rax       ; x
    call    pow
    cvtsd2ss xmm0, xmm0
    leave
    retn

custom:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 18h
    movss   [rbp - 14h], xmm0
    movss   [rbp - 18h], xmm1
    mov     qword[rbp - 0Ch], 0
    pxor    xmm0, xmm0
    movss   [rbp - 8h], xmm0
    .loop:
        add     qword[rbp - 0Ch], 1
        mov     edx, [rbp - 0Ch]
        mov     eax, [rbp - 14h]
        mov     edi, edx        ; n
        movd    xmm0, eax       ; x
        call    series_member
        call    print_file
        movd    eax, xmm0
        mov     [rbp - 4h], eax
        movss   xmm0, [rbp - 8h]
        addss   xmm0, [rbp - 4h]
        movss   [rbp - 8h], xmm0
        movss   xmm0, [rbp - 4h]
        movss   xmm1, [mask]
        andps   xmm0, xmm1
        comiss  xmm0, [rbp - 18h]
        jnb     .loop
    movss   xmm1, [rbp - 8h]
    movss   xmm0, [three]
    mulss   xmm0, xmm1
    movss   xmm1, [four]
    divss   xmm0, xmm1
    leave
    retn


series_member:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 18h
    movss   [rbp - 14h], xmm0
    mov     [rbp - 18h], edi
    pxor    xmm1, xmm1
    cvtsi2ss xmm1, [rbp - 18h]
    movss   xmm0, [one]
    addss   xmm0, xmm1
    movaps  xmm1, xmm0      ; p
    mov     eax, [minus_one]
    movd    xmm0, eax       ; x
    call    custom_pow
    movd    eax, xmm0
    mov     [rbp - 4h], eax
    pxor    xmm0, xmm0
    cvtsi2ss xmm0, [rbp - 18h]
    addss   xmm0, xmm0
    movaps  xmm1, xmm0      ; p
    mov     eax, [three]
    movd    xmm0, eax       ; x
    call    custom_pow
    movd    eax, xmm0
    movss   xmm1, [one]
    movd    xmm0, eax
    subss   xmm0, xmm1
    movss   xmm1, [rbp - 4h]
    mulss   xmm0, xmm1
    movss   [rbp - 4h], xmm0
    pxor    xmm0, xmm0
    cvtsi2ss xmm0, [rbp - 18h]
    movaps  xmm1, xmm0
    addss   xmm1, xmm0
    movss   xmm0, [one]
    addss   xmm0, xmm1
    mov     eax, [rbp - 14h]
    movaps  xmm1, xmm0      ; p
    movd    xmm0, eax       ; x
    call    custom_pow
    movss   xmm1, [rbp - 4h]
    mulss   xmm0, xmm1
    movss   [rbp - 4h], xmm0
    pxor    xmm0, xmm0
    cvtsi2ss xmm0, [rbp - 18h]
    movaps  xmm1, xmm0
    addss   xmm1, xmm0
    movss   xmm0, [one]
    addss   xmm0, xmm1
    cvttss2si eax, xmm0
    mov     edi, eax        ; n
    call    custom_fact
    pxor    xmm1, xmm1
    cvtsi2ss xmm1, eax
    movss   xmm0, [rbp - 4h]
    divss   xmm0, xmm1
    movss   [rbp - 4h], xmm0
    movss   xmm0, [rbp - 4h]
    leave
    retn

custom_pow:
    push    rbp
    mov     rbp, rsp
    movss   [rbp - 14h], xmm0
    movss   [rbp - 18h], xmm1
    movss   xmm0, [rbp - 14h]
    movss   [rbp - 4h], xmm0
    jmp     .check
    .loop:
        movss   xmm0, [rbp - 4h]
        mulss   xmm0, [rbp - 14h]
        movss   [rbp - 4h], xmm0
        movss   xmm0, [rbp - 18h]
        movss   xmm1, [one]
        subss   xmm0, xmm1
        movss   [rbp - 18h], xmm0
        .check:
            movss   xmm0, [rbp - 18h]
            movss   xmm1, [one]
            comiss  xmm0, xmm1
        ja      .loop
    movss   xmm0, [rbp - 4h]
    pop     rbp
    retn

custom_fact:
    push    rbp
    mov     rbp, rsp
    mov     [rbp - 14h], edi
    mov     eax, [rbp - 14h]
    mov     [rbp - 4h], eax
    jmp     .check
    .loop:
        sub     dword[rbp - 14h], 1
        mov     eax, [rbp - 4h]
        imul    eax, [rbp - 14h]
        mov     [rbp - 4h], eax
        .check:
            cmp     dword[rbp - 14h], 1
            jg      .loop
    mov     eax, [rbp - 4h]
    pop     rbp
    retn

scan:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 10h
    mov     [rbp - 8h], rdi
    mov     [rbp - 10h], rsi
    lea     rax, aInputX     ; "Input x: "
    mov     rdi, rax        ; msg_scan_x
    mov     eax, 0
    call    printf
    mov     rax, [rbp - 8h]
    mov     rsi, rax
    lea     rax, aFloatFormat   ; "%f"
    mov     rdi, rax
    mov     eax, 0
    call    scanf
    lea     rax, aInputPrecision ; "Input precision: "
    mov     rdi, rax        ; msg_scan_x
    mov     eax, 0
    call    printf
    mov     rax, [rbp - 10h]
    mov     rsi, rax
    lea     rax, aFloatFormat   ; "%f"
    mov     rdi, rax
    mov     eax, 0
    call    scanf
    leave
    retn

print:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 10h
    movss   [rbp - 4h], xmm0
    movss   [rbp - 8h], xmm1
    pxor    xmm2, xmm2
    cvtss2sd xmm2, [rbp - 4h]
    movq    rax, xmm2
    movq    xmm0, rax
    lea     rax, aLibResultF ; "Lib result: %f\n"
    mov     rdi, rax        ; format
    mov     eax, 1
    call    printf
    pxor    xmm3, xmm3
    cvtss2sd xmm3, [rbp - 8h]
    movq    rax, xmm3
    movq    xmm0, rax
    lea     rax, aCustomResultF ; "Custom result: %f\n"
    mov     rdi, rax        ; format
    mov     eax, 1
    call    printf
    nop
    leave
    retn

print_file:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 10h
    movss   [rbp - 4h], xmm0     ; Save the series_member value in [rbp - 4h]
    mov     rdi, filename        ; Set the filename
    mov     rax, 0               ; File open mode: 0 (write mode)
    call    fopen                ; Open the file
    mov     [rbp - 8h], rax      ; Save the file pointer in [rbp - 8h]
    cmp     dword[rbp - 8h], 0   ; Check if file pointer is NULL (file opening failed)
    je      .file_open_failed    ; If file opening failed, jump to file_open_failed
    mov     rdx, [rbp - 4h]      ; Load the series_member value into rdx
    mov     rax, [rbp - 8h]      ; Load the file pointer into rax
    mov     rdi, aStringFormat   ; Set the format string for fprintf
    call    fprintf              ; Print the series_member value to the file
    mov     rax, [rbp - 8h]      ; Load the file pointer into rax
    mov     rdi, rax             ; Set the file pointer as the argument for fclose
    call    fclose               ; Close the file
    jmp     .end                 ; Jump to the end of the function
    .file_open_failed:
        lea     rdi, [aFileOpenFailed]       ; Load the error message
        call    printf                       ; Print the error message to the console
    .end:
        nop
        leave
        retn