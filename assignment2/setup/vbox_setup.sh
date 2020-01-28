#!/bin/bash

# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/d/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="net4640auto"
VM_NAME="VM4640auto"
SSH_PORT="8022"
WEB_PORT="8000"
PXE_SSH_PORT="12222"
SUBNET="192.168.233.0/24"
PORT_RULE_SSH="my_ssh_rule:tcp:[127.0.0.1]:$SSH_PORT:[192.168.233.10]:22"
PORT_RULE_HTTP="my_http_rule:tcp:[127.0.0.1]:$WEB_PORT:[192.168.233.10]:80"
PORT_RULT_PXE_SSH="pxe_ssh_rule:tcp:[127.0.0.1]:$PXE_SSH_PORT:[192.168.230.200]:22"
STORAGE_CONTROLLER_NAME="SataController"
# ISO_PATH="C:\\Users\\cuish\\Documents\\acit4640-provision\\CentOS-7-x86_64-Minimal-1908.iso"


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
        --port-forward-4 "$PORT_RULE_HTTP"
}

create_vm () {
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME"\
        --memory 1536\
        --nic1 natnetwork\
        --nat-network1 "$NET_NAME"\
        --cableconnected1 on\
        --audio none\
        --boot1 disk\
        --boot2 net\
        --boot3 none
    
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

    # vbmg storageattach "$VM_NAME"\
    #     --storagectl "$STORAGE_CONTROLLER_NAME"\
    #     --port 1\
    #     --device 0\
    #     --type dvddrive\
    #     --medium "$ISO_PATH"
}

configure_pxe_machine () {
    ssh -i ~/.ssh/acit_admin_id_rsa admin@localhost\
        -p "$PXE_SSH_PORT"\
        "sudo chmod 755 /var/www/lighttpd; sudo chown admin /var/www/lighttpd/files;\
        sudo sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers"
    scp -i ~/.ssh/acit_admin_id_rsa -P "$PXE_SSH_PORT" ./acit_admin_id_rsa.pub admin@localhost:/var/www/lighttpd/files/public_key
}

echo "Starting script..."

clean_all
create_network
create_vm
configure_pxe_machine

echo "DONE!"