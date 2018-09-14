#!/bin/bash

echo "Setting up sample data"
/opt/mattermost/bin/mattermost sampledata --seed 10 --teams 4 --users 30
echo "Setting up admin user"
/opt/mattermost/bin/mattermost user create --system_admin --email paul@mattermost.com --username admin --password admin

echo "Starting Mattermost!"
service mattermost start

IP_ADDR=`/sbin/ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`


printf '=%.0s' {1..80}
echo 
echo '                     VAGRANT UP!'
echo "GO TO http://${IP_ADDR}:8065 and log in with \`admin\`"
echo
printf '=%.0s' {1..80}