#!/bin/bash

scp -P 12022 -i ~/.ssh/acit_admin_id_rsa -r ./setup admin@localhost:/home/admin/
ssh todoapp "sudo /home/admin/setup/install_script.sh"
