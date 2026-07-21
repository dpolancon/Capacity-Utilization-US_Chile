# S90 Path-Dependent Theta Robustness

Standalone diagnostic implementation of the approved plan.

- canonical input: D10 clean US panel
- frozen v6 audit inputs: S35 coefficients and S34R-B orthogonalized panel
- main estimator: manual intercept-only Restricted DOLS, LL11
- dynamic correction: differences of k_NRC, tau, and the wage state only
- persistence inference: BIC profile plus four-year moving-block bootstrap
- output and capital boundaries: real NFC GVA and NFC capital, fixed
- downstream status: S90 diagnostic only; S40 and Stage B/C unchanged
