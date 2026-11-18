#!/usr/bin/env sh
# Claude Code runs this to get OTLP headers, so the Datadog API key stays in your shell, never in a file.
# compute_stats=true turns on Datadog trace metrics for spans sent straight to the OTLP intake.
if [ -z "${DD_API_KEY:-}" ]; then
  echo "DD_API_KEY is not set in the shell that launched Claude Code" >&2
  exit 1
fi
printf '{"dd-api-key":"%s","compute_stats":"true"}\n' "$DD_API_KEY"
