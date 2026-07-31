---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-25
layer: econometrics
created_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
role: pre-testing-protocol
stage: pre-estimation-design
tags:
  - chapter2/econometrics
  - chapter2/pre-testing
  - chapter2/aggregation-bias
  - chapter2/capital-controversy
aliases:
  - E13 Baseline Aggregation Scrutiny
  - Aggregation Bias Protocol
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E13 — Scrutiny of Simple Capital Aggregation ($K^{\text{cap}} = K^{\text{ME}} + K^{\text{NRC}}$) in the Baseline Model

## Executive Summary

This note documents the mathematical, accounting, and econometric restrictions imposed on the Baseline Specification (Specification A) when employing a simple additive GPIM aggregation for capital in operation ($K^{\text{cap}} = K^{\text{ME}} + K^{\text{NRC}}$). It establishes the analytical boundaries between valid Harrodian accumulation and misspecified composition drift.

---

## 1. Mathematical & Accounting Decomposition of the Simple Sum

When defining aggregate capacity capital as the simple arithmetic sum of GPIM physical stocks, taking natural logarithms yields:

$$ k^{\text{cap}}_t = \ln(K^{\text{ME}}_t + K^{\text{NRC}}_t) = \ln K^{\text{NRC}}_t + \ln\left(1 + \frac{K^{\text{ME}}_t}{K^{\text{NRC}}_t}\right) $$

By defining the **machinery composition log-ratio** as $\tau_t \equiv \ln K^{\text{ME}}_t - \ln K^{\text{NRC}}_t$, this becomes:

$$ k^{\text{cap}}_t = k^{\text{NRC}}_t + \ln(1 + e^{\tau_t}) $$

Taking a first-order Taylor expansion around a mean composition ratio $\bar{\tau}$ demonstrates:

$$ k^{\text{cap}}_t \approx k^{\text{NRC}}_t + s_{\text{ME}} \cdot \tau_t + \text{constant} $$

where $s_{\text{ME}} = \frac{K^{\text{ME}}}{K^{\text{ME}} + K^{\text{NRC}}}$ represents the physical machinery composition share in base-year reference prices.

**Key Structural Insight**: Aggregate log capital ($k^{\text{cap}}$) is mathematically equivalent to the nonresidential plant footprint scale ($k^{\text{NRC}}$) **plus** the composition ratio ($\tau$) scaled by the machinery share ($s_{\text{ME}}$).

---

## 2. Parametric Restrictions Imposed on the Baseline Model

In the Baseline Specification (Specification A), we estimate:
$$ y_t = \alpha + b k^{\text{cap}}_t + f \omega_t + d (k^{\text{cap}}_t \cdot \omega_{t-1}) + u_t $$

Substituting the Taylor approximation $k^{\text{cap}}_t \approx k^{\text{NRC}}_t + s_{\text{ME}} \tau_t$ into this baseline equation reveals the implicit structural restrictions it enforces:

$$ y_t \approx \alpha + b k^{\text{NRC}}_t + (b \cdot s_{\text{ME}}) \tau_t + f \omega_t + d (k^{\text{NRC}}_t \cdot \omega_{t-1}) + (d \cdot s_{\text{ME}}) (\tau_t \cdot \omega_{t-1}) + u_t $$

Estimating the baseline model with a simple aggregate $k^{\text{cap}}_t$ imposes **two strict parametric equality constraints** relative to the heterogeneous capital model (Specification B):

1. **Composition Elasticity Constraint**: The direct capacity payoff of machinery composition ($\psi$) is restricted to be exactly proportional to the scale elasticity: $\psi = b \cdot s_{\text{ME}}$.
2. **State-Dependent Interaction Constraint**: The distributional mediation on machinery composition ($d_{\tau}$) is restricted to be exactly proportional to the scale interaction: $d_{\tau} = d \cdot s_{\text{ME}}$.

These rigid proportionality constraints require that capitalists expand plant scale ($K^{\text{NRC}}$) and machinery ($K^{\text{ME}}$) in strictly balanced proportions without structural shifts in relative marginal productivity. If class struggle ($\omega_{t-1}$) primarily drives the *tactical choice of technique* (accelerating machinery substitution $\tau_t$) while plant scale remains governed by long-run institutional commitments, these parametric constraints will severely bias the estimated elasticity.
