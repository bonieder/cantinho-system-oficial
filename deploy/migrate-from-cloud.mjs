#!/usr/bin/env node
// =====================================================
// Cantinho System — Migração Supabase Cloud → Self-hosted
// =====================================================
// Uso:
//   node migrate-from-cloud.mjs
//
// Pré-requisitos:
//   1. Stack local rodando (docker compose up -d)
//   2. Variáveis de ambiente preenchidas (veja --help)
// =====================================================

const CLOUD_URL = process.env.CLOUD_SUPABASE_URL || 'https://ropzcmibzqylcukwkyzu.supabase.co';
const CLOUD_KEY = process.env.CLOUD_SUPABASE_KEY || 'sb_publishable_dOyD2PHNJS3NqHVB2eSBzg_Tvxxi4jZ';
const LOCAL_URL = process.env.LOCAL_API_URL  || 'http://localhost:8000';

if(process.argv.includes('--help') || process.argv.includes('-h')){
  console.log(`
Cantinho System — Migração de dados Supabase Cloud → Self-hosted

VARIÁVEIS:
  CLOUD_SUPABASE_URL    URL do Supabase nuvem (default: projeto Cantinho)
  CLOUD_SUPABASE_KEY    Chave anon do Supabase nuvem
  LOCAL_API_URL         URL da API local (default: http://localhost:8000)

EXEMPLOS:
  # Migra usando os defaults (Supabase Cloud do Cantinho → http://localhost:8000)
  node migrate-from-cloud.mjs

  # Especificando outro servidor local
  LOCAL_API_URL=http://192.168.0.100:8000 node migrate-from-cloud.mjs
`);
  process.exit(0);
}

async function main(){
  console.log('🚀 Cantinho System — Migração de dados\n');
  console.log(`📥 Origem: ${CLOUD_URL}`);
  console.log(`📤 Destino: ${LOCAL_URL}\n`);

  // 1. Lê todos os dados do Supabase Cloud
  console.log('1/3  Lendo dados do Supabase Cloud...');
  let cloudData;
  try {
    const resp = await fetch(`${CLOUD_URL}/rest/v1/kv_store?select=key,value`, {
      headers: { 'apikey': CLOUD_KEY, 'Authorization': `Bearer ${CLOUD_KEY}` }
    });
    if(!resp.ok) throw new Error(`HTTP ${resp.status}: ${await resp.text()}`);
    cloudData = await resp.json();
    console.log(`     ✓ ${cloudData.length} registros encontrados na nuvem\n`);
  } catch(e){
    console.error('❌ Falha ao ler nuvem:', e.message);
    process.exit(1);
  }

  if(!cloudData.length){
    console.log('⚠ Nenhum dado pra migrar. Encerrando.');
    return;
  }

  // 2. Verifica se o servidor local está respondendo
  console.log('2/3  Testando conexão com servidor local...');
  try {
    const test = await fetch(`${LOCAL_URL}/`, { method: 'GET' });
    console.log(`     ✓ Servidor local respondeu (HTTP ${test.status})\n`);
  } catch(e){
    console.error(`❌ Não consegui conectar em ${LOCAL_URL}`);
    console.error('   Confira se o Docker está rodando: docker compose ps');
    process.exit(1);
  }

  // 3. Insere em batches
  console.log('3/3  Migrando para o servidor local...');
  const BATCH = 50;
  let migrados = 0, erros = 0;
  for(let i = 0; i < cloudData.length; i += BATCH){
    const chunk = cloudData.slice(i, i + BATCH);
    try {
      const resp = await fetch(`${LOCAL_URL}/kv_store`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates,return=minimal'
        },
        body: JSON.stringify(chunk)
      });
      if(!resp.ok){
        const txt = await resp.text();
        console.error(`     ⚠ Lote ${i}–${i+chunk.length}: HTTP ${resp.status} — ${txt.slice(0,200)}`);
        erros += chunk.length;
      } else {
        migrados += chunk.length;
        process.stdout.write(`\r     Progresso: ${migrados}/${cloudData.length} (${Math.round(migrados/cloudData.length*100)}%)`);
      }
    } catch(e){
      console.error(`\n     ❌ Erro no lote ${i}: ${e.message}`);
      erros += chunk.length;
    }
  }

  console.log(`\n\n${erros === 0 ? '✅' : '⚠'} Migração concluída`);
  console.log(`   Migrados: ${migrados}`);
  console.log(`   Erros:    ${erros}`);
  console.log(`\n📊 Próximo passo: abra ${LOCAL_URL.replace(':8000',':3000')} pra ver os dados no dashboard.`);
  console.log('\n💡 Configure o sistema:');
  console.log(`   1. Abra https://bonieder.github.io/cantinho-system-oficial/`);
  console.log(`   2. Login como Admin`);
  console.log(`   3. Vá em Setup & Instalação → Servidor`);
  console.log(`   4. Cole a URL: ${LOCAL_URL}`);
  console.log(`   5. Clique "Salvar e usar este servidor"`);
}

main().catch(e => { console.error(e); process.exit(1); });
