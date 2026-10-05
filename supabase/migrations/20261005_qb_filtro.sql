-- Panel /qb: filtro de quarterbacks en dos fases (cognitiva y de campo).
-- Tablas nuevas; no tocan ninguna tabla existente. Acceso solo para cuentas listadas en qb_access.

create table if not exists public.qb_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nombre  text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.qb_candidatos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  grupo text not null check (grupo in ('10-11','12-14','15-18')),
  notas text,
  creado_por uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.qb_resultados (
  candidato_id uuid not null references public.qb_candidatos(id) on delete cascade,
  prueba text not null,
  valor numeric not null,
  updated_at timestamptz not null default now(),
  primary key (candidato_id, prueba)
);

create table if not exists public.qb_config (
  id int primary key default 1 check (id = 1),
  config jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.qb_access     enable row level security;
alter table public.qb_candidatos enable row level security;
alter table public.qb_resultados enable row level security;
alter table public.qb_config     enable row level security;

create policy qb_access_self on public.qb_access
  for select to authenticated using (user_id = (select auth.uid()));

do $$
declare t text;
begin
  foreach t in array array['qb_candidatos','qb_resultados','qb_config'] loop
    execute format($f$create policy %1$s_all on public.%1$s for all to authenticated
      using (exists (select 1 from public.qb_access a where a.user_id = (select auth.uid())))
      with check (exists (select 1 from public.qb_access a where a.user_id = (select auth.uid())))$f$, t);
  end loop;
end $$;
