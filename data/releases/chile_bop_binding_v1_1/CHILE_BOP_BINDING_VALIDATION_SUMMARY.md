# Chile BOP Binding v1.1 — Validation Summary

Release status: **PASS**

- Source-of-truth wide and long files are byte-identical copies of `chile_bop_binding_v1`.
- The variable dictionary explicitly includes `log_K_NR_gross` as a contextual integration-test variable excluded from the final VECM.

- Annual coverage is complete from 1920 through 2024 (105 observations).
- The split panels contain 1920–1973 (54 observations) and 1974–2024 (51 observations).
- GDP, imports, investment, NRS, and gross machinery capital are expressed in 2003 CLP.
- The ClioLab RER uses the 2003 scale; BCCh observations are rebased to that scale.
- All required model variables are finite and NRS is positive throughout.
- Shares and ratios are explicitly marked base-year-free.
- Downstream estimation must read this release, not live source files.
