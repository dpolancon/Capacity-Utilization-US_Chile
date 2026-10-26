# EXP_01 Active Integration Change Ledger

**Document:** `section5.tex`  
**Baseline Reference:** `_editing_ai_detrace/phase2_exp01_section5/01_BASELINE_SECTION5.tex`  
**Active Manuscript:** `section5.tex`  
**Pre-Integration SHA-256:** `F01541AC68F9816E61D93B7CA6E530603569C961D8588C345147506420F67443`  
**Post-Integration SHA-256:** `22CC24891C934D2B27503E3E06F7F683C6910535AB338904A3BB6163FFA01387`  
**Date:** 2026-09-30  

---

## 1. Summary of Integrated Scope

Integration applied candidate prose from `02_CANDIDATE_SECTION5.tex` to the active manuscript with approved human amendments for `CH2-S05-P004`, `CH2-S05-P006`, `CH2-S05-P012`, and the heading immediately preceding P012.

Word counts are reported as cleaned prose counts (LaTeX commands, formatting wrappers, and math delimiters stripped) alongside raw whitespace-split token counts in parentheses.

**Total target-paragraph cleaned words:** 1118 → 947 (-171 words; -15.3%)  
*(Raw tokens: 1145 → 974; -171 tokens; -14.9%)*

### Integration Summary Table

| ID | Line | Status | Baseline Words | Integrated Words | Δ Words | Δ % | Citations | Numbers | Math | Causal Dir. | Uncertainty | Operation & Amendments |
|---|---:|---|---:|---:|---:|---:|:---:|:---:|:---:|:---:|:---:|---|
| **CH2-S05-P001** | 4 | COMPRESS | 90 (89) | 69 (68) | -21 (-21) | -23.3% | PASS (0/0) | PASS (1/1) | PASS (2/2) | PASS | PASS | Candidate accepted exactly as approved: removed repeated baseline/mismatch framing. |
| **CH2-S05-P002** | 6 | COMPRESS | 93 (97) | 62 (66) | -31 (-31) | -33.3% | PASS (0/0) | PASS (1/1) | PASS (2/2) | PASS | PASS | Candidate accepted exactly as approved: deleted section announcement roadmap. |
| **CH2-S05-P004** | 21 | REWRITE | 193 (196) | 174 (177) | -19 (-19) | -9.8% | PASS (0/0) | PASS (8/8) | PASS (5/5) | PASS | PASS | Candidate accepted with 3 human amendments: removed "directly", changed "severe macro-historical trough" to "macroeconomic trough", changed "radically divergent" to "divergent". |
| **CH2-S05-P006** | 26 | REWRITE | 241 (249) | 218 (226) | -23 (-23) | -9.5% | PASS (5/5) | PASS (14/14) | PASS (8/8) | PASS | PASS | Candidate accepted with human revision: FRB series identification statement and post-Fordist intangible-asset closing. |
| **CH2-S05-P008** | 31 | COMPRESS | 248 (257) | 218 (227) | -30 (-30) | -12.1% | PASS (1/1) | PASS (16/16) | PASS (3/3) | PASS | PASS | Candidate accepted exactly as approved: condensed repeated intensifiers, preserved dual strangulation. |
| **CH2-S05-P010** | 35 | COMPRESS | 159 (163) | 133 (137) | -26 (-26) | -16.4% | PASS (0/0) | PASS (2/2) | PASS (2/2) | PASS | PASS | Candidate accepted exactly as approved: compressed threshold caveat and fixed syntax. |
| **Heading** | 37 | HEADING | 8 (8) | 8 (8) | 0 (0) | 0.0% | PASS | PASS | PASS | PASS | PASS | Heading retitled: `\paragraph{Synthesis: Dead Labour Across the Global Divide.}` |
| **CH2-S05-P012** | 40 | REWRITE | 94 (94) | 73 (73) | -21 (-21) | -22.3% | PASS (0/0) | PASS (0/0) | PASS (0/0) | PASS | PASS | Approved human formulation integrated: classical political economy synthesis, removed competing metaphors. |

---

## 2. Paragraph-by-Paragraph Integration Record

