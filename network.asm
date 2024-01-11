
global _start

struc   sockaddr
	sin_family:	resw	1
	sin_port:	resw	1
	sin_addr:	resd	1
    padding:    resb    8

endstruc

struc   inaddr
	s_addr:	resq	1

endstruc

section .data


    sock_addr:
        istruc sockaddr
            at sin_family,	dw	0x02
            at sin_port,	dw	0x3500
            at sin_addr,	dd	0x1a01a8c0
            at padding,     dq  0X0000000000000000
        iend
        
    sock_addr_size EQU $ - sock_addr


    short_message db 'wikipedia'
    short_message_length EQU $ - short_message

    time_wait dd 0x00000001
              dd 0x00000000




section .bss

    request_content: resb 500
    request_content_size EQU $ - request_content


    time_left: resb 8

    pipe_fd: resb 4
             resb 4


    recvfrom_src_addr: resw 1
                       resb 14
                       
    recvfrom_src_addr_size EQU $ - recvfrom_src_addr

    dns_ID: resw 1

section .text

_start:

    push rbp
    mov rbp, rsp
    sub rsp, 0x40
    
    mov rdi, 0x2 ; AF_INET
    mov rsi, 0x2 ; SOCK_DGRAM
    mov rdx, 0x0 ; IPPROTO_IP
    mov rax, 0x29 
    syscall ; creates the socket
    mov [rbp - 0x08], rax ; save the socket fd in the stack


    mov rdi, dns_ID ; buffer
    mov rsi, 0x02 ; buffer size
    mov rdx, 0x00 ; flags
    mov rax, 0x013e
    syscall ; get random bytes for the dns ID

    xor rcx, rcx

    mov rax, [dns_ID] ; DNS Query ID
    mov [request_content+rcx], ax
    add rcx, 2

    mov rax, 0x00 ; DNS Flags
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, 0x0100 ; DNS QDCOUNT
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, 0x0000 ; DNS ANCOUNT
    mov [request_content + 6], ax
    add rcx, 2

    mov [request_content + 8], ax ; DNS NSCOUNT
    add rcx, 2

    mov [request_content + 10], ax ; DNS ARCOUNT
    add rcx, 2

    mov rax, short_message_length ; DNS QNAME LENGTH 1
    mov [request_content + 12], al
    add rcx, 1

    mov [rbp - 0x10], rcx ; save the request content size in the stack
    mov rdi, request_content ; buffer destination
    mov rsi, short_message ; buffer source
    mov rdx, short_message_length ; buffer size
    mov r10, rcx ; buffer destination offset
    call create_message ; create the message
    mov rcx, [rbp - 0x10] ; restore the request content size from the stack
    add rcx, rax ; add the message size to the request content size

    mov rax, 0x03 ; DNS QNAME LENGTH 2
    mov [request_content + rcx], al
    add rcx, 1

    mov al, 0x63
    mov [request_content + rcx], al
    inc rcx
    mov al, 0x6f
    mov [request_content + rcx], al
    inc rcx
    mov al, 0x6d
    mov [request_content + rcx], al
    inc rcx

    mov rax, 0x00 ; DNS QNAME Null Terminator
    mov [request_content + rcx], al
    add rcx, 1


    
    mov rax, 0x1c00 ; DNS QTYPE
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, 0x0100 ; DNS QCLASS
    mov [request_content + rcx], ax
    add rcx, 2

    
    mov rdi, [rbp - 0x08] ; socket fd
    mov rsi, request_content ; message
    mov rdx, rcx; message length
    mov r10, 0x0 ; flags
    mov r8, sock_addr ; sockaddr
    mov r9, sock_addr_size ; sockaddr size
    mov rax, 0x2c
    syscall ; udp sendto


    mov rdi, [rbp - 0x08] ; socket fd
    mov rsi, request_content ; buffer
    mov rdx, request_content_size ; buffer size
    mov r10, 0x0 ; flags
    mov r8, 0x00 ; sockaddr
    mov r9, 0x00 ; sockaddr size
    mov rax, 0x2d
    syscall ; udp recvfrom

    mov [rbp - 0x10], rax ; save the number of bytes received in the stack

    mov rdi, 0x01 ; stdout
    mov rsi, request_content ; buffer
    mov rdx, [rbp - 0x10] ; buffer size
    mov rax, 0x01
    syscall ; write the received data to stdout

    
    mov rdi, [rbp - 0x08] ; socket fd
    mov rax, 0x3
    syscall ; close the socket



    mov rdi, 0 ; exit code
    mov rax, 60
    syscall ; exit




    create_message:

        xor rcx, rcx

        create_message_loop:

            mov al, byte [rsi+rcx] ; get the first byte of the message
            mov [rdi + r10], al
            inc r10
            inc rcx
            cmp rcx, rdx
            jl create_message_loop

            mov rax, rcx ; return the message size
            ret





