#!/usr/bin/env sh
# Check every prerequisite for the demo. Prints one line per check, never prints secret values.
# Exit 0 when everything is present, 1 otherwise.
missing=0
ok()   { printf 'ok       %s\n' "$1"; }
miss() { printf 'MISSING  %s  ->  %s\n' "$1" "$2"; missing=1; }

for t in bun supabase vercel gh curl; do
  command -v "$t" >/dev/null 2>&1 && ok "$t installed" || miss "$t installed" "install $t"
done

supabase projects list >/dev/null 2>&1 && ok "supabase login" || miss "supabase login" "supabase login"
vercel whoami >/dev/null 2>&1          && ok "vercel login"   || miss "vercel login"   "vercel login"
gh auth status >/dev/null 2>&1         && ok "gh login"       || miss "gh login"       "gh auth login"

need_env() { eval "v=\${$1:-}"; [ -n "$v" ] && ok "\$$1 set" || miss "\$$1 set" "$2"; }
need_env SUPABASE_PROJECT_REF "create a Supabase project, then: export SUPABASE_PROJECT_REF=<ref>"
need_env DD_SITE              "export DD_SITE=datadoghq.com   (or your site, e.g. datadoghq.eu)"
need_env DD_API_KEY           "Datadog > Organization Settings > API Keys, then: export DD_API_KEY=..."
need_env DD_APP_KEY           "Datadog > Organization Settings > Application Keys, then: export DD_APP_KEY=..."

exit $missing
