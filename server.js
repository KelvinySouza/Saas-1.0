// ============================================================
//  server.js — Backend Node.js + Supabase
//  CRM SaaS Multi-tenant | Express + JWT + bcrypt
// ============================================================

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

const app = express();

// Segurança
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));
app.use(morgan('combined')); // Log de auditoria
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS || 'http://localhost:3000', // Configure para produção
  credentials: true,
}));
app.use(express.json({ limit: '10mb' })); // Limite de payload

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // Limite de 100 requisições por IP
  message: 'Muitas requisições, tente novamente mais tarde.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Rate limiting mais restritivo para auth
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Muitas tentativas de login, tente novamente mais tarde.',
});
// Força HTTPS em produção
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (req.header('x-forwarded-proto') !== 'https') {
      res.redirect(`https://${req.header('host')}${req.url}`);
    } else {
      next();
    }
  });
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY   // service_role key (server-side)
);

const JWT_SECRET = process.env.JWT_SECRET || 'f4a8b9c2d3e4f5678901234567890abcdef1234567890abcdef1234567890abcdef'; // Use uma chave forte e única
const JWT_EXPIRES = '1h'; // Reduzido para mais segurança
const REFRESH_EXPIRES = '7d';

// ============================================================
// MIDDLEWARE — autenticação JWT
// ============================================================
const auth = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer '))
    return res.status(401).json({ error: 'Token não fornecido' });

  try {
    const token = header.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido ou expirado' });
  }
};

// Middleware de log de auditoria
const auditLog = (action, entity) => async (req, res, next) => {
  res.on('finish', async () => {
    if (res.statusCode < 400) {
      await supabase.from('audit_logs').insert({
        company_id: req.user?.companyId,
        user_id: req.user?.userId,
        action,
        entity,
        entity_id: req.params.id,
        ip_address: req.ip,
        user_agent: req.headers['user-agent'],
      });
    }
  });
  next();
};

// ============================================================
// AUTH — Login
// ============================================================
app.post('/api/auth/login', [
  body('slug').isLength({ min: 3, max: 50 }).withMessage('Slug inválido'),
  body('email').isEmail().normalizeEmail().withMessage('Email inválido'),
  body('password').isLength({ min: 8 }).withMessage('Senha deve ter pelo menos 8 caracteres'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { slug, email, password } = req.body;

  // Buscar empresa pelo slug
  const { data: company } = await supabase
    .from('companies')
    .select('id, name, is_active')
    .eq('slug', slug)
    .single();

  if (!company || !company.is_active)
    return res.status(401).json({ error: 'Empresa não encontrada' });

  // Buscar usuário
  const { data: user } = await supabase
    .from('users')
    .select('id, name, email, password_hash, role, is_active')
    .eq('company_id', company.id)
    .eq('email', email)
    .single();

  if (!user || !user.is_active)
    return res.status(401).json({ error: 'Credenciais inválidas' });

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid)
    return res.status(401).json({ error: 'Credenciais inválidas' });

  // Verificar onboarding
  const { data: settings } = await supabase
    .from('company_settings')
    .select('onboarding_completed')
    .eq('company_id', company.id)
    .single();

  // Gerar tokens
  const payload = { userId: user.id, companyId: company.id, role: user.role };
  const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES });
  const refreshToken = jwt.sign(payload, JWT_SECRET, { expiresIn: REFRESH_EXPIRES });

  // Salvar sessão
  const expiresAt = new Date(Date.now() + 8 * 60 * 60 * 1000);
  await supabase.from('sessions').insert({ user_id: user.id, token, refresh_token: refreshToken, expires_at: expiresAt });

  // Atualizar last_login
  await supabase.from('users').update({ last_login: new Date() }).eq('id', user.id);

  res.json({
    token,
    refreshToken,
    user: { id: user.id, name: user.name, email: user.email, role: user.role },
    company: { id: company.id, name: company.name, slug },
    onboardingCompleted: settings?.onboarding_completed ?? false,
  });
});

// Logout
app.post('/api/auth/logout', auth, async (req, res) => {
  const token = req.headers.authorization.split(' ')[1];
  await supabase.from('sessions').delete().eq('token', token);
  res.json({ ok: true });
});

// Refresh token
app.post('/api/auth/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  try {
    const decoded = jwt.verify(refreshToken, JWT_SECRET);
    const { data: session } = await supabase
      .from('sessions')
      .select('id')
      .eq('refresh_token', refreshToken)
      .single();
    if (!session) throw new Error('Session not found');
    const newToken = jwt.sign(
      { userId: decoded.userId, companyId: decoded.companyId, role: decoded.role },
      JWT_SECRET, { expiresIn: JWT_EXPIRES }
    );
    await supabase.from('sessions').update({ token: newToken }).eq('refresh_token', refreshToken);
    res.json({ token: newToken });
  } catch {
    res.status(401).json({ error: 'Refresh token inválido' });
  }
});

