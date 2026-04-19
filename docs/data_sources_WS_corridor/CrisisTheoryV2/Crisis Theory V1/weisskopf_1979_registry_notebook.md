# Weisskopf (1979) Research Notebook Registry

Source text: Thomas E. Weisskopf, *Marxian crisis theory and the rate of profit in the postwar U.S. economy* (1979).

---

## Section I. Imported toggles and imported bindings for the current architecture

This section records which elements from Weisskopf (1979) are worth importing into the current profitability architecture, and whether they should function as baseline structure, binding decomposition logic, or optional analytical toggles.

### I.1 Binding import: technical squeeze criterion inside the productive-capacity block

This is the strongest import from Weisskopf for the present framework.

Current productive-capacity term:

\[
\kappa_t^G = \frac{Y_t^p}{K_t^{gr}} = \frac{a_t^p}{q_t^p}
\]

where:

- \(a_t^p = Y_t^p / L_t^p\) is labour productivity at productive capacity,
- \(q_t^p = K_t^{gr} / L_t^p\) is mechanization or capital intensity at productive capacity.

The key Weisskopf lesson is that rising capital intensity does **not** by itself identify a technically adverse movement for profitability. A technical squeeze exists only when mechanization outruns capacity productivity.

Therefore, the binding criterion is:

\[
\Delta \ln q_t^p > \Delta \ln a_t^p
\quad \Longleftrightarrow \quad
\Delta \ln \kappa_t^G < 0.
\]

Interpretation:

- rising \(q_t^p\) alone is **not** sufficient evidence of a technical squeeze,
- rising \(a_t^p\) may offset or dominate mechanization,
- the relevant technically adverse movement is the fall in \(\kappa_t^G\), not capital deepening by itself.

This should be treated as a **binding interpretive rule** in the decomposition, not as an optional toggle.

### I.2 Optional toggle: internal decomposition of wage share

Baseline distributive term:

\[
\omega_t
\]

Optional internal decomposition:

\[
\omega_t = \frac{w_t^c}{a_t} \cdot \frac{P_{C,t}}{P_{Y,t}}
\]

where:

- \(w_t^c = w_t^N / P_{C,t}\) is the consumption real wage,
- \(a_t = Y_t / L_t\) is labour productivity,
- \(\lambda_t = P_{C,t} / P_{Y,t}\) is the consumption-output price wedge.

Imported Weisskopf interpretation:

- \(w_t^c / a_t\) = offensive labour/distributive real component,
- \(P_C / P_Y\) = defensive inflation-price wedge inside distribution.

This remains a **toggle**, not a binding rule.

### I.3 Optional toggle: domestic-demand vs external corridor inside capacity utilization

Baseline utilization term:

\[
u_t = \frac{Y_t}{Y_t^p}
\]

Optional split:

\[
u_t = \nu_t^{dom} + \nu_t^{ext}
\]

with:

\[
\nu_t^{dom} = \frac{D_t^{dom}}{Y_t^p},
\qquad
\nu_t^{ext} = \frac{TB_t^{(Y)}}{Y_t^p}
\]

and:

\[
TB_t^{(Y)} = \frac{P_{X,t}}{P_{Y,t}} X_t^q - \frac{P_{M,t}}{P_{Y,t}} M_t^q
\]

so that, defining terms of trade as \(\tau_t = P_{X,t}/P_{M,t}\),

\[
\nu_t^{ext} = \frac{P_{M,t}}{P_{Y,t}} \cdot \frac{\tau_t X_t^q - M_t^q}{Y_t^p}.
\]

This remains a **toggle**, not a binding rule.

### I.4 Optional toggle: utilization-correction inside wage share

Weisskopf's overhead-labour correction implies that observed wage share may move mechanically with utilization. The imported abstract form is:

\[
\omega_t = \omega_t^* / \eta_{\omega,t}
\]

where:

- \(\omega_t^*\) is the utilization-corrected or “true” wage share,
- \(\eta_{\omega,t}\) is the utilization-effect term.

Use case:

- useful for short-run cyclical work,
- useful when quasi-fixed labour or overhead labour is important,
- unnecessary in simpler long-run presentations.

This should remain an **optional diagnostic toggle**.

### I.5 Optional toggle: common external-price normalization

Weisskopf uses a numeraire trick to identify a common terms-of-trade channel running through both distribution and capital valuation. In the current framework, this should not replace the clearer baseline wedges:

