## disable-cooler-master-rgb

This repository just ships a helper script that installs the dependencies for [`cm-rgb`](https://github.com/landrash/cm-rgb) and switches Cooler Master RGB lighting off.

### Usage

1. Make sure the script has execute permissions: `chmod +x disable-cooler-master-rgb.sh`
2. Run it as your normal user (it will use `sudo` for the system packages):  
   `./disable-cooler-master-rgb.sh`

The script will create a per-user virtual environment and then power down the RGB channels via the `cm-rgb` controller.

`--apply-only` skips package installation and only powers the lighting down. The systemd service uses that mode.

### Boot

`systemd/disable-cooler-master-rgb.service` runs the script at startup. `udev/99-disable-cooler-master-rgb.rules` starts the same service when the Cooler Master USB device appears, including after the controller resets and turns the lighting back on.

The same unit can also be installed for your user. With `loginctl enable-linger` it starts at boot; otherwise it starts when your login session starts:

```bash
mkdir -p ~/.config/systemd/user
cp systemd/disable-cooler-master-rgb.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now disable-cooler-master-rgb.service
```

Install it system-wide so it runs at boot, before login (requires sudo):

```bash
sudo cp systemd/disable-cooler-master-rgb.service /etc/systemd/system/
sudo cp udev/99-disable-cooler-master-rgb.rules /etc/udev/rules.d/
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo systemctl enable --now disable-cooler-master-rgb.service
```
