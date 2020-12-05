; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 5 (part 1)
;   by Alicja Piecha

; Place input in 5.in
; nasm -f elf64 5a.asm && ld 5a.o -o 5a && ./5a

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED but it does work on my input so idk.

global _start
section .rodata
input:
  incbin "5.in"
inputend:
section .text
_start:
  mov rbp, rsp
  mov r11, input
  
  ; rax: row
  ; rbx: column
  ; rcx: ID
  ; rdx: scratch for sete
  ; r11: input
  ; r15: result
loop:
  xor eax, eax
  xor ebx, ebx

  cmp byte [r11], 'B'
  sete dl
  or rax, rdx
  shl rax, 1

  cmp byte [r11+1], 'B'
  sete dl
  or rax, rdx
  shl rax, 1

  cmp byte [r11+2], 'B'
  sete dl
  or rax, rdx
  shl rax, 1

  cmp byte [r11+3], 'B'
  sete dl
  or rax, rdx
  shl rax, 1

  cmp byte [r11+4], 'B'
  sete dl
  or rax, rdx
  shl rax, 1

  cmp byte [r11+5], 'B'
  sete dl
  or rax, rdx
  shl rax, 1

  cmp byte [r11+6], 'B'
  sete dl
  or rax, rdx

  cmp byte [r11+7], 'R'
  sete dl
  or rbx, rdx
  shl rbx, 1

  cmp byte [r11+8], 'R'
  sete dl
  or rbx, rdx
  shl rbx, 1

  cmp byte [r11+9], 'R'
  sete dl
  or rbx, rdx

  mov rcx, rax
  shl rcx, 3
  add rcx, rbx

  cmp r15, rcx
  jge .skip
  mov r15, rcx
.skip:

  add r11, 11
  cmp r11, inputend
  jge itoa
  jmp loop

itoa:
  mov r10, 10
  sub rsp, 22            ; longest string possible from u64 plus newline plus one
                         ; (we inc r9 every time so we have to compensate)
  mov byte [rbp-1], `\n`
  lea r12, [rbp-2]
  ; r12: string pointer
  mov rax, r15

.loop:
  xor edx, edx           ; rdx is used as upper bytes for division
  div r10
  add rdx, '0'
  mov [r12], dl
  dec r12
  cmp r12, rsp
  jne .loop

  mov r9, rsp
  mov r11, 22
.trim:
  inc r9
  dec r11
  cmp byte [r9], '0'
  je .trim

  mov rax, 1             ; write
  mov rdi, 1             ; fd (stdout)
  mov rsi, r9            ; buf
  mov rdx, r11           ; count
  syscall

  mov rax, 60            ; exit
  mov rdi, 0             ; exit code
  syscall
