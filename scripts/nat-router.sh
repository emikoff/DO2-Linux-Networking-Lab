#!/usr/bin/env bash

set -euo pipefail

readonly TRANSIT_IFACE="${DO2_TRANSIT_IFACE:-enp0s3}"
readonly LAN_IFACE="${DO2_LAN_IFACE:-enp0s8}"
readonly ROUTER_IP="${DO2_ROUTER_IP:-10.100.0.12}"
readonly WEB_SERVER="${DO2_WEB_SERVER:-10.20.0.20}"

if (( EUID != 0 )); then
    printf 'Run as root: sudo %s\n' "$0" >&2
    exit 1
fi

sysctl -w net.ipv4.ip_forward=1 >/dev/null

iptables -C FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -C FORWARD -i "$LAN_IFACE" -o "$TRANSIT_IFACE" -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i "$LAN_IFACE" -o "$TRANSIT_IFACE" -j ACCEPT
iptables -C FORWARD -i "$TRANSIT_IFACE" -o "$LAN_IFACE" -p tcp \
    -d "$WEB_SERVER" --dport 80 -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i "$TRANSIT_IFACE" -o "$LAN_IFACE" -p tcp \
        -d "$WEB_SERVER" --dport 80 -j ACCEPT

iptables -t nat -C POSTROUTING -o "$TRANSIT_IFACE" -j SNAT \
    --to-source "$ROUTER_IP" 2>/dev/null || \
    iptables -t nat -A POSTROUTING -o "$TRANSIT_IFACE" -j SNAT \
        --to-source "$ROUTER_IP"
iptables -t nat -C PREROUTING -i "$TRANSIT_IFACE" -p tcp --dport 8080 \
    -j DNAT --to-destination "$WEB_SERVER:80" 2>/dev/null || \
    iptables -t nat -A PREROUTING -i "$TRANSIT_IFACE" -p tcp --dport 8080 \
        -j DNAT --to-destination "$WEB_SERVER:80"

printf 'NAT configured: %s:8080 -> %s:80\n' "$ROUTER_IP" "$WEB_SERVER"
