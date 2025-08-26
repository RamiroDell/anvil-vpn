# TROUBLESHOOTING

### `tun0` no existe
- Revisa el servicio:
  ```bash
  systemctl status -n 60 openvpn-client@lab
  journalctl -u openvpn-client@lab -n 100 --no-pager
  ```
- Verifica `proto/puerto` del `.conf` y conectividad al endpoint.
- Asegura `resolvconf` activo y hooks:
  ```
  script-security 2
  up /etc/openvpn/update-resolv-conf
  down /etc/openvpn/update-resolv-conf
  ```

### `Connection refused`
- El puerto/protocolo no coincide. Ajusta `proto` (udp/tcp) y el puerto del `remote`.
- Comprueba que tu red/ISP/Firewall no bloqueen ese puerto.

### Fugas DNS
- Verifica que `/etc/resolv.conf` apunte al DNS del túnel al conectar.
- Asegura `resolvconf` y los hooks `update-resolv-conf`.

### Sin Internet al apagar la VPN
- Es el **comportamiento esperado**: el *kill‑switch* bloquea todo fuera del túnel.
- Para salir temporalmente sin VPN, **detén el servicio** y resetea reglas:
  ```bash
  sudo systemctl stop vpn-killswitch.service
  sudo iptables -F && sudo iptables -P INPUT ACCEPT && sudo iptables -P FORWARD ACCEPT && sudo iptables -P OUTPUT ACCEPT
  sudo ip6tables -F && sudo ip6tables -P INPUT ACCEPT && sudo ip6tables -P FORWARD ACCEPT && sudo ip6tables -P OUTPUT ACCEPT
  ```
