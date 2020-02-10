#!/bin/bash

VM_NAME="VM4640auto"
PXE_SERVER="PXE4640"
NET_NAME="net4640auto"

# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

# Create the NAT network in VirtualBox (vbox_setup)
# Create the TODO virtual machine, connected to the NET_4640 network, ready to boot from the network
./vbox_setup.sh

# Make sure the PXE server is connected to the right NAT network
vbmg modifyvm "$PXE_SERVER" \
    --nat-network1 "$NET_NAME" \


# Start the PXE server
vbmg startvm "$PXE_SERVER"

# Copy the necessary files to the PXE server
while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p 12222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                scp -P 12222 -i ~/.ssh/acit_admin_id_rsa -r ./install/ks.cfg admin@localhost:/var/www/lighttpd/files
                scp -P 12222 -i ~/.ssh/acit_admin_id_rsa -r ./install/acit_admin_id_rsa.pub admin@localhost:/var/www/lighttpd/files
                break
        fi
done


# Boot the TODO virtual machine
vbmg startvm "$VM_NAME"

# Turn off the PXE server when the installation is complete
while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p 12022 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "Waiting for CentOS to install..."
                sleep 10
        else
                vbmg controlvm "$PXE_SERVER" acpipowerbutton
                ./install_script.sh
                break
        fi
done