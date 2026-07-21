# S90 Verdict: Path-Dependent Technique Choice and Aggregate-Elasticity Lumpiness

## Verdict

The red series in v6 is not a structural aggregate elasticity. It is `vartheta_path = g^p/g^cap`, a ratio evaluated along the observed annual direction of ME/NRC accumulation. The exact contribution identity passes at 8.88e-16. Relative to the balanced-accumulation counterfactual, the Shapley decomposition assigns 1.2% of total first-difference roughness to wage conditioning, 58.0% to unbalanced capital composition, and 26.2% to the capital-growth denominator; the observed structures-growth baseline accounts for the remaining 14.6%. The point estimate therefore classifies the original lumpiness as **COMPOSITION_DRIVEN**, with dominance **BOOTSTRAP_UNSTABLE** under the moving-block interval; coefficient reconstruction is not the dominant source and the path is data-sensitive under the prespecified influence rule.

## Persistence

NFC_GVA: rho=0.98 (95% block CI 0.92--0.98), half-life 34.31 years; NFC_NVA: rho=0.96 (95% block CI 0.77--0.98), half-life 16.98 years; CORP_GVA: rho=0.95 (95% block CI 0.86--0.98), half-life 13.51 years; CORP_NVA: rho=0.94 (95% block CI 0.74--0.98), half-life 11.20 years.

The full smoother-equilibrium adjudication is **NOT FULLY SUPPORTED**. This is a joint test: the structural coefficients are smoother by construction of the economic object, but the claim is accepted only if embodied-memory models pass sample, rank, generated-path, and residual-stationarity gates; the Fordist sign survives H5; adaptive persistence excludes rho=0; influential years do not manufacture the result; and both NFC-GVA and NFC-NVA agree.

## Economic interpretation

Real NFC output and NFC capital never change across the grid. The wage state may be measured at the whole-NFC or all-corporation boundary because bargaining pressure can condition the technique installed in NFC productive capacity without sharing the same accounting boundary as output. The corporate variants are institutional comparisons only: their high Fordist correlation with NFC shares does not identify a unique bargaining sector.

## Implication for v6

Rename the red line `Observed-direction capacity payoff (ratio diagnostic)` and remove every sentence that treats it as equilibrium `theta_t`. Report `theta_scale` and `theta_tau` separately; show `g^p` and its ME/NRC contributions before dividing by `g^cap`; and present adaptive/embodied memory as S90 robustness evidence rather than as a replacement for the locked chapter specification.

## Reproducibility

The script used 1000 four-year moving-block bootstrap replications. All outputs are isolated under `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S90_path_dependent_theta_robustness`. No S40 or Stage B/C object is read or written.
