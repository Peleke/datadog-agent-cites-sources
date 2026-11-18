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

Run `sh scripts/doctor.sh`. If any line says `MISSING`, stop and show those lines as a checklist. The person fixes them in their own shell, then restarts Claude Code from that shell so the new env vars reach you.

## 2. Database

```sh
supabase link --project-ref "$SUPABASE_PROJECT_REF"
supabase db query --linked -f supabase/migrations/20261117000000_orders.sql
supabase db query --linked "select count(*) from public.orders"
```

The count should be 200000. If `link` asks for a database password, the person can leave it blank.

## 3. App

Get the project URL and anon key without printing the key:

```sh
SUPABASE_URL="https://$SUPABASE_PROJECT_REF.supabase.co"
SUPABASE_ANON_KEY=$(supabase projects api-keys --project-ref "$SUPABASE_PROJECT_REF" -o json | bun -e 'const k=JSON.parse(await Bun.stdin.text()).find(k=>k.name==="anon");process.stdout.write(k.api_key)')
```

Then link, set env, and deploy:

```sh
vercel link --yes --project datadog-demo
printf %s "$SUPABASE_URL"      | vercel env add SUPABASE_URL production --force
printf %s "$SUPABASE_ANON_KEY" | vercel env add SUPABASE_ANON_KEY production --force
vercel deploy --prod --yes > .demo-url
curl -s "$(cat .demo-url)/api/orders?customer=1" | head -c 200
```

The curl should return JSON with `"customer":1`.

## 4. Datadog

1. Ask the person to confirm the Datadog integration is installed from the Vercel Marketplace with **Trace Drain on at 100% sampling** and Log Drain on. Wait for their yes.
2. Create the latency monitor. If `MONITOR_OPERATION` or `MONITOR_RESOURCE` in `demo.env` is empty, skip this and say so. Otherwise:

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