\[
\lambda_t = \frac{P_C}{P_Y},
\qquad
p_t = \frac{P_Y}{P_K}.
\]

But it can be used as an optional deep-dive device when needed to test whether a shared external-price force is driving both blocks simultaneously.

### I.6 Optional presentation layer: contribution accounting

Baseline structural identity:

\[
r_t = (1-\omega_t)\,u_t\,p_t\,\kappa_t^G\,\nu_t.
\]

Optional reporting layer:

- distributive contribution,
- realization contribution,
- technical-valuation contribution.

This is a presentational tool for results display, not a replacement for the main structural decomposition.

---

## Section II. Weisskopf algebra registry

This section records the paper’s decomposition architecture in sequential order, preserving the logic of its algebraic build-up.

### II.1 Base profit-rate identity

Weisskopf starts from:

\[
p = \frac{\Pi}{K} = \sigma_n \cdot \phi \cdot \zeta
\]

where:

- \(\sigma_n = \Pi / Y\) = profit share,
- \(\phi = Y / Z\) = capacity utilization,
- \(\zeta = Z / K\) = capacity/capital ratio.

Methodological role:

- common identity for all crisis variants,
- each theoretical variant is mapped to one component as the *initial* source of profitability decline.

### II.2 Basic growth-accounting form

The base identity is immediately transformed into:

\[
\dot p = \dot \sigma_n + \dot \phi + \dot \zeta.
\]

This is crucial because it converts an accounting identity into an empirical contribution framework.

### II.3 ROC variant: value formulation

Weisskopf restates the classical Marxian value relations:

\[
g = c/v,
\qquad
e = s/v,
\qquad
r = \frac{s}{c+v} = \frac{e}{g+1}.
\]

This is the value-theoretic background for the ROC variant.

### II.4 ROC variant: price analogue

He translates the ROC logic into price terms:

\[
\gamma = K/W,
\qquad
e = \Pi/W,
\qquad
p = \Pi/K.
\]

Under constant relative shares and utilization, rising \(\gamma\) implies a falling capacity/capital ratio.

### II.5 RSL wage-share decomposition, preliminary form

Weisskopf expresses wage share in terms of money wages, productivity, and prices. In compact notation:

\[
\sigma_w = \frac{W}{Y} = \frac{w/P_y}{y}
\]

so wage share rises when wages outpace productivity and output prices do not fully offset the rise in unit labour cost.

### II.6 Utilization contamination via overhead labour

He distinguishes:

- total labour \(L\),
- direct labour \(L_d\),
- overhead labour \(L_o\).

He then defines:

\[
L = L_d + L_o,
\qquad
L^* = L_d + L_o^*.
\]

From there he constructs:

- a labour-hour requirement ratio \(\eta_\ell\),
- a wage-bill requirement ratio \(\eta_w\),
- a truly required wage bill \(W^*\),
- a true wage share:

\[
\sigma_w^* = \frac{W^*}{Y}.
\]

Observed and true wage share are then linked by:

\[
\sigma_w = \sigma_w^*/\eta_w.
\]

This is one of the paper’s most important corrections.

### II.7 True productivity correction

He similarly defines true productivity:

\[
y^* = \frac{Y}{L^*}
\]

and relates actual to true productivity through the labour-hour requirement ratio:

\[
y = \eta_\ell \, y^*.
\]

This prevents utilization effects from being confused with genuine productivity movements.

### II.8 Offensive versus defensive labour decomposition

Once true wage share is defined, he splits its movement into:

- **offensive labour strength**: rise in \(w^*/y^*\),
- **defensive labour strength**: rise in \(P_w/P_y\).

This is one of the central interpretive decompositions in the paper.

### II.9 Capacity/capital decomposition

He writes the capacity/capital ratio as a real and price decomposition, then corrects it for utilization by introducing an actually utilized capital stock:

\[
J = \phi R.
\]

This is then used to define an actually utilized capital-labour ratio and, after the labour correction, a true capital-labour ratio:

\[
j^* = \frac{J}{L^*}.
\]

### II.10 Technical-composition criterion

The ROC mechanism is not identified merely by \(j^*\) rising. Weisskopf insists that the adverse technical effect requires:

\[
j^* \uparrow
\quad \text{and} \quad
\frac{y^*}{j^*} \downarrow.
\]

This is the key precedent for the binding technical-squeeze rule imported into the current framework.

### II.11 Value-of-capital-price mechanism

