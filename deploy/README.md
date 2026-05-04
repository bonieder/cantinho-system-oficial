# Cantinho System — Servidor Self-hosted

Pacote para rodar o **Cantinho System** com PostgreSQL próprio no servidor do bar.
Substitui o Supabase Cloud — você passa a ter controle total dos dados, sem custo recorrente de cloud.

---

## 📋 O que vem nesse pacote

| Arquivo | O que faz |
|---|---|
| `docker-compose.yml` | Define os 4 contêineres (Postgres, PostgREST, Studio, Backup) |
| `init-db.sql` | Cria a tabela `kv_store` automaticamente |
| `.env.example` | Template de variáveis de ambiente (senhas, IP) |
| `install-ubuntu.sh` | Instalador automatizado pra Ubuntu/Debian |
| `migrate-from-cloud.mjs` | Migra os dados do Supabase Cloud → seu servidor |
| `README.md` | Este guia |

---

## ⚙ Pré-requisitos

### Servidor
- **Sistema:** Ubuntu 22.04 LTS ou Debian 12 (recomendados)
- **RAM:** mínimo 2 GB · ideal 4 GB
- **Disco:** mínimo 20 GB livres
- **Rede:** conectado à internet via cabo (recomendado) ou Wi-Fi do bar
- **Energia:** liguar 24/7 (ou aceitar que o sistema cai quando desliga)

### Hardware sugerido (escolha um)

| Opção | Custo | Característica |
|---|---|---|
| **Mini PC** (Beelink, Intel NUC, etc) | R$ 1.200–2.500 | Compacto, silencioso, baixo consumo |
| **PC velho** com Linux | R$ 0–500 | Aproveita o que você tem |
| **Raspberry Pi 5 + SSD externo** | R$ 1.500 (kit completo) | Pequeno e econômico (~5W) |
| **VPS Hostinger KVM2** | R$ 30/mês | Sem hardware físico, na nuvem |

---

## 🚀 Instalação automática (Ubuntu/Debian)

```bash
# 1) Baixe os arquivos no servidor
git clone https://github.com/bonieder/cantinho-system-oficial.git
cd cantinho-system-oficial/deploy

# 2) Execute o instalador (ele cuida de Docker, .env, firewall, etc)
sudo bash install-ubuntu.sh

# 3) Anote as senhas que aparecem no final
```

Pronto! Em ~3 minutos o servidor estará rodando.

---

## 📥 Migrar dados do Supabase Cloud (opcional)

Se você já tem dados na nuvem (Supabase Pro), pode migrar tudo de uma vez:

```bash
# Instale Node.js (se ainda não tem)
sudo apt install -y nodejs

# Migra todos os dados
node migrate-from-cloud.mjs
```

O script:
- Lê todos os registros da nuvem
- Insere no servidor local
- Mostra progresso e erros
- Não duplica (usa upsert)

---

## 🔌 Conectar o sistema ao servidor

1. Acesse `https://bonieder.github.io/cantinho-system-oficial/`
2. Faça login como **Admin**
3. Vá em **Setup & Instalação**
4. Em **🗄 Servidor de banco de dados**:
   - Marque **🏠 Self-hosted**
   - URL do servidor: `http://192.168.0.X:8000` (use o IP do seu servidor)
   - Clique **🧪 Testar conexão**
   - Se aparecer ✓ verde, clique **💾 Salvar e usar este servidor**
5. O sistema vai recarregar e passar a usar seu servidor local

---

## 🌐 Configurar IP fixo no roteador

**Importante:** o IP do servidor não pode mudar (senão o sistema perde a conexão).

1. Acesse a interface admin do roteador (geralmente `http://192.168.0.1` ou `http://192.168.1.1`)
2. Procure por **DHCP** → **Reserva de IP** ou **DHCP Static**
3. Adicione uma reserva:
   - **MAC Address:** veja no servidor com `ip a | grep ether`
   - **IP:** escolha um (ex: `192.168.0.100`)
4. Reinicie o servidor pra pegar o IP novo

---

## 🔒 Segurança básica

Por padrão o servidor só responde na rede local. Mas vale reforçar:

```bash
# Firewall (já configurado pelo install-ubuntu.sh)
sudo ufw enable
sudo ufw allow from 192.168.0.0/24 to any port 8000  # API
sudo ufw allow from 192.168.0.0/24 to any port 3000  # Dashboard
sudo ufw deny 5432  # Postgres só acessível dentro do Docker
```

⚠ **NÃO abra essas portas para a internet** sem antes configurar HTTPS + autenticação JWT. Se quiser acesso de fora, use uma VPN (WireGuard) ou um VPS com domínio + Cloudflare.

---

## 📦 Backup

### Backup automático (já configurado)
O contêiner `cantinho-backup` roda `pg_dump` **a cada 24h** e mantém os 14 últimos backups em `./backups/`.

### Backup manual

```bash
# Snapshot agora
docker compose exec postgres pg_dump -U cantinho cantinho > backup-$(date +%F).sql

# Restaurar
docker compose exec -T postgres psql -U cantinho cantinho < backup-2026-05-01.sql
```

### Levar pro Drive/Dropbox
```bash
# Instale rclone uma vez
curl https://rclone.org/install.sh | sudo bash
rclone config  # configura Drive

# Sincroniza pasta de backups (rode no cron)
rclone sync ./backups remote:CantinhoBackups
```

---

## 🛠 Comandos úteis

```bash
# Status dos contêineres
docker compose ps

# Ver logs
docker compose logs -f
docker compose logs -f postgres

# Reiniciar
docker compose restart

# Parar
docker compose down

# Subir de novo
docker compose up -d

# Atualizar imagens
docker compose pull && docker compose up -d

# Acessar o Postgres direto
docker compose exec postgres psql -U cantinho cantinho

# Ver tamanho do banco
docker compose exec postgres psql -U cantinho cantinho -c "SELECT pg_size_pretty(pg_database_size('cantinho'));"
```

---

## 🆘 Troubleshooting

### "Erro: connection refused"
- Verifique se o Docker está rodando: `docker compose ps`
- Verifique a porta 8000: `curl http://localhost:8000/`

### "Schema não atualizou"
- Reinicie o PostgREST: `docker compose restart postgrest`

### "Disco cheio"
- Limpe backups antigos: `find ./backups -name '*.sql' -mtime +30 -delete`
- Limpe imagens Docker: `docker system prune -a`

### "Esqueci a senha"
- Veja no `.env`: `cat .env`
- Pra resetar: edite `.env`, depois `docker compose restart`

### "Quero voltar pro Supabase Cloud"
- No sistema, vá em Setup → Servidor → clique **↩ Voltar para Cloud**
- Os dados continuam no Cloud (a migração não apagou nada lá)

---

## 📞 Suporte

Sistema desenvolvido por Cantinho do Boni Colorado LTDA.
Repositório: https://github.com/bonieder/cantinho-system-oficial

Pra dúvidas técnicas, abra uma issue no repositório.
