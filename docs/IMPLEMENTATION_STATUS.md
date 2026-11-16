# Sal & Bit — status técnico do MVP

## Incluído nesta primeira entrega
- Base Next.js App Router, TypeScript, Tailwind e manifesto PWA.
- Home inicial com seletor de modalidade/nível, temas e ranking de picos.
- Catálogo dos nove picos e endpoint que consulta Open-Meteo Marine + Weather.
- Primeira heurística Boia 021 com ajuste de sombra do Pontal e alerta de tamanho para iniciantes.
- Cliente Supabase, callback Google OAuth e SQL inicial com perfis, picos, check-ins, stories, chat, Match, murais, áudio, badges, assinaturas, cupons, denúncias e auditoria.
- RLS inicial, proteção de alteração de cargos e cabeçalhos HTTP básicos.

## Ainda depende de configuração e desenvolvimento
- Criar projeto Supabase, executar as migrations em ordem e configurar Google OAuth, URLs autorizadas e buckets privados/públicos conforme o tipo de mídia.
- Validar e completar políticas RLS para cada fluxo antes de abrir cadastro público; configurar Realtime e limpeza agendada de stories expirados.
- A nota Boia 021 é heurística inicial: não há ainda modelagem de bancada, batimetria, maré, raios ou alerta oficial de ressaca; temperatura da água também não é fornecida pelo endpoint marinho usado.
- O login Google exige variáveis e callback autorizado.
- Checkout Mercado Pago/Stripe está intencionalmente fechado (503/501) até implementação de criação de sessão, assinatura de webhooks e conciliação server-side.
- Trial anti-abuso, validação de telefone/fingerprint, cupons/relatórios, chat privado, automoderação anti-spam, filtro de links/palavrões, painel administrativo completo, exportação CSV/XLSX, notificações e webhook de alerta ainda não estão implementados.
- As contas dos três administradores precisam ser identificadas por UUID e promovidas manualmente no SQL; não inserir UUIDs fictícios.
- Componentes completos de comunidade, mapas Leaflet, gráficos de série temporal, compartilhamento, stories/votação e áudio ainda precisam ser construídos.

## Segurança
Nunca publicar SUPABASE_SERVICE_ROLE_KEY, credenciais de pagamento ou webhook secrets. Não confiar em cargo, preço, assinatura ou status de trial enviados pelo navegador. A previsão não é orientação de segurança marítima; consultar avisos oficiais e condições locais.
