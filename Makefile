all: install

.PHONY: install
install:
	stat ephemeral-disk > /dev/null 2>&1 || (echo "ephemeral-disk file not found" ; exit 1)
	stat ephemeral-units.service > /dev/null 2>&1 || (echo "ephemeral-units.service file not found" ; exit 1)
	install -d /etc/ephemeral-scripts/
	install -m 750 ephemeral-disk_start.sh /etc/ephemeral-scripts/
	install -m 750 ephemeral-disk_stop.sh /etc/ephemeral-scripts/
	install -m 750 ephemeral-list.sh /etc/ephemeral-scripts/
	install -m 644 ephemeral-list.service /etc/systemd/system/
	install -m 644 ephemeral-disk.service /etc/systemd/system/
	install -m 644 mnt-data.mount /etc/systemd/system/
	install -m 644 ephemeral-units.service /etc/systemd/system/
	install -m 644 ephemeral-disk /etc/default/
	systemctl daemon-reload

.PHONY: uninstall
uninstall:
	rm -f /etc/ephemeral-scripts/ephemeral-list.sh
	rm -f /etc/ephemeral-scripts/ephemeral-disk_start.sh
	rm -f /etc/ephemeral-scripts/ephemeral-disk_stop.sh
	rmdir /etc/ephemeral-scripts/
	rm -f /etc/systemd/system/ephemeral-disk.service
	rm -f /etc/systemd/system/mnt-data.mount
	rm -f /etc/systemd/system/ephemeral-units.service
	rm -f /etc/default/ephemeral-disk
	systemctl daemon-reload

.PHONY: enable
enable:
	systemctl enable ephemeral-list.service
	systemctl enable ephemeral-disk.service
	systemctl enable mnt-data.mount
	systemctl enable ephemeral-units.service

.PHONY: disable
disable:
	systemctl disable ephemeral-list.service
	systemctl disable ephemeral-units.service
	systemctl disable mnt-data.mount
	systemctl disable ephemeral-disk.service

.PHONY: start
start:
	systemctl start ephemeral-list.service
	systemctl start ephemeral-disk.service
	systemctl start mnt-data.mount
	systemctl start ephemeral-units.service

.PHONY: stop
stop:
	systemctl stop ephemeral-list.service
	systemctl stop ephemeral-units.service
	systemctl stop mnt-data.mount
	systemctl stop ephemeral-disk.service
