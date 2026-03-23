# Configuração do Supabase

Este projeto usa Supabase como backend. Siga os passos abaixo para configurar:

## 1. Criar conta no Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Crie uma conta gratuita
3. Crie um novo projeto
4. Copie a **Project URL** e **Anon Key**

## 2. Executar o Schema

1. Vá para **SQL Editor** no painel do Supabase
2. Cole o conteúdo de `schema.sql` (na raiz do projeto)
3. Clique em **Run** para criar as tabelas

## 3. Configurar o Flutter App

Abra `main.dart` e substitua:
```dart
await Supabase.initialize(
  url: 'https://SEU_PROJECT_ID.supabase.co',
  anonKey: 'SUA_ANON_KEY',
);
```

Com seus valores reais do Supabase.

## 4. Configurar o Backend (Node.js)

Crie um arquivo `.env` na raiz do projeto com:
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=sua_service_role_key
JWT_SECRET=qualquer_string_longa_e_aleatoria
PORT=3000
```

**Como obter as chaves:**
- **SUPABASE_URL**: Project Settings → API → Project URL
- **SUPABASE_SERVICE_KEY**: Project Settings → API → Service Role Secret
- **JWT_SECRET**: Crie uma string aleatória forte (ex: `openssl rand -base64 32`)

## Segurança

- **Row Level Security (RLS)**: Ative RLS em todas as tabelas do Supabase e configure políticas para isolamento multi-tenant.
- **Chaves de API**: Use a chave `anon` para o cliente Flutter e `service_role` apenas no servidor.
- **HTTPS**: Configure HTTPS no servidor de produção.
- **Auditoria**: Os logs de auditoria são armazenados na tabela `audit_logs`.
- **Rate Limiting**: Implementado para prevenir ataques de força bruta.
- **Validação**: Entradas são validadas no backend.

## 5. Instalar Dependências

```bash
# Flutter
flutter pub get

# Node.js
cd backend
npm install
```

## 6. Rodar o Projeto

```bash
# Frontend Flutter
flutter run

# Backend Node.js
npm start
```

## Estrutura de Folders

```
├── lib/
│   ├── models/        # Modelos de dados
│   ├── services/      # Integração com Supabase
│   ├── widgets/       # Componentes UI reutilizáveis
│   └── screens/       # Telas da aplicação
├── assets/
│   ├── images/        # Imagens da app
│   ├── icons/         # Ícones
│   └── fonts/         # Fontes (Inter .ttf)
├── server.js          # Backend Node.js
├── schema.sql         # Tabelas do Supabase
└── pubspec.yaml       # Dependências Flutter
```

## Próximos Passos

- [ ] Baixar **Inter Font** do [Google Fonts](https://fonts.google.com/specimen/Inter)
- [ ] Adicionar imagens e ícones em `assets/`
- [ ] Implementar as telas faltantes (Contatos, Vendas, Configurações)
- [ ] Configurar notificações com Firebase
