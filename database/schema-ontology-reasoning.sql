-- ============================================================
-- FONCTIONS DE RAISONNEMENT CRÉATIF
-- Permet à l'IA de synthétiser de nouveaux styles et techniques
-- à partir de combinaisons de concepts existants
-- ============================================================

-- ============================================================
-- 1. SYNTHÈSE DE STYLE : combine N concepts pour créer
--    une nouvelle approche artistique
-- ============================================================
CREATE OR REPLACE FUNCTION synthesize_style(
  seed_concepts TEXT[],       -- ex: '{hachure, aquarelle, manga}'
  max_depth INT DEFAULT 3,
  max_results INT DEFAULT 10
)
RETURNS TABLE(
  concept_slug TEXT,
  concept_label TEXT,
  concept_category TEXT,
  path TEXT[],               -- chemin de relations suivi
  relation_chain TEXT,       -- description lisible de la chaîne
  composite_weight DECIMAL(3,2),
  synthesis_prompt TEXT      -- prompt prêt pour génération SDXL
)
LANGUAGE plpgsql
AS $$
DECLARE
  concept_ids BIGINT[];
  c RECORD;
BEGIN
  -- Résoudre les slugs en IDs
  SELECT ARRAY_AGG(id) INTO concept_ids
  FROM ontology_concepts
  WHERE slug = ANY(seed_concepts);

  -- Retourner les concepts racines + leurs connexions
  RETURN QUERY
  WITH RECURSIVE creative_paths AS (
    -- Point de départ : les concepts semences
    SELECT 
      c.id AS source_id,
      c.id AS target_id,
      c.slug AS source_slug,
      c.slug AS target_slug,
      c.label AS target_label,
      c.category AS target_category,
      ARRAY[c.slug] AS path,
      ''::TEXT AS relation_chain,
      1.0::DECIMAL(3,2) AS weight,
      0 AS depth
    FROM ontology_concepts c
    WHERE c.id = ANY(concept_ids)

    UNION ALL

    -- Explorer les relations
    SELECT 
      cp.source_id,
      r.target_id,
      cp.source_slug,
      c2.slug,
      c2.label,
      c2.category,
      cp.path || c2.slug,
      cp.relation_chain || ' → ' || r.relation_type || '→ ' || c2.label,
      cp.weight * r.weight,
      cp.depth + 1
    FROM creative_paths cp
    JOIN ontology_relations r ON r.source_id = cp.target_id
    JOIN ontology_concepts c2 ON c2.id = r.target_id
    WHERE cp.depth < max_depth
      AND NOT c2.id = ANY(concept_ids)
      AND NOT c2.slug = ANY(cp.path)
  )
  SELECT DISTINCT
    cp.target_slug,
    cp.target_label,
    cp.target_category,
    cp.path,
    cp.relation_chain,
    cp.weight AS composite_weight,
    -- Générer un prompt de synthèse lisible
    CASE cp.target_category
      WHEN 'technique' THEN
        'Fusion créative : combine ' || cp.source_slug || ' avec ' || cp.target_slug
        || '. Utilise les principes de ' || cp.target_label
        || ' appliqués à ' || cp.source_slug || '. '
        || 'Explore la tension entre ces approches pour créer une nouvelle expression.'
      WHEN 'style' THEN
        'Nouveau style hybride : ' || cp.source_slug || '-' || cp.target_slug
        || '. Mélange les codes esthétiques de ' || cp.target_label
        || ' avec les fondations de ' || cp.source_slug || '. '
        || 'Cherche les points de convergence et les contrastes intéressants.'
      WHEN 'medium' THEN
        'Adaptation cross-medium : ' || cp.source_slug || ' via ' || cp.target_slug
        || '. Transpose les principes de ' || cp.source_slug
        || ' en utilisant les propriétés uniques du ' || cp.target_label || '.'
      ELSE
        'Synthèse créative : ' || cp.source_slug || ' x ' || cp.target_slug
        || '. Explore les interactions entre ' || cp.source_slug
        || ' et ' || cp.target_label || '.'
    END AS synthesis_prompt
  FROM creative_paths cp
  WHERE cp.depth > 0  -- exclure les points de départ
  ORDER BY cp.weight DESC, cp.depth ASC
  LIMIT max_results;
