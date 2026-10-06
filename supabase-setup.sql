create extension if not exists pgcrypto;

create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  nom_complet text not null check (char_length(nom_complet) between 1 and 120),
  sexe text not null check (sexe in ('Homme', 'Femme')),
  profil_fonction text not null check (char_length(profil_fonction) between 1 and 120),
  whatsapp text not null check (char_length(whatsapp) between 6 and 30),
  email text not null check (char_length(email) between 3 and 150),
  achat_livre text not null check (achat_livre in ('oui', 'non')),
  choix_livre text,
  created_at timestamptz not null default now(),
  constraint registration_book_choice_check check (
    (achat_livre = 'oui' and choix_livre in (
      'Comprennent-ils le temps ? — 30 €',
      'Construire la RDC du futur — 50 €',
      'Les deux livres — 50 €'
    ))
    or (achat_livre = 'non' and choix_livre is null)
  )
);

alter table public.registrations enable row level security;

revoke all on public.registrations from anon, authenticated;
grant insert (
  reference, nom_complet, sexe, profil_fonction, whatsapp, email,
  achat_livre, choix_livre
) on public.registrations to anon, authenticated;
grant select, delete on public.registrations to anon, authenticated;

drop policy if exists "Anyone can register" on public.registrations;
drop policy if exists "Admins can read registrations" on public.registrations;
drop policy if exists "Admins can delete registrations" on public.registrations;
drop policy if exists "Public can read registrations" on public.registrations;
drop policy if exists "Public can delete registrations" on public.registrations;

create policy "Anyone can register"
  on public.registrations for insert
  to public
  with check (true);

create policy "Public can read registrations"
  on public.registrations for select
  to public
  using (true);

create policy "Public can delete registrations"
  on public.registrations for delete
  to public
  using (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'registrations'
  ) then
    alter publication supabase_realtime add table public.registrations;
  end if;
end;
$$;
