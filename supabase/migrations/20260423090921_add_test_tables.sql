-- Test table for exercising all query operators
CREATE TABLE public.products (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  description text,
  price numeric NOT NULL DEFAULT 0,
  tags text[] NOT NULL DEFAULT '{}',
  metadata jsonb NOT NULL DEFAULT '{}',
  in_stock boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  fts tsvector GENERATED ALWAYS AS (to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, ''))) STORED
);

-- Enable RLS but allow anon access for testing
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_all" ON public.products FOR ALL TO anon USING (true) WITH CHECK (true);

-- Seed some test data
INSERT INTO public.products (name, description, price, tags, metadata, in_stock) VALUES
  ('Widget A', 'A small widget', 10.00, '{"small", "metal"}', '{"color": "red", "weight": 100}', true),
  ('Widget B', 'A medium widget', 25.50, '{"medium", "plastic"}', '{"color": "blue", "weight": 250}', true),
  ('Widget C', 'A large widget', 99.99, '{"large", "metal"}', '{"color": "red", "weight": 500}', false),
  ('Gadget X', 'A fancy gadget', 150.00, '{"large", "electronic"}', '{"color": "black", "weight": 300}', true),
  ('Gadget Y', NULL, 5.00, '{"small", "plastic"}', '{"color": "green", "weight": 50}', true);

-- RPC function for testing
CREATE OR REPLACE FUNCTION public.products_cheaper_than(max_price numeric)
RETURNS SETOF public.products
LANGUAGE sql
STABLE
AS $$
  SELECT * FROM public.products WHERE price < max_price ORDER BY price;
$$;

-- RPC function without params for testing
CREATE OR REPLACE FUNCTION public.product_count()
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
  SELECT count(*) FROM public.products;
$$;

-- Grant access
GRANT EXECUTE ON FUNCTION public.products_cheaper_than(numeric) TO anon;
GRANT EXECUTE ON FUNCTION public.product_count() TO anon;