END;
$$;

-- ============================================================
-- 2. FUSION DE DEUX CONCEPTS : trouve le chemin le plus
--    court et propose une synthèse
-- ============================================================
CREATE OR REPLACE FUNCTION blend_styles(
  concept_a TEXT,
  concept_b TEXT
)
RETURNS TABLE(
  a_label TEXT,
  b_label TEXT,
  a_category TEXT,
  b_category TEXT,
  connection_path TEXT[],    -- chemin de concepts intermédiaires
  relation_types TEXT[],     -- types de relations empruntées
  blend_description TEXT,    -- description de la fusion
  difficulty TEXT            -- difficulté estimée
)
LANGUAGE plpgsql
AS $$
DECLARE
  a_id BIGINT;
  b_id BIGINT;
  a_cat TEXT;
  b_cat TEXT;
BEGIN
  SELECT id, category INTO a_id, a_cat FROM ontology_concepts WHERE slug = concept_a;
  SELECT id, category INTO b_id, b_cat FROM ontology_concepts WHERE slug = concept_b;

  IF a_id IS NULL OR b_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH RECURSIVE fusion_paths AS (
    -- Départ de A, exploration des relations
    SELECT 
      r.target_id AS current_id,
      ARRAY[r.source_id, r.target_id] AS path_ids,
      ARRAY[r.relation_type] AS relations,
      1 AS depth
    FROM ontology_relations r
    WHERE r.source_id = a_id

    UNION ALL

    SELECT 
      r.target_id,
      fp.path_ids || r.target_id,
      fp.relations || r.relation_type,
      fp.depth + 1
    FROM fusion_paths fp
    JOIN ontology_relations r ON r.source_id = fp.current_id
    WHERE fp.depth < 5
      AND NOT r.target_id = ANY(fp.path_ids)
  )
  SELECT DISTINCT
    ca.label AS a_label,
    cb.label AS b_label,
    ca.category AS a_category,
    cb.category AS b_category,
    ARRAY(
      SELECT c2.slug FROM ontology_concepts c2 
      WHERE c2.id = ANY(fp.path_ids) 
      ORDER BY array_position(fp.path_ids, c2.id)
    ) AS connection_path,
    fp.relations AS relation_types,
    CASE
      WHEN a_cat = b_cat THEN
        'Fusion de ' || a_cat || 's : ' || ca.label || ' × ' || cb.label || '. '
        || 'Explore comment ' || ca.label || ' peut être réinterprété à travers le prisme de ' || cb.label
        || '. Les deux appartenant à la même catégorie, la fusion peut créer un sous-genre ou une hybridation inédite.'
      WHEN a_cat IN ('technique', 'medium', 'outil') AND b_cat IN ('style', 'genre', 'mouvement') THEN
        'Application stylistique : ' || ca.label || ' appliqué au style ' || cb.label || '. '
        || 'Maîtrise la technique de ' || ca.label || ' dans le contexte du style ' || cb.label
        || '. Joue avec les codes du style pour créer une variation technique originale.'
      WHEN a_cat IN ('style', 'genre', 'mouvement') AND b_cat IN ('technique', 'medium', 'outil') THEN
        'Réinterprétation technique : le style ' || ca.label || ' revisité par ' || cb.label || '. '
        || 'Utilise ' || cb.label || ' comme contrainte créative pour renouveler les codes esthétiques de ' || ca.label
        || '. Le résultat peut être une réinvention complète du style original.'
      WHEN a_cat = 'theorie' OR b_cat = 'theorie' THEN
        'Approche théorique appliquée : ' || ca.label || ' rencontré ' || cb.label || '. '
        || 'Applique les principes théoriques de ' || ca.label || ' à la pratique de ' || cb.label
        || '. La théorie devient un moteur de création plutôt qu'une contrainte.'
      ELSE
        'Hybridation transdisciplinaire : ' || ca.label || ' × ' || cb.label || '. '
        || 'Transpose les concepts de ' || ca.label || ' (' || a_cat || ') dans le domaine de ' || cb.label || ' (' || b_cat || '). '
        || 'Les croisements entre catégories différentes produisent souvent les innovations les plus surprenantes.'
    END AS blend_description,
    CASE
      WHEN fp.depth <= 2 THEN 'debutant'
      WHEN fp.depth <= 4 THEN 'intermediaire'
      ELSE 'avance'
    END AS difficulty
  FROM fusion_paths fp
  JOIN ontology_concepts ca ON ca.id = a_id
  JOIN ontology_concepts cb ON cb.id = b_id
  WHERE fp.current_id = b_id
  ORDER BY fp.depth ASC
  LIMIT 3;
