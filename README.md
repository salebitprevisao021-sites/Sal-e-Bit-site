# Sal & Bit 🌊

MVP de monitoramento de surf e esportes de onda no Rio de Janeiro, com motor de previsão Tecnologia Boia 021.

## Stack

- Next.js App Router + TypeScript
- Tailwind CSS
- Supabase (Auth, PostgreSQL, Realtime e Storage)
- Open-Meteo Marine e Weather
- Vercel

## Desenvolvimento

1. `npm install`
2. Copie `.env.example` para `.env.local` e configure as chaves do Supabase.
3. `npm run dev`

## Supabase

Execute `supabase/migrations/0001_initial_schema.sql` no SQL Editor do projeto Supabase. O SQL habilita RLS e cria as estruturas iniciais. Configure Google OAuth no painel do Supabase antes de liberar login.

## Segurança e integrações

Segredos devem existir apenas nas variáveis de ambiente do servidor. O checkout está preparado por interface de provedor, mas só deve ser ativado após configurar e validar Mercado Pago/Stripe e webhooks. Não use `NEXT_PUBLIC_` para service role, tokens de pagamento ou segredos.

## Status

Fundação inicial do MVP. Previsões são estimativas baseadas em modelos públicos, não substituem observação local, avisos oficiais ou avaliação de segurança no mar.