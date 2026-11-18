# /// script
# requires-python = ">=3.12"
# dependencies = ["pandas", "seaborn", "matplotlib"]
# ///
"""Before/after latency chart from data/latency.csv (last 'break' row vs last 'fix' row).

Usage: uv run plot.py   ->  asset-pack/b4/latency.png, asset-pack/b4/latency.json
"""
import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

df = pd.read_csv("data/latency.csv")
before = df[df.label == "break"].iloc[-1]
after = df[df.label == "fix"].iloc[-1]

out = Path("asset-pack/b4")
out.mkdir(parents=True, exist_ok=True)
pcts = ["p50", "p90", "p95"]
summary = {
    "before": {p: int(before[f"{p}_ms"]) for p in pcts},
    "after": {p: int(after[f"{p}_ms"]) for p in pcts},
    "unit": "ms",
    "n_requests": {"before": int(before.n), "after": int(after.n)},
    "source": "data/latency.csv",
}
(out / "latency.json").write_text(json.dumps(summary, indent=2) + "\n")

long = pd.DataFrame(
    [{"percentile": p, "run": run, "ms": summary[key][p]} for p in pcts for run, key in [("no index", "before"), ("with index", "after")]]
)
sns.set_theme(style="whitegrid", context="talk")
fig, ax = plt.subplots(figsize=(19.2, 10.8), dpi=100)
sns.barplot(data=long, x="percentile", y="ms", hue="run", ax=ax)
for c in ax.containers:
    ax.bar_label(c, fmt="%d ms")
ax.set(xlabel="", ylabel="latency (ms, client-side)", title="GET /api/orders latency")
ax.legend(title="")
fig.tight_layout()
fig.savefig(out / "latency.png")
print(json.dumps(summary))
