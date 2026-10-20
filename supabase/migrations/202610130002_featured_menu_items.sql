-- Allow administrators to choose published menu items for the featured dishes section.
alter table public.menu_items
  add column if not exists is_featured boolean not null default false;

create index if not exists menu_items_featured_public_idx
  on public.menu_items(is_featured, is_published, is_available);
