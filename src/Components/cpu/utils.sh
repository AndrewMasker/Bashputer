#!/usr/bin/env bash
# utils.sh

get_Lower_Byte() {
    printf '0x%02X' $(( $1 & 0xFF )) 
}

store_Byte() {
    local pidx=${1}
    local to=${2} # The register holding the address to be stored to
    local from=${3} # The register holding the value 
    local addr_offset=${4:-0}
    local data_offset=${5:-0}
    local to_address
    printf -v "to_address" '0x%016X' $(( ${!to} + addr_offset ))
    local byte
    printf -v "byte" '0x%02X' $(( (${!from} >> data_offset) & 0xFF ))
    echo store "$byte" "$to_address"
    if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_store_${to}_${addr_offset}"; fi
}

store_Quarter() {
    local pidx=${1}
    local to=${2}
    local from=${3}
    local addr_offset=${4:-0}
    local data_offset=${5:-0}
    local byte_0_addr_offset=$addr_offset
    local byte_1_addr_offset=$((addr_offset + 1))
    local byte_0_data_offset=$data_offset
    local byte_1_data_offset=$((data_offset + 8))
    case ${PROC_STATE[pidx]-} in
        "")
            store_Byte $((pidx+1)) "$to" "$from" "$byte_0_addr_offset" "$byte_0_data_offset"
            ;;
        "done_store_${to}_${byte_0_addr_offset}")
            store_Byte $((pidx+1)) "$to" "$from" "$byte_1_addr_offset" "$byte_1_data_offset"
            ;;
        "done_store_${to}_${byte_1_addr_offset}")
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_store_${to}_${addr_offset}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

store_Half() {
    local pidx=${1}
    local to=${2}
    local from=${3}
    local addr_offset=${4:-0}
    local data_offset=${5:-0}
    local quarter_0_addr_offset=$addr_offset
    local quarter_1_addr_offset=$((addr_offset + 2))
    local quarter_0_data_offset=$data_offset
    local quarter_1_data_offset=$((data_offset + 16))
    case ${PROC_STATE[pidx]-} in
        "")
            store_Quarter $((pidx+1)) "$to" "$from" "$quarter_0_addr_offset" "$quarter_0_data_offset"
            ;;
        "done_store_${to}_${quarter_0_addr_offset}")
            store_Quarter $((pidx+1)) "$to" "$from" "$quarter_1_addr_offset" "$quarter_1_data_offset"
            ;;
        "done_store_${to}_${quarter_1_addr_offset}")
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_store_${to}_${addr_offset}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

store_Word() {
    local pidx=${1}
    local to=${2}
    local from=${3}
    local addr_offset=${4:-0}
    local data_offset=${5:-0}
    local half_0_addr_offset=$addr_offset
    local half_1_addr_offset=$((addr_offset + 4))
    local half_0_data_offset=$data_offset
    local half_1_data_offset=$((data_offset + 32))
    case ${PROC_STATE[pidx]-} in
        "")
            store_Half $((pidx+1)) "$to" "$from" "$half_0_addr_offset" "$half_0_data_offset"
            ;;
        "done_store_${to}_${half_0_addr_offset}")
            store_Half $((pidx+1)) "$to" "$from" "$half_1_addr_offset" "$half_1_data_offset"
            ;;
        "done_store_${to}_${half_1_addr_offset}")
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_store_${to}_${addr_offset}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_Byte() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"} # The register that the byte should be loaded into
    local from=${3:-"PC"} # The register that holds the address to be loaded
    local where=${4:-0}
    local clear=${5:-"true"}
    local increment=${6:-"true"}
    local data=$(( DATA & 0xFF))
    case ${PROC_STATE[pidx]-} in
        "")
            if $increment; then printf -v "$from" '0x%016X' $((${!from} + 1)); fi
            echo load "${!from}"
            if $clear; then printf -v "$to" '0x%016X' 0; fi
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            local prev
            printf -v "prev" '0x%016X' "${!to}"
            if ((where < 7)); then
                local upper_mask=$(( -1 << ( (where + 1)*8 ) ))
                local lower_mask=$(( ~( -1 << ( where*8 ) ) ))
                local mask=$(( (upper_mask) | (lower_mask) ))
                data=$(( data << (where*8) ))
            elif ((where == 7)); then
                local mask=$(( ~( -1 << ( where*8 ) ) ))
                data=$(( data << (where*8) ))
            else
                local mask=-1
                data=0
            fi
            printf -v "$to" '0x%016X' $(( (prev & mask) | data))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_${to}_${where}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_Quarter() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"}
    local from=${3:-"PC"}
    local where=${4:-0}
    local clear=${5:-"true"}
    local increment=${6:-"true"}
    local byte_0_where=$where
    local byte_1_where=$(( where + 1 ))
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $((pidx+1)) "$to" "$from" "$byte_0_where" "$clear" "$increment"
            ;;
        "done_load_${to}_${byte_0_where}")
            load_Byte $((pidx+1)) "$to" "$from" "$byte_1_where" false true
            ;;
        "done_load_${to}_${byte_1_where}")
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_${to}_${where}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_Half() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"}
    local from=${3:-"PC"}
    local where=${4:-0}
    local clear=${5:-"true"}
    local increment=${6:-"true"}
    local quarter_0_where=$where
    local quarter_1_where=$(( where + 2))
    case ${PROC_STATE[pidx]-} in
        "")
            load_Quarter $((pidx+1)) "$to" "$from" "$quarter_0_where" "$clear" "$increment"
            ;;
        "done_load_${to}_${quarter_0_where}")
            load_Quarter $((pidx+1)) "$to" "$from" "$quarter_1_where" false true
            ;;
        "done_load_${to}_${quarter_1_where}")
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_${to}_${where}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_Word() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"}
    local from=${3:-"PC"}
    local where=${4:-0}
    local clear=${5:-"true"}
    local increment=${6:-"true"}
    local half_0_where=$where
    local half_1_where=$(( where + 4 ))
    case ${PROC_STATE[pidx]-} in
        "")
            load_Half $((pidx+1)) "$to" "$from" "$half_0_where" "$clear" "$increment"
            ;;
        "done_load_${to}_${half_0_where}")
            load_Half $((pidx+1)) "$to" "$from" "$half_1_where" false true
            ;;
        "done_load_${to}_${half_1_where}")
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_${to}_${where}"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_1_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $(( pidx + 1)) ARGA
            ;;
        done_load_ARGA_0)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_2_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $(( pidx + 1)) ARGA
            ;;
        done_load_ARGA_0)
            load_Byte $(( pidx + 1)) ARGB
            ;;
        done_load_ARGB_0)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_3_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $(( pidx + 1)) ARGA
            ;;
        done_load_ARGA_0)
            load_Byte $(( pidx + 1)) ARGB
            ;;
        done_load_ARGB_0)
            load_Byte $(( pidx + 1)) ARGC
            ;;
        done_load_ARGC_0)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

