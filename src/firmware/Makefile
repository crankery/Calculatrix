ASM = ../tools/bin/vasm6502_std

ASMFLAGS = \
	-Fbin \
	-L firmware.lst \
	-x

TARGET = firmware.bin
SRC = calc.s

all: $(TARGET)

$(TARGET): $(SRC)
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -f $(TARGET) firmware.lst