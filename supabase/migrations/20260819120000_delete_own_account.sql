-- In-app account deletion (Play requirement).
-- Cloud rows cascade via existing FKs on auth.users(id) on delete cascade.
-- SECURITY DEFINER stays in private; public wrapper is invoker for supabase.rpc.

create schema if not exists private;

create or replace function private.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function private.delete_own_account() from public, anon;
grant execute on function private.delete_own_account() to authenticated;

create or replace function public.delete_own_account()
returns void
language sql
security invoker
set search_path = ''
as $$
  select private.delete_own_account();
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
