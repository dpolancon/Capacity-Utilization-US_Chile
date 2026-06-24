# S31A Diagnostic Roadmap

S31A registers the frozen S30 dataset as the immutable baseline for diagnostics. All later S31 work must read the frozen release without correcting, extending, reclassifying, or rebuilding it.

## Diagnostic Questions After Intake

- Univariate descriptive diagnostics may examine support, missingness patterns, scale, distribution, and time-profile properties of level and already transformed canonical series.
- Cross-variable diagnostics may compare frozen series only after their support and S30 analytical roles are respected; no complete-case, common-support, or estimation sample is created in S31A.
- Objects with `REFERENCE_ONLY` status remain diagnostic references because S30 classified them as `DIAGNOSTIC_ONLY`.
- Any release-integrity defect, contract ambiguity, or apparent need to alter a variable requires human review and an S30 remediation decision.
- S31I is reserved for integration-order testing.

Descriptive diagnostics do not authorize modeling. No dataset changes are permitted in S31.
