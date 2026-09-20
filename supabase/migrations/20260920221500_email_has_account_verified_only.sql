-- Create-account / sign-in gates must ignore unverified signup rows.
-- The first register OTP inserts auth.users with email_confirmed_at null;
-- counting that as an account blocked resend and "try again".

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
      and u.email_confirmed_at is not null
  );
$$;

revoke all on function public.email_has_account(text) from public;
grant execute on function public.email_has_account(text) to anon, authenticated;
