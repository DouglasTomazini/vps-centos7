#!/bin/bash

user="user"
useradicional="useradicional"
senha="senha"
site="site.com.br"
email="email@site.com.br"
me="$(whoami)"

#-----------Configuração do ambiente para servir aplicações web-----------------
yum install epel-release wget -y

wget https://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum install remi-release-7.rpm -y

yum install nginx php73 php73-php-fpm -y

#------------Configuração de usuário---------------------

sed -i 's/SELINUX=enforcing/SELINUX=permissive/'  /etc/selinux/config

setenforce 0

useradd $user -m -s /bin/bash

echo "$senha" | passwd "$user" --stdin

mkdir /home/$user/www

touch /home/$user/www/phpinfo.php

echo "<?php
        phpinfo(); 

     ?>" > /home/$user/www/phpinfo.php

chown -R $user.$user /home/$user/www

#-----------configuração de firewall-------------------

firewall-cmd --add-service={http,https,ftp}

firewall-cmd --runtime-to-permanent

firewall-cmd --reload

#----------Configuração nginx e php-fpm------------------

touch /etc/nginx/conf.d/$user.conf

echo "    server {
        listen       80;
        server_name  "$site" www."$site";
        root         /home/"$user"/www;

        # Load configuration files for the default server block.
        location = /favicon.ico {
                 log_not_found off;
        }

        location / {
                index index.htm index.html index.php;
        }

        location ~* \.php$ {
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_pass unix:/var/run/php-fpm/"$user".sock;
        }
    }" > /etc/nginx/conf.d/$user.conf

sed -i 's/SCRIPT_FILENAME/SCRIPT_FILENAME $document_root$fastcgi_script_name/' /etc/nginx/conf.d/$user.conf

chmod +x /home/$user


touch /etc/opt/remi/php73/php-fpm.d/$user.conf

echo "[douglastomazini]


user = douglastomazini
group = nginx

listen = /var/run/php-fpm/douglastomazini.sock


listen.owner = nginx
listen.group = douglastomazini
listen.mode = 0660

listen.allowed_clients = 127.0.0.1

pm = ondemand
pm.max_children = 3
pm.process_idle_timeout = 15s;
pm.status_path = /status

access.log=/var/opt/remi/php73/log/php-fpm/$pool-access.log
slowlog=/var/opt/remi/php73/log/php-fpm/$pool-slow.log
request_slowlog_timeout = 3


php_flag[display_errors] = on
php_admin_value[error_log] = /home/douglastomazini/php_error
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 100M" > /etc/opt/remi/php73/php-fpm.d/$user.conf


sed -i 's/-access.log/$pool-access.log/' /etc/opt/remi/php73/php-fpm.d/$user.conf
sed -i 's/-slow.log/$pool-slow.log/' /etc/opt/remi/php73/php-fpm.d/$user.conf


touch /etc/systemd/system/php73-php-fpm.service

echo "It's not recommended to modify this file in-place, because it
# will be overwritten during upgrades.  If you want to customize,
# the best way is to use the "systemctl edit" command.

[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=notify
EnvironmentFile=/etc/opt/remi/php73/sysconfig/php-fpm
ExecStartPre=-/bin/mkdir /var/run/php-fpm
ExecStart=/opt/remi/php73/root/usr/sbin/php-fpm --nodaemonize
ExecReload=/bin/kill -USR2 $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/php73-php-fpm.service

sed -i 's/ExecReload=/bin/kill -USR2 /ExecReload=/bin/kill -USR2 $MAINPID' /etc/systemd/system/php73-php-fpm.service


#--------------------------SSL ---------------------------------

yum install certbot python2-certbot-nginx -y

certbot certonly --nginx -d 'douglastomazini.tk, www.douglastomazini.tk' --non-interactive --agree-tos -m $email

certbot renew --dryrun 

#----------------------------FTP------------------------------------

yum install proftpd -y

useradd $useradicional -d /home/$user/www -G $user

sudo pkill -f nginx & wait $!

systemctl restart nginx
systemctl restart php73-php-fpm
systemctl restart proftpd

systemctl enable nginx
systemctl enable php73-php-fpm
systemctl enable proftpd

#---------------------------Script de backup---------------------

wget https://raw.githubusercontent.com/DouglasTomazini/backup/main/backup_semsql.sh

mv backup_semsql.sh /usr/bin

chmod +x /usr/bin/backup_semsql.sh

backup_semsql.sh

#---------------------------Editando o crontab---------------------

touch /var/spool/cron/$me

echo "0 23 * * * /backup.sh" > /var/spool/cron/$me
