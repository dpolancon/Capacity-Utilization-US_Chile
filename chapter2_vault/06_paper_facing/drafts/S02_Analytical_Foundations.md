---
type: paper_facing
section_id: S02
title: 'Section 2: The Micro-Meso Hinge: Okishio, Vidal, and the Analytical Foundations of Capacity Formation'
status: draft
authority_files:
  - '[[Ch2_Outline_DEFINITIVE]]'
  - '[[00E_Chapter2_PaperFacing_Constitution]]'
  - '[[00N_Chapter2_PaperFacing_MAP]]'
analytical_foundations:
  - '[[A01_Extensive_Accumulation]]'
  - '[[A02_Intensive_Accumulation]]'
  - '[[A03_TransformationElasticity_Two-CapitalCapacityComposition]]'
  - '[[A05_NRCEnvelope_MechanizationBias]]'
  - '[[H00_Okishio_Vidal_Decentralized_Accumulation]]'
  - '[[H01_Cajas_to_Transformation_Elasticity]]'
  - '[[R05_Frontier_of_Not_Becoming]]'
audit_reference:
  - '[[2026-07-24_capital_integration_cointegration_handoff]]'
created: 2026-07-24
subtype: paper_draft_section
status_detail: draft_for_review
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: context
---

# Section 2: The Micro-Meso Hinge: Okishio, Vidal, and the Analytical Foundations of Capacity Formation

> [!NOTE]
> **Obsidian Review Interface (Pass 1):** This note represents the back-end Markdown draft for Section 2 of Chapter 2. It integrates the theoretical micro-meso synthesis of Okishio market anarchy and Vidal divided-firm dynamics with the formal two-capital baseline model of cost-efficient mechanization. Empirical specifications are directly anchored in the cointegration audit [[2026-07-24_capital_integration_cointegration_handoff]].

---

## 2.1 Decentralized Accumulation and Market Anarchy (Okishio)

Heterodox growth models routinely deploy capacity utilization as an adjusting macro variable, yet they frequently treat the firm as a unified optimization unit capable of targeting a stable, "normal" degree of utilization. Once capital accumulation is analyzed as a decentralized process under market anarchy, this assumption breaks down.

As established by [[Okishio1961]] and [[Okishio2022]] (and articulated in [[H00_Okishio_Vidal_Decentralized_Accumulation]]), capitalist accumulation is characterized by investment decentralization. Individual capitals commit sunk fixed investments without ex-ante coordination. The validation of capacity expansion occurs strictly ex-post through market realization:

1. **Uncoordinated Investment & Disproportionality:** Decisions to expand capacity in capital-goods sectors versus consumer-goods sectors are made independently based on partial, backward-looking price signals.
2. **The Timing Failure of Prices:** Market prices register imbalances only after fixed capital commitments have already been sunk. Relative prices arrive too late to coordinate capacity formation, resulting in recurring sectoral disproportionalities.
3. **Chronic Idle Capacity:** Under decentralized accumulation, idle capacity is not an accidental friction or an exogenous demand shock. It is the necessary structural form through which market anarchy manifests at the macro level.

However, Okishio's macro framework leaves a fundamental organizational gap: it implicitly treats firms as coherent, friction-free units that respond systematically to profit signals, ignoring the internal organizational contradictions that govern the actual operation of equipment on the shop floor.

---

## 2.2 The Internally Divided Firm (Vidal)

To close this macro-micro gap, we integrate Vidal's (2022) theory of the internally divided firm (see [[H00_Okishio_Vidal_Decentralized_Accumulation]]). Capitalist firms do not operate as coherent, single-minded production functions. Rather, the firm is an internally divided social organization fractured by the constitutive contradiction between **valorization** (the extraction of surplus-value) and the **labor process** (the technical coordination of cooperative work):

> [!IMPORTANT]
> **The Valorization–Labor Process Contradiction:** Management faces contradictory imperatives. To maximize valorization, management must standardize, monitor, and intensify labor. But to maintain the technical workflow productivity on which surplus depends, management must also rely on worker discretion, tacit knowledge, and problem-solving capacities.

This organizational fracture unfolds across three shop-floor dynamics:

- **Contradictory Managerial Imperatives:** Management cannot optimize both control and cooperation simultaneously. Standardization reduces supervisory costs but eliminates worker discretion needed to resolve operational bottlenecks.
- **Labor Resistance and Effort Calibration:** Workers observe managerial contradictions and quietly calibrate their effort, cooperation, and machine operating speeds. Labor effort is not a fixed technical parameter but a contested social outcome.
- **Contested Capacity Conventions ("Mediocre Sufficiency"):** Physical "capacity" is not a neutral physical constant. It is a contested accounting convention and shop-floor settlement. Firms settle into organizational configurations of *"mediocre sufficiency"* [[Vidal2022]], institutionalizing structural gaps between engineering potential and operational output.

---

## 2.3 Formal Baseline Analytical Model: Two-Capital Accumulation and Technique Choice

