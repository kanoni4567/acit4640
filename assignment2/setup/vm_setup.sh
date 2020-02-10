#!/bin/bash

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P "$SSH_PORT" -i ~/.ssh/acit_admin_id_rsa -r "$SETUP_FOLDER" admin@localhost:/home/admin/
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$SSH_PORT" -i ~/.ssh/acit_admin_id_rsa admin@localhost "sudo /home/admin/setup/install_script.sh"
