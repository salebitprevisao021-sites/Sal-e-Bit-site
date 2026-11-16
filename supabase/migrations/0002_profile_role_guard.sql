-- Impede que o próprio usuário altere role, mute ou banimento via API de perfil.
create or replace function public.guard_profile_privileges() returns trigger
language plpgsql security definer set search_path=public as $$
begin
 if (new.role is distinct from old.role or new.muted_until is distinct from old.muted_until or new.banned_at is distinct from old.banned_at) and not public.is_admin() then
  raise exception 'Somente administradores podem alterar cargo ou moderação';
 end if;
 new.updated_at=now();
 return new;
end; $$;
 drop trigger if exists guard_profile_privileges_trigger on public.profiles;
 create trigger guard_profile_privileges_trigger before update on public.profiles for each row execute function public.guard_profile_privileges();
-- O acesso de administrador deve ser concedido manualmente após conferir a identidade dos três UUIDs.
