-- ============================================================
-- ONTOLOGIE ARTISTIQUE ARTEÏA
-- Structure les connaissances pour l'assistant IA
-- ============================================================

-- 1. CONCEPTS DE BASE (nœuds de l'ontologie)
CREATE TABLE IF NOT EXISTS ontology_concepts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'technique', 'style', 'mouvement', 'medium', 'outil',
    'theorie', 'genre', 'format', 'artiste', 'oeuvre'
  )),
  icon TEXT DEFAULT '📚',
  difficulty TEXT CHECK (difficulty IN ('debutant', 'intermediaire', 'avance', 'expert')),
  embedding vector(1536),  -- Pour recherche sémantique
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. RELATIONS ENTRE CONCEPTS (arêtes de l'ontologie)
CREATE TABLE IF NOT EXISTS ontology_relations (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  source_id BIGINT REFERENCES ontology_concepts(id) ON DELETE CASCADE,
  target_id BIGINT REFERENCES ontology_concepts(id) ON DELETE CASCADE,
  relation_type TEXT NOT NULL CHECK (relation_type IN (
    'est_un',           -- Haïku EST_UN Poème
    'influence',        -- Impressionnisme INFLUENCE Art Nouveau
    'utilise',          -- Aquarelle UTILISE Technique humide
    'requiert',         -- Portrait REQUIERT Proportions visage
    'appartient_a',     -- Jazz APPARTIENT_A Musique
    'contient',         -- Composition CONTIENT Regle des tiers
    'complimente',      -- Couleur chaude COMPLIMENTE Couleur froide
    'precede',          -- Renaissance PRECEDE Baroque
    'derive_de',        -- Cubisme DERIVE_DE Cezanne
    's_applique_a',     -- Theorie couleurs S_APPLIQUE_A Peinture
    'similaire_a',      -- Manga SIMILAIRE_A Bande dessinee
    'contredit',        -- Art academique CONTREDIT Art moderne
    'exemple'           -- La Joconde EXEMPLE Renaissance
  )),
  weight DECIMAL(3,2) DEFAULT 1.0, -- Force de la relation (0-1)
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(source_id, target_id, relation_type)
);

-- Index pour navigation dans le graphe
CREATE INDEX idx_relations_source ON ontology_relations(source_id);
CREATE INDEX idx_relations_target ON ontology_relations(target_id);
CREATE INDEX idx_relations_type ON ontology_relations(relation_type);

-- 3. TAXONOMIE DES CATÉGORIES
CREATE TABLE IF NOT EXISTS ontology_taxonomy (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id BIGINT REFERENCES ontology_taxonomy(id),
  slug TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  level INTEGER DEFAULT 0,
  path TEXT[] DEFAULT '{}', -- Chemin complet ex: {art, visuel, peinture, aquarelle}
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. PROPRIÉTÉS DES CONCEPTS (attributs)
CREATE TABLE IF NOT EXISTS ontology_properties (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  concept_id BIGINT REFERENCES ontology_concepts(id) ON DELETE CASCADE,
  property_key TEXT NOT NULL,
  property_value TEXT NOT NULL,
  unit TEXT,
  language TEXT DEFAULT 'fr',
  CONSTRAINT unique_concept_property UNIQUE (concept_id, property_key, language)
);

-- ============================================================
-- VUES DE NAVIGATION
-- ============================================================

-- Arbre complet des catégories
CREATE VIEW ontology_tree AS
WITH RECURSIVE tree AS (
  SELECT id, parent_id, slug, label, level, path, order_index
  FROM ontology_taxonomy
  WHERE parent_id IS NULL
  UNION ALL
  SELECT t.id, t.parent_id, t.slug, t.label, t.level, 
         tree.path || t.slug, t.order_index
  FROM ontology_taxonomy t
  JOIN tree ON t.parent_id = tree.id
)
SELECT * FROM tree ORDER BY path;

-- Relations enrichies avec les labels
CREATE VIEW ontology_relations_extended AS
SELECT 
  r.id,
  s.label as source_label,
  s.slug as source_slug,
  s.category as source_category,
  t.label as target_label,
  t.slug as target_slug,
  t.category as target_category,
  r.relation_type,
  r.weight,
  r.description
FROM ontology_relations r
JOIN ontology_concepts s ON r.source_id = s.id
JOIN ontology_concepts t ON r.target_id = t.id;

-- Chemins entre concepts (pour le raisonnement)
CREATE VIEW ontology_paths AS
WITH RECURSIVE paths AS (
  SELECT 
    source_id, target_id, relation_type, 
    ARRAY[source_id, target_id] AS path,
    1 AS depth
  FROM ontology_relations
  WHERE relation_type IN ('est_un', 'contient', 'derive_de')
  UNION ALL
  SELECT 
    p.source_id, r.target_id, r.relation_type,
    p.path || r.target_id,
    p.depth + 1
  FROM paths p
  JOIN ontology_relations r ON p.target_id = r.source_id
  WHERE r.relation_type IN ('est_un', 'contient', 'derive_de')
    AND NOT r.target_id = ANY(p.path)
    AND p.depth < 5
)
SELECT DISTINCT * FROM paths;

-- ============================================================
-- FONCTIONS DE RAISONNEMENT
-- ============================================================

-- Obtenir tous les parents d'un concept (remonter la hiérarchie)
CREATE OR REPLACE FUNCTION get_concept_ancestors(concept_slug TEXT)
RETURNS TABLE(slug TEXT, label TEXT, level INTEGER, path TEXT[])
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE ancestors AS (
    SELECT t.slug, t.label, t.level, t.path
    FROM ontology_taxonomy t
    WHERE t.slug = concept_slug
    UNION ALL
    SELECT pt.slug, pt.label, pt.level, pt.path
    FROM ontology_taxonomy pt
    JOIN ancestors a ON pt.slug = a.path[1]
  )
  SELECT DISTINCT * FROM ancestors;
END;
$$;

-- Recommander des concepts connexes
CREATE OR REPLACE FUNCTION recommend_related_concepts(
  concept_slug TEXT,
  max_results INTEGER DEFAULT 5
)
RETURNS TABLE(
  slug TEXT,
  label TEXT,
  category TEXT,
  relation_type TEXT,
  weight DECIMAL(3,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    c.slug, c.label, c.category,
    r.relation_type, r.weight
  FROM ontology_concepts c
  JOIN ontology_relations r ON 
    (r.source_id = c.id OR r.target_id = c.id)
  WHERE c.slug != concept_slug
    AND (r.source_id IN (SELECT id FROM ontology_concepts WHERE slug = concept_slug)
      OR r.target_id IN (SELECT id FROM ontology_concepts WHERE slug = concept_slug))
  ORDER BY r.weight DESC
  LIMIT max_results;
END;
$$;

-- ============================================================
-- SÉCURITÉ
-- ============================================================
ALTER TABLE ontology_concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ontology_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ontology_taxonomy ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ontology publicly readable"
  ON ontology_concepts FOR SELECT USING (true);
CREATE POLICY "Ontology relations publicly readable"
  ON ontology_relations FOR SELECT USING (true);
CREATE POLICY "Taxonomy publicly readable"
  ON ontology_taxonomy FOR SELECT USING (true);