# S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD

Branch: `feature/s30d-dataset-release-scaffold`

Purpose: Create schema-only or zero-row templates for final dataset release infrastructure.

Exact base: `USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED`.

Exclusive writes: `codes/US_S30D*` and `output/US/S30D*`.

May do:
- create canonical long/wide schemas
- create dictionary, provenance, admissibility, support, registry, manifest, and validation templates
- create final handoff and decision templates

Must not do:
- copy live family values
- join families
- select new authoritative variables
- create complete-case samples, release candidates, final hashes, q, theta, utilization, or models

Acceptance condition: `DATASET_RELEASE_SCAFFOLD_READY`.
