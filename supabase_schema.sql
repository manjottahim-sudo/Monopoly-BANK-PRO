-- MONOPOLY CENTRAL BANK PRO database setup
-- Run this once in Supabase SQL Editor for the NEW separate project.

create table if not exists public.games (
  code text primary key,
  banker_pin_hash text not null,
  starting_money integer not null default 1500,
  created_at timestamptz default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  game_code text not null references public.games(code) on delete cascade,
  name text not null,
  pin_hash text not null,
  balance integer not null default 1500 check (balance >= 0),
  character text default 'Top Hat',
  color text default '#1769ff',
  created_at timestamptz default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  game_code text not null references public.games(code) on delete cascade,
  from_player_id text not null,
  to_player_id text not null,
  amount integer not null check (amount > 0),
  note text,
  created_at timestamptz default now()
);

alter table public.games enable row level security;
alter table public.players enable row level security;
alter table public.transactions enable row level security;

do $$ begin create policy "games read" on public.games for select using (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "games insert" on public.games for insert with check (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "players read" on public.players for select using (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "players insert" on public.players for insert with check (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "players update" on public.players for update using (true) with check (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "transactions read" on public.transactions for select using (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "transactions insert" on public.transactions for insert with check (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "transactions delete" on public.transactions for delete using (true); exception when duplicate_object then null; end $$;

create or replace function public.perform_monopoly_transaction(
  p_game_code text,
  p_from text,
  p_to text,
  p_amount integer,
  p_note text default ''
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  from_balance integer;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'INVALID_AMOUNT';
  end if;

  if p_from = p_to then
    raise exception 'SAME_SENDER_RECEIVER';
  end if;

  -- If a player is paying, lock their row and confirm enough money exists.
  if p_from <> 'BANK' then
    select balance into from_balance
    from public.players
    where id::text = p_from and game_code = p_game_code
    for update;

    if from_balance is null then
      raise exception 'SENDER_NOT_FOUND';
    end if;

    if from_balance < p_amount then
      raise exception 'INSUFFICIENT_FUNDS';
    end if;

    update public.players
    set balance = balance - p_amount
    where id::text = p_from and game_code = p_game_code;
  end if;

  -- If a player is receiving, add money to their balance.
  if p_to <> 'BANK' then
    update public.players
    set balance = balance + p_amount
    where id::text = p_to and game_code = p_game_code;

    if not found then
      raise exception 'RECEIVER_NOT_FOUND';
    end if;
  end if;

  insert into public.transactions(game_code, from_player_id, to_player_id, amount, note)
  values (p_game_code, p_from, p_to, p_amount, p_note);
end;
$$;

grant execute on function public.perform_monopoly_transaction(text,text,text,integer,text) to anon, authenticated;

do $$ begin alter publication supabase_realtime add table public.players; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.transactions; exception when duplicate_object then null; end $$;
