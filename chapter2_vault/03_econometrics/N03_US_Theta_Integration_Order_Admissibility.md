---
type: econometric_protocol
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US
last_updated: 2026-07-23
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
- Interaction_Term_Integration_Order_Gate
tags:
- chapter2/econometrics
- chapter2/us
- chapter2/theta
- chapter2/integration-order
---

# N03 — U.S. $\theta_t$ Integration-Order Admissibility Map

## Verdict

The integration-order record admits two families of first-layer candidates for estimating $\theta_t$, the elasticity that measures how capital accumulation becomes productive capacity. The first conditions aggregate productive capital directly on distribution. The second conditions the nonresidential-capital envelope either directly or through capital composition. The repaired polynomial-cointegration design gate advances six distribution-conditioned specifications, $D_4$–$D_9$, to estimator preparation. The residual-centered nonresidential-capital specifications, $D_7$ and $D_9$, are the leading candidates within that gate.

The accumulated mechanization route does not enter that set. The distribution-weighted accumulation path is nearly collinear with aggregate capital, the machinery-share path remains too fragile for estimation, and the observed-$q$ path carries unresolved $I(2)$ risk. These results reject their promotion to the active $\theta_t$ specification.

This note records what the integration and design tests admit. It does not select the final estimator, report a coefficient estimate, estimate productive capacity, or construct capacity utilization.

## How to read the statuses

Three layers use different language and must not be collapsed.

| Status | Meaning in this ledger |
|---|---|
| **Admissible at the integration screen** | The S34 screen classifies the relation as compatible with an $I(1)$ cointegration design. This is a necessary entry condition, not authorization to estimate the final model. |
| **Admissible under the repaired polynomial-cointegration gate** | The S34R-B gate permits the mixed-order state or interaction to proceed because the integration and design checks pass and the residual-stationarity evidence reaches the gate’s weaker 10 percent threshold. |
| **Not retained** | The relation is blocked, diagnostic only, or held after the screen. It is not an active first-layer specification for estimating $\theta_t$. |

The current boundary follows the repaired gate rather than the older B1/E2B labels. Earlier S31I level tests found persistent $I(2)$ risk for aggregate and component capital in several windows. S34R-B therefore does not relabel those capital levels as clean $I(1)$ variables. It admits the relevant mixed-order relations under its polynomial-cointegration rule, conditional on the residual evidence recorded by that gate.

## 1. Aggregate NFC productive-capital specifications

Let $k_t^{\mathrm{cap}}=\log(K_t^{\mathrm{ME}}+K_t^{\mathrm{NR}})$, and let $\tilde{\omega}_t$ denote the centered NFC wage share. The aggregate specification tests whether distribution conditions the transformation of capital into productive capacity:

$$
y_t
=\alpha
+\beta_K\tilde{k}_t^{\mathrm{cap}}
+\phi\tilde{\omega}_t
+\beta_{K\omega}
\left(\tilde{k}_t^{\mathrm{cap}}\tilde{\omega}_t\right)
+\varepsilon_t.
\tag{D_4}
$$

Specification $D_5$ expresses the same long-run relation after residual-centering the interaction on its lower-order terms.

| Specification | Integration and design evidence | Status after pre-testing |
|---|---|---|
| $D_4$ — aggregate interaction | The mixed-order terms pass the repaired gate. The design is full rank, with condition number 1.73, and residual stationarity reaches the 10 percent threshold. | Secondary candidate for S35. |
| $D_5$ — residual-centered aggregate interaction | The mixed-order terms pass the repaired gate. The design is full rank, with condition number 1.48, and residual stationarity reaches the 10 percent threshold. | Secondary candidate for S35. |

Both specifications estimate the direct distribution-conditioned scale elasticity,

$$
\theta_t=\beta_K+\beta_{K\omega}\tilde{\omega}_t.
$$

Specification $D_5$ changes the coefficient basis and improves the geometry of the design matrix; it does not define a different economic relation. The simpler aggregate specifications $D_0$–$D_2$ pass the design checks but do not advance because they cannot estimate a distribution-conditioned $\theta_t$.

## 2. Heterogeneous NFC-capital specifications

