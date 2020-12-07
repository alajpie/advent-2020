; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 7 (part 1)
;   by Alicja Piecha

; Place input in 7.in
; nasm -f elf64 7a.asm && ld 7a.o -o 7a && ./7a

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED but it does work on my input so idk.

global _start

section .rodata
input:
  incbin "7.in"
input_end:

section .bss
t2i_table:
  resb 4096
tree:
  resb 16384
cache:
  resb 1024

section .text
; name2tag
; rdi: pointer to two words separated by space and ended by space
; eax (result): tag (crc32)
n2t:
  xor eax, eax
  mov rcx, 2
.loop:
  cmp byte [rdi], ' '
  jne .continue
  dec rcx
  test rcx, rcx
  jnz .continue
  ret
.continue:
  crc32 eax, byte [rdi]
  inc rdi
  jmp .loop


; tag2index
; edi: tag
; rsi: t2i_table end
; rax (result): index
t2i:
  ; rcx: min
  ; rsi: max
  ; rax: current
  mov rcx, t2i_table
.loop:
  mov rax, rsi
  sub rax, rcx
  shr rax, 1
  add rax, rcx
  and rax, -4  ; clear two last bits to align
  cmp [rax], edi
  jb .higher
  je .equal
.lower:
  sub rax, 4
  mov rsi, rax
  jmp .loop
.higher:
  add rax, 4
  mov rcx, rax
  jmp .loop
.equal:
  sub rax, t2i_table
  shr rax, 2   ; address to index
  ret


; name2index
; rdi: pointer to two words separated by space and ended by space
; rsi: t2i_table end
; rax (result): index
n2i:
  push rsi
; rdi: pointer to two words separated by space and ended by space
  call n2t
  mov edi, eax
  pop rsi
; edi: tag
; rsi: t2i_table end
  call t2i
  ret
  

_start:
  mov rbp, rsp

; build t2i_table
; r12: table pointer
; rbx: input pointer
build_table:
  mov r12, t2i_table
  mov rbx, input  

.loop:
  cmp rbx, input_end
  jge sort
  mov rdi, rbx
  call n2t
  mov [r12], eax
  add r12, 4
.skip:
  inc rbx
  cmp byte [rbx], `\n`
  jne .skip
  inc rbx
  jmp .loop

  ; insertion sort based on Wikipedia's pseudocode (second snippet)
sort:
  ; t2i_table: beginning of numbers array
  ; r12: end of numbers array
  mov rax, t2i_table
  add rax, 4
.outer:
  mov ecx, [rax]
  mov rbx, rax
  sub rbx, 4

  cmp rbx, t2i_table
  jb .after
  cmp [rbx], ecx
  jbe .after
  jmp .inner
.inner:
  mov edx, [rbx]
  mov [rbx+4], edx 
  sub rbx, 4

  cmp rbx, t2i_table
  jb .after
  cmp [rbx], ecx
  jbe .after
  jmp .inner
.after:
  
  mov [rbx+4], ecx
  add rax, 4

  cmp rax, r12
  jl .outer

  mov r13, input
; r12: t2i_table end
; r13: input pointer
build_tree:
.parent:
  cmp r13, input_end
  jge traverse
  mov rdi, r13
  mov rsi, r12
  call n2i
  mov rbx, rax
  shl rbx, 4
  ; rbx: next child's offset in the tree

.child:
.loop:
  inc r13
  cmp byte [r13], `\n`
  jne .sameline
  inc r13
  jmp .parent
.sameline:
  cmp byte [r13], '0'
  jl .loop
  cmp byte [r13], '9'
  jg .loop

  movzx rax, byte [r13]
  sub rax, '0'
  ; rax: count
  mov [tree+rbx], ax
  add rbx, 2

  add r13, 2  ; next name

  mov rdi, r13
  mov rsi, r12
  call n2i
  ; rax: child
  mov [tree+rbx], ax
  add rbx, 2
  jmp .child
  
traverse:
  ; r12: t2i_table end
  ; r15: result
  mov r13, r12
  sub r13, t2i_table
  shr r13, 2
  ; r13: last index
  mov edi, 0x309277af  ; tag of shiny gold
  mov rsi, r12
  call t2i
  mov byte [cache+rax], 2
  xor edi, edi

.loop:
  push rdi
  xor edx, edx
  call subtree
  pop rdi
  add r15, rax
  inc rdi
  
  cmp rdi, r13
  jge itoa
  jmp .loop


; rdi: index
; rdx: depth
; rax (result): contains shiny gold
subtree:
  push rbp
  mov rbp, rsp
  cmp byte [cache+rdi], 1
  jg .yes
  je .no
  cmp rdx, 1024           ; too deep
  jge .saveno
  inc rdx
  mov r9, rdi
  ; rcx: offset
  mov r8, 4               ; max amount of children
  mov rcx, rdi
  shl rcx, 4

.loop:
  test r8, r8             ; checked all children
  jz .saveno
  cmp word [tree+rcx], 0  ; no more children
  jz .saveno
  movzx rdi, word [tree+rcx+2]
  push r8
  push rcx
  push rdx
  push r9
  call subtree
  pop r9
  cmp rax, 1
  je .saveyes
  pop rdx
  pop rcx
  pop r8
  add rcx, 4
  dec r8
  jmp .loop
.saveyes:
  mov byte [cache+r9], 2
.yes:
  mov eax, 1
  leave
  ret
.saveno:
  mov byte [cache+r9], 1
.no:
  xor eax, eax
  leave
  ret
  
itoa:
  dec r15                ; we count the gold bag as yes so we need to exclude it
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
