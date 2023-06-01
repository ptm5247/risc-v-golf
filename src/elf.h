/* Standard ELF types.  */

#include <stdint.h>

typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Word;
typedef	int32_t  Elf32_Sword;
typedef uint64_t Elf32_Xword;
typedef	int64_t  Elf32_Sxword;
typedef uint32_t Elf32_Addr;
typedef uint32_t Elf32_Off;

/* The ELF file header.  This appears at the start of every ELF file.  */

#define EI_NIDENT (16)

typedef struct {
  //  ehdr:
  unsigned char	e_ident[EI_NIDENT];   /* Magic number and other info */
  //  db          0x7f, "ELF"            File identification bytes
  //  db          1                      32-bit objects
  //  db          1                      2's complement, little endian
  //  db          1                      Current version
  //  db          0                      UNIX System V ABI
  //  db          0                      EI_ABIVERSION
  //  times 7 db  0                      EI_PAD
  Elf32_Half  e_type;                 /* Object file type */
  //  dw          2                      Executable file
  Elf32_Half  e_machine;              /* Architecture */
  //  dw          3                      Intel 80386
  Elf32_Word  e_version;              /* Object file version */
  //  dd          1                      Current version
  Elf32_Addr  e_entry;                /* Entry point virtual address */
  //  dd          _start
  Elf32_Off   e_phoff;                /* Program header table file offset */
  //  dd          phdr-$$
  Elf32_Off   e_shoff;                /* Section header table file offset */
  //  dd          0                      No section header table
  Elf32_Word  e_flags;                /* Processor-specific flags */
  //  dd          0
  Elf32_Half  e_ehsize;               /* ELF header size in bytes */
  //  dw          ehdrsize
  Elf32_Half  e_phentsize;            /* Program header table entry size */
  //  dw          phdrsize
  Elf32_Half  e_phnum;                /* Program header table entry count */
  //  dw          1
  Elf32_Half  e_shentsize;            /* Section header table entry size */
  //  dw          0
  Elf32_Half  e_shnum;                /* Section header table entry count */
  //  dw          0
  Elf32_Half  e_shstrndx;             /* Section header string table index */
  //  dw          0
} Elf32_Ehdr;
  // ehdrsize equ $-ehdr

/* Program segment header.  */

typedef struct {
  //  phdr:
  Elf32_Word  p_type;                 /* Segment type */
  //  dd          1                      Loadable program segment
  Elf32_Off   p_offset;               /* Segment file offset */
  //  dd          segstart-$$
  Elf32_Addr  p_vaddr;                /* Segment virtual address */
  //  dd          segstart
  Elf32_Addr  p_paddr;                /* Segment physical address */
  //  dd          segstart
  Elf32_Word  p_filesz;               /* Segment size in file */
  //  dd          filesize
  Elf32_Word  p_memsz;                /* Segment size in memory */
  //  dd          filesize
  Elf32_Word  p_flags;                /* Segment flags */
  //  dd          7                      PF_X | PF_W | PF_R
  Elf32_Word  p_align;                /* Segment alignment */
  //  dd          0                      No alignment requirements (same as 1)
} Elf32_Phdr;
  // phdrsize equ $-phdr
  // segstart equ $

  // ...

  // filesize equ $-segstart