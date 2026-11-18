# Instruction Set

Bashputer has a 64-bit, little-endian instruction set with 66 instructions.

- [Registers](#registers)
- [Instruction encoding](#instruction-encoding)
- [Reading the tables](#reading-the-tables)
- [Control](#control)
- [Arithmetic](#arithmetic)
- [Logic](#logic)
- [Shifts](#shifts)
- [Loads and stores](#loads-and-stores)
- [Immediates](#immediates)
- [Comparisons](#comparisons)
- [Jumps and branches](#jumps-and-branches)
- [Stack](#stack)
- [Calls](#calls)
- [Register moves](#register-moves)
- [Random numbers](#random-numbers)
- [Opcode map](#opcode-map)

## Registers

| Register | Width | Value at reset | Purpose |
| --- | --- | --- | --- |
| `r0` to `r255` | 64 bits | `0` | General purpose. `r0` is an ordinary register. |
| `PC` | 64 bits | `0` | Program counter |
| `SP` | 64 bits | `0x157C00` | Stack pointer. Points at the last byte written. |
| `JO` | 64 bits | `0` | Jump origin, added to every jump, branch, and call target |
| `RNG` | 64 bits | `0x9E3779B97F4A7C15` | Random number generator state |

## Instruction encoding

An instruction is a one-byte opcode followed by its operands in order. Register operands take one byte. Immediate operands take 1, 2, 4, or 8 bytes and are stored little-endian.

For example, `liq r3 , 0x1234` encodes as `0x1D 0x03 0x34 0x12`.

Memory is byte-addressed, and multi-byte values do not need to be aligned.

| Size name | Bytes | Instruction suffix |
| --- | --- | --- |
| Byte | 1 | `B` |
| Quarter | 2 | `Q` |
| Half | 4 | `H` |
| Word | 8 | `W` |

## Reading the tables

- `ra`, `rb`, and `rc` are source registers.
- `rd` is the destination register. **The destination comes last.**
- `imm8`, `imm16`, `imm32`, and `imm64` are immediate values of that many bits.
- `mem8[x]` to `mem64[x]` mean the value of that width at address `x`.
- **Bytes** is the encoded length of the instruction.
- **Cycles** is the number of bus accesses, and so the number of clock cycles the instruction takes.

## Control

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `nop` | `0x00` | 1 | 1 | Does nothing |
| `hlt` | `0x01` | 1 | 1 | Halts the CPU, which stops the computer |

Any opcode without an instruction also halts the CPU.

## Arithmetic

All arithmetic wraps around at 64 bits.

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `add ra , rb , rd` | `0x02` | 4 | 4 | `rd = ra + rb` |
| `sub ra , rb , rd` | `0x03` | 4 | 4 | `rd = ra - rb` |
| `inc rd` | `0x04` | 2 | 2 | `rd = rd + 1` |
| `dec rd` | `0x05` | 2 | 2 | `rd = rd - 1` |
| `neg ra , rd` | `0x07` | 3 | 3 | `rd = -ra` |
| `mul ra , rb , rd` | `0x08` | 4 | 4 | `rd = ra * rb` |
| `div ra , rb , rd` | `0x09` | 4 | 4 | `rd = ra / rb`, signed |
| `rem ra , rb , rd` | `0x0A` | 4 | 4 | `rd = ra % rb`, signed |

`div` rounds toward zero, and the result of `rem` takes the sign of `ra`. For example, `-7 / 2` is `-3` and `-7 % 2` is `-1`.

| Special case | `div` result | `rem` result |
| --- | --- | --- |
| `rb` is 0 and `ra` is zero or positive | `0x7FFFFFFFFFFFFFFF` | `ra` |
| `rb` is 0 and `ra` is negative | `0x8000000000000000` | `ra` |
| `ra` is `0x8000000000000000` and `rb` is -1 | `0x8000000000000000` | `0` |

## Logic

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `and ra , rb , rd` | `0x0B` | 4 | 4 | `rd = ra & rb` |
| `or ra , rb , rd` | `0x0C` | 4 | 4 | `rd = ra \| rb` |
| `xor ra , rb , rd` | `0x0D` | 4 | 4 | `rd = ra ^ rb` |
| `not ra , rd` | `0x0E` | 3 | 3 | `rd = ~ra` |

## Shifts

The shift amount in `rb` is treated as an unsigned value.

| Instruction | Opcode | Bytes | Cycles | Effect | If `rb` is 64 or more |
| --- | --- | --- | --- | --- | --- |
| `lsr ra , rb , rd` | `0x10` | 4 | 4 | Logical shift right, filling with zeros | `rd = 0` |
| `asr ra , rb , rd` | `0x11` | 4 | 4 | Arithmetic shift right, copying the sign bit | Every bit of `rd` equals the sign bit of `ra` |
| `shl ra , rb , rd` | `0x12` | 4 | 4 | Shift left | `rd = 0` |

## Loads and stores

Addresses are absolute: `JO` does not apply. Loads zero-extend their result to 64 bits. Stores write the low bytes of the source register.

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `ldb ra , rd` | `0x14` | 3 | 4 | `rd = mem8[ra]` |
| `ldq ra , rd` | `0x15` | 3 | 5 | `rd = mem16[ra]` |
| `ldh ra , rd` | `0x16` | 3 | 7 | `rd = mem32[ra]` |
| `ldw ra , rd` | `0x17` | 3 | 11 | `rd = mem64[ra]` |
| `stb ra , rb` | `0x18` | 3 | 4 | `mem8[rb] = ra` |
| `stq ra , rb` | `0x19` | 3 | 5 | `mem16[rb] = ra` |
| `sth ra , rb` | `0x1A` | 3 | 7 | `mem32[rb] = ra` |
| `stw ra , rb` | `0x1B` | 3 | 11 | `mem64[rb] = ra` |

## Immediates

Each instruction zero-extends its immediate to 64 bits.

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `lib rd , imm8` | `0x1C` | 3 | 3 | `rd = imm8` |
| `liq rd , imm16` | `0x1D` | 4 | 4 | `rd = imm16` |
| `lih rd , imm32` | `0x1E` | 6 | 6 | `rd = imm32` |
| `liw rd , imm64` | `0x1F` | 10 | 10 | `rd = imm64` |

## Comparisons

Each comparison sets `rd` to `1` if the condition is true and `0` otherwise. An `S` suffix means the comparison is signed. Comparisons without it are unsigned.

| Instruction | Opcode | Bytes | Cycles | Condition |
| --- | --- | --- | --- | --- |
| `eq ra , rb , rd` | `0x20` | 4 | 4 | `ra == rb` |
| `neq ra , rb , rd` | `0x21` | 4 | 4 | `ra != rb` |
| `lt ra , rb , rd` | `0x22` | 4 | 4 | `ra < rb`, unsigned |
| `lts ra , rb , rd` | `0x23` | 4 | 4 | `ra < rb`, signed |
| `le ra , rb , rd` | `0x24` | 4 | 4 | `ra <= rb`, unsigned |
| `les ra , rb , rd` | `0x25` | 4 | 4 | `ra <= rb`, signed |
| `gt ra , rb , rd` | `0x42` | 4 | 4 | `ra > rb`, unsigned |
| `gts ra , rb , rd` | `0x43` | 4 | 4 | `ra > rb`, signed |
| `ge ra , rb , rd` | `0x44` | 4 | 4 | `ra >= rb`, unsigned |
| `ges ra , rb , rd` | `0x45` | 4 | 4 | `ra >= rb`, signed |

## Jumps and branches

Every target is relative to the jump origin, so the CPU jumps to `target + JO`. A branch costs the same whether or not it is taken.

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `jmp ra` | `0x28` | 2 | 2 | Jump to `ra + JO` |
| `bz ra , rb` | `0x26` | 3 | 3 | If `ra == 0`, jump to `rb + JO` |
| `bnz ra , rb` | `0x27` | 3 | 3 | If `ra != 0`, jump to `rb + JO` |
| `jmpi imm64` | `0x39` | 9 | 9 | Jump to `imm64 + JO` |
| `bzi ra , imm64` | `0x3A` | 10 | 10 | If `ra == 0`, jump to `imm64 + JO` |
| `bnzi ra , imm64` | `0x3B` | 10 | 10 | If `ra != 0`, jump to `imm64 + JO` |

The register forms are much cheaper. Hot loops can load their branch targets into registers once and reuse them.

## Stack

The stack grows upward, and `SP` points at the last byte written. A push writes starting at `SP + 1`, and a pop reads the value that ends at `SP`.

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `pshb ra` | `0x29` | 2 | 3 | Push the low 8 bits of `ra`, then `SP = SP + 1` |
| `pshq ra` | `0x2A` | 2 | 4 | Push the low 16 bits of `ra`, then `SP = SP + 2` |
| `pshh ra` | `0x2B` | 2 | 6 | Push the low 32 bits of `ra`, then `SP = SP + 4` |
| `pshw ra` | `0x2C` | 2 | 10 | Push all 64 bits of `ra`, then `SP = SP + 8` |
| `popb rd` | `0x2E` | 2 | 3 | Pop 8 bits into `rd`, then `SP = SP - 1` |
| `popq rd` | `0x2F` | 2 | 4 | Pop 16 bits into `rd`, then `SP = SP - 2` |
| `poph rd` | `0x30` | 2 | 6 | Pop 32 bits into `rd`, then `SP = SP - 4` |
| `popw rd` | `0x31` | 2 | 10 | Pop 64 bits into `rd`, then `SP = SP - 8` |
| `ssp ra` | `0x3C` | 2 | 2 | `SP = ra` |
| `sspi imm64` | `0x3D` | 9 | 9 | `SP = imm64` |
| `xsp rd` | `0x3E` | 2 | 2 | Swap `SP` and `rd` |

Pops zero-extend their result. `ssp`, `sspi`, and `xsp` use absolute addresses, which makes it possible to switch between several stacks.

## Calls

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `cal ra` | `0x32` | 2 | 10 | Push the return address, then jump to `ra + JO` |
| `cali imm64` | `0x33` | 9 | 17 | Push the return address, then jump to `imm64 + JO` |
| `ret` | `0x34` | 1 | 9 | Pop the return address and jump to it |

Return addresses are 8 bytes on the stack. They are absolute, so `ret` does not add `JO`.

## Register moves

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `mov ra , rd` | `0x35` | 3 | 3 | `rd = ra` |
| `pc rd` | `0x36` | 2 | 2 | `rd` = the address of this `pc` instruction |
| `sp rd` | `0x37` | 2 | 2 | `rd = SP` |
| `sjo ra` | `0x38` | 2 | 2 | `JO = ra` |

`pc` and `sjo` together make position-independent code possible. See [label origins](assembly-language.md#label-origins).

## Random numbers

| Instruction | Opcode | Bytes | Cycles | Effect |
| --- | --- | --- | --- | --- |
| `rnd rd` | `0x3F` | 2 | 2 | `rd` = the next pseudorandom value |
| `seed ra` | `0x40` | 2 | 2 | `RNG = ra`. A seed of `0` restores the reset value. |
| `ent rd` | `0x41` | 2 | 2 | `rd` = a random value from the host |

`rnd` is an xorshift generator, so the same seed always gives the same sequence. To get a different sequence on every run, seed it from `ent`:

```bassm
ent r1
seed r1
```

## Opcode map

Blank entries are invalid opcodes, which halt the CPU. Opcodes from `0x46` to `0xFF` are also invalid.

| | `x0` | `x1` | `x2` | `x3` | `x4` | `x5` | `x6` | `x7` | `x8` | `x9` | `xA` | `xB` | `xC` | `xD` | `xE` | `xF` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `0x` | NOP | HLT | ADD | SUB | INC | DEC | | NEG | MUL | DIV | REM | AND | OR | XOR | NOT | |
| `1x` | LSR | ASR | SHL | | LDB | LDQ | LDH | LDW | STB | STQ | STH | STW | LIB | LIQ | LIH | LIW |
| `2x` | EQ | NEQ | LT | LTS | LE | LES | BZ | BNZ | JMP | PSHB | PSHQ | PSHH | PSHW | | POPB | POPQ |
| `3x` | POPH | POPW | CAL | CALI | RET | MOV | PC | SP | SJO | JMPI | BZI | BNZI | SSP | SSPI | XSP | RND |
| `4x` | SEED | ENT | GT | GTS | GE | GES | | | | | | | | | | |
