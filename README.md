# DevSecOps - Projeto Wordpress na AWS

 **Documentação do segundo projeto proposto na trilha de DevSecOps no meu programa de estágio PB - 2025**  

## 🎯 Objetivo  
Desenvolver e testar habilidades em **Linux**, **AWS** e **automação de processos** através da configuração de um ambiente de servidor web monitorado.

## 🛠️ Requisitos Técnicos  
- **Windows 11**  
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

### 1.2 Criar um banco de dados MySQL no Amazon RDS
No console da AWS, pesquise pelo serviço "Aurora and RDS" e crie um novo database, de acordo com as orientações abaixo:

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



### 1.3 Criar uma instância EC2  
Com a VPC configurada, podemos criar uma **instância EC2**, que será o servidor web do nosso projeto.  

Antes disso, é essencial configurar um **Security Group**, que atua como um firewall controlando o tráfego de entrada e saída da instância.  

#### 🔹 Criando um Security Group  
No console da AWS, acesse **EC2 → Security Groups** e crie um novo com as seguintes regras:  

✅ **Regra de entrada:**  
   - **HTTP (porta 80)** → Permite tráfego de qualquer origem (`0.0.0.0/0`)  
   - **SSH (porta 22)** → Permite apenas o acesso do seu IP (`Meu IP`) para garantir segurança  
  - **HTTPS (porta 443)** → Permite tráfego de qualquer origem (`0.0.0.0/0`)  
   

✅ **Regra de saída:**  
   - Permitir todo o tráfego de saída (padrão)
   - **MySQL/Aurora (porta 3306)** -> Permite tráfego do Security Group do banco de dados

![alt text](imgs/sg-ec2.png) 
![alt text](imgs/sg-ec2-2.png) 

No console da AWS, acesse **EC2 → Security Groups** defina as seguintes regras para o security group do banco de dados: 

✅ **Regra de entrada:**  
   - Permitir todo o tráfego de saída (padrão)
   - **MySQL/Aurora (porta 3306)** -> Permite tráfego do Security Group da instância EC2

✅ **Regra de saída:**  
   - Permitir todo o tráfego de saída (padrão)

![alt text](imgs/sg-bd.png) 
![alt text](imgs/sg-bd-2.png) 


Agora podemos criar a instância EC2:  

1️⃣ No console da AWS, vá até **EC2 → Instâncias** e clique em **Criar Instância**  
2️⃣ Escolha a **AMI Amazon Linux 2023**  
3️⃣ **Configure uma chave SSH** para permitir acesso remoto à instância 

4️⃣ Configure as opções de rede:  
   - Selecione a **VPC criada** anteriormente  
   - Escolha uma **subnet pública**  
   - Ative o **IP público automático**  
   - Associe o **Security Group** criado  


![alt text](imgs/image-8.png)  
![alt text](imgs/image-7.png) 

---

### 1.4 Acessar a instância via SSH  

Agora que a EC2 está criada, podemos acessá-la via **SSH**.  

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

### 1.5 Tentar conexão entre a EC2 e o banco de dados
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

## 2. Intalação e configuração do Docker
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

## 3. Instalação e configuração do Wordpress
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