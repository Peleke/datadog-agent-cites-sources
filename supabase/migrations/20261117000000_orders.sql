-- Orders table with the seeded fault: no index on (customer_id, created_at).
-- /api/orders filters on customer_id and sorts on created_at, so every request scans the table.

create table if not exists public.orders (
  id          bigint generated always as identity primary key,
  customer_id int         not null,
  total_cents int         not null,
  status      text        not null,
  created_at  timestamptz not null
);

-- Row count is the latency dial. Raise it if the slow p90 is too close to network noise.
-- Seeds only an empty table, so re-running this file is safe.
insert into public.orders (customer_id, total_cents, status, created_at)
select
  1 + (random() * 1999)::int,
  (random() * 50000)::int,
  (array['pending', 'paid', 'shipped', 'refunded'])[1 + (random() * 3)::int],
  now() - (random() * interval '365 days')
from generate_series(1, 2000000)
where not exists (select 1 from public.orders);

analyze public.orders;

-- Read-only access for the demo API (anon key).
alter table public.orders enable row level security;
drop policy if exists "demo read" on public.orders;
create policy "demo read" on public.orders for select to anon using (true);
