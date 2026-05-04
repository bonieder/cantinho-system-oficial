# =====================================================
# Cantinho System — Instalador automatizado (Windows)
# =====================================================
# Como usar:
#   1. Clique direito neste arquivo → "Executar com PowerShell"
#   2. Se pedir permissão de Administrador, clique "Sim"
#   3. Aguarde ~10 minutos (depende da internet)
# =====================================================

# Forca exibicao em UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Cantinho System - Instalador Windows" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. Verifica se esta rodando como Admin
# ============================================================
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERRO] Esse script precisa rodar como Administrador." -ForegroundColor Red
    Write-Host "       Clique direito no arquivo -> 'Executar com PowerShell'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "[1/7] Rodando como Administrador OK" -ForegroundColor Green

# ============================================================
# 2. Verifica versao do Windows
# ============================================================
$winBuild = [System.Environment]::OSVersion.Version.Build
if ($winBuild -lt 18362) {
    Write-Host "[ERRO] Windows muito antigo (build $winBuild)." -ForegroundColor Red
    Write-Host "       Necessario Windows 10 1903 (build 18362) ou superior." -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host "[2/7] Windows compativel (build $winBuild)" -ForegroundColor Green

# ============================================================
# 3. Verifica/instala WSL2 (Windows Subsystem for Linux 2)
# ============================================================
Write-Host "[3/7] Verificando WSL2..." -ForegroundColor Yellow
$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if (-not $wsl) {
    Write-Host "      Instalando WSL2 (pode demorar 5 min)..." -ForegroundColor Yellow
    wsl --install --no-launch
    Write-Host "      WSL2 instalado. ATENCAO: voce precisa REINICIAR o PC e rodar este script de novo." -ForegroundColor Yellow
    Read-Host "Pressione Enter para reiniciar agora"
    Restart-Computer -Force
    exit 0
}
Write-Host "      WSL2 ja instalado OK" -ForegroundColor Green

# ============================================================
# 4. Verifica/instala Docker Desktop
# ============================================================
Write-Host "[4/7] Verificando Docker Desktop..." -ForegroundColor Yellow
$dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerExe)) {
    Write-Host "      Baixando Docker Desktop..." -ForegroundColor Yellow
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installer = "$env:TEMP\DockerDesktopInstaller.exe"
    Invoke-WebRequest -Uri $dockerUrl -OutFile $installer -UseBasicParsing
    Write-Host "      Instalando Docker Desktop (5-10 min)..." -ForegroundColor Yellow
    Start-Process -FilePath $installer -ArgumentList "install --quiet --accept-license" -Wait
    Write-Host "      Docker Desktop instalado." -ForegroundColor Green
    Write-Host "      ATENCAO: voce precisa REINICIAR o PC e rodar este script de novo." -ForegroundColor Yellow
    Read-Host "Pressione Enter para reiniciar agora"
    Restart-Computer -Force
    exit 0
}
Write-Host "      Docker Desktop ja instalado OK" -ForegroundColor Green

# ============================================================
# 5. Garante que o Docker esta rodando
# ============================================================
Write-Host "[5/7] Iniciando Docker Desktop..." -ForegroundColor Yellow
Start-Process -FilePath $dockerExe -WindowStyle Hidden
Write-Host "      Aguardando Docker Engine ficar pronto (ate 60s)..." -ForegroundColor Yellow
$dockerReady = $false
for ($i = 0; $i -lt 60; $i++) {
    docker ps 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $dockerReady = $true; break }
    Start-Sleep -Seconds 1
}
if (-not $dockerReady) {
    Write-Host "[ERRO] Docker Engine nao iniciou. Abra o Docker Desktop manualmente e rode este script de novo." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host "      Docker Engine rodando OK" -ForegroundColor Green

# ============================================================
# 6. Cria .env com senhas aleatorias se nao existir
# ============================================================
Write-Host "[6/7] Configurando arquivo .env..." -ForegroundColor Yellow
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

if (-not (Test-Path ".env")) {
    # Gera senhas aleatorias
    Add-Type -AssemblyName System.Security
    function New-Senha([int]$tamanho) {
        $bytes = New-Object byte[] $tamanho
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        return [Convert]::ToBase64String($bytes).Replace('/','_').Replace('+','-').Substring(0, $tamanho)
    }

    $pgPass = New-Senha 32
    $jwtSecret = New-Senha 48
    $adminPass = New-Senha 16

    # Detecta o IP local
    $serverIp = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" } |
        Select-Object -First 1).IPAddress
    if (-not $serverIp) { $serverIp = "127.0.0.1" }

    $envContent = @"
POSTGRES_DB=cantinho
POSTGRES_USER=cantinho
POSTGRES_PASSWORD=$pgPass
SERVER_HOST=$serverIp
JWT_SECRET=$jwtSecret
ADMIN_EMAIL=admin@cantinhodoboni.local
ADMIN_PASSWORD=$adminPass
"@
    Set-Content -Path ".env" -Value $envContent -NoNewline
    Write-Host "      Arquivo .env criado com senhas aleatorias" -ForegroundColor Green
} else {
    Write-Host "      Arquivo .env ja existe (mantendo)" -ForegroundColor Yellow
}

