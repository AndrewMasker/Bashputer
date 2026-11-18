# Memory Map and Devices

Programs reach memory and every device through a single byte-addressed address space. The layout is defined in `src/Components/bus_interconnect/config.sh`.

- [Address space](#address-space)
- [Screen](#screen)
- [Keyboard](#keyboard)
- [Timer](#timer)
- [Loader](#loader)

## Address space

| Start | End (inclusive) | Start (hex) | End (hex) | Size in bytes | Device | Access |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | 63,999 | `0x000000` | `0x00F9FF` | 64,000 | ROM | Read |
| 64,000 | 191,999 | `0x00FA00` | `0x02EDFF` | 128,000 | [Screen](#screen) | Read, write |
| 192,000 | 255,999 | `0x02EE00` | `0x03E7FF` | 64,000 | [Keyboard](#keyboard) | Read |
| 256,000 | 319,999 | `0x03E800` | `0x04E1FF` | 64,000 | [Timer](#timer) | Read, write |
| 320,000 | 383,999 | `0x04E200` | `0x05DBFF` | 64,000 | [Loader](#loader) | Read, write |
| 384,000 | 1,407,999 | `0x05DC00` | `0x157BFF` | 1,024,000 | RAM | Read, write |
| 1,408,000 | 2,431,999 | `0x157C00` | `0x251BFF` | 1,024,000 | Stack | Read, write |

Execution starts at address 0, and `SP` starts at 1,408,000. Because `SP` points at the last byte written, the first push writes to address 1,408,001.

RAM and the stack are ordinary memory and are contiguous, so programs can use either one for data. Both start out filled with zeros.

| Access | Result |
| --- | --- |
| Read from an address above the stack | `0x00` |
| Write to an address above the stack | Ignored |
| Write to ROM or the keyboard | Ignored |
| Read from an unused register inside a device | `0xFF` |

Because `0x00` is the `nop` opcode, a program that runs off the end of its code does not halt on its own. End programs with `hlt`.

## Screen

Base address: **64,000** (`0xFA00`). The screen draws to your terminal using ANSI escape sequences.

Drawing is buffered. Nothing appears until the program writes to `BLIT`, which lets it draw a whole frame at once.

### Registers

| Offset | Name | Access | Reset value | Description |
| --- | --- | --- | --- | --- |
| 0 | `MODE` | Read, write | 0 | `0` for characters, `1` for half-block pixels |
| 1 | `CMODE` | Read, write | 0 | `0` for palette colors, `1` for 24-bit RGB |
| 2 | `CX` | Read, write | 0 | Cursor column |
| 3 | `CY` | Read, write | 0 | Cursor row |
| 4 | `FIDX` | Read, write | 15 | Foreground palette index |
| 5 | `FR` | Read, write | 255 | Foreground red |
| 6 | `FG` | Read, write | 255 | Foreground green |
| 7 | `FB` | Read, write | 255 | Foreground blue |
| 8 | `BIDX` | Read, write | 16 | Background palette index |
| 9 | `BR` | Read, write | 0 | Background red |
| 10 | `BG` | Read, write | 0 | Background green |
| 11 | `BB` | Read, write | 0 | Background blue |
| 12 | `WIDTH` | Read | 254 | Screen width in cells |
| 13 | `HEIGHT` | Read | 127 | Screen height in cells |
| 14 | `CELL` | Write | | Draws at the cursor |
| 15 | `BLIT` | Write | | Sends all buffered drawing to the terminal |
| 16 | `FILL` | Write | | Clears the screen to the background color |
| 17 | `RESET` | Write | | Restores the reset values and discards buffered drawing |
| 18 | `RD_FIDX` | Read | | Foreground palette index of the cell at the cursor |
| 19 | `RD_FR` | Read | | Foreground red of the cell at the cursor |
| 20 | `RD_FG` | Read | | Foreground green of the cell at the cursor |
| 21 | `RD_FB` | Read | | Foreground blue of the cell at the cursor |
| 22 | `RD_BIDX` | Read | | Background palette index of the cell at the cursor |
| 23 | `RD_BR` | Read | | Background red of the cell at the cursor |
| 24 | `RD_BG` | Read | | Background green of the cell at the cursor |
| 25 | `RD_BB` | Read | | Background blue of the cell at the cursor |

The value written to `BLIT`, `FILL`, or `RESET` does not matter.

### Drawing

- **The cursor does not move on its own.** Set `CX` and `CY` before each write to `CELL`. Values past the edge of the screen are clamped to the last column or row.
- **Character mode:** writing a byte to `CELL` draws that character. Control characters and `0x7F` draw as a space.
- **Pixel mode:** each cell is two pixels stacked vertically, drawn with the `▀` character. The foreground color sets the top pixel and the background color sets the bottom pixel. The value written to `CELL` is ignored.
- **Colors:** palette indices are the standard 256-color terminal palette. The foreground and background registers apply to later writes to `CELL`.

### Reading cells back

The read-back registers return the colors last drawn at the cursor, which lets a program check a cell without keeping its own copy of the screen.

A cell only remembers colors in the mode it was drawn with. For example, the RGB registers of a cell drawn with a palette color return the default. Cells that have not been drawn since the last `FILL` or `RESET` return that operation's background color from both the foreground and background registers.

## Keyboard

Base address: **192,000** (`0x2EE00`). Keys are buffered until the program reads them. There are no interrupts, so programs must poll.

| Offset | Name | Description |
| --- | --- | --- |
| 0 | `STATUS` | `1` if a key is waiting, otherwise `0` |
| 1 | `DATA` | Removes and returns the oldest byte, or `0` if the buffer is empty |
| 2 | `CLEAR` | Reading this register empties the buffer and returns `0` |

All three registers are read-only. Input is delivered one byte at a time, so a key that sends several bytes takes several reads. The up arrow, for example, arrives as `0x1B`, `0x5B`, `0x41`.

## Timer

Base address: **256,000** (`0x3E800`). The timer counts milliseconds.

| Offset | Name | Access | Description |
| --- | --- | --- | --- |
| 0 | `RESET` | Write | Restarts the count from zero |
| 1 | `TRIGGER` | Write | Copies the current count into `TICKS` |
| 2 to 9 | `TICKS` | Read | The copied count as a little-endian 64-bit value |

The value written to `RESET` or `TRIGGER` does not matter. `TICKS` only changes when `TRIGGER` is written, so all eight bytes come from the same moment. This program measures an interval in milliseconds:

```bassm
def TIMER   = 256000
def RESET   = ( $TIMER + 0 )
def TRIGGER = ( $TIMER + 1 )
def TICKS   = ( $TIMER + 2 )

liw r1 , $RESET
stb r0 , r1             # start timing

# ... the code being measured ...

liw r1 , $TRIGGER
stb r0 , r1             # capture the count
liw r1 , $TICKS
ldw r1 , r2             # r2 = elapsed milliseconds
hlt
```

## Loader

Base address: **320,000** (`0x4E200`). The loader copies data between cartridges and memory while the CPU keeps running. Changes written to a cartridge are saved to its file on disk.

| Offset | Name | Access | Description |
| --- | --- | --- | --- |
| 0 | `CART` | Write | Cartridge number |
| 1 | `COMMAND` | Write | Starts a command |
| 2 | `BUSY` | Read | `1` while a command is running, otherwise `0` |
| 3 | `RESULT` | Read | Result of the last command |
| 4 to 11 | `START` | Write | First source address, little-endian |
| 12 to 19 | `END` | Write | Last source address (inclusive), little-endian |
| 20 to 27 | `OFFSET` | Write | First destination address, little-endian |

### Commands

Set `CART`, `START`, `END`, and `OFFSET`, then write the command number to `COMMAND`.

| Command | Name | `START` and `END` refer to | `OFFSET` refers to | Effect |
| --- | --- | --- | --- | --- |
| 0 | Load | Cartridge addresses | Memory address | Copies from the cartridge to memory |
| 1 | Store | Memory addresses | Cartridge address | Copies from memory to the cartridge file |
| 2 | Clear cartridge | Length only | Cartridge address | Zeros a range of the cartridge file |
| 3 | Clear memory | Length only | Memory address | Zeros a range of memory |

### Results

| Value | Meaning |
| --- | --- |
| 0 | Success |
| 1 | Command in progress |
| 2 | `END` is less than `START` |
| 3 | No cartridge has that number |
| 4 | Unknown command |
| 5 | The cartridge's file is missing |
| 6 | A command was issued while the loader was busy |

### Cartridge numbers

The numbers are assigned in `src/Components/loader/cartridges.sh`:

| Number | Cartridge |
| --- | --- |
| `0x00` | `Fibonacci` |
| `0x02` | `FastSnake` |
| `0x03` | `Hanoi` |
| `0x04` | `Maze` |
| `0x05` | `Pong` |
| `0x06` | `Showcase` |
| `0x07` | `Snake` |

To make another cartridge available to the loader, add it to that file. Any cartridge in `src/Cartridges/` can be started directly with `run.sh`, whether or not it has a number.
