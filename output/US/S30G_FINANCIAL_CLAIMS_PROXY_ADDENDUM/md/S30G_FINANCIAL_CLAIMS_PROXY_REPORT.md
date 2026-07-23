---
type: stage_report
status: active
depends_on: [chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]
stage_scope: all_stages
country: US
last_updated: 2026-06-24
---

# S30G Financial-Claims Proxy Report

S30G creates 6 bounded proxy variables across 97 annual observations.

The construction preserves the source payment series, measures the payment burden relative to NFC net operating surplus and net value added, subtracts the payment from NFC net operating surplus, and expresses the remainder relative to net and gross value added.

The wage-share baseline remains unchanged. The new shares are robustness candidates; the burden measures are diagnostic or robustness candidates.

The optional consolidated corporate proxy is `PARKED_COUNTERPARTY_OR_ACCOUNTING_IDENTITY_UNRESOLVED` because the financial counterparty and compatible financial-side surplus identity are unresolved.
