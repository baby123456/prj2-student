O ?= $(shell pwd)/out

ROOT := $(shell pwd)

OUT := $(O)/xvc_server
OBJS := $(addprefix $(O)/, xvcserver.o xvc_io.o)

CC := $(CROSS_COMPILE)gcc

all: $(OUT)
	@echo "Compiled xvc_server"

$(OUT): $(OBJS)
	$(CC) -o $(OUT) $(OBJS)

$(O)/%.o: $(ROOT)/%.c
	@mkdir -p $(O)
	$(CC) -c -o $@ $<

clean:
	@rm -f $(OUT) $(OBJS)

distclean:
	@rm -rf $(O)



