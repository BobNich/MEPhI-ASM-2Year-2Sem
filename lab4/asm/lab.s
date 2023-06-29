BITS 64

section .data
    file_w_m        db 'w', 0
    fd              dq 0
    aInputX         db 'Input x: ',0
    aFloatFormat    db '%f',0
    aStringFormat   db '%f', 0
    aArgsError      db "Use ./lab <filename> to run program properly", 0x0a, 0
    aFileOpenFailed db 'Error: File open failed.',0Ah,0
    aTermInfinity   db 'Error: Term is infinity. All non-infinite elements are written to the file',0Ah,0
    aSeriesMember   db "%-10d %f",0x0a,0
    aInputPrecision db 'Input precision: ',0
    aLibResultF     db 'Lib result: %f',0Ah,0
    aCustomResultF  db 'Custom result: %f',0Ah,0
    three_double    dq 4008000000000000h
    minus_one       dd 0BF800000h
    mask            dd 7FFFFFFFh
    zero            dd 80000000h
    one             dd 3F800000h
    two             dd 40000000h
    three           dd 40400000h
    four            dd 40800000h
    eight           dd 41000000h
    nine            dd 41100000h

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
    sub     rsp, 28h
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
    push        rbp
    mov         rbp, rsp
    movss       [rbp - 24h], xmm0
    movss       [rbp - 28h], xmm1
    movss       xmm0, [rbp - 24h]
    mulss       xmm0, xmm0
    mulss       xmm0, [rbp - 24h]
    movss       xmm1, [eight]
    divss       xmm0, xmm1
    movss       [rbp - 14h], xmm0
    movss       xmm0, [eight]
    movss       [rbp - 10h], xmm0
    movss       xmm0, [rbp - 14h]
    mulss       xmm0, [rbp - 10h]
    movss       [rbp - 0Ch], xmm0
    pxor        xmm0, xmm0
    movss       [rbp - 8h], xmm0
    mov         [rbp - 4h], 0
    jmp         .end
    .loop:
        movss       xmm0, [rbp - 8h]
        addss       xmm0, [rbp - 0Ch]
        movss       [rbp - 8h], xmm0
        add         [rbp - 4h], 1
        movss       xmm0, [rbp - 14h]
        movss       xmm1, [zero]
        xorps       xmm1, xmm0
        movss       xmm0, [rbp - 24h]
        mulss       xmm0, xmm0
        mulss       xmm1, xmm0
        pxor        xmm0, xmm0
        cvtsi2ss    xmm0, [rbp - 4h]
        movaps      xmm2, xmm0
        addss       xmm2, xmm0
        movss       xmm0, [two]
        addss       xmm2, xmm0
        pxor        xmm0, xmm0
        cvtsi2ss    xmm0, [rbp - 4h]
        movaps      xmm3, xmm0
        addss       xmm3, xmm0
        movss       xmm0, [three]
        addss       xmm0, xmm3
        mulss       xmm2, xmm0
        divss       xmm1, xmm2
        movaps      xmm0, xmm1
        movss       [rbp - 14h], xmm0
        movss       xmm1, [rbp - 10h]
        movss       xmm0, [nine]
        mulss       xmm1, xmm0
        movss       xmm0, [eight]
        addss       xmm0, xmm1
        movss       [rbp - 10h], xmm0
        movss       xmm0, [rbp - 14h]
        mulss       xmm0, [rbp - 10h]
        movss       [rbp - 0Ch], xmm0
    .end:
        movss       xmm0, [rbp - 8h]
        movss       xmm1, [mask]
        andps       xmm0, xmm1
        comiss      xmm0, [rbp - 28h]
        ja          .loop
        movss       xmm0, [rbp - 8h]
        pop         rbp
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

check_infinity:
    push    rbp
    mov     rbp, rsp
    call    isinf
    cmp     rax, 0
    jne     .infinity
    jmp     .not_infinity
    .infinity:
        mov     eax, 0
        lea     rdi, aTermInfinity
        call    printf
        call    close_file
        mov     rdi, 1
        call    exit
        leave
        ret 
    .not_infinity:
        leave
        retn

open_file:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8
    lea     rdi, filename
    lea     rsi, file_w_m
    xor     edx, edx
    call    fopen
    mov     qword [rbp - 8], rax
    cmp     qword [rbp - 8], 0
    jne     .file_opened
    jmp     .error_exit
    .file_opened:
        mov     [fd], rax
        leave
        ret
    .error_exit:
        lea     rdi, aFileOpenFailed
        call    printf
        mov     rdi, 1
        call    exit
        leave
        ret

close_file:
    push    rbp
    mov     rbp, rsp
    mov     rdi, [fd]
    call    fclose
    leave
    ret

print_file:
    push        rbp
    mov         rbp, rsp
    sub         rsp, 8
    pxor        xmm2, xmm2
    cvtss2sd    xmm2, xmm0
    movq        rax, xmm2
    movq        xmm0, rax
    mov         rdi, [fd]
    lea         rsi, aSeriesMember
    mov         eax, 1
    call        fprintf
    movq        xmm0, xmm2
    add         rsp, 8
    leave
    retn