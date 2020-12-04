; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 4 (part 1)
;   by Alicja Piecha

; Place input in 4.in
; nasm -f elf64 4a.asm && ld 4a.o -o 4a && ./4a

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED but it does work on my input so idk.

global _start
section .rodata
input:
  incbin "4.in"  ; thanks u/process_parameter!
inputend:
keys:
  db "byr:"
  db "iyr:"
  db "eyr:"
  db "hgt:"
  db "hcl:"
  db "ecl:"
  db "pid:"
  db "cid:"
section .text
_start:
  mov rbp, rsp
  mov rax, input
  mov r10, 0b01111111  ; we don't care about cid
  
  ; rax: input
  ; rbx: key address
  ; ecx: key value
  ; rdx: bitmask
  ; r8: bitset
  ; r10: keys we care about
  ; r15: result
passport:
  xor r8d, r8d         ; reset the bitset

key:
  mov rbx, keys
  mov rdx, 1
.next:
  mov ecx, [rbx]
  add rbx, 4           ; go to next key
  cmp [rax], ecx
  je .matched
  shl rdx, 1           ; move bimask left
  jmp .next
.matched:
  or r8, rdx           ; set bit indicating key exists
  shl rdx, 1           ; move bimask left
  jmp value

value:
  add rax, 5            ; keys are 4 bytes long, all values are at least a byte long
.loop:
  cmp rax, inputend     ; check if we processed everything
  jge validity
  inc rax
  cmp byte [rax-1], 10  ; '\n'
  je .end
  cmp byte [rax-1], 32  ; ' '
  je .end
  jmp .loop
.end:
  cmp byte [rax], 10    ; '\n'
  je validity           ; double newline, end of passport
  jmp key

validity:
  inc rax               ; rax is on newline, move it to next key
  and r8, r10
  cmp r8, r10
  jne .invalid
  inc r15
.invalid:
  cmp rax, inputend     ; check if we processed everything
  jge itoa
  jmp passport

itoa:
  mov r10, 10
  sub rsp, 22            ; longest string possible from u64 plus newline plus one
                         ; (we inc r9 every time so we have to compensate)
  mov byte [rbp-1], 10   ; '\n'
  lea r12, [rbp-2]
  ; r12: string pointer
  mov rax, r15

.loop:
  xor edx, edx           ; rdx is used as upper bytes for division
  div r10
  add rdx, 48            ; '0'
  mov [r12], dl
  dec r12
  cmp r12, rsp
  jne .loop

  mov r9, rsp
  mov r11, 22
.trim:
  inc r9
  dec r11
  cmp byte [r9], 48      ; '0'
  je .trim

  mov rax, 1             ; write
  mov rdi, 1             ; fd (stdout)
  mov rsi, r9            ; buf
  mov rdx, r11           ; count
  syscall

  mov rax, 60            ; exit
  mov rdi, 0             ; exit code
  syscall
