# Message Protocol
This file documents the message protocols used by every component shipped with the repo.

Messages are used to pipe the components together; they are not something that the virtual components can see or interact with.

A message is a space separated list of words representing the message type and data sent within it. The first word within a message specifies its type. You can think of a message's type as specifying which pins the component is outputting the data onto.

A message out goes via STDOUT and a message in comes via STDIN.

## General
**Value Formats**
<dd>

addresses : All addresses must be in the format `0x%016X`.

bytes : All bytes must be in the format `0x%02X`.

</dd>

**Component Addresses**
<dd>

Global addresses sent from the cpu go to the bus interconnect. There they are sent to each memory mapped component based on the memory layout in the bus interconnect's `config.sh` file. The `LOW_ADDR` of the component is subtracted from the global address the cpu sends to make a component relative address for the component.

</dd>

**Commands and Responses**
<dd>

Each command is given gets a response back. That response may contain information or may just indicate that the command has finished. A "*" indicates optional arguments.

"clock" &rarr; "tick"

"* load `<address>`" &rarr; "data `<byte>`"

"* store `<addr>` `<byte>`" &rarr; "done"

</dd>

**Shutdown**
<dd>

Each component accepts a "shutdown" message which shuts down the component.

</dd>

**UMAPPED REGISTERS**

<dd>

Reading an unmapped register from a component returns `0xFF`.

Storing to an unmapped register is silently ignored.

</dd>

**ERRORS**

<dd>

Errors go to stderr and exit with status 1. 

</dd>

## Components

### CPU

**IN**
<dd>

"clock" : This moves the cpu forward by a state in its lowest process. 

"data `<byte>`" : This puts the byte `<byte>` into the data register and sets the `DATA_VALID` flag to true which allows the cpu to continue.

"reset" : This enters the cpu reset pipeline.

"stall" : This stalls the cpu at its current state.

"unstall : This resumes the cpu from its stalled state.

shutdown : This is a message that tells the cpu to shutdown.

</dd>

**OUT**
<dd>

load `<addr>` : This tells whatever is hooked up to the address bus and the data bus for the cpu to return a byte from address `<addr>`.

store `<addr>` `<byte>` : This tells whatever is hooked up to the address bus and the data bus to store the byte `<byte>` formatted with '0x%02X' at address `<addr>`.

tick : This is a message sent after a clock pulse has been fully completed.

halted : This is a message that is printed when the cpu has halted.

</dd>

### BUS INTERCONNECT
**IN**
<dd>

load `<addr>` : This tells the bus interconnect to return a byte from whatver owns address `<addr>` at `<addr>` minus the offset of the component.

store `<addr>` `<byte>` : This tells the bus interconnect to store a byte to whatver owns address `<addr>` at `<addr>` minus the offset of the component.

data `<byte>` : This tells the bus interconnect the byte from the last load command it sent.

**OUT**

done : Indicates that the current step is over.

`<name>` load `<addr>` : This tells the outside world to forward the load `<addr>` command to the component with name `<name>`.

`<name>` store `<addr>` `<byte>` : This tells the outside world to forward the store `<addr>` `<byte>` command to the component with name `<name>`.

data `<byte>` : This passes the byte that the interconnect received from a load request back to the thing that is requesting from it.

</dd>

### RAM
**IN**
<dd>

load `<addr>` : This tells the ram to return a byte from address `<addr>`.

store `<addr>` `<byte>` : This tells the ram to store a byte at address `<addr>`.

**OUT**

done : Indicates that the current step is over.

data `<byte>` : This passes the byte the ram found back.

</dd>