END;
$$;

-- ============================================================
-- 3. DÉCOUVERTE DE COMBINAISONS CRÉATIVES
--    Suggère des paires de concepts inattendues
-- ============================================================
CREATE OR REPLACE FUNCTION discover_creative_pairs(
  category_filter TEXT DEFAULT NULL,  -- filtrer par catégorie
  max_pairs INT DEFAULT 8
)
RETURNS TABLE(
  concept_a_slug TEXT,
  concept_a_label TEXT,
  concept_a_category TEXT,
  concept_b_slug TEXT,
  concept_b_label TEXT,
  concept_b_category TEXT,
  surprise_score DECIMAL(3,2),  -- 0=attendue, 1=surprenante
  creative_hook TEXT             -- accroche pour l'inspiration
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH ranked_pairs AS (
    SELECT
      a.slug AS a_slug, a.label AS a_label, a.category AS a_cat,
      b.slug AS b_slug, b.label AS b_label, b.category AS b_cat,
      -- Score de surprise basé sur la distance catégorielle
      CASE 
        WHEN a.category = b.category THEN 0.3  -- même catégorie = moins surprenant
        WHEN a.category IN ('technique','medium','outil') 
         AND b.category IN ('theorie','genre') THEN 0.7  -- croisement pratique-théorie
        WHEN a.category IN ('style','mouvement','genre')
         AND b.category IN ('technique','outil') THEN 0.8  -- application technique
        ELSE 0.5
      END +
      -- Bonus si pas de relation directe (combinaison inédite)
      CASE WHEN NOT EXISTS (
        SELECT 1 FROM ontology_relations r 
        WHERE (r.source_id = a.id AND r.target_id = b.id)
           OR (r.source_id = b.id AND r.target_id = a.id)
      ) THEN 0.3 ELSE 0 END AS surprise,
      -- Générer un hook créatif
      CASE 
        WHEN a.category = b.category THEN
          'Et si ' || a.label || ' rencontrait ' || b.label || ' ? Deux visions d''une même catégorie qui pourraient fusionner.'
        WHEN a.category IN ('technique','medium','outil') 
         AND b.category IN ('style','mouvement','genre') THEN
          'Appliquer la technique "' || a.label || '" au style "' || b.label || '" pourrait donner naissance à une interprétation totalement nouvelle.'
        WHEN a.category = 'theorie' AND b.category IN ('technique','medium') THEN
          'La théorie "' || a.label || '" comme contrainte créative pour "' || b.label || '" : ça donne quoi ?'
        ELSE
          'Croiser "' || a.label || '" (' || a.category || ') avec "' || b.label || '" (' || b.category || ') peut créer quelque chose d''inattendu.'
      END AS hook
    FROM ontology_concepts a
    CROSS JOIN ontology_concepts b
    WHERE a.id < b.id
      AND (category_filter IS NULL OR a.category = category_filter OR b.category = category_filter)
  )
  SELECT 
    rp.a_slug, rp.a_label, rp.a_cat,
    rp.b_slug, rp.b_label, rp.b_cat,
    LEAST(rp.surprise, 1.0)::DECIMAL(3,2) AS surprise_score,
    rp.hook
  FROM ranked_pairs rp
  ORDER BY rp.surprise DESC
  LIMIT max_pairs;
END;
$$;
