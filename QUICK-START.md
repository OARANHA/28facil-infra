# ⚡ Quick Start - Deploy em 5 Minutos

Guia para rodar a stack 28Facil direto do GitHub, sem precisar clonar.

---

## 🚀 Deploy Rápido

### Pré-requisitos

- VPS/Servidor Linux (Ubuntu 20.04+ recomendado)
- Docker e Docker Compose instalados
- Domínio apontando para o IP do servidor
- Portas 80, 443 abertas

---

## 1️⃣ Instalar Docker (se necessário)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Relogar ou:
newgrp docker
```

---

## 2️⃣ Deploy da Stack Traefik

```bash
# Criar rede
docker network create traefik-public

# Download do arquivo
curl -O https://raw.githubusercontent.com/OARANHA/28facil-infra/main/traefik-stack.yml

# Editar email (IMPORTANTE!)
nano traefik-stack.yml
# Alterar: ACME_EMAIL=seu-email@dominio.com

# Subir Traefik
docker compose -f traefik-stack.yml up -d

# Verificar
docker ps | grep traefik
```

---

## 3️⃣ Deploy da API

```bash
# Download dos arquivos
curl -O https://raw.githubusercontent.com/OARANHA/28facil-infra/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/OARANHA/28facil-infra/main/.env.example

# Configurar
cp .env.example .env
nano .env
```

**Editar `.env`:**
```bash
DB_DATABASE=28facil_api
DB_USERNAME=28facil
DB_PASSWORD=SUA_SENHA_FORTE_AQUI  # 🔒 TROCAR!

JWT_SECRET=$(openssl rand -base64 32)  # Gerar

ACME_EMAIL=seu-email@exemplo.com  # 📧 TROCAR!
```

**Iniciar:**
```bash
docker compose up -d

# Verificar logs
docker compose logs -f
```

---

## 4️⃣ Criar Banco de Dados

```bash
# Download da migration
curl -o migration.sql https://raw.githubusercontent.com/OARANHA/28facil-api/main/database/migrations/001_api_keys.sql

# Executar
docker compose exec -T mysql mysql -u root -p${DB_PASSWORD} 28facil_api < migration.sql
```

---

## 5️⃣ Gerar Primeira API Key

```bash
# Download do script
curl -O https://raw.githubusercontent.com/OARANHA/28facil-api/main/scripts/generate-key.php

# Executar
docker compose exec -T api-server php /tmp/generate-key.php "Minha Primeira Key" < <(cat generate-key.php)
```

**Ou manualmente via MySQL:**
```bash
docker compose exec mysql mysql -u root -p${DB_PASSWORD} 28facil_api
```

```sql
-- Gerar key (exemplo)
SET @full_key = '28fc_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6';
SET @key_hash = SHA2(@full_key, 256);

INSERT INTO api_keys (
    key_hash,
    key_prefix,
    name,
    permissions,
    rate_limit
) VALUES (
    @key_hash,
    '28fc_a1b2c3d4',
    'Primeira Key',
    JSON_ARRAY('read', 'write'),
    1000
);

SELECT * FROM api_keys;
```

---

## 6️⃣ Testar

```bash
# Health check
curl https://api.28facil.com.br/health | jq .

# Validar key
curl -H "X-API-Key: 28fc_sua_key_aqui" \
     https://api.28facil.com.br/auth/validate | jq .
```

---

## 🛠️ Comandos Úteis

### Ver logs
```bash
docker compose logs -f api-server
docker logs traefik
```

### Reiniciar
```bash
docker compose restart api-server
```

### Parar tudo
```bash
docker compose down
docker compose -f traefik-stack.yml down
```

### Backup do banco
```bash
docker compose exec mysql mysqldump -u root -p${DB_PASSWORD} 28facil_api > backup_$(date +%Y%m%d).sql
```

---

## 🐞 Troubleshooting

### API não responde
```bash
# Verificar containers
docker ps

# Ver logs
docker compose logs api-server

# Reiniciar
docker compose restart api-server
```

### SSL não funciona
```bash
# Verificar DNS
dig api.28facil.com.br +short
# Deve retornar o IP do servidor

# Ver logs do Traefik
docker logs traefik

# Verificar certificados
docker exec traefik ls -la /letsencrypt/
```

### MySQL não conecta
```bash
# Verificar se está rodando
docker compose ps mysql

# Ver logs
docker compose logs mysql

# Testar conexão
docker compose exec mysql mysql -u root -p
```

---

## 📚 Próximos Passos

Depois do deploy, você pode:

1. **Clonar repos para desenvolvimento:**
   ```bash
   git clone https://github.com/OARANHA/28facil-infra.git
   git clone https://github.com/OARANHA/28facil-api.git
   ```

2. **Instalar Portainer** (gerenciamento visual):
   ```bash
   curl -O https://raw.githubusercontent.com/OARANHA/28facil-infra/main/setup-portainer.sh
   chmod +x setup-portainer.sh
   ./setup-portainer.sh
   ```

3. **Usar cliente de monitoramento:**
   ```bash
   composer require aivopro/integrity
   ```

---

## 🔗 Links Úteis

- **Infraestrutura**: https://github.com/OARANHA/28facil-infra
- **API**: https://github.com/OARANHA/28facil-api
- **Cliente PHP**: https://github.com/OARANHA/aivopro-integrity
- **Documentação completa**: Ver README.md de cada repo

---

**Desenvolvido com ❤️ pela equipe 28Fácil**
