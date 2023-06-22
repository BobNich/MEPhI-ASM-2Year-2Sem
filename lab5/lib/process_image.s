section .data
    ; Syscall
    SYS_READ    equ 0
    SYS_WRITE   equ 0x01
    SYS_OPEN    equ 0x02
    SYS_CLOSE   equ 0x03
    SYS_MMAP    equ 0x09
    SYS_MUNMAP  equ 0x0b
    SYS_EXIT    equ 0x3c

    ; Lengths
    length_header               equ 0x36
    length_footer               equ 0x54
    length_input_file_error     equ 25
    length_output_file_error    equ 26

    ; Messages
    input_file_error    db "Error opening input file", 0x0a, 0
    output_file_error   db "Error opening output file", 0x0a, 0

section .bss
    header  resb 0x36
    footer  resb 0x54

section .text
    global  process_image

process_image:
    ; Arguments: rdi = input_filename, rsi = output_filename
    ; Call scan_image
    lea     rdi, [rdi]      ; input_filename
    push    rsi             ; save output_filename
    call    scan_image      ; scan_image(input_filename)

    ; Save for writing
    push    rax     ; size
    push    rbx     ; data

    ; Process image data
    mov     rcx, rax
    .process_loop:
        test    rcx, rcx
        jz      .end_process_loop

        ; Load r, g, b
        movzx   rdi, byte [rbx]         ; r
        movzx   rsi, byte [rbx + 0x01]  ; g
        movzx   rdx, byte [rbx + 0x02]  ; b

        ; reverse color
        xor     rdi, 0xff
        xor     rsi, 0xff
        xor     rdx, 0xff

        ; Store gray in data[i], data[i+1], data[i+2]
        mov     byte [rbx], dil
        mov     byte [rbx + 0x01], sil
        mov     byte [rbx + 0x02], dl

        ; Update loop variables
        add     rbx, 3
        sub     rcx, 3
        jmp     .process_loop
    .end_process_loop:

    ; Call write_image
    pop     rsi             ; data
    pop     rdx             ; size
    pop     rdi             ; output_filename
    call    write_image     ; write_image(output_filename = rdi, data = rsi, size = rdx)

    ; Call munmap
    mov     rax, SYS_MUNMAP
    mov     rdi, rdx        ; data
    mov     rsi, rcx        ; size
    syscall                 ; munmap(addr = rdi, length = rsi)
    ret

scan_image:
    ; Arguments: rdi = input_filename
    mov     rax, SYS_OPEN
    xor     rsi, rsi        ; no flags
    xor     rdx, rdx        ; no permissions
    syscall                 ; open(pathname = rdi, flags = rsi, mode = rdx)
    cmp     rax, -1         ; check if file opened successfully
    jge     .continue
        mov     rdi, input_file_error           ; message
        mov     rsi, length_input_file_error    ; length
        call    error_exit                      ; error_exit(message = rdi, length = rsi)
    .continue:

    ; Save file descriptor
    mov     r10, rax

    ; Read header
    mov     rax, SYS_READ
    mov     rdi, r10                ; file descriptor
    mov     rsi, header             ; buffer
    mov     rdx, length_header      ; count
    syscall                         ; read(fd = rdi, buf = rsi, count = rdx)

    ; Get width and height from header
    mov     eax, dword[rsi + 0x12]
    mov     ebx, dword[rsi + 0x16]

    ; Calculate size = 3 * width * height
    imul    rax, rbx
    imul    rax, 0x03
    push    rax

    ; Map memory for data
    push    r10
    mov     rsi, rax        ; length
    mov     rax, SYS_MMAP
    xor     rdi, rdi        ; starting address
    mov     rdx, 0x03       ; PROT_READ | PROT_WRITE
    mov     r10, 0x21       ; MAP_SHARED | MAP_ANONYMOUS
    mov     r8, -1          ; no file descriptor
    xor     r9, r9          ; no offset
    syscall                 ; mmap(addr = rdi, length = rsi, prot = rdx, flags = r10, fd = r8, offset = r9)
    mov     rbx, rax        ; save the pointer into rbx
    pop     r10

    ; Read data into mapped memory
    mov     rax, SYS_READ
    mov     rdi, r10        ; file descriptor
    mov     rdx, rsi        ; count
    mov     rsi, rbx        ; buffer
    syscall                 ; read(fd = rdi, buf = rsi, count = rdx)

    ; Read footer
    mov     rax, SYS_READ
    mov     rdi, r10                ; file descriptor
    mov     rdx, length_footer      ; count
    mov     rsi, footer             ; buffer
    syscall                         ; read(fd = rdi, buf = rsi, count = rdx)

    ; Return size
    pop     rax
    ret

write_image:
    ; Arguments: rdi = output_filename, rsi = data, rdx = size
    ; Save arguments
    push    rsi     ; data
    push    rdx     ; size

    ; Open file
    mov     rax, SYS_OPEN
    mov     rsi, 102o       ; write and create file flags
    mov     rdx, 600o       ; user read/write permissions
    syscall                 ; open(filename = rdi, flags = rsi, mode = rdx)cmp     rax, -1         ; check if file opened successfully
    jge     .continue
        mov     rdi, output_file_error              ; message
        mov     rsi, length_output_file_error       ; length
        call    error_exit                          ; error_exit(message = rdi, length = rsi)
    .continue:

    ; Save file descriptor
    mov     r10, rax

    ; Write header
    mov     rax, SYS_WRITE
    mov     rdi, r10                ; file descriptor
    mov     rsi, header             ; header
    mov     rdx, length_header      ; count
    syscall                         ; write(fd = rdi, buf = rsi, count = rdx)

    ; Write data
    mov     rax, SYS_WRITE
    mov     rdi, r10        ; file descriptor
    pop     rdx             ; count
    pop     rsi             ; data
    syscall                 ; write(fd = rdi, buf = rsi, count = rdx)

    ; Write footer
    mov     rax, SYS_WRITE
    mov     rdi, r10                 ; file descriptor
    mov     rsi, footer              ; footer
    mov     rdx, length_footer       ; count
    syscall

    ; Close file
    mov     rax, SYS_CLOSE
    mov     rdi, r10        ; file descriptor
    syscall                 ; close(fd = rdi)
    ret

error_exit:
    ; Arguments: rdi = message, rsi = length
    ; Print error message
    mov     rax, SYS_WRITE
    mov     rdx, rsi        ; count
    mov     rsi, rdi        ; message
    mov     rdi, 1          ; stdout descriptor
    syscall                 ; write(fd = rdi, buf = rsi, count = rdx)

    ; Terminate program
    mov     rax, SYS_EXIT
    xor     rdi, rdi        ; status 0
    syscall                 ; exit(status = rdi)