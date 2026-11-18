# Architecture

Bashputer models a computer as a set of independent Bash processes. Each hardware component is one process, and components only communicate by exchanging text messages.

- [Startup](#startup)
- [Components](#components)
- [The clock cycle](#the-clock-cycle)
- [Bus requests](#bus-requests)
- [Inside the CPU](#inside-the-cpu)
- [Shutdown](#shutdown)
- [Error handling](#error-handling)
- [Adding a component](#adding-a-component)

## Startup

Running `src/run.sh <Cartridge>` goes through these steps:

1. `run.sh` saves the terminal settings and starts `Computer/computer.sh` inside a [bubblewrap](https://github.com/containers/bubblewrap) sandbox.
2. `computer.sh` switches the terminal to unbuffered input with echo turned off.
3. It creates an input and an output named pipe for every component in `Computer/config.sh`, then starts each component with those pipes as its stdin and stdout.
4. It sends each component a `set_name` message.
5. It copies the cartridge into ROM.
6. It runs the clock loop until the computer halts or is interrupted.

The sandbox has no network access. The host filesystem is read-only except for the cartridge directories, which stay writable so that programs can save data through the [loader](memory-map.md#loader).

## Components

| Component | Script | Clocked | Role |
| --- | --- | --- | --- |
| `cpu` | `Components/cpu/cpu.sh` | Yes | Fetches and executes instructions |
| `loader` | `Components/loader/loader.sh` | Yes | Copies data between cartridges and memory |
| `clock` | `Components/clock/clock.sh` | No | Paces the computer |
| `bus_interconnect` | `Components/bus_interconnect/bus_interconnect.sh` | No | Decodes addresses and enforces permissions |
| `rom` | `Components/ram/ram.sh` | No | Holds the program |
| `ram` | `Components/ram/ram.sh` | No | General-purpose memory |
| `stack` | `Components/ram/ram.sh` | No | Stack memory |
| `screen` | `Components/screen/screen.sh` | No | Draws to the terminal |
| `keyboard` | `Components/keyboard/keyboard.sh` | No | Buffers key presses |
| `timer` | `Components/timer/timer.sh` | No | Counts milliseconds |

ROM, RAM, and the stack are three instances of the same script. Each stores bytes in a sparse associative array, so unused memory takes no space and reads as `0x00`. ROM is only read-only from the bus's point of view: `computer.sh` writes the cartridge directly into it at startup.

`computer.sh` is the hub. Each component has a single connection to it, and components never talk to each other directly, so every message passes through `computer.sh`.

The components fall into three groups:

- **Clocked bus masters:** the CPU and the loader receive clock pulses and can start memory requests.
- **Support components:** the clock paces the computer, and the bus interconnect decides where each memory request goes.
- **Memory-mapped devices:** ROM, RAM, the stack, the screen, the keyboard, and the timer respond to memory requests.

The loader belongs to two of these groups. It is a clocked bus master, and its registers are also mapped into the address space.

Messages are single lines of space-separated words, and the first word is the message type. [`src/message_protocol.md`](../src/message_protocol.md) lists the message formats.

## The clock cycle

Each pass through the main loop in `computer.sh` is one clock cycle:

1. Send `wait` to the clock and block until it replies `clock`.
2. Send `clock` to the CPU, then handle its messages until it replies `tick`.
3. Send `clock` to the loader, then handle its messages until it replies `tick`.

The clock's period is set by `PERIOD_US` in `Components/clock/config.sh`. The default of 1 µs means the computer runs as fast as the host allows.

## Bus requests

A clocked component reads or writes memory by printing a `load` or `store` message. `computer.sh` asks the bus interconnect where the request should go, forwards it, and returns any data.

A load of the value `0x2A` from RAM at global address `0x5DC10` takes these steps:

1. The CPU sends `load 0x000000000005DC10` to `computer.sh`.
2. `computer.sh` forwards the same message to the bus interconnect.
3. The bus sees that the address belongs to RAM and replies `ram load 0x0000000000000010`.
4. `computer.sh` sends `load 0x0000000000000010` to RAM.
5. RAM replies `data 0x2A`.
6. `computer.sh` sends `data 0x2A` to the CPU.

In step 3, the bus subtracts the start of the device's address range, so each device only sees addresses relative to itself.

A store follows the same path. The device replies `done`, and the bus sends its own `done` once it has forwarded the request. The CPU does not wait for a reply to a store.

The bus answers some requests itself instead of forwarding them:

| Request | Bus response |
| --- | --- |
| Load from an unmapped address | `data 0x00` |
| Load from a device without read permission | `data 0xFF` |
| Store to an unmapped address | `done`, and the write is dropped |
| Store to a device without write permission | `done`, and the write is dropped |

## Inside the CPU

The CPU is a nested state machine. The `PROC_STATE` array holds one state per nesting level, so an instruction handler can call a helper such as `load_Word`, which calls `load_Half`, and so on down to `load_Byte`. Each helper records its progress and reports back to its parent through the level above it.

| File | Contents |
| --- | --- |
| `cpu.sh` | Reset sequence, fetch loop, and message handling |
| `cu.sh` | One `parse_*_OPCODE` handler per instruction, and the opcode dispatch table |
| `alu.sh` | Arithmetic, logic, shift, and comparison operations |
| `utils.sh` | Multi-byte load and store helpers |
| `config.sh` | Reset values of `PC`, `SP`, `JO`, and the random number generator |

A clock cycle ends when the CPU makes a bus access. On each `clock` message, the CPU runs its state machine until it has issued one `load` or `store`, so internal work such as an addition costs no extra cycles. The cost of an instruction is therefore the number of bytes it occupies plus the number of bytes it reads or writes. The [instruction set](instruction-set.md) lists the cost of each one.

## Shutdown

The computer stops in one of two ways:

- **Halt:** after a `hlt` or an invalid opcode, the CPU prints `cpu halted` on its next clock. `computer.sh` then ends the main loop.
- **Interrupt:** pressing `Ctrl-C` ends the main loop. Pressing it a second time exits immediately.

`computer.sh` then sends `shutdown` to every component, waits for them to exit, and removes the named pipes. The terminal settings are restored and the cursor is shown again.

## Error handling

Bashputer separates faults in the simulator from faults in the simulated program.

**Simulator faults crash immediately.** Malformed messages, unexpected states, and failed commands call `die` in `src/errors.sh`, which prints the component name, the error, and a call stack to stderr, then exits with status 1. The CPU also prints its registers. If a component exits, `computer.sh` reports the crash and stops the computer.

**Program faults behave as they would on real hardware.** None of these stop the simulator with an error:

| Program behavior | Result |
| --- | --- |
| Invalid opcode | The CPU halts |
| Division by zero | Returns a defined value, as described in the [instruction set](instruction-set.md#arithmetic) |
| Access to an unmapped address | Reads `0x00`, and writes are ignored |
| Write to read-only memory | Ignored |
| Read from an unmapped device register | Returns `0xFF` |

## Adding a component

1. Create a script in `src/Components/<name>/` that reads messages from stdin in a loop. It must handle `shutdown` and `set_name`.
2. Answer each `load <addr>` with `data <byte>`, and each `store <addr> <byte>` with `done`.
3. Add it to `COMPONENTS` in `src/Computer/config.sh`.
4. To map it into memory, add its name, address range, and permissions to `src/Components/bus_interconnect/config.sh`.
5. If it needs a clock, add it to `CLOCKABLE` in `src/Computer/config.sh`, and reply `tick` to every `clock` message.
