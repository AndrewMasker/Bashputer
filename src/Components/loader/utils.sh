#!/usr/bin/env bash
# utils.sh

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

make_Rewrite_String() {
    local out=$1 i msg="" tmp bytes_strung=0 last_i_set=0
    for i in "${!NEW_BYTES[@]}"; do
        if (( i != (last_i_set+1) )); then bytes_strung=0; fi
        if (( bytes_strung == 0 )); then
            printf -v tmp '0x%016X' i
            msg+="$tmp "
        if (( bytes_strung < 16  )); then
            msg+="$NEW_BYTES[i] "
            bytes_strung=$(( bytes_strung + 1))
            last_i_set=$i
        else
            msg+="\n"
            bytes_strung=0
        fi

    done
}