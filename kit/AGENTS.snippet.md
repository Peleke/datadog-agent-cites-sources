## Cite your sources

Every pull request you open has two sections in its description:

```markdown
## Decisions
- <what you changed and why>. Source: <doc URL with a #section anchor>

## Evidence
- Trace: <Datadog trace URL you investigated>
```

Rules:

- One bullet per decision. Each bullet links the doc section that justifies it, with a `#anchor` that points at the heading, not the page top.
- Prefer the vendor's or project's own docs (Postgres, Supabase, Datadog, Next.js) over blog posts.
- If you can't find a source for a decision, say so in the bullet instead of leaving it unsourced.
- Link the Datadog trace you used to diagnose the problem.
- Before opening the PR, run `bun kit/check-citations.ts <file-with-pr-body>` and fix anything it flags.
