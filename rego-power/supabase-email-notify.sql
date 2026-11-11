-- REGO Power — email a notification for each new entry
--
-- Optional add-on. Run supabase-setup.sql first, then this file, then the one
-- line at the bottom that stores the Postmark token.
--
-- The token is NOT in this file and must never be committed: this repository is
-- public, and anyone holding the token can send email as your domain. It lives in
-- public.rego_notify, which has Row Level Security on and no grants, so neither
-- the publishable key nor any visitor can read it.
--
-- An email is sent once per person, the moment they leave contact details — not
-- on every game. Scores posted afterwards update their row silently.
--
-- pg_net sends the request after the transaction commits, so a slow or failing
-- Postmark never delays or fails a player's submission. The trade-off is that a
-- failed send is not retried; the entry is still in the table either way.

create extension if not exists pg_net;

-- ------------------------------------------------------------- where to send --
create table if not exists public.rego_notify (
  id         boolean primary key default true check (id),
  token      text not null,                   -- Postmark SERVER token
  from_email text not null,                   -- must be a confirmed Sender Signature
  to_email   text not null
);

alter table public.rego_notify enable row level security;
revoke all on public.rego_notify from anon, authenticated;

create or replace function public.rego_set_notify(p_token text, p_from text, p_to text)
returns text
language plpgsql
security definer
set search_path = ''
as $fn$
begin
  insert into public.rego_notify (id, token, from_email, to_email)
  values (true, p_token, p_from, p_to)
  on conflict (id) do update
    set token = excluded.token, from_email = excluded.from_email, to_email = excluded.to_email;
  return 'Notifications on. Entries will be emailed to ' || p_to || '.';
end;
$fn$;

revoke all on function public.rego_set_notify(text, text, text) from public, anon, authenticated;

-- one email per person, never a second
alter table public.rego_entries add column if not exists notified_at timestamptz;

-- ------------------------------------------------------------- the notifier --
create or replace function public.rego_notify_entry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  cfg   public.rego_notify%rowtype;
  who   text;
  body  text;
begin
  -- only when contact details have just arrived, and only once
  if new.contact is null or new.notified_at is not null then
    return new;
  end if;

  select * into cfg from public.rego_notify where id;
  if not found or cfg.token is null then
    return new;            -- not configured: carry on without an email
  end if;

  -- the full name is optional for the player, so fall back to their board name
  who := coalesce(nullif(trim(coalesce(new.full_name, '')), ''), new.name);

  body := 'REGO Power — new entry' || chr(10) || chr(10)
       || 'Name:        ' || who || chr(10)
       || 'Company:     ' || coalesce(nullif(new.company, ''), '—') || chr(10)
       || 'Contact:     ' || new.contact
          || ' (' || coalesce(new.contact_kind, 'unknown') || ')' || chr(10)
       || 'News opt-in: ' || case when new.opt_in then 'YES' else 'no' end || chr(10) || chr(10)
       || 'Best score:  ' || case when new.best_at is null then 'no finished run yet'
            else new.best_score || '  (' || new.best_regos || ' REGOs, day ' || new.best_day || ')' end
          || chr(10)
       || 'Games:       ' || new.plays || chr(10)
       || 'Event:       ' || new.event || chr(10)
       || 'Entered:     ' || to_char(now() at time zone 'Pacific/Auckland',
                                     'DD Mon YYYY, HH24:MI') || ' NZ' || chr(10) || chr(10)
       || 'Wording they agreed to:' || chr(10)
       || coalesce(new.consent_text, '—');

  perform net.http_post(
    url     := 'https://api.postmarkapp.com/email',
    headers := jsonb_build_object(
                 'Accept', 'application/json',
                 'Content-Type', 'application/json',
                 'X-Postmark-Server-Token', cfg.token),
    -- strip_nulls because ReplyTo is absent when the player left a mobile number,
    -- and Postmark rejects a null where it expects a string
    body    := jsonb_strip_nulls(jsonb_build_object(
                 'From', cfg.from_email,
                 'To', cfg.to_email,
                 'ReplyTo', case when new.contact_kind = 'email' then new.contact end,
                 'Subject', 'REGO Power Entry: ' || who,
                 'TextBody', body,
                 'Tag', 'rego-power-entry',
                 'MessageStream', 'outbound')),
    timeout_milliseconds := 5000);

  new.notified_at := now();
  return new;
end;
$fn$;

-- BEFORE, so the stamp is written in the same row write and the trigger cannot
-- set off another round of itself
drop trigger if exists rego_entries_notify on public.rego_entries;
create trigger rego_entries_notify
  before insert or update on public.rego_entries
  for each row execute function public.rego_notify_entry();

-- ------------------------------------------------------------------ switch on --
-- Run this ONCE, here in the SQL Editor, with your own token. Do not commit it.
-- The From address must be a confirmed Sender Signature in Postmark, or Postmark
-- rejects the send with a 422 and no email arrives.
--
--   select public.rego_set_notify(
--     'your-postmark-server-token',
--     'noreply@pattech.com',
--     'matthew.saunders@pattech.com');
--
-- Check it is working — recent sends, newest first:
--   select id, created, url, status_code, content
--     from net._http_response order by created desc limit 10;
--
-- Turn it off again without dropping anything:
--   delete from public.rego_notify;
