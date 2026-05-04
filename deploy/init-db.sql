-- =====================================================
-- Cantinho System — Schema inicial
-- Executado automaticamente no primeiro start do PostgreSQL
-- =====================================================

-- Cria role anônima (necessária pro PostgREST sem autenticação)
DO $$ BEGIN
  CREATE ROLE anon NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE ROLE authenticated NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Permite ao usuário principal mudar pra essas roles
GRANT anon, authenticated TO cantinho;

-- Tabela principal de armazenamento chave-valor (estilo Supabase kv_store)
-- O sistema serializa todos os módulos como entradas aqui
CREATE TABLE IF NOT EXISTS public.kv_store (
  key       TEXT PRIMARY KEY,
  value     JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice pra buscas por prefixo
CREATE INDEX IF NOT EXISTS kv_store_key_prefix_idx ON public.kv_store (key text_pattern_ops);

-- Trigger pra atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_kv_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS kv_store_updated_at ON public.kv_store;
CREATE TRIGGER kv_store_updated_at
  BEFORE UPDATE ON public.kv_store
  FOR EACH ROW EXECUTE FUNCTION update_kv_updated_at();

-- Permissões: anon pode ler/escrever (pra simplicidade na rede local do bar)
-- Em produção pública, restrinja com RLS (Row Level Security)
GRANT ALL ON public.kv_store TO anon, authenticated, cantinho;

-- Reload schema cache do PostgREST
NOTIFY pgrst, 'reload schema';
