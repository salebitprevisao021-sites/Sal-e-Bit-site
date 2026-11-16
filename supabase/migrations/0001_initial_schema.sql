-- Sal & Bit — esquema inicial. Execute no SQL Editor do Supabase.
create extension if not exists pgcrypto;
create type public.app_role as enum ('user','parceiro','admin');
create type public.surf_level as enum ('Iniciante','Intermediário','Avançado');
create type public.surf_sport as enum ('Surf','Bodyboard','Bodysurf','Skimboard');
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text, avatar_url text, role public.app_role not null default 'user',
 level public.surf_level not null default 'Iniciante', sport public.surf_sport not null default 'Surf',
 is_photographer boolean not null default false, surfmappers_url text,
 muted_until timestamptz, banned_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.peaks (id text primary key,name text not null,latitude double precision not null,longitude double precision not null,calibration_multiplier numeric(4,2) not null default 1.0 check(calibration_multiplier between 0.5 and 1.5));
insert into public.peaks(id,name,latitude,longitude) values
('arpoador','Arpoador',-22.9892,-43.1922),('sao-conrado','São Conrado',-23.0003,-43.2667),('barra-postinho','Barra — Postinho / Posto 4',-23.0128,-43.3105),('reserva','Reserva',-23.0145,-43.3850),('recreio-canto','Recreio — Canto / Posto 10',-23.0285,-43.4650),('macumba','Macumba',-23.0336,-43.4892),('prainha','Prainha',-23.0408,-43.5053),('grumari','Grumari',-23.0481,-43.5244),('itacoatiara','Itacoatiara',-22.9742,-43.0289) on conflict do nothing;
create table public.checkins(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,peak_id text not null references public.peaks(id),wave_size numeric(4,2) not null,formation text not null check(formation in ('Liso/Clássico','Regular','Mexido','Flat')),photo_path text,comment text check(char_length(comment)<=280),created_at timestamptz not null default now());
create table public.stories(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,peak_id text not null references public.peaks(id),media_path text not null,media_type text not null check(media_type in ('image','video')),created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '24 hours');
create table public.chat_messages(id uuid primary key default gen_random_uuid(),peak_id text not null references public.peaks(id),user_id uuid not null references public.profiles(id) on delete cascade,body text not null check(char_length(body) between 1 and 1000),reaction text check(reaction in ('🌊','🤙','🔥')),created_at timestamptz not null default now());
create table public.match_intents(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,peak_id text not null references public.peaks(id),spot text not null,happens_at timestamptz not null,sport public.surf_sport not null,created_at timestamptz not null default now());
create table public.match_likes(id uuid primary key default gen_random_uuid(),from_user uuid not null references public.profiles(id) on delete cascade,to_user uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),unique(from_user,to_user),check(from_user<>to_user));
create table public.boards(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,kind text not null check(kind in ('lost_found','progress')),title text not null,body text not null,created_at timestamptz not null default now());
create table public.audio_logs(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,storage_path text not null,title text,created_at timestamptz not null default now());
create table public.badges(id text primary key,name text not null,description text not null);
create table public.user_badges(user_id uuid references public.profiles(id) on delete cascade,badge_id text references public.badges(id),earned_at timestamptz not null default now(),primary key(user_id,badge_id));
insert into public.badges values('local-recreio','Local do Recreio','Colaborador frequente do Recreio'),('madrugador','Madrugador','Check-in nas primeiras horas do dia'),('cacador-tubos','Caçador de Tubos','Compartilhou sessões clássicas') on conflict do nothing;
create table public.subscriptions(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,plan text not null,status text not null,provider text,provider_subscription_id text,trial_started_at timestamptz,trial_ends_at timestamptz,current_period_end timestamptz,created_at timestamptz not null default now());
create table public.coupons(code text primary key,discount_percent int not null check(discount_percent between 1 and 100),partner_name text,active boolean not null default true,created_at timestamptz not null default now());
create table public.audit_logs(id bigint generated always as identity primary key,admin_id uuid references public.profiles(id),action text not null,target_user uuid,details jsonb not null default '{}',created_at timestamptz not null default now());
create table public.reports(id uuid primary key default gen_random_uuid(),reporter_id uuid references public.profiles(id),target_user uuid references public.profiles(id),message_id uuid references public.chat_messages(id),reason text not null,status text not null default 'open',created_at timestamptz not null default now());

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and banned_at is null) $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,display_name,avatar_url) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name'),new.raw_user_meta_data->>'avatar_url'); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.peaks enable row level security;
alter table public.checkins enable row level security;
alter table public.stories enable row level security;
alter table public.chat_messages enable row level security;
alter table public.match_intents enable row level security;
alter table public.match_likes enable row level security;
alter table public.boards enable row level security;
alter table public.audio_logs enable row level security;
alter table public.user_badges enable row level security;
alter table public.subscriptions enable row level security;
alter table public.coupons enable row level security;
alter table public.audit_logs enable row level security;
alter table public.reports enable row level security;
create policy "profiles are readable" on public.profiles for select using (true);
create policy "profile owner updates safe fields" on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id and role=(select p.role from public.profiles p where p.id=auth.uid()));
create policy "peaks are public" on public.peaks for select using(true);
create policy "checkins public read" on public.checkins for select using(true);
create policy "partners create checkins" on public.checkins for insert with check(auth.uid()=user_id and exists(select 1 from public.profiles where id=auth.uid() and role in ('parceiro','admin')));
create policy "stories visible while active" on public.stories for select using(expires_at>now());
create policy "users create stories" on public.stories for insert with check(auth.uid()=user_id);
create policy "owners delete stories" on public.stories for delete using(auth.uid()=user_id or public.is_admin());
create policy "chat readable" on public.chat_messages for select using(true);
create policy "active users send chat" on public.chat_messages for insert with check(auth.uid()=user_id and not exists(select 1 from public.profiles where id=auth.uid() and (muted_until>now() or banned_at is not null)));
create policy "match intents readable" on public.match_intents for select using(auth.uid()=user_id or happens_at>now());
create policy "users manage own intents" on public.match_intents for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "users create likes" on public.match_likes for insert with check(auth.uid()=from_user);
create policy "users see own likes" on public.match_likes for select using(auth.uid()=from_user or auth.uid()=to_user);
create policy "boards public read" on public.boards for select using(true);
create policy "users manage own boards" on public.boards for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "audio private" on public.audio_logs for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "badges public" on public.user_badges for select using(true);
create policy "subscription owner read" on public.subscriptions for select using(auth.uid()=user_id);
create policy "coupon active read" on public.coupons for select using(active=true);
create policy "admins audit read" on public.audit_logs for select using(public.is_admin());
create policy "users create reports" on public.reports for insert with check(auth.uid()=reporter_id);
create policy "admins manage reports" on public.reports for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage roles" on public.profiles for update using(public.is_admin()) with check(public.is_admin());
create policy "admins manage calibration" on public.peaks for update using(public.is_admin()) with check(public.is_admin());
create policy "admins manage audit" on public.audit_logs for insert with check(public.is_admin());

-- IMPORTANTE: promova os 3 administradores manualmente, após identificar os UUIDs reais:
-- update public.profiles set role='admin' where id in ('UUID_FUNDADOR','UUID_MODERADOR_1','UUID_MODERADOR_2');
-- Nunca habilite service_role no navegador. Mute anti-spam, checkout, trial e cargos devem ser validados em rotas server-side/Edge Functions.
