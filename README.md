# raspap-tools
Scripts to prepare the raspberry pi for RaspAP
==============================================

`create_RAM_version.sh` : modify the system services and file system in order to minimize the write access to the sd-card.

`install_wlan_driver_modules.sh` : Install the driver modules from http://downloads.fars-robotics.net . The scripts asks to plug in wlan devices one by one. These are precompiled modules. 

`install_wlan_drivers_8812au_88x2bu.sh` : Install the 8812au and 88x2bu Realtek wireless drivers. The sources are extracted from github repositories, compiled and installed. Depending on the raspberry pi version, this can take a long time.

`install_raspap_RAMonly.sh`: Configure the system for (nearly) RAM only operation, install additional Wifi drivers (calls `install_wlan_driver_modules.sh`) and run the RaspAP installer
