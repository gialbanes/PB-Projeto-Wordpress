#!/bin/bash

# Atualiza pacotes
sudo yum update -y

# Instalação do Docker e habilitação do serviço
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo docker --version

# Instalação do wget e efs-utils
sudo yum install wget -y
sudo yum install amazon-efs-utils -y

# Instalação do docker-compose e fornecendo permissão de execução à ele
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# Criando diretório do WordPress
mkdir -p /mnt/wordpress

# Montagem do efs
sudo mount -t efs -o tls fs-05578cd8a5b20e263:/ /mnt/wordpress

# Pegando o do meu GitHub arquivo docker-compose.yml
wget -O /home/ec2-user/docker-compose.yml https://raw.githubusercontent.com/gialbanes/PB-Projeto-Wordpress/refs/heads/main/docker-compose.yml
sudo chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml


# Inicia os containers
cd /home/ec2-user
sudo docker-compose up -d --build 