We now formalize these micro-meso foundations into a two-capital model of capacity formation, operationalizing the distinction between extensive plant expansion ($K^{\text{NRC}}$) and intensive mechanization choice ($K^{\text{ME}}$), grounded in [[A01_Extensive_Accumulation]], [[A02_Intensive_Accumulation]], [[A03_TransformationElasticity_Two-CapitalCapacityComposition]], and [[H01_Cajas_to_Transformation_Elasticity]].

### 2.3.1 Ontological Guardrail: Benchmark of "Not Becoming" vs. Historical "Becoming"

Following the ontological protocol of Basu (2022) and [[R05_Frontier_of_Not_Becoming]], the formal optimization problem derived below **does not assume** a representative profit-maximizing firm operating in a frictionless environment. 

Instead, formal cost-surplus optimization defines the **smooth reproduction benchmark** ($q^*, a^N$)---the theoretical abstraction of **"not becoming."** Historical realization (**"becoming"**) is scarred by Okishio's market anarchy, Vidal's shop-floor effort bargaining, and external realization bottlenecks. The gap between historical labor productivity $a_t$ and normal productivity $a^N$, as well as utilization gaps $\mu_t = Y_t / Y_t^p \neq 1$, represent the empirical fingerprints of capitalist contradiction.

### 2.3.2 The Extensive Margin: Nonresidential Structures Envelope

Accumulation unfolds across two distinct capital assets: nonresidential structures and infrastructure ($K^{\text{NRC}}$), and machinery and equipment ($K^{\text{ME}}$). 

The extensive margin $K^{\text{NRC}}$ defines the physical plant scale, logistical ceiling, and spatial envelope $\Gamma(K^{\text{NRC}})$, per [[A01_Extensive_Accumulation]]. Structures require multi-year planning and heavy sunk commitments, evolving along a normal reproduction path:

$$ g_{K^{\text{NRC}}, t}^N = \chi^N r_t^N - \delta^{\text{NRC}} $$

where $\chi^N$ is the normal recapitalization rate and $r_t^N$ is normal profitability. Because structural plant commitments filter out short-run cyclical fluctuations, the extensive envelope satisfies the **independence property**:

$$ \frac{\partial K^{\text{NRC}}}{\partial \omega} = 0 $$

Short-run wage bargaining ($\omega$) does not alter the structural physical plant envelope; distribution conditions accumulation strictly through the intensive tactical choice of machinery.

### 2.3.3 The Intensive Margin: Tactical Choice of Technique and Cost Minimization

Within the infrastructural envelope $\Gamma(K^{\text{NRC}})$, firms choose the mechanization rate $q = K^{\text{ME}}/L$ (machinery per worker) to maximize net productivity surplus (or minimize unit production cost under distributive pressure), per [[A02_Intensive_Accumulation]].

Let $a = Y/L$ represent labor productivity, $\omega$ the wage share, and $\pi = 1 - \omega$ the nominal profit share. The effective distributive cost of deploying machinery per worker is $q\pi$. The firm solves the tactical optimization problem:

$$ \max_{q} \ c(q) = a - q\pi $$

subject to the regime-conditioned technological frontier $\Phi(q; K^{\text{NRC}})$:

$$ a = \Phi(q; K^{\text{NRC}}) = \lambda_0^{[s]} + \lambda_1^{[s]} q + \lambda_2^{[s]} q^2 $$

The frontier parameters obey structural constraints:
- $\lambda_0^{[s]} > 0$: Base productivity anchored by the infrastructural envelope $K^{\text{NRC}}$.
- $\lambda_1^{[s]} > 0$: Linear productivity payoff of machinery intensity.
- $\lambda_2^{[s]} < 0$: Concavity condition enforcing **decreasing returns to mechanization**.

Importantly, $\frac{\partial \lambda_i^{[s]}}{\partial \omega} = 0$; the frontier parameters are structurally determined within institutional regime $s$ and do not shift distributively.

Substituting the technological frontier into the objective function yields the unconstrained tactical problem:

$$ c(q) = \lambda_0^{[s]} + \left[ \lambda_1^{[s]} - \pi \right] q + \lambda_2^{[s]} q^2 $$

The **First-Order Condition (FOC)** for optimal mechanization requires:

$$ \frac{dc}{dq} = \lambda_1^{[s]} - \pi + 2\lambda_2^{[s]} q^* = 0 $$

Solving for the optimal mechanization rate $q^*$ gives:

$$ q^*(\pi, s) = \frac{\pi - \lambda_1^{[s]}}{2\lambda_2^{[s]}} $$

The **Second-Order Condition (SOC)** $c''(q) = 2\lambda_2^{[s]} < 0$ is strictly satisfied by the concavity parameter $\lambda_2^{[s]} < 0$, guaranteeing a unique, stable maximum.

Differentiating $q^*$ with respect to the profit share $\pi$ establishes the **induced innovation mechanism**:

$$ \frac{\partial q^*}{\partial \pi} = \frac{1}{2\lambda_2^{[s]}} < 0 \quad \implies \quad \frac{\partial q^*}{\partial \omega} = -\frac{1}{2\lambda_2^{[s]}} > 0 $$

