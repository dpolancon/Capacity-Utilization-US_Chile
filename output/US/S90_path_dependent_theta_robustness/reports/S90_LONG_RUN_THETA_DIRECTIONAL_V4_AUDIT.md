---
type: stage_report
status: active
depends_on: [chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]
stage_scope: S90
country: US
last_updated: 2026-07-20
---

# Long-Run Theta Directional Beamer v4 Audit

All 13 source-anchored claims passed.
All 10 deterministic directional identities passed at tolerance 1e-12.

This audit validates the two-capital directional algebra and source anchors only.
It does not estimate a historical regime interval. The existing roughness bootstrap is not
relabelled as regime inference.

Source commit: `d726353c96eecdb0c92470d54b1a88d97f8e83a8`.
