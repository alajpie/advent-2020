; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 4 (part 2)
;   by Alicja Piecha

; Place input in 4.in
; nasm -f elf64 4b.asm && ld 4b.o -o 4b && ./4b

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
eyes:
  db "amb"
  db "blu"
  db "brn"
  db "gry"
  db "grn"
  db "hzl"
  db "oth"
section .text
_start:
  mov rbp, rsp
  mov r11, input
  
  ; rbx: key address
  ; ecx: key value
  ; r8: bitset
  ; r9: bitmask
  ; r11: input
  ; r15: result
passport:
  xor r8d, r8d         ; reset the bitset

key:
  mov rbx, keys
  mov r9, 1
.next:
  mov ecx, [rbx]
  add rbx, 4           ; go to next key
  cmp [r11], ecx
  je value
  shl r9, 1            ; move bimask left
  jmp .next

value:
  add r11, 4           ; keys are 4 bytes long

  cmp ecx, 'byr:'
  je .byr
  cmp ecx, 'iyr:'
  je .iyr
  cmp ecx, 'eyr:'
  je .eyr
  cmp ecx, 'hgt:'
  je .hgt
  cmp ecx, 'hcl:'
  je .hcl
  cmp ecx, 'ecl:'
  je .ecl
  cmp ecx, 'pid:'
  je .pid
  cmp ecx, 'cid:'
  je .valid

.byr:
  call atoi
  cmp r12, 1920
  jl .invalid
  cmp r12, 2002
  jg .invalid
  jmp .valid

.iyr:
  call atoi
  cmp r12, 2010
  jl .invalid
  cmp r12, 2020
  jg .invalid
  jmp .valid

.eyr:
  call atoi
  cmp r12, 2020
  jl .invalid
  cmp r12, 2030
  jg .invalid
  jmp .valid

.hgt:
  call atoi
  cmp word [rsi], 'in'
  sete r13b
  cmp word [rsi], 'cm'
  sete r14b
  or r13, r14
  jz .invalid
  cmp byte [rsi], 'i'
  je .in
.cm:
  cmp r12, 150
  jl .invalid
  cmp r12, 193
  jg .invalid
  jmp .valid
.in:
  cmp r12, 59
  jl .invalid
  cmp r12, 76
  jg .invalid
  jmp .valid

.hcl:
  cmp byte [r11], '#'
  jne .invalid
  xor edi, edi
.hex:
  inc rdi
  ; (x >= 0 && x <= 9) || (x >= a && x <= f)
  cmp byte [r11+rdi], '0'
  setge r13b
  cmp byte [r11+rdi], '9'
  setle r14b
  and r13, r14
  mov rsi, r13
  cmp byte [r11+rdi], 'a'
  setge r13b
  cmp byte [r11+rdi], 'f'
  setle r14b
  and r13, r14
  or rsi, r13
  jz .invalid
  cmp rdi, 6
  je .valid
  jmp .hex
   
.ecl:
  xor edi, edi
.eye:
  mov r13d, [eyes+rdi]
  and r13d, 0x00FFFFFF ; 3 bytes
  mov r14d, [r11]
  and r14d, 0x00FFFFFF
  cmp r13d, r14d
  je .valid
  add rdi, 3
  cmp rdi, 21          ; 7 eye colors, 3 bytes each
  je .invalid
  jmp .eye

.pid:
  xor edi, edi
  xor r13d, r13d
  mov rsi, r11
.digit:
  cmp byte [rsi], '0'
  jl .end
  cmp byte [rsi], '9'
  jg .end
  inc rsi
  inc r13
  jmp .digit
.end:
  cmp r13, 9
  je .valid
  jmp .invalid

.valid:
    or r8, r9           ; set bit indicating field is valid
.invalid:

.loop:
  cmp r11, inputend     ; check if we processed everything
  jge validity
  inc r11
  cmp byte [r11-1], `\n`
  je .done
  cmp byte [r11-1], ' '
  je .done
  jmp .loop
.done:
  cmp byte [r11], `\n`
  je validity           ; double newline, end of passport
  jmp key

atoi:
  ; r11 points to a number terminated by a non-numeric char
  ; we leave the converted number in r12

  mov rsi, r11
  xor r12d, r12d
  ; rsi: current byte

.loop:
  imul r12, 10          ; move digits to the left
  movzx r13, byte [rsi] ; current digit
  sub r13, '0'
  add r12, r13          ; add a new digit to the right
  inc rsi               ; next byte
  cmp byte [rsi], '0'
  jl .ret
  cmp byte [rsi], '9'
  jg .ret
  jmp .loop
.ret:
  ret

validity:
  inc r11               ; r11 is on newline, move it to next key
  and r8, 0b01111111    ; we don't care about cid
  cmp r8, 0b01111111
  jne .invalid
  inc r15
.invalid:
  cmp r11, inputend     ; check if we processed everything
  jge itoa
  jmp passport

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
