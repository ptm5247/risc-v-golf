%ifndef DEBUG

BITS 32

          org       0x00ba0000

%else

          global    _start

%endif

;         read(open(argv[1], O_RDONLY), &mem, 512KB)

ehdr:     db        0x7f, "ELF"             ; File identification bytes
dtbl:     db        20, 5
          db        7, 5
          db        15, 5
          db        0, 0
          db        12, 3
          db        4, 3
target:   dw        2                       ; Executable file
          dw        3                       ; Intel 80386
          dd        1                       ; Current version
          dd        _start
          dd        phdr-$$
_start:   mov       ebx, [esp+8]            ; 0x8b, 0x5c, 0x24, 0x08
          mov       al, 5                   ; 0xb0, 0x05
          int       0x80                    ; 0xcd, 0x80
          jmp       phdr.L0
          dw        phdrsize                ; Program header size
phdr:     dd        1                       ; Loadable program segment
          dd        0                       ; segstart-$$
ehdrsize  equ       $-ehdr
          dw        0
  .L0:    mov       edx, 0x80000            ; 0xba, 0x00, 0x00, 0x08, 0x00
          nop                               ; 0x90
          sub       esp, edx                ; 0x29, 0xd4
          mov       esi, esp                ; 0x89, 0xe6
          sub       esp, edx                ; 0x29, 0xd4
          mov       esi, esp                ; 0x89, 0xe6
          add       esp, -128               ; 0x83, 0xc4, 0x80
          mov       ebx, eax                ; 0x89, 0xc3
          mov       ecx, esi                ; 0x89, 0xf1
          int       0x80                    ; 0xcd, 0x80
phdrsize  equ       ($-1)-phdr

; edi starts as zero so execution can fall through -> AUIPC -> fetch

; 4
UIMM:
  .AUIPC: lea       ebx, [ebx+ecx-4]        ;  4
  .LUI:                                     ;  0

; 9
finally:  test      edi, edi                ;  7
          jz        .ret
          mov       [esp+4*edi], ebx
  .ret:   jmp       fetch                   ;  2

; 69
help:

  .SLT:   jnl       .L1                     ; 7
    .L0:  xor       ebx, ebx
          inc       ebx
          jmp       finally
  .SLTU:  jb        .L0                     ; 6
    .L1:  xor       ebx, ebx
          jmp       finally

  .SRL:   shl       eax, 1                  ; 12
          jns       .L2
          sar       ebx, cl
          jmp       finally
    .L2:  shr       ebx, cl
          jmp       finally

  .ADD:   test      al, 0b01000000          ; 14
          jz        .L3
          shl       eax, 1
          jns       .L3
          neg       ecx
    .L3:  add       ebx, ecx
          jmp       finally

  .TAKE:  lea       esi, [esi+ebp-4]        ; 6
          jmp       finally.ret

; 8
base:     db        LOAD-base
          db        OP-base
          db        STORE-base
          db        OP-base
          db        0
          db        0
          db        BRANCH-base
          db        SYSTEM-base

help.ECALL:
          cmp       dword [esp+4*17], 10    ; 24
          jne       finally.ret
          mov       ecx, esp
          pop       ebx
          inc       ebx
          lea       eax, [ebx+3]
          lea       edx, [ebx+127]
          int       0x80                    ; write(stdout, &regs, 128)
          xor       eax, eax
          xchg      eax, ebx
          int       0x80                    ; exit(EXIT_SUCCESS)

sparse:   ; 12: sparse switch
          cmp       al, 0b01101110
          je        UIMM.LUI
          cmp       al, 0b00101110
          je        UIMM.AUIPC
          cmp       al, 0b11011110
          je        JUMP.JAL

; 12
JUMP:
  .JALR:  mov       esi, ebp                ;  4
          jmp       .L0
  .JAL:   lea       esi, [esi+edx-4]        ;  8
  .L0:    mov       ebx, ecx
          jmp       finally

;
;         Current Register State:
;
;         esi     = pc
;         esp     = &regs
;         esp+128 = &mem
;

; 1
fetch:    lodsd