The heterogeneous route does not place $k_t^{ME}$ and $k_t^{NR}$ side by side as unrestricted level regressors. S34 finds that pair full rank but highly correlated, with a correlation of 0.9944, while the earlier rolling audit records persistent $I(2)$ risk for the component levels. The repaired design therefore uses the nonresidential-capital envelope, $k_t^{NR}$, and, where required, the capital-composition state,

$$
\tau_t=\log K_t^{ME}-\log K_t^{NR}
$$



| Specification                                                  | Long-run relation                                                                                                          | Integration and design evidence                                                                                                                         | Status after pre-testing       |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| $D_6$ — nonresidential-capital interaction                   | $y_t=\alpha+\beta_{NR}\tilde k_t^{NR}+\phi\tilde\omega_t+\beta_{NR\omega}(\tilde k_t^{NR}\tilde\omega_t)+\varepsilon_t$ | The relation passes the repaired gate. The design is full rank, with condition number 1.67, and residual stationarity reaches the 10 percent threshold. | Secondary candidate for S35.   |
| $D_7$ — residual-centered nonresidential-capital interaction | The same long-run relation as $D_6$, expressed after residual-centering the interaction.                               | The relation passes the repaired gate. The design is full rank, with condition number 1.32, and residual stationarity reaches the 10 percent threshold. | **Leading candidate for S35.** |
| $D_8$ — composition-conditioned interaction                  | $y_t=\alpha+\theta\tilde k_t^{NR}+\psi\tilde\tau_t+\phi\tilde\omega_t+\lambda(\tilde\tau_t\tilde\omega_t)+\varepsilon_t$ | The relation passes the repaired gate. The design is full rank, with condition number 6.31, and residual stationarity reaches the 10 percent threshold. | Secondary candidate for S35.   |
| $D_9$ — residual-centered composition interaction            | The same long-run relation as $D_8$, expressed after residual-centering the composition interaction.                   | The relation passes the repaired gate. The design is full rank, with condition number 4.81, and residual stationarity reaches the 10 percent threshold. | **Leading candidate for S35.** |

Specification $D_7$ estimates a direct nonresidential-capital elasticity conditioned by distribution. Specification $D_9$ tests the distinct claim that distribution conditions the productivity of capital composition, $\psi+\lambda\tilde\omega_t$, while $\theta$ remains the scale elasticity. The two specifications answer different questions and cannot be treated as interchangeable parameterizations.

## 3. Optimal-mechanization proxy and accumulated-path specifications

The theoretical sequence

$$
\omega_t\rightarrow q_t^*\rightarrow\Delta K_t\rightarrow Y_t^p
$$

does not itself constitute an admissible long-run regression. The empirical menu contains several proxies for that sequence:

| Candidate | Relation or construction | Integration evidence | Disposition |
|---|---|---|---|
| Distribution-weighted accumulation, $Q_t^\omega$ | $Q_t^\omega=\sum_{s\leq t}\omega_{s-1}\Delta k_s^{cap}$, entering $y_t$ alongside $k_t^{cap}$. | The path is classified as $I(1)$ and passes the initial integration screen. | **Not retained as a leading specification.** Its correlation with $k_t^{cap}$ is 0.99997 and the condition number is 271.7. It measures reduced-form distributional conditioning, not mechanization directly. |
| Machinery-share accumulation, $Q_t^{MEshare}$ | $Q_t^{MEshare}=\sum_{s\leq t}s_{s-1}^{ME}\Delta k_s^{cap}$, entering $y_t$ alongside $k_t^{cap}$. | The path is classified as $I(1)$ and passes the initial integration screen. | **Held before estimation.** It is an admissible stock-composition surrogate, but its correlation with $k_t^{cap}$ is 0.99796 and the condition number is 31.3. |
| Observed-mechanization accumulation, $Q_t^q$ | $Q_t^q=\sum_{s\leq t}q_{s-1}\Delta k_s^{cap}$, entering $y_t$ alongside $k_t^{cap}$. | The path carries unresolved $I(2)$ risk. | **Blocked.** It would imply $\theta_t=\beta_K+\beta_Qq_{t-1}$, but the integration evidence does not admit it to the standard specification set. |
| Upstream mechanization-growth relation | The technique-choice screen relates $q_t$ to $\omega_t$. | The mechanization proxy is $I(1)$, while the wage-share state is bounded and persistent; their level correlation is only 0.112. | **Diagnostic only.** This relation cannot identify $q_t^*$ or a capacity elasticity by itself. |
| Raw products $k_t^{cap}q_t$, $q_t^2$, and $q_t\omega_t$ | Level interactions and polynomial technique-choice terms. | Each carries unresolved $I(2)$ risk in the standard grid. | **Blocked from the standard specification set.** They require a separately governed polynomial-cointegration design. |

