#!/usr/bin/env sh
# Reference fix, for resetting between takes. In the video the agent writes this as a migration.
set -eu
cd "$(dirname "$0")/.."
supabase db query --linked "
create index if not exists orders_customer_created_idx
  on public.orders (customer_id, created_at desc);
analyze public.orders;"
echo "fixed: orders_customer_created_idx exists"
