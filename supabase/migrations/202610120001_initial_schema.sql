create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null check (char_length(name_ar) between 1 and 80),
  slug text not null unique,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name_ar text not null check (char_length(name_ar) between 1 and 120),
  description_ar text check (description_ar is null or char_length(description_ar) <= 1000),
  price_egp numeric(10,2) check (price_egp is null or price_egp >= 0),
  image_path text,
  is_published boolean not null default false,
  is_available boolean not null default true,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  title_ar text not null check (char_length(title_ar) between 1 and 120),
  description_ar text check (description_ar is null or char_length(description_ar) <= 1000),
  image_path text,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default false,
  is_published boolean not null default false,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  check (starts_at is null or ends_at is null or ends_at > starts_at)
);
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 80),
  message text not null check (char_length(message) between 8 and 1000),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create index if not exists menu_items_public_idx on public.menu_items(is_published,is_available,category_id);
create index if not exists offers_public_idx on public.offers(is_published,is_active,starts_at,ends_at);
create index if not exists feedback_public_idx on public.feedback(status,created_at desc);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admin_users where user_id = (select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.admin_users enable row level security;
alter table public.categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.offers enable row level security;
alter table public.feedback enable row level security;

create policy "admins can read their admin membership" on public.admin_users for select to authenticated using (user_id = (select auth.uid()));
create policy "public reads categories used by published menu" on public.categories for select to anon, authenticated using (exists(select 1 from public.menu_items mi where mi.category_id = categories.id and mi.is_published and mi.is_available) or public.is_admin());
create policy "admins manage categories" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads published available menu" on public.menu_items for select to anon, authenticated using ((is_published and is_available) or public.is_admin());
create policy "admins manage menu" on public.menu_items for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads current published offers" on public.offers for select to anon, authenticated using ((is_active and is_published and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now())) or public.is_admin());
create policy "admins manage offers" on public.offers for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public submits pending feedback" on public.feedback for insert to anon, authenticated with check (status = 'pending');
create policy "admins read feedback" on public.feedback for select to authenticated using (public.is_admin());
create policy "public reads approved feedback" on public.feedback for select to anon, authenticated using (status = 'approved');
create policy "admins moderate feedback" on public.feedback for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins delete feedback" on public.feedback for delete to authenticated using (public.is_admin());

grant select on public.categories, public.menu_items, public.offers, public.feedback to anon, authenticated;
grant insert on public.feedback to anon, authenticated;
grant insert, update, delete on public.categories, public.menu_items, public.offers to authenticated;
grant update, delete on public.feedback to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('restaurant-images','restaurant-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg','image/png','image/webp'];
create policy "public reads restaurant images" on storage.objects for select to anon, authenticated using (bucket_id = 'restaurant-images');
create policy "admins upload restaurant images" on storage.objects for insert to authenticated with check (bucket_id = 'restaurant-images' and public.is_admin());
create policy "admins update restaurant images" on storage.objects for update to authenticated using (bucket_id = 'restaurant-images' and public.is_admin()) with check (bucket_id = 'restaurant-images' and public.is_admin());
create policy "admins delete restaurant images" on storage.objects for delete to authenticated using (bucket_id = 'restaurant-images' and public.is_admin());
