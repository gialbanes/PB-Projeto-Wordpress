# DevSecOps - Projeto Wordpress na AWS

 **Documentação do segundo projeto proposto na trilha de DevSecOps no meu programa de estágio PB - 2025**  

## 🎯 Objetivo  
Desenvolver e testar habilidades em **Linux**, **AWS** e **automação de processos** através da configuração de um ambiente de servidor web monitorado.

1. Instalação e configuração do DOCKER ou CONTAINERD no host EC2;
- Ponto adicional para o trabalho utilizar
a instalação via script de Start Instance (user_data.sh);
- Seguir o desenho da topologia disposta;

2. Efetuar Deploy de uma aplicação Wordpress com:
- Container de aplicação;
- RDS database Mysql;

3. Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação Wordpress

4. Configuração do serviço de Load Balancer AWS para a aplicação Wordpress

## Topologia 
![alt text](image.png)

## Etapas a serem seguidas:
1. Criar a VPC, EC2 
2. Criar o RDS 
3. Instalar o Docker na EC2 
4. Rodar o Wordpress na EC2 
5. Criar um script de inicialização no User Data e o testar
6. Criar o auto-scaling group e balanceador de Carga 
7. Criar regras de scaling 
8. Monitoramento no Cloudwatch 

## 🛠️ Requisitos Técnicos  
- **Windows 11**  
- **Visual Studio Code**
- **Amazon Linux 2023**  
- **Instância EC2 AWS**  
- **Nginx**  


### 🔹 Tecnologias Utilizadas  
<p align="left">
  <img src="https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white"/>
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black"/>
  <img src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white"/>
  <img src="https://img.shields.io/badge/Amazon%20EC2-FF9900?style=for-the-badge&logo=amazon-ec2&logoColor=white"/>

</p>


