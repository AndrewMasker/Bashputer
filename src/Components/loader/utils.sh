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
    local i msg="" bytes_strung=0 last_i_set=0
    for i in "${!NEW_BYTES[@]}"; do
        if (( i != (last_i_set+1) && bytes_strung > 0)); then 
            msg+=$'\n'
            bytes_strung=0
        fi
        if (( bytes_strung == 0 )); then
            printf -v msg '%s0x%016X' "$msg" "$i"
        fi
        msg+=" ${NEW_BYTES[i]}"
        bytes_strung=$(( bytes_strung + 1))
        last_i_set=$i
        if (( bytes_strung == 16)); then
            msg+=$'\n'
            bytes_strung=0
        fi
    done
    if (( bytes_strung > 0 )); then msg+=$'\n'; fi
    printf -v "REWRITE" '%s' "$msg"
}

hex_Commit() {
    local path=$1 tmp="$1.tmp" base top rewrite_top n in out fields num_to_keep start_to_keep wrote_new=false
    exec {in}<"$path" {out}>"$tmp"
    while read -r -u "$in" -a fields; do
        (( ${#fields[@]} )) || continue
        base=${fields[0]}
        n=$(( ${#fields[@]} - 1 ))
        top=$(( base + n -1 ))
        rewrite_top=$(( OFFSET + END - START ))
        if (( base < OFFSET )); then
            if (( OFFSET - base < n )); then
                num_to_keep=$(( OFFSET - base ))
            else
                num_to_keep=$n
            fi
            printf '0x%016X %s\n' "$base" "${fields[*]:1:num_to_keep}" >&"$out"
        fi
        if (( top > rewrite_top )); then
            $wrote_new || { printf '%s' "$REWRITE" >&"$out"; wrote_new=true; }
            start_to_keep=$(( rewrite_top - base + 1 ))
            if (( start_to_keep < 0 )); then start_to_keep=0; fi
            printf '0x%016X %s\n' $((base + start_to_keep )) "${fields[*]:1+start_to_keep}" >&"$out"
        fi
    done
    $wrote_new || { printf '%s' "$REWRITE" >&"$out"; wrote_new=true; }
    exec {in}<&- {out}>&-
    mv -- "$tmp" "$path"
}