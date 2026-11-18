Speeds up `GET /api/orders`.

## Decisions
- Add a composite index on `(customer_id, created_at desc)` because it's faster.
- Put `created_at desc` in the index. Source: https://www.postgresql.org/docs/current/indexes-ordering.html

## Evidence
- Looked at the slow trace.
