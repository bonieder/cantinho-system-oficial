#!/bin/bash
# =====================================================
# Cantinho System — Instalador automatizado (Ubuntu/Debian)
# =====================================================
# Execute como root ou com sudo:
#   sudo bash install-ubuntu.sh
# =====================================================

set -e

echo ""
echo "============================================="
echo "  Cantinho System — Instalador Ubuntu/Debian"
echo "============================================="
echo ""

# Verifica root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Execute como root: sudo bash install-ubuntu.sh"
  exit 1
fi

# 1. Atualiza pacotes
echo "[1/6] Atualizando pacotes..."
apt-get update -qq

# 2. Instala dependências
echo "[2/6] Instalando dependências (curl, ca-certificates, openssl)..."
apt-get install -y -qq curl ca-certificates openssl ufw

# 3. Instala Docker
if ! command -v docker &> /dev/null; then
  echo "[3/6] Instalando Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
else
  echo "[3/6] Docker já instalado ✓"
fi

# 4. Gera senhas seguras se .env não existe
if [ ! -f .env ]; then
  echo "[4/6] Gerando .env com senhas aleatórias..."
  POSTGRES_PASS=$(openssl rand -hex 24)
  JWT_SECRET=$(openssl rand -hex 32)
  ADMIN_PASS=$(openssl rand -hex 12)
  SERVER_IP=$(hostname -I | awk '{print $1}')

  cat > .env <<EOF
POSTGRES_DB=cantinho
POSTGRES_USER=cantinho
POSTGRES_PASSWORD=${POSTGRES_PASS}
SERVER_HOST=${SERVER_IP}
JWT_SECRET=${JWT_SECRET}
ADMIN_EMAIL=admin@cantinhodoboni.local
ADMIN_PASSWORD=${ADMIN_PASS}
EOF
  chmod 600 .env
  echo "     ✓ Arquivo .env criado com senhas aleatórias"
else
  echo "[4/6] Arquivo .env já existe — pulando geração"
fi

# 5. Configura firewall
echo "[5/6] Liberando portas no firewall (3000, 5432, 8000)..."
ufw allow 3000/tcp comment 'Cantinho Studio' >/dev/null 2>&1 || true
ufw allow 5432/tcp comment 'Cantinho PostgreSQL' >/dev/null 2>&1 || true
ufw allow 8000/tcp comment 'Cantinho API' >/dev/null 2>&1 || true

# 6. Sobe os contêineres
echo "[6/6] Subindo contêineres Docker..."
docker compose up -d

# Aguarda saúde do Postgres
echo ""
echo "⏳ Aguardando PostgreSQL ficar pronto..."
for i in {1..30}; do
  if docker compose exec -T postgres pg_isready -U cantinho >/dev/null 2>&1; then
    echo "   ✓ PostgreSQL pronto"
    break
  fi
  sleep 2
done

echo ""
echo "============================================="
echo "  ✅ Instalação concluída!"
echo "============================================="
echo ""
echo "📍 Endereços (rede local):"
echo "   • API:        http://${SERVER_IP:-$(hostname -I | awk '{print $1}')}:8000"
echo "   • Dashboard:  http://${SERVER_IP:-$(hostname -I | awk '{print $1}')}:3000"
echo "   • Postgres:   ${SERVER_IP:-$(hostname -I | awk '{print $1}')}:5432"
echo ""
echo "🔐 Credenciais (ANOTE!):"
grep -E "POSTGRES_PASSWORD|ADMIN_EMAIL|ADMIN_PASSWORD" .env
echo ""
echo "📥 Próximo passo — migrar dados da nuvem:"
echo "   apt install -y nodejs"
echo "   node migrate-from-cloud.mjs"
echo ""
echo "🔄 Para reiniciar:    docker compose restart"
echo "🛑 Para parar:        docker compose down"
echo "📊 Para ver logs:     docker compose logs -f"
echo ""
