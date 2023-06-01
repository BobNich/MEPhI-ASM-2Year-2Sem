CC = ld
NASM = nasm
CFLAGS = -D_DEBUG
NASMFLAGS = -f elf64 -g -F dwarf
LIBPATH = /lib/gcc/x86_64-linux-gnu/11
OBJPATH = /usr/lib/x86_64-linux-gnu
PREOBJ = ${OBJPATH}/crt1.o ${OBJPATH}/crti.o
POSTOBJ = ${OBJPATH}/crtn.o
LIBS = -lgcc -lgcc_eh -lc -lm

SOURCE = lab.s
OBJECTS = lab.o
EXECUTABLE = lab.out

.PHONY: all clean

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) -static -L $(LIBPATH) $(PREOBJ) $(OBJECTS) $(POSTOBJ) -\( $(LIBS) -\) -o $(EXECUTABLE)

$(OBJECTS): $(SOURCE)
	$(NASM) $(NASMFLAGS) -o $(OBJECTS) $(SOURCE)

clean:
	rm -f $(OBJECTS) $(EXECUTABLE)