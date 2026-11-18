// Fail a PR description whose decisions don't cite a resolving doc section.
// Usage: bun kit/check-citations.ts <file>   or   gh pr view N --json body -q .body | bun kit/check-citations.ts -
// Exit 0: every bullet under "## Decisions" has a URL with a #anchor that returns HTTP 200,
//         and "## Evidence" has a Datadog trace link (presence only; it needs a login to open).
// Exit 1: anything missing. Anchors not found in the page HTML are warnings (some docs render headings client-side).

const arg = process.argv[2];
if (!arg) {
  console.error("usage: bun kit/check-citations.ts <file|->");
  process.exit(2);
}
const body = arg === "-" ? await Bun.stdin.text() : await Bun.file(arg).text();

function section(name: string): string {
  const m = body.match(new RegExp(`^##\\s+${name}\\s*$([\\s\\S]*?)(?=^##\\s|(?![\\s\\S]))`, "mi"));
  return m ? m[1] : "";
}
const URL_RE = /https?:\/\/[^\s)>\]]+/g;

const problems: string[] = [];
const warnings: string[] = [];

const decisions = section("Decisions")
  .split("\n")
  .filter((l) => /^\s*[-*]\s+/.test(l));
if (decisions.length === 0) problems.push('no bullets under "## Decisions"');

const toFetch = new Map<string, string>(); // url -> decision text
for (const d of decisions) {
  const anchored = (d.match(URL_RE) ?? []).filter((u) => new URL(u).hash.length > 1);
  if (anchored.length === 0) problems.push(`no #anchored source: ${d.trim()}`);
  for (const u of anchored) toFetch.set(u, d.trim());
}

const traces = (section("Evidence").match(URL_RE) ?? []).filter((u) => /datadoghq\.(com|eu)\/apm\/trace\//.test(u));
if (traces.length === 0) problems.push('no Datadog trace link under "## Evidence"');

await Promise.all(
  [...toFetch.keys()].map(async (u) => {
    try {
      const res = await fetch(u, { redirect: "follow", headers: { "user-agent": "check-citations" } });
      const html = await res.text();
      const frag = decodeURIComponent(new URL(u).hash.slice(1));
      if (res.status !== 200) problems.push(`HTTP ${res.status}: ${u}`);
      else if (!new RegExp(`(id|name)=["']${frag.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}["']`, "i").test(html))
        warnings.push(`anchor #${frag} not in page HTML (may render client-side): ${u}`);
      console.log(`${res.status} ${u}`);
    } catch (e) {
      problems.push(`fetch failed: ${u} (${(e as Error).message})`);
    }
  }),
);

for (const w of warnings) console.log(`warn  ${w}`);
for (const p of problems) console.log(`FAIL  ${p}`);
console.log(problems.length ? `\n${problems.length} problem(s)` : `\nok: ${decisions.length} decision(s), all cited`);
process.exit(problems.length ? 1 : 0);
