# S29I Total Capital Downstream Interface Assembly

S29I assembles S29H-contracted variables into separate downstream interface lanes. It copies S29F values exactly and creates no new economic variables, transformations, complete-case samples, q, theta, productive capacity, utilization, modeling outputs, or econometric outputs.

## Lanes

- Baseline primary level: `G_TOT_GPIM_2017`.
- Baseline primary log: `LOG_G_TOT_GPIM_2017`.
- Net robustness level: `N_TOT_GPIM_2017`.
- Net robustness log: `LOG_N_TOT_GPIM_2017`.
- Conditional secondary variables remain inactive by default and require explicit future authorization.
- Diagnostic and alias variables are catalogs only, not active value-bearing candidates.