### CH2-S05-P001 (Line 4)
- **Baseline:** `Section~4 established a structural baseline: the transformation elasticity $\theta_t$ sits strictly below unity in both the center and the periphery. Capitalist accumulation exhibits a persistent tendency toward overaccumulation—understood within a single-sector framework as a structural disproportionality between capital accumulation and its transformation into productive capacity. This structural mismatch yields systemic disequilibrium and chronic idle capacity as an enduring byproduct. However, the engine that converts accumulated capital into potential capacity represents only the supply-side dimension of this process; its macroeconomic realization remains mediated through the rate of capacity utilization ($\mu_t$).`
- **Integrated:** `Section~4 established that the transformation elasticity $\theta_t$ sits strictly below unity in both the center and the periphery. Within a single-sector framework, the persistent tendency toward overaccumulation is a structural disproportionality between capital accumulation and its transformation into productive capacity, yielding systemic disequilibrium and chronic idle capacity. Capacity formation is the supply-side dimension of this process; its macroeconomic realization remains mediated through the rate of capacity utilization ($\mu_t$).`
- **Cleaned words:** 90 → 69 (-21 words; -23.3%)
- **Raw tokens:** 89 → 68 (-21 tokens; -23.6%)
- **Integration action:** Candidate accepted verbatim without further modification.

---

### CH2-S05-P002 (Line 6)
- **Baseline:** `While $\theta < 1$ is the shared premise of unbalanced growth, the historical trajectories of $\mu_t$ reveal fundamentally distinct crisis formations across the global divide. In the United States, utilization crises stem from the exhaustion of institutional class compromises and the failure of effective demand. In Chile, stagnation and crisis originate in the external truncation of capital-import capacity and the physical strangulation of the productive apparatus. By placing the implicit capacity utilization rates of both economies on a single comparative axis, this section traces how the same underlying condition of overaccumulation manifests as two divergent political-economic realities.`
- **Integrated:** `While $\theta < 1$ is the shared premise of unbalanced growth, the historical trajectories of $\mu_t$ reveal fundamentally distinct crisis formations across the global divide. In the United States, utilization crises stem from the exhaustion of institutional class compromises and the failure of effective demand. In Chile, stagnation and crisis originate in the external truncation of capital-import capacity and the physical strangulation of the productive apparatus.`
- **Cleaned words:** 93 → 62 (-31 words; -33.3%)
- **Raw tokens:** 97 → 66 (-31 tokens; -32.0%)
- **Integration action:** Candidate accepted verbatim without further modification.

---

### CH2-S05-P004 (Line 21)
- **Baseline:** `The visual narrative of Figure~\ref{fig:sec5_combined_mu} yields several immediate conclusions. First, neither economy converges toward a normal rate of utilization in the long run ($\mu = 100\%$); persistent idle capacity remains the structural norm of decentralized accumulation. Second, the volatility of $\mu_t$ in Chile vastly exceeds that of the United States. Rather than an econometric anomaly, this higher amplitude directly tracks the structural asymmetry between a diversified, reserve-currency center capable of dampening demand swings, and a dependent peripheral formation vulnerable to sudden international liquidity collapses. Because installed gross fixed capital ($K_t$) represents an immovable physical envelope that cannot vanish during downturns, catastrophic peripheral output collapses—such as the supply shocks of 1975 and the 1982 debt crisis—translate into violent, vertical contractions of utilization. Crucially, the shaded window (1979--1985) captures a global overaccumulation crisis and structural turning point: the Volcker interest-rate shock triggered a severe domestic realization drop in the center ($\mu_{1982} \approx 82\%$) while violently terminating Chile's debt-led boom ($\mu_{1981} = 100\%$), plunging peripheral utilization into a severe macro-historical trough. This global conjuncture was subsequently resolved through radically divergent regime shifts: debt-led financialization in the center, and a violent transition toward neoliberalization and external subordination in the periphery.`
- **Integrated:** `Neither economy in Figure~\ref{fig:sec5_combined_mu} converges toward a normal rate of utilization in the long run ($\mu = 100\%$); persistent idle capacity remains the structural norm of decentralized accumulation. The volatility of $\mu_t$ in Chile vastly exceeds that of the United States. This higher amplitude tracks the structural asymmetry between a diversified, reserve-currency center capable of dampening demand swings and a dependent periphery vulnerable to sudden international liquidity collapses; it is not an econometric anomaly. Installed gross fixed capital ($K_t$) cannot vanish during downturns, so peripheral output collapses, such as the supply shocks of 1975 and the 1982 debt crisis, translate into abrupt contractions of utilization. The shaded window (1979--1985) captures a global overaccumulation crisis and structural turning point: the Volcker interest-rate shock triggered a severe domestic realization drop in the center ($\mu_{1982} \approx 82\%$) while ending Chile's debt-led boom ($\mu_{1981} = 100\%$) and driving peripheral utilization into a macroeconomic trough. This common conjuncture was subsequently resolved through divergent regime shifts: debt-led financialization in the center, and a violent transition toward neoliberalization and external subordination in the periphery.`
- **Cleaned words:** 193 → 174 (-19 words; -9.8%)
- **Raw tokens:** 196 → 177 (-19 tokens; -9.7%)
- **Integration action:** Candidate accepted with three approved human amendments:
  1. Replaced `"This higher amplitude directly tracks"` with `"This higher amplitude tracks"`.
  2. Replaced `"severe macro-historical trough"` with `"macroeconomic trough"`.
  3. Replaced `"radically divergent regime shifts"` with `"divergent regime shifts"`.

