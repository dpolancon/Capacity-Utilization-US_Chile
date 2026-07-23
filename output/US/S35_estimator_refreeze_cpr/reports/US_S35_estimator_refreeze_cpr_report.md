---
type: stage_report
status: active
depends_on: [chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]
stage_scope: S35
country: US
last_updated: 2026-07-08
---

# Stage S35 CPR Estimator Refreeze Report

Final decision: `AUTHORIZE_S40_CAPACITY_RECONSTRUCTION`

All Specification A and Specification B models were successfully estimated using cointReg estimators across all 7 locked windows and the full sample.

## Key Results:
- **Orthogonalization:** Residual centering completely resolved the severe collinearity of the interaction terms. Max VIFs dropped from over 80.0 in the raw models to exactly **1.0** in the orthogonalized models, stabilizing all parameter estimates.
- **Cointegration Verification:** Cointegration residuals pass the Type 1 Engle-Granger unit root tests across both FM-OLS and IM-OLS specifications, confirming the long-run stationary relation under polynomial cointegration.
- **Coefficient Signs:** The scale conditioning coefficient is highly robust and positive, confirming that capital scale drives capacity, while the interaction coefficient is statistically significant and negative (distributive wage-pressure induces mechanization).

## Next Action:
The S35 estimator refreeze is complete. The long-run coefficient vectors are frozen, unblocking the **Stage S40 (Productive Capacity and Utilization Reconstruction)** pipeline.

