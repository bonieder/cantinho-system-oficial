#!/bin/bash
# =====================================================
# Cantinho System — Setup completo VPS em 1 comando
# =====================================================
# Uso (no VPS Ubuntu, como root):
#   curl -fsSL https://raw.githubusercontent.com/bonieder/cantinho-system-oficial/main/deploy/vps-quickstart.sh | bash -s -- DOMINIO
#
# Exemplos:
#   bash vps-quickstart.sh cantinhodoboni.com.br
#   bash vps-quickstart.sh cantinhodoboni.duckdns.org
#
# Pré-requisito: o domínio (ou subdomínio) DEVE ter DNS apontando pro IP do VPS
# (registros A pra @, api, db, wa)
# =====================================================

set -e

DOMAIN="${1:-}"

echo ""
echo "============================================="
echo "  Cantinho System — VPS Quickstart"
echo "============================================="
echo ""

# Verifica root
if [ "$EUID" -ne 0 ]; then
  echo "[ERRO] Execute como root: sudo bash vps-quickstart.sh DOMINIO"
  exit 1
fi

# Verifica domínio
if [ -z "$DOMAIN" ]; then
  echo "[ERRO] Informe o domínio:"
  echo "  bash vps-quickstart.sh cantinhodoboni.com.br"
  echo ""
  echo "Ou use um subdomínio gratuito do DuckDNS:"
  echo "  1. Crie conta em https://www.duckdns.org"
  echo "  2. Crie um subdomínio (ex: cantinhodoboni)"
  echo "  3. Aponte pro IP do VPS"
  echo "  4. Rode: bash vps-quickstart.sh cantinhodoboni.duckdns.org"
  exit 1
fi

echo "→ Domínio: $DOMAIN"
echo "→ Vai criar: api.$DOMAIN, db.$DOMAIN, wa.$DOMAIN"
echo ""

# 1. Atualiza pacotes
echo "[1/8] Atualizando sistema..."
apt-get update -qq
apt-get install -y -qq curl ca-certificates openssl ufw git

# 2. Instala Docker
if ! command -v docker &> /dev/null; then
  echo "[2/8] Instalando Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
else
  echo "[2/8] Docker OK"
fi

# 3. Clona repo se não existe
if [ ! -d "/opt/cantinho-system" ]; then
  echo "[3/8] Baixando código..."
  git clone https://github.com/bonieder/cantinho-system-oficial.git /opt/cantinho-system
else
  echo "[3/8] Atualizando código..."
  cd /opt/cantinho-system && git pull
fi

cd /opt/cantinho-system/deploy

# 4. Gera .env se não existir
if [ ! -f .env ]; then
  echo "[4/8] Gerando .env com senhas seguras..."
  POSTGRES_PASS=$(openssl rand -hex 24)
  JWT_SECRET=$(openssl rand -hex 32)
  ADMIN_PASS=$(openssl rand -hex 12)
  EVO_KEY=$(openssl rand -hex 16)

  cat > .env <<EOF
POSTGRES_DB=cantinho
POSTGRES_USER=cantinho
POSTGRES_PASSWORD=${POSTGRES_PASS}
DOMAIN=${DOMAIN}
JWT_SECRET=${JWT_SECRET}
ADMIN_EMAIL=admin@${DOMAIN}
ADMIN_PASSWORD=${ADMIN_PASS}
EVOLUTION_API_KEY=${EVO_KEY}
EOF
  chmod 600 .env
  echo "    .env criado com senhas aleatórias"
else
  echo "[4/8] .env já existe"
fi

# 5. Firewall
echo "[5/8] Configurando firewall..."
ufw --force enable
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP (Caddy)'
ufw allow 443/tcp comment 'HTTPS (Caddy)'
echo "    Firewall: SSH + HTTP + HTTPS"

# 6. Sobe os contêineres
echo "[6/8] Subindo stack Docker (pode demorar 2-3 min)..."
docker compose pull
docker compose up -d

# 7. Aguarda saúde
echo "[7/8] Aguardando PostgreSQL..."
for i in {1..30}; do
  if docker compose exec -T postgres pg_isready -U cantinho >/dev/null 2>&1; then
    echo "    PostgreSQL OK"
    break
  fi
  sleep 2
done

# 8. Mostra resumo
echo ""
echo "============================================="
echo "  ✅ Instalação concluída!"
echo "============================================="
echo ""
echo "📍 Endereços públicos (HTTPS automático via Let's Encrypt):"
echo "   • API REST (kv_store): https://api.${DOMAIN}"
echo "   • Dashboard pgAdmin:    https://db.${DOMAIN}"
echo "   • WhatsApp Evolution:   https://wa.${DOMAIN}"
echo ""
echo "🔐 Credenciais (anote e GUARDE com segurança):"
grep -E "POSTGRES_PASSWORD|ADMIN_EMAIL|ADMIN_PASSWORD|EVOLUTION_API_KEY" .env
echo ""
echo "📥 Próximos passos:"
echo ""
echo "   1) DNS: aponte os subdomínios pro IP deste VPS:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "<IP do VPS>")
echo "      • api.${DOMAIN}  →  ${SERVER_IP}"
echo "      • db.${DOMAIN}   →  ${SERVER_IP}"
echo "      • wa.${DOMAIN}   →  ${SERVER_IP}"
echo "      (Caddy gera HTTPS automático em 1-2 min após DNS propagar)"
echo ""
echo "   2) Migre dados do Supabase Cloud:"
echo "      apt install -y nodejs"
echo "      cd /opt/cantinho-system/deploy"
echo "      LOCAL_API_URL=https://api.${DOMAIN} node migrate-from-cloud.mjs"
echo ""
echo "   3) Configure no sistema (Mac/celular):"
echo "      • Abra https://bonieder.github.io/cantinho-system-oficial/"
echo "      • Login → Setup → Servidor de banco de dados"
echo "      • Self-hosted → URL: https://api.${DOMAIN}"
echo "      • Salvar"
echo ""
echo "🔄 Para reiniciar:    cd /opt/cantinho-system/deploy && docker compose restart"
echo "🛑 Para parar:        docker compose down"
echo "📊 Para ver logs:     docker compose logs -f"
echo ""
