# S29L Parallel Fanout Execution Guide

Do not create branches from floating `main`. Use the exact S29L result commit after push.

* `S30A_REAL_OUTPUT_FAMILY_CLOSURE` -> `feature/s30a-output-family-closure`; writes `codes/US_S30A*` and `output/US/S30A*`.
* `S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE` -> `feature/s30b-distribution-family-closure`; writes `codes/US_S30B*` and `output/US/S30B*`.
* `S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK` -> `feature/s30c-contextual-family-lock`; writes `codes/US_S30C*` and `output/US/S30C*`.
* `S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD` -> `feature/s30d-dataset-release-scaffold`; writes `codes/US_S30D*` and `output/US/S30D*`.

Merge order after all reports are reviewed: S30A, S30B, S30C, S30D. Then run S31A through S31E sequentially.
