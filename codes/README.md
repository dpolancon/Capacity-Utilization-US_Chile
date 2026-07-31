# Code Index (Chapter 2)

## By Stage & Country

### US Track

#### S00–S10: Data Staging
- US_S05_*.R — Read BEA files, validate K stock
- US_S10_*.R — Construct Y, K, ω vectors; synchronize to Chile calendar

#### S15–S30: Specification & Estimation
- US_S15_*.R — Test cointegration order
- US_S20_*.R — Estimate long-run transformation relation (θ identification)
- US_S25_*.R — Recover Y^p from θ estimates
- US_S30_*.R — Reconstruct μ from Y^p + normalization

#### S35+: Validation & Output
- US_S35_*.R — VECM stability, residual diagnostics
- US_S40_*.R — Final figure/table generation for paper

### Chile Track

#### CL_S00–S10: Data Reconstruction
- CL_S05_*.R — BCCH/INE query + raw series staging
- CL_S10_*.R — WBOP reconciliation, RER base audit
- CL_S10_structural_break_*.R — Identify regime breaks (1973, 1990)

#### CL_S15–S30: External Constraint & Specification
- CL_S15_*.R — External balance evidence layer
- CL_S20_*.R — Model external constraint; test admissibility
- CL_S25_*.R — Stationary accumulation breaks; recapitalization analysis
- CL_S30_*.R — Estimate transformation relation w/ external mediation

#### CL_S35+: Estimation & Comparison
- CL_S35_*.R — VECM with external constraint
- CL_S40_*.R — μ reconstruction; center-periphery comparison figures

## By Theoretical Object

### θ_t Identification
- codes/US_S20_*.R, CL_S30_*.R (Polynomial Cointegration / CPR)
- Output: 03_econometrics/N01_CapacityUtilization_StructuralObject.md (theta_hat table)

### Y^p Reconstruction
- codes/US_S25_*.R, CL_S35_*.R
- Dependency: θ estimates (prior stage)

### External Constraint Modeling (Chile only)
- CL_S20_external_constraint_*.R
- Theory: 02_analyitical_foundation/[regulation theory notes]

### Recapitalization χ_t
- CL_S25_stationary_accumulation_breaks.R
- Theory: Needs linking to 00_constitutive_core/ profit-rate-of-profit section (if exists)

## Dependency: Data → Code → Output → Paper

See DEPENDENCY_MANIFEST.md for full chain.