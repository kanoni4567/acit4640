#!/bin/bash
PXE_SSH_PORT="12222"
PXE_IP="192.168.230.200"
export PXE_SSH_PORT PXE_IP
./setup/vbox_setup.sh

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

configure_pxe_machine () {
    ssh -i ~/.ssh/acit_admin_id_rsa admin@localhost\
        -p "$PXE_SSH_PORT"\
        "sudo chmod 755 /var/www/lighttpd; sudo chown admin /var/www/lighttpd/files;\
        sudo sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers"
    scp -i ~/.ssh/acit_admin_id_rsa -P "$PXE_SSH_PORT" ./acit_admin_id_rsa.pub admin@localhost:/var/www/lighttpd/files/public_key
}

# configure_pxe_machine
