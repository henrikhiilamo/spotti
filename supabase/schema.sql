-- Ilmaispaikka: käyttäjien lisäämät pysäköintipaikat.
-- Aja kerran Supabasen hallintapaneelissa: SQL Editor → New query → liitä tämä → Run.

create table public.spots (
  id         uuid primary key default gen_random_uuid(),
  lat        double precision not null check (lat between -90 and 90),
  lng        double precision not null check (lng between -180 and 180),
  name       text not null check (char_length(name) between 1 and 80),
  maxstay    text not null default '' check (char_length(maxstay) <= 40),
  note       text not null default '' check (char_length(note) <= 200),
  -- Lisääjä: tietokanta täyttää tämän itse kirjautuneen (anonyymin) käyttäjän id:llä.
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

-- Row Level Security (RLS): kun se on päällä, taulusta ei saa lukea eikä
-- siihen kirjoittaa mitään, ellei alla oleva sääntö sitä erikseen salli.
alter table public.spots enable row level security;

-- Kaikki näkevät kaikki paikat, myös kirjautumattomat.
create policy "Kaikki näkevät paikat"
  on public.spots for select
  to anon, authenticated
  using (true);

-- Kirjautunut (myös anonyymi) käyttäjä voi lisätä paikan vain omissa nimissään.
create policy "Lisätä voi vain omissa nimissään"
  on public.spots for insert
  to authenticated
  with check (created_by = (select auth.uid()));

-- Paikan voi poistaa vain sen lisääjä.
create policy "Poistaa voi vain omia paikkojaan"
  on public.spots for delete
  to authenticated
  using (created_by = (select auth.uid()));

-- Oikeudet: mitä toimintoja kukin rooli ylipäätään saa yrittää.
-- Muokkausta (update) ei sallita kenellekään.
revoke all on public.spots from anon, authenticated;
grant select on public.spots to anon, authenticated;
grant insert, delete on public.spots to authenticated;
