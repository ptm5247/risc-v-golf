#include <elf.h>

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>

typedef int8_t i1;
typedef int16_t i2;
typedef int32_t i4;
typedef int64_t i8;
typedef uint8_t u1;
typedef uint16_t u2;
typedef uint32_t u4;
typedef uint64_t u8;

#define N_REGS 32         // number of registers
#define M_SIZE (1 << 20)  // size of the program's memory

i4  regs[N_REGS];         // registers
i1  mem[M_SIZE];          // program meory (1MB)
i1  *pc = mem;            // program counter

#define fetch   (*(i4 *)pc)
#define rd      (regs[fetch >>  7 & 0b11111])
#define rs1     (regs[fetch >> 15 & 0b11111])
#define rs2     (regs[fetch >> 20 & 0b11111])
#define sext(n) (i4)((i8)fetch >> 32 << n)
#define imm_i   (sext(11) | (fetch >> 20 & 0b11111111111))
#define imm_s   (sext(11) | (fetch >>  7 & 0b00000011111) \
                          | (fetch >> 20 & 0b11111100000))
#define imm_b   (sext(12) | (fetch >>  7 & 0b000000011110) \
                          | (fetch >> 20 & 0b011111100000) \
                          | (fetch <<  4 & 0b100000000000))
#define imm_u   (fetch & 0b11111111111111111111000000000000)
#define imm_j   (sext(20) | (fetch >> 20 & 0b00000000011111111110) \
                          | (fetch >>  9 & 0b00000000100000000000) \
                          | (fetch       & 0b11111111000000000000))

#define PC            (pc - mem)
#define M(addr, type) (*(type *)(mem + addr))

int main(int argc, char **argv) {

  int fd, flag;
  i4  map;

  if (argc != 2) {
    fprintf(stderr, "Usage: %s program\n", argv[0]);
    _exit(1);
  }

  fd = open(argv[1], O_RDONLY);                     // open the program
  read(fd, mem, M_SIZE);                            // read into memory

  do {
    map = fetch >> 2 & 0x1F;
    if ((map & 0x1) == 0)
      map |= fetch >> 7 & 0xE0;
    if ((map & 0xE4) == 0xA4 || map == 0xC)
      map |= fetch >> 29 & 0x2;
    map = ((map << 5) - map) >> 2 & 0x3F;

    switch (map) {
    case 29: /* ADD   */ rd = rs1 + rs2;                             goto incr;
    case 44: /* SUB   */ rd = rs1 - rs2;                             goto incr;
    case 61: /* XOR   */ rd = rs1 ^ rs2;                             goto incr;
    case 45: /* OR    */ rd = rs1 | rs2;                             goto incr;
    case 37: /* AND   */ rd = rs1 & rs2;                             goto incr;
    case 21: /* SLL   */ rd = rs1 << rs2;                            goto incr;
    case 53: /* SRL   */ rd = (u8)(u4)rs1 >> rs2;                    goto incr;
    case  4: /* SRA   */ rd = (i8)rs1 >> rs2;                        goto incr;
    case 13: /* SLT   */ rd = rs1 < rs2;                             goto incr;
    case  5: /* SLTU  */ rd = (u4)rs1 < (u4)rs2;                     goto incr;
    case 31: /* ADDI  */ rd = rs1 + imm_i;                           goto incr;
    case 63: /* XORI  */ rd = rs1 ^ imm_i;                           goto incr;
    case 47: /* ORI   */ rd = rs1 | imm_i;                           goto incr;
    case 39: /* ANDI  */ rd = rs1 & imm_i;                           goto incr;
    case 23: /* SLLI  */ rd = rs1 << imm_i;                          goto incr;
    case 55: /* SRLI  */ rd = (u8)(u4)rs1 >> imm_i;                  goto incr;
    case  6: /* SRAI  */ rd = (i8)rs1 >> imm_i;                      goto incr;
    case 15: /* SLTI  */ rd = rs1 < imm_i;                           goto incr;
    case  7: /* SLTIU */ rd = (u4)rs1 < (u4)imm_i;                   goto incr;
    case  0: /* LB    */ rd = M(rs1 + imm_i, i1);                    goto incr;
    case 56: /* LH    */ rd = M(rs1 + imm_i, i2);                    goto incr;
    case 48: /* LW    */ rd = M(rs1 + imm_i, i4);                    goto incr;
    case 32: /* LBU   */ rd = M(rs1 + imm_i, u1);                    goto incr;
    case 24: /* LHU   */ rd = M(rs1 + imm_i, u2);                    goto incr;
    case 62: /* SB    */ M(rs1 + imm_s, i1) = (i1)rs2;               goto incr;
    case 54: /* SH    */ M(rs1 + imm_s, i2) = (i2)rs2;               goto incr;
    case 46: /* SW    */ M(rs1 + imm_s, i4) = (i4)rs2;               goto incr;
    case 58: /* BEQ   */ pc += rs1 == rs2 ? imm_b : 4;               goto setz;
    case 50: /* BNE   */ pc += rs1 != rs2 ? imm_b : 4;               goto setz;
    case 26: /* BLT   */ pc += rs1 <  rs2 ? imm_b : 4;               goto setz;
    case 18: /* BGE   */ pc += rs1 >= rs2 ? imm_b : 4;               goto setz;
    case 10: /* BLTU  */ pc += (u4)rs1 <  (u4)rs2 ? imm_b : 4;       goto setz;
    case  2: /* BGEU  */ pc += (u4)rs1 >= (u4)rs2 ? imm_b : 4;       goto setz;
    case 17: /* JAL   */ rd = PC + 4; pc += imm_j;                   goto setz;
    case  1: /* JALR  */ rd = PC + 4; pc = mem + rs1 + imm_i;        goto setz;
    case 36: /* LUI   */ rd = imm_u;                                 goto incr;
    case 38: /* AUIPC */ rd = imm_u + PC;                            goto incr;
    case 25: /* ECALL */ if (regs[17] == 10) { flag = 0; break; }
    
    default:    fprintf(stderr, "Illegal instruction");     _exit(1);

    incr:       pc += 4;
    setz:       regs[0] = 0;
    }
  } while (flag);                                   // execute the program

  fwrite(regs, sizeof(i4), N_REGS, stdout);         // dump the registers

}