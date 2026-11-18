#!/usr/bin/env sh
# Check every prerequisite for the demo. Prints one line per check, never prints secret values.
# Exit 0: everything present. Exit 2: only Datadog settings missing (database and app steps can run).
# Exit 1: something the database or app steps need is missing.
core=0
dd=0
ok()   { printf 'ok       %s\n' "$1"; }
miss() { printf 'MISSING  %s  ->  %s\n' "$1" "$2"; }

for t in bun supabase vercel gh curl; do
  command -v "$t" >/dev/null 2>&1 && ok "$t installed" || { miss "$t installed" "install $t"; core=1; }
done

supabase projects list >/dev/null 2>&1 && ok "supabase login" || { miss "supabase login" "supabase login"; core=1; }
vercel whoami >/dev/null 2>&1          && ok "vercel login"   || { miss "vercel login"   "vercel login"; core=1; }
gh auth status >/dev/null 2>&1         && ok "gh login"       || { miss "gh login"       "gh auth login"; core=1; }

has() { eval "v=\${$1:-}"; [ -n "$v" ]; }
has SUPABASE_PROJECT_REF && ok "\$SUPABASE_PROJECT_REF set" \
  || { miss "\$SUPABASE_PROJECT_REF set" "create a Supabase project, then: export SUPABASE_PROJECT_REF=<ref>"; core=1; }

has DD_SITE    && ok "\$DD_SITE set"    || { miss "\$DD_SITE set"    "export DD_SITE=datadoghq.com   (or your site, e.g. datadoghq.eu)"; dd=1; }
has DD_API_KEY && ok "\$DD_API_KEY set" || { miss "\$DD_API_KEY set" "Datadog > Organization Settings > API Keys, then: export DD_API_KEY=..."; dd=1; }
has DD_APP_KEY && ok "\$DD_APP_KEY set" || { miss "\$DD_APP_KEY set" "Datadog > Organization Settings > Application Keys, then: export DD_APP_KEY=..."; dd=1; }

[ $core -eq 1 ] && exit 1
[ $dd -eq 1 ] && exit 2
exit 0
