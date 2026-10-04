#!/bin/bash

# Add linux-surface repository to pacman.conf
echo -e "\n[linux-surface]\nServer = https://pkg.surfacelinux.com/arch/\n" >> /etc/pacman.conf

# Add and sign the repository keys
curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | pacman-key --add -
pacman-key --lsign-key 56C055A9438C3B1E403432B254E44E470C9990DE

# Update system and install Surface packages, drivers, and audio/Wi-Fi tools
pacman -Syu --noconfirm
pacman -S --noconfirm linux-surface linux-surface-headers surface-dtx iptsd surface-secureboot-ctl \
nvidia-dkms nvidia-utils opencl-nvidia lib32-nvidia-utils supergfxctl \
pipewire pipewire-pulse pipewire-alsa wireplumber intel-media-driver libva-intel-driver iw wireless-regdb

# Configure Wi-Fi power-saving tweaks
echo "options mwifiex_pcie disable_auto_ds=1" > /etc/modprobe.d/mwifiex.conf
echo -e "[connection]\nwifi.powersave = 2" > /etc/NetworkManager/conf.d/turnoff-powersave.conf

# Create a post-boot cleanup script
echo -e "#!/bin/sh\nrm -rf /tmp/*\npacman -Sc --noconfirm\nif command -v yay >/dev/null; then user_var=\$(logname); sudo -u \$user_var yay -Sc --noconfirm; fi" > /etc/initcpio/post-boot-cleanup.sh
chmod +x /etc/initcpio/post-boot-cleanup.sh

# Create a systemd service for the cleanup script
echo -e "[Unit]\nDescription=Automated Boot Cleanup\nAfter=local-fs.target\n\n[Service]\nType=oneshot\nExecStart=/etc/initcpio/post-boot-cleanup.sh\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/boot-cleanup.service

# Reload systemd and enable necessary services
systemctl daemon-reload
systemctl enable --now surface-dtx supergfxctl boot-cleanup.service

# Completion message
echo -e "\n\033[1;32mSetup complete! Run 'sudo surface-secureboot-ctl enroll' if Secure Boot is enabled, then reboot.\033[0m\n"
