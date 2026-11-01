#!/usr/bin/env bash
# rom_loader.sh

load_ROM() {
    local rom_cart=$1 path reply fields base n i fd addr byte
    path="$MY_DIR"/../Cartridges/"$rom_cart"/hex
    if [[ ! -f $path ]]; then 
        die "'$rom_cart' was not found"
    fi
    exec {fd}<"$path"
    while read -r -u "$fd" -a fields; do
        if (( ${#fields[@]} == 0 )); then continue; fi

        base=${fields[0]}
        if ! is_16_Digit_Hex "$base"; then
            die "address $base in cartridge $rom_cart has impropper format"
        fi
        n=$(( ${#fields[@]} - 1 ))

        for (( i = 1; i<=n; i++ )); do
            printf -v addr '0x%016X' $(( base + i - 1 ))
            byte=${fields[i]}
            if [[ $byte == 0x00 ]]; then continue; fi
            if ! is_2_Digit_Hex "$byte"; then
                die "byte $byte at address $addr has impropper format"
            fi
            send_Message "$ROM" "store $addr $byte"
            get_Message "$ROM" reply
        done
    done
    exec {fd}<&-
}