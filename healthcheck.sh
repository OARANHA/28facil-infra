#!/bin/bash

# =====================================================
# HEALTHCHECK - Verificar saúde da API
# =====================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="${API_URL:-https://api.28facil.com.br}"

echo -e "${BLUE}==========================================="
echo -e "  Healthcheck - API 28Fácil"
echo -e "===========================================${NC}"
echo ""

# Função para testar endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"
    
    echo -n "Testando $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✓ OK ($response)${NC}"
        return 0
    else
        echo -e "${RED}✗ FALHOU (esperado: $expected_code, obtido: $response)${NC}"
        return 1
    fi
}

# Testes
FAILURES=0

test_endpoint "Health Check" "$API_URL/" || ((FAILURES++))
test_endpoint "Health Endpoint" "$API_URL/health" || ((FAILURES++))
test_endpoint "API Spec" "$API_URL/api.json" || ((FAILURES++))
test_endpoint "Auth Validate (sem key)" "$API_URL/auth/validate" "401" || ((FAILURES++))

echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✅ Todos os testes passaram!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILURES teste(s) falharam${NC}"
    exit 1
fi
