// Fire N requests at /api/orders and append client-side p50/p90/p95 to data/latency.csv.
// Usage: bun scripts/load.ts <base-url> <label> [n=300] [concurrency=10]
import { appendFileSync, existsSync, mkdirSync } from "node:fs";

const [base, label, nArg = "300", cArg = "10"] = process.argv.slice(2);
if (!base || !label) {
  console.error("usage: bun scripts/load.ts <base-url> <label> [n] [concurrency]");
  process.exit(2);
}
const n = Number(nArg);
const concurrency = Number(cArg);
const url = new URL("/api/orders", base).toString();

const times: number[] = [];
let errors = 0;
let next = 0;

async function worker() {
  while (next < n) {
    next++;
    const t0 = performance.now();
    try {
      const res = await fetch(url);
      await res.arrayBuffer();
      if (!res.ok) errors++;
    } catch {
      errors++;
    }
    times.push(performance.now() - t0);
  }
}
await Promise.all(Array.from({ length: concurrency }, worker));

times.sort((a, b) => a - b);
const pct = (p: number) => Math.round(times[Math.min(times.length - 1, Math.floor((p / 100) * times.length))]);
const row = { ts: new Date().toISOString(), label, n, errors, p50_ms: pct(50), p90_ms: pct(90), p95_ms: pct(95) };

const file = "data/latency.csv";
mkdirSync("data", { recursive: true });
if (!existsSync(file)) appendFileSync(file, Object.keys(row).join(",") + "\n");
appendFileSync(file, Object.values(row).join(",") + "\n");
console.log(row);
if (errors > 0) process.exit(1);
