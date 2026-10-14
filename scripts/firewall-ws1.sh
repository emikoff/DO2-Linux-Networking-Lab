#!/usr/bin/env bash

set -euo pipefail

readonly CHAIN="DO2_ICMP_OUT"

if (( EUID != 0 )); then
    printf 'Run as root: sudo %s\n' "$0" >&2
    exit 1
fi

iptables -N "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN"
iptables -A "$CHAIN" -j ACCEPT
iptables -A "$CHAIN" -j DROP

iptables -C OUTPUT -p icmp --icmp-type echo-reply -j "$CHAIN" 2>/dev/null || \
    iptables -I OUTPUT 1 -p icmp --icmp-type echo-reply -j "$CHAIN"

printf 'ICMP echo replies are accepted before the drop rule.\n'
