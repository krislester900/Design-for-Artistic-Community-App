-- ============================================================
-- Diagnostic de la table categories
-- A exécuter AVANT la migration
-- ============================================================

-- Voir toutes les tables existantes
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'categories';

-- Voir les colonnes de categories
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'categories'
order by ordinal_position;

-- Voir les contraintes de categories
select constraint_name, constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'categories';
