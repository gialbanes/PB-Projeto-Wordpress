#!/bin/bash

# Atualiza pacotes
sudo yum update -y

# Instalação do Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Instalação do docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalação do mysql-client
sudo yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm

sudo yum install mysql-community-client -y --nogpgcheck


# Criando diretório do WordPress
mkdir -p wordpress
cd wordpress/

# Criando arquivo docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'
services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db-wordpress.cxyow8s4km5z.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: giovana
      WORDPRESS_DB_PASSWORD: teste123
      WORDPRESS_DB_NAME: db_wordpress
    volumes:
      - wordpress:/var/www/html
    networks:
      - rede       
volumes:
  wordpress:
  db:

networks:  
  rede:    
   driver: bridge
EOF

# Inicia os containers
sudo docker-compose up -d
sudo docker run -d -it wordpress