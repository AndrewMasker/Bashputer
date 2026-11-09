#!/usr/bin/env bash
# config.sh

printf -v 'RESET_PC' '0x%016X' 0
printf -v 'RESET_SP' '0x%016X' $(( 22*64*1000 ))
printf -v 'RESET_JO' '0x%016X' 0
printf -v 'RESET_RNG' '0x%016X' 0x9E3779B97F4A7C15