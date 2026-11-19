-- UniMarket REPORTS setup (run once in Supabase SQL Editor)
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  listing_id uuid references public.listings(id) on delete set null,
  listing_title text check (char_length(listing_title) <= 80),
  reason text not null check (reason in ('scam','fake','sold','wrong_info','no_reply','offensive','other')),
  details text check (char_length(details) <= 500),
  contact text check (contact is null or contact ~ '^[0-9]{10,15}$'),
  status text not null default 'open' check (status in ('open','resolved'))
);
create index if not exists reports_created_idx on public.reports (created_at desc);
alter table public.reports enable row level security;

-- Anyone can send a report (but can't read other people's reports)
drop policy if exists "public report" on public.reports;
create policy "public report" on public.reports
  for insert to anon, authenticated with check (status = 'open');

-- Only admins can read, resolve and delete reports
drop policy if exists "admin read reports" on public.reports;
create policy "admin read reports" on public.reports
  for select to authenticated using (public.is_admin());
drop policy if exists "admin update reports" on public.reports;
create policy "admin update reports" on public.reports
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin delete reports" on public.reports;
create policy "admin delete reports" on public.reports
  for delete to authenticated using (public.is_admin());

grant insert on public.reports to anon, authenticated;
grant select, update, delete on public.reports to authenticated;
