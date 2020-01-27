#!/bin/bash

SCRIPT_PATH="/home/admin/setup"

sec_config () {
    setenforce 0
    sudo sed -i "s/enforcing/permissive/" /etc/selinux/config

    firewall-cmd --zone=public --add-port=80/tcp
    sudo firewall-cmd --zone=public --add-port=8080/tcp
    firewall-cmd --zone=public --add-port=443/tcp
    sudo firewall-cmd --runtime-to-permanent
    echo "Security configuration done"
}


# sudo nginx -s reload
# sudo sed -i "s/\/usr\/share\/nginx\/html;/\/home\/todo-app\/app\/public;/" /etc/nginx/nginx.conf
# sudo sed '/location \/ {.*\n*.*} a location /api/todos { proxy_pass http://localhost:8080; } ' /etc/nginx/nginx.conf

install_packages () {
    sudo yum -y install git
    echo "Installed git"
    sudo yum -y install nodejs
    echo "Installed nodejs"

    MONGODBREPOFILE="/etc/yum.repos.d/mongodb-org-4.2.repo"
MONGODBREPO="[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc"

    echo "$MONGODBREPO" | sudo tee $MONGODBREPOFILE
    sudo yum -y install mongodb-org
    sudo systemctl enable mongod && sudo systemctl start mongod

    sudo yum -y install nginx
    sudo cp "$SCRIPT_PATH/nginx.conf" /etc/nginx/nginx.conf
    sudo systemctl enable nginx && sudo systemctl start nginx
    echo "Installed and enabled mongo"
}

install_app_as_user () {
    APPUSER="todoapp"
    APPUSERPASSWORD="SomeVeryStrongPassword777666555dsua89y8ej9u0dsa!!!!"
    ADMINUSER="admin"
    CLONEFOLDER="app"
    CLONETARGET="/home/$APPUSER/$CLONEFOLDER"
    REPOSRC="https://github.com/timoguic/ACIT4640-todo-app.git"

    sudo adduser "$APPUSER"
    echo "$APPUSERPASSWORD" | sudo passwd --stdin "$APPUSER"
    chmod 755 /home/todoapp/

    if [ ! -d "$CLONETARGET" ]
    then
        git clone $REPOSRC $CLONETARGET
    else
        cd $CLONETARGET
        git pull $REPOSRC
    fi
    
    cd /home/todoapp/app
    npm install
    chown -R "$APPUSER" /home/todoapp/

    sed -i "s/CHANGEME/acit4640/" /home/todoapp/app/config/database.js
    echo "Installed todo app"
}

cofigure_node_service () {
    sudo cp "$SCRIPT_PATH/todoapp.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable todoapp
    sudo systemctl start todoapp
    echo "Configured todo app as service"
}

sec_config
install_packages
install_app_as_user
cofigure_node_service