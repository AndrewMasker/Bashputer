#!/usr/bin/env bash
# screen.sh

COMPONENT_NAME="Screen"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh
source "$MY_DIR"/config.sh

reset() {
    writes=""
    mode=0x00
    cmode=0x00
    cx=0x00
    cy=0x00
    fidx=0x10
    fr=0x00
    fg=0x00
    fb=0x00
    bidx=0x0F
    br=0x00
    bg=0x00
    bb=0x00
}

parse_Load() {
    local addr=$1
    if ! is_16_Digit_Hex "$addr"; then
        die "address '$addr' has wrong format. Must be '0x%016X'"
    fi
    case $addr in
        "$MODE_ADDR")
            echo "data $mode"
            ;;
        "$CMODE_ADDR")
            echo "data $cmode"
            ;;
        "$CX_ADDR")
            echo "data $cx"
            ;;
        "$CY_ADDR")
            echo "data $cy"
            ;;
        "$FIDX_ADDR")
            echo "data $fidx"
            ;;
        "$FR_ADDR")
            echo "data $fr"
            ;;
        "$FG_ADDR")
            echo "data $fg"
            ;;
        "$FB_ADDR")
            echo "data $fb"
            ;;
        "$BIDX_ADDR")
            echo "data $bidx"
            ;;
        "$BR_ADDR")
            echo "data $br"
            ;;
        "$BG_ADDR")
            echo "data $bg"
            ;;
        "$BB_ADDR")
            echo "data $bb"
            ;;
        "$WIDTH_ADDR")
            echo "data $WIDTH"
            ;;
        "HEIGHT_ADDR")
            echo "data $HEIGHT"
            ;;
        *)
            echo "data $UNMAPPED_DATA"
            ;;
    esac
}

parse_Mode() {
    local byte=$1
    printf -v 'byte' '0x%02X' $(( byte % 2 ))
    mode=$byte
}

parse_Cmode() {
    local byte=$1
    printf -v 'byte' '0x%02X' $(( byte % 2 ))
    cmode=$byte
}

parse_CX() {
    local byte=$1
    if (( byte < WIDTH )); then 
        cx=$byte 
    else 
        cx=$WIDTH
    fi
}

parse_CY() {
    local byte=$1
    if (( byte < HEIGHT )); then 
        cx=$byte 
    else 
        cx=$HEIGHT
    fi
}

parse_Char() {
    local byte=$1 tmp
    printf -v 'tmp' '\e[%d;%dH' $(( cy + 1 )) $(( cx + 1))
    writes+=$tmp
    if (( cmode == 0 )); then
        printf -v 'tmp' '\e[38;5;%d;48;5;%dm' "$fidx" "$bidx"
    else
        printf -v 'tmp' '\e[38;2;%d;%d;%d;48;2;%d;%d;%dm' "$fr" "$fg" "$fb" "$br" "$bg" "$bb"
    fi
    writes+=$tmp
    if (( byte < 0x20 || byte == 0x7F )); then byte=0x20; fi
    printf -v 'tmp' "\\x${byte:2}"
    writes+=$tmp
}

parse_Pixel() {
    local byte=$1 tmp
    printf -v 'tmp' '\e[%d;%dH' $(( cy + 1 )) $(( cx + 1))
    writes+=$tmp
    if (( cmode == 0 )); then
        printf -v 'tmp' '\e[38;5;%d;48;5;%dm' "$fidx" "$bidx"
    else
        printf -v 'tmp' '\e[38;2;%d;%d;%d;48;2;%d;%d;%dm' "$fr" "$fg" "$fb" "$br" "$bg" "$bb"
    fi
    writes+=$tmp
    writes+=$'\xE2\x96\x80'
}

parse_Cell() {
    local byte=$1
    if (( mode == 0 )); then 
        parse_Char $byte
    else
        parse_Pixel
}

parse_Blit() {
    printf '%s' "$writes" >&"$TTY"
    writes=""
}

parse_Fill() {
    if (( cmode == 0 )); then
        printf '\e[48;5;%dm\e[2J' "$bidx" >&"$TTY"
    else
        printf '\e[48;2;%d;%d;%dm\e[2J'"$br" "$bg" "$bb" >&"$TTY"
    fi
}

parse_Store() {
    local addr=$1 byte=$2
    if ! is_16_Digit_Hex "$addr"; then
        die "address '$addr' has wrong format. Must be '0x%016X'"
    fi
    if ! is_2_Digit_Hex "$byte"; then
        die "byte '$byte' has wrong format. Must be '0x%02X'"
    fi
    case $addr in
        "$MODE_ADDR")
            parse_Mode $byte
            ;;
        "$CMODE_ADDR")
            parse_Cmode $byte
            ;;
        "$CX_ADDR")
            parse_CX $byte
            ;;
        "$CY_ADDR")
            parse_CY $byte
            ;;
        "$FIDX_ADDR")
            fidx=$byte
            ;;
        "$FR_ADDR")
            fr=$byte
            ;;
        "$FG_ADDR")
            fb=$byte
            ;;
        "$FB_ADDR")
            fg=$byte
            ;;
        "$BIDX_ADDR")
            bidx=$byte
            ;;
        "$BR_ADDR")
            br=$byte
            ;;
        "$BG_ADDR")
            bg=$byte
            ;;
        "$BB_ADDR")
            bb=$byte
            ;;
        "$CELL_ADDR")
            parse_Cell $byte
            ;;
        "$BLIT_ADDR")
            parse_Blit
            ;;
        "$FILL_ADDR")
            parse_Fill
            ;;
        "$RESET_ADDR")
            reset
            ;;
    esac
}

parse_Input() {
    local type=$1 value=$2
    case $type in
        load) parse_Load "$value" ; echo done ;;
        store) parse_Store $value ; echo done ;;
        *) die "unknown input type" ;;
    esac
}

run_SCREEN() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

reset

run_SCREEN