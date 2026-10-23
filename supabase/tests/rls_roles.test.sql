begin;

select plan(15);

-- Fixtures locales. El trigger de 0002 debe crear los perfiles con rol usuario.
insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
)
values
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'authenticated',
    'authenticated',
    'rls-user@example.test',
    '',
    now(),
    now(),
    now()
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'authenticated',
    'authenticated',
    'rls-manager@example.test',
    '',
    now(),
    now(),
    now()
  ),
  (
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    'authenticated',
    'authenticated',
    'rls-admin@example.test',
    '',
    now(),
    now(),
    now()
  );

update public.perfiles
set rol_global = 'administrador'
where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

insert into public.restaurantes (id, nombre, estado, creado_por)
values
  (
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    'RLS restaurante del gestor',
    'pendiente',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  ),
  (
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    'RLS restaurante ajeno',
    'pendiente',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  );

insert into public.restaurante_gestores (restaurante_id, usuario_id)
values (
  'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
);

select is(
  (select count(*)::integer from public.perfiles),
  3,
  'el trigger crea un perfil para cada usuario de Auth'
);
select is(
  (
    select rol_global::text
    from public.perfiles
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ),
  'usuario',
  'el perfil nuevo obtiene el rol usuario por defecto'
);

-- Usuario normal: solo ve su perfil y restaurantes activos.
set local role authenticated;
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
set local request.jwt.claim.role = 'authenticated';

select is(
  (select count(*)::integer from public.perfiles),
  1,
  'el usuario solo puede leer su perfil'
);
select is(
  (
    select count(*)::integer
    from public.perfiles
    where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  ),
  0,
  'el usuario no puede leer el perfil de otro usuario'
);
update public.perfiles
set nombre = 'Nombre actualizado por usuario'
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
select is(
  (
    select nombre
    from public.perfiles
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ),
  'Nombre actualizado por usuario',
  'el usuario puede actualizar un campo permitido de su perfil'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'public.perfiles',
    'rol_global',
    'UPDATE'
  ),
  'el usuario autenticado no puede cambiar rol_global'
);
select is(
  (
    select count(*)::integer
    from public.restaurantes
    where estado = 'pendiente'
  ),
  0,
  'el usuario no puede ver restaurantes pendientes ajenos'
);
update public.restaurantes
set nombre = 'Edición no autorizada'
where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
reset role;
select is(
  (
    select nombre
    from public.restaurantes
    where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
  ),
  'RLS restaurante ajeno',
  'el usuario no puede modificar un restaurante ajeno'
);

-- Gestor: ve el restaurante asignado, no los restaurantes de otros gestores.
set local role authenticated;
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
select is(
  (
    select count(*)::integer
    from public.restaurantes
    where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
  ),
  1,
  'el gestor puede ver su restaurante asignado'
);
select is(
  (
    select count(*)::integer
    from public.restaurantes
    where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
  ),
  0,
  'el gestor no puede ver el restaurante ajeno pendiente'
);
update public.restaurantes
set descripcion = 'Actualizado por su gestor'
where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
update public.restaurantes
set nombre = 'Edición no autorizada por gestor'
where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
reset role;
select is(
  (
    select descripcion
    from public.restaurantes
    where id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
  ),
  'Actualizado por su gestor',
  'el gestor puede actualizar su restaurante'
);
select is(
  (
    select nombre
    from public.restaurantes
    where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
  ),
  'RLS restaurante ajeno',
  'el gestor no puede modificar un restaurante ajeno'
);

-- Administrador: puede consultar los restaurantes pendientes y los perfiles.
set local role authenticated;
set local request.jwt.claim.sub = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
select is(
  (
    select count(*)::integer
    from public.restaurantes
    where estado = 'pendiente'
  ),
  2,
  'el administrador puede consultar todos los restaurantes pendientes'
);
select is(
  (select count(*)::integer from public.perfiles),
  3,
  'el administrador puede consultar los perfiles para tareas administrativas'
);
update public.restaurantes
set estado = 'activo'
where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';

reset role;
select is(
  (
    select estado::text
    from public.restaurantes
    where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
  ),
  'activo',
  'el administrador puede actualizar el estado de un restaurante'
);
select * from finish();
rollback;
