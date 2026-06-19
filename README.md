# MONOPOLY CENTRAL BANK PRO

A mobile-first Monopoly banking site for Vercel + Supabase.

## Features
- Banker-only vault with full player balances.
- Player private balance screen.
- Players can pay other players or the bank.
- Everyone can see all transaction activity, but not other players' balances.
- My Transactions filter.
- Player self-join using game code, name, PIN, character, and colour.
- Returning player login.
- 10 player colours and 10 character tokens.
- No credit/negative balances.
- If a player tries to send more than they have, the app shows an error.
- If a player reaches $0, the app shows BANKRUPT.

## Setup
1. Create a new Supabase project.
2. Open SQL Editor.
3. Paste and run `supabase_schema.sql`.
4. Create a new GitHub repository.
5. Upload all files from this folder.
6. In Vercel, click Add New Project and import that new GitHub repo.
7. Deploy.
8. Open the site, paste Supabase URL and anon key once on each device.

## Important privacy note
The app UI hides player balances from other players. The banker screen is the only screen that shows all balances. For casual game-night use this is enough. Do not use this app for real money.
