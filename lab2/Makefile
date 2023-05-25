AS = nasm
LD = ld

ASFLAGS = -g -f elf64
LDFLAGS = -static

SRCS = lab.s
OBJS = $(SRCS:.s=.o)

MODE=1
DEF1=UPWARD
DEF2=BACKWARD

EXE = lab

all: $(SRCS) $(EXE)

clean:
	rm -rf $(EXE) $(OBJS)

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@ 

.s.o:
	$(AS) $(ASFLAGS) $< -o $@ -D$(DEF$(MODE))
