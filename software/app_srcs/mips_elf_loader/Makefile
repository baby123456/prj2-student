O ?= $(shell pwd)/out

ROOT := $(shell pwd)

OUT := $(O)/mips_elf_loader
OBJS := $(O)/mips_elf_loader.o

CC := $(CROSS_COMPILE)gcc

all: $(OUT)
	@echo "Compiled mips_elf_loader"

$(OUT): $(OBJS)
	$(CC) -o $(OUT) $(OBJS)

$(O)/%.o: $(ROOT)/%.c
	@mkdir -p $(O)
	$(CC) -c -o $@ $<

clean:
	@rm -f $(OUT) $(OBJS)

distclean:
	@rm -rf $(O)



