-- Retire visitor-submitted feedback without deleting its historical rows.
drop policy if exists "public submits pending feedback" on public.feedback;
drop policy if exists "public reads approved feedback" on public.feedback;
revoke insert, select on public.feedback from anon;
revoke insert on public.feedback from authenticated;
grant select, update, delete on public.feedback to authenticated;

-- Add an explicit review workflow for names/prices transcribed from low-resolution menu sources.
alter table public.menu_items add column if not exists needs_review boolean not null default false;
alter table public.menu_items add column if not exists review_note_ar text;
alter table public.menu_items add column if not exists variation_ar text[] not null default '{}';
drop policy if exists "public reads published available menu" on public.menu_items;
create policy "public reads published verified menu" on public.menu_items for select to anon, authenticated
  using ((is_published and is_available and not needs_review) or public.is_admin());
drop policy if exists "public reads categories used by published menu" on public.categories;
create policy "public reads categories used by verified menu" on public.categories for select to anon, authenticated
  using (exists(select 1 from public.menu_items mi where mi.category_id = categories.id and mi.is_published and mi.is_available and not mi.needs_review) or public.is_admin());

-- Testimonials are authored only by administrators. Legacy customer feedback is deliberately not copied.
create table if not exists public.testimonials (
  id uuid primary key default gen_random_uuid(),
  display_name text check (display_name is null or char_length(display_name) between 1 and 80),
  content text not null check (char_length(content) between 8 and 1000),
  rating smallint check (rating is null or rating between 1 and 5),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists testimonials_public_idx on public.testimonials(is_published, created_at desc);
alter table public.testimonials enable row level security;
create policy "public reads published testimonials" on public.testimonials for select to anon, authenticated
  using (is_published or public.is_admin());
create policy "admins manage testimonials" on public.testimonials for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select on public.testimonials to anon, authenticated;
grant insert, update, delete on public.testimonials to authenticated;
