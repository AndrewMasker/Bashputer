# Cartridges

A cartridge is a program stored as text. Each one lives in its own directory:

```text
src/Cartridges/<Name>/hex
```

- [Building a cartridge](#building-a-cartridge)
- [Running a cartridge](#running-a-cartridge)
- [File format](#file-format)
- [Included cartridges](#included-cartridges)

## Building a cartridge

Assemble a source file with the output directory set to the cartridge's directory:

```bash
bash Assembler/assembler.sh Assembler/Examples/Snake.bassm -o src/Cartridges/Snake
```

The `hex` files in the repository are already built, so you only need to do this after changing a program.

## Running a cartridge

Pass the cartridge's directory name to `run.sh`:

```bash
src/run.sh Snake
```

At startup, `computer.sh` copies the cartridge into ROM, and the CPU starts executing at address 0. ROM is 64,000 bytes, so a program must fit within that size to be fully reachable.

A running program can also read and write cartridges through the [loader](memory-map.md#loader). Store commands change the `hex` file on disk.

## File format

A `hex` file is plain text. Each line holds a starting address followed by the bytes stored from that address onward:

```text
0x0000000000000000 0x1F 0x2A 0x14 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x36 0x08 0x38 0x08 0x1F 0x1F
0x0000000000000010 0x67 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x28 0x1F 0x1F 0x06 0x48 0x00 0x00 0x00
```

| Field | Format |
| --- | --- |
| Address | `0x` followed by 16 uppercase hexadecimal digits |
| Byte | `0x` followed by 2 uppercase hexadecimal digits |

Fields are separated by spaces. The assembler writes up to 16 bytes per line. Addresses that do not appear in the file read as `0x00`.

## Included cartridges

| Cartridge | Source | Author | Ends when |
| --- | --- | --- | --- |
| `Fibonacci` | [`Fibonacci.bassm`](../Assembler/Examples/Fibonacci.bassm) | Andrew Masker | It finishes printing |
| `Hanoi` | [`Hanoi.bassm`](../Assembler/Examples/Hanoi.bassm) | Claude Opus 5.5 | It finishes printing |
| `Showcase` | [`Showcase.bassm`](../Assembler/Examples/Showcase.bassm) | Claude Opus 5.5 | You press `q` |
| `Snake` | [`Snake.bassm`](../Assembler/Examples/Snake.bassm) | Andrew Masker | You press `q` |
| `FastSnake` | [`FastSnake.bassm`](../Assembler/Examples/FastSnake.bassm) | Andrew Masker and Claude Opus 5.5 | You press `q` |
| `Pong` | [`Pong.bassm`](../Assembler/Examples/Pong.bassm) | Claude Opus 5.5 | You press `q` |
| `Maze` | [`Maze.bassm`](../Assembler/Examples/Maze.bassm) | Claude Opus 5.5 | You press `Ctrl-C` |
