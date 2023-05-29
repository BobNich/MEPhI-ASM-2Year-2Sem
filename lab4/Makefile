CC = ld
NASM = nasm
CFLAGS = -static -L /lib/gcc/x86_64-linux-gnu/11
NASMFLAGS = -f elf64 -g -F dwarf
LIBS = -lgcc -lgcc_eh -lc -lm

SOURCE = lab.s
OBJECTS = lab.o
EXECUTABLE = lab.out

.PHONY: all clean

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(CFLAGS) $(OBJECTS) $(LIBS) -o $(EXECUTABLE)

$(OBJECTS): $(SOURCE)
	$(NASM) $(NASMFLAGS) -o $(OBJECTS) $(SOURCE)

clean:
	rm -f $(OBJECTS) $(EXECUTABLE)
