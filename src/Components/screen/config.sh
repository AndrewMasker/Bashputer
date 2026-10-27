#!/usr/bin/env bash
# config.sh

printf -v 'WIDTH' '0x%02X' 254
printf -v 'HEIGHT' '0x%02X' 127 # height of characters. Pixel height is twice as high

printf -v 'MODE_ADDR' '0x%016X' 0       # 0 is character, 1 is pixel
printf -v 'CMODE_ADDR' '0x%016X' 1      # 0 is by index,  1 is by rgb
printf -v 'CX_ADDR' '0x%016X' 2
printf -v 'CY_ADDR' '0x%016X' 3
printf -v 'FIDX_ADDR' '0x%016X' 4
printf -v 'FR_ADDR' '0x%016X' 5
printf -v 'FG_ADDR' '0x%016X' 6
printf -v 'FB_ADDR' '0x%016X' 7
printf -v 'BIDX_ADDR' '0x%016X' 8
printf -v 'BR_ADDR' '0x%016X' 9
printf -v 'BG_ADDR' '0x%016X' 10
printf -v 'BB_ADDR' '0x%016X' 11
printf -v 'WIDTH_ADDR' '0x%016X' 12
printf -v 'HEIGHT_ADDR' '0x%016X' 13
printf -v 'CELL_ADDR' '0x%016X' 14      # Writes to a cell
printf -v 'BLIT_ADDR' '0x%016X' 15      # Blits all writes onto the screen
printf -v 'FILL_ADDR' '0x%016X' 16     # Clears the screen to the background color
printf -v 'RESET_ADDR' '0x%016X' 17
UNMAPPED_DATA=0xFF