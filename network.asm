
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
            at sin_addr,	dd	0x33b6a8c0
            at padding,     dq  0X0000000000000000
        iend
        
    sock_addr_size EQU $ - sock_addr


    short_message db 0xc6,0x9f,0x01,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x09,0x77,0x69,0x6b,0x69,0x70,0x65,0x64,0x69,0x61,0x03,0x6f,0x72,0x67,0x00,0x00,0x01,0x00,0x01
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



    mov rdi, [rbp - 0x08] ; socket fd
    mov rsi, short_message ; message
    mov rdx, short_message_length ; message length
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