---

### CH2-S05-P006 (Line 26)
- **Baseline:** `When the profit squeeze emerged in the late 1960s, $\mu_t$ plummeted to 76.2\% in 1975 and bottomed at 74.1\% in 1982 during the Volcker disinflation. In his seminal decomposition of this postwar U.S. profit rate collapse, \citet{Weisskopf1979} pinned the crisis on the ``Rising Strength of Labor'' (RSL), treating the ``Realization Failure'' (RF) variant—a drop in $\mu_t$—as a secondary, survey-driven symptom. Our framework upgrades this insight by revealing that the Federal Reserve Board data black-boxed the physical conversion of accumulation into capacity. Here, $\mu_t$ is evaluated as an endogenous residual of $\theta_t$. The Fordist profit squeeze was not just a distributional fight over a fixed pie; it was a structural breakdown in $\theta_t$ itself. When effective wage pressure peaked, $\theta_t$ collapsed to 0.32. The subsequent plunge in $\mu_t$ was the direct macroeconomic footprint of that distributive conflict degrading the capacity-generating power of capital. Post-Fordism dismantled the institutional foundations of wage-led growth to resolve this crisis. Through deunionization and wage suppression, the capitalist class successfully restored profitability. Nevertheless, this structural wage suppression fundamentally undermined the domestic realization of productive capacity over the long run, an effect only partially offset by debt-led consumption \citep{Stockhammer2012,Vidal2019}. Average utilization failed to permanently re-anchor to its Fordist peaks, breaching the 100\% benchmark temporarily only during the speculative tech-investment bubble of 2000 ($\mu_{2000} \approx 103\%$). The center's idle capacity stands as a monument to the long-term dynamics of secular stagnation in the aftermath of financialization and its mutation toward the paramount accumulation of intangible assets \citep{Rikap2021, Rotta2018}.`
- **Integrated:** `When the profit squeeze emerged in the late 1960s, $\mu_t$ fell to 76.2\% in 1975 and bottomed at 74.1\% in 1982 during the Volcker disinflation. In his decomposition of this postwar U.S. profit rate collapse, \citet{Weisskopf1979} pinned the crisis on the ``Rising Strength of Labor'' (RSL), treating the ``Realization Failure'' (RF) variant—a drop in $\mu_t$—as a secondary, survey-driven symptom. The Federal Reserve Board utilization series does not identify the physical conversion of accumulation into capacity. Here, $\mu_t$ is instead recovered as an endogenous residual of $\theta_t$. The Fordist profit squeeze was not just a distributional fight over a fixed pie; it was a structural breakdown in $\theta_t$ itself. When effective wage pressure peaked, $\theta_t$ fell to 0.32. The subsequent fall in $\mu_t$ directly reflected that distributive conflict degrading the capacity-generating power of capital. Post-Fordism dismantled the institutional foundations of wage-led growth to resolve this crisis. The capitalist class restored profitability through deunionization and wage suppression. This structural wage suppression nevertheless fundamentally undermined the domestic realization of productive capacity over the long run, an effect only partially offset by debt-led consumption \citep{Stockhammer2012,Vidal2019}. Average utilization failed to return permanently to its Fordist peaks, exceeding the 100\% benchmark temporarily only during the speculative tech-investment bubble of 2000 ($\mu_{2000} \approx 103\%$). Persistent idle capacity therefore accompanies the post-Fordist shift toward financialization and the growing weight of intangible-asset accumulation \citep{Rikap2021, Rotta2018}.`
- **Cleaned words:** 241 → 218 (-23 words; -9.5%)
- **Raw tokens:** 249 → 226 (-23 tokens; -9.2%)
- **Integration action:** Candidate accepted with two approved human revisions:
  1. Replaced unexamined/residual sentences with: `"The Federal Reserve Board utilization series does not identify the physical conversion of accumulation into capacity. Here, $\mu_t$ is instead recovered as an endogenous residual of $\theta_t$."`
  2. Replaced closing secular stagnation formulation with: `"Persistent idle capacity therefore accompanies the post-Fordist shift toward financialization and the growing weight of intangible-asset accumulation \citep{Rikap2021, Rotta2018}."`

