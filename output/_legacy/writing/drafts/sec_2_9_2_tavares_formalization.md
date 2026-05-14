# §2.9.2 — Formalization
**Source authority:** `empirical_strategy_peripheral_Ch2_v3.md`
**Date drafted:** 2026-03-29
**Word count:** 506
**Self-check:** PASS
**Transition check:** Closes by noting the structural null η₃^US > η₃^CL is testable — handing off to §2.9.3 (technical composition channel) which develops the mechanism further.

The Tavares channel described in §2.9.1 identifies a structural constraint on the recapitalization rate $\beta_t$ in the periphery, operating through the import content of investment and the availability of foreign exchange. This section gives that constraint formal expression within the behavioral accumulation law.

The key claim is that the recapitalization response to capital productivity — the parameter $\eta_3 = b_3 - 1$ in the behavioral accumulation law of §2.8.1 — is not a free behavioral parameter in the periphery. It is structurally constrained by two forces: the import content of investment $\tilde{\phi}_t^{ME}$ and the external financial conditions summarized by a balance-of-payments proxy $\text{BoP}_t$. Formally,

$$\eta_3^{CL} = \eta_3^{CL}(\tilde{\phi}_t^{ME},\, \text{BoP}_t). \tag{2.18}$$

The import content of investment $\tilde{\phi}_t^{ME}$ is the share of machinery and equipment in gross capital formation that must be sourced from abroad. Disaggregated import data for Chile at the machinery-and-equipment level are not available at annual frequency over the full sample, so the empirical strategy adopts the Kaldor (1959) prior: from the cross-country tabulation in Cuadro 8, the machinery-and-equipment share of capital formation in semi-industrialized economies clusters around $\xi_K^{ME} \approx 0.92$–$0.94$. This value is imposed as an empirical prior, not estimated from unavailable disaggregated data. The balance-of-payments proxy $\text{BoP}_t$ admits several candidate series — the terms of trade, the real exchange rate, or the current-account balance — and the choice among them is an empirical question adjudicated by the Stage B estimation.

Three candidate specifications implement the constraint. The first augments the Chilean ARDL with a foreign-exchange availability proxy, entering $\text{BoP}_t$ directly as an additional regressor in the behavioral accumulation law and testing whether it absorbs part of the $b_3$ channel. The second tests whether the estimated $b_3^{CL}$ is stable across balance-of-payments regimes or breaks at sudden-stop episodes — the preferred implementation is the Hansen and Seo (2002) threshold VECM, in which the balance-of-payments constraint activates as a threshold on $\tilde{\phi}_t^{ME}$ rather than operating linearly throughout the sample. The third compares the unconstrained US estimate $b_3^{US}$ directly against the Chilean estimate $b_3^{CL}$ and tests the structural null:

$$\eta_3^{US} > \eta_3^{CL}. \tag{2.19}$$

The structural null states that the peripheral recapitalization response to capital productivity is more constrained than the center's — that is, Chilean capitalists cannot translate changes in the structural conditions of capital productivity into reinvestment at the rate that US capitalists can, because the foreign-exchange constraint binds the conversion channel.

It is important to distinguish two sources of external constraint that the literature sometimes conflates. The income elasticity of exports $\varepsilon$ — the responsiveness of world demand for Chilean commodities — is an exogenous parameter reflecting the composition of global trade. The import propensity $\pi^m$ is endogenous to the domestic productive structure: it reflects the degree of structural incompleteness of the capital-goods sector. The Kaldor-versus-ECLA fault line turns on whether the external ceiling on accumulation is determined primarily by $\varepsilon$ (the export side, as in Thirlwall) or by $\pi^m$ operating through $\tilde{\phi}_t^{ME}$ (the import-content side, as in Tavares). This is an estimable structural question, and the threshold-VECM specification is designed to adjudicate it. The next subsection traces the implications of over-mechanization for this constraint.
