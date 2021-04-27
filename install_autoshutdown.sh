#!/bin/bash
#
# Install an auto shutdown service
# ================================
# - check frequently the number of clients connected to the Access Point
# - if the time since the last client disconnected exceeds the timeout, the raspberry pi is shutting down
#
# zbchristian 2021

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
DEF="\e[0m"

echo -e "${GREEN}\n\nInstall an automatic shutdown service${DEF}\n"

echo -e "${GREEN}"
echo    "The Raspberry Pi will be shut down, if no client was connected to the Access Point for a given time"
read -p "Enter the timeout in minutes ( default 60min ) :" timeout < /dev/tty
echo -e "${DEF}"

[ -n "$timeout" ] && [ "$timeout" -eq "$timeout" ] 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}No valid given for the timeout - fall back to 60min\n${DEF}"
    timeout=60
fi

servicefile="/usr/lib/systemd/system/autoshutdown.service"
echo "Create service file $servicefile ..."

sudo tee $servicefile << EOF > /dev/null
[Unit]
Description=Shutdown the Raspberry Pi when no clients are connected to AP (after timeout)
After=network.target
PartOf=hostapd.service

[Service]
Type=simple
ExecStart=/usr/local/sbin/autoShutdown.sh $timeout
Restart=on-failure

[Install]
Alias=autoshutdown.service
RequiredBy=hostapd.service
EOF

scriptfile="/usr/local/sbin/autoShutdown.sh"
echo "Create script file $scriptfile ..."
sudo tee $scriptfile << EOF > /dev/null
#!/bin/bash

function sigquit {
    kill \$!
    exit 0
}

trap 'sigquit' QUIT
trap 'sigquit' SIGINT

timeout=60
if [ "\$1" -eq "\$1" ] 2>/dev/null; then
    timeout=\$1
fi
logger "\$0 started with timeout \$timeout minutes..."
sleep 300
apDevice=\$(iwconfig 2> /dev/null | sed -rn 's/^([a-zA-Z0-9]*).*mode:master.*/\1/ip')
if [ -z \$apDevice ]; then
   logger "\$0 : no Access Point device found - exit" 
   exit
fi
timeout=\$((60*timeout))
lastTime=0
while true
do
    numClients=\$(/sbin/iw dev \$apDevice station dump | /bin/grep -oE "([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}" | /usr/bin/wc)
    if [[ ! \$numClients =~ \s*0(.*) ]] || [ \$lastTime -eq 0 ]; then
        lastTime=\$(cat /proc/uptime | grep -o '^[0-9]*')
    fi
    tidle=\$((\$( cat /proc/uptime | grep -o '^[0-9]*') - \$lastTime))
    if [[ \$tidle -gt \$timeout ]]; then
        logger "\$0: timer expired - shutdown now"
        sudo halt
    fi
    sleep 10
done

EOF

echo "Enable and start service autoshutdown ..."
sudo chmod a+x $scriptfile

sudo systemctl enable autoshutdown
sudo systemctl start autoshutdown

echo -e "${GREEN}\nTo disable the service again:${DEF}\n"
echo -e "\$sudo systemctl stop autoshutdown\n\$sudo systemctl disable autoshutdown\n"
