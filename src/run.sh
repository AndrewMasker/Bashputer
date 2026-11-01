#!/usr/bin/env bash
# run.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)


if ! command -v bwrap >/dev/null; then 
      echo "run.sh: bwrap not found" >&2
      exit 1
fi

binds=()
for cart in "$MY_DIR"/Cartridges/*/; do
      if [[ ! -f $cart/hex ]]; then
            continue
      fi
      cart=${cart%/}
      binds+=(--bind "$cart" "$cart")
done

trap '' INT
trap ':' QUIT
saved=$(stty -g </dev/tty)
bwrap --ro-bind / / \
      --dev /dev --proc /proc --tmpfs /tmp \
      "${binds[@]}" \
      --unshare-all --die-with-parent \
      env --default-signal=INT bash "$MY_DIR"/Computer/computer.sh "$@"
status=$?
stty "$saved" </dev/tty
printf '\e[0m\e[?25h' >/dev/tty
exit "$status"