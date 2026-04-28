# Cantinho System

Sistema completo de gestão para bar/restaurante — desenvolvido para o **Cantinho do Boni Colorado LTDA**.

100% client-side, sem backend, sem custo de hospedagem. Funciona em qualquer navegador moderno e pode ser hospedado gratuitamente no GitHub Pages.

---

## 🎯 Features

### Operacional
- ☑ **Checklists Operacionais** com IA local (validação automática)
- 🏷 **Etiquetas de Validade** com impressão térmica 60×40mm + código de barras
- 📅 **Reservas** de mesa com tipos de ocasião, lista de espera, no-show tracking
- 📦 **Estoque** segregado por 12 locais físicos (câmaras frias, freezers, mercearia, etc.)
- 📋 **Inventário** parcial por local com contagem cédula a cédula
- 🛒 **Pedidos de Compra** com fluxo solicitação → aprovação → recebimento → entrada no estoque

### Financeiro
- 🏦 **Integração Itaú** via OFX (parser próprio + classificação automática)
- 💵 **Controle de Caixa** com sangria, contagem de cédulas, fechamento
- 📊 **DRE** comparativa com drill-down + análise de fornecedores
- 💰 **Pagamento de Freelancers** com recibo de prestação de serviços
- 📈 **CMV** com fichas técnicas
- 📅 **Mês de competência** para apropriação correta (folha paga em maio referente a abril)

### Cadastros
- 👥 Funcionários, fornecedores, clientes, prestadores PJ
- 🔐 **Usuários e Acesso** (RBAC granular por módulo)
- 🏛 Dados da empresa editáveis

### IA / Automação
- 🧠 Categorização inteligente do extrato bancário (memória do usuário)
- 📥 Detecção de duplicatas + saldos no OFX
- 🤖 Classificação por regras + histórico
- 📷 Foto obrigatória de comprovação no checklist

---

## 🚀 Deploy no GitHub Pages

### Passo a passo

1. **Criar o repositório**
   ```bash
   gh repo create cantinho-system --public
   ```

2. **Subir os arquivos**
   ```bash
   cd cantinho-system/
   git init
   git add index.html seed-produtos.js README.md .gitignore LICENSE
   git commit -m "Initial commit — Cantinho System v1"
   git branch -M main
   git remote add origin https://github.com/SEU-USUARIO/cantinho-system.git
   git push -u origin main
   ```

3. **Ativar GitHub Pages**
   - Acesse `Settings → Pages` no repositório
   - Em "Source", selecione **Deploy from a branch**
   - Escolha branch `main` e pasta `/ (root)`
   - Salve

4. **Acessar**
   - URL: `https://SEU-USUARIO.github.io/cantinho-system/`
   - Disponível em ~1 minuto após o save

### Domínio personalizado (opcional)
1. No `Settings → Pages`, em **Custom domain**, digite `app.cantinhodoboni.com.br`
2. No seu provedor de DNS, crie um registro CNAME apontando para `SEU-USUARIO.github.io`
3. Aguarde propagação DNS (~10min)
4. GitHub gera certificado HTTPS automaticamente via Let's Encrypt

---

## 🔐 Login

**Usuários demo pré-cadastrados** (todos com senha `cantinho123`):

| Email | Perfil | Acesso |
|---|---|---|
| `boni@cantinhodoboni.com` | Admin | Todos os 16 módulos |
| `carla@cantinhodoboni.com` | Gerente | Tudo exceto Usuários |
| `joao@cantinhodoboni.com` | Operador | Checklist, Compras, Estoque, Etiquetas |
| `maria@cantinhodoboni.com` | Operador | Idem |
| `pedro@cantinhodoboni.com` | Estoquista | Estoque, Almoxarifado, Compras |
| `ana@cantinhodoboni.com` | Caixa | Apenas Caixa |

> ⚠️ **Importante:** após o primeiro login, troque as senhas em **Usuários e Acesso** ou edite o código antes de subir para o GitHub.

---

## ⚠️ Limitações da hospedagem GitHub Pages

GitHub Pages é **estático** — não há banco de dados centralizado. Todos os dados ficam no `localStorage` do navegador de cada usuário, ou seja:

- ✅ Funciona perfeitamente para **um único computador** (caixa do estabelecimento)
- ❌ **Não sincroniza** entre múltiplos computadores ou tablets
- ❌ Limpar cache do navegador apaga todos os dados

Para uso multi-usuário com sincronização real, veja o módulo **Setup & Instalação** dentro do sistema com 3 opções:
- 🏠 Raspberry Pi + PocketBase (R$ 800 único + R$ 6/mês)
- ☁️ Supabase free tier (R$ 0/mês até 500MB)
- 🖥 VPS Hostinger/Contabo (R$ 30-50/mês)

---

## 📦 Estrutura do projeto

```
cantinho-system/
├── index.html        # Aplicação completa (520 KB)
├── seed-produtos.js  # 468 produtos pré-cadastrados (~30 KB)
├── README.md         # Este arquivo
├── .gitignore
└── LICENSE
```

Apenas isso. Sem build, sem dependências NPM, sem backend.

---

## 🛠 Stack técnica

- **Frontend**: HTML + Tailwind CSS via CDN
- **JavaScript**: vanilla ES2020+ (sem framework)
- **Charts**: Chart.js via CDN
- **Códigos de barras**: JsBarcode via CDN
- **Persistência**: localStorage com namespace `cantinho:`
- **Auth**: SHA-256 via `crypto.subtle` (Web Crypto API nativa)

---

## 🧪 Testar localmente antes do deploy

Não precisa de servidor — abra direto no navegador:

```bash
cd cantinho-system/
open index.html  # macOS
xdg-open index.html  # Linux
start index.html  # Windows
```

Ou se preferir um servidor estático:

```bash
python3 -m http.server 8000 --directory .
# Acesse http://localhost:8000
```

---

## 📄 Backup e exportação dos dados

Como tudo fica no `localStorage`, para fazer backup manual:

```js
// No DevTools Console:
const backup = {};
Object.keys(localStorage).filter(k => k.startsWith('cantinho:')).forEach(k => backup[k] = localStorage[k]);
copy(JSON.stringify(backup));
// Cole em um arquivo .json e guarde
```

Para restaurar:
```js
const backup = /* cole o JSON aqui */;
Object.entries(backup).forEach(([k,v]) => localStorage.setItem(k, v));
location.reload();
```

---

## 📝 Licença

MIT — veja `LICENSE`. Use, modifique e distribua livremente.

---

## 🤝 Contribuindo

Pull requests bem-vindos. Mantenha o código em vanilla JS sem build step para preservar a simplicidade de deploy.
