import { registerOTel } from "@vercel/otel";

// On Vercel, spans go to the Datadog Trace Drain set up by the Marketplace integration.
// Outbound fetches (supabase-js → PostgREST) become child spans, so the slow query shows up in the trace.
export function register() {
  registerOTel({ serviceName: "orders-api" });
}
