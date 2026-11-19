-- UniMarket ADMIN setup
-- BEFORE running: create your admin login in Supabase →
--   Authentication → Users → Add user → Create new user
--   (enter email + password, tick "Auto Confirm User")
-- for BOTH emails: zuluiwell26@gmail.com and mumbap771@gmail.com
-- THEN paste this whole file and click Run.

-- 1) Table of admins (not readable from the website)
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

-- 2) "Is the logged-in person an admin?" check
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admins where user_id = auth.uid()); $$;
grant execute on function public.is_admin() to anon, authenticated;

-- 3) Admins can see hidden listings, edit and delete
drop policy if exists "admin read all" on public.listings;
create policy "admin read all" on public.listings
  for select to authenticated using (public.is_admin());

drop policy if exists "admin update" on public.listings;
create policy "admin update" on public.listings
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin delete" on public.listings;
create policy "admin delete" on public.listings
  for delete to authenticated using (public.is_admin());

grant update, delete on public.listings to authenticated;

-- 4) Admins can delete photos
drop policy if exists "admin read images" on storage.objects;
create policy "admin read images" on storage.objects
  for select to authenticated using (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "admin delete images" on storage.objects;
create policy "admin delete images" on storage.objects
  for delete to authenticated using (bucket_id = 'product-images' and public.is_admin());

-- 5) Only these two accounts are admins
delete from public.admins
where user_id not in (select id from auth.users where lower(email) in ('zuluiwell26@gmail.com','mumbap771@gmail.com'));

insert into public.admins (user_id)
select id from auth.users where lower(email) in ('zuluiwell26@gmail.com','mumbap771@gmail.com')
on conflict do nothing;

-- Check it worked (should show 2 rows):
select u.email from public.admins a join auth.users u on u.id = a.user_id;
