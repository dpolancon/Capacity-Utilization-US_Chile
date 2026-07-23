---
type: stage_report
status: active
depends_on: [chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]
stage_scope: all_stages
country: US
last_updated: 2026-07-07
---

# D12F-R No-Trend Contract

NO_TREND_BASELINE_RULE

The preferred Chapter 2 RDOLS baseline excludes a deterministic linear time trend from the long-run level relation.

Trend-included RDOLS estimates are retained only as diagnostic Shaikh-closure comparators.

Trend-included estimates cannot authorize baseline interpretation, productive-capacity reconstruction, utilization reconstruction, or elasticity recovery.

Allowed: intercept, capital terms, distribution term, capital-distribution interactions, restricted base first-difference dynamics, periodized windows, and maximal feasible effective samples.

Blocked: linear deterministic trend, trend-stabilized capacity closure, trend as autonomous technical change, q_omega, interaction/generated dynamics, FM-OLS/IM-OLS drift, and cointRegD interacted-baseline drift.
