import { registerOTel } from "@vercel/otel";

// Spans go to Datadog's OTLP intake via the standard OTEL_EXPORTER_OTLP_TRACES_* env vars (set by the setup skill),
// so no Vercel drain or Pro plan is needed. Outbound fetches (supabase-js → PostgREST) become child spans, so the slow query shows up in the trace.
export function register() {
  registerOTel({ serviceName: "orders-api" });
}
