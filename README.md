# Helper Scripts for RaspAP 
To run a script
```
$ wget https://raw.githubusercontent.com/zbchristian/raspap-tools/main/install_raspap_ram_wlan.sh
$ chmod +x install_raspap_ram_wlan.sh
$ ./install_raspap_ram_wlan.sh
```
Follow the instructions.

## Configure Raspian, install drivers and start the RaspAP installer
The script `install_raspap_ram_wlan.sh` configures Raspian for a (nearly) read-only operation, allows to install additional Wifi driver modules and starts the RaspAP installer ( https://install.raspap.com ). See details about the Raspian configuration and driver installation below.

## Install missing WLAN driver modules
A standard nuisance of Raspian is, that drivers for a lot of WLAN devices are missing. This is especially true for Realtek based devices.

### Precompiled driver modules
The webpage http://downloads.fars-robotics.net by MrEngman provides a lot of pre-compiled WLAN driver modules for different Raspian kernel versions. In order to install multiple drivers in one go, the script `install_wlan_driver_modules.sh` provides a wrapper for the install script http://downloads.fars-robotics.net/wifi-drivers/install-wifi. The script asks to plug in one device at a time and starts the `install-wifi` script. You might have to rerun the installation, when a kernel update is done.

### Alternative: Compile and install drivers
If you prefer to compile drivers from scratch, the script `install_wlan_drivers_8812au_88x2bu.sh` extracts the source for two very common drivers (Realtek 8812au and 88x2bu) from Github. The source is compiled and the installation done via DKMS. This ensures, that the driver is automatically recompiled, when the kernel version is changing.
Depending on the raspberry pi version, this can take a long time.

## Raspian with substantially reduced SD-Card write access
Utilizing a Raspberry PI as an access point, requires a reliable operation over a long period of time. Switching the Raspberry PI off without a regular shutdown procedure might lead to a damaged system. Writing lots of logging and temporary data to the SD-card will shorten the lifetime of the system. 

Moving logging and temporary data to a RAM based files system can minimize the risk and extend the lifetime of the SD-card substantially.

The script `raspian_min_write.sh` replaces the default logging service, moves temporary file locations to RAM and switches off the file system check and swap in `/boot/config.txt`. By default the file system is still in read/write mode, so RaspAP settings can be saved. 
The remaing access to the SD-card can be checked with the tool `iotop -aoP`. 
