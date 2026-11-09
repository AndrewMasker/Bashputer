#!/usr/bin/env bash
# screen.sh

COMPONENT_NAME="Screen"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh
source "$MY_DIR"/config.sh

exec {TTY}>/dev/tty

declare -A fidx_array fr_array fg_array fb_array bidx_array br_array bg_array bb_array

reset_Arrays() {
    fidx_array=() fr_array=() fg_array=() fb_array=() 
    bidx_array=() br_array=() bg_array=() bb_array=()
    rd_fidx_df=$bidx
    rd_fr_df=$br
    rd_fg_df=$bg
    rd_fb_df=$bb
    rd_bidx_df=$bidx
    rd_br_df=$br
    rd_bg_df=$bg
    rd_bb_df=$bb
}

reset() {
    writes=""
    mode=0x00
    cmode=0x00
    cx=0x00
    cy=0x00
    fidx=0x0F
    fr=0xFF
    fg=0xFF
    fb=0xFF
    bidx=0x10
    br=0x00
    bg=0x00
    bb=0x00
    reset_Arrays
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
        "$HEIGHT_ADDR")
            echo "data $HEIGHT"
            ;;
        "$RD_FIDX_ADDR")
            echo "data ${fidx_array[$cx $cy]-$rd_fidx_df}"
            ;;
        "$RD_FR_ADDR")
            echo "data ${fr_array[$cx $cy]-$rd_fr_df}"
            ;;
        "$RD_FG_ADDR")
            echo "data ${fg_array[$cx $cy]-$rd_fg_df}"
            ;;
        "$RD_FB_ADDR")
            echo "data ${fb_array[$cx $cy]-$rd_fb_df}"
            ;;
        "$RD_BIDX_ADDR")
            echo "data ${bidx_array[$cx $cy]-$rd_bidx_df}"
            ;;
        "$RD_BR_ADDR")
            echo "data ${br_array[$cx $cy]-$rd_br_df}"
            ;;
        "$RD_BG_ADDR")
            echo "data ${bg_array[$cx $cy]-$rd_bg_df}"
            ;;
        "$RD_BB_ADDR")
            echo "data ${bb_array[$cx $cy]-$rd_bb_df}"
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
        printf -v 'cx' '0x%02X' $(( WIDTH - 1 ))
    fi
}

parse_CY() {
    local byte=$1
    if (( byte < HEIGHT )); then 
        cy=$byte 
    else 
        printf -v 'cy' '0x%02X' $(( HEIGHT - 1 ))
    fi
}

set_Arrays_0() {
    fidx_array["$cx $cy"]="$fidx"
    unset 'fr_array['"$cx $cy"']'
    unset 'fg_array['"$cx $cy"']'
    unset 'fb_array['"$cx $cy"']'
    bidx_array["$cx $cy"]="$bidx"
    unset 'br_array['"$cx $cy"']'
    unset 'bg_array['"$cx $cy"']'
    unset 'bb_array['"$cx $cy"']'
}

set_Arrays_1() {
    fr_array["$cx $cy"]="$fr"
    fg_array["$cx $cy"]="$fg"
    fb_array["$cx $cy"]="$fb"
    unset 'bidx_array['"$cx $cy"']'
    br_array["$cx $cy"]="$br"
    bg_array["$cx $cy"]="$bg"
    bb_array["$cx $cy"]="$bb"
}

parse_Char() {
    local byte=$1 tmp
    printf -v 'tmp' '\e[%d;%dH' $(( cy + 1 )) $(( cx + 1))
    writes+=$tmp
    if (( cmode == 0 )); then
        printf -v 'tmp' '\e[38;5;%d;48;5;%dm' "$fidx" "$bidx"
        set_Arrays_0
        
    else
        printf -v 'tmp' '\e[38;2;%d;%d;%d;48;2;%d;%d;%dm' "$fr" "$fg" "$fb" "$br" "$bg" "$bb"
        set_Arrays_1
    fi
    writes+=$tmp
    if (( byte < 0x20 || byte == 0x7F )); then byte=0x20; fi
    printf -v 'tmp' "\\x${byte:2}"
    writes+=$tmp
}

parse_Pixel() {
    local tmp
    printf -v 'tmp' '\e[%d;%dH' $(( cy + 1 )) $(( cx + 1))
    writes+=$tmp
    if (( cmode == 0 )); then
        printf -v 'tmp' '\e[38;5;%d;48;5;%dm' "$fidx" "$bidx"
        set_Arrays_0
    else
        printf -v 'tmp' '\e[38;2;%d;%d;%d;48;2;%d;%d;%dm' "$fr" "$fg" "$fb" "$br" "$bg" "$bb"
        set_Arrays_1
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
    fi
}

parse_Blit() {
    printf '%s' "$writes" >&"$TTY"
    writes=""
}

parse_Fill() {
    local tmp
    if (( cmode == 0 )); then
        printf -v 'tmp' '\e[48;5;%dm\e[2J' "$bidx"
        reset_Arrays
        rd_fidx_df=$bidx
        rd_bidx_df=$bidx
    else
        printf -v 'tmp' '\e[48;2;%d;%d;%dm\e[2J' "$br" "$bg" "$bb"
        reset_Arrays
        rd_fr_df=$br
        rd_fg_df=$bg
        rd_fb_df=$bb
        rd_br_df=$br
        rd_bg_df=$bg
        rd_bb_df=$bb
    fi
    writes+=$tmp
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
            fg=$byte
            ;;
        "$FB_ADDR")
            fb=$byte
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
        load) parse_Load "$value" ;;
        store) parse_Store $value ; echo done ;;
        *) die "unknown input type" ;;
    esac
}

run_SCREEN() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            set_name) COMPONENT_NAME="$value" ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

reset

run_SCREEN