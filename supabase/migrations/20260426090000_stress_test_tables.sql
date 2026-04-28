-- Stress test: complex schema with relationships, composites, edge cases

-- Categories (self-referencing)
CREATE TABLE public.categories (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL UNIQUE,
  parent_id uuid REFERENCES public.categories(id),
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Orders with foreign keys to products
CREATE TABLE public.orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES public.products(id),
  quantity int NOT NULL DEFAULT 1,
  total_price numeric NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  notes text,
  shipped_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Order items (many-to-many junction)
CREATE TABLE public.order_items (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES public.products(id),
  quantity int NOT NULL DEFAULT 1,
  unit_price numeric NOT NULL,
  discount numeric NOT NULL DEFAULT 0
);

-- Product categories (many-to-many)
CREATE TABLE public.product_categories (
  product_id bigint NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);

-- Audit log with jsonb diff
CREATE TABLE public.audit_log (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name text NOT NULL,
  record_id text NOT NULL,
  action text NOT NULL,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Table with all nullable columns (edge case)
CREATE TABLE public.optional_everything (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text,
  count int,
  amount numeric,
  flag boolean,
  tags text[],
  meta jsonb,
  stamp timestamptz
);

-- Table with many types for type mapping stress test
CREATE TABLE public.type_zoo (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  col_int2 smallint NOT NULL DEFAULT 0,
  col_int4 int NOT NULL DEFAULT 0,
  col_int8 bigint NOT NULL DEFAULT 0,
  col_float4 real NOT NULL DEFAULT 0,
  col_float8 double precision NOT NULL DEFAULT 0,
  col_numeric numeric NOT NULL DEFAULT 0,
  col_bool boolean NOT NULL DEFAULT false,
  col_text text NOT NULL DEFAULT '',
  col_varchar varchar(255) NOT NULL DEFAULT '',
  col_uuid uuid NOT NULL DEFAULT gen_random_uuid(),
  col_timestamptz timestamptz NOT NULL DEFAULT now(),
  col_date date NOT NULL DEFAULT CURRENT_DATE,
  col_jsonb jsonb NOT NULL DEFAULT '{}',
  col_json json NOT NULL DEFAULT '{}',
  col_text_arr text[] NOT NULL DEFAULT '{}',
  col_int_arr int[] NOT NULL DEFAULT '{}'
);

-- RLS for all tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.optional_everything ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.type_zoo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_all" ON public.categories FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.orders FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.order_items FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.product_categories FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.audit_log FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.optional_everything FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.type_zoo FOR ALL TO anon USING (true) WITH CHECK (true);

-- Seed categories
INSERT INTO public.categories (name, sort_order) VALUES
  ('Electronics', 1),
  ('Home', 2);
INSERT INTO public.categories (name, parent_id, sort_order) VALUES
  ('Gadgets', (SELECT id FROM public.categories WHERE name = 'Electronics'), 1),
  ('Kitchen', (SELECT id FROM public.categories WHERE name = 'Home'), 1);

-- Seed orders
INSERT INTO public.orders (product_id, quantity, total_price, status, notes, shipped_at) VALUES
  (1, 2, 20.00, 'shipped', 'Rush delivery', now()),
  (2, 1, 25.50, 'pending', NULL, NULL),
  (4, 3, 450.00, 'shipped', 'Bulk order', now());

-- Seed order items
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, discount) VALUES
  (1, 1, 2, 10.00, 0),
  (2, 2, 1, 25.50, 0),
  (3, 4, 2, 150.00, 10),
  (3, 1, 1, 10.00, 0);

-- Seed product categories
INSERT INTO public.product_categories (product_id, category_id) VALUES
  (1, (SELECT id FROM public.categories WHERE name = 'Electronics')),
  (4, (SELECT id FROM public.categories WHERE name = 'Electronics')),
  (4, (SELECT id FROM public.categories WHERE name = 'Gadgets'));

-- Seed audit log
INSERT INTO public.audit_log (table_name, record_id, action, old_data, new_data) VALUES
  ('products', '1', 'UPDATE', '{"price": 9.00}', '{"price": 10.00}'),
  ('products', '3', 'UPDATE', '{"in_stock": true}', '{"in_stock": false}');

-- Seed optional_everything (mix of nulls and values)
INSERT INTO public.optional_everything (name, count, amount, flag, tags, meta, stamp) VALUES
  ('full', 42, 99.9, true, '{"a","b"}', '{"key": "val"}', now()),
  (NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  ('partial', NULL, 50.0, NULL, NULL, NULL, NULL);

-- Seed type_zoo
INSERT INTO public.type_zoo (col_int2, col_int4, col_int8, col_float4, col_float8, col_numeric, col_bool, col_text, col_varchar, col_uuid, col_jsonb, col_json, col_text_arr, col_int_arr) VALUES
  (1, 100, 1000000, 1.5, 2.5, 99.99, true, 'hello', 'world', gen_random_uuid(), '{"a":1}', '{"b":2}', '{"x","y"}', '{1,2,3}');

-- Complex RPC: join query
CREATE OR REPLACE FUNCTION public.order_summary()
RETURNS TABLE(order_id bigint, product_name text, quantity int, total_price numeric)
LANGUAGE sql
STABLE
AS $$
  SELECT o.id, p.name, o.quantity, o.total_price
  FROM public.orders o
  JOIN public.products p ON p.id = o.product_id
  ORDER BY o.id;
$$;

-- RPC with multiple join
CREATE OR REPLACE FUNCTION public.order_items_detail(p_order_id bigint)
RETURNS TABLE(product_name text, quantity int, unit_price numeric, line_total numeric)
LANGUAGE sql
STABLE
AS $$
  SELECT p.name, oi.quantity, oi.unit_price, (oi.quantity * oi.unit_price - oi.discount) as line_total
  FROM public.order_items oi
  JOIN public.products p ON p.id = oi.product_id
  WHERE oi.order_id = p_order_id
  ORDER BY p.name;
$$;

GRANT EXECUTE ON FUNCTION public.order_summary() TO anon;
GRANT EXECUTE ON FUNCTION public.order_items_detail(bigint) TO anon;
