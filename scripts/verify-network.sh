#!/usr/bin/env bash

set -u

section() {
    printf '\n== %s ==\n' "$1"
}

run_if_available() {
    local command_name="$1"
    shift
    if command -v "$command_name" >/dev/null 2>&1; then
        "$command_name" "$@" || true
    else
        printf 'WARN: %s is not installed\n' "$command_name" >&2
    fi
}

section "IPv4 interfaces"
run_if_available ip -brief -4 address

section "Routing table"
run_if_available ip -4 route

section "IP forwarding"
if [[ -r /proc/sys/net/ipv4/ip_forward ]]; then
    printf 'net.ipv4.ip_forward = %s\n' "$(</proc/sys/net/ipv4/ip_forward)"
fi

section "Firewall"
if (( EUID == 0 )); then
    run_if_available iptables -S
    run_if_available iptables -t nat -S
else
    printf 'Run with sudo to inspect iptables rules.\n'
fi

section "DHCP leases"
if [[ -r /var/lib/dhcp/dhclient.leases ]]; then
    tail -n 20 /var/lib/dhcp/dhclient.leases
else
    printf 'No readable dhclient lease file found.\n'
fi

section "Listening TCP ports"
run_if_available ss -lnt

section "Optional peer checks"
for host in ${DO2_PEERS:-}; do
    if ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
        printf 'PASS: %s is reachable\n' "$host"
    else
        printf 'WARN: %s did not answer ICMP\n' "$host" >&2
    fi
done
