# 🐳 28Facil Infra - Deploy com Docker + Traefik

## 🎯 O que este repositório faz?

Infraestrutura completa para deploy do sistema 28Facil:
- **SSL automático** com Let's Encrypt
- **Reverse proxy** com Traefik 3.6
- **Gerenciamento visual** com Portainer
- **Scripts de deploy** e gerenciamento
- **Banco de dados** MySQL isolado

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

## ⚡ Instalação Rápida

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
APP_KEY=base64:$(openssl rand -base64 32)  # Gerar

JWT_SECRET=$(openssl rand -base64 32)  # Gerar

LETSENCRYPT_EMAIL=seu-email@exemplo.com  # 📧 TROCAR!
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
curl https://api.28facil.com.br/
```

**Resposta esperada:**
```json
{
  "status": "success",
  "message": "28Facil API Server is running!",
  "timestamp": "2026-01-20 04:00:00",
  "version": "1.0.0",
  "php_version": "8.2.x"
}
```

---

## 🛠️ Gerenciamento

### Ver status
```bash
./manage.sh status
```

### Ver logs
```bash
./manage.sh logs          # Todos
./manage.sh logs-api      # Apenas API
./manage.sh logs-mysql    # Apenas MySQL
```

### Reiniciar
```bash
./manage.sh restart       # Todos
./manage.sh restart-api   # Apenas API
```

### Parar/Iniciar
```bash
./manage.sh stop
./manage.sh start
```

### Entrar nos containers
```bash
./manage.sh shell         # API Server
./manage.sh mysql         # MySQL
```

### Estatísticas
```bash
./manage.sh stats
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

---

## 📈 Monitoramento

### Recursos do sistema
```bash
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

---

## 🐞 Troubleshooting

### API não responde

```bash
# Ver logs
./manage.sh logs-api

# Verificar se container está rodando
docker ps | grep api-server

# Reiniciar
./manage.sh restart-api
```

### SSL não funciona

```bash
# Verificar logs do Traefik
docker logs traefik

# Verificar DNS
dig api.28facil.com.br +short

# Verificar arquivo acme.json
ls -la traefik/acme.json
chmod 600 traefik/acme.json
```

### MySQL não conecta

```bash
# Ver logs
./manage.sh logs-mysql

# Testar conexão
docker compose exec mysql mysql -u root -p

# Verificar .env
cat .env | grep DB_
```

---

## 🔄 Atualizar

```bash
git pull
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
├── deploy.sh                   # Script de deploy
├── manage.sh                   # Script de gerenciamento
├── setup-portainer.sh          # Instalar Portainer
└── README.md                   # Este arquivo
```

---

## 🔗 Repositórios Relacionados

- **[28facil-api](https://github.com/OARANHA/28facil-api)**: Código da API REST
- **[28facil-integrity](https://github.com/OARANHA/28facil-integrity)**: Pacote PHP de monitoramento

---

## ❓ Suporte

Problemas? Verifique:
1. Logs: `./manage.sh logs`
2. Status: `./manage.sh status`
3. DNS configurado corretamente
4. Portas 80/443 abertas no firewall
5. `.env` configurado

---

**Feito com ❤️ pela 28Fácil**
