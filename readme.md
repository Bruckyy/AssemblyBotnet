# x64 Assembly DDoS Botnet

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
## Description

Simple assembly DDoS linux implant that communicate over DNS to a C2 and receive a target IP to attack.

## Features
- Persistency
- Anti-debugging
- Communication with C2 via DNS

## Persistency
Recuperation of the $HOME env in the execution of the stack for copy himself in `/home/$USER/.ssh` and add auto-execution in `$USER/.bashrc`.  The orginal programs then fork to a new process and execute the newly created copy before deleting himself.

## Anti-debugging

Use of **ptrace** syscall, commonly used by debuggers or tracing programs to attach and probe into another program's execution state. If our program is already attached by another the syscall will fail (return -1) which tells us that our program is being debugged, so we can modify the program's behavior and do nothing malicious. On top of that the call of **ptrace** is obfuscated when looking statically at the code, the program modify itself to write the syscall opcode during runtime.

## DNS Communication

The Program, when executed on the victim's machine, sends periodic udp datagrams to signal it is ready to receive an order. The datagram is masquerading as a legitimate DNS request for 'wikipedia.org', with a randomly generated transaction ID that will be used to encrypt future exchange with the control server. The victim then waits a few second waiting for an answer, and if none comes, it closes the socket and waits for another few seconds before trying again.
If an answer is received, the victim parse the answer to isolate the fake IPV6 address that contains the encrypted ipv4 address to target with an ICMP flooding attack.

## Schema  
![ddosbotnet drawio](https://github.com/Bruckyy/AssemblyBotnet/assets/73838483/b9e8b7ac-fa0f-4e43-b64a-fdcc7b8c03e0)

## Building

To build the program, you need to use the NASM assembler and LD linker with the -N flag enabled to make the .text section writable because the anti debugging features are written to the program at runtime.

```bash
nasm -f elf64 -o implant.o implant.asm && ld -N -o implant.exe implant.o
```
