---
type: evidence_ledger
status: active
layer: econometrics
design_role: integration_order_admissibility_map
scope: US_first_layer_theta_recovery
created: 2026-07-20
sources:
  - output/S34_pre_regression/us_s34_variable_menu_integration_ledger.csv
  - output/S34_pre_regression/us_s34_interaction_i2_risk_ledger.csv
  - output/S34_pre_regression/us_s34_candidate_level_relation_ledger.csv
  - output/S35_specification_review/us_s35_specification_review_ledger.csv
  - output/S35_specification_review/us_s35_estimator_menu_candidate_ledger.csv
  - output/S34R_B_cpr_realigned_design_gate/csv/S34R_B_repaired_path_admissibility_ledger.csv
  - output/S34R_B_cpr_realigned_design_gate/csv/S34R_B_specification_review_ledger.csv
related_to:
  - R_distribution_conditioned_theta_identification
  - D12V_Restricted_DOLS_Active_Estimator_Lock
  - Interaction_Term_Integration_Order_Gate
tags:
  - chapter2/econometrics
  - chapter2/us
  - chapter2/theta
  - chapter2/integration-order
---

# N03: U.S. \(\theta_t\) Integration-Order Admissibility Map

## Verdict

The integration-order record authorizes two families of first-layer \(\theta_t\) candidates for estimator-refreeze preparation: direct scale-conditioning with aggregate productive capital, and direct or composition-mediated conditioning with the heterogeneous NFC-capital boundary. The repaired CPR gate promoted six distribution-conditioned specifications, `D4`--`D9`; `D7` and `D9`, the residual-centered NRC-envelope forms, are its main candidates. The accumulated optimal-mechanization route is not in that authorized set. Its two surrogate paths pass the earlier I(1) screen but fail to become an active recovery specification: `Q_omega` is near-collinear with aggregate capital, `Q_MEshare` is held for design fragility, and the observed-\(q\) path `Q_q` is blocked as I(2)-risk.

This ledger records what the pre-tests authorize. It does not turn a gate pass into a coefficient estimate, a productive-capacity reconstruction, or a utilization result.

## How to read the statuses

Three layers use different language and must not be collapsed.

| Status | Meaning in this ledger |
|---|---|
| **Screen-admissible** | The S34 variable/relation screen found an I(1)-compatible standard cointegration object. This is a necessary entry condition, not estimator authorization. |
| **CPR-authorized** | The repaired S34R-B gate permits the mixed-order state or interaction in polynomial cointegration conditional on a stationary residual. Its review ledger records `PASS` integration and design status, `EG_PASS_WEAK`, and promotion to S35 preparation. |
| **Not retained** | The object is blocked, diagnostic-only, or held after the screen. It is not an active first-layer \(\theta_t\)-recovery specification. |

The current boundary follows the repaired gate rather than the older B1/E2B labels. Earlier S31I level tests found persistent I(2) risk for aggregate and component capital in several windows. S34R-B therefore does not relabel those capital levels as clean I(1) variables: it explicitly authorizes the relevant mixed-order objects under the CPR rule, conditional on residual cointegration.

## 1. Aggregate NFC productive-capital specifications

Let \(k_t^{cap}=\log(K_t^{ME}+K_t^{NR})\) and let \(\tilde\omega_t\) be centered NFC wage share. The following two direct scale-conditioning models are CPR-authorized secondary candidates:

| ID | Long-run relation | Integration/design outcome | Role after pre-testing |
|---|---|---|---|
| `D4_y_kKcap_omega_inter` | \(y_t=\alpha+\beta_K\tilde k_t^{cap}+\phi\tilde\omega_t+\beta_{K\omega}(\tilde k_t^{cap}\tilde\omega_t)+\varepsilon_t\) | All terms pass the repaired CPR path ledger; the design is full rank (condition number 1.73); `EG_PASS_WEAK`. | Secondary candidate for S35. |
| `D5_y_kKcap_omega_inter_orth` | Same long-run space, with the interaction residual-centered on its lower-order terms. | All terms pass; full rank (condition number 1.48); `EG_PASS_WEAK`. | Secondary candidate for S35. |

Both recover the direct state-conditioned scale elasticity \(\theta_t=\beta_K+\beta_{K\omega}\tilde\omega_t\). `D5` changes the coefficient basis and improves design geometry; it does not define a different economic object. The simple aggregate models `D0`--`D2` passed design checks but were not advanced because they do not recover a distribution-conditioned \(\theta_t\).

