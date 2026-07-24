-- ============================================================
-- Artéïa - Migration safe pour categories
-- Ce script adapte la table categories existante
-- ============================================================

-- D'abord, on adapte la table categories si elle existe
do $$
begin
  if exists (select 1 from information_schema.tables where table_name = 'categories') then
    -- Ajouter les colonnes manquantes si elles n'existent pas
    if not exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'name') then
      alter table public.categories add column name text;
    end if;
    if not exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'description') then
      alter table public.categories add column description text default '';
    end if;
    if not exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'icon') then
      alter table public.categories add column icon text default '📝';
    end if;
    if not exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'color') then
      alter table public.categories add column color text default '#7C5CFC';
    end if;
    if not exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'sort_order') then
      alter table public.categories add column sort_order int default 0;
    end if;
    if not exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'created_at') then
      alter table public.categories add column created_at timestamptz default now();
    end if;
  end if;
end $$;

-- Maintenant, on peut insérer les catégories
insert into public.categories (slug, name, description, icon, color, sort_order) values
  ('visual-art', 'Arts Visuels', 'Galerie et discussions artistiques', '🎨', '#00D4AA', 1),
  ('music', 'Musique', 'Partagez vos créations musicales', '🎵', '#7C5CFC', 2),
  ('literature', 'Littérature', 'Poèmes, histoires et écrits', '✍️', '#FF6B9D', 3),
  ('manga', 'Manga', 'Mangas et illustrations japonaises', '📚', '#FFA500', 4),
  ('film', 'Films', 'Cinéma et productions vidéo', '🎬', '#00BFFF', 5),
  ('animation', 'Animation', 'Animations et motion design', '🎞️', '#FF69B4', 6)
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  sort_order = excluded.sort_order;
