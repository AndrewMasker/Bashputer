#!/usr/bin/env bash
# loader.sh

COMPONENT_NAME=Loader

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/config.sh
source "$MY_DIR"/utils.sh
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh

# INITIALIZATION CODE
LOADER_STATE=""
BUSY_STATE=0x00
CART_BYTE=0x00
COMMAND_BYTE=0x00
PROC_STATE=()

parse_Load_CLK() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $((pidx+1)) OPCODE PC 0 true false '0x%02X'
            ;;
        done_load_OPCODE_0)
            parse_OPCODE $((pidx+1))
            ;;
        done_parse)
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_CLK() {
    case $LOADER_STATE in
        "") : ;;
        load) parse_Load_CLK ;;
        store) parse_Load_CLK ;;
        clear) parse_Load_CLK ;;
        *) die "unknown CPU_STATE '$CPU_STATE'" ;;
    esac
}

parse_Data() {
    local value=$1
    if is_2_Digit_Hex "$value" ; then
        DATA="$value"
        DATA_VALID=true
    else
        die "invalid data input of '$value'. CPU data inputs must be of format '0x%02X'"
    fi
}

parse_Command()
{
    COMMAND_BYTE=$byte
    case $COMMAND_BYTE in
        0x00) LOADER_STATE=load ;;
        0x00) LOADER_STATE=store ;;
        0x02) LOADER_STATE=clear ;;
        *) LOADER_STATE="" ; RESULT_STATE=0x04; ;;
    esac
}

parse_Address_Store() {
    local addr=$1 byte=$2
    
}

parse_Store() {
    local addr=$1 byte=$2
    if ! is_16_Digit_Hex "$addr"; then
        die "address '$addr' has wrong format. Must be '0x%016X'"
    fi
    if ! is_2_Digit_Hex "$addr"; then
        die "byte '$byte' has wrong format. Must be '0x%02X'"
    fi
    case $addr in
        "$CART_ADDR")
            CART_BYTE=$byte
            ;;
        "$COMMAND_ADDR")
            parse_Command $byte
            ;;
        *)
            parse_Address_Store $addr $byte
            ;;
    esac
}

parse_Load() {
    local addr=$1
    if ! is_16_Digit_Hex "$addr"; then
        die "address '$addr' has wrong format. Must be '0x%016X'"
    fi
    case $addr in
        "$BUSY_ADDR")
            echo "data $BUSY_STATE"
            ;;
        "$RESULT_ADDR")
            echo "data $RESULT_STATE"
            ;;
        *)
            echo "data $UNMAPPED_DATA"
            ;;
    esac
}

parse_Input() {
    local type=$1
    local value=${2-}
    case $type in
        clock) parse_CLK; echo tick ;;
        store) parse_Store $value ; echo done ;;
        load) parse_Load "$value" ; echo done ;;
        *) die "unknown input type '$type' with value '$value'" ;;
    esac
}

run_LOADER() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

# dump_State() {
#     local i 
#     printf 'CPU STATE: \n'
#     printf '    CPU_STATE=%s RESUME_STATE=%s\n' "${CPU_STATE-unset}" "${RESUME_STATE-unset}"
#     printf '    PC=%s SP=%s OPCODE=%s\n' "${PC-unset}" "${SP-unset}" "${OPCODE-unset}"
#     printf '    ARGA=%s ARGB=%s ARGC=%s\n' "${ARGA-unset}" "${ARGB-unset}" "${ARGC-unset}"
#     printf '    MAR=%s MDR=%s DATA=%s DATA_VALID=%s\n' "${MAR-unset}" "${MDR-unset}" "${DATA-unset}" "${DATA_VALID-unset}"
#     printf '    PROC_STATE=(%s)\n' "${PROC_STATE[*]@Q}"
#     printf '    Nonzero GPRs:\n'
#     for i in "${!GPRs[@]}"; do
#         if (( GPRs[i] != 0 )); then printf '        r%d=%s\n' "$i" "${GPRs[i]}"; fi
#     done
# }

run_LOADER
