-- Mueve la contrasena de admin fuera del codigo: ya no se compara contra un texto fijo.
-- La contrasena se guarda como hash bcrypt en una tabla que ningun rol de la API puede leer.
-- El hash (no la contrasena) se carga aparte con:
--   insert into public.admin_secret (id, pwd_hash)
--   values (1, extensions.crypt('NUEVA_CONTRASENA', extensions.gen_salt('bf')))
--   on conflict (id) do update set pwd_hash = excluded.pwd_hash, updated_at = now();

create table if not exists public.admin_secret (
  id int primary key default 1 check (id = 1),
  pwd_hash text not null,
  updated_at timestamptz not null default now()
);
alter table public.admin_secret enable row level security;
revoke all on public.admin_secret from anon, authenticated;

create or replace function public.check_admin_pwd(p_pwd text) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if p_pwd is null or not exists (
    select 1 from public.admin_secret s where s.pwd_hash = extensions.crypt(p_pwd, s.pwd_hash)
  ) then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
end;
$$;
