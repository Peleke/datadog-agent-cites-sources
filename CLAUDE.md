This is the demo app for the Datadog quickstart. `GET /api/orders` reads `public.orders` in Supabase.

@kit/AGENTS.snippet.md

Schema changes go in a new file under `supabase/migrations/` and are applied with `supabase db query --linked -f <file>`.