## 📑 Índice  
1. [Configuração do Ambiente](#1-configuração-do-ambiente) 
2. [Intalação e configuração do Docker](#2-intalação-e-configuração-do-docker)
3. [Instalação e configuração do Wordpress](#3-instalação-e-configuração-do-wordpress)

## 1. Configuração do ambiente 

### 1.1 Criar uma VPC na AWS  
O primeiro passo para configurar seu ambiente na AWS é criar uma VPC personalizada. No console da AWS, pesquise pelo serviço **VPC** e crie uma nova, definindo um **bloco CIDR** adequado para sua rede (por exemplo, `10.0.0.0/16` permite criar até 65.536 endereços IP privados dentro dessa VPC).  

![alt text](imgs/image.png)

Após criar a VPC, será necessário configurar as **subnets**, que são divisões menores dentro da VPC. As subnets permitem organizar os recursos e distribuir a carga de trabalho em diferentes zonas de disponibilidade.  

1️⃣ Acesse a seção de Subnets no console da AWS

2️⃣ Crie quatro subnets:  
   - **Duas públicas** (acessíveis pela internet)  
   - **Duas privadas** (acessíveis apenas dentro da VPC) 

3️⃣ Distribua as subnets entre diferentes zonas de disponibilidade, por exemplo:  
   - **us-east-1a** → 1 subnet pública e 1 privada  
   - **us-east-1b** → 1 subnet pública e 1 privada  

Isso melhora a **alta disponibilidade** do ambiente, garantindo que, caso uma zona fique indisponível, a outra ainda estará funcionando.  

Após a criação, as subnets aparecerão listadas no console da AWS:  

![alt text](imgs/image-1.png) 

---

#### 🔹 Configurar Acesso à Internet  

Por padrão, uma VPC recém-criada não tem conexão direta com a internet. Para permitir que as **subnets públicas** acessem a internet (e sejam acessadas externamente), precisamos configurar dois elementos fundamentais:  

✅ **Internet Gateway (IGW)** → Responsável por fornecer acesso à internet para os recursos da VPC  
✅ **Route Table** → Controla como o tráfego é roteado dentro da VPC  

#### 🔹 Criando um Internet Gateway  
O **Internet Gateway (IGW)** é um componente que permite que recursos dentro da VPC se comuniquem com a internet. Sem ele, mesmo que a instância tenha um IP público, não será possível acessar nada externo.  

1️⃣ No console da AWS, vá até **Internet Gateway** e clique em **Criar Internet Gateway**.  
2️⃣ Após a criação, é necessário anexá-lo à VPC clicando em **Attach to VPC**.  

![alt text](imgs/image-2.png) 

#### 🔹 Criando uma Route Table  
A **Route Table** define quais caminhos (rotas) o tráfego de rede deve seguir dentro da VPC. Por padrão, todas as subnets criadas usam a **route table principal**, que só permite comunicação interna.  

Para permitir que as **subnets públicas** acessem a internet:  

1️⃣ Vá até **Route Tables** no console da VPC e crie uma nova tabela de rotas.  
2️⃣ Adicione uma **rota com destino `0.0.0.0/0`** apontando para o **Internet Gateway (IGW)** criado anteriormente. Isso garante que qualquer tráfego externo será roteado para a internet.  

![alt text](imgs/image-3.png) 
![alt text](imgs/image-4.png)  

3️⃣ Agora, associe as **subnets públicas** a essa nova Route Table:  
   - Vá até **Subnet Associations**  
   - Edite e selecione as duas **subnets públicas**  

![alt text](imgs/image-5.png) 

Agora, suas **subnets públicas** podem acessar a internet!  

## 2. Security Groups
### 2.1 Criar Security Group para o Amazon RDS
No console da AWS, acesse **EC2 → Security Groups** defina as seguintes regras para o security group do banco de dados: 

✅ **Regra de entrada:**  
   - **MySQL/Aurora (porta 3306)** -> Permite tráfego do Security Group da instância EC2

✅ **Regra de saída:**  
   - Permitir todo o tráfego de saída (padrão)

![alt text](imgs/sg-bd.png) 
![alt text](imgs/sg-bd-2.png) 


### 2.2 Criar Security Group para EC2
Com a VPC configurada, podemos criar uma **instância EC2**, que será o servidor web do nosso projeto.  

Antes disso, é essencial configurar um **Security Group**, que atua como um firewall controlando o tráfego de entrada e saída da instância.  

#### 🔹 Criando um Security Group  
No console da AWS, acesse **EC2 → Security Groups** e crie um novo com as seguintes regras:  

✅ **Regra de entrada:**   
   - **SSH (porta 22)** → Permite apenas o acesso do seu IP (`Meu IP`) para garantir segurança  
   - **HTTP (port 80)** → Permite para o grupo de segurança do Load Balancer 

  - Permitir todo o tráfego de saída (padrão) 
  - **MYSQL/Aurora (port 3306)** → Permite tráfego para o grupo de segurança do RDS
  - **NFS (port 2049)** → Permite tráfego para o grupo de segurança do EFS

   

✅ **Regra de saída:**  
   - Permitir todo o tráfego de saída (padrão)
   - **MySQL/Aurora (porta 3306)** -> Permite tráfego do Security Group do banco de dados

![alt text](imgs/sg-ec2.png) 
![alt text](imgs/sg-ec2-2.png) 


### 2.3 Criar Security Group para o Amazon EFS
Antes de criar um EFS de fato, é necessário criar um Security Group pra ele.

Acesse o serviço da EC2, na aba de `Network & Security` clique em `Security Group` e crie um novo chamado `efs-sg`.   

✅ **Regra de entrada:**   
   - **NFS (porta 2049)** → Permite apenas o acesso do grupo de segurança utilizado para a instância.  
   
✅ **Regra de saída:**  
   - Permitir todo o tráfego de saída (padrão)

![alt text](imgs/sg-efs-1.png)
![alt text](imgs/sg-efs-2.png)

### 2.4 Criar security group para o Load Balancer  
✅ **Regra de entrada:**   
   - **HTTP (porta 80)** → Permite para qualquer lugar  
   
✅ **Regra de saída:**  
   - **HTTP (port 80)** → Permitir tráfego para o security group das instâncias


## 2. Criar um banco de dados MySQL no Amazon RDS
No console da AWS, pesquise pelo serviço `Aurora and RDS` e crie um novo database, de acordo com as orientações abaixo:

1. Selecione MySQL como o tipo de banco de dados. Escolha a versão mais recente disponível.
![alt text](imgs/mysql.png)

2. Marque a opção Free Tier para evitar cobranças.
![alt text](imgs/freetier.png)

3. Defina um ID único para o banco de dados.
![alt text](imgs/id.png)

4. Forneça um nome de usuário, assim como sua própria senha em `Self managed`
![alt text](imgs/credentials.png)

5. Escolha a instância do tipo db.t3.micro.
![alt text](imgs/t3.png)

6. Na aba `Storage`, clique em `Additional storage configuration` e defina o tamanho máximo como 22GB.
![alt text](imgs/storage.png)

7. Na aba `Connectivity`, escolha `Don’t connect to an EC2 compute resource`. 
![alt text](imgs/vpc.png)


> **Nota de Atenção**:  
> Selecione a mesma VPC e subnet utilizadas na sua instância EC2 para permitir a comunicação entre elas.

8. Por fim, na aba `Additional configuration`, dê um nome ao seu database. 
![alt text](imgs/db_name.png)



## 3. Criar um volume EFS 
No console da AWS, pesquise pelo serviço `EFS` e crie um novo file system, de acordo com as orientações abaixo:

1. Dê um nome ao file system e o coloque na VPC criada anteriormente. Depois clique em `Customize`. 
![alt text](imgs/efs-vpc.png)

2. Em `General` apenas desabilite a opção de backups automáticos.
![alt text](imgs/efs-type.png)

3. Em `Lifecycle Management` mude tudo para `None`.
![alt text](imgs/efs-lifecycle.png)

4. Em `Performance settings`, mude para `Bursting`. Em seguida, avance.
![alt text](imgs/efs-performance.png)

5. Em `Network`, dexei dois `Mount targets`. Um em cada zona de disponibilidade, na subnet pública, apontando para o security group do efs 
![alt text](imgs/efs-network.png)

6. Por fim, crie o EFS

## 4. Criar um template 
Agora criaremos um Launch Template, ou seja, a nossa própria imagem para as nossas instâncias. 

Acesse **EC2 -> Launch Template**.

1. Insira uma nome e uma descrição para o template
![alt text](imgs/t-name.png)

2. Selecione a AMI desejada
![alt text](imgs/t-ami.png)

3. Defina o tipo da instância como `t2.micro` e uma chave SSH.
![alt text](imgs/t-type.png)

4. Nas configurações de rede, selecione apenas o security group criado para as instâncias 
![alt text](imgs/t-network.png)

5. Por fim adicione o seu scrip `userdata.sh` na aba de `Advanced details` 
![alt text](imgs/t-userdata.png)

A seguir o script utilizado 
```bash
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
sudo mount -t efs -o tls fs-09d2ca3dffa8c3d3e:/ /mnt/wordpress

# Pegando o do meu GitHub arquivo docker-compose.yml
wget -O /home/ec2-user/docker-compose.yml https://raw.githubusercontent.com/gialbanes/PB-Projeto-Wordpress/refs/heads/main/docker-compose.yml
sudo chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml


# Inicia os containers
cd /home/ec2-user
sudo docker-compose up -d --build 
```


## 5. Criar o Auto Scaling Group com o Load Balancer

1. Insira um nome para o seu grupo de scaling, e como tenplate, o criado anteriormente
![alt text](imgs/asg-name.png)

2. Selecione a VPC criada e as duas subnets públicas
![alt text](imgs/asg-network.png)

3. Agora, escolha criar um novo load balancer
![alt text](imgs/asg-lb-name.png)

4. Em seguida, por padrão, as configurações de rede já estarão selecionadas. Apenas escolha criar um `Target Group`
![alt text](imgs/asg-lb-network.png)

5. Marque a opção de `Health checks`
![alt text](imgs/asg-health.png)

6. Defina as regras de scaling com o mínimo de 2 EC2 e o máximo como 4 EC2
![alt text](imgs/asg-group-size.png)

7. Defina uma política com a média de utilização de CPU com o valor 80
![alt text](imgs/asg-scaling.png)

8. Depois, habilite a opção de métricas do CloudWatch
![alt text](imgs/asg-monitoring.png)

9. Por fim, adicione a TAG name com o nome de suas instâncias que serão lançadas
![alt text](imgs/asg-tags.png)

---

### 5.1 Trocar security group do Load Balancer 
Acesse **EC2 -> Load Balancer**. Selecione o criado e navegue até a aba de `Security`. Pode verificar que por padrão, foi criado com o security group das instâncias, precisamos alterar. Clique em `Editar`
![alt text](imgs/lb-security-group.png)

Deixe somente o security group criado para o Load Balancer
![alt text](imgs/lb-lb.png)

### 5.2 Instâncias
Em **EC2 -> Instances**, é possível notar que duas instâncias foram criadas
![alt text](imgs/asg-ec2.png)

### 6. Acessar a aplicação via DNS
Vá até **EC2 -> Load Balancer** e clique em cima do que está criado. Depois, copie o DNS name e cole no navegador
![alt text](imgs/lb-dns.png)

Essa tela deve ser exibida 
![alt text](imgs/wordpress.png)


## 6.1 Acessar as instâncias criadas  

No console da AWS, selecione a instância e clique em **Connect**. A AWS fornecerá instruções para conexão via terminal:  

![alt text](imgs/Captura%20de%20tela%202025-03-24%20113225.png)

> **Nota de Atenção**:  
> Os comandos descritos foram executados no terminal do Visual Studio Code, localizado na pasta onde a chave SSH foi baixada. Certifique-se de estar na pasta correta com a chave SSH configurada para garantir que todas as conexões e comandos relacionados ao seu servidor EC2 funcionem corretamente.

Antes de conectar, precisamos alterar as permissões da chave SSH,  deixando a chave acessível apenas para o proprietário (400 significa somente leitura para o dono), com o comando:  
```bash
chmod 400 "suaChave.pem"
```

Agora podemos conectar à EC2 executando:
```bash
ssh -i "suaChave.pem" ec2-user@IpPublicoDaEC2
```

Caso tudo esteja certo, veremos a tela de conexão:
![alt text](imgs/Captura%20de%20tela%202025-03-24%20113701.png)

### 4.2 Tentar conexão entre a EC2 e o banco de dados
Após acessar a instância, execute os seguinte comando: 
```bash
mysql -h db-wordpress.cxyow8s4km5z.us-east-1.rds.amazonaws.com -u giovana -p 
```

Logo em seguida:
```bash
show databases;
```

O banco de dados que você criou deve ser listado. 
![alt text](imgs/conexao.png)

## 5. Intalação e configuração do Docker
Para instalar o Docker, dentro da instância execute: 

```bash
sudo yum install -y docker 
```
![alt text](imgs/instalacao-docker.png)

Para confirmar, verifique a versão do docker com:
```bash
docker --version 
```
![alt text](imgs/versao-docker.png)

Em seguida, inicie o serviço do docker com: 
```bash
sudo service docker start
```
![alt text](imgs/start-docker.png)

Habilite o serviço do docker. Para confirmar, veja se o serviço está rodando:
```bash
sudo systemctl enable docker
sudo systemctl status docker 
```
![alt text](imgs/status-docker.png)

Agora, é necessário isntalar o docker-compose, para isso, execute:
```bin
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

- o "curl" baixa arquivos da internet;
- "o" define o nome e local onde o arquivo ficará;

![alt text](imgs/compose-install.png)

Adicione a permissão de execução ao arquivo:
```bin 
sudo chmod +x /usr/local/bin/docker-compose
```

## 6. Instalação e configuração do Wordpress
Dentro da instância, instale a imagem do Wordpress com: 
```bash
sudo docker pull wordpress
```

![alt text](imgs/pull-wordpress.png)

Crie um espaço de trabalho para o Wordpress:
```bash
mkdir wordpress
```

Dentro dessa pasta, crie um arquivo `docker-compose.yml`. Esse arquivo configura e inicia dois serviços, o WordPress com um banco de dados MySQL.

```bash
sudo nano docker-compose.yml
```

```bash
services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: seuHost
      WORDPRESS_DB_USER: seuUser
      WORDPRESS_DB_PASSWORD: suaSenha
      WORDPRESS_DB_NAME: seuBanco
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
```

Construa o container a partir do docker-compose:
```bash
sudo docker-compose up -d --build
```

Por fim, rode o container:
```bash
sudo docker run -d -it wordpress 
```

Para testar, abra o navegador e digite `https://ipDaInstancia`

![alt text](imgs/wordpress.png)