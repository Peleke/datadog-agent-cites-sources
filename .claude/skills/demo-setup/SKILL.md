---
name: demo-setup
description: Set up the Datadog demo end to end — check prerequisites, seed Supabase, deploy the app to Vercel, wire the Datadog monitor, and trigger the slow endpoint. Use when the user says "set up the demo", "run the demo setup", or "reset the demo".
---

# Set up the demo

You are setting up this repo's demo for the person in front of you. Work through the steps in order. After each step, say in one line what happened. If a step fails, stop, show the exact command and its error, and say what the person needs to do. Do not work around a failure.

Hard rules:

- Never print, echo, or log a secret value (`DD_API_KEY`, `DD_APP_KEY`, Supabase keys). Pass them through env or stdin only.
- Never create accounts, projects, or GitHub repos on the person's behalf. Tell them what to create.
- Only change files inside this directory.

## 1. Prerequisites

Run `sh scripts/doctor.sh` and check its exit code:

- **1**: stop. Show the `MISSING` lines as a checklist. The person fixes them in their own shell, then restarts Claude Code from that shell so the new env vars reach you.
- **2**: only Datadog settings are missing. Say so, run steps 2, 3 and 5, and skip the Datadog parts (marked below).
- **0**: run everything.

## 2. Database

```sh
supabase link --project-ref "$SUPABASE_PROJECT_REF"
supabase db query --linked -f supabase/migrations/20261117000000_orders.sql
supabase db query --linked "select count(*) from public.orders"
```

The count should be 2000000. If `link` asks for a database password, the person can leave it blank.

## 3. App

Get the project URL and anon key without printing the key:

```sh
SUPABASE_URL="https://$SUPABASE_PROJECT_REF.supabase.co"
SUPABASE_ANON_KEY=$(supabase projects api-keys --project-ref "$SUPABASE_PROJECT_REF" -o json | bun -e 'const k=JSON.parse(await Bun.stdin.text()).find(k=>k.name==="anon");process.stdout.write(k.api_key)')
```

`vercel.json` pins the function to `pdx1` (Oregon). If the Supabase project is in another region, change it to the nearest Vercel region first (`supabase projects list` shows the region), or every query pays a cross-country round trip and the fixed endpoint never looks fast.

Then link, set env, and deploy:

```sh
vercel link --yes --project datadog-demo
printf %s "$SUPABASE_URL"      | vercel env add SUPABASE_URL production --force
printf %s "$SUPABASE_ANON_KEY" | vercel env add SUPABASE_ANON_KEY production --force
```

**Datadog part (skip if doctor exited 2).** The app sends its traces straight to Datadog's OTLP intake, so this works on Vercel Hobby with no drain. `@vercel/otel` reads these standard OTLP variables:

```sh
printf %s "https://otlp.$DD_SITE/v1/traces"                 | vercel env add OTEL_EXPORTER_OTLP_TRACES_ENDPOINT production --force
printf %s "http/protobuf"                                   | vercel env add OTEL_EXPORTER_OTLP_TRACES_PROTOCOL production --force
printf "dd-api-key=%s,compute_stats=true" "$DD_API_KEY"     | vercel env add OTEL_EXPORTER_OTLP_TRACES_HEADERS production --force
```

Then deploy:

```sh
DEPLOY_URL=$(vercel deploy --prod --yes)
vercel inspect "$DEPLOY_URL" --json | bun -e 'const j=JSON.parse(await Bun.stdin.text());process.stdout.write("https://"+j.aliases[0])' > .demo-url
for i in 1 2 3; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$(cat .demo-url)/api/orders?customer=1")
  echo "warm-up $i: HTTP $code"; [ "$code" = 200 ] && break; sleep 2
done
curl -s "$(cat .demo-url)/api/orders?customer=1" | head -c 200
```

The warm-up loop is there because the first scan after the table goes cold reads it from disk, and that can run past the `anon` role's 3 s `statement_timeout` and return HTTP 500. Each attempt pulls more of the table into Postgres's cache, and once it's warm the scan takes about 1.3 s. A 500 on the first attempt is expected. If all three attempts fail, stop and report it.

`.demo-url` holds the production alias, not the URL `vercel deploy` prints. Vercel Authentication protects each deployment's own URL, so curl and the load script get a login redirect there. Production domains are not protected. The curl should return JSON with `"customer":1`.

## 4. Datadog (skip if doctor exited 2)

Create the latency monitor. If `MONITOR_OPERATION` or `MONITOR_RESOURCE` in `demo.env` is empty, skip this and say so. Otherwise:

```sh
. ./demo.env
sed -e "s|__OPERATION__|$MONITOR_OPERATION|" -e "s|__RESOURCE__|$MONITOR_RESOURCE|" \
    -e "s|__THRESHOLD_S__|$MONITOR_THRESHOLD_S|g" kit/latency-monitor.json > .monitor.json
curl -s -X POST "https://api.$DD_SITE/api/v1/monitor" \
  -H "DD-API-KEY: $DD_API_KEY" -H "DD-APPLICATION-KEY: $DD_APP_KEY" \
  -H "Content-Type: application/json" -d @.monitor.json
```

Report the monitor id and its URL: `https://app.$DD_SITE/monitors/<id>`.

## 5. Break it

```sh
sh scripts/break.sh
bun scripts/load.ts "$(cat .demo-url)" break 300 10
```

Report p50/p90/p95 from the output. The monitor goes to Alert within about 5 minutes.

## 6. Hand over

Finish with a short table: each step, done or stopped, and the deployed URL. Then tell the person the demo is ready: they can ask you "why is /api/orders slow?"
