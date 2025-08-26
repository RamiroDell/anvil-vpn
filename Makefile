# Makefile opcional para instalar/desinstalar rápidamente
PREFIX=/usr/local
SYSTEMD_DIR=/etc/systemd/system

install:
	install -Dm0755 scripts/vpn_killswitch.sh $(PREFIX)/sbin/vpn_killswitch.sh
	install -Dm0644 systemd/vpn-killswitch.service $(SYSTEMD_DIR)/vpn-killswitch.service
	systemctl daemon-reload
	systemctl enable --now vpn-killswitch.service

uninstall:
	systemctl disable --now vpn-killswitch.service || true
	rm -f $(PREFIX)/sbin/vpn_killswitch.sh
	rm -f $(SYSTEMD_DIR)/vpn-killswitch.service
	systemctl daemon-reload
