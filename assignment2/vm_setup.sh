#!/bin/bash

scp  -r ./setup todoapp:/home/admin/
ssh todoapp "sudo /home/admin/setup/install_script.sh"