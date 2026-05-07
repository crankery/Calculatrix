#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <sys/select.h>

#include "MCS6502.h"

#define RAM_START 0x0000
#define RAM_END 0x07FF

#define DISPLAY_LATCH 0x0800
#define LED_LATCH 0x0801
#define KEY_LATCH 0x0802
#define KEY_BUFFER 0x0803

#define ROM_START 0x1000
#define ROM_END 0x1FFF

uint8_t memory[8192];

uint8_t displayLatch;
uint8_t ledLatch;
uint8_t keyLatch;

char keybuf[16];

const char keyColumns[8][8] =
    {
        {'7', '4', '1', 's', 0, 0, 0, 0},
        {'8', '5', '2', '0', 0, 0, 0, 0},
        {'9', '6', '3', '.', 0, 0, 0, 0},
        {'/', '*', '-', '+', 0, 0, 0, 0},
        {'c', 8, 0, '=', 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0}};

static struct termios original_termios;

void reset_terminal_mode(void)
{
    tcsetattr(STDIN_FILENO, TCSANOW, &original_termios);
}

void set_conio_terminal_mode(void)
{
    struct termios new_termios;

    tcgetattr(STDIN_FILENO, &original_termios);
    new_termios = original_termios;

    /* raw-ish mode */
    new_termios.c_lflag &= ~(ICANON | ECHO);

    tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);

    atexit(reset_terminal_mode);
}

int kbhit(void)
{
    struct timeval tv = {0L, 0L};
    fd_set fds;

    FD_ZERO(&fds);
    FD_SET(STDIN_FILENO, &fds);

    return select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv);
}

int getch(void)
{
    unsigned char c;

    if (read(STDIN_FILENO, &c, 1) < 0)
        return 0;

    return c;
}

int selected_column(uint8_t value)
{
    for (int i = 0; i < 8; i++)
    {
        if ((value & (1 << i)) == 0)
            return i;
    }

    return -1; // no column selected
}

char nextBufferedKey()
{
    if (strlen(keybuf))
    {
        char c = keybuf[0];
        memmove(keybuf, keybuf + 1, strlen(keybuf));

        return c;
    }

    return 0xff; // no key pressed
}

uint8_t readKeypad()
{
    static char scankey = 0xff;
    uint8_t result = 0xff; // no key pressed

    int col = selected_column(keyLatch);
    if (col != -1)
    {
        if (col == 0)
        {
            scankey = nextBufferedKey();
        }

        for (int r = 0; r < 8; r++)
        {
            if (keyColumns[col][r] == scankey)
            {
                // clear the bit for the key being scanned
                result &= ~(1 << r);
            }
        }

        return result;
    }

    return result;
}

uint8_t read8(uint16_t addr, void *readWriteContext)
{
    uint16_t addr8k = addr & 0x1fff;

    if ((addr8k >= RAM_START && addr8k <= RAM_END) ||
        (addr8k >= ROM_START && addr8k <= ROM_END))
    {
        // printf("read @ $%04x: %02x\n", addr, memory[addr8k]);
        return memory[addr8k];
    }
    else if (addr8k >= KEY_BUFFER)
    {
        return readKeypad();
    }

    return 0x0;
}

void write8(uint16_t addr, uint8_t value, void *readWriteContext)
{
    uint16_t addr8k = addr & 0x1fff;

    if (addr8k >= RAM_START && addr8k <= RAM_END)
    {
        memory[addr8k] = value;
    }
    else if (addr8k == DISPLAY_LATCH)
    {
        printf("DISPLAY<-%02x\n", value);
    }
    else if (addr8k == LED_LATCH)
    {
        printf("LED<-%02x\n", value);
    }
    else if (addr8k == KEY_LATCH)
    {
        printf("KEY<-%02x\n", value);
    }
}

bool load_rom(char *path)
{
    FILE *fp;
    size_t rom_size;
    size_t rom_max = ROM_END - ROM_START + 1;

    fp = fopen(path, "rb");
    if (fp == NULL)
    {
        perror("fopen");
        return false;
    }

    fseek(fp, 0, SEEK_END);
    rom_size = ftell(fp);
    rewind(fp);

    if (rom_size > rom_max)
    {
        fprintf(stderr,
                "ROM too large (%zu bytes, max %zu)\n",
                rom_size,
                rom_max);

        fclose(fp);
        return false;
    }

    if (fread(&memory[ROM_START], 1, rom_size, fp) != rom_size)
    {
        fprintf(stderr, "Failed to read ROM\n");
        fclose(fp);
        return false;
    }

    fclose(fp);

    printf("Loaded %zu bytes at $%04X\n",
           rom_size,
           ROM_START);

    return true;
}

void dump_state()
{
    FILE *fp = fopen("dump.bin", "wb");

    fwrite(&memory, sizeof(memory), 1, fp);

    fclose(fp);
}

void handleKeyboardInput()
{
    if (kbhit())
    {
        char c = getch();

        // only attempt to buffer the key if there's room and it's a sensible value
        if (c > 0 && strlen(keybuf) < sizeof(keybuf) - 1)
        {
            snprintf(keybuf, sizeof(keybuf), "%s%c", keybuf, c);
        }
    }
}

int main(int argc, char **argv)
{
    memset(keybuf, 0, sizeof(keybuf));

    set_conio_terminal_mode();

    MCS6502ExecutionContext context;

    if (argc > 1)
    {
        if (!load_rom(argv[1]))
        {
            return 1;
        }
    }
    else
    {
        printf("missing rom\n");
        return 1;
    }

    printf("initilizing 6502\n");
    MCS6502Init(&context, read8, write8, NULL);

    printf("resetting 6502\n");
    MCS6502Reset(&context);

    while (context.pc != 0x1ff0)
    {
        handleKeyboardInput();

        // updateDisplay();

        MCS6502ExecNext(&context);
    }

    dump_state();

    return 0;
}
