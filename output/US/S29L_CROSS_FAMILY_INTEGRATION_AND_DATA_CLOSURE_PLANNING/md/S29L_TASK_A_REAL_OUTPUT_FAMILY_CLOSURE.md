# S30A_REAL_OUTPUT_FAMILY_CLOSURE

Branch: `feature/s30a-output-family-closure`

Purpose: Close the real-output family without joining it to capital, distribution, or contextual families.

Exact base: `USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED`.

Exclusive writes: `codes/US_S30A*` and `output/US/S30A*`.

May do:
- audit the output source boundary
- construct authorized output variables only if required by locked evidence
- validate units, reference years, support, contract, interface, handoff, and intake

Must not do:
- edit capital/distribution/contextual outputs
- join families
- create complete-case samples
- construct q, theta, productive capacity, utilization, or models

Acceptance condition: `OUTPUT_FAMILY_CLOSED_CONSUMABLE`.
