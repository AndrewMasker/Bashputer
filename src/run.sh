#!/usr/bin/env bash
# run.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

bwrap --ro-bind / / \
      --dev /dev --proc /proc --tmpfs /tmp \
      --bind "$MY_DIR"/Cartridges "$MY_DIR"/Cartridges \
      --unshare-all --die-with-parent \
      bash "$MY_DIR"/Computer/computer.sh