## 2. Heterogeneous NFC-capital specifications

The authorized heterogeneous route does **not** put \(k_t^{ME}\) and \(k_t^{NR}\) side by side as unrestricted level regressors. S34 found that pair full rank but highly correlated (0.9944), while the earlier rolling audit recorded stable I(2) risk for the component levels. The repaired design therefore uses an NRC envelope, \(k_t^{NR}\), and, where required, the composition state \(\tau_t=\log K_t^{ME}-\log K_t^{NR}\).

| ID | Long-run relation | Integration/design outcome | Role after pre-testing |
|---|---|---|---|
| `D6_y_kNRC_omega_inter` | \(y_t=\alpha+\beta_{NR}\tilde k_t^{NR}+\phi\tilde\omega_t+\beta_{NR\omega}(\tilde k_t^{NR}\tilde\omega_t)+\varepsilon_t\) | CPR-authorized; full rank (condition number 1.67); `EG_PASS_WEAK`. | Secondary candidate for S35. |
| `D7_y_kNRC_omega_inter_orth` | `D6` with residual-centered interaction. | CPR-authorized; full rank (condition number 1.32); `EG_PASS_WEAK`. | **Main candidate for S35.** |
| `D8_y_kNRC_tau_omega_inter` | \(y_t=\alpha+\theta\tilde k_t^{NR}+\psi\tilde\tau_t+\phi\tilde\omega_t+\lambda(\tilde\tau_t\tilde\omega_t)+\varepsilon_t\) | CPR-authorized; full rank (condition number 6.31); `EG_PASS_WEAK`. | Secondary candidate for S35. |
| `D9_y_kNRC_tau_omega_inter_orth` | `D8` with residual-centered composition interaction. | CPR-authorized; full rank (condition number 4.81); `EG_PASS_WEAK`. | **Main candidate for S35.** |

`D7` identifies a direct NRC-envelope elasticity conditioned by distribution. `D9` tests the distinct claim that distribution conditions the composition payoff, \(\psi+\lambda\tilde\omega_t\), while \(\theta\) remains the scale term. The two models answer different questions and remain a specification fork, not interchangeable parameterizations.

## 3. Optimal-mechanization proxy and accumulated-path specifications

The theoretical sequence \(\omega_t\rightarrow q_t^*\rightarrow\Delta K_t\rightarrow Y_t^p\) is not itself a passed long-run regression. The empirical menu contains proxies for that sequence. Their exact gate outcomes are:

| Object / candidate | Relation or construction | S34 integration result | Disposition |
|---|---|---|---|
| `Q_omega` / `S35_DIST_ACCUM_PATH` | \(Q_t^\omega=\sum_{s\leq t}\omega_{s-1}\Delta k_s^{cap}\); \(y_t\sim k_t^{cap}+Q_t^\omega\) | `I1`; `AUTHORIZE_STANDARD_IF_I1`; visually plausible I(1) pair. | **Not retained as main.** S35 classifies it as reduced-form distribution robustness: its design with \(k_t^{cap}\) has correlation 0.99997 and condition number 271.7. It is not a direct mechanization proxy. |
| `Q_MEshare` / `S35_MECH_COMP_PATH` | \(Q_t^{MEshare}=\sum_{s\leq t}s_{s-1}^{ME}\Delta k_s^{cap}\); \(y_t\sim k_t^{cap}+Q_t^{MEshare}\) | `I1`; `AUTHORIZE_STANDARD_IF_I1`; visually plausible I(1) pair. | **Held, not estimator-authorized.** It is the admissible stock-composition surrogate, but the joint design remains fragile (correlation 0.99796; condition number 31.3). |
| `Q_q` / `S35_OBS_Q_PATH` | \(Q_t^q=\sum_{s\leq t}q_{s-1}\Delta k_s^{cap}\); \(y_t\sim k_t^{cap}+Q_t^q\) | `I2_RISK`; `BLOCK_STANDARD_I2_RISK`. | **Blocked.** This would recover \(\theta_t=\beta_K+\beta_Qq_{t-1}\), but no authorized observed-\(q\) proxy supports that recovery. |
| `q_proxy_mechanization_growth` / `REL_q_omega` | Upstream \(q_t\sim\omega_t\) technique-choice screen. | The proxy is I(1), but the wage-share state is bounded persistent and visual support is weak (level correlation 0.112). | **Diagnostic only.** It cannot identify \(q_t^*\) or a capacity elasticity by itself. |
| Raw \(k_t^{cap}q_t\), \(q_t^2\), and \(q_t\omega_t\) | Level products or polynomial technique-choice terms. | `BLOCK_STANDARD_I2_RISK`. | **Blocked from the standard grid.** They require a separate polynomial-cointegration protocol, not ordinary first-layer promotion. |