He distinguishes a second ROC mechanism, based not on the real technical ratio but on adverse relative prices affecting the value of constant capital. This is what he calls the “value” side of the ROC block.

### II.12 Relative-price normalization

Weisskopf introduces a composite numeraire:

\[
P_x = \sqrt{P_w P_k}
\]

and defines adjusted price variables relative to it. This lets him rewrite the key price effects in terms that reflect:

- the terms of trade,
- the capital/wage-goods price relation.

This is a normalization device for diagnostic purposes.

### II.13 Final master decomposition

He nests the corrected wage-share block, the utilization effect, and the corrected capital block into a single final profit-rate identity. This is the culminating algebraic object of the paper.

### II.14 Final contribution accounting

The master identity is then converted into contribution form:

\[
\dot p = p^\ell + p^r + p^c
\]

where:

- \(p^\ell\) = labour-strength contribution,
- \(p^r\) = realization contribution,
- \(p^c\) = composition-of-capital contribution.

This is the paper’s principal reporting architecture.

---

## Section III. Weisskopf presentation artifact

This section extracts the paper’s method of exposition as a reusable research-presentation template.

### III.1 Taxonomy before evidence

He begins by classifying rival theoretical variants before showing data. This prevents empirical material from becoming theoretically unanchored.

Reusable rule:

- define the object,
- classify rival explanations,
- only then move to evidence.

### III.2 One simple common identity first

Before introducing complexity, he gives the reader a minimal shared identity. This creates a stable baseline for the whole paper.

Reusable rule:

- start with the simplest identity that can host all rival explanations.

### III.3 Map each theory to one initial source of movement

His most effective move is to assign each crisis variant to the *initial* movement of one term of the identity.

Reusable rule:

- do not compare theories at the level of labels,
- compare them by what each claims moves first.

### III.4 Preliminary empirical pass before refinement

He does not jump immediately to the full corrected decomposition. He first runs a preliminary empirical exercise with the crude identity.

Reusable rule:

- do an interpretable first pass,
- then show why it is not yet enough.

### III.5 Ambiguity diagnosis as the transition device

He explicitly states why the first pass is insufficient: the components are not uniquely tied to mechanisms.

Reusable rule:

- move from simple to elaborate decomposition by identifying a specific ambiguity.

### III.6 One refinement at a time

The paper’s refinements are sequenced carefully:

1. utilization effect in wage share,
2. offensive/defensive labour,
3. technical/value capital,
4. relative-price/terms-of-trade effects,
5. limits of the realization block.

Reusable rule:

- each refinement should answer one previously diagnosed ambiguity.

### III.7 Every refinement must become reportable

Conceptual distinctions are not left floating. Each one becomes a variable or contribution term that can be shown in a table.

Reusable rule:

- if a distinction matters theoretically, make it empirically reportable.

### III.8 Nested exposition

The structural flow is:

- simple identity,
- corrected identity,
- master identity,
- contribution accounting.

Reusable rule:

- build layered exposition so the reader climbs the architecture progressively.

### III.9 Theory-driven periodization

He defines cycles and then subdivides each into theoretically meaningful phases A, B, and C, giving special attention to the late expansion when profitability falls before output does.

Reusable rule:

- periodization should follow the mechanism under study, not just calendar convenience.

### III.10 Conclusion as residual research agenda

The paper ends by specifying what its framework cannot yet settle: the role of the state, sources of terms-of-trade deterioration, and finer discrimination inside realization problems.

Reusable rule:

- end with a residual agenda generated by the decomposition itself.

---

## Section IV. Portable template distilled from Weisskopf

This is a reusable skeleton for later research presentation.

1. Define the object to be explained.
2. Build a taxonomy of rival mechanisms.
3. Introduce one simple common identity.
4. Run a preliminary empirical pass.
5. Diagnose the ambiguities of the simple pass.
6. Add one refinement per ambiguity.
7. Consolidate refinements into a master identity.
8. Convert the master identity into contribution accounting.
9. Periodize the evidence according to the mechanism.
10. Close with a residual agenda.

---

## Section V. Immediate implication for the current profitability architecture

The most important imported binding from Weisskopf is the technical-squeeze criterion:

\[
\kappa_t^G = \frac{a_t^p}{q_t^p}
\]

with the rule:

\[
\Delta \ln \kappa_t^G < 0
\quad \Longleftrightarrow \quad
\Delta \ln q_t^p > \Delta \ln a_t^p.
\]

This should be used as the baseline interpretive rule for the technical productive-capacity block.