# ============================================================
# 7. Sobe os conteineres
# ============================================================
Write-Host "[7/7] Subindo conteineres Docker..." -ForegroundColor Yellow
docker compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] Falha ao subir conteineres. Verifique o Docker Desktop." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Aguarda Postgres ficar pronto
Write-Host "      Aguardando PostgreSQL ficar pronto..." -ForegroundColor Yellow
for ($i = 0; $i -lt 30; $i++) {
    docker compose exec -T postgres pg_isready -U cantinho 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 2
}

# ============================================================
# 8. Libera firewall
# ============================================================
Write-Host "      Liberando portas no Firewall do Windows..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Cantinho API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName "Cantinho Studio" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName "Cantinho Postgres" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null

# ============================================================
# 9. Configura Docker pra subir automaticamente no boot
# ============================================================
$dockerStartup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Docker Desktop.lnk"
if (-not (Test-Path $dockerStartup)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($dockerStartup)
    $shortcut.TargetPath = $dockerExe
    $shortcut.Save()
    Write-Host "      Docker configurado para subir automaticamente no boot do Windows" -ForegroundColor Green
}

# ============================================================
# Finaliza
# ============================================================
$envData = Get-Content ".env" -Raw
$serverIp = ($envData -split "`n" | Where-Object { $_ -like "SERVER_HOST=*" }) -replace "SERVER_HOST=",""
$pgPass = ($envData -split "`n" | Where-Object { $_ -like "POSTGRES_PASSWORD=*" }) -replace "POSTGRES_PASSWORD=",""
$adminPass = ($envData -split "`n" | Where-Object { $_ -like "ADMIN_PASSWORD=*" }) -replace "ADMIN_PASSWORD=",""

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  INSTALACAO CONCLUIDA!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Enderecos (rede local do bar):" -ForegroundColor Cyan
Write-Host "  API:       http://${serverIp}:8000"
Write-Host "  Dashboard: http://${serverIp}:3000"
Write-Host "  Postgres:  ${serverIp}:5432"
Write-Host ""
Write-Host "Credenciais (ANOTE em local seguro!):" -ForegroundColor Yellow
Write-Host "  Postgres password: $pgPass"
Write-Host "  Admin (pgAdmin):   admin@cantinhodoboni.local / $adminPass"
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "  1. Abra https://bonieder.github.io/cantinho-system-oficial/"
Write-Host "  2. Login como Admin -> Setup -> Servidor de banco de dados"
Write-Host "  3. Marque 'Self-hosted', cole a URL: http://${serverIp}:8000"
Write-Host "  4. Clique 'Testar conexao' e depois 'Salvar'"
Write-Host ""
Write-Host "Comandos uteis (PowerShell na pasta deploy):" -ForegroundColor Cyan
Write-Host "  Status:    docker compose ps"
Write-Host "  Logs:      docker compose logs -f"
Write-Host "  Reiniciar: docker compose restart"
Write-Host "  Parar:     docker compose down"
Write-Host ""
Read-Host "Pressione Enter para fechar"
