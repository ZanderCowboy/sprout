-- Sprout schema: accounts, goals, transactions with RLS.
-- Enable Anonymous sign-in (Auth > Providers) if you use signInAnonymously().

create table if not exists public.accounts (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  target_amount_cents bigint not null,
  color bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid not null references public.accounts (id) on delete cascade,
  goal_id uuid not null references public.goals (id) on delete cascade,
  amount_cents bigint not null check (amount_cents > 0),
  occurred_at timestamptz not null,
  is_recurring boolean not null default false,
  frequency text not null default 'none',
  next_scheduled_date timestamptz,
  note text,
  created_at timestamptz not null default now()
);

alter table public.transactions
  add constraint transactions_frequency_check
  check (frequency in ('none', 'daily', 'weekly', 'monthly', 'yearly'));

create index if not exists accounts_user_id_idx on public.accounts (user_id);
create index if not exists goals_user_id_idx on public.goals (user_id);
create index if not exists transactions_user_id_idx on public.transactions (user_id);
create index if not exists transactions_account_id_idx on public.transactions (account_id);
create index if not exists transactions_goal_id_idx on public.transactions (goal_id);

alter table public.accounts enable row level security;
alter table public.goals enable row level security;
alter table public.transactions enable row level security;

create policy accounts_select_own on public.accounts
  for select using (auth.uid() = user_id);

create policy accounts_insert_own on public.accounts
  for insert with check (auth.uid() = user_id);

create policy accounts_update_own on public.accounts
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy accounts_delete_own on public.accounts
  for delete using (auth.uid() = user_id);

create policy goals_select_own on public.goals
  for select using (auth.uid() = user_id);

create policy goals_insert_own on public.goals
  for insert with check (auth.uid() = user_id);

create policy goals_update_own on public.goals
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy goals_delete_own on public.goals
  for delete using (auth.uid() = user_id);

create policy transactions_select_own on public.transactions
  for select using (auth.uid() = user_id);

create policy transactions_insert_own on public.transactions
  for insert with check (auth.uid() = user_id);

create policy transactions_update_own on public.transactions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy transactions_delete_own on public.transactions
  for delete using (auth.uid() = user_id);
