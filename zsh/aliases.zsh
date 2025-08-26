# Alias útiles (zsh)
alias myip='curl -s ifconfig.me; echo'
alias vpn-up='sudo systemctl restart vpn-killswitch.service && sudo systemctl restart openvpn-client@lab'
alias vpn-down='sudo systemctl stop openvpn-client@lab && echo "Kill-switch mantiene Internet bloqueado"'
