#!/usr/bin/env bash
# Kill-switch iptables para forzar salida SOLO por VPN (owner-based, robusto ante rotación de IP)
# Uso: ejecutar como root (systemd aplica esto antes de levantar OpenVPN).
set -euo pipefail

# Interfaces y parámetros (puedes exportarlos como variables de entorno al llamar desde systemd)
WAN_IF="${WAN_IF:-eth0}"          # Interfaz de salida de la VM (NAT): eth0/ens33...
VPN_IF="${VPN_IF:-tun0}"          # Interfaz de túnel OpenVPN
HANDSHAKE_PROTO_PORT="${HANDSHAKE_PROTO_PORT:-udp/80}"  # udp/80 por defecto

# Derivar protocolo y puerto
PROTO="${HANDSHAKE_PROTO_PORT%/*}"
PORT="${HANDSHAKE_PROTO_PORT#*/}"

# Limpieza de reglas existentes
iptables -F; iptables -X; iptables -t nat -F; iptables -t mangle -F
ip6tables -F; ip6tables -X

# Políticas por defecto: DROP (bloqueo total salvo excepciones)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Permitir loopback y conexiones establecidas
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir el handshake SOLO al proceso OpenVPN (root y nobody) por la interfaz WAN
NOBODY_UID="$(id -u nobody 2>/dev/null || echo 65534)"
iptables -A OUTPUT -o "$WAN_IF" -p "$PROTO" --dport "$PORT" -m owner --uid-owner 0 -j ACCEPT
iptables -A OUTPUT -o "$WAN_IF" -p "$PROTO" --dport "$PORT" -m owner --uid-owner "$NOBODY_UID" -j ACCEPT

# Todo el tráfico real SOLO por el túnel
iptables -A OUTPUT -o "$VPN_IF" -j ACCEPT
iptables -A INPUT  -i "$VPN_IF" -j ACCEPT

# Endurecer: denegar UDP directo fuera del túnel (opcional; ya cubierto por OUTPUT DROP)
iptables -A OUTPUT -o "$WAN_IF" -p udp -j DROP

# IPv6: política DROP + excepciones mínimas (ajusta si tu VPN enruta IPv6)
ip6tables -A INPUT  -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT
ip6tables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT  -i "$VPN_IF" -j ACCEPT
ip6tables -A OUTPUT -o "$VPN_IF" -j ACCEPT

echo "[+] Kill-switch aplicado (WAN_IF=$WAN_IF, VPN_IF=$VPN_IF, HANDSHAKE=$HANDSHAKE_PROTO_PORT)"