; 92
decode:   ; 22: unpack
          push      esi
          mov       ebp, eax
          mov       esi, dtbl
          xor       ecx, ecx
          mov       cl, 6
  .L0:    push      eax
          lodsw
          bextr     eax, ebp, eax
          loop      .L0

          ; 20: create target
          mov       edi, esi
          lea       ebx, [edi+base-target]
          xlat                              ; eax = opcode[6:4] -> rel offset
          lea       esi, [ebx+eax]          ; esi = abs offset
          lodsd
          dec       esi
          pop       edx                     ; edx = funct3
          shl       edx, 1
          add       esi, edx
          movsw
          mov       [edi], eax

          ;  8: prepare registers
          sar       ebp, 20
          push      ebp                     ; eax = *pc    esp = &regs
          push      ebp                     ; ecx = rs2    ebp = I
          push      ebp                     ; edx = rd     esi = pc + 4
          popa                              ; ebx = rs1    edi = I
          pop       esi

          ; 42: prepare registers
          mov       ebx, [esp+4*ebx]        ; ebx = *rs1
          mov       ecx, [esp+4*ecx]        ; ecx = *rs2
          test      al, 0b00100000
          cmovz     ecx, ebp                ; ecx = *rs2 | I
          xchg      edx, edi                ; edi = rd, edx = I
          and       dl, 0b11100000
          or        edx, edi                ; edx = S
          shl       al, 1
          cmp       al, 0b01000110
          cmove     ebp, edx                ; ebp =  I | S
          lea       ebp, [ebp+esp+127]
          add       ebp, ebx
          inc       ebp                     ; ebp = &mem + *rs1 + ( I | S )
          rcr       dh, 4
          btr       edx, 0
          rcl       dh, 4                   ; edx = B

;
;         Current Register State:
;
;         eax     = *pc[31:8,6:0,0]       ebx = *rs1
;         esi     = pc + 4                ecx = *rs2 | I
;         esp     = &regs                 edx = B
;         esp+128 = &mem                  edi = rd
;                                         ebp = &mem + *rs1 + ( I | S )
;

; 46
execute:  ; 13: dense opcodes
          test      al, 0b00011000
          jnz       .L0
          xchg      ebp, edx
          cmp       ebx, ecx
          jmp       target

          ; 23: sparse immediates
  .L0:    mov       ebx, eax                ; ebx = U, edx = J
          mov       cl, 12
          sar       ebx, cl
          mov       edx, ebx
          sar       edx, 8
          rcr       edx, cl
          mov       dl, bl
          btr       edx, 21
          rcl       edx, cl
          shl       ebx, cl

          ;  5: rel pc
          lea       ecx, [esi-128]          ; ecx = rel pc + 4
          sub       ecx, esp

          jmp       sparse

; 19
OP:       jmp       $+(finally-(target+2))
          db        0
          jmp       $+(help.ADD-target)     ; EB imm8
          shl       ebx, cl                 ; D3 E3
          jmp       $+(help.SLT-target)     ; EB imm8
          jmp       $+(help.SLTU-target)    ; EB imm8
          xor       ebx, ecx                ; 31 CB
          jmp       $+(help.SRL-target)     ; EB imm8
          or        ebx, ecx                ; 09 CB
          and       ebx, ecx                ; 21 CB

; 15
LOAD:     db        0x1A
          jmp       $+(finally-(target+3))
          db        0x0F, 0xBE              ; movsx ebx,byte[edx] - 0F BE 1A
          db        0x0F, 0xBF              ; movsx ebx,word[edx] - 0F BF 1A
SYSTEM    equ       $-1
          db        0x90, 0x8B              ; mov   ebx,    [edx] -    8B 1A
          jmp       $+(help.ECALL-target)
          db        0x0F, 0xB6              ; movzx ebx,byte[edx] - 0F B6 1A
          db        0x0F, 0xB7              ; movzx ebx,word[edx] - 0F B7 1A

; 9
STORE:    db        0x0A
          jmp       $+(finally.ret-(target+3))
          db        0x90, 0x88              ; mov [edx],cl  -    88 0A
          db        0x66, 0x89              ; mov [edx],cx  - 66 89 0A
          db        0x90, 0x89              ; mov [edx],ecx -    89 0A

; 19
BRANCH:   jmp       $+(finally.ret-(target+2))
          db        0
          je        $+(help.TAKE-target)    ; 74 imm8
          jne       $+(help.TAKE-target)    ; 75 imm8
          times 4 db 0
          jl        $+(help.TAKE-target)    ; 7C imm8
          jge       $+(help.TAKE-target)    ; 7D imm8
          jb        $+(help.TAKE-target)    ; 72 imm8
          jae       $+(help.TAKE-target)    ; 73 imm8
