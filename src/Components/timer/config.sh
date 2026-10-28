#!/usr/bin/env bash
# config.sh

US_PER_TICK=1000 # 1 kHz freq

printf -v RESET_ADDR '0x%016X' 0
printf -v TRIGGER_ADDR '0x%016X' 1
printf -v LOW_ADDR '0x%016X' 2

UNMAPPED_DATA=0xFF