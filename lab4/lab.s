BITS 64

section .data
    file_w_m        db 'w', 0
    fd              dq 0
    aInputX         db 'Input x: ',0
    aFloatFormat    db '%f',0
    aStringFormat   db '%f', 0
    aArgsError      db "Use ./lab <filename> to run program properly", 0x0a, 0
    aFileOpenFailed db 'Error: File open failed.',0Ah,0
    aTermInfinity   db 'Term is infinity',0Ah,0
    aSeriesMember   db "%-10d %f",0x0a,0
    aInputPrecision db 'Input precision: ',0
    aLibResultF     db 'Lib result: %f',0Ah,0
    aCustomResultF  db 'Custom result: %f',0Ah,0
    three_double    dq 4008000000000000h
    one             dd 3F800000h
    minus_one       dd 0BF800000h
    three           dd 40400000h
    mask            dd 7FFFFFFFh
    four            dd 40800000h

section .bss
    filename resb 256

section .text
    extern  scanf
    extern  printf
    extern  pow
    extern  fprintf
    extern  fopen
    extern  fclose
    extern  fabs
    extern  isinf
    extern  sin
    extern  exit
    global  main

main:
    push    rbp
    mov     rbp, rsp
    push    rbx
    sub     rsp, 18h
    mov     eax, edi
    cmp     eax, 2
    jne     .args_error
    mov	    rcx, [rsi + 8]
    call    get_filename
    mov     [rbp - 18h], rax
    xor     eax, eax
    lea     rdx, [rbp - 1Ch]
    lea     rax, [rbp - 20h]
    mov     rsi, rdx        ; precision
    mov     rdi, rax        ; x
    call    scan
    call    open_file
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
    call    close_file
    jmp     .end_program
    .args_error:
        mov     rdi, aArgsError
        call    printf
        leave
        retn
    .end_program:
        leave
        retn

get_filename:
    push    rbp
    mov     rbp, rsp
    xor rdx, rdx
    .copy_filename_loop:
        mov al, byte [rcx + rdx]
        mov [filename + rdx], al
        cmp al, 0
        je .done_filename_copying
        inc rdx
        jmp .copy_filename_loop
    .done_filename_copying:
        mov [filename + rdx], al
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
    mov     rdi, aFloatFormat
    call    printf
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

open_file:
    push    rbp
    mov     rbp, rsp
    mov     rdx, file_w_m
    mov     rax, filename
    mov     rdi, rax
    mov     rsi, rdx
    call    fopen
    cmp     rax, 0
    je      .file_open_failed
    mov     [fd], rax
    leave
    ret
    .file_open_failed:
        mov     rdi, aFileOpenFailed
        call    printf
        mov     rdi, 1
        call    exit
        leave
        ret

close_file:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 18h
    mov     rax, [fd]
    mov     rdi, rax
    call    fclose
    leave
    ret

print_file:
    ; -------------------------------------------------
    ; TODO №2 (Print series member and it's 'n'-номер члена в ряде)
    ; push    rbp
    ; mov     rbp, rsp
    ; mov     rdi, [fd]
    ; mov     rsi, aSeriesMember
    ; mov     rdx, 1
    ; xor     rax, rax
    ; call    fprintf
    ; leave
    ; retn
     ; -------------------------------------------------