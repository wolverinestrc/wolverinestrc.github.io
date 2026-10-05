-- Panel /socialmedia: publicaciones de Instagram y Facebook.
-- Solo estas dos tablas nuevas; no toca ninguna tabla existente.

create table if not exists public.social_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nombre  text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  fecha date not null,
  plataformas text[] not null default array['instagram','facebook'],
  formato text not null default 'post' check (formato in ('post','carrusel','reel','historia')),
  titulo text not null,
  texto text,
  hashtags text,
  material text,
  notas text,
  url_publicacion text,
  publicado boolean not null default false,
  publicado_at timestamptz,
  publicado_por uuid references auth.users(id),
  creado_por uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists social_posts_fecha_idx on public.social_posts (fecha);

alter table public.social_access enable row level security;
alter table public.social_posts  enable row level security;

-- Cada usuario solo puede ver su propia fila de acceso (suficiente para las politicas de abajo).
create policy social_access_self on public.social_access
  for select to authenticated using (user_id = (select auth.uid()));

-- Solo usuarios listados en social_access pueden leer y escribir publicaciones. El rol anon no tiene acceso.
create policy social_posts_select on public.social_posts for select to authenticated
  using (exists (select 1 from public.social_access a where a.user_id = (select auth.uid())));
create policy social_posts_insert on public.social_posts for insert to authenticated
  with check (exists (select 1 from public.social_access a where a.user_id = (select auth.uid())));
create policy social_posts_update on public.social_posts for update to authenticated
  using (exists (select 1 from public.social_access a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.social_access a where a.user_id = (select auth.uid())));
create policy social_posts_delete on public.social_posts for delete to authenticated
  using (exists (select 1 from public.social_access a where a.user_id = (select auth.uid())));

create or replace function public.social_posts_touch() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;
create trigger social_posts_touch before update on public.social_posts
  for each row execute function public.social_posts_touch();
