create table if not exists public.user_relationship_memory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  entity_name text not null,
  inferred_relationship text,
  confidence real default 0.5,
  context text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_relationships_user on public.user_relationship_memory(user_id);
create index if not exists idx_user_relationships_entity on public.user_relationship_memory(entity_name);