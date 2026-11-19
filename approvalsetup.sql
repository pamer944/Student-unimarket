-- UniMarket APPROVAL setup (run in Supabase SQL Editor)
-- Listings you already have stay live. New listings wait for admin approval.

-- 1) Add "approved" column: existing listings = approved, new ones = pending
alter table public.listings add column if not exists approved boolean not null default true;
alter table public.listings alter column approved set default false;

-- 2) Public can only see listings that are approved and not hidden
drop policy if exists "public read" on public.listings;
create policy "public read" on public.listings
  for select to anon, authenticated
  using (approved = true and hidden = false);

-- 3) Anyone can submit, but it always starts as pending (can't approve themselves)
drop policy if exists "public insert" on public.listings;
create policy "public insert" on public.listings
  for insert to anon, authenticated
  with check (approved = false and featured = false and hidden = false);

-- Check: how many are live vs waiting
select approved, count(*) from public.listings group by approved;
