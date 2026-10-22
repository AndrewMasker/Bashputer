# Message Protocol
This file documents the message protocols used by every component shipped with the repo.

A message is a space separated list of words representing the message type and data sent within it. The first word within a message specifies its type. You can think of a message's type as specifying which pins the component is outputting the data onto.

A message out goes via STDOUT and a message in comes via STDIN.

## CPU
**IN**
<dd>

"clock_pulse" : This moves the cpu forward by a state in its lowest process.

"data" `<byte>` : This puts the byte `<byte>` which must be formatted with '0x%02X' into the data register.

"reset" : This enters the cpu reset pipeline.

"stall" : This stalls the cpu at its current state.

"unstall" : This resumes the cpu from its stalled state.

"data_valid" : This sets the internal DATA_VALID register to "true" which allows a load command to progress.

</dd>

**OUT**
<dd>

load `<addr>` : This tells whatever is hooked up to the address bus and the data bus for the cpu to return a byte from address `<addr>`.

store `<addr>` `<byte>` This tells whatever is hooked up to the address bus and the data bus to store the byte `<byte>` formatted with '0x%02X' at address `<addr>`.

</dd>
