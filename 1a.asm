; Advent of Code 2020
; Day 1 (part 1)
; by Alicja Piecha

; Place input in 1.in (<= 4096 bytes)
; nasm -f elf64 1a.asm && ld 1a.o -o 1a && ./1a

global _start
section .data
  input: db "1.in", 0
section .text
_start:
  mov rbp, rsp

  ; mmap
  mov rax, 9      ; mmap
  ;xor edi, edi   ; addr (registers start out zeroed)
  mov rsi, 8192   ; len (2 pages ought to be enough for anybody)
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

  ; read
  mov rdi, rax    ; fd (from last syscall)
  xor eax, eax    ; read
  mov rsi, r12    ; buf (saved allocation's address)
  mov rdx, 4096   ; count (try to get everything at once)
  syscall
  mov r14, rax    ; save bytes read

atoi:
  mov r13, r12
  add r13, 4096  ; second page
  ; r12: address of first page (input string)
  ; r13: address of second page (u16 array)
  ; r14: bytes read into buffer
  mov rsi, r12
  mov rdi, r13
  ; rsi: pointer for reading
  ; rdi: pointer for writing
.outer:
  xor eax, eax
  ; rax: current number
.inner:
  imul rax, 10          ; move digits to the left
  movzx rbx, byte [rsi]
  add rax, rbx          ; add a new digit to the right
  sub rax, 48           ; '0'
  inc rsi               ; next byte
  cmp byte [rsi], 10    ; '\n'
  jne .inner            ; we hit a newline so we're done with this number
  inc rsi               ; skip the newline
  mov [rdi], ax         ; save converted number
  add rdi, 2            ; ready up for next save
  ; check if we've converted all read bytes
  ; r14 == rsi - r12
  mov rcx, rsi
  sub rcx, r12
  cmp rcx, r14
  jne .outer

  ; insertion sort based on Wikipedia's pseudocode (second snippet)
sort:
  ; r13: beginning of numbers array
  ; rdi: end of numbers array
  mov rax, r13
  add rax, 2
.outer:
  mov cx, [rax]
  mov rbx, rax
  sub rbx, 2

  cmp rbx, r13
  jl .after
  cmp [rbx], cx
  jle .after
  jmp .inner
.inner:
  mov dx, [rbx]
  mov [rbx+2], dx
  sub rbx, 2

  cmp rbx, r13
  jl .after
  cmp [rbx], cx
  jle .after
  jmp .inner
.after:
  
  mov [rbx+2], cx
  add rax, 2

  cmp rax, rdi
  jl .outer

search:
  mov r10, 10
  ; r10: ten (for div)
  mov r14, r13
  ; r14: currently checked number's address
.outer:
  movzx r8, word [r14]
  add r14, 2
  ; r8: currently checked number
  ; r13: beginning of numbers array
  ; rdi: end of numbers array
  mov rbx, 0
  mov rcx, rdi
  sub rcx, r13
  sub rcx, 2
  shr rcx, 1
  ; rbx: left index
  ; rcx: right index
  mov rsi, 2020
  sub rsi, r8
  ; rsi: target
.inner:
  mov rax, rbx
  add rax, rcx
  shr rax, 1
  ; rax: midpoint index
  mov rdx, rax
  shl rdx, 1
  add rdx, r13
  ; rdx: midpoint address
  cmp [rdx], si
  jl .less
  jg .more
  jmp itoa
.less:
  lea rbx, [rax+1]
  jmp .after
.more:
  lea rcx, [rax-1]
.after:

  cmp rbx, rcx
  jle .inner
  jmp .outer

itoa:
  imul rsi, r8           ; calculate the solution!

  sub rsp, 22            ; longest string possible from u64 plus newline plus one
                         ; (we inc r9 every time so we have to compensate)
  mov byte [rbp-1], 10   ; '\n'
  lea r12, [rbp-2]
  ; r12: string pointer
  mov rax, rsi

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
