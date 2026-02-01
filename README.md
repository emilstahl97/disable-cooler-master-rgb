## disable-cooler-master-rgb

This repository just ships a helper script that installs the dependencies for [`cm-rgb`](https://github.com/landrash/cm-rgb) and switches Cooler Master RGB lighting off.

### Usage

1. Make sure the script has execute permissions: `chmod +x disable-cooler-master-rgb.sh`
2. Run it as your normal user (it will use `sudo` for the system packages):  
   `./disable-cooler-master-rgb.sh`

The script will create a per-user virtual environment and then power down the RGB channels via the `cm-rgb` controller.
