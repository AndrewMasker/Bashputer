# Assembly Language

Bashputer programs are written in `.bassm` assembly and built into cartridges by an assembler written in Bash.

- [A first program](#a-first-program)
- [Using the assembler](#using-the-assembler)
- [Statements and comments](#statements-and-comments)
- [Operands](#operands)
- [Labels](#labels)
- [Scopes](#scopes)
- [Label origins](#label-origins)
- [Arithmetic](#arithmetic)
- [Substitutions](#substitutions)
- [Macros](#macros)
- [Data](#data)
- [Common mistakes](#common-mistakes)
- [Editor support](#editor-support)

For a tour of these features in a working program, read [`Assembler/Examples/Showcase.bassm`](../Assembler/Examples/Showcase.bassm).

## A first program

This program prints `Hello!` and waits for a key press:

```bassm
# Hello.bassm

def SCREEN    = 64000
def CX        = ( $SCREEN + 2 )
def CELL      = ( $SCREEN + 14 )
def BLIT      = ( $SCREEN + 15 )
def FILL      = ( $SCREEN + 16 )
def KB_STATUS = 192000

def r_ptr  = r1                     # address of the next character
def r_char = r2                     # the current character
def r_col  = r3                     # the current column
def r_cx   = r4                     # address of the CX register
def r_cell = r5                     # address of the CELL register
def r_addr = r6                     # scratch address

liw $r_addr , $FILL
stb $r_addr , $r_addr               # any write clears the screen

liw $r_ptr , :message
lib $r_col , 0
liw $r_cx , $CX
liw $r_cell , $CELL

next:
    ldb $r_ptr , $r_char            # read a character
    bzi $r_char , :done             # stop at the terminating 0
    stb $r_col , $r_cx              # move the cursor
    stb $r_char , $r_cell           # draw the character
    inc $r_ptr
    inc $r_col
    jmpi :next

done:
liw $r_addr , $BLIT
stb $r_addr , $r_addr               # show what was drawn

liw $r_addr , $KB_STATUS
wait:
    ldb $r_addr , $r_char
    bzi $r_char , :wait             # loop until a key is waiting
hlt

message:
db 0x48 , 0x65 , 0x6C , 0x6C , 0x6F , 0x21 , 0      # "Hello!"
```

Save it as `Hello.bassm`, then build and run it from the root of the repository:

```bash
bash Assembler/assembler.sh Hello.bassm -o src/Cartridges/Hello
src/run.sh Hello
```

## Using the assembler

```text
bash Assembler/assembler.sh [options] <source>
```

| Option | Description |
| --- | --- |
| `-o DIR`, `--output DIR` | Writes the `hex` file to `DIR`. Defaults to a directory named after the source file, next to it. |
| `-k`, `--keep` | Keeps the intermediate files in `work/` inside that default directory |
| `-h`, `--help` | Shows the help message |

| Exit status | Meaning |
| --- | --- |
| 0 | Success |
| 2 | The source contains an error |
| 64 | The command line is invalid |
| Other | The assembler itself failed |

The assembler runs three stages in order:

| Stage | Script | Work done | Output with `-k` |
| --- | --- | --- | --- |
| Preprocessor | `stages/preprocessor.sh` | Removes comments, splits statements, and expands substitutions and macros | `work/pre.bassm` |
| Processor | `stages/processor.sh` | Assigns addresses, resolves labels, and evaluates arithmetic | `work/post.bassm` |
| Hexer | `stages/hexer.sh` | Encodes each statement as bytes | `hex` |

When a macro misbehaves, `-k` is the quickest way to see what it expanded to.

## Statements and comments

Each line holds one or more statements separated by semicolons:

```bassm
lib r1 , 5 ; lib r2 , 6
add r1 , r2 , r3
```

A `#` starts a comment that runs to the end of the line. Closing it with `/#` lets code continue on the same line:

```bassm
lib r1 , # the count /# 10
inc r1              # this comment runs to the end of the line
```

Mnemonics, register names, `db`, and assembler commands such as `!scope` are not case-sensitive. Labels and substitution names are case-sensitive, and the `def` and `undef` keywords must be lowercase.

## Operands

Operands are separated by commas.

| Form | Example |
| --- | --- |
| Register | `r0` to `r255`, or `R0` to `R255` |
| Decimal | `42`, `-1` |
| Hexadecimal | `0x2A` |
| Binary | `0b101010` |
| Octal (leading zero) | `052` |
| Label | `:loop` |
| Arithmetic | `( 6 * 7 )` |

See the [instruction set](instruction-set.md) for the operands of each instruction. In most instructions the destination comes last, so `add r1 , r2 , r3` stores the sum in `r3`.

## Labels

A label names the address of the next statement. Define it with a trailing colon, and refer to it with a leading colon. Labels can be used before they are defined.

```bassm
jmpi :end
nop
end:
hlt
```

A label must be a statement of its own. To put code on the same line, separate them with a semicolon:

```bassm
loop: ; nop
jmpi :loop
```

## Scopes

Scopes let the same label name be used in different parts of a program.

| Syntax | Meaning |
| --- | --- |
| `!scope name` | Opens a named scope and defines the label `name` at its start |
| `!scope` | Opens an anonymous scope |
| `!endscope` | Closes the current scope |
| `:name` | Refers to a global label |
| `:a.b.name` | Refers to a label by its full path |
| `:.name` | Searches the current scope, then each enclosing scope, then the global labels |

Use `:.name` for labels in the current scope. A plain `:name` only finds labels outside of any scope.

```bassm
cali :countdown
hlt

!scope countdown
    lib r1 , 3
    loop:
        dec r1
        bnzi r1 , :.loop
    ret
!endscope
```

From outside the scope above, the loop's address is `:countdown.loop`.

## Label origins

`!label_origin` makes all later label references relative to the current address. Combined with `pc` and `sjo`, this produces code that runs correctly wherever it is loaded:

```bassm
!label_origin
pc r1                   # r1 = the address of this instruction
sjo r1                  # add r1 to every jump, branch, and call

loop:
    jmpi :loop          # the target is relative, and JO makes it absolute
```

The jump origin only applies to jumps, branches, and calls. Loads and stores use absolute addresses, so add the origin yourself when reading data through a label:

```bassm
!label_origin
pc r1
sjo r1

liw r2 , :value         # the offset of value from the origin
add r1 , r2 , r2        # the absolute address of value
ldb r2 , r3             # r3 = 42
hlt

value:
db 42
```

## Arithmetic

An expression in parentheses is evaluated at assembly time using Bash arithmetic, with 64-bit signed integers:

```bassm
lib r1 , ( 2 + 3 * 4 )
liw r2 , ( ( 1 << 40 ) | 0xFF )
lib r3 , ( 10 > 5 ? 1 : 0 )
```

Expressions can include labels, so `( :end - :start )` gives the size of a block of code.

An expression can span several lines. The lines are joined with commas, so earlier lines can set temporary variables and the last line gives the result:

```bassm
lib r1 , (
    width = 12
    height = 7
    width * height
)
```

## Substitutions

`def` defines a name, and `$name` replaces it with its text. Names must start with a letter.

```bassm
def SCREEN = 64000
def FILL   = ( $SCREEN + 16 )
def r_addr = r6

liw $r_addr , $FILL
```

A substitution must be defined above the first place it is used. Defining a name again replaces its value from that point on, and `undef` removes it:

```bassm
def COUNT = 3
lib r1 , $COUNT
undef COUNT
```

Braces hold several statements, on one line or across many:

```bassm
def CLEAR_TWO = { lib r1 , 0 ; lib r2 , 0 }

def CLEAR_THREE = {
    lib r1 , 0
    lib r2 , 0
    lib r3 , 0
}

$CLEAR_TWO
$CLEAR_THREE
```

## Macros

A substitution with `@` parameters is a macro. Pass arguments by name in square brackets:

```bassm
def POKE = { liw r200 , @addr ; stb @value , r200 }

lib r1 , 7
$POKE[addr=64002, value=r1]
```

- Every parameter used in the body must be given an argument.
- An argument can contain anything, including whole statements, as long as its brackets are balanced. Wrap an argument in braces to pass commas or semicolons.
- Arguments can be mnemonics, which lets one macro work with several instructions.
- Macros can call other macros, as long as those macros are defined first.

```bassm
def TWICE = { @body ; @body }
def APPLY = { @op r1 , r2 , r3 }

$TWICE[body={ inc r1 ; inc r2 }]
$APPLY[op=add]
$APPLY[op=xor]
```

A macro that defines labels is automatically wrapped in an anonymous scope, so it can be used more than once. Refer to its labels with `:.name`:

```bassm
def SPIN = {
    lib r1 , @count
    loop:
        dec r1
        bnzi r1 , :.loop
}

$SPIN[count=3]
$SPIN[count=5]
hlt
```

## Data

`db` places raw bytes in the program. Values are reduced to their low 8 bits, and there are no string literals.

```bassm
table:
db 1 , 0x02 , 0b11 , ( 2 * 2 )
```

## Common mistakes

| Mistake | Fix |
| --- | --- |
| `loop: nop` fails with an unknown mnemonic | Put a semicolon after the label: `loop: ; nop` |
| A label inside a scope can't be resolved | Refer to it as `:.name` |
| A value comes out wrong with no error | The assembler keeps only the low bytes of a value that doesn't fit. `lib r1 , 300` loads 44, so use `liq`, `lih`, or `liw` for larger values. |
| A register number above 255 uses the wrong register | Register numbers are also cut to one byte, so `r300` assembles as `r44` |
| `DEF X = 1` fails | Write `def` and `undef` in lowercase |
| A substitution is reported as unknown | Move its `def` above its first use, including uses inside macros |
| `add r1 , r2` fails with an argument error | Three-operand instructions need an explicit destination: `add r1 , r2 , r1` |
| The program never exits | End it with `hlt` |

## Editor support

[`Assembler/Assembly Extension/`](../Assembler/Assembly%20Extension/) contains a VS Code extension that adds syntax highlighting for `.bassm`, `.basm`, and `.bsm` files. To install it, link it into your extensions folder from the root of the repository and restart VS Code:

```bash
ln -s "$PWD/Assembler/Assembly Extension" ~/.vscode/extensions/bassm-syntax
```
