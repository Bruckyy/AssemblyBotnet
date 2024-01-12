
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


    short_message db 'wikipedia'
    short_message_length EQU $ - short_message

    time_wait dq 0x0000000000000004
              dq 0x0000000000000000

    time_wait_size EQU $ - time_wait

    time_sleep dq 20
               dq 0
               
               



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



    mov rdi , [rbp - 0x08] ; socket fd
    mov rsi, 0x01
    mov rdx, 66
    mov r10, time_wait
    mov r8, time_wait_size
    mov rax, 0x36
    syscall ; set the socket timeout




    call write_dns_request ; write the dns request to the request content buffer

    
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

    cmp rax, 0x00 ; check if the recvfrom failed
    jg next
    
    mov rdi, [rbp - 0x08] ; socket fd
    mov rax, 0x3
    syscall ; close the socket

    mov rdi, time_sleep
    mov rsi, 0x00
    mov rax, 0x23
    syscall ; sleep for 4 seconds

    jmp _start ; try again



next:

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



;;;;;;;;;;;;;;;;;;;;;;; functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


create_message:
    push rbp
    mov rbp, rsp
    sub rsp, 0x40
    xor rcx, rcx

    create_message_loop:

        

        mov al, byte [rsi+rcx] ; get the first byte of the message
        mov [rdi + r10], al
        inc r10
        inc rcx
        cmp rcx, rdx
        jl create_message_loop

    mov rax, rcx ; return the message size
    leave
    ret



;;;


write_dns_request:

    push rbp
    mov rbp, rsp
    sub rsp, 0x40

    mov rdi, dns_ID ; buffer
    mov rsi, 0x02 ; buffer size
    mov rdx, 0x00 ; flags
    mov rax, 0x013e
    syscall ; get random bytes for the dns ID

    xor rcx, rcx

    mov rax, [dns_ID] ; DNS Query ID
    mov [request_content+rcx], ax
    add rcx, 2

    mov rax, 0x0001 ; DNS Flags
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

    mov al, 'o'
    mov [request_content + rcx], al
    inc rcx
    mov al, 'r'
    mov [request_content + rcx], al
    inc rcx
    mov al, 'g'
    mov [request_content + rcx], al
    inc rcx

    mov rax, 0x00 ; DNS QNAME Null Terminator
    mov [request_content + rcx], al
    add rcx, 1


    
    mov rax, 0x0100 ; DNS QTYPE
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, 0x0100 ; DNS QCLASS
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, rcx ; return the request content size
    
    leave
    ret
