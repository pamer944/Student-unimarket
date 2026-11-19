-- Student UniMarket – Supabase setup
-- Paste into Supabase → SQL Editor → New query → Run.
-- Safe to run more than once.

-- 1) Listings table (creates it, or adds missing columns to your existing one)
create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  type text not null,
  title text not null
);

alter table public.listings
  add column if not exists category    text,
  add column if not exists price       text,
  add column if not exists location    text,
  add column if not exists status      text,
  add column if not exists features    text,
  add column if not exists seller      text,
  add column if not exists phone       text,
  add column if not exists course      text,
  add column if not exists link        text,
  add column if not exists description text,
  add column if not exists image_url   text,
  add column if not exists featured    boolean not null default false,
  add column if not exists hidden      boolean not null default false;

-- 2) Rules the database enforces (so nobody can skip them by calling the API directly)
alter table public.listings drop constraint if exists listings_rules;
alter table public.listings add constraint listings_rules check (
  type in ('product','room','material','video')
  and char_length(title) between 2 and 80
  and coalesce(char_length(category),0)    <= 40
  and coalesce(char_length(price),0)       <= 30
  and coalesce(char_length(location),0)    <= 60
  and coalesce(char_length(status),0)      <= 30
  and coalesce(char_length(features),0)    <= 200
  and coalesce(char_length(seller),0)      <= 60
  and coalesce(char_length(course),0)      <= 20
  and coalesce(char_length(description),0) <= 1000
  and (phone is null or phone ~ '^[0-9]{10,15}$')
  and (link is null or (link ~* '^https?://' and char_length(link) <= 500))
  and (image_url is null or image_url like 'https://wcvualnkdslszltismqs.supabase.co/storage/v1/object/public/product-images/%')
) not valid;  -- "not valid" = old rows aren't checked, new ones are

create index if not exists listings_created_idx on public.listings (created_at desc);

-- 3) Who can do what
alter table public.listings enable row level security;

-- Remove old policies (names from earlier setups — delete any others in the dashboard too)
drop policy if exists "public read"   on public.listings;
drop policy if exists "public insert" on public.listings;

-- Everyone can see listings that aren't hidden
create policy "public read" on public.listings
  for select to anon, authenticated
  using (hidden = false);

-- Anyone can post, but can't make their own listing featured or hidden
create policy "public insert" on public.listings
  for insert to anon, authenticated
  with check (featured = false and hidden = false);

-- No update/delete policies = only you (in the dashboard) can edit, feature or remove listings.

-- 4) Photo storage bucket: public, images only, max 5 MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = true,
      file_size_limit = 5242880,
      allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "public upload product images" on storage.objects;
create policy "public upload product images" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'product-images');

-- ADMIN TIPS (Table Editor → listings):
--   Remove a scam/spam listing:  set hidden = true
--   Feature a paid listing:      set featured = true
