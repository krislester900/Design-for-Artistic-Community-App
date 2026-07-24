-- ============================================================
-- Artéïa - Migration safe pour categories existantes
-- A exécuter APRES schema-consolidated.sql
-- Gère les tables categories avec colonnes différentes
-- ============================================================

do $$
begin
  -- Vérifier si la table categories existe
  if exists (select 1 from information_schema.tables where table_name = 'categories') then
    
    -- Vérifier les colonnes existantes
    declare
      has_name boolean;
      has_title boolean;
      has_description boolean;
      has_icon boolean;
      has_color boolean;
      has_sort_order boolean;
      has_created_at boolean;
    begin
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'name') into has_name;
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'title') into has_title;
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'description') into has_description;
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'icon') into has_icon;
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'color') into has_color;
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'sort_order') into has_sort_order;
      select 
        exists (select 1 from information_schema.columns where table_name = 'categories' and column_name = 'created_at') into has_created_at;

      -- Si title existe mais pas name, on renomme title en name
      if has_title and not has_name then
        alter table public.categories rename column title to name;
      end if;

      -- Si ni name ni title n'existe, on ajoute name
      if not has_name and not has_title then
        alter table public.categories add column name text not null default '';
      end if;

      -- Ajouter les colonnes manquantes
      if not has_description then
        alter table public.categories add column description text default '';
      end if;
      if not has_icon then
        alter table public.categories add column icon text default '📝';
      end if;
      if not has_color then
        alter table public.categories add column color text default '#7C5CFC';
      end if;
      if not has_sort_order then
        alter table public.categories add column sort_order int default 0;
      end if;
      if not has_created_at then
        alter table public.categories add column created_at timestamptz default now();
      end if;
    end;

    -- Upsert des catégories avec les slugs attendus par le Flutter actuel
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
    
    -- Si la table n'a pas de contrainte d'unicité sur slug, on évite les doublons manuellement
    if not exists (
      select 1 from information_schema.constraint_column_usage
      where table_name = 'categories' and column_name = 'slug'
    ) then
      update public.categories set
        slug = case
          when lower(slug) in ('musique', 'music') then 'music'
          when lower(slug) in ('art-visuel', 'visual-art', 'art visuel') then 'visual-art'
          when lower(slug) in ('litterature', 'literature', 'ecriture', 'écriture') then 'literature'
          when lower(slug) in ('manga', 'bd') then 'manga'
          when lower(slug) in ('films', 'film') then 'film'
          when lower(slug) in ('animation') then 'animation'
          else slug
        end,
        name = case
          when lower(slug) in ('musique', 'music') then 'Musique'
          when lower(slug) in ('art-visuel', 'visual-art', 'art visuel') then 'Arts Visuels'
          when lower(slug) in ('litterature', 'literature', 'ecriture', 'écriture') then 'Littérature'
          when lower(slug) in ('manga', 'bd') then 'Manga'
          when lower(slug) in ('films', 'film') then 'Films'
          when lower(slug) in ('animation') then 'Animation'
          else name
        end;
    end if;
  end if;
end $$;
