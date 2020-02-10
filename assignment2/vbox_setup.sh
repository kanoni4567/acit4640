#!/bin/bash

# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="net4640auto"
VM_NAME="VM4640auto"

#SSH_PORT="8022"
#WEB_PORT="8000"

SSH_PORT="12022"
WEB_PORT="12080"
PXE_SSH_PORT="12222"

SUBNET="192.168.230.0/24"
PORT_RULE_SSH="my_ssh_rule:tcp:[127.0.0.1]:$SSH_PORT:[192.168.230.10]:22"
PORT_RULE_HTTP="my_http_rule:tcp:[127.0.0.1]:$WEB_PORT:[192.168.230.10]:80"
PORT_RULE_PXE="my_pxe_ssh_rule:tcp:[127.0.0.1]:$PXE_SSH_PORT:[192.168.230.200]:22"
STORAGE_CONTROLLER_NAME="SataController"
ISO_PATH="D:\\OS Distributions\\CentOS-7-x86_64-Minimal-1908.iso"


# This function will clean the NAT network and the virtual machine
clean_all () {
    vbmg natnetwork remove --netname "$NET_NAME"
    vbmg unregistervm "$VM_NAME" --delete
}

create_network () {
    vbmg natnetwork add --netname "$NET_NAME" \
        --network "$SUBNET"\
        --enable\
        --dhcp off\
        --port-forward-4 "$PORT_RULE_SSH"\
        --port-forward-4 "$PORT_RULE_HTTP"\
        --port-forward-4 "$PORT_RULE_PXE"
}

create_vm () {
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME"\
        --memory 2048\
        --vram 12\
        --nic1 natnetwork\
        --nat-network1 "$NET_NAME"\
        --cableconnected1 on\
        --audio none\
        --boot1 disk\
        --boot2 net\
        --boot3 none\
        --boot4 none
    
    SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
    VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
    VM_DIR=$(dirname "$VBOX_FILE")

    VDI_PATH="$VM_DIR\\$VM_NAME".vdi
    echo VDI location: "$VDI_PATH"

    vbmg createmedium disk --filename "$VDI_PATH"\
        --size 10240
    
    vbmg storagectl "$VM_NAME"\
        --name "$STORAGE_CONTROLLER_NAME"\
        --add sata

    vbmg storageattach "$VM_NAME"\
        --storagectl "$STORAGE_CONTROLLER_NAME"\
        --port 0\
        --device 0\
        --type hdd\
        --medium "$VDI_PATH"

    vbmg storageattach "$VM_NAME"\
        --storagectl "$STORAGE_CONTROLLER_NAME"\
        --port 0\
        --device 0\
        --type hdd\
        --medium "$VDI_PATH"

    vbmg storageattach "$VM_NAME"\
        --storagectl "$STORAGE_CONTROLLER_NAME"\
        --port 1\
        --device 0\
        --type dvddrive\
        --medium "$ISO_PATH"
}

echo "Starting script..."

clean_all
create_network
create_vm

echo "DONE!"