This proves that a squeeze in the profit share ($\pi \downarrow$, or equivalently a rise in the wage share $\omega \uparrow$) compels cost-minimizing firms to substitute machinery for labor, elevating the optimal mechanization intensity $q^*$.

Substituting $q^*$ back into the technological frontier recovers the **normal rate of labor productivity** under smooth reproduction:

$$ a^N(\pi, s) = \lambda_0^{[s]} + \lambda_1^{[s]} q^*(\pi, s) + \lambda_2^{[s]} \left[ q^*(\pi, s) \right]^2 $$

### 2.3.4 Two-Capital Capacity Composition and Transformation Elasticity

Integrating the extensive plant envelope with the intensive choice of technique yields the aggregate potential capacity identity [[A03_TransformationElasticity_Two-CapitalCapacityComposition]]:

$$ Y^p = \frac{a^N(\pi, s)}{q^*(\pi, s)} K^{\text{ME}} + \Gamma(K^{\text{NRC}}) $$

Define the machinery capacity payoff as $\theta^{\text{ME}}(\pi, s) = \frac{a^N}{q^*} = \frac{\lambda_0^{[s]}}{q^*} + \lambda_1^{[s]} + \lambda_2^{[s]} q^*$ and the structural plant payoff as $\theta^{\text{NRC}} = \frac{\partial \ln \Gamma(K^{\text{NRC}})}{\partial \ln K^{\text{NRC}}}$.

The composition-weighted transformation elasticity $\theta^N(\pi, s)$ measures how aggregate productive capital accumulation translates into potential output expansion:

$$ \theta^N(\pi, s) = \frac{\theta^{\text{NRC}}(1-s) g_{K^{\text{NRC}}} + \theta^{\text{ME}}(\pi, s) s g_{K^{\text{ME}}}}{(1-s) g_{K^{\text{NRC}}} + s g_{K^{\text{ME}}}} $$

where $s = K^{\text{ME}} / (K^{\text{ME}} + K^{\text{NRC}})$ is the physical capital composition share evaluated in base-year constant reference prices ($P_r^j = 1$). 

As derived in [[H01_Cajas_to_Transformation_Elasticity]], when accumulation is machinery-dominated ($s \to 1$), the transformation elasticity converges to the traditional productivity-mechanization gap formulation $b = a^N - q^*$:

$$ \theta^N \approx \theta^{\text{ME}} = 1 + \frac{a^N - q^*}{q^*} \approx 1 + \frac{b}{g_K^N} $$

This proves that the productivity-mechanization gap $b$ is the intensive-margin limiting case of the two-capital transformation elasticity $\theta^N$.

> [!CAUTION]
> **Empirical Specification Bridge:** While $q^*$ and $a^N$ provide the smooth reproduction benchmark, raw $q_t = K^{\text{ME}}/L$ and accumulated path proxies $Q_t^\omega$ are demoted per [[2026-07-24_capital_integration_cointegration_handoff]]. The admissible empirical proxy for $s_t$ is the centered log composition ratio $\tau_t = \ln K^{\text{ME}}_t - \ln K^{\text{NRC}}_t$, entering via Frisch-Waugh-Lovell (FWL) residual-centered Specification $D_9$.

### 2.3.5 Macro Disequilibrium and Profitability Ceilings

Because actual shop-floor effort (Vidal) and uncoordinated investment (Okishio) cause historical labor productivity $a_t$ to diverge from $a^N(\pi, s)$, observed output $Y_t$ diverges from capacity $Y_t^p$.

Capacity utilization $\mu_t = Y_t / Y_t^p$ acts as the structural transmission mechanism shaping the upper ceiling of historical profitability via the Weisskopf decomposition:

$$ r_t = \mu_t b_t \pi_t $$

where $b_t = Y_t^p / K_t$ is maximum capital productivity. Capacity utilization $\mu_t$ is not a firm-level behavioral constant or target, but a socially mediated macro ceiling that regulates the long-run rate of profit.

---

## 2.4 Summary of Locked Analytical Properties

1. **Separation of Margins:** $K^{\text{NRC}}$ sets the structural envelope independent of short-run distribution ($\frac{\partial K^{\text{NRC}}}{\partial \omega} = 0$). Distribution conditions accumulation strictly through $K^{\text{ME}}$ mechanization choice.
2. **Decreasing Returns:** Concavity ($\lambda_2^{[s]} < 0$) ensures a unique interior optimal mechanization rate $q^*(\pi, s)$.
3. **Induced Innovation:** Profit squeeze ($\pi \downarrow \implies \omega \uparrow$) drives cost-minimizing firms to elevate mechanization ($q^* \uparrow$).
4. **Gap Equivalence:** The aggregate transformation elasticity $\theta^N$ converges to the traditional gap payoff ($1 + b/g_K^N$) under machinery-dominated accumulation ($s \to 1$).
5. **Ontological Distinction:** $q^*$ and $a^N$ represent the smooth reproduction limit of "not becoming." Historical utilization gaps $\mu_t \neq 1$ measure the reality of capitalist "becoming."
