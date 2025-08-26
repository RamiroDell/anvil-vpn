# QUICKSTART

## Requisitos
```bash
sudo apt update
sudo apt install -y openvpn resolvconf iptables
sudo systemctl enable --now resolvconf
```

## Instalación
```bash
# Script de kill-switch
sudo cp scripts/vpn_killswitch.sh /usr/local/sbin/
sudo chmod +x /usr/local/sbin/vpn_killswitch.sh

# Servicio systemd
sudo cp systemd/vpn-killswitch.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now vpn-killswitch.service
```

## Cliente OpenVPN
1. Descarga tu archivo `.ovpn` del proveedor (no lo subas al repo).  
2. Crea `/etc/openvpn/credentials` con usuario/clave OpenVPN (no el login web).  
3. Copia la plantilla a `/etc/openvpn/client/lab.conf` y ajusta:
   ```
   auth-user-pass /etc/openvpn/credentials
   proto udp
   dev tun
   script-security 2
   up /etc/openvpn/update-resolv-conf
   down /etc/openvpn/update-resolv-conf
   ```
4. Habilita y arranca:
   ```bash
   sudo systemctl enable --now openvpn-client@lab
   ```

## Pruebas
```bash
curl -s ifconfig.me; echo
sudo ip link set tun0 down
curl --max-time 5 ifconfig.me || echo "OK: sin salida"
sudo systemctl restart openvpn-client@lab
sleep 3
curl -s ifconfig.me; echo
```