The evidence admits $Q_t^\omega$ and $Q_t^{MEshare}$ as $I(1)$ paths at the initial screen, but neither becomes an active specification for estimating $\theta_t$. No observed or optimal-mechanization proxy survives the complete integration and design sequence.

## 4. Complete promoted set for estimating $\theta_t$

The repaired integration and design gate advances the following set:

1. $D_4$: aggregate scale-conditioning, secondary;
2. $D_5$: residual-centered aggregate scale-conditioning, secondary;
3. $D_6$: nonresidential-capital scale-conditioning, secondary;
4. $D_7$: residual-centered nonresidential-capital scale-conditioning, leading;
5. $D_8$: composition-mediated conditioning, secondary; and
6. $D_9$: residual-centered composition-mediated conditioning, leading.

Each specification passes the integration and design checks recorded by S34R-B, while its residual-stationarity evidence reaches only the gate’s weaker 10 percent threshold. The gate therefore authorizes preparation for the next estimator stage. It does not authorize unrestricted estimation or automatic productive-capacity reconstruction.

## 5. Guardrails for later use

- Treat the raw and residual-centered variants as the same economic long-run space only after recording the coefficient back-transformation. The residual-centered interaction coefficient is not, by itself, the primitive marginal elasticity.
- Do not claim that separate $K^{ME}$ and $K^{NR}$ level coefficients were admitted. The heterogeneous route uses a $K^{NR}$ envelope plus the $K^{ME}/K^{NR}$ composition state because the unrestricted component-level design is fragile.
- Do not promote $Q_t^\omega$, $Q_t^{MEshare}$, or an upstream relation between $q_t$ and distribution as an active $\theta_t$ specification. The first two stop at the screen or design review, and the third remains diagnostic.
- Do not treat the 10 percent residual-stationarity result as conclusive evidence of cointegration. Coefficient robustness, generated-path checks, and reconstruction validation remain separate requirements.

## Source ledger

| Artifact | SHA-256 at audit | Evidence used |
|---|---|---|
| `output/S34_pre_regression/us_s34_variable_menu_integration_ledger.csv` | `0C9B96ED255B2ABB60E18A048DEBF01C00875B9A513A06D9BACFD2BFEEEDFB78` | $I(1)$/$I(2)$-risk classifications for the aggregate, heterogeneous, and accumulated-path relations. |
| `output/S34_pre_regression/us_s34_interaction_i2_risk_ledger.csv` | `39BAC113C8B678B588E0BA1995401244D52B3045924D4927611B9076D56F7F11` | Standard-grid authorization/blocking for accumulated paths and raw products. |
| `output/S35_specification_review/us_s35_specification_review_ledger.csv` | `4B9EE9AE71E1AE9CE58D67910C0F8D399B08517C5409FD52B475409B48A537BE` | Meaning and implied $\theta_t$ recovery for each accumulated-path candidate. |
| `output/S35_specification_review/us_s35_estimator_menu_candidate_ledger.csv` | `FCFD09C121AE6908A04881C3AF03D82B397A103B3638D61BC36FF9D407B11CAB` | Hold, diagnostic, and blocked dispositions after the S34 screen. |
| `output/S34R_B_cpr_realigned_design_gate/csv/S34R_B_repaired_path_admissibility_ledger.csv` | `B352F58179813577DA768154C3878FF5FD1544BDDCAE971C93FD3C3B5ED58706` | CPR authorization of states and interactions. |
| `output/S34R_B_cpr_realigned_design_gate/csv/S34R_B_specification_review_ledger.csv` | `B5B58531B5281259734EC2AC9B1B321EA5EECF1089C80BB5CD417D158CBCD929` | The six promoted models, their gates, and S35 roles. |

## Locked statement

**The U.S. integration-order tests advance aggregate scale-conditioning and heterogeneous nonresidential-capital/composition conditioning to polynomial-cointegration estimator preparation. They reject the promotion of an observed or optimal-mechanization proxy as an active long-run specification for estimating $\theta_t$.**
