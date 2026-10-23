-- El perfil se crea desde el trigger de Supabase Auth. Los usuarios solo
-- pueden leer su perfil y actualizar campos de perfil no privilegiados.

create or replace function public.crear_perfil_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.crear_perfil_usuario() from public, anon, authenticated;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.crear_perfil_usuario();

revoke all on table public.perfiles from public, anon, authenticated;

grant select on table public.perfiles to authenticated;
grant update (nombre, rango_precio_id, restricciones)
  on table public.perfiles to authenticated;