---

### CH2-S05-P008 (Line 31)
- **Baseline:** `In a closed economy, the 20-percentage-point surge in the gross wage share---pushing it from roughly 49\% in 1970 to a historical peak of 69.03\% in 1972---would have simply induced rapid labor-saving mechanization. In the context of peripheral capitalism, however, the internal profit squeeze and the external balance-of-payments constraint locked together. The threshold cointegrating model formalizes precisely why this distributive explosion failed to induce mechanization: as the distributive impulse surged, the composite balance-of-payments index plunged deep into the binding domain ($Z_t = -1.06 < \hat{\gamma} = 0.425$). This external constraint effectively truncated the choice of technique. Peripheral capitalists retained the microeconomic incentive to substitute machinery for labor but lost the macroeconomic means to do so. The very success of the working class in capturing a larger share of the surplus increased the import demand for wage-goods, which in turn starved the economy of the foreign exchange required to import capital goods. The macroeconomic cost of this ``dual strangulation'' is visible in the violent reversal of capacity utilization. When the \textit{Unidad Popular} assumed power, $\mu_t$ operated at a constrained baseline of 94.1\% in 1969. The initial redistributive boom drove $\mu_t$ to an unsustainable cyclical peak of 98.4\% in 1971. Stripped of the foreign exchange required to import machinery---exacerbated by credit blockades, capital flight, and the 1972 bosses' lockout \citep{DeVylder1976}---the economy shed more than 26 percentage points of utilization in just four years, plunging to roughly 72\% by 1975. The unconverted distributive surplus manifested as a blocked surplus, generating structural inflation and severe supply bottlenecks rather than expanding productive capacity.`
- **Integrated:** `In a closed economy, the 20-percentage-point rise in the gross wage share---from roughly 49\% in 1970 to a historical peak of 69.03\% in 1972---would have simply induced rapid labor-saving mechanization. In peripheral capitalism, however, the internal profit squeeze and the external balance-of-payments constraint locked together. The threshold cointegrating model formalizes why this distributive impulse failed to induce mechanization: as it rose, the composite balance-of-payments index fell deep into the binding domain ($Z_t = -1.06 < \hat{\gamma} = 0.425$). The external constraint truncated the choice of technique: peripheral capitalists retained the microeconomic incentive to substitute machinery for labor but lost the macroeconomic means. The working class's success in capturing a larger share of the surplus increased import demand for wage-goods, leaving insufficient foreign exchange to import capital goods. The cost of this ``dual strangulation'' appears in capacity utilization. When the \textit{Unidad Popular} assumed power, $\mu_t$ operated at a constrained baseline of 94.1\% in 1969. The initial redistributive boom drove $\mu_t$ to an unsustainable cyclical peak of 98.4\% in 1971. Deprived of the foreign exchange required to import machinery---exacerbated by credit blockades, capital flight, and the 1972 bosses' lockout \citep{DeVylder1976}---the economy lost more than 26 percentage points of utilization in just four years, reaching roughly 72\% by 1975. The unconverted distributive surplus manifested as a blocked surplus, generating structural inflation and severe supply bottlenecks rather than expanding productive capacity.`
- **Cleaned words:** 248 → 218 (-30 words; -12.1%)
- **Raw tokens:** 257 → 227 (-30 tokens; -11.7%)
- **Integration action:** Candidate accepted verbatim without further modification.

---

