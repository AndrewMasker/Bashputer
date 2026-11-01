#!/usr/bin/env bash
# rom_loader.sh

HEX_FD=""
HEX_BASE=0
HEX_BYTES=()
HEX_EOF=false
BYTE=0x00

hex_Open() {
    local path=$1
    exec {HEX_FD}<"$path"
    HEX_BASE=0
    HEX_EOF=false
    HEX_BYTES=()
}

hex_Close() {
    [[ -n ${HEX_FD} ]] && exec {HEX_FD}<&-; HEX_FD=""
}

get_Byte() {
    local addr=$1 fields
    while (( addr >= HEX_BASE + ${#HEX_BYTES[@]})); do
        if ! read -r -u "$HEX_FD" -a fields; then 
            BYTE=0x00 
            HEX_EOF=true
            return 0
        fi
        HEX_BASE=${fields[0]}
        if ! is_16_Digit_Hex $HEX_BASE; then
            die "incorrect address format for address '$HEX_BASE'. must be '0x%016X'"
        fi
        HEX_BYTES=("${fields[@]:1}")
    done
    if (( addr < HEX_BASE )); then 
        BYTE=0x00
    else
        BYTE=${HEX_BYTES[addr - HEX_BASE]}
        if ! is_2_Digit_Hex $BYTE; then
            die "incorrect byte format for byte '$BYTE'. must be '0x%02X'"
        fi
    fi
}

load_ROM() {
    local rom_cart=$1 path addr reply
    path="$MY_DIR"/../Cartridges/"$rom_cart"/hex
    if [[ ! -f $path ]]; then 
        die "'$rom_cart' was no found"
    fi
    hex_Open "$path"
    addr=0x00
    while ! HEX_EOF; do
        get_Byte $addr
        send_Message rom "store $addr $BYTE"
        get_Message rom reply
        printf -v addr '0x%016X' $(( addr + 1 ))
    done
    hex_Close
}