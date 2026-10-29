-- Configuration de la base de donnees pour l'application Paris 2026.
-- Ce script peut etre execute plusieurs fois sans supprimer les inscriptions.

begin;

create extension if not exists pgcrypto;

create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  nom_complet text not null,
  sexe text not null,
  profil_fonction text not null,
  whatsapp text not null,
  email text not null,
  achat_livre text not null,
  choix_livre text,
  created_at timestamptz not null default now(),

  constraint registrations_nom_complet_length
    check (char_length(trim(nom_complet)) between 1 and 120),
  constraint registrations_sexe_value
    check (sexe in ('Homme', 'Femme')),
  constraint registrations_profil_length
    check (char_length(trim(profil_fonction)) between 1 and 120),
  constraint registrations_whatsapp_length
    check (char_length(trim(whatsapp)) between 6 and 30),
  constraint registrations_email_length
    check (char_length(trim(email)) between 3 and 150),
  constraint registrations_achat_livre_value
    check (achat_livre in ('oui', 'non')),
  constraint registrations_choix_livre_value
    check (
      (
        achat_livre = 'oui'
        and choix_livre in (
          'Comprennent-ils le temps ? — 30 €',
          'Construire la RDC du futur — 50 €',
          'Les deux livres — 50 €'
        )
      )
      or (achat_livre = 'non' and choix_livre is null)
    )
);

create index if not exists registrations_created_at_idx
  on public.registrations (created_at desc);

alter table public.registrations enable row level security;

-- Retire les anciens droits et les anciennes politiques, le cas echeant.
revoke all on table public.registrations from anon, authenticated;

drop policy if exists "Anyone can register" on public.registrations;
drop policy if exists "Admins can read registrations" on public.registrations;
drop policy if exists "Admins can delete registrations" on public.registrations;
drop policy if exists "Public can read registrations" on public.registrations;
drop policy if exists "Public can delete registrations" on public.registrations;

-- Le formulaire public peut creer une inscription.
grant insert (
  reference,
  nom_complet,
  sexe,
  profil_fonction,
  whatsapp,
  email,
  achat_livre,
  choix_livre
) on table public.registrations to anon, authenticated;

create policy "Anyone can register"
  on public.registrations
  for insert
  to anon, authenticated
  with check (true);

-- Le dashboard actuel est public et peut lire les inscriptions.
grant select on table public.registrations to anon, authenticated;

create policy "Public can read registrations"
  on public.registrations
  for select
  to anon, authenticated
  using (true);

-- Le dashboard actuel permet aussi la suppression sans connexion.
grant delete on table public.registrations to anon, authenticated;

create policy "Public can delete registrations"
  on public.registrations
  for delete
  to anon, authenticated
  using (true);

commit;
