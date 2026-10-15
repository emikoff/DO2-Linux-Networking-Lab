#!/usr/bin/env bash

set -euo pipefail

readonly CHAIN="DO2_ICMP_OUT"
readonly INPUT_CHAIN="DO2_TCP_IN"

if (( EUID != 0 )); then
    printf 'Run as root: sudo %s\n' "$0" >&2
    exit 1
fi

iptables -N "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN"
iptables -A "$CHAIN" -j DROP
iptables -A "$CHAIN" -j ACCEPT

iptables -N "$INPUT_CHAIN" 2>/dev/null || true
iptables -F "$INPUT_CHAIN"
iptables -A "$INPUT_CHAIN" -p tcp -m multiport --dports 22,80 -j ACCEPT

iptables -C OUTPUT -p icmp --icmp-type echo-reply -j "$CHAIN" 2>/dev/null || \
    iptables -I OUTPUT 1 -p icmp --icmp-type echo-reply -j "$CHAIN"
iptables -C INPUT -p tcp -j "$INPUT_CHAIN" 2>/dev/null || \
    iptables -I INPUT 1 -p tcp -j "$INPUT_CHAIN"

printf 'ws1: ICMP echo replies are dropped by the first matching rule.\n'
