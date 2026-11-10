-- REGO Power — event leaderboard and lead capture
--
-- Paste the whole file into the Supabase SQL Editor and press Run. It is safe to
-- run more than once.
--
-- There is no admin page and no admin passphrase. Entries, contact details and
-- opt-ins are read, exported and deleted from the Supabase table editor, so the
-- only way to reach anyone's contact details is to log in to Supabase.
--
-- The publishable key in rego-config.js can call exactly two functions, listed at
-- the bottom. The table itself is closed: Row Level Security is on, no policy is
-- written, and the table grants are revoked — so the only way in or out is through
-- a function that validates its arguments first. Neither function ever returns a
-- contact detail.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------- entries ----
create table if not exists public.rego_entries (
  id            uuid        primary key,
  event         text        not null,
  key_hash      text        not null,   -- sha256 of the phone's key; the key is never stored
  name          text        not null,   -- the short name shown on the board
  best_score    integer     not null default -1,
  best_regos    integer     not null default 0,
  best_day      integer     not null default 0,
  best_mode     text,
  best_at       timestamptz,            -- null until a finished run is posted
  plays         integer     not null default 0,
  full_name     text,
  company       text,
  contact       text,
  contact_kind  text,                   -- 'email' or 'mobile'
  opt_in        boolean     not null default false,
  opt_in_at     timestamptz,
  consent_text  text,                   -- the exact wording the player was shown
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- the ranking order: highest score first, and whoever got there first wins ties
create index if not exists rego_entries_rank_idx
  on public.rego_entries (event, best_score desc, best_at asc);

alter table public.rego_entries enable row level security;
revoke all on public.rego_entries from anon, authenticated;

-- -------------------------------------------------------------- the board ----
-- One shape for every caller: the top ten, the total, and the caller's own row if
-- they have one. Contact details are never part of it.
create or replace function public.rego_board_json(p_event text, p_id uuid, p_improved boolean)
returns jsonb
language sql
security definer
set search_path = ''
stable
as $fn$
  with ranked as (
    select e.id, e.name, e.best_score, e.best_regos, e.best_day,
           e.contact is not null as in_draw,
           row_number() over (order by e.best_score desc, e.best_at asc) as rank
      from public.rego_entries e
     where e.event = p_event and e.best_at is not null
  )
  select jsonb_build_object(
    'total',    (select count(*) from ranked),
    'improved', coalesce(p_improved, false),
    'top',      coalesce((
                  select jsonb_agg(jsonb_build_object(
                           'rank',  r.rank, 'name', r.name, 'score', r.best_score,
                           'regos', r.best_regos, 'day', r.best_day,
                           'me',    p_id is not null and r.id = p_id)
                         order by r.rank)
                    from ranked r where r.rank <= 10), '[]'::jsonb),
    'me',       (select jsonb_build_object('rank', r.rank, 'name', r.name,
                         'score', r.best_score, 'in_draw', r.in_draw)
                   from ranked r where p_id is not null and r.id = p_id)
  );
$fn$;

revoke all on function public.rego_board_json(text, uuid, boolean) from public, anon, authenticated;

create or replace function public.rego_board(p_event text, p_id uuid default null)
returns jsonb
language sql
security definer
set search_path = ''
stable
as $fn$
  select public.rego_board_json(lower(trim(p_event)), p_id, false);
$fn$;

-- --------------------------------------------------------------- submitting --
create or replace function public.rego_submit(
  p_event     text,
  p_id        uuid,
  p_key       text,
  p_name      text,
  p_score     integer default null,
  p_regos     integer default null,
  p_day       integer default null,
  p_mode      text    default null,
  p_final     boolean default true,
  p_full_name text    default null,
  p_company   text    default null,
  p_contact   text    default null,
  p_opt_in    boolean default false,
  p_consent   text    default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_event    text := lower(trim(coalesce(p_event, '')));
  v_name     text := upper(trim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g')));
  v_hash     text := encode(extensions.digest(coalesce(p_key, ''), 'sha256'), 'hex');
  v_contact  text := nullif(trim(regexp_replace(coalesce(p_contact, ''), '\s+', ' ', 'g')), '');
  v_kind     text;
  v_entry    public.rego_entries%rowtype;
  v_improved boolean := false;
begin
  if v_event !~ '^[a-z0-9][a-z0-9-]{0,31}$' then
    raise exception 'bad_event' using errcode = '22023';
  end if;
  if p_id is null or length(coalesce(p_key, '')) < 16 then
    raise exception 'bad_key' using errcode = '22023';
  end if;
  if v_name = '' or length(v_name) > 12 then
    raise exception 'bad_name' using errcode = '22023';
  end if;
  if length(coalesce(p_full_name, '')) > 80
     or length(coalesce(p_company, '')) > 80
     or length(coalesce(v_contact, '')) > 120
     or length(coalesce(p_consent, '')) > 1000 then
    raise exception 'too_long' using errcode = '22023';
  end if;

  if v_contact is not null then
    if v_contact ~ '^[^@\s]+@[^@\s]+\.[^@\s]{2,}$' then
      v_kind := 'email';
    elsif v_contact ~ '^\+?[0-9 ()-]{7,20}$'
      and length(regexp_replace(v_contact, '\D', '', 'g')) between 7 and 15 then
      v_kind := 'mobile';
    else
      raise exception 'bad_contact' using errcode = '22023';
    end if;
  end if;

  if p_score is not null and (p_score < 0 or p_score > 9999999
       or coalesce(p_day, 1) < 1 or coalesce(p_day, 1) > 999
       or coalesce(p_regos, 0) < 0 or coalesce(p_regos, 0) > 24 * coalesce(p_day, 1)) then
    raise exception 'bad_score' using errcode = '22023';
  end if;

  select * into v_entry from public.rego_entries where id = p_id;

  if not found then
    if (select count(*) from public.rego_entries where event = v_event) >= 5000 then
      raise exception 'event_full' using errcode = '22023';
    end if;
    insert into public.rego_entries (id, event, key_hash, name)
    values (p_id, v_event, v_hash, v_name)
    returning * into v_entry;
  elsif v_entry.key_hash <> v_hash or v_entry.event <> v_event then
    -- someone else's id, or the same id replayed against another event
    raise exception 'bad_key' using errcode = '22023';
  end if;

  if p_score is not null and p_score > v_entry.best_score then
    v_improved := true;
  end if;

  update public.rego_entries e set
    name         = v_name,
    plays        = e.plays + case when p_score is not null and p_final then 1 else 0 end,
    best_score   = case when v_improved then p_score                  else e.best_score end,
    best_regos   = case when v_improved then coalesce(p_regos, 0)     else e.best_regos end,
    best_day     = case when v_improved then coalesce(p_day, 1)       else e.best_day end,
    best_mode    = case when v_improved then p_mode                   else e.best_mode end,
    best_at      = case when v_improved then now()                    else e.best_at end,
    full_name    = coalesce(nullif(trim(coalesce(p_full_name, '')), ''), e.full_name),
    company      = coalesce(nullif(trim(coalesce(p_company, '')), ''), e.company),
    contact      = coalesce(v_contact, e.contact),
    contact_kind = coalesce(v_kind, e.contact_kind),
    opt_in       = case when v_contact is not null then coalesce(p_opt_in, false) else e.opt_in end,
    opt_in_at    = case when v_contact is not null and coalesce(p_opt_in, false)
                        then now() else e.opt_in_at end,
    consent_text = case when v_contact is not null then p_consent else e.consent_text end,
    updated_at   = now()
  where e.id = p_id;

  return public.rego_board_json(v_event, p_id, v_improved);
end;
$fn$;

-- -------------------------------------------------------- what anon may call --
-- Everything else stays closed. These two are the whole public surface.
revoke all on function public.rego_board(text, uuid) from public, anon, authenticated;
revoke all on function public.rego_submit(text, uuid, text, text, integer, integer, integer,
         text, boolean, text, text, text, boolean, text) from public, anon, authenticated;

grant execute on function public.rego_board(text, uuid) to anon;
grant execute on function public.rego_submit(text, uuid, text, text, integer, integer, integer,
         text, boolean, text, text, text, boolean, text) to anon;

-- If an earlier version of this file was ever run, these remove the admin surface
-- it created. Harmless when they were never there.
drop function if exists public.rego_admin_list(text, text);
drop function if exists public.rego_admin_remove(text, uuid);
drop function if exists public.rego_admin_clear(text, text);
drop function if exists public.rego_admin_ok(text);
drop function if exists public.rego_set_admin_pass(text);
drop table if exists public.rego_admin;

-- ----------------------------------------------------------------- exports ---
-- Reading the leads: Table editor -> rego_entries, or run this and use the
-- "Download CSV" button above the results.
--
--   select name, full_name, company, contact, contact_kind, opt_in, opt_in_at,
--          best_score, best_regos, best_day, plays, consent_text, created_at, updated_at
--     from public.rego_entries
--    where event = 'meug-2026'
--    order by best_score desc, best_at asc;
--
-- Someone asks to be removed:
--   delete from public.rego_entries where contact = 'them@example.com';
