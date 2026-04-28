CREATE TABLE public.user_pillars (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL DEFAULT auth.uid() UNIQUE,
  pillars text[] NOT NULL DEFAULT '{}'::text[],
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_pillars_pkey PRIMARY KEY (id),
  CONSTRAINT user_pillars_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);