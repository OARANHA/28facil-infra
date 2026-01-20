# 🐳 28Facil Infra - Deploy com Docker + Traefik

## ⚡ Instalação Rápida (One-Liner)

```bash
curl -fsSL https://raw.githubusercontent.com/OARANHA/28facil-infra/main/install.sh | bash
```

**Ou via wget:**
```bash
wget -qO- https://raw.githubusercontent.com/OARANHA/28facil-infra/main/install.sh | bash
```

Este comando vai:
- ✅ Instalar Docker (se necessário)
- ✅ Configurar Traefik com SSL automático
- ✅ Subir API Server + MySQL
- ✅ Criar banco de dados
- ✅ Gerar primeira API Key
- ✅ Testar funcionamento

**Duração:** ~5 minutos

---

## 🎯 O que este repositório faz?

Infraestrutura completa para deploy do sistema 28Facil:
- **SSL automático** com Let's Encrypt
- **Reverse proxy** com Traefik 3.6
- **Gerenciamento visual** com Portainer
- **Scripts de deploy** e gerenciamento
- **Banco de dados** MySQL isolado

---

## 📚 Guias de Instalação

### Opção 1: Automatizada (⭐ Recomendada)

**Instalação completa em um comando:**
```bash
curl -fsSL https://raw.githubusercontent.com/OARANHA/28facil-infra/main/install.sh | bash
```

Veja: [QUICK-START.md](QUICK-START.md)

### Opção 2: Manual (Avançada)

**Clonar e configurar manualmente:**
```bash
git clone https://github.com/OARANHA/28facil-infra.git
cd 28facil-infra
cp .env.example .env
nano .env
./deploy.sh
```

