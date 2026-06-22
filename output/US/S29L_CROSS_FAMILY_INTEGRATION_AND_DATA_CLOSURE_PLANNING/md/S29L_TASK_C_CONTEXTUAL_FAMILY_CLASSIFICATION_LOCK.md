# S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK

Branch: `feature/s30c-contextual-family-lock`

Purpose: Lock contextual, diagnostic, metadata-only, parked, blocked, and excluded objects without promoting them into core capital or model controls.

Exact base: `USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED`.

Exclusive writes: `codes/US_S30C*` and `output/US/S30C*`.

May do:
- inventory contextual and non-core objects
- classify each object
- create contextual reference contract, interface where authorized, validation, and handoff

Must not do:
- modify core capital aggregates
- assign productive-efficiency weights
- join families
- construct q, theta, productive capacity, utilization, controls, or models

Acceptance condition: `CONTEXTUAL_FAMILY_CLASSIFICATION_LOCKED`.
