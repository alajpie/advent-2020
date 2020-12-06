; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 5 (part 2)
;   by Alicja Piecha

; Place input in 5.in
; nasm -f elf64 5b.asm && ld 5b.o -o 5b && ./5b

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
  xor rcx, rcx

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

  push cx

  add r11, 11
  cmp r11, inputend
  jl loop

  ; insertion sort based on Wikipedia's pseudocode (second snippet)
sort:
  ; rsp: beginning of numbers array
  ; rbp: end of numbers array
  mov rax, rsp
  add rax, 2
.outer:
  mov cx, [rax]
  mov rbx, rax
  sub rbx, 2

  cmp rbx, rsp
  jl .after
  cmp [rbx], cx
  jle .after
  jmp .inner
.inner:
  mov dx, [rbx]
  mov [rbx+2], dx
  sub rbx, 2

  cmp rbx, rsp
  jl .after
  cmp [rbx], cx
  jle .after
  jmp .inner
.after:
  
  mov [rbx+2], cx
  add rax, 2

  cmp rax, rbp
  jl .outer

find:
  xor eax, eax
  xor ebx, ebx
.loop:
  mov ax, [rsp]
  add rsp, 2
  mov bx, [rsp]
  inc ax
  cmp ax, bx
  jz .loop

  mov r15, rax
  mov rsp, rbp

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
