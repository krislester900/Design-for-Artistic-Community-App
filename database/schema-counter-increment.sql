-- Incrément atomique des compteurs de ai_manga_styles (évite les race conditions
-- read-modify-write depuis les Edge Functions). À appliquer une fois sur Supabase
-- (Table Editor > SQL Editor, ou `supabase db push`).
-- Sécurité : SECURITY DEFINER + whitelist des champs autorisés.

create or replace function public.increment_style_counter(
  p_style_id bigint,
  p_field text,
  p_delta int default 1
) returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  new_val int;
begin
  if p_field not in ('generation_count', 'reference_count') then
    raise exception 'champ non autorisé : %', p_field;
  end if;

  if p_field = 'generation_count' then
    update public.ai_manga_styles
       set generation_count = coalesce(generation_count, 0) + p_delta
     where id = p_style_id
     returning generation_count into new_val;
  else
    update public.ai_manga_styles
       set reference_count = coalesce(reference_count, 0) + p_delta
     where id = p_style_id
     returning reference_count into new_val;
  end if;

  return new_val;
end;
$$;

grant execute on function public.increment_style_counter(bigint, text, int) to service_role;
