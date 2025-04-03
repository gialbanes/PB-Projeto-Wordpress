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


# Criando diretório 
mkdir -p [nome da pasta]

# Montagem do efs
[link do seu volume efs (pegar no efs -> attach)] [pasta criada]

# Pegando o do meu GitHub arquivo docker-compose.yml
wget -O /home/ec2-user/docker-compose.yml [link do docker-compose no seu github (raw)]
sudo chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml


# Inicia os containers
cd /home/ec2-user
sudo docker-compose up -d --build 