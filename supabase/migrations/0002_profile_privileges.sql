-- Crear perfiles de forma segura cuando Supabase Auth crea una cuenta.
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

-- El rol solo se modifica mediante operaciones de servidor confiables.
-- Los usuarios autenticados pueden leer su perfil y actualizar los campos
-- editables, pero no pueden insertar, eliminar ni modificar rol_global.
revoke all on table public.perfiles from public, anon, authenticated;

grant select on table public.perfiles to authenticated;
grant update (nombre, rango_precio_id, restricciones)
  on table public.perfiles to authenticated;
