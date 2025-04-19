# Projeto Terraform AWS - Provisionamento Automático com CSV

Este projeto provisiona automaticamente VPCs, subnets públicas e privadas, Internet Gateways, Route Tables, Virtual Private Gateways (VGW), Transit Gateways (TGW), conexões de VPC Peering e rotas personalizadas na AWS utilizando Terraform. Toda configuração é realizada através de arquivos `.csv`, permitindo fácil manutenção e escalabilidade sem modificar diretamente o código Terraform.

---

## 📁 Estrutura do Projeto

```text
tf-aws-project/
├── main.tf
├── provider.tf
├── variables.tf
├── outputs.tf
├── redes.csv
├── peerings.csv
├── routes.csv
├── .gitignore
└── modules/
    └── network/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 🚀 Como Usar

### 1. Clonar o projeto (se aplicável)

```bash
git clone <url_do_seu_repositorio>
cd tf-aws-project
```

### 2. Configurar AWS CLI

Certifique-se que suas credenciais AWS estão configuradas:

```bash
aws configure
```

### 3. Configurar os arquivos CSV

#### `redes.csv`

Contém as definições de VPCs, subnets e ativação de VGW/TGW:

```csv
name,vpc_cidr,public_subnet_cidr,private_subnet_cidr,region,az,enable_vgw,enable_tgw
vpc-network-services-us-east-2a,10.10.0.0/22,10.10.0.0/23,10.10.2.0/23,us-east-2,us-east-2a,true,true
vpc-security-services-us-east-2a,10.10.4.0/22,10.10.4.0/23,10.10.6.0/23,us-east-2,us-east-2a,true,true
vpc-infrastructure-services-us-east-2a,10.10.8.0/22,10.10.8.0/23,10.10.10.0/23,us-east-2,us-east-2a,true,true
```

#### `peerings.csv`

Define os pares de VPCs que devem ser interconectados via peering:

```csv
requester,accepter
vpc-network-services-us-east-2a,vpc-security-services-us-east-2a
vpc-network-services-us-east-2a,vpc-infrastructure-services-us-east-2a
vpc-security-services-us-east-2a,vpc-infrastructure-services-us-east-2a
```

#### `routes.csv`

Define rotas customizadas nas VPCs:

```csv
vpc_name,route_table_type,destination_cidr,target_type,target_value
vpc-infrastructure-services-us-east-2a,private,0.0.0.0/0,tgw,auto
vpc-security-services-us-east-2a,public,0.0.0.0/0,igw,auto
vpc-network-services-us-east-2a,private,10.10.4.0/22,vpc_peering,vpc-network-services-us-east-2a-vpc-security-services-us-east-2a
```

> Use `target_value = auto` para IGWs e TGWs criados automaticamente pelo módulo.

### 4. Executar o Terraform

Rode os comandos abaixo para provisionar os recursos:

```bash
terraform init
terraform plan
terraform apply
```

---

## ✅ Recursos Criados

Para cada linha no `redes.csv`, o Terraform provisionará automaticamente:

- **1 VPC**
- **1 Internet Gateway** (se necessário)
- **1 Subnet Pública** (com acesso direto à internet)
- **1 Route Table Pública** (associada à subnet pública)
- **1 Subnet Privada** (sem acesso direto à internet)
- **1 Route Table Privada** (associada à subnet privada)
- **Virtual Private Gateway (VGW)** (opcional)
- **Transit Gateway (TGW)** (opcional, compartilhado entre várias VPCs)

Para cada linha no `peerings.csv`, o Terraform provisionará:

- **1 VPC Peering Connection**
- **Rotas privadas entre as VPCs envolvidas**

Para cada linha no `routes.csv`, o Terraform provisionará:

- **Rotas customizadas** (para TGW, IGW, VPC Peering, etc.) nas route tables públicas ou privadas

---

## ⚙️ Customização e Expansão

- Para adicionar novos ambientes, basta incluir linhas no `redes.csv`
- Para interconectar redes, edite o `peerings.csv`
- Para criar rotas customizadas, use o `routes.csv`
- Para adicionar NAT Gateway, Bastion Hosts, etc., expanda o módulo `network`

---

## 📄 .gitignore

```gitignore
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
*.csv.backup
```

Esses arquivos são gerados automaticamente e não devem ser versionados.

---

## 🛠 Pré-requisitos

- Terraform instalado (`>= v1.0`)
- AWS CLI configurado com credenciais válidas

---

## 📝 Boas Práticas

- Faça testes sempre com `terraform plan` antes de aplicar as mudanças
- Utilize versionamento Git para gerenciar mudanças e evoluções do projeto
- Use budgets na AWS para evitar cobranças inesperadas
- Destrua recursos ao final do teste com `terraform destroy`

---

## 📌 Suporte

Em caso de dúvidas ou problemas, consulte a documentação oficial do [Terraform](https://www.terraform.io/docs) ou abra uma issue no seu repositório.
