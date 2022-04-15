#!/bin/bash

# Created and maintained by the DCGPU-Netowrking team.
# Last update - 2022-02-15-12:20

Help()
{
    echo
    echo "======================================="
    echo "Syntax : sudo ./get_gpuinfo.sh"
    echo
    echo "- Runs on the server under test"
    echo "- No argrument required"
    echo "- Saves output and dmesg in users home directory"
    echo "- /home/user/$(hostname).gpuinfo.<date>"
    echo "- /tmp/suer/$(hostname).dmesg.<date>"
    echo "======================================="
}

while getopts ":h" option; do
        case $option in
                h | help) Help
                exit;;
        esac
done

scriptuser=root
:
rundate=$(date "+%Y-%m-%d_%H%M%S")
#filepath="/home/$scriptuser/$(hostname).gpuinfo.$rundate"
filepath="/root/$(hostname).gpuinfo.$rundate"

exec &> >(tee $filepath ) # save stdout stderr to file. No output on screen
#exec >$filepath
#{
echo "===================================="
echo  "=== date === "
echo "===================================="
echo
echo
echo "===================================="
echo "=== PCI verbose output ==="
echo "===================================="
echo
echo " === command ran: lspci -vvvs <pci id> ==="
for i in $(lspci | grep Display | awk '{print$1}'); do echo === $i ===; lspci -vvvs $i; done

echo
echo "===================================="
echo "=== rocm-smi info  ==="
echo "===================================="
echo
echo "command ran: rocm-smi --showallinfo "
rocm-smi --showallinfo

echo
echo "===================================="
echo "=== rocm-bandwidth-test  ==="
echo "===================================="
echo
echo "command ran: rocm-bandwidth-test "
echo

/opt/rocm/bin/rocm-bandwidth-test -t
/opt/rocm/bin/rocm-bandwidth-test

echo
echo "===================================="
echo "=== Run PCI GPU Link status ===="
echo "===================================="
echo
echo "=== Run PCI GPU Link status extended === "
echo
#for i in $(lspci | grep Display | awk '{print$1}'); do echo === $i ===; lspci -vvvs $i| grep -iE "LnkCap|LnkSta|CESta|ATS|MaxReadReq"; done
for i in $(lspci | grep Display | awk '{print$1}'); do echo === $i ===; out=($(lspci -s $i -PP| awk '{print$1}'| tr / " ")); for j in "${out[@]}"; do  echo "- $j -" $(lspci -vvs $j | grep -E "LnkSta:|CESta|ATS|MaxReadReq"); done ; done
echo
echo "=== Run PCI GPU Link status consise === "
echo
for i in $(sudo lspci | grep Display | awk '{print$1}'); do echo === $i ===; out=($(sudo lspci -s $i -PP| awk '{print$1}'| tr / " ")); for j in "${out[@]}"; do  echo "- $j -" $(sudo lspci -vvs $j | grep -E "LnkSta:"); done ; done

echo
echo
echo "===================================="
echo "=== Run GPU stress test from ==="
echo "=== rocm Validation Suite    ==="
echo "===================================="
echo

rvspath="/opt/rocm/rvs"
sudo $rvspath/conf/deviceid.sh $rvspath/conf/gst_single.conf
sudo $rvspath/rvs -c $rvspath/conf/gst_single.conf -d 3
echo
echo "===================================="
echo "=== Re-Run PCI GPU Link status ===="
echo "===================================="
echo
echo "=== Re-Run PCI GPU Link status extended === "
echo
#for i in $(lspci | grep Display | awk '{print$1}'); do echo === $i ===; lspci -vvvs $i| grep -iE "LnkCap|LnkSta|CESta|ATS|MaxReadReq"; done
for i in $(lspci | grep Display | awk '{print$1}'); do echo === $i ===; out=($(lspci -s $i -PP| awk '{print$1}'| tr / " ")); for j in "${out[@]}"; do  echo "- $j -" $(lspci -vvs $j | grep -E "LnkSta:|CESta|ATS|MaxReadReq"); done ; done
echo
echo "=== Run PCI GPU Link status consise === "
echo
for i in $(sudo lspci | grep Display | awk '{print$1}'); do echo === $i ===; out=($(sudo lspci -s $i -PP| awk '{print$1}'| tr / " ")); for j in "${out[@]}"; do  echo "- $j -" $(sudo lspci -vvs $j | grep -E "LnkSta:"); done ; done

echo
echo
echo "===================================="
echo "=== Saving dmesg -T   ==="
echo "===================================="
echo
dmesg -T >> /root/$(hostname).dmesg.$rundate
#}  | tee > $filepath 2>&1
exec > /dev/tty
