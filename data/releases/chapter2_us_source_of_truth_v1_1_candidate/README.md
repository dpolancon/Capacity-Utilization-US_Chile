---
type: data_manifest
status: frozen
depends_on: [data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/HANDOFF.md]
stage_scope: S30
country: none
last_updated: 2026-06-24
---

# Chapter 2 US Source-of-Truth Dataset v1.1 Candidate

- Status: release candidate only; not frozen and not tagged.
- Source stage: `S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM`.
- Parent release: `chapter2_us_source_of_truth_v1`.
- Original v1 rows and values are preserved.
- Added variables are bounded financial-claims and after-interest surplus proxies.
- The selected source is NFC net interest and miscellaneous payments; its financial counterparty is not directly observed.
- These variables are Shaikh-Tonak-inspired accounting proxies, not exact Appendix 6.7 adjustments.
- The wage-share baseline remains unchanged.
