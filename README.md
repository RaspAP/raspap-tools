# Helper Scripts for RaspAP 
To run a script
```
$ wget https://raw.githubusercontent.com/RaspAP/raspap-tools/main/install_raspap_ram_wlan.sh
$ chmod +x install_raspap_ram_wlan.sh
$ ./install_raspap_ram_wlan.sh
```
Follow the instructions.

## Configure Raspberry Pi OS, install drivers and start the RaspAP installer
The script `install_raspap_ram_wlan.sh` configures Raspberry Pi OS for a (nearly) read-only operation, allows to install additional Wifi drivers and starts the RaspAP installer ( https://install.raspap.com ). See details about the Raspberry Pi OS configuration and driver installation below.

## Install missing WLAN driver modules
A standard nuisance of Raspberry Pi OS is, that drivers for a lot of WLAN devices are missing. This is especially true for newer Realtek based devices. 

### Compile and install drivers from source
The script `install_wlan_drivers.sh` tries to detect the WIFI card and extracts the required source for some very common drivers from Github (rtl8814au, rtl8812au, rtl88x2bu, rtl8821cu). The source is compiled and the installation done via DKMS. This ensures, that the driver is automatically recompiled, when the kernel version is changing.
Depending on the raspberry pi version, this can take a long time.

## Raspberry Pi OS with substantially reduced SD-Card write access
Utilizing a Raspberry PI as an access point, requires a reliable operation over a long period of time. Switching the Raspberry PI off without a regular shutdown procedure might lead to a damaged system. Writing lots of logging and temporary data to the SD-card will shorten the lifetime of the system. 

Moving logging and temporary data to a RAM based files system can minimize the risk and extend the lifetime of the SD-card substantially.

The script `raspian_min_write.sh` replaces the default logging service, moves temporary file locations to RAM and switches off the file system check and swap in `/boot/config.txt`. By default the file system is still in read/write mode, so RaspAP settings can be saved. 
The remaing access to the SD-card can be checked with the tool `iotop -aoP`. 


## Automatic Shutdown when idle
Running a battery powered RaspAP makes energy management mandatory. The script `install_autoshutdown.sh` installs a system service, which checks every 10 seconds the number of 
client devices connected to the access point. If the time since the last client disconnected exceeds a predefined number of minutes, the shutdown process of the Raspberry Pi 
is initiated

The script includes the service file `autoshutdown.service` as well as the required script `autoShutdown.sh` written to `/usr/local/sbin`. The install script is asking for the 
timeout in minutes. 
  
