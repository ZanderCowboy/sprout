-- Support account deposits (unallocated) vs goal allocations.
-- Backward compatible: existing rows become kind='deposit' (assigned-to-goal deposits).

alter table public.transactions
  add column if not exists kind text not null default 'deposit';

alter table public.transactions
  alter column goal_id drop not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'transactions_kind_goal_check'
  ) then
    alter table public.transactions
      add constraint transactions_kind_goal_check
      check (
        (kind = 'allocation' and goal_id is not null)
        or
        (kind = 'deposit')
      );
  end if;
end $$;

