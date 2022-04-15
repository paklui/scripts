#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[0;31m'
BLUE='\e[1;34m'
NC='\e[m'
echo " ==== System/OS ==== "
#printf '\e[1;34m%-20s\e[m %s \n' "Kernel:" "$(uname -r)"
printf ''${BLUE}'%-20s'${NC}' %s \n' "Kernel:" "$(uname -r)"
printf ''${BLUE}'%-20s'${NC}' %s \n' "HostOS:" "$(cat /etc/os-release  | grep -i PRETTY_NAME)"
echo
printf ''${BLUE}'%-20s'${NC}' %s \n' "BIOS VERSION:" "$(dmidecode -s bios-version)"
printf ''${BLUE}'%-20s'${NC}' %s \n' "BIOS Release Date:" "$(dmidecode -s bios-release-date)"
echo
printf ''${BLUE}'%-20s'${NC}' %s \n' "Processor:" "$(dmidecode -s processor-version| uniq)"
printf ''${BLUE}'%-20s'${NC}' %s \t\n' "Processor Frequency:" "$(dmidecode -s processor-frequency | uniq)"
