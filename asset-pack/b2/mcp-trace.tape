# b2: Claude Code asks Datadog's MCP why /api/orders is slow.
# Run from demos/datadog:  vhs asset-pack/b2/mcp-trace.tape
# Needs: claude on PATH, the datadog MCP already authorized in this directory (.mcp.json),
# .demo-url present, the seeded fault in place (sh scripts/break.sh).
# No secrets are typed: MCP auth comes from Claude Code's stored OAuth grant.
# DRY-RUN TODO: tune the Sleep after launch and confirm --allowedTools "mcp__datadog" skips permission prompts.

Source tapes/_preamble.tape
Require claude
Require bun
Output asset-pack/b2/mcp-trace.mp4

# Off camera: fresh slow traffic so the trace is recent.
Hide
Type "bun scripts/load.ts $(cat .demo-url) break 60 6"
Enter
Wait+Screen@180s /p95_ms: [0-9]+/
Type "clear"
Enter
Show

Type `claude --allowedTools "mcp__datadog"`
Enter
Sleep 5s

Type "Why is /api/orders slow? Use the Datadog MCP to find the trace."
Sleep 500ms
Enter

# Fails the render if the agent never surfaces the database span.
Wait+Screen@240s /rest\/v1\/orders|fetch\.GET/
Sleep 15s
Screenshot asset-pack/b2/mcp-trace-end.png
Ctrl+C
Ctrl+C
