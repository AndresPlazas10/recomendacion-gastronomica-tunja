begin;

select plan(5);

select ok(
  has_table_privilege('authenticated', 'public.perfiles', 'SELECT'),
  'authenticated puede leer perfiles sujetos a RLS'
);
select ok(
  has_column_privilege('authenticated', 'public.perfiles', 'nombre', 'UPDATE'),
  'authenticated puede actualizar el nombre del perfil'
);
select ok(
  has_column_privilege('authenticated', 'public.perfiles', 'restricciones', 'UPDATE'),
  'authenticated puede actualizar restricciones del perfil'
);
select ok(
  not has_column_privilege('authenticated', 'public.perfiles', 'rol_global', 'UPDATE'),
  'authenticated no puede cambiar el rol global'
);
select ok(
  not has_table_privilege('authenticated', 'public.perfiles', 'INSERT'),
  'authenticated no puede crear perfiles directamente'
);

select * from finish();
rollback;
