TEST_DIR = ./tests
TEST_FILE = addlarge
FIND = find $(TEST_DIR) -name $(TEST_FILE).bin

SRC = src/main.s
OBJ = src/main.o

HD = hexdump -ve '4 \"%08x \" \"\n\"'

TEST = .\/$? & 1>1.t 2>2.t \&\& \(diff 1.t \1.res > \/dev\/null \&\& echo \1\
passed! || \(echo \1 failed: ; $(HD) \1.res > r.t ; $(HD) 1.t | paste - r.t\)\)\
|| echo -n \1 failed:' ' ; cat 2.t

default: small

small.exe: $(SRC)
	@ nasm -fbin $(SRC) -o $@

debug.exe: $(SRC)
	@ nasm -felf32 -DDEBUG $(SRC) -o $(OBJ)
	@ ld -N -g -melf_i386 $(OBJ) -o $@

FORCE: ;

.PHONY: small
small: small.exe
	@ wc -c $? | awk '{print $$1, 0x4C, $$1 - 0x4C}'

.PHONY: debug
debug: debug.exe
	@ $(FIND) -exec gdb -tui --args $? {} \;

.PHONY: clean
clean:
	rm -f *.t $(OBJ) *.exe

.PHONY: test
test: small.exe
	@ $(FIND) | sed -nr "s/(.*).bin/$(TEST)/p" | sh ; rm -f *.t

testa: TEST_FILE = *
testa: test
	@ #
