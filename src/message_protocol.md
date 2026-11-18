# Message Protocol
This file documents the message protocols used by every component shipped with the repo.

Messages are used to pipe the components together; they are not something that the virtual components can see or interact with.

A message is a single line containing a space separated list of words representing the message type and data sent within it. The first word within a message specifies its type. You can think of a message's type as specifying which pins the component is outputting the data onto.

A message out goes via STDOUT and a message in comes via STDIN. Components never message each other directly. Every message goes to `computer.sh`, which routes it to its destination.

## General
**Value Formats**
<dd>

addresses : All addresses must be in the format `0x%016X`.

bytes : All bytes must be in the format `0x%02X`.

</dd>

**Component Addresses**
<dd>

Global addresses sent from a clocked component go to the bus interconnect. There they are sent to each memory mapped component based on the memory layout in the bus interconnect's `config.sh` file. The `ADDR_LOW` of the component is subtracted from the global address to make a component relative address for the component.

</dd>

**Messages and Responses**
<dd>

Some messages are special and get a response back. That response may contain information or may just indicate that the command initiated by the message has finished. These are the messages that allow data to flow across the computer and allow the computer to tick forward.

"clock" &rarr; "tick" : Indicates a clock pulse to a clockable component. The component may send other messages before its response. The response indicates that the component is done with that cycle.

"load `<addr>`" &rarr; "data `<byte>`" : Indicates a load from an address. The response indicates the data found at that address.

"store `<addr>` `<byte>`" &rarr; "done" : Indicates a store of a byte into an address. The response indicates that the store is done.

</dd>

**Bus Masters**
<dd>

The clocked components are the bus masters. A bus master requests a bus access by sending "load `<addr>`" or "store `<addr>` `<byte>`" with a global address during a clock cycle.

A load is answered with "data `<byte>`", which the bus master receives before its next "clock" message. A store sends nothing back to the bus master.

</dd>

**Shutdown**
<dd>

Each component accepts a "shutdown" message which shuts down the component. A component treats its input closing before a "shutdown" message as an error.

</dd>

**Set Name**
<dd>

"set_name `<name>`" : Sets the name of the component. Each component accepts this message.

</dd>

**UNMAPPED REGISTERS**

<dd>

Reading an unmapped register from a component returns `0xFF`.

Storing to an unmapped register is silently ignored.

</dd>

**ERRORS**

<dd>

Errors go to stderr and exit with status 1.

</dd>

## Component Specific Messages

### CPU

**IN**
<dd>

"clock" : Runs the cpu until it makes a bus access or leaves the ready state. The cpu responds with "tick".

"data `<byte>`" : This delivers the response to a load.

"reset" : This enters the cpu reset pipeline.

"stall" : This stalls the cpu at its current state.

"unstall" : This resumes the cpu from its stalled state.

</dd>

**OUT**
<dd>

"load `<addr>`" : Requests a load from a global address.

"store `<addr>` `<byte>`" : Requests a store to a global address.

"tick" : Indicates that the cpu is done with the clock cycle.

"`<name>` stalled" : This is a message that is printed when the cpu is clocked when stalled. `<name>` is the name given by "set_name".

"`<name>` halted" : This is a message that is printed when the cpu is clocked when halted. `<name>` is the name given by "set_name". The computer stops running when it receives this message.

</dd>

### BUS INTERCONNECT

**IN**
<dd>

"load `<addr>`" : Asks where a load from a global address should go.

"store `<addr>` `<byte>`" : Asks where a store to a global address should go.

"data `<byte>`" : Responds with the same "data `<byte>`" message.

</dd>

**OUT**
<dd>

"`<name>` load `<addr>`" : This tells the computer to route a "load `<addr>`" command to the component with name `<name>`. `<addr>` is the component relative address.

"`<name>` store `<addr>` `<byte>`" : This tells the computer to route a "store `<addr>` `<byte>`" command to the component with name `<name>`. `<addr>` is the component relative address. The bus follows this message with "done".

"data `<byte>`" : Answers a load that is not forwarded. An unmapped address returns `UNMAPPED_DATA` (`0x00`), and a component without read permission returns `DENIED_READ_DATA` (`0xFF`).

"done" : Indicates that the bus is finished with a store. If the address is unmapped or the component has no write permission, the store is dropped and this is the only message sent.

</dd>

### CLOCK
**IN**
<dd>

"wait" : Will cause the clock component to wait until the next clock pulse interval has passed and then to emit a "clock" message.

</dd>

**OUT**
<dd>

"clock" : Indicates that a clock interval has passed and that the computer should tick the clockable components.

</dd>

### LOADER

The loader is both a bus master and a memory mapped component.

**IN**
<dd>

"clock" : Runs one step of the current command. The loader responds with "tick".

"load `<addr>`" : Reads a loader register. The loader responds with "data `<byte>`".

"store `<addr>` `<byte>`" : Writes a loader register. The loader responds with "done".

"data `<byte>`" : This delivers the response to a load requested by the loader.

</dd>

**OUT**
<dd>

"load `<addr>`" : Requests a load from a global address while storing memory to a cartridge.

"store `<addr>` `<byte>`" : Requests a store to a global address while loading a cartridge or clearing memory.

"tick" : Indicates that the loader is done with the clock cycle.

"data `<byte>`" : The response to a load from a loader register.

"done" : The response to a store to a loader register.

</dd>

### ROM, RAM, AND STACK

These three components run the same script. Addresses that have not been written read as `0x00`.

**IN**
<dd>

"load `<addr>`" : Reads a byte.

"store `<addr>` `<byte>`" : Writes a byte.

</dd>

**OUT**
<dd>

"data `<byte>`" : The response to a load.

"done" : The response to a store.

</dd>

### SCREEN AND TIMER

**IN**
<dd>

"load `<addr>`" : Reads a register.

"store `<addr>` `<byte>`" : Writes a register.

</dd>

**OUT**
<dd>

"data `<byte>`" : The response to a load.

"done" : The response to a store.

</dd>

### KEYBOARD

The keyboard is read only, so the bus never forwards a store to it. Sending it a "store" message is an error.

**IN**
<dd>

"load `<addr>`" : Reads a register.

</dd>

**OUT**
<dd>

"data `<byte>`" : The response to a load.

</dd>
