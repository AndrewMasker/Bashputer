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

**Messages and Responses**
<dd>

Some messages are special and get a response back. That response may contain information or may just indicate that the command initiated by the message has finished. These are the messages that allow data to flow across the computer and allow the computer to tick forward. A "*" indicates optional arguments. 

"clock" &rarr; "tick" : Indicates a clock pulse to a clockable component. The response indicates that the component is done with that cycle.

"* load `<address>`" &rarr; "data `<byte>`" : Indicates a load from an address. The response indicated the data found at that address.

"* store `<addr>` `<byte>`" &rarr; "done" : Indicates a store of a byte into an address. The response indicates that the store is done.

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

## Component Specific Messages

### CPU

**IN**
<dd>

"reset" : This enters the cpu reset pipeline.

"stall" : This stalls the cpu at its current state.

"unstall : This resumes the cpu from its stalled state.

</dd>

**OUT**
<dd>

"stalled" : This is a message that is printed when the cpu is clocked when stalled

"halted" : This is a message that is printed when the cpu is clocked when halted.

</dd>

### BUS INTERCONNECT
**OUT**

"`<name>` load `<addr>`" : This tells the computer to route a "load `<addr>`" command to the component with name `<name>`.

"`<name>` store `<addr>` `<byte>`" : This tells the computer to route a "store `<addr>` `<byte>`" command to the component with name `<name>`.

</dd>

### CLOCK
**IN**
<dd>

"wait" : Will cause the clock component to wait until the next clock pulse interval has passed and then to emit a "clock" message.

**OUT**

"clock" : Indicates that a clock interval has passed and that the computer should tick the clockable components.

</dd>