#!/usr/bin/env bash
# config.sh

NAMES=(       rom               screen              keyboard            ram              )
ADDR_LOW=(    0                 $(( 64*1000 ))      $(( 3*64*1000 ))    $(( 4*64*1000 )) )
ADDR_HIGH=(   $(( 64*1000 ))    $(( 3*64*1000 ))    $(( 4*64*1000 ))    $(( 20*64*1000 )) )
PERMISSIONS=( R                 RW                  R                   RW               )

printf -v 'DENIED_READ_DATA' '0x%016X' $(( 1 << 63 ))
