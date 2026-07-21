---
type: methodological_correction
status: active_for_v4_deck
scope: S90_long_run_theta_directional_identification
supersedes_in_deck_only: cpr_long_run_theta_identification_addendum_v3
does_not_modify:
  - AGENTS.md
  - chapter2_vault constitutional files
  - locked chapter outline
  - v3 TeX or PDF
date: 2026-07-20
---

# Methodological correction for the long-run theta v4 deck

## Corrected estimand

The v3 deck defines the long-run transformation elasticity and then removes the composition mechanism by setting composition growth to zero. That move changes the estimand. The v4 deck instead defines the historical directional elasticity along the unbalanced accumulation path:

\[
\theta_{\Gamma,t}
=
\left.\frac{d\ln Y_t^p}{d\ln K_t^{cap}}\right|_{\Gamma}.
\]

The composition-mediated specification identifies the gradient of the potential-output surface,

\[
d y_t^p
=
\theta^{scale}d k_t^{NR}
+
\theta_t^\tau d\tau_t,
\qquad
\tau_t=k_t^{ME}-k_t^{NR},
\]

while the accumulation path supplies the direction. With

\[
K_t^{cap}=K_t^{ME}+K_t^{NR},
\qquad
s_t^{ME}=\frac{K_t^{ME}}{K_t^{cap}},
\]

the aggregate capital differential is

\[
d k_t^{cap}=d k_t^{NR}+s_t^{ME}d\tau_t.
\]

The aggregate elasticity therefore becomes

\[
\theta_{\Gamma,t}
=
\theta^{scale}
+
\left(\theta_t^\tau-s_t^{ME}\theta^{scale}\right)
\frac{d\tau_t}{d k_t^{cap}}.
\]

The evidence and verdict coincide: the two-capital coefficients do not lose aggregate theta; the unbalanced accumulation direction combines them into the scalar elasticity that changes capacity productivity.

## Why fixed technique does not imply fixed stock composition

A fixed technique determines the ME/NR bundle of the marginal installation. It does not require the percentage growth of the inherited component stocks to be equal:

\[
d\tau_t
=
\frac{dK_t^{ME}}{K_t^{ME}}
-
\frac{dK_t^{NR}}{K_t^{NR}}.
\]

The expression vanishes only when the marginal bundle reproduces the inherited stock composition. The v3 balanced restriction is therefore a special counterfactual, not the implication of causal technique timing.

## One path, two growth rates

The notation in v3 makes `g_t^{cap}` look like a second capacity path. The v4 deck renames it `g_{K,t}`. Potential-output growth and productive-capital growth remain distinct magnitudes evaluated on the same path:

\[
g_t^p=\Delta\ln Y_t^p,
\qquad
g_{K,t}=\Delta\ln K_t^{cap}.
\]

Their ratio is the local directional transformation elasticity. Imposing equality between them would impose the Harrodian benchmark, \(\theta=1\), by construction.

## Affine-form conflict

`AGENTS.md`, the deleted-but-locked outline at `HEAD:chapter2/outline/Ch2_Outline_DEFINITIVE.md`, and the active direct-scale rule retain the affine object

\[
\theta_t=\theta_1+\theta_2\pi_t.
\]

The composition-mediated model instead implies

\[
\theta_{\Gamma,t}^{LR}
=
\theta^{scale}
+
\left[
\psi_\pi+\lambda_\pi\pi_{t-1}^{LR}
-s_t^{ME}\theta^{scale}
\right]r_t^{LR},
\qquad
r_t^{LR}=\frac{d\tau_t}{d k_t^{cap}}.
\]

The aggregate object is affine in the profit share only if the long-run composition direction and the relevant capital share are fixed over the marginal comparison, or if an explicit approximation imposes that restriction. The v4 deck records that restriction; it does not edit the locked affine authority.

The active A03 note also writes the component-capital aggregate with share-weighted component payoffs, whereas the estimated CPR coordinate system uses \((k^{NR},\tau)\). These normalizations must be reconciled before the composition-mediated model is promoted as the chapter baseline. The v4 deck uses the CPR coordinate differential and the exact capital aggregation identity, then flags the authority-level reconciliation rather than silently treating the formulas as identical.

## Regime classification and constitutional terminology

The v4 window object is

\[
\Theta_{\Gamma,w}^{LR}
=
\frac{\sum_{t\in w}g_t^p}
     {\sum_{t\in w}g_{K,t}}.
\]

For positive cumulative capital growth,

\[
\Delta_w\ln b
=
\left(\Theta_{\Gamma,w}^{LR}-1\right)
\Delta_w\ln K^{cap}.
\]

A below-one interval identifies capital growing faster than the capacity it builds. An above-one interval identifies capacity deepening; it becomes overaccumulation of productive capacities only when realized demand fails to absorb the additional capacity, as shown by the anchored level or sustained decline of \(\mu_t\). This wording reconciles the Harrodian identity with the constitutional process-tracing rule.

## Inference status

The existing S90 moving-block bootstrap attributes the roughness of the annual ratio. It does not provide a bootstrap interval for the accumulation-window elasticity. The v4 deck therefore makes no numerical historical regime claim. Required regime inference must re-estimate the composition equation and persistent distributive state, reconstruct causally timed \(g_t^p\), recalculate \(g_{K,t}\), construct \(\Theta_{\Gamma,w}^{LR}\), and compare its interval with unity in every bootstrap draw.

## Governing verdict

The composition payoff is not tested against unity separately. It enters the aggregate path elasticity together with the plant-envelope payoff and the unbalanced accumulation direction. That combined object, not the balanced scale coefficient and not an isolated noisy annual observation, is the elasticity that can classify a historical accumulation regime.
