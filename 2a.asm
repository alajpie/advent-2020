; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 2 (part 1)
;   by Alicja Piecha

; Place input in 2.in (<= 32768 bytes)
; nasm -f elf64 2a.asm && ld 2a.o -o 2a && ./2a

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED but it does work on my input so idk.

global _start
section .data
  input: db "2.in", 0
section .text
_start:
  mov rbp, rsp
  
  ; r12: anonymous pages
  ; r13: fd
  ; r14: bytes read so far

  ; mmap
  mov rax, 9      ; mmap
  ;xor edi, edi   ; addr (registers start out zeroed)
  mov rsi, 32768  ; len (my input fits in 5 pages so 8 should be enough headroom)
  mov rdx, 3      ; prot (PROT_READ | PROT_WRITE)
  mov r10, 34     ; flags (MAP_PRIVATE | MAP_ANONYMOUS) 
  mov r8, -1      ; fd (-1 for compat)
  ;xor r9d, r9d   ; offset (doesn't matter)
  syscall
  mov r12, rax    ; save allocation's address

  ; open
  mov rax, 2      ; open
  mov rdi, input  ; filename 
  xor esi, esi    ; flags (O_RDONLY)
  ;xor edx, edx   ; mode (doesn't matter)
  syscall
  mov r13, rax    ; save the fd

read:
  ; read
  xor eax, eax    ; read
  mov rdi, r13    ; fd (from last syscall)
  mov rsi, r12    ; buf (saved allocation's address)
  mov rdx, 32768  ; count
  sub rdx, r14    ; don't overflow the buffer
  syscall
  add r14, rax    ; add bytes read
  test rax, rax   ; check if read 0 bytes
  jnz read        ;   which means EOF

  ; r12: base pointer
  ; r14: total bytes
  ; r8: minimum count
  ; r9: maximum count
  ; r10: character
  ; r11: intraline count
  ; rcx: total count

  xor ecx, ecx           ; clear total count
  mov rsi, r12           ; currently read byte
header:
  xor r11d, r11d         ; clear current count
  mov rax, rsi
  sub rax, r12
  cmp rax, r14
  jge itoa               ; check if we've processed all bytes
  cmp byte [rsi+1], 45   ; '-'
  jne .min2              ; if the second character is not a dash, minimum count has two digits
.min1:
  movzx r8, byte [rsi]   ; only digit
  sub r8, 48             ; '0'
  add rsi, 2             ; move pointer to max
  jmp .max
.min2:
  movzx r8, byte [rsi]   ; first digit
  sub r8, 48             ; '0'
  imul r8, 10            ; move to the left
  movzx rax, byte [rsi+1]
  add r8, rax            ; second digit
  sub r8, 48             ; '0'
  add rsi, 3             ; move pointer to max
.max:
  cmp byte [rsi+1], 32   ; ' '
  jne .max2              ; if the second character is not a space, maximum count has two digits
.max1:
  movzx r9, byte [rsi]   ; only digit
  sub r9, 48             ; '0'
  add rsi, 2             ; move pointer to char
  jmp .after
.max2:
  movzx r9, byte [rsi]   ; first digit
  sub r9, 48             ; '0'
  imul r9, 10            ; move to the left
  movzx rax, byte [rsi+1]
  add r9, rax            ; second digit
  sub r9, 48             ; '0'
  add rsi, 3             ; move pointer to char
.after:
  movzx r10, byte [rsi]  ; save char
  add rsi, 3             ; move pointer to text

line:
  cmp byte [rsi], r10b   ; check for correct character
  jne .different
  inc r11                ; increase count
.different:
  inc rsi                ; next character
  cmp byte [rsi], 10     ; '\n'
  jne line
  ; end of line
  inc rsi                ; make rsi point to next line
  cmp r11, r8            ; count > min
  jl header
  cmp r11, r9
  jg header              ; count < max
  inc rcx                ; increase total
  jmp header

  ; rcx: total count
  ; r10: ten (for div)

itoa:
  mov r10, 10
  sub rsp, 22            ; longest string possible from u64 plus newline plus one
                         ; (we inc r9 every time so we have to compensate)
  mov byte [rbp-1], 10   ; '\n'
  lea r12, [rbp-2]
  ; r12: string pointer
  mov rax, rcx

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