### CH2-S05-P010 (Line 35)
- **Baseline:** `A methodological caveat is in order regarding the threshold classification. The composite index $Z_t$ and the threshold $\hat{\gamma} = 0.425$ are estimated via a deterministic hard classification. This does not model smooth, probabilistic regime shifts; rather, it acts as a binary gate capturing the frequency with which the constraint binds. It effectively captures the ``stop-go'' shocks of the ISI era and the intra-cycle tightness of the 2000s mining boom, rather than positing a single, clean macro-historical break but without a granularly identification within regimes. Future research requires backward and forward extension of time-series, and exploring other econometrics techniques such as Markov-switching modelling to assign a time-varying threshold for the regime classification . Even within these bounds, however, the hard classification robustly captures the core structural reality: in the periphery, the transformation of accumulation into capacity is discretely severed whenever external solvency collapses. Applying this double-constraint metric to comparative panel datasets across other commodity-dependent or semi-peripheral spaces represents a promising avenue for future research.`
- **Integrated:** `The composite index $Z_t$ and the threshold $\hat{\gamma} = 0.425$ are estimated via a deterministic hard classification. This binary gate captures the frequency with which the constraint binds, not smooth, probabilistic regime shifts. It captures the ``stop-go'' shocks of the ISI era and the intra-cycle tightness of the 2000s mining boom rather than positing a single macro-historical break, but does not provide granular identification within regimes. Within these limits, the classification captures the discrete severing of the transformation of accumulation into capacity whenever external solvency collapses in the periphery. Future research requires backward and forward extension of time-series and exploration of other econometric techniques, such as Markov-switching modelling, to assign a time-varying threshold for regime classification. Applying this double-constraint metric to comparative panel datasets across other commodity-dependent or semi-peripheral spaces remains a promising avenue for future research.`
- **Cleaned words:** 159 → 133 (-26 words; -16.4%)
- **Raw tokens:** 163 → 137 (-26 tokens; -16.0%)
- **Integration action:** Candidate accepted verbatim without further modification.

---

### Heading Immediately Preceding P012 (Line 37)
- **Baseline:** `\paragraph{Synthesis: Scar Tissue of the Global Divide.}`
- **Integrated:** `\paragraph{Synthesis: Dead Labour Across the Global Divide.}`
- **Cleaned words:** 8 → 8 (0 words; 0.0%)
- **Integration action:** Re-titled as authorized. Eliminates the lingering "scar tissue" metaphor from the section structure, aligning the heading with the classical political economy framing of the synthesis paragraph.

---

### CH2-S05-P012 (Line 40)
- **Baseline:** `Ultimately, the dead labour embedded in under-utilized productive capacities speaks a distinct language across the scar tissue of the global divide. As crystallized past labour denied the living labour necessary for its valorization, this idle fixed capital represents the past labour of an accumulation regime too frail to sustain its own reproduction. In the center, it stands as a monument to a domestic social contract dismantled in the name of profitability and financialized rent extraction; in the periphery, it remains the quiet casualty of an asymmetrical global order that conditions growth on structural subordination.`
- **Integrated:** `The dead labour embedded in under-utilized productive capacities is crystallized past labour denied the living labour necessary for its valorization. In the center, this idleness accompanies the dismantling of a domestic social settlement in the name of profitability and financialized rent extraction; in the periphery, it reflects an asymmetrical global order that conditions growth on structural subordination. In both cases, accumulated capital remains physically present while the conditions for its reproduction are impaired.`
- **Cleaned words:** 94 → 73 (-21 words; -22.3%)
- **Raw tokens:** 94 → 73 (-21 tokens; -22.3%)
- **Integration action:** Replaced with the authorized formulation. Grounded strictly in surplus-approach reproduction dynamics; no decorative metaphors restored.

---

## 3. Byte-for-Byte Unchanged Elements

The following 5 paragraphs and all structural elements were certified **100% byte-for-byte identical** between baseline and active integrated `section5.tex`:

- `CH2-S05-P003` (Line 9): `Figure~\ref{fig:sec5_combined_mu} places the reconstructed implicit capacity utilization rates...`
- `CH2-S05-P005` (Line 24): `In the United States, the dynamics of $\mu_t$ are governed by...`
- `CH2-S05-P007` (Line 29): `The terminal crisis of the inward-oriented regime in the peripheral Chilean economy...`
- `CH2-S05-P009` (Line 33): `The post-1975 resolution did not rebuild domestic manufacturing...`
- `CH2-S05-P011` (Line 38): `This comparative analysis demonstrates that the contemporary political economy...`
- Section heading and label (Lines 1–2).
- Paragraph headings (Lines 8, 23, 28).
- Figure 5 environment and caption/note (Lines 11–19).
- All intervening blank lines.
