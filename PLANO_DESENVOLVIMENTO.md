# Plano de Desenvolvimento — CRM SaaS Completo
## Sistema Multi-tenant White-Label | Flutter + Node.js + Supabase

---

## Stack Recomendada (e por quê)

| Camada | Tecnologia | Motivo |
|--------|-----------|--------|
| App (mobile + desktop) | Flutter 3 | 1 código → Android, iOS, macOS, Windows, Web |
| Backend/API | Node.js + Express | Rápido, muito suporte, fácil de hospedar |
| Banco de dados | Supabase (PostgreSQL) | Gratuito pra começar, Row-Level Security nativa |
| Autenticação | JWT + bcrypt | Padrão da indústria, seguro |
| Chat WhatsApp | Meta Cloud API | Oficial, não corre risco de ban |
| Chat Instagram | Meta Graph API | Oficial, integrado com WhatsApp |
| IA de vendas | OpenAI GPT-4o | Sugestão de respostas, classificação de leads |
| Storage (logos/arquivos) | Supabase Storage | Integrado, gratuito até 1GB |
| Deploy backend | Railway ou Render | Grátis pra começar, escala depois |
| Deploy app | Play Store + App Store + Web | Flutter faz tudo de uma vez |

---

## Estrutura de Arquivos Flutter

```
lib/
  main.dart                          ← roteador principal
  screens/
    auth/
      login_screen.dart              ← tela de login
    onboarding/
      onboarding_screen.dart         ← wizard configuração (1ª vez)
    dashboard/
      dashboard_screen.dart          ← visão geral + métricas
    crm/
      leads_screen.dart              ← kanban + lista de leads
      lead_detail_screen.dart        ← detalhe + histórico do lead
    chat/
      chat_list_screen.dart          ← inbox WhatsApp + Instagram
      chat_detail_screen.dart        ← conversa individual
    sales/
      sales_screen.dart              ← pedidos + status
      history_screen.dart            ← histórico de vendas
    warranty/
      warranty_screen.dart           ← garantias + vencimentos
    financial/
      financial_screen.dart          ← financeiro + comissões
    settings/
      settings_screen.dart           ← configurações gerais
      users_screen.dart              ← gerenciar logins (este arquivo)
      company_screen.dart            ← dados da empresa (editável)
  services/
    auth_service.dart
    company_service.dart
    users_service.dart
    leads_service.dart
    orders_service.dart
    chat_service.dart
    financial_service.dart
  models/
    user_model.dart
    lead_model.dart
    order_model.dart
    conversation_model.dart
  widgets/
    crm_button.dart
    crm_text_field.dart
    crm_metric_card.dart
    lead_card.dart
```

---

## Fluxo do Sistema (do zero ao CRM)

```
Acessa o app
    ↓
Tem sessão salva?
    ├── NÃO → Tela de Login (slug + email + senha)
    └── SIM ↓
         ↓
    Onboarding concluído?
         ├── NÃO → Wizard 4 etapas (dados da loja, cores, integrações)
         └── SIM → Dashboard CRM
                        ↓
                  [Configurações → Minha Empresa]
                  Editar tudo depois sem precisar
                  passar pelo onboarding novamente
```

---

## Plano de Desenvolvimento por Fases

### FASE 1 — Base do sistema (Semanas 1–3)
**Objetivo:** Login funcionando + onboarding + tela de usuários

| Tarefa | Tempo | Prioridade |
|--------|-------|-----------|
| Setup Flutter + Supabase | 1 dia | ★★★ |
| Banco de dados (schema.sql) | 1 dia | ★★★ |
| Backend Node.js básico | 2 dias | ★★★ |
| Tela de Login | 2 dias | ★★★ |
| Onboarding (wizard 4 etapas) | 3 dias | ★★★ |
| Gestão de usuários/logins | 2 dias | ★★★ |
| Configurações editáveis | 1 dia | ★★★ |
| Testes + ajustes | 3 dias | ★★★ |

**Entrega:** Sistema de acesso completo + multi-empresa funcionando

---

### FASE 2 — CRM + Leads (Semanas 4–5)
**Objetivo:** Gerenciar leads com kanban e IA de temperatura

| Tarefa | Tempo |
|--------|-------|
| Tela de leads (kanban + lista) | 3 dias |
| Formulário de lead | 1 dia |
| Filtros + busca | 1 dia |
| Classificação IA (quente/morno/frio) | 2 dias |
| Detalhe do lead + histórico | 2 dias |

---

### FASE 3 — Chat Unificado (Semanas 6–8)
**Objetivo:** WhatsApp + Instagram numa inbox só