The resulting conclusion is sharp: pre-testing admits the construction of `Q_omega` and `Q_MEshare` as I(1) screened paths, but no optimal-mechanization proxy specification is currently authorized to recover the active \(\theta_t\) path. The `q_omega` family remains parked under the active estimator lock.

## 4. Complete promoted \(\theta_t\)-recovery set

The set actually promoted by the repaired integration/design gate is therefore:

1. `D4_y_kKcap_omega_inter` — aggregate direct scale-conditioning, secondary;
2. `D5_y_kKcap_omega_inter_orth` — aggregate direct scale-conditioning, residual-centered, secondary;
3. `D6_y_kNRC_omega_inter` — NRC-envelope direct scale-conditioning, secondary;
4. `D7_y_kNRC_omega_inter_orth` — NRC-envelope direct scale-conditioning, residual-centered, main;
5. `D8_y_kNRC_tau_omega_inter` — heterogeneous composition-mediated conditioning, secondary; and
6. `D9_y_kNRC_tau_omega_inter_orth` — heterogeneous composition-mediated conditioning, residual-centered, main.

Each entry has `PASS` integration and design status in the S34R-B review ledger and `EG_PASS_WEAK`. The gate's final decision is `AUTHORIZE_S35_ESTIMATOR_REFREEZE_PREP`, not unrestricted estimation or automatic S40 reconstruction.

## 5. Guardrails for later use

- Treat the raw and residual-centered variants as the same economic long-run space only after the coefficient back-transformation is recorded. Do not read the orthogonalized coefficient itself as the primitive marginal elasticity.
- Do not claim that separate ME and NR level coefficients were admitted. The current heterogeneous route is an NRC envelope plus the ME/NR composition state, precisely because the unrestricted component-level design is fragile.
- Do not promote `Q_omega`, `Q_MEshare`, or an upstream \(q\)-on-distribution relation as an active \(\theta_t\) specification. The first two stopped at screen/design review; the third is diagnostic.
- Do not treat `EG_PASS_WEAK` as conclusive residual evidence. It cleared the gate used here, while later coefficient robustness, generated-path checks, and reconstruction validation remain separate requirements.

## Source ledger

| Artifact | SHA-256 at audit | Evidence used |
|---|---|---|
| `output/S34_pre_regression/us_s34_variable_menu_integration_ledger.csv` | `0C9B96ED255B2ABB60E18A048DEBF01C00875B9A513A06D9BACFD2BFEEEDFB78` | I(1)/I(2)-risk classifications for the aggregate, heterogeneous, and accumulated-path objects. |
| `output/S34_pre_regression/us_s34_interaction_i2_risk_ledger.csv` | `39BAC113C8B678B588E0BA1995401244D52B3045924D4927611B9076D56F7F11` | Standard-grid authorization/blocking for accumulated paths and raw products. |
| `output/S35_specification_review/us_s35_specification_review_ledger.csv` | `4B9EE9AE71E1AE9CE58D67910C0F8D399B08517C5409FD52B475409B48A537BE` | Meaning and implied \(\theta_t\) recovery for each accumulated-path candidate. |
| `output/S35_specification_review/us_s35_estimator_menu_candidate_ledger.csv` | `FCFD09C121AE6908A04881C3AF03D82B397A103B3638D61BC36FF9D407B11CAB` | Hold, diagnostic, and blocked dispositions after the S34 screen. |
| `output/S34R_B_cpr_realigned_design_gate/csv/S34R_B_repaired_path_admissibility_ledger.csv` | `B352F58179813577DA768154C3878FF5FD1544BDDCAE971C93FD3C3B5ED58706` | CPR authorization of states and interactions. |
| `output/S34R_B_cpr_realigned_design_gate/csv/S34R_B_specification_review_ledger.csv` | `B5B58531B5281259734EC2AC9B1B321EA5EECF1089C80BB5CD417D158CBCD929` | The six promoted models, their gates, and S35 roles. |

## Locked statement

**The U.S. integration-order pre-tests promote aggregate direct scale-conditioning and heterogeneous NRC-envelope/composition-conditioning for CPR estimator preparation. They do not promote an observed or optimal-mechanization proxy as an active long-run \(\theta_t\)-recovery specification.**
