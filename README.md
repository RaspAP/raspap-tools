# Helper Scripts for RaspAP 
To run a script
```
$ wget https://raw.githubusercontent.com/zbchristian/raspap-tools/main/install_raspap_RAMonly.sh
$ chmod +x install_raspap_RAMonly.sh
$ ./install_raspap_RAMonly.sh
```
Follow the instructions.

## (Nearly) RAM only Raspian
Utilizing a Raspberry PI as an access point, requires a reliable operation over a long period of time. Switching the Raspberry PI off without a regular shutdown procedure might lead to a damaged system. Writing lots of logging and temporary data to the SD-card will shorten the lifetime of the system. 

Moving logging and temporary data to a RAM based files system can minimize the risk and extend the lifetime of the SD-card substantially.

The script `create_RAM_version.sh` will replaces the default logging service, moves temporary file locations to RAM and switches off the file check and swap in `/boot/config.txt`.  
The remaing access to the SD-card can be checked with the tool `iotop`. 

## Install missing WLAN driver modules
A standard nuisance of Raspian is, that drivers for a lot of WLAN devices are missing. This is especially true for Realtek based devices.

### Precompiled driver modules
The webpage http://downloads.fars-robotics.net by MrEngman provides a lot of pre-compiled WLAN driver modules for different Raspian kernel versions. In order to install multiple drivers in one go, the script `install_wlan_driver_modules.sh` provides a wrapper for the install script http://downloads.fars-robotics.net/wifi-drivers/install-wifi. The script asks to plug in one device at a time and starts the `install-wifi script`. You might have to rerun the installation, when a kernel update is done.

## Compile and install drivers
If you prefer to compile drivers from scratch, the script `install_wlan_drivers_8812au_88x2bu.sh` extracts the source for two very common drivers (Realtek 8812au and 88x2bu) from Github. The source is compiled and the installation done via DKMS. This ensures, that the driver is automatically recompiled, when the kernel version is changing.
Depending on the raspberry pi version, this can take a long time.

## Configure Raspian, install drivers and start the RaspAP installer
The script `install_raspap_RAMonly.sh` configures Raspian for a (nearly) RAM only operation (see below), installs additional Wifi driver modules and starts the RaspAP installer ( https://install.raspap.com ).
