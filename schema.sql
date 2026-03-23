-- ============================================================
--  CRM SAAS — SCHEMA COMPLETO (Supabase / PostgreSQL)
--  Versão 1.0 | Multi-tenant | White-Label
-- ============================================================

-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. EMPRESAS (tenants — cada cliente é uma empresa)
-- ============================================================
CREATE TABLE companies (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  slug          TEXT UNIQUE NOT NULL,         -- ex: techbrasil (usado no domínio)
  domain        TEXT UNIQUE,                  -- ex: crm.techbrasil.com.br
  logo_url      TEXT,
  primary_color TEXT DEFAULT '#185FA5',
  plan          TEXT DEFAULT 'starter'        -- starter | pro | enterprise
    CHECK (plan IN ('starter','pro','enterprise')),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. CONFIGURAÇÕES DA EMPRESA (onboarding + ajustes depois)
-- ============================================================
CREATE TABLE company_settings (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id               UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  -- Dados da loja
  business_type            TEXT,              -- varejo | servicos | tecnologia | outro
  phone                    TEXT,
  email                    TEXT,
  address                  TEXT,
  city                     TEXT,
  state                    TEXT,
  cnpj                     TEXT,
  -- Integrações
  whatsapp_token           TEXT,
  instagram_token          TEXT,
  -- Automações
  welcome_message          TEXT DEFAULT 'Olá! Como posso te ajudar?',
  no_reply_alert_minutes   INT DEFAULT 10,
  followup_hours           INT DEFAULT 24,
  -- Onboarding
  onboarding_completed     BOOLEAN DEFAULT FALSE,
  onboarding_step          INT DEFAULT 1,    -- qual etapa o usuário parou
  created_at               TIMESTAMPTZ DEFAULT NOW(),
  updated_at               TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (company_id)
);

-- ============================================================
-- 3. USUÁRIOS / LOGINS
-- ============================================================
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  password_hash TEXT NOT NULL,               -- bcrypt hash
  name          TEXT NOT NULL,
  role          TEXT DEFAULT 'seller'
    CHECK (role IN ('super_admin','admin','supervisor','seller')),
  avatar_url    TEXT,
  is_active     BOOLEAN DEFAULT TRUE,
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (company_id, email)
);

-- Permissões granulares por usuário
CREATE TABLE user_permissions (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  can_view_financial  BOOLEAN DEFAULT FALSE,
  can_edit_financial  BOOLEAN DEFAULT FALSE,
  can_view_all_leads  BOOLEAN DEFAULT FALSE,
  can_edit_stock      BOOLEAN DEFAULT FALSE,
  can_manage_users    BOOLEAN DEFAULT FALSE,
  can_export_data     BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id)
);

-- Tokens de sessão / refresh tokens
CREATE TABLE sessions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token         TEXT NOT NULL UNIQUE,
  refresh_token TEXT NOT NULL UNIQUE,
  expires_at    TIMESTAMPTZ NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. LEADS / CRM
