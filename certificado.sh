#!/bin/bash
################################################################################
# Descripción: Script para configurar Certificado de Seguridad Autofirmado en Raspberry para Grupo Buen Rollo
# Autor: Pitaya Tech, S.A.
#-------------------------------------------------------------------------------
# Instrucciones:
# Crear un nuevo archivo:
# sudo nano certificado.sh
# Insertar el contenido de este documento y habilitar su ejecución:
# sudo chmod +x certificado.sh
# Ejecutar el Script:
# sudo ./certificado.sh
################################################################################

#Solicitando IP para generación del certificado
echo -e "\n---- Por favor ingrese la IP de la Raspberry: ----"
read IP

#Creando los archivos self-signed.key y self-signed.crt
echo -e "\n---- Creando los archivos self-signed.key y self-signed.crt ----"
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=GT/ST=Guatemala/L=Guatemala/O=Grupo Buen Rollo/OU=IT Department/CN=$IP"

#Creando el archivo pem
echo -e "\n---- Creando el archivo pem ----"
sudo openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096


#Creando el archivo self-signed.conf
echo -e "\n---- Creando el archivo self-signed.conf ----"
sudo touch /etc/nginx/snippets/self-signed.conf

#Insertando los valores en el archivo self-signed.conf
echo -e "\n---- Insertando los valores en el archivo self-signed.conf ----"
cat <<EOF > /etc/nginx/snippets/self-signed.conf
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOF

#Creando el archivo ssl-params.conf
echo -e "\n---- Creando el archivo ssl-params.conf ----"
sudo touch /etc/nginx/snippets/ssl-params.conf

#Insertando los valores en el archivo ssl-params.conf
echo -e "\n---- Insertando los valores en el archivo ssl-params.conf ----"
cat <<EOF > /etc/nginx/snippets/ssl-params.conf
ssl_protocols TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/nginx/dhparam.pem;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
ssl_session_timeout  10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off; # Requires nginx >= 1.5.9
ssl_stapling on; # Requires nginx >= 1.3.7
ssl_stapling_verify on; # Requires nginx => 1.3.7
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
# Disable strict transport security for now. You can uncomment the following
# line if you understand the implications.
# add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
EOF


#Eliminando el link simbólico de nginx odoo en sites-enabled
echo -e "\n---- Eliminando el link simbólico de nginx odoo en sites-enabled ----"
sudo rm /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo

#Eliminando el archivo de nginx odoo
echo -e "\n---- Eliminando el archivo de nginx odoo ----"
sudo rm /etc/nginx/sites-available/odoo

#Creando el archivo de nginx odoo
echo -e "\n---- Creando el archivo de nginx odoo ----"
sudo touch /etc/nginx/sites-available/odoo

#Insertando los valores en el archivo de nginx odoo
echo -e "\n---- Insertando los valores en el archivo de nginx odoo ----"
cat <<EOF > /etc/nginx/sites-available/odoo
upstream odooproxy {
    server localhost:8069;
}
upstream odoochat {
    server localhost:8072;
}
server {
    listen 80;
    server_name $IP;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    location / {
        proxy_redirect off;
        proxy_pass http://odooproxy;
    }
    location /longpolling {
        proxy_pass http://odoochat;
    }
}
server {
    listen 443 ssl;
    server_name $IP;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    location / {
        proxy_redirect off;
        proxy_pass http://odooproxy;
    }
    location /longpolling {
        proxy_pass http://odoochat;
    }
}
EOF


#Creando el link simbólico de nginx odoo en sites-enabled
echo -e "\n---- Creando el link simbólico de nginx odoo en sites-enabled ----"
sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo

#Deteniendo el servicio de nginx
echo -e "\n---- Deteniendo el servicio de nginx ----"
sudo service nginx stop

#Iniciando el servicio de nginx
echo -e "\n---- Iniciando el servicio de nginx ----"
sudo service nginx start

#Validando funcionamiento de la configuración del nginx
echo -e "\n---- Validando funcionamiento de la configuración del nginx ----"
sudo nginx -t

