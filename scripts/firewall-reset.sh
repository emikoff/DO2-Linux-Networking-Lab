#!/usr/bin/env bash

set -euo pipefail

readonly CHAIN="DO2_ICMP_OUT"

if (( EUID != 0 )); then
    printf 'Run as root: sudo %s\n' "$0" >&2
    exit 1
fi

while iptables -C OUTPUT -p icmp --icmp-type echo-reply -j "$CHAIN" 2>/dev/null; do
    iptables -D OUTPUT -p icmp --icmp-type echo-reply -j "$CHAIN"
done

iptables -F "$CHAIN" 2>/dev/null || true
iptables -X "$CHAIN" 2>/dev/null || true
printf 'DO2 firewall demo rules removed.\n'
