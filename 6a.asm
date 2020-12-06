; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 6 (part 1)
;   by Alicja Piecha

; Place input in 6.in
; nasm -f elf64 6a.asm && ld 6a.o -o 6a && ./6a

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED but it does work on my input so idk.

global _start
section .rodata
input:
  incbin "6.in"
inputend:
section .bss
letters:
  resb 26
section .text
_start:
  mov rbp, rsp
  mov r11, input

  ; r11: input
  ; r15: result

outer:
  mov rax, 26
  xor ebx, ebx
.loop:
  dec rax
  mov bl, [letters+rax]
  add r15, rbx
  mov byte [letters+rax], 0
  test rax, rax
  jnz .loop
  cmp r11, inputend
  jge itoa
inner:
  cmp r11, inputend
  jge outer
  cmp byte [r11], `\n`
  jne letter
  sete bl
  cmp byte [r11+1], `\n`
  sete cl
  inc r11
  and cl, bl
  jz inner
  inc r11
  jmp outer
letter:
  mov al, [r11]
  sub al, 'a'
  mov byte [letters+rax], 1
  inc r11
  jmp inner

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
