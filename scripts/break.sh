#!/usr/bin/env sh
# Restore the fault: drop every index on public.orders except the primary key.
set -eu
cd "$(dirname "$0")/.."
supabase db query --linked "
do \$\$
declare r record;
begin
  for r in
    select indexname from pg_indexes
    where schemaname = 'public' and tablename = 'orders' and indexname <> 'orders_pkey'
  loop
    execute format('drop index if exists public.%I', r.indexname);
  end loop;
end \$\$;
analyze public.orders;"
echo "broken: public.orders has no secondary index"
