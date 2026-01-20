#!/bin/bash

# =====================================================
# INSTALADOR AUTOMÁTICO - 28Facil Stack
# Deploy completo direto do GitHub
# =====================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "========================================"
echo "  🚀 28Facil Stack - Instalador"
echo "========================================"
echo -e "${NC}"

# Verificar root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}⚠️  Não execute como root. Use sudo apenas quando necessário.${NC}"
    exit 1
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker não encontrado. Instalando...${NC}"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker instalado${NC}"
    echo -e "${YELLOW}⚠️  Faça logout e login novamente, depois execute este script de novo${NC}"
    exit 0
fi

echo -e "${GREEN}✓ Docker encontrado${NC}"

# Coletar informações
echo ""
echo -e "${BLUE}Configuração:${NC}"
echo ""

read -p "Domínio da API (ex: api.28facil.com.br): " DOMAIN
read -p "Email para Let's Encrypt: " ACME_EMAIL
read -s -p "Senha do MySQL: " DB_PASSWORD
echo ""
read -s -p "Confirme a senha: " DB_PASSWORD_CONFIRM
echo ""

if [ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}❌ Senhas não conferem${NC}"
    exit 1
fi

if [ -z "$DOMAIN" ] || [ -z "$ACME_EMAIL" ] || [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}❌ Todos os campos são obrigatórios${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Configurando com:${NC}"
echo "  Domínio: $DOMAIN"
echo "  Email: $ACME_EMAIL"
echo ""
read -p "Continuar? (s/N): " CONFIRM

if [ "$CONFIRM" != "s" ]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# Criar diretório de trabalho
WORK_DIR="$HOME/28facil"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo -e "${BLUE}\n📍 Trabalhando em: $WORK_DIR${NC}\n"

# Download dos arquivos
echo -e "${BLUE}1️⃣  Baixando arquivos...${NC}"

curl -sSL -o traefik-stack.yml https://raw.githubusercontent.com/OARANHA/28facil-infra/main/traefik-stack.yml
curl -sSL -o docker-compose.yml https://raw.githubusercontent.com/OARANHA/28facil-infra/main/docker-compose.yml
curl -sSL -o migration.sql https://raw.githubusercontent.com/OARANHA/28facil-api/main/database/migrations/001_api_keys.sql

echo -e "${GREEN}✓ Arquivos baixados${NC}"

# Criar .env
echo -e "${BLUE}\n2️⃣  Configurando ambiente...${NC}"

JWT_SECRET=$(openssl rand -base64 32)

cat > .env << EOF
# 28Facil API - Configuracoes
DB_DATABASE=28facil_api
DB_USERNAME=28facil
DB_PASSWORD=$DB_PASSWORD

APP_ENV=production
APP_DEBUG=false
APP_URL=https://$DOMAIN

JWT_SECRET=$JWT_SECRET
ACME_EMAIL=$ACME_EMAIL
EOF

echo -e "${GREEN}✓ Ambiente configurado${NC}"

# Ajustar traefik-stack.yml
sed -i "s/api.28facil.com.br/$DOMAIN/g" traefik-stack.yml docker-compose.yml
sed -i "s/admin@28facil.com.br/$ACME_EMAIL/g" traefik-stack.yml

# Criar rede
echo -e "${BLUE}\n3️⃣  Criando rede Docker...${NC}"
docker network create traefik-public 2>/dev/null || echo "Rede já existe"
echo -e "${GREEN}✓ Rede criada${NC}"

# Subir Traefik
echo -e "${BLUE}\n4️⃣  Iniciando Traefik...${NC}"
docker compose -f traefik-stack.yml up -d
sleep 5
echo -e "${GREEN}✓ Traefik rodando${NC}"

# Subir API
echo -e "${BLUE}\n5️⃣  Iniciando API Server...${NC}"
docker compose up -d
sleep 10
echo -e "${GREEN}✓ API rodando${NC}"

# Migrar banco
echo -e "${BLUE}\n6️⃣  Criando banco de dados...${NC}"
docker compose exec -T mysql mysql -u root -p$DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS 28facil_api;"
docker compose exec -T mysql mysql -u root -p$DB_PASSWORD 28facil_api < migration.sql
echo -e "${GREEN}✓ Banco criado${NC}"

# Gerar primeira key
echo -e "${BLUE}\n7️⃣  Gerando primeira API Key...${NC}"

SECRET=$(openssl rand -hex 24)
FULL_KEY="28fc_${SECRET}"
KEY_HASH=$(echo -n "$FULL_KEY" | sha256sum | cut -d' ' -f1)
KEY_PREFIX="28fc_${SECRET:0:8}"

docker compose exec -T mysql mysql -u root -p$DB_PASSWORD 28facil_api << EOSQL
INSERT INTO api_keys (
    key_hash, key_prefix, name, 
    permissions, rate_limit, is_active
) VALUES (
    '$KEY_HASH',
    '$KEY_PREFIX',
    'Primeira Key (gerada na instalação)',
    JSON_ARRAY('read', 'write'),
    1000,
    1
);
EOSQL

echo -e "${GREEN}✓ API Key gerada${NC}"

# Testar
echo -e "${BLUE}\n8️⃣  Testando...${NC}"
sleep 5

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null || echo "000")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ API respondendo!${NC}"
else
    echo -e "${YELLOW}⚠️  API ainda não responde (código: $RESPONSE)${NC}"
    echo -e "${YELLOW}Aguarde alguns minutos para o SSL ser configurado${NC}"
fi

# Resumo final
echo ""
echo -e "${GREEN}========================================"
echo "  ✅ Instalação Concluída!"
echo "========================================${NC}"
echo ""
echo -e "${BLUE}Informações:${NC}"
echo ""
echo "  🌐 URL da API: https://$DOMAIN"
echo "  📋 Logs: docker compose logs -f"
echo "  🐳 Containers: docker ps"
echo ""
echo -e "${YELLOW}🔑 Sua primeira API Key:${NC}"
echo ""
echo "    $FULL_KEY"
echo ""
echo -e "${YELLOW}⚠️  GUARDE ESTA KEY! Ela não será mostrada novamente.${NC}"
echo ""
echo -e "${BLUE}Testar:${NC}"
echo ""
echo "  curl https://$DOMAIN/health | jq ."
echo ""
echo "  curl -H \"X-API-Key: $FULL_KEY\" \\"
echo "       https://$DOMAIN/auth/validate | jq ."
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo ""
echo "  1. Aguarde 1-2 minutos para o SSL ser configurado"
echo "  2. Teste os endpoints acima"
echo "  3. Veja README.md em: https://github.com/OARANHA/28facil-infra"
echo ""
