-- Migración inicial: catálogo, usuarios, interacciones, recomendaciones y embeddings.
-- Basada en el modelo ER v1.0 (S0-06) y el diseño vectorial v1.0 (S0-07).

create extension if not exists postgis;
create extension if not exists vector;

-- =========================================================
-- Tipos
-- =========================================================
create type rol_global as enum ('usuario', 'administrador');
create type estado_restaurante as enum ('pendiente', 'activo', 'suspendido');
create type origen_preferencia as enum ('explicita', 'inferida');
create type tipo_consentimiento as enum ('interacciones', 'preferencias', 'ubicacion');
create type tipo_evento as enum (
  'busqueda', 'ver_restaurante', 'ver_plato', 'recomendacion_impresion', 'clic_recomendacion'
);
create type entidad_evento as enum ('restaurante', 'plato', 'consulta');
create type origen_evento as enum ('busqueda', 'recomendacion', 'catalogo');
create type estrategia_recomendacion as enum ('cold_start', 'popularidad', 'contenido', 'hibrido');

-- =========================================================
-- Catálogo base
-- =========================================================
create table categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  slug text not null unique
);

create table rangos_precio (
  id uuid primary key default gen_random_uuid(),
  etiqueta text not null unique,
  min numeric(10, 2) not null default 0,
  max numeric(10, 2)
);

-- =========================================================
-- Usuarios y privacidad
-- =========================================================
create table perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text,
  rango_precio_id uuid references rangos_precio(id),
  restricciones text[] not null default '{}',
  rol_global rol_global not null default 'usuario',
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table preferencias_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references perfiles(id) on delete cascade,
  categoria_id uuid not null references categorias(id),
  origen origen_preferencia not null default 'explicita',
  peso numeric(3, 2) not null default 1.00,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  unique (usuario_id, categoria_id)
);

create table consentimientos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references perfiles(id) on delete cascade,
  tipo tipo_consentimiento not null,
  version text not null,
  otorgado boolean not null,
  fecha timestamptz not null default now(),
  unique (usuario_id, tipo, version)
);

-- =========================================================
-- Catálogo gastronómico
-- =========================================================
create table restaurantes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text,
  categoria_id uuid references categorias(id),
  rango_precio_id uuid references rangos_precio(id),
  direccion text,
  ubicacion geography(Point, 4326),
  estado estado_restaurante not null default 'pendiente',
  creado_por uuid references perfiles(id),
  aprobado_por uuid references perfiles(id),
  aprobado_en timestamptz,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table platos (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references restaurantes(id) on delete cascade,
  nombre text not null,
  descripcion text,
  precio numeric(10, 2),
  categoria_id uuid references categorias(id),
  disponible boolean not null default true,
  imagen_url text,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table horarios (
  id uuid primary key default gen_random_uuid(),
  restaurante_id uuid not null references restaurantes(id) on delete cascade,
  dia_semana smallint not null check (dia_semana between 0 and 6),
  abre time,
  cierra time,
  cerrado boolean not null default false
);

create table restaurante_gestores (
  restaurante_id uuid not null references restaurantes(id) on delete cascade,
  usuario_id uuid not null references perfiles(id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (restaurante_id, usuario_id)
);

-- =========================================================
-- Analítica y recomendación
-- =========================================================
create table eventos (
  id bigint generated always as identity primary key,
  usuario_id uuid references perfiles(id) on delete set null,
  tipo tipo_evento not null,
  entidad_tipo entidad_evento not null,
  entidad_id uuid,
  origen origen_evento,
  sesion_id uuid,
  termino text,
  filtros jsonb,
  recomendacion_id uuid,
  request_id uuid,
  modelo_version text,
  posicion smallint,
  creado_en timestamptz not null default now()
);

create table recomendaciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references perfiles(id) on delete cascade,
  request_id uuid not null,
  modelo_version text,
  estrategia estrategia_recomendacion not null,
  uso_ubicacion boolean not null default false,
  radio_km numeric(5, 2),
  total_items smallint not null default 0,
  creado_en timestamptz not null default now()
);

create table recomendacion_items (
  recomendacion_id uuid not null references recomendaciones(id) on delete cascade,
  restaurante_id uuid not null references restaurantes(id),
  posicion smallint not null,
  score numeric(6, 4),
  razones jsonb,
  primary key (recomendacion_id, restaurante_id)
);

create table auditoria_cambios (
  id bigint generated always as identity primary key,
  tabla text not null,
  registro_id uuid not null,
  accion text not null,
  actor_id uuid references perfiles(id),
  datos jsonb,
  creado_en timestamptz not null default now()
);

create table restaurante_embeddings (
  restaurante_id uuid primary key references restaurantes(id) on delete cascade,
  modelo text not null,
  version text not null,
  dims smallint not null,
  embedding vector(768) not null,
  contenido_hash text not null,
  actualizado_en timestamptz not null default now()
);

-- =========================================================
-- Índices
-- =========================================================
create index restaurantes_ubicacion_idx on restaurantes using gist (ubicacion);
create index restaurantes_estado_idx on restaurantes (estado);
create index platos_restaurante_idx on platos (restaurante_id);
create index horarios_restaurante_idx on horarios (restaurante_id);
create index eventos_usuario_fecha_idx on eventos (usuario_id, creado_en desc);
create index eventos_recomendacion_idx on eventos (recomendacion_id);
create index eventos_filtros_idx on eventos using gin (filtros jsonb_path_ops);
create index embeddings_hnsw_idx on restaurante_embeddings
  using hnsw (embedding vector_cosine_ops);

-- =========================================================
-- Funciones auxiliares de autorización
-- =========================================================
create or replace function es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from perfiles p
    where p.id = auth.uid() and p.rol_global = 'administrador'
  );
$$;

create or replace function es_gestor_de(restaurante uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from restaurante_gestores g
    where g.restaurante_id = restaurante and g.usuario_id = auth.uid()
  );
$$;

-- =========================================================
-- RLS
-- =========================================================
alter table perfiles enable row level security;
create policy perfiles_propios on perfiles
  for all using (id = auth.uid()) with check (id = auth.uid());
create policy perfiles_admin on perfiles
  for all using (es_admin());

alter table preferencias_usuario enable row level security;
create policy preferencias_propias on preferencias_usuario
  for all using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy preferencias_admin on preferencias_usuario
  for all using (es_admin());

alter table consentimientos enable row level security;
create policy consentimientos_propios on consentimientos
  for all using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy consentimientos_admin on consentimientos
  for select using (es_admin());

alter table categorias enable row level security;
create policy categorias_lectura on categorias
  for select using (auth.role() = 'authenticated');
create policy categorias_admin on categorias
  for all using (es_admin());

alter table rangos_precio enable row level security;
create policy rangos_lectura on rangos_precio
  for select using (auth.role() = 'authenticated');
create policy rangos_admin on rangos_precio
  for all using (es_admin());

alter table restaurantes enable row level security;
create policy restaurantes_lectura on restaurantes
  for select using (estado = 'activo' or es_gestor_de(id) or es_admin());
create policy restaurantes_gestion on restaurantes
  for all using (es_gestor_de(id) or es_admin())
  with check (es_gestor_de(id) or es_admin());

alter table platos enable row level security;
create policy platos_lectura on platos
  for select using (
    exists (
      select 1 from restaurantes r
      where r.id = restaurante_id
        and (r.estado = 'activo' or es_gestor_de(r.id) or es_admin())
    )
  );
create policy platos_gestion on platos
  for all using (es_gestor_de(restaurante_id) or es_admin())
  with check (es_gestor_de(restaurante_id) or es_admin());

alter table horarios enable row level security;
create policy horarios_lectura on horarios
  for select using (
    exists (
      select 1 from restaurantes r
      where r.id = restaurante_id
        and (r.estado = 'activo' or es_gestor_de(r.id) or es_admin())
    )
  );
create policy horarios_gestion on horarios
  for all using (es_gestor_de(restaurante_id) or es_admin())
  with check (es_gestor_de(restaurante_id) or es_admin());

alter table restaurante_gestores enable row level security;
create policy gestores_lectura on restaurante_gestores
  for select using (usuario_id = auth.uid() or es_admin());
create policy gestores_admin on restaurante_gestores
  for all using (es_admin());

alter table eventos enable row level security;
create policy eventos_insert on eventos
  for insert with check (usuario_id = auth.uid());
create policy eventos_admin on eventos
  for select using (es_admin());

alter table recomendaciones enable row level security;
create policy recomendaciones_propias on recomendaciones
  for select using (usuario_id = auth.uid() or es_admin());

alter table recomendacion_items enable row level security;
create policy items_propios on recomendacion_items
  for select using (
    exists (
      select 1 from recomendaciones r
      where r.id = recomendacion_id and (r.usuario_id = auth.uid() or es_admin())
    )
  );

alter table auditoria_cambios enable row level security;
create policy auditoria_admin on auditoria_cambios
  for select using (es_admin());

alter table restaurante_embeddings enable row level security;
create policy embeddings_admin on restaurante_embeddings
  for select using (es_admin());

-- =========================================================
-- Vistas de investigación (solo backend con service_role)
-- =========================================================
create view v_interacciones_anonimas as
select
  id,
  md5(usuario_id::text) as usuario_hash,
  tipo,
  entidad_tipo,
  entidad_id,
  origen,
  recomendacion_id,
  modelo_version,
  posicion,
  creado_en
from eventos
where usuario_id is not null;

create view v_metricas_eventos_diarios as
select
  date_trunc('day', creado_en) as dia,
  tipo,
  count(*) as total
from eventos
group by 1, 2
order by 1 desc;

create view v_metricas_recomendaciones as
select
  modelo_version,
  count(*) filter (where tipo = 'recomendacion_impresion') as impresiones,
  count(*) filter (where tipo = 'clic_recomendacion') as clics,
  round(
    (count(*) filter (where tipo = 'clic_recomendacion'))::numeric
    / nullif(count(*) filter (where tipo = 'recomendacion_impresion'), 0),
    4
  ) as ctr
from eventos
where recomendacion_id is not null
group by 1;

revoke all on v_interacciones_anonimas from anon, authenticated;
revoke all on v_metricas_eventos_diarios from anon, authenticated;
revoke all on v_metricas_recomendaciones from anon, authenticated;
grant select on v_interacciones_anonimas to service_role;
grant select on v_metricas_eventos_diarios to service_role;
grant select on v_metricas_recomendaciones to service_role;