// ============================================================
// ONBOARDING — Salvar dados da empresa
// ============================================================
app.post('/api/onboarding', auth, async (req, res) => {
  const { name, slug, email, phone, cnpj, address, city, businessType,
          primaryColor, whatsappToken, instagramToken, welcomeMessage } = req.body;

  const { companyId } = req.user;

  await supabase.from('companies').update({
    name, slug, primary_color: primaryColor,
  }).eq('id', companyId);

  await supabase.from('company_settings').upsert({
    company_id: companyId,
    email, phone, cnpj, address, city,
    business_type: businessType,
    whatsapp_token: whatsappToken,
    instagram_token: instagramToken,
    welcome_message: welcomeMessage,
    onboarding_completed: true,
    onboarding_step: 4,
  }, { onConflict: 'company_id' });

  res.json({ ok: true });
});

// ============================================================
// CONFIGURAÇÕES — Editar dados da empresa (após onboarding)
// ============================================================
app.get('/api/settings', auth, async (req, res) => {
  const { companyId } = req.user;
  const { data: company } = await supabase.from('companies').select('*').eq('id', companyId).single();
  const { data: settings } = await supabase.from('company_settings').select('*').eq('company_id', companyId).single();
  res.json({ company, settings });
});

app.put('/api/settings', auth, auditLog('update_settings', 'company_settings'), async (req, res) => {
  const { companyId } = req.user;
  const { company, settings } = req.body;

  if (company) {
    await supabase.from('companies').update(company).eq('id', companyId);
  }
  if (settings) {
    await supabase.from('company_settings').update(settings).eq('company_id', companyId);
  }

  res.json({ ok: true });
});

// ============================================================
// USUÁRIOS — CRUD completo
// ============================================================
app.get('/api/users', auth, async (req, res) => {
  const { companyId } = req.user;
  const { data } = await supabase
    .from('users')
    .select('id, name, email, role, is_active, last_login, created_at, user_permissions(*)')
    .eq('company_id', companyId)
    .order('created_at');
  res.json(data);
});

app.post('/api/users', auth, auditLog('create_user', 'users'), async (req, res) => {
  const { companyId } = req.user;
  const { name, email, password, role } = req.body;

  // Verificar se email já existe
  const { data: existing } = await supabase.from('users')
    .select('id').eq('company_id', companyId).eq('email', email).single();
  if (existing) return res.status(409).json({ error: 'Email já cadastrado' });

  const passwordHash = await bcrypt.hash(password, 12);
  const { data: user, error } = await supabase.from('users').insert({
    company_id: companyId, name, email, password_hash: passwordHash, role,
  }).select('id, name, email, role').single();

  if (error) return res.status(500).json({ error: error.message });

  // Criar permissões padrão
  await supabase.from('user_permissions').insert({ user_id: user.id });

  res.json(user);
});

app.put('/api/users/:id', auth, auditLog('update_user', 'users'), async (req, res) => {
  const { id } = req.params;
  const { companyId } = req.user;
  const { name, email, password, role } = req.body;

  const updateData = { name, email, role };
  if (password) {
    updateData.password_hash = await bcrypt.hash(password, 12);
  }

  await supabase.from('users').update(updateData)
    .eq('id', id).eq('company_id', companyId);

  res.json({ ok: true });
});

app.patch('/api/users/:id/active', auth, async (req, res) => {
  const { id } = req.params;
  const { companyId } = req.user;
  const { isActive } = req.body;
  await supabase.from('users').update({ is_active: isActive })
    .eq('id', id).eq('company_id', companyId);
  res.json({ ok: true });
});

app.delete('/api/users/:id', auth, auditLog('delete_user', 'users'), async (req, res) => {
  const { id } = req.params;
  const { companyId, userId } = req.user;
  if (id === userId) return res.status(400).json({ error: 'Você não pode deletar sua própria conta' });
  await supabase.from('users').delete().eq('id', id).eq('company_id', companyId);
  res.json({ ok: true });
});

app.put('/api/users/:id/permissions', auth, async (req, res) => {
  const { id } = req.params;
  await supabase.from('user_permissions').upsert({ user_id: id, ...req.body }, { onConflict: 'user_id' });
  res.json({ ok: true });
});