| Tarefa | Tempo |
|--------|-------|
| Integração Meta API WhatsApp | 4 dias |
| Integração Instagram Graph API | 3 dias |
| Inbox unificada | 2 dias |
| Sugestões de resposta (IA) | 2 dias |
| Notificações push | 2 dias |

---

### FASE 4 — Vendas + Financeiro (Semanas 9–11)
**Objetivo:** Pedidos, histórico, garantias e fluxo de caixa

| Tarefa | Tempo |
|--------|-------|
| Módulo de vendas/pedidos | 2 dias |
| Histórico de vendas + filtros | 2 dias |
| Garantias + alertas | 2 dias |
| Financeiro + comissões | 3 dias |
| Dashboard de metas | 2 dias |

---

### FASE 5 — Polish + Deploy (Semanas 12–14)
**Objetivo:** Produto pronto para produção

| Tarefa | Tempo |
|--------|-------|
| White-label por empresa | 3 dias |
| Testes em dispositivos reais | 3 dias |
| Otimização performance | 2 dias |
| Deploy backend (Railway/Render) | 1 dia |
| Publicação Play Store | 3 dias |
| Publicação App Store | 5 dias* |
| Build macOS + Windows | 2 dias |

*App Store costuma demorar para aprovação

---

## Estimativa de Custos

### Desenvolvimento (se contratar)

| Perfil | Custo/hora | Tempo total | Total estimado |
|--------|-----------|------------|----------------|
| Dev Flutter Pleno | R$80–120/h | ~400h | R$32.000–48.000 |
| Dev Backend Node.js | R$70–100/h | ~200h | R$14.000–20.000 |
| Designer UX/UI | R$60–90/h | ~80h | R$4.800–7.200 |
| **Total MVP** | | | **R$50.000–75.000** |

### Se você desenvolver sozinho (com suporte de IA)
| Item | Custo |
|------|-------|
| Supabase (até 500MB banco + 50k usuários) | Grátis |
| Railway/Render (backend) | R$0–50/mês |
| OpenAI API (IA de vendas) | ~R$30–100/mês |
| Meta API (WhatsApp) | Pago por mensagem (~R$0,05–0,30 cada) |
| Apple Developer | R$540/ano |
| Google Play | R$130 (único) |
| **Total mensal inicial** | **~R$100–300/mês** |

---

## Infraestrutura Recomendada por Fase

### Fase inicial (0–100 clientes)
- **Supabase Free tier** — banco + auth + storage
- **Railway Starter** (~R$25/mês) — backend Node.js
- **Custo total:** R$25–50/mês

### Crescimento (100–1.000 clientes)
- **Supabase Pro** (R$115/mês)
- **Railway Pro** (R$100/mês)
- **Custo total:** R$215–400/mês

### Escala (1.000+ clientes)
- Migrar para AWS/GCP com auto-scaling
- **Custo:** R$800–3.000/mês (mas receita já justifica)

---

## Modelo de Precificação Sugerido (SaaS)

| Plano | Preço/mês | Limites | Margem estimada |
|-------|----------|---------|-----------------|
| Starter | R$97 | 2 usuários, 500 leads | ~85% |
| Pro | R$197 | 5 usuários, ilimitado | ~88% |
| Business | R$397 | 15 usuários, IA ativa | ~90% |
| Enterprise | R$797+ | Ilimitado, white-label | ~91% |

### Projeção de receita
| Clientes | Plano médio | MRR |
|---------|------------|-----|
| 50 | Pro R$197 | R$9.850 |
| 200 | Pro R$197 | R$39.400 |
| 500 | Mix | ~R$80.000 |
| 1.000 | Mix | ~R$150.000 |

---

## Próximos Passos Imediatos

1. **Criar conta Supabase** (supabase.com) — grátis
2. **Rodar o schema.sql** no SQL Editor do Supabase
3. **Instalar Flutter** (flutter.dev) — grátis
4. **Instalar Node.js** (nodejs.org) — grátis
5. **Clonar a estrutura de arquivos** entregue aqui
6. **Configurar variáveis de ambiente** (.env com suas chaves)
7. **Testar login + onboarding** localmente

---

## Variáveis de Ambiente Necessárias

### Backend (.env)
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhxxxxx
JWT_SECRET=um_segredo_muito_longo_e_aleatorio_aqui
PORT=3000
OPENAI_API_KEY=sk-xxxxx        (fase 2 em diante)
META_WHATSAPP_TOKEN=EAAxxxxx   (fase 3)
META_INSTAGRAM_TOKEN=IGQxxxxx  (fase 3)
```

### Flutter (lib/config.dart)
```dart
const supabaseUrl = 'https://xxxxx.supabase.co';
const supabaseAnonKey = 'eyJhxxxxx';
const apiBaseUrl = 'https://sua-api.railway.app';
```

---

*Gerado por VendaFlow CRM System — Plano v1.0*
