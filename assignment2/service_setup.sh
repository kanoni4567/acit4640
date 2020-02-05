#!/bin/bash
VM_NAME="VM4640auto"
NET_NAME="net4640auto"
PXE_NAME="PXE4640"
PXE_SSH_PORT="12222"
SSH_PORT="12022"
SETUP_FOLDER="./setup"


vbmg () { /mnt/d/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }


create_vm_and_network () {
    PXE_IP="192.168.230.200"
    export PXE_SSH_PORT PXE_IP NET_NAME VM_NAME SSH_PORT
    ./setup/vbox_setup.sh
}

attach_pxe_to_network () {
    vbmg modifyvm "$PXE_NAME"\
        --nic1 natnetwork\
        --nat-network1 "$NET_NAME"\
        --cableconnected1 on
}

start_pxe_and_wait () {
    vbmg startvm "$PXE_NAME"
    while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p "$PXE_SSH_PORT" \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                echo "PXE server started!"
                break
        fi
    done
}

configure_pxe_machine () {
    ssh -i ~/.ssh/acit_admin_id_rsa admin@localhost\
        -p "$PXE_SSH_PORT"\
        "sudo chmod 755 /var/www/lighttpd; sudo chown -R admin /var/www/lighttpd/files;\
        sudo sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers"
    scp -i ~/.ssh/acit_admin_id_rsa -P "$PXE_SSH_PORT" ./setup/acit_admin_id_rsa.pub admin@localhost:/var/www/lighttpd/files/public_key
    scp -i ~/.ssh/acit_admin_id_rsa -P "$PXE_SSH_PORT" ./setup/ks.cfg admin@localhost:/var/www/lighttpd/files/ks.cfg
    scp -i ~/.ssh/acit_admin_id_rsa -P "$PXE_SSH_PORT" -r ./setup admin@localhost:/var/www/lighttpd/files/
}

start_vm_install_os_and_wait () {
    vbmg startvm "$VM_NAME"
    while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p "$SSH_PORT" \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "VM is not up, sleeping..."
                sleep 2
        else
                echo "VM started!"
                break
        fi
    done
}

install_app () {
    export SSH_PORT SETUP_FOLDER
    ./setup/vm_setup.sh
}

shutdown_pxe () {
    vbmg controlvm "$PXE_NAME" acpipowerbutton
}
# vbox setup
#     create vm network
#     port forwarding
# turn on pxe
#     wait for it

# copy files to pxe
# boot vm
#     install
#     post install 
#     reboot

# vm_setup
# turn off pxe




# PXE_SSH_PORT="12222"

create_vm_and_network
attach_pxe_to_network
start_pxe_and_wait
configure_pxe_machine
start_vm_install_os_and_wait
install_app
shutdown_pxe