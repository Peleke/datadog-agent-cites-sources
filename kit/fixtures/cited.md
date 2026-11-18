Speeds up `GET /api/orders` by indexing the columns it filters and sorts on.

## Decisions
- Add a composite index on `(customer_id, created_at desc)`: the query filters on equality first, then sorts. Source: https://www.postgresql.org/docs/current/indexes-multicolumn.html#INDEXES-MULTICOLUMN
- Put `created_at desc` in the index so Postgres can read rows already in the order the query asks for. Source: https://www.postgresql.org/docs/current/indexes-ordering.html#INDEXES-ORDERING

## Evidence
- Trace: https://app.datadoghq.com/apm/trace/0000000000000000000
