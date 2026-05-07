BIN_DIR := bin

VASM_DIR := vasm
VASM_REL := http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
VASM := vasm6502_std
VOBJDUMP := vobjdump

TARGET_VASM := $(BIN_DIR)/$(VASM)
VASM_OUT := $(VASM_DIR)/$(VASM)
TARGET_VOBJDUMP := $(BIN_DIR)/$(VOBJDUMP)
VOBJDUMP_OUT := $(VASM_DIR)/$(VOBJDUMP)

TARGETS := $(TARGET_VASM) $(TARGET_VLINK) $(TARGET_VOBJDUMP) 

tools: $(TARGETS)

all: tools

$(VASM_DIR):
	wget -O - $(VASM_REL) | tar -xz

$(VLINK_DIR):
	wget -O - $(VLINK_REL) | tar -xz

$(TARGET_VLINK): $(VLINK_OUT) $(BIN_DIR)
	cp $(VLINK_OUT) $(TARGET_VLINK)

$(TARGET_VASM): $(VASM_OUT) $(BIN_DIR)
	cp $(VASM_OUT) $(TARGET_VASM)

$(TARGET_VOBJDUMP): $(VASM_OUT)
	cp $(VOBJDUMP_OUT) $(TARGET_VOBJDUMP)

$(VASM_OUT): $(VASM_DIR)
	$(MAKE) -C $(VASM_DIR) CPU=6502 SYNTAX=std
	
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean: clean_bin clean_vasm 

clean_bin:
	rm -rf $(TARGET_VASM) $(TARGET_VOBJDUMP) 

clean_vasm:
	rm -rf $(VASM_DIR)

.PHONY: all clean tools
