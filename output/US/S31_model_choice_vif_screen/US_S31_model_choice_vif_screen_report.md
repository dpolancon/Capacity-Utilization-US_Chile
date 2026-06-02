# US S31 Model-Choice VIF Screen Report

Run timestamp: `2026-06-02 17:20:00 -04`.

## 1. Purpose

This script adds a governed S31 VIF screen for model-choice review. It combines existing S31 VIF diagnostics for reported S30 specifications with new A05 E-specification VIF-only diagnostics. It reports collinearity feasibility; it does not estimate coefficients, adjudicate cointegration, or choose a model.

## 2. Governance from A05/R10/D04

A00/B1 remains the baseline review object. C1/C2 are A03 proxy-escalation specifications. E1/E2A/E2B are A03 candidate specifications and are not estimated. D1/D2 are diagnostic-only and non-promotable. VIF can block or caution coefficient interpretation, but it cannot promote a model.

## 3. Existing S30 Specs Included in the Screen

- `SPEC_B1_WAGE_BASELINE`: A00 baseline review object.
- `SPEC_C1_COMPOSITION_STOCK`: A03 proxy-escalation review object.
- `SPEC_C2_FULL_COMPOSITION`: A03 proxy-escalation review object.
- `SPEC_D1_CURRENT_COST_DIAGNOSTIC`: diagnostic-only, non-promotable.
- `SPEC_D2_PRICE_WEDGE_DIAGNOSTIC`: diagnostic-only, non-promotable.

## 4. Candidate A05 E-Specs Included as VIF-Only Diagnostics

- `SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS`: VIF only, `y_t ~ k_NRC_proxy_t + m_ME_NRC_t`.
- `SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL`: VIF only, `y_t ~ k_NRC_proxy_t + m_ME_NRC_t + omega_m_ME_NRC_t`.
- `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`: VIF only, `y_t ~ k_NRC_proxy_t + omega_m_ME_NRC_t`.

The envelope variable is log real NRC capital. The mechanization-bias variable is log(ME/NRC), so higher values indicate greater machinery intensity relative to the NRC envelope. The reverse-sign construction `c_NRC_ME_t = -m_ME_NRC_t` is documentation-only and is not used in VIF regressions.

## 5. Window Set

- `full_long_sample`: 1929-2024
- `pre_1974`: 1929-1973
- `post_1973`: 1974-2024
- `fordist_core`: 1945-1973
- `bridge_1940_1978`: 1940-1978
- `pre_1974_alt_1940_1973`: 1940-1973
- `pre_1974_alt_1947_1974`: 1947-1974

Excluded windows remain excluded from this screen: `prefordist_core_1929_1944`, `post_1974_tight`, and `post_1974_support`.

## 6. VIF Thresholds

- `low`: VIF < 5.
- `moderate`: 5 <= VIF < 10.
- `high`: VIF >= 10.

## 7. Spec-Level Screen Results

| Spec | Layer | Estimated status | Max VIF | High windows | Recommendation | Final screen status |
|---|---|---:|---:|---:|---|---|
| `SPEC_B1_WAGE_BASELINE` | `A00_baseline` | `estimated_in_S30` | 5.934 | 0 | `vif_feasible_with_caution` | `baseline_vif_fragile_for_human_adjudication` |
| `SPEC_C1_COMPOSITION_STOCK` | `A03_proxy_escalation` | `estimated_in_S30` | 6.475 | 0 | `vif_feasible_with_caution` | `proxy_escalation_vif_fragile_for_human_adjudication` |
| `SPEC_C2_FULL_COMPOSITION` | `A03_proxy_escalation` | `estimated_in_S30` | 4363.707 | 7 | `vif_block_before_estimation_or_promotion` | `proxy_escalation_vif_fragile_for_human_adjudication` |
| `SPEC_D1_CURRENT_COST_DIAGNOSTIC` | `diagnostic_only` | `estimated_in_S30` | 20.968 | 1 | `vif_block_before_estimation_or_promotion` | `diagnostic_only_not_promotable` |
| `SPEC_D2_PRICE_WEDGE_DIAGNOSTIC` | `diagnostic_only` | `estimated_in_S30` | 25.539 | 2 | `vif_block_before_estimation_or_promotion` | `diagnostic_only_not_promotable` |
| `SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS` | `A03_candidate` | `not_estimated_vif_only` | 4.312 | 0 | `vif_feasible_for_human_review` | `vif_feasible_for_possible_future_S30b_or_S32_review` |
| `SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL` | `A03_candidate` | `not_estimated_vif_only` | 25.407 | 2 | `vif_block_before_estimation_or_promotion` | `vif_blocks_candidate_estimation_pending_human_override` |
| `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED` | `A03_candidate` | `not_estimated_vif_only` | 1.395 | 0 | `vif_feasible_for_human_review` | `vif_feasible_for_possible_future_S30b_or_S32_review` |

## 8. Main Interpretation

The candidate E-spec VIF output contains `21` spec-window cells across the seven governed S31 windows.
The existing S31 report was read as a required reference input (`70` lines). Existing S31 coefficient tables were not overwritten.
The screen ranks and flags specifications for human review. A high VIF blocks estimation or promotion pending human override. Moderate VIF requires caution. Low VIF only clears the collinearity screen; it does not authorize promotion.

## 9. No Final Model Is Selected

No row selects a final model. No row is marked `promoted_for_reconstruction`. The VIF screen alone never makes a model S40-eligible.

## 10. S40 Remains Parked

S40 remains parked. This run reads no S40 outputs, reconstructs no theta_tot, reconstructs no Yp, computes no mu, and chooses no anchor.

## 11. Recommended Next Human Decisions

- Decide whether B1/A00 remains adequate as the baseline review object after inspecting coefficient stability and VIF.
- Decide whether C1/C2 proxy-escalation rows remain interpretable or are blocked by high VIF.
- Decide whether any E1/E2A/E2B candidate with feasible VIF should be authorized for a separate estimation pass.
- Decide whether any estimated specification should move toward S40 reconstruction; that movement requires human adjudication and is not authorized here.
