import mmap
from struct import unpack

with open('./a.out', 'rb') as f:
  with mmap.mmap(f.fileno(), 0, prot=mmap.ACCESS_READ) as file:
    ehdr = file[:0x34]
    phdr = file[0x34:0x54]
    start, = unpack('<I', phdr[0x04:0x08])
    len, = unpack('<I', phdr[0x10:0x14])
    program = file[start:start+len]
with open('./a.out', 'wb+') as out:
  out.write(ehdr[:0x20])
  out.write(b'\0\0\0\0')
  out.write(ehdr[0x24:0x2E])
  out.write(b'\0\0\0\0\0\0')
  out.write(phdr)
  out.write(b'\0\0\0\0\0\0\0\0\0\0\0\0')
  out.write(program)