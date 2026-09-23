-- Datos iniciales (seed) — SOLO para desarrollo local y pruebas.
-- En producción se cargan únicamente categorías y rangos de precio.
-- El catálogo de ejemplo permite que el MVP funcione sin gestión de catálogo (Incremento 2).

-- ===== Categorías =====
insert into categorias (id, nombre, slug) values
  ('11111111-0000-0000-0000-000000000001', 'Comida típica', 'tipica'),
  ('11111111-0000-0000-0000-000000000002', 'Italiana', 'italiana'),
  ('11111111-0000-0000-0000-000000000003', 'Comida rápida', 'rapida'),
  ('11111111-0000-0000-0000-000000000004', 'Asiática', 'asiatica'),
  ('11111111-0000-0000-0000-000000000005', 'Saludable', 'saludable'),
  ('11111111-0000-0000-0000-000000000006', 'Panadería y café', 'panaderia-cafe'),
  ('11111111-0000-0000-0000-000000000007', 'Postres', 'postres'),
  ('11111111-0000-0000-0000-000000000008', 'Parrilla', 'parrilla'),
  ('11111111-0000-0000-0000-000000000009', 'Vegetariana', 'vegetariana'),
  ('11111111-0000-0000-0000-000000000010', 'Mariscos', 'mariscos')
on conflict (slug) do nothing;

-- ===== Rangos de precio =====
insert into rangos_precio (id, etiqueta, min, max) values
  ('22222222-0000-0000-0000-000000000001', '$', 0, 10000),
  ('22222222-0000-0000-0000-000000000002', '$$', 10001, 25000),
  ('22222222-0000-0000-0000-000000000003', '$$$', 25001, 50000),
  ('22222222-0000-0000-0000-000000000004', '$$$$', 50001, null)
on conflict (etiqueta) do nothing;

-- ===== Restaurantes de ejemplo (Tunja) =====
insert into restaurantes (id, nombre, descripcion, categoria_id, rango_precio_id, direccion, ubicacion, estado)
values
  ('33333333-0000-0000-0000-000000000001', 'Sabor Boyacense',
   'Cocina típica boyacense en el centro de Tunja.',
   '11111111-0000-0000-0000-000000000001',
   '22222222-0000-0000-0000-000000000002',
   'Calle 20 # 8-35, Centro',
   st_setsrid(st_makepoint(-73.3678, 5.5353), 4326)::geography, 'activo'),
  ('33333333-0000-0000-0000-000000000002', 'Trattoria La Colina',
   'Pastas y pizzas artesanales.',
   '11111111-0000-0000-0000-000000000002',
   '22222222-0000-0000-0000-000000000003',
   'Carrera 9 # 25-14, Norte',
   st_setsrid(st_makepoint(-73.3610, 5.5450), 4326)::geography, 'activo'),
  ('33333333-0000-0000-0000-000000000003', 'Verde Café',
   'Opciones saludables y café de origen.',
   '11111111-0000-0000-0000-000000000005',
   '22222222-0000-0000-0000-000000000002',
   'Avenida Universitaria # 40-02',
   st_setsrid(st_makepoint(-73.3700, 5.5270), 4326)::geography, 'activo')
on conflict (id) do nothing;

-- ===== Platos =====
insert into platos (restaurante_id, nombre, descripcion, precio, categoria_id, disponible) values
  ('33333333-0000-0000-0000-000000000001', 'Cocido boyacense', 'Guiso tradicional con tubérculos y carnes', 22000, '11111111-0000-0000-0000-000000000001', true),
  ('33333333-0000-0000-0000-000000000001', 'Arepa de choclo', 'Con queso campesino', 8000, '11111111-0000-0000-0000-000000000001', true),
  ('33333333-0000-0000-0000-000000000002', 'Pasta carbonara', 'Receta clásica con panceta y parmesano', 28000, '11111111-0000-0000-0000-000000000002', true),
  ('33333333-0000-0000-0000-000000000002', 'Pizza margarita', 'Masa artesanal, tomate y albahaca', 30000, '11111111-0000-0000-0000-000000000002', true),
  ('33333333-0000-0000-0000-000000000003', 'Bowl de quinoa', 'Quinoa, pollo, aguacate y vegetales', 24000, '11111111-0000-0000-0000-000000000005', true),
  ('33333333-0000-0000-0000-000000000003', 'Café de origen', 'Café de especialidad de la región', 6000, '11111111-0000-0000-0000-000000000006', true)
on conflict do nothing;

-- ===== Horarios (0=domingo … 6=sábado) =====
insert into horarios (restaurante_id, dia_semana, abre, cierra, cerrado) values
  ('33333333-0000-0000-0000-000000000001', 1, '11:00', '21:00', false),
  ('33333333-0000-0000-0000-000000000001', 2, '11:00', '21:00', false),
  ('33333333-0000-0000-0000-000000000001', 3, '11:00', '21:00', false),
  ('33333333-0000-0000-0000-000000000001', 4, '11:00', '21:00', false),
  ('33333333-0000-0000-0000-000000000001', 5, '11:00', '22:00', false),
  ('33333333-0000-0000-0000-000000000001', 6, '11:00', '22:00', false),
  ('33333333-0000-0000-0000-000000000001', 0, null, null, true),
  ('33333333-0000-0000-0000-000000000002', 1, '12:00', '22:00', false),
  ('33333333-0000-0000-0000-000000000002', 2, '12:00', '22:00', false),
  ('33333333-0000-0000-0000-000000000002', 3, '12:00', '22:00', false),
  ('33333333-0000-0000-0000-000000000002', 4, '12:00', '22:00', false),
  ('33333333-0000-0000-0000-000000000002', 5, '12:00', '23:00', false),
  ('33333333-0000-0000-0000-000000000002', 6, '12:00', '23:00', false),
  ('33333333-0000-0000-0000-000000000002', 0, '12:00', '20:00', false),
  ('33333333-0000-0000-0000-000000000003', 1, '07:00', '19:00', false),
  ('33333333-0000-0000-0000-000000000003', 2, '07:00', '19:00', false),
  ('33333333-0000-0000-0000-000000000003', 3, '07:00', '19:00', false),
  ('33333333-0000-0000-0000-000000000003', 4, '07:00', '19:00', false),
  ('33333333-0000-0000-0000-000000000003', 5, '07:00', '19:00', false),
  ('33333333-0000-0000-0000-000000000003', 6, '08:00', '17:00', false),
  ('33333333-0000-0000-0000-000000000003', 0, null, null, true)
on conflict do nothing;
