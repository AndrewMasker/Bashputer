#!/usr/bin/env bash
# rom_loader.sh

load_ROM() {
    local rom_cart=$1 path reply fields base n i tmp
    path="$MY_DIR"/../Cartridges/"$rom_cart"/hex
    if [[ ! -f $path ]]; then 
        die "'$rom_cart' was no found"
    fi
    exec {fd}<"$path"
    while read -r -u "$fd" -a fields; do
        if (( ${#fields[@]} == 0 )); then continue; fi

        base=${fields[0]}
        n=$(( ${#fields[@]} - 1 ))

        for i in {1..i}; do
            printf -v tmp 'store 0x%016X 0x%02X' $(( base + i - 1 )) ${fields[i]}
            send_Message rom "$tmp"
            get_Message rom reply
        done
    done
    exec {fd}<&-
}