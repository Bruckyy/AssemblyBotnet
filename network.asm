
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

in_addr:
    istruc inaddr
        at s_addr, dd   0x00
    iend

sock_addr:
    istruc sockaddr
        at sin_family,	dw	0x02
	    at sin_port,	dw	0x5000
	    at sin_addr,	dd	0x00
        at padding,     db  0X0000000000000000
    iend
    
    sock_addr_size EQU $ - sock_addr



    response db `HTTP/1.0 200 OK\r\n\r\n`
    response_length EQU $ - response

    short_message db `Hello World!`
    short_message_length EQU $ - short_message


section .bss

    request_content: resb 500
    request_content_size EQU $ - request_content

    file_content: resb 500
    file_content_size EQU $ - file_content

    filename: resb 20
    filename_length EQU $ - filename

section .text

_start:

    push rbp
    mov rbp, rsp
    sub rsp, 0x40
    
    mov rdi, 0x2
    mov rsi, 0x1
    mov rdx, 0x0
    mov rax, 0x29
    syscall ; creates the socket
    mov [rbp - 0x08], rax ; save the socket fd in the stack

    mov rdi,rax
    mov rsi, sock_addr
    mov rdx, sock_addr_size
    mov rax, 0x31
    syscall ; bind the socket with an address and a port 


    mov rdi, [rbp - 0x08]
    mov rsi, sock_addr
    mov rdx, sock_addr_size
    mov rax, 0x2a
    syscall ; connect to remote computer

    mov rdi, [rbp - 0x08]
    mov rsi, short_message
    mov rdx, short_message_length
    mov rax, 0x1
    syscall ; send the short message
    
    mov rdi, [rbp - 0x08]
    mov rax, 0x3
    syscall ; close the connection



    mov rdi, 0
    mov rax, 60
    syscall ; exit

