-- Onboarding answers per account (spec FR-008).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  answers jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles: read own" on public.profiles
  for select using (id = auth.uid());
create policy "profiles: insert own" on public.profiles
  for insert with check (id = auth.uid());
create policy "profiles: update own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Phone -> Telegram chat links, written by the telegram-webhook function.
-- RLS on with no policies: only the service role (inside Edge Functions) can touch it.
create table public.telegram_links (
  phone text primary key check (phone ~ '^\+[1-9][0-9]{6,14}$'),
  chat_id bigint not null,
  telegram_user_id bigint not null,
  linked_at timestamptz not null default now()
);

alter table public.telegram_links enable row level security;
