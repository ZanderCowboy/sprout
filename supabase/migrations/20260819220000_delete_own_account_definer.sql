-- public.delete_own_account was SECURITY INVOKER, so authenticated needed
-- USAGE on schema private to call private.delete_own_account — that raised
-- 42501 permission denied for schema private.
-- Keep private schema closed; let the public wrapper run as DEFINER.

create or replace function public.delete_own_account()
returns void
language sql
security definer
set search_path = ''
as $$
  select private.delete_own_account();
$$;

revoke all on function private.delete_own_account() from public, anon, authenticated;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
