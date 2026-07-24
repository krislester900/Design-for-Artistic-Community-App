-- Diagnostic categories
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'categories';

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'categories'
order by ordinal_position;
