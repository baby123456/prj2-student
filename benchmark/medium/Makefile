CROSS_PREFIX := mips-

CC := $(CROSS_PREFIX)gcc
AS := $(CROSS_PREFIX)as
LD := $(CROSS_PREFIX)ld
OBJDUMP := $(CROSS_PREFIX)objdump
OBJCOPY := $(CROSS_PREFIX)objcopy

EXPORT_CC_PATH := export PATH=$(MIPS_TOOLS_PATH):$$PATH

CFLAGS = -fno-pic -static -fno-strict-aliasing -fno-delayed-branch -fno-builtin \
		-fno-stack-protector -mno-check-zero-division \
		-Wall -Werror -mno-imadd -mno-mad -EL -mips32 -G0
CFLAGS += -I $(shell pwd)/common
ASFLAGS := -EL
LDFLAGS := -EL -N -e start -T user.ld

ROOT := $(shell pwd)
OBJ_DIR := $(ROOT)/obj
BIN := $(ROOT)/bin
RAW := $(ROOT)/raw
SIM := $(ROOT)/sim
DISASSEMBLY := $(ROOT)/disassembly

DIR_OBJS := $(BIN) $(RAW) $(SIM) $(DISASSEMBLY)

TARGET := $(patsubst src/%.c,%,$(wildcard src/*.c))
BINS := $(addprefix $(BIN)/,$(TARGET))

NO_OPT_TARGET := if-else min3 select-sort max
NO_OPT_OBJ_LOC := $(addprefix $(OBJ_DIR)/, $(NO_OPT_TARGET))
NO_OPT_OBJ := $(addsuffix .o, $(NO_OPT_OBJ_LOC))

all: $(BINS)
	@rm -rf $(OBJ_DIR)

$(BIN)/%: common/start.o $(OBJ_DIR)/%.o
	@mkdir -p $(DIR_OBJS)
	@$(EXPORT_CC_PATH) && $(LD) $(LDFLAGS) -o $@ $^
	@$(EXPORT_CC_PATH) && $(OBJDUMP) -DS $@ > $(DISASSEMBLY)/$(patsubst $(BIN)/%,%,$@).S
	@$(EXPORT_CC_PATH) && $(OBJCOPY) -S -O binary \
				-j .text -j .text.startup -j .MIPS.abiflags \
				-j .data -j .rodata \
				-j .bss --set-section-flags .bss=alloc,contents \
				-j .sbss --set-section-flags .sbss=alloc,contents \
				-j .scommon --set-section-flags .scommon=alloc,contents \
				$@ $(RAW)/$(patsubst $(BIN)/%,%,$@).raw
	@xxd -e -c 4 $(RAW)/$(patsubst $(BIN)/%,%,$@).raw | awk -F ":" '{print $$2}' | awk -F " " '{print $$1}' \
				> $(SIM)/$(patsubst $(BIN)/%,%,$@).vh

$(NO_OPT_OBJ): $(OBJ_DIR)/%.o: src/%.c
	@mkdir -p $(OBJ_DIR)
	@$(EXPORT_CC_PATH) && $(CC) -c $(CFLAGS) -o $@ $<

$(OBJ_DIR)/%.o: src/%.c
	@mkdir -p $(OBJ_DIR)
	@$(EXPORT_CC_PATH) && $(CC) -c $(CFLAGS) -O2 -o $@ $<

common/start.o: common/start.S 
	@$(EXPORT_CC_PATH) && $(CC) -c $(CFLAGS) -o $@ $<

clean:
	rm -rf $(DIR_OBJS) common/start.o

