# Datadog: your coding agent, observable and sourced

Your coding agent's sessions show up as traces in Datadog APM, and every decision in its pull requests links the doc section that justifies it.

## What you get

When a coding agent changes your code, you usually get a diff and take its reasoning on trust. With this kit you can see what the agent did, next to the service it changed, and check each decision in one click instead of rereading the code.

## Use it in your project

1. Copy `.claude/settings.json` and `.claude/otel-headers.sh` into your repo's `.claude/`. If your Datadog site isn't `datadoghq.com`, change the three `otlp.datadoghq.com` endpoints to `otlp.<your-site>`.
2. In the shell you start Claude Code from: `export DD_API_KEY=<your key>`. The key is read by `otel-headers.sh` and never written to a file.
3. Copy `.mcp.json` (Datadog MCP with the `core` and `apm` toolsets) and approve it on first start, or use the plugin: `/plugin install datadog@claude-plugins-official`, then `/ddsetup`.
4. Paste `kit/AGENTS.snippet.md` into your `CLAUDE.md` or `AGENTS.md`.
5. Add `bun kit/check-citations.ts <pr-body-file>` to CI.

Run one prompt, then search Datadog APM for `service:claude-code`.

## Reproduce the demo

You need accounts on Datadog, Vercel (Hobby is enough: the app sends traces straight to Datadog's OTLP intake) and Supabase, plus the `bun`, `supabase`, `vercel` and `gh` CLIs.

```sh
git clone https://github.com/Peleke/datadog-agent-cites-sources && cd datadog-agent-cites-sources
bun install
export SUPABASE_PROJECT_REF=... DD_SITE=datadoghq.com DD_API_KEY=... DD_APP_KEY=...
claude
```

Then tell Claude Code: **set up the demo**. The `demo-setup` skill (`.claude/skills/demo-setup/SKILL.md`) checks prerequisites, seeds 2,000,000 orders with no index, deploys the app, creates the latency monitor and makes `/api/orders` slow. Each step is a plain shell command in that file if you'd rather run it by hand.

Then ask: **why is /api/orders slow?**

`scripts/break.sh` and `scripts/fix.sh` reset the fault between runs. `bun scripts/load.ts <url> <label>` records latency to `data/latency.csv`; `uv run plot.py` charts it.

## Disclosure

AI-assisted: code generated with Claude Code and reviewed by the author. Claude Code tracing is a beta feature, and Datadog's Agent Console is in Preview.
