#!/usr/bin/env bash
# config.sh

NAMES=(       rom               screen              keyboard            timer               loader              ram                 stack             )
ADDR_LOW=(    0                 $(( 64*1000 ))      $(( 3*64*1000 ))    $(( 4*64*1000 ))    $(( 5*64*1000 ))    $(( 6*64*1000 ))    $(( 22*64*1000 )) )
ADDR_HIGH=(   $(( 64*1000 ))    $(( 3*64*1000 ))    $(( 4*64*1000 ))    $(( 5*64*1000 ))    $(( 6*64*1000 ))    $(( 22*64*1000 ))   $(( 38*64*1000 )) )
PERMISSIONS=( R                 RW                  R                   RW                  RW                  RW                  RW                )

DENIED_READ_DATA=0xFF
UNMAPPED_DATA=0x00