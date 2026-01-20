#!/bin/bash

# =====================================================
# SCRIPT DE BACKUP - Banco MySQL 28Fácil
# =====================================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configurar
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="28facil_api"

# Detectar Docker Compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${YELLOW}💾 Iniciando backup do banco de dados...${NC}"

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"

# Nome do arquivo
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.sql"

# Fazer backup
echo "Exportando banco de dados..."
$DOCKER_COMPOSE exec -T mysql mysqldump -u root -p${DB_PASSWORD:-senha_forte_123} $DB_NAME > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    # Comprimir
    echo "Comprimindo backup..."
    gzip "$BACKUP_FILE"
    
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    
    echo -e "${GREEN}✅ Backup concluído com sucesso!${NC}"
    echo -e "${GREEN}Arquivo: ${BACKUP_FILE}.gz${NC}"
    echo -e "${GREEN}Tamanho: $BACKUP_SIZE${NC}"
    
    # Limpar backups antigos (manter apenas últimos 7 dias)
    echo "Limpando backups antigos..."
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
    
    echo -e "${GREEN}Backups disponíveis:${NC}"
    ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "Nenhum backup encontrado"
else
    echo -e "${RED}❌ Erro ao fazer backup!${NC}"
    exit 1
fi
