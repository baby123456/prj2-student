CROSS_PREFIX := mips-

CC := $(CROSS_PREFIX)gcc
LD := $(CROSS_PREFIX)ld
OBJDUMP := $(CROSS_PREFIX)objdump
OBJCOPY := $(CROSS_PREFIX)objcopy

EXPORT_CC_PATH := export PATH=$(MIPS_TOOLS_PATH):$$PATH

CFLAGS := -fno-pic -static -fno-strict-aliasing -fno-delayed-branch -fno-builtin \
		 -fno-stack-protector -mno-check-zero-division \
		 -Wall -Werror -mno-imadd -mno-mad -EL -mips32 -G0
LDFLAGS := -EL -N -e start -T user.ld

ROOT := $(shell pwd)
OBJ_DIR := $(ROOT)/obj
BIN := $(ROOT)/bin
RAW := $(ROOT)/raw
SIM := $(ROOT)/sim
DISASSEMBLY := $(ROOT)/disassembly

DIR_OBJS := $(BIN) $(RAW) $(SIM) $(DISASSEMBLY) 

TARGET := memcpy
BINS := $(addprefix $(BIN)/,$(TARGET))

all: $(BINS)
	@rm -rf $(OBJ_DIR)

$(BIN)/%: $(OBJ_DIR)/%.o
	@mkdir -p $(DIR_OBJS)
	@$(EXPORT_CC_PATH) && $(LD) $(LDFLAGS) -o $@ $^
	@$(EXPORT_CC_PATH) && $(OBJDUMP) -j .text -DS $@ > $(DISASSEMBLY)/$(patsubst $(BIN)/%,%,$@).S
	@$(EXPORT_CC_PATH) && $(OBJCOPY) -S -O binary -j .text -j .data $@ $(RAW)/$(patsubst $(BIN)/%,%,$@).raw
	@xxd -e -c 4 $(RAW)/$(patsubst $(BIN)/%,%,$@).raw | awk -F ":" '{print $$2}' | awk -F " " '{print $$1}' \
				> $(SIM)/$(patsubst $(BIN)/%,%,$@).vh

$(OBJ_DIR)/%.o: %.S
	@mkdir -p $(OBJ_DIR)
	@$(EXPORT_CC_PATH) && $(CC) -c $(CFLAGS) -o $@ $<

clean:
	rm -rf $(DIR_OBJS)

