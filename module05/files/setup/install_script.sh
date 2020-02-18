#!/bin/bash

SCRIPT_PATH="/home/admin/setup"

sec_config () {
    setenforce 0
    sed -i "s/enforcing/permissive/" /etc/selinux/config

    firewall-cmd --zone=public --add-port=80/tcp
    firewall-cmd --zone=public --add-port=8080/tcp
    firewall-cmd --zone=public --add-port=443/tcp
    firewall-cmd --runtime-to-permanent
    echo "Security configuration done"
}


# nginx -s reload
# sed -i "s/\/usr\/share\/nginx\/html;/\/home\/todo-app\/app\/public;/" /etc/nginx/nginx.conf
# sed '/location \/ {.*\n*.*} a location /api/todos { proxy_pass http://localhost:8080; } ' /etc/nginx/nginx.conf

install_packages () {
    # yum -y install epel-release
    # yum -y update
    yum -y install git
    echo "Installed git"
    yum -y install nodejs
    echo "Installed nodejs"

# somehow on my vm, without following commands, mongodb-org cannot be found for install,
#  even with epel-release and yum update
MONGODBREPOFILE="/etc/yum.repos.d/mongodb-org-4.2.repo"
MONGODBREPO="[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc"

    echo "$MONGODBREPO" | tee $MONGODBREPOFILE
    yum -y install mongodb-org
    systemctl enable mongod && systemctl start mongod

    yum -y install nginx
    cp "$SCRIPT_PATH/nginx.conf" /etc/nginx/nginx.conf
    systemctl enable nginx && systemctl start nginx
    echo "Installed and enabled mongo"
}

install_app_as_user () {
    APPUSER="todoapp"
    APPUSERPASSWORD="SomeVeryStrongPassword777666555dsua89y8ej9u0dsa!!!!"
    ADMINUSER="admin"
    CLONEFOLDER="app"
    CLONETARGET="/home/$APPUSER/$CLONEFOLDER"
    REPOSRC="https://github.com/timoguic/ACIT4640-todo-app.git"

    adduser "$APPUSER"
    echo "$APPUSERPASSWORD" | passwd --stdin "$APPUSER"
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
    cp "$SCRIPT_PATH/todoapp.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable todoapp
    systemctl start todoapp
    echo "Configured todo app as service"
}

sec_config
install_packages
install_app_as_user
cofigure_node_service