-- ============================================================
CREATE TABLE leads (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  assigned_to   UUID REFERENCES users(id),
  name          TEXT NOT NULL,
  phone         TEXT,
  email         TEXT,
  channel       TEXT DEFAULT 'whatsapp'
    CHECK (channel IN ('whatsapp','instagram','indicacao','site','outro')),
  stage         TEXT DEFAULT 'novo'
    CHECK (stage IN ('novo','contato','proposta','negociacao','fechado_ganhou','fechado_perdeu')),
  temperature   TEXT DEFAULT 'morno'
    CHECK (temperature IN ('quente','morno','frio')),
  estimated_value NUMERIC(12,2) DEFAULT 0,
  notes         TEXT,
  last_contact  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. CHAT (mensagens WhatsApp + Instagram unificadas)
-- ============================================================
CREATE TABLE conversations (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  lead_id       UUID REFERENCES leads(id),
  assigned_to   UUID REFERENCES users(id),
  channel       TEXT NOT NULL CHECK (channel IN ('whatsapp','instagram')),
  external_id   TEXT,                        -- ID externo do contato
  status        TEXT DEFAULT 'open' CHECK (status IN ('open','closed','waiting')),
  unread_count  INT DEFAULT 0,
  last_message  TEXT,
  last_message_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender          TEXT NOT NULL CHECK (sender IN ('customer','agent','bot')),
  content         TEXT NOT NULL,
  message_type    TEXT DEFAULT 'text' CHECK (message_type IN ('text','image','audio','file')),
  media_url       TEXT,
  ai_suggestion   TEXT,                      -- sugestão gerada pela IA
  is_read         BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. VENDAS / PEDIDOS
-- ============================================================
CREATE TABLE orders (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  lead_id       UUID REFERENCES leads(id),
  seller_id     UUID REFERENCES users(id),
  order_number  SERIAL,
  product_name  TEXT NOT NULL,
  description   TEXT,
  amount        NUMERIC(12,2) NOT NULL,
  status        TEXT DEFAULT 'aguardando'
    CHECK (status IN ('aguardando','em_analise','pago','cancelado','reembolsado')),
  channel       TEXT,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. GARANTIAS
-- ============================================================
CREATE TABLE warranties (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  order_id      UUID REFERENCES orders(id),
  lead_id       UUID REFERENCES leads(id),
  description   TEXT NOT NULL,
  expires_at    DATE NOT NULL,
  status        TEXT DEFAULT 'ativa'
    CHECK (status IN ('ativa','vencida','acionada','resolvida')),
  claim_notes   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. FINANCEIRO
-- ============================================================
CREATE TABLE financial_transactions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  order_id      UUID REFERENCES orders(id),
  type          TEXT NOT NULL CHECK (type IN ('income','expense')),
  category      TEXT,                        -- vendas | comissao | despesa_fixa | etc
  amount        NUMERIC(12,2) NOT NULL,
  description   TEXT,
  due_date      DATE,
  paid_at       TIMESTAMPTZ,
  status        TEXT DEFAULT 'pendente' CHECK (status IN ('pendente','pago','cancelado')),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE commissions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id),
  order_id      UUID REFERENCES orders(id),
  amount        NUMERIC(12,2) NOT NULL,
  percentage    NUMERIC(5,2) DEFAULT 10.00,
  status        TEXT DEFAULT 'pendente' CHECK (status IN ('pendente','pago')),
  paid_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. LOGS DE AUDITORIA (segurança)
-- ============================================================
CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id  UUID REFERENCES companies(id),
  user_id     UUID REFERENCES users(id),
  action      TEXT NOT NULL,                 -- login | logout | create_lead | delete_user | etc
  entity      TEXT,                          -- leads | users | orders | etc
  entity_id   UUID,
  old_data    JSONB,
  new_data    JSONB,
  ip_address  TEXT,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES (performance)
-- ============================================================
CREATE INDEX idx_users_company       ON users(company_id);
CREATE INDEX idx_leads_company       ON leads(company_id);
CREATE INDEX idx_leads_assigned      ON leads(assigned_to);
CREATE INDEX idx_leads_stage         ON leads(stage);
CREATE INDEX idx_conversations_co    ON conversations(company_id);
CREATE INDEX idx_messages_conv       ON messages(conversation_id);
CREATE INDEX idx_orders_company      ON orders(company_id);
CREATE INDEX idx_orders_seller       ON orders(seller_id);
CREATE INDEX idx_warranties_company  ON warranties(company_id);
CREATE INDEX idx_financial_company   ON financial_transactions(company_id);
CREATE INDEX idx_audit_company       ON audit_logs(company_id);
CREATE INDEX idx_audit_user          ON audit_logs(user_id);

-- ============================================================
-- ROW LEVEL SECURITY (Supabase — isolamento por empresa)
-- ============================================================
ALTER TABLE companies            ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_settings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE users                ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads                ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages             ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders               ENABLE ROW LEVEL SECURITY;
ALTER TABLE warranties           ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs           ENABLE ROW LEVEL SECURITY;

-- Política: cada usuário só vê dados da sua empresa
CREATE POLICY "company_isolation" ON leads
  USING (company_id = (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "company_isolation" ON orders
  USING (company_id = (SELECT company_id FROM users WHERE id = auth.uid()));

-- ============================================================
-- TRIGGERS — updated_at automático
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_companies_updated
  BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_leads_updated
  BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_orders_updated
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- SEED: empresa demo + admin padrão (para testes)
-- ============================================================
INSERT INTO companies (id, name, slug, primary_color, plan)
VALUES ('00000000-0000-0000-0000-000000000001', 'Demo Company', 'demo', '#185FA5', 'pro');

INSERT INTO company_settings (company_id, business_type, onboarding_completed)
VALUES ('00000000-0000-0000-0000-000000000001', 'tecnologia', FALSE);

INSERT INTO users (company_id, email, password_hash, name, role)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'admin@demo.com',
  crypt('admin123', gen_salt('bf', 12)),   -- senha: admin123
  'Admin Demo',
  'admin'
);
