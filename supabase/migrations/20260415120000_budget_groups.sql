-- Master Budget Planner: budget_groups (static monthly template)

create table if not exists public.budget_groups (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  description text,
  category text not null check (category in ('income', 'essentials', 'lifestyle')),
  color_hex text not null,
  icon_code_point integer,
  icon_font_family text,
  items_json jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists budget_groups_user_id_idx
  on public.budget_groups (user_id);

alter table public.budget_groups enable row level security;

drop policy if exists budget_groups_select_own on public.budget_groups;
create policy budget_groups_select_own on public.budget_groups
  for select using (auth.uid() = user_id);

drop policy if exists budget_groups_insert_own on public.budget_groups;
create policy budget_groups_insert_own on public.budget_groups
  for insert with check (auth.uid() = user_id);

drop policy if exists budget_groups_update_own on public.budget_groups;
create policy budget_groups_update_own on public.budget_groups
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists budget_groups_delete_own on public.budget_groups;
create policy budget_groups_delete_own on public.budget_groups
  for delete using (auth.uid() = user_id);