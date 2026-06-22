# S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE

Branch: `feature/s30b-distribution-family-closure`

Purpose: Close the income-distribution family while preserving wage-share preference, exploitation alternative status, and the Shaikh-adjustment block.

Exact base: `USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED`.

Exclusive writes: `codes/US_S30B*` and `output/US/S30B*`.

May do:
- consume S29A
- classify primary, robustness, diagnostic, blocked, and alias variables
- create contract, interface, validation, handoff, and intake

Must not do:
- construct new Shaikh-adjusted variables
- join families
- construct interactions, q, theta, productive capacity, utilization, or models

Acceptance condition: `DISTRIBUTION_FAMILY_CLOSED_CONSUMABLE`.
