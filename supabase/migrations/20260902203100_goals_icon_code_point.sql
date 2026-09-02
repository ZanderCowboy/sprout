-- Optional Material icon code point on goals (null = app default).
alter table public.goals
  add column if not exists icon_code_point bigint;
