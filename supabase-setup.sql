-- Padel Club cloud sync. Run once in Supabase SQL Editor.
create table if not exists public.padel_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.padel_club_state (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.padel_admins enable row level security;
alter table public.padel_club_state enable row level security;
drop policy if exists "admin self-read" on public.padel_admins;
create policy "admin self-read" on public.padel_admins for select to authenticated using (user_id=auth.uid());
drop policy if exists "public state read" on public.padel_club_state;
create policy "public state read" on public.padel_club_state for select to anon,authenticated using (id='main');
drop policy if exists "admin state insert" on public.padel_club_state;
create policy "admin state insert" on public.padel_club_state for insert to authenticated with check
(id='main' and exists(select 1 from public.padel_admins where user_id=auth.uid()));
drop policy if exists "admin state update" on public.padel_club_state;
create policy "admin state update" on public.padel_club_state for update to authenticated using
(id='main' and exists(select 1 from public.padel_admins where user_id=auth.uid()))
with check (id='main' and exists(select 1 from public.padel_admins where user_id=auth.uid()));
revoke all on public.padel_admins from anon;
revoke insert,update,delete,truncate,references,trigger on public.padel_admins from authenticated;
grant select on public.padel_admins to authenticated;
revoke insert,update,delete,truncate,references,trigger on public.padel_club_state from anon;
grant select on public.padel_club_state to anon;
revoke delete,truncate,references,trigger on public.padel_club_state from authenticated;
grant select,insert,update on public.padel_club_state to authenticated;
alter publication supabase_realtime add table public.padel_club_state;
-- After administrator signs in for first time, run ONCE replacing email:
-- insert into public.padel_admins(user_id)
-- select id from auth.users where lower(email)=lower('YOUR_ADMIN_EMAIL@example.com')
-- on conflict do nothing;
-- No secret keys belong in frontend source.
