# OpenVPN + Kill‑Switch (iptables) para Kali Linux

**Objetivo:** forzar que *todas* las conexiones de la VM salgan **exclusivamente** a través de una VPN (OpenVPN).  
Si el túnel cae, **no hay Internet**: el *kill‑switch* bloquea tráfico y DNS fuera de `tun0`.

## Características
- Reglas **iptables** con política *deny‑all* y excepciones mínimas.
- Modo **resistente a rotación de IP** del nodo VPN: permite el *handshake* sólo al **proceso** de OpenVPN (por UID), no a una IP fija.
- Servicio **systemd** para aplicar reglas de forma automática antes de levantar la VPN.
- Plantilla de cliente OpenVPN (sin credenciales ni endpoints reales).
- Documentación en español, lista para copiar/instalar.

> **Aviso**: No se incluyen `.ovpn` reales ni credenciales. Úsalo sólo en laboratorios o entornos con autorización explícita.

## Arquitectura (resumen)
```
VM (eth0) ──► [iptables: OUTPUT DROP]
           └─► Permitir handshake (udp/80) SOLO al proceso OpenVPN (root/nobody) por eth0
           └─► TODO el tráfico real va por tun0 (VPN)
           └─► IPv6 bloqueado por defecto (se puede ajustar)
```

## Requisitos
- Kali/Debian/Ubuntu con `systemd`.
- Paquetes: `openvpn`, `resolvconf`, `iptables`/`ip6tables`.
- Privilegios de `sudo` para instalar scripts y servicios.

## Instalación rápida
```bash
# 1) Copia el script del kill-switch
sudo cp scripts/vpn_killswitch.sh /usr/local/sbin/
sudo chmod +x /usr/local/sbin/vpn_killswitch.sh

# 2) Instala el servicio systemd
sudo cp systemd/vpn-killswitch.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now vpn-killswitch.service

# 3) Configura OpenVPN (cliente)
sudo mkdir -p /etc/openvpn/client
sudo cp openvpn/example-client.conf /etc/openvpn/client/lab.conf
# Crea archivo de credenciales (NO subas esto a Git)
echo "USER_OVPN" | sudo tee /etc/openvpn/credentials >/dev/null
echo "PASS_OVPN" | sudo tee -a /etc/openvpn/credentials >/dev/null
sudo chmod 600 /etc/openvpn/credentials
# Ajusta lab.conf: auth-user-pass /etc/openvpn/credentials

# 4) Arranca el cliente al boot
sudo systemctl enable --now openvpn-client@lab

# 5) Verifica
curl -s ifconfig.me; echo
ip a show tun0
```

## Uso
```bash
# Conectar / desconectar / reiniciar la VPN
sudo systemctl start openvpn-client@lab
sudo systemctl stop openvpn-client@lab
sudo systemctl restart openvpn-client@lab

# Estado y autostart
systemctl status -n 30 openvpn-client@lab
systemctl is-enabled openvpn-client@lab

# Reaplicar kill-switch
sudo systemctl restart vpn-killswitch.service
```

## Comprobaciones
```bash
# IP pública debe ser la de la VPN
curl -s ifconfig.me; echo

# Simular caída del túnel → no debe haber salida
sudo ip link set tun0 down
curl --max-time 5 ifconfig.me || echo "OK: sin salida"

# Levantar de nuevo
sudo systemctl restart openvpn-client@lab
sleep 3
curl -s ifconfig.me; echo
```

## Buenas prácticas
- Mantén el *kill‑switch* activo: **sin túnel = sin tráfico**.
- Ajusta `HANDSHAKE_PROTO_PORT` (p. ej. `udp/80`, `tcp/443`) si tu proveedor usa otro puerto/protocolo.
- Si OpenVPN usa un usuario dedicado, cambia los `--uid-owner` en el script por ese UID.

## Licencia
Este proyecto se distribuye bajo la licencia MIT. Ver [LICENSE](LICENSE).

---
© 2025. Proyecto educativo. Uso responsable y autorizado.