// ============================================================
// LEADS
// ============================================================
app.get('/api/leads', auth, async (req, res) => {
  const { companyId } = req.user;
  const { stage, temperature, assignedTo } = req.query;
  let query = supabase.from('leads').select('*, users(name)').eq('company_id', companyId);
  if (stage) query = query.eq('stage', stage);
  if (temperature) query = query.eq('temperature', temperature);
  if (assignedTo) query = query.eq('assigned_to', assignedTo);
  const { data } = await query.order('created_at', { ascending: false });
  res.json(data);
});

app.post('/api/leads', auth, auditLog('create_lead', 'leads'), async (req, res) => {
  const { companyId } = req.user;
  const { data } = await supabase.from('leads').insert({ ...req.body, company_id: companyId }).select().single();
  res.json(data);
});

app.put('/api/leads/:id', auth, auditLog('update_lead', 'leads'), async (req, res) => {
  const { data } = await supabase.from('leads').update(req.body).eq('id', req.params.id).select().single();
  res.json(data);
});

app.delete('/api/leads/:id', auth, auditLog('delete_lead', 'leads'), async (req, res) => {
  await supabase.from('leads').delete().eq('id', req.params.id);
  res.json({ ok: true });
});

// ============================================================
// PEDIDOS / VENDAS
// ============================================================
app.get('/api/orders', auth, async (req, res) => {
  const { companyId } = req.user;
  const { data } = await supabase.from('orders')
    .select('*, leads(name), users(name)').eq('company_id', companyId)
    .order('created_at', { ascending: false });
  res.json(data);
});

app.post('/api/orders', auth, async (req, res) => {
  const { companyId, userId } = req.user;
  const { data } = await supabase.from('orders')
    .insert({ ...req.body, company_id: companyId, seller_id: userId })
    .select().single();

  // Criar comissão automática (10%)
  if (data) {
    await supabase.from('commissions').insert({
      company_id: companyId, user_id: userId, order_id: data.id,
      amount: data.amount * 0.1, percentage: 10,
    });
  }

  res.json(data);
});

// ============================================================
// GARANTIAS
// ============================================================
app.get('/api/warranties', auth, async (req, res) => {
  const { companyId } = req.user;
  const { data } = await supabase.from('warranties')
    .select('*, orders(product_name), leads(name)').eq('company_id', companyId)
    .order('expires_at');
  res.json(data);
});

app.post('/api/warranties', auth, async (req, res) => {
  const { companyId } = req.user;
  const { data } = await supabase.from('warranties')
    .insert({ ...req.body, company_id: companyId }).select().single();
  res.json(data);
});

// ============================================================
// FINANCEIRO
// ============================================================
app.get('/api/financial/summary', auth, async (req, res) => {
  const { companyId } = req.user;
  const { month = new Date().getMonth() + 1, year = new Date().getFullYear() } = req.query;

  const start = `${year}-${String(month).padStart(2,'0')}-01`;
  const end = `${year}-${String(month).padStart(2,'0')}-31`;

  const { data } = await supabase.from('financial_transactions')
    .select('type, amount, status').eq('company_id', companyId)
    .gte('created_at', start).lte('created_at', end);

  const income = data.filter(t => t.type === 'income' && t.status === 'pago')
    .reduce((s, t) => s + Number(t.amount), 0);
  const expenses = data.filter(t => t.type === 'expense' && t.status === 'pago')
    .reduce((s, t) => s + Number(t.amount), 0);

  res.json({ income, expenses, profit: income - expenses, month, year });
});

// ============================================================
// DASHBOARD — Métricas rápidas
// ============================================================
app.get('/api/dashboard', auth, async (req, res) => {
  const { companyId } = req.user;
  const today = new Date().toISOString().split('T')[0];

  const [leadsRes, ordersRes, conversationsRes] = await Promise.all([
    supabase.from('leads').select('stage, temperature', { count: 'exact' }).eq('company_id', companyId),
    supabase.from('orders').select('amount, status').eq('company_id', companyId).gte('created_at', `${today}T00:00:00`),
    supabase.from('conversations').select('status, unread_count').eq('company_id', companyId).eq('status', 'open'),
  ]);

  const salesToday = (ordersRes.data || [])
    .filter(o => o.status === 'pago')
    .reduce((s, o) => s + Number(o.amount), 0);

  res.json({
    totalLeads: leadsRes.count,
    hotLeads: (leadsRes.data || []).filter(l => l.temperature === 'quente').length,
    salesToday,
    openConversations: conversationsRes.data?.length ?? 0,
    unreadMessages: (conversationsRes.data || []).reduce((s, c) => s + c.unread_count, 0),
  });
});

// ============================================================
// START
// ============================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`CRM API rodando na porta ${PORT}`));
