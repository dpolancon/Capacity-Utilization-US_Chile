---
type: theory
status: pending_resolution
depends_on:
  - chapter2_vault/02_analyitical_foundation/A04_PeripheralTransformationElasticity.md
  - chapter2_vault/03_econometrics/E_00_I2_Trap.md
stage_scope: S10-S90
country: CL
last_updated: 2026-07-23
subtype: analytical_resolution_note
blocks: []
layer: theory
scope: chapter2
priority: reference
---

# A06: Pending Resolution for Chilean 3-Way Orthogonalization

## The Analytical Problem

The peripheral model (`A04`) introduces an external wedge $z_t$ (proxying foreign exchange availability $\phi_t$) that gates the conversion of accounting surplus into real machinery accumulation. 

The raw econometric specification tests this external bottleneck through a 3-way interaction between physical scale ($k_t$), class distribution ($\omega_t$), and the external wedge ($z_t$):
$$ \text{Raw 3-way interaction} = (k_t \cdot \omega_t \cdot z_t) $$

However, standard integration-order protocols and the Frisch-Waugh-Lovell (FWL) theorem mandate that interaction terms constructed from $I(1)$ base variables be orthogonalized (residual-centered) against their linear components to avoid the $I(2)$ trap and severe multicollinearity (`E_00_I2_Trap`).

## The Resolution Target

A rigorous orthogonalization filter must be defined for the Chilean specification. The open questions to resolve are:

1.  **Statistical Filter Scope:** Must the 3-way interaction $(k_t \cdot \omega_t \cdot z_t)$ be residualized against *all* constituent linear terms ($k_t, \omega_t, z_t$) AND all intermediate 2-way interactions ($(k_t \omega_t), (k_t z_t), (\omega_t z_t)$)?
2.  **Economic Interpretation:** How does this statistical filtering impact the economic interpretation of the peripheral capacity bottleneck constraint? Does partialing out the 2-way interactions over-filter the structural mechanism described by structuralist dependency theory?
3.  **Nomenclature:** The final orthogonalized residual will be denoted as $\hat{u}^{(k,\omega,z)}_{pending, t}$ in the outline until the exact auxiliary regression is formally specified and locked.

## Next Steps
- Establish the exact auxiliary OLS regression(s) required to safely orthogonalize Specification C without destroying the structural variance.
- Lock the specification under the `E10V` regime.
