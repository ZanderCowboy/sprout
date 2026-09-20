-- Register path needs to know if an email already has a Supabase user
-- before sending a signup OTP. Returns a boolean only (no ids).

create or replace function public.email_has_account(p_email text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users as u
    where u.email is not null
      and lower(u.email) = lower(trim(p_email))
  );
$$;

revoke all on function public.email_has_account(text) from public;
grant execute on function public.email_has_account(text) to anon, authenticated;