Veja detalhes na seção [Instalação Manual](#-instalação-manual) abaixo.

---

## 📦 Arquitetura

```
[🌐 Internet]
       ↓
api.28facil.com.br (DNS)
       ↓
[Traefik :80/:443] ← SSL Let's Encrypt
       ↓
[API Server :80] ← PHP/Apache
       ↓
[MySQL :3306] ← Banco de dados
```

---

## 🚀 Instalação Manual

### Pré-requisitos

- VPS/Servidor Linux (Ubuntu 20.04+ recomendado)
- Docker e Docker Compose
- Domínio apontando para o IP do servidor
- Portas 80, 443 abertas

### 1️⃣ Clonar o repositório

```bash
cd /root  # ou onde preferir
git clone https://github.com/OARANHA/28facil-infra.git
cd 28facil-infra
```

### 2️⃣ Configurar variáveis de ambiente

```bash
cp .env.example .env
nano .env
```

**Edite:**
```bash
DB_DATABASE=28facil_api
DB_USERNAME=28facil
DB_PASSWORD=SUA_SENHA_FORTE_AQUI  # 🔒 TROCAR!

APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.28facil.com.br

JWT_SECRET=$(openssl rand -base64 32)  # Gerar

ACME_EMAIL=seu-email@exemplo.com  # 📧 TROCAR!
```

### 3️⃣ Configurar DNS

Aponte o domínio para o IP do seu VPS:

```
Tipo: A
Nome: api.28facil.com.br
Valor: SEU_IP_VPS
TTL: 300
```

**Aguarde a propagação** (1-5 minutos):
```bash
dig api.28facil.com.br +short
# Deve retornar o IP do seu VPS
```

### 4️⃣ Deploy do Traefik

Primeiro, faça deploy da stack do Traefik:

```bash
# Criar rede externa
docker network create traefik-public

# Deploy do Traefik
docker compose -f traefik-stack.yml up -d
```

### 5️⃣ Deploy da API

```bash
chmod +x deploy.sh manage.sh
./deploy.sh
```

O script vai:
- ✅ Verificar dependências
- ✅ Criar diretórios
- ✅ Construir imagens Docker
- ✅ Iniciar containers
- ✅ Configurar SSL
- ✅ Criar banco de dados

---

## 🧪 Testar

### Health Check
```bash
curl https://api.28facil.com.br/health | jq .
```

**Resposta esperada:**
```json
{
  "status": "success",
  "message": "28Facil API Server is running!",
  "version": "1.0.0",
  "timestamp": "2026-01-20T04:00:00-03:00",
  "database": {
    "status": "connected",
    "host": "mysql",
    "database": "28facil_api"
  }
}
```

### Validar API Key
```bash
curl -H "X-API-Key: 28fc_sua_key_aqui" \
     https://api.28facil.com.br/auth/validate | jq .
```

---

## 🛠️ Gerenciamento

### Via Makefile (Recomendado)

```bash
make help           # Ver todos os comandos
make status         # Ver status dos containers
make logs           # Ver logs em tempo real
make restart        # Reiniciar containers
make backup         # Backup do banco
make healthcheck    # Testar API
```

### Via manage.sh

```bash
./manage.sh status        # Status
./manage.sh logs          # Logs de todos
./manage.sh logs-api      # Logs da API
./manage.sh logs-mysql    # Logs do MySQL
./manage.sh restart       # Reiniciar todos
./manage.sh restart-api   # Reiniciar API
./manage.sh shell         # Shell no container
./manage.sh mysql         # MySQL CLI
./manage.sh stats         # Estatísticas
```

### Backup do Banco

```bash
# Manual
./backup.sh

# Ou via make
make backup

# Backups ficam em: ./backups/
```

---

## 🐳 Instalar Portainer (Opcional)

Gerenciador visual de containers:

```bash
chmod +x setup-portainer.sh
./setup-portainer.sh
```

Acesse:
- **HTTPS**: `https://SEU_IP:9443`
- **HTTP**: `http://SEU_IP:9000`

---

## 🔒 Segurança

### Firewall (recomendado)

```bash
# Permitir apenas portas necessárias
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (redirect)
ufw allow 443/tcp   # HTTPS
ufw enable
```

### Mudar senha do MySQL

```bash
nano .env  # Editar DB_PASSWORD
docker compose down
docker compose up -d
```

### Rotação de API Keys

Veja: [28facil-api/scripts](https://github.com/OARANHA/28facil-api/tree/main/scripts)

---

## 📊 Monitoramento

### Recursos do sistema
```bash
make stats
# Ou
docker stats
```

### Espaço em disco
```bash
df -h
docker system df
```

### Limpar containers/imagens antigas
```bash
docker system prune -a
```

### Healthcheck automático
```bash
./healthcheck.sh
# Ou
make healthcheck
```

---

## 🐞 Troubleshooting

### API não responde

```bash
# Ver logs
make logs-api

# Verificar se container está rodando
docker ps | grep api-server

# Reiniciar
make restart
```

### SSL não funciona

```bash
# Verificar logs do Traefik
docker logs traefik

# Verificar DNS
dig api.28facil.com.br +short

# Verificar certificados
ls -la docker/traefik/acme.json
chmod 600 docker/traefik/acme.json
```

### MySQL não conecta

```bash
# Ver logs
make logs-mysql

# Testar conexão
docker compose exec mysql mysql -u root -p

# Verificar .env
cat .env | grep DB_
```

---

## 🔄 Atualizar

```bash
git pull
make rebuild
# Ou
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## 🗂️ Estrutura de Arquivos

```
28facil-infra/
├── docker-compose.yml          # Orquestração da API
├── traefik-stack.yml          # Stack do Traefik
├── .env                        # Configurações (CRIAR!)
├── .env.example                # Exemplo de configurações
├── install.sh                  # Instalador automático
├── deploy.sh                   # Script de deploy
├── manage.sh                   # Script de gerenciamento
├── backup.sh                   # Backup do banco
├── healthcheck.sh              # Healthcheck
├── setup-portainer.sh          # Instalar Portainer
├── Makefile                    # Comandos simplificados
├── QUICK-START.md              # Guia de deploy rápido
└── README.md                   # Este arquivo
```

---

## 🔗 Repositórios Relacionados

- **[28facil-api](https://github.com/OARANHA/28facil-api)**: Código da API REST
- **[aivopro-integrity](https://github.com/OARANHA/aivopro-integrity)**: Pacote PHP de monitoramento

---

## ❓ Suporte

Problemas? Verifique:
1. Logs: `make logs` ou `./manage.sh logs`
2. Status: `make status`
3. DNS configurado corretamente
4. Portas 80/443 abertas no firewall
5. `.env` configurado corretamente

Veja também: [QUICK-START.md](QUICK-START.md)

---

**Desenvolvido com ❤️ pela equipe 28Fácil**
