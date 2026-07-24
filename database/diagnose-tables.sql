-- Diagnostic des tables existantes dans Supabase
select table_name, table_type
from information_schema.tables
where table_schema = 'public'
order by table_name;
