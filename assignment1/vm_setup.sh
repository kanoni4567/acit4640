#!/bin/bash

sudo sed -i "s/enforcing/permissive/" /etc/selinux/config

sudo firewall-cmd --zone=public --add-port=8080/tcp
sudo firewall-cmd --runtime-to-permanent

sudo yum -y install git
sudo yum -y install nodejs

# sudo nginx -s reload
# sudo sed -i "s/\/usr\/share\/nginx\/html;/\/home\/todo-app\/app\/public;/" /etc/nginx/nginx.conf
# sudo sed '/location \/ {.*\n*.*} a location /api/todos { proxy_pass http://localhost:8080; } ' /etc/nginx/nginx.conf


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


APPUSER="todoapp"
APPUSERPASSWORD="SomeVeryStrongPassword777666555!!!!"
sudo adduser "$APPUSER"
echo "$APPUSERPASSWORD" | sudo passwd --stdin "$APPUSER"
sudo su -  "$APPUSER"
chmod 755 home/todoapp/
git clone https://github.com/timoguic/ACIT4640-todo-app.git app
cd app/
npm install
sed -i "s/CHANGEME/acit4640/" ./config/database.js

exit

sudo yum -y install nginx
sudo cp ./setup/nginx.conf /etc/nginx/nginx.conf
sudo systemctl enable nginx && sudo systemctl start nginx

sudo cp ./setup/todoapp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp


