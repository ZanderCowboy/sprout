-- Link a deposit to its allocations (batch/group).

alter table public.transactions
  add column if not exists group_id uuid;

create index if not exists transactions_group_id_idx
  on public.transactions (group_id);

