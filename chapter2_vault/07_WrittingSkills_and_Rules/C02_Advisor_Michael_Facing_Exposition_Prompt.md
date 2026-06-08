# C02 — Advisor / Michael-Facing Exposition Prompt

## Deployment note

This prompt is a full advisor-facing exposition source. It supports `06_Advisor_Facing_Exposition_Ring_v0.1.md` but does not override the Core, the Human Sovereignty Protocol, the Chapter 1 Conceptual Protective Ring, the Chapter 1 Results / Claim Ledger, or the Live Decision Ledger.

For Chapter 1 opening and abstract passages, D001 and D002 govern: the observed/unobserved sequence is an exposition aid, not an automatic replacement for the chapter’s conceptual framing.

Bernanke--Blanchard functions here as a style and exposition comparator only. It is not theoretical authority.

---

# Michael-Facing Exposition Prompt

## Purpose

Use this prompt as a project-level artifact for writing, rewriting, editing, slide-building, and advisor-facing explanation inside this project.

The prompt enforces a specific writing discipline: use the exposition clarity associated with Bernanke and Blanchard-style empirical presentation, while preserving the conceptual vocabulary and theoretical commitments of the surplus approach to political economy.

The purpose is not to import neoclassical theory. The purpose is to import an exposition sequence: concrete question, clearly named variables, simple equation, empirical test, bounded finding, and implication.

All revisions must remain compatible with the surplus approach to political economy, including productive capacity, capital accumulation, exploitation, wage share, closure, smooth reproduction, unbalanced growth, and distribution-conditioned transformation of capital into productive capacity.

---

## Core exposition principle

Begin with the empirical object, not the architecture of the chapter.

The default entry point is:

Actual output is observed. Productive capacity is not observed. Capacity utilization is constructed as observed output relative to estimated productive capacity.

Use this sequence unless there is a strong reason not to:

1. What is observed?
2. What is unobserved?
3. What must be estimated?
4. What equation estimates it?
5. What does the coefficient mean in surplus-theoretic terms?
6. What empirical test is performed?
7. What survives and what does not?
8. What implication follows for the next section, slide, or chapter?

For the Chapter 1 to Chapter 2 transition, the compact version is:

Capacity utilization is not directly observed. Actual output is observed; productive capacity is not. Shaikh estimates productive capacity from a long-run output--capital equation. Chapter 1 shows that this estimate can be approximately reconstructed, but the utilization path changes with the long-run assumptions. When the relation is estimated as a system, the bivariate output--capital specification does not survive, while a trivariate specification including the exploitation rate does. Chapter 2 therefore estimates productive capacity with distribution included explicitly.

---

## Positive lesson table

| Lesson | Old tendency to avoid | Better exposition rule | Use in this project |
|---|---|---|---|
| Start from the empirical object | “Chapter 1 disciplines Chapter 2” | Begin with what is observed and what is not observed | “Actual output is observed. Productive capacity is not. Utilization is constructed from both.” |
| Name the thing before theorizing it | “Reconstructed object” | Use concrete nouns first | “estimated productive capacity,” “constructed utilization path,” “output--capital equation” |
| Separate verbs precisely | “derive/recover utilization” | Estimate unobserved capacity; construct utilization | estimate \(\hat{Y}^p\) → construct \(\hat{\mu}=Y/\hat{Y}^p\) |
| Keep surplus approach, simplify entry | Full closure/theory first | Introduce closure after the variable and equation are clear | \(Y^p\), \(\mu\), \(\theta\), then smooth reproduction / unbalanced growth |
| Explain economic meaning before estimator | “FM-OLS is preferred because...” | Say what relation is estimated and what coefficient means first | “\(\theta\) measures how capital accumulation becomes productive capacity.” |
| Present ARDL as conditional | “ARDL model” as a black box | Explain that output is modeled conditional on capital | Single-equation benchmark: \(y_t=a+bt+\theta k_t+\varepsilon_t\) |
| Present VECM as joint system | “System admissibility” without translation | Explain the relation is tested with variables estimated jointly | Bivariate VECM: \(X_t=(y_t,k_t)'\) |
| Avoid overclaiming distribution | “without distributional effects” | Say “without an explicit distributional variable” | The bivariate system omits \(e_t\); it does not prove distribution is absent |
| Use precise system language | “bilateral system” | Say “bivariate output--capital system” | \((\ln Y,\ln K)\), rank 1 |
| State findings as bounded | “Shaikh fails” or “benchmark solved” | Use restrained empirical conclusions | “Approximately reconstructed, but not unique.” |
| Explain the ARDL fan plainly | “closure-sensitive family” | Distinguish levels from path shape | “Some differences are level conventions; others change the shape of the path.” |
| Use closure language | “long-run discipline” | Name the modeling restriction | “Bounded utilization does not require balanced-growth closure.” |
| Avoid unearned theory payloads | Adding core/periphery claims too early | Only state what the slide has prepared | “Chile tests whether the reconstruction strategy travels beyond the U.S. benchmark.” |
| Slide titles should be empirical | “Main implication,” “mechanism map” | Use titles that name the result | “ARDL result: the estimated path is not unique.” |
| Keep one task per slide | Claim + roadmap + caveat + theory | One claim, one equation/table, one interpretation | Especially for mechanism/closure slides |
| Use Bernanke--Blanchard as style, not theory | Importing their framework | Import their sequence: question → model → finding → implication | Keep surplus theory; simplify exposition rhythm |
| Define notation before use | \(e_t\), \(\omega_t\), \(\theta\) appear late | Define terms where they first appear | \(e_t\): exploitation rate; \(\omega_t\): wage share |
| Treat figures as evidence, not decoration | Dense visual with no reading rule | Add one reading sentence per figure | “The figure shows that the utilization path changes under assumptions.” |
| Keep estimator hierarchy late | Estimator details before object | First object, then result, then estimator | FM-OLS/IM-OLS/DOLS appear after capacity sequence |
| Carry-over paragraph | Fragmented bridge | One compact transition paragraph | “Actual output is observed; productive capacity is not... Chapter 2 estimates capacity with distribution included explicitly.” |

---

## Negative editing rules

| Do not... | Because... | Instead, force the text to... |
|---|---|---|
| Do not begin with the architecture of the chapter. | It makes the reader reconstruct the argument before seeing the empirical problem. | Begin with what is observed, what is unobserved, and what must be estimated. |
| Do not say “Chapter 1 disciplines Chapter 2” as the main bridge. | It is too abstract and sounds like internal project management. | Say what Chapter 1 empirically shows and what Chapter 2 must therefore estimate. |
| Do not use “object” in slide titles or advisor-facing summaries. | It hides the concrete variable behind methodological language. | Name the concrete term: productive capacity, utilization path, output--capital equation, system relation. |
| Do not use “reconstructed object,” “structural object,” or “object recovery.” | These phrases sound conceptual before the reader knows the empirical target. | Say “estimated productive capacity” or “constructed utilization path.” |
| Do not say utilization is “derived” if the denominator is estimated. | It makes the operation sound mechanical and fully observed. | Say utilization is constructed from observed output and estimated productive capacity. |
| Do not use “recovery” for the utilization path. | It suggests a true path was simply found in the data. | Say “approximately reconstructed,” “estimated,” or “constructed,” depending on the step. |
| Do not introduce \(\theta\), \(e_t\), or \(\omega_t\) before defining them. | The notation becomes a comprehension tax. | Define each symbol at first use in plain economic terms. |
| Do not present \(\theta\) only as an econometric coefficient. | That loses the surplus-theoretic interpretation. | State that \(\theta\) measures how capital accumulation becomes productive capacity. |
| Do not introduce closure vocabulary before the observed/unobserved distinction is clear. | The reader has no anchor for why closure matters. | First establish \(Y_t\), \(\hat{Y}_t^p\), and \(\hat{\mu}_t\); then discuss closure. |
| Do not say “long-run discipline” when the issue is model closure. | It sounds generic and theoretically vague. | Say balanced-growth closure, unbalanced-growth closure, or full-capacity convergence. |
| Do not imply that bounded utilization requires \(\mu_t \to 1\). | That contradicts the unbalanced-growth point. | Say the model can retain a capacity benchmark without forcing utilization to converge to one. |
| Do not say “without distributional effects” for the bivariate VECM. | It overclaims what the model excludes. | Say “without an explicit distributional variable.” |
| Do not call the VECM “bilateral.” | The econometric object is a system with two variables. | Say “bivariate output--capital system.” |
| Do not state “system admissibility” without translation. | It sounds like an opaque econometric gate. | Say the relation is tested as a joint system and must meet the admissibility criteria. |
| Do not make ARDL or VECM carry the economic interpretation by themselves. | Estimator names do not explain the relationship. | Explain the economic relation first, then name the estimator. |
| Do not present estimator choice before the empirical sequence is clear. | It makes the presentation technical before the object is understood. | Present: estimate \(\theta\), estimate \(\hat{Y}^p\), construct \(\hat{\mu}\), compare paths. |
| Do not treat the ARDL fan as self-explanatory. | Some differences are level conventions and others are substantive path changes. | Tell the reader which differences are level conventions and which alter path shape. |
| Do not write “Shaikh fails.” | The result is more precise and more useful. | Say Shaikh’s estimate can be approximately reconstructed, but the resulting utilization path is not unique. |
| Do not write as if the replication fully solves the identification problem. | The result is bounded. | Say the replication narrows the next step for Chapter 2. |
| Do not use “distributionally mediated object” as a slide conclusion. | It is conceptually dense and sounds like a label rather than a finding. | Say the trivariate system survives when the exploitation rate is included explicitly. |
| Do not introduce Chile with unearned claims. | It risks smuggling in theory before the deck has prepared it. | Say Chile tests whether the same capacity-estimation strategy travels beyond the U.S. benchmark. |
| Do not call Chile a robustness check. | That flattens the comparative logic. | Say it is a second case for testing portability of the reconstruction strategy. |
| Do not compress firm organization, accumulation, disproportionality, utilization, and center/periphery into one mechanism slide. | One slide cannot carry that much argument. | Split the mechanism later or keep it as backup. |
| Do not let a slide carry claim, roadmap, caveat, theory, and defense at once. | It produces density without clarity. | Use one claim, one equation/table, one interpretation. |
| Do not use “main implication” as a vague title. | It does not tell the reader what implication matters. | Use a result-bearing title, such as “Bounded utilization does not require balanced growth.” |
| Do not overuse “benchmark.” | Repetition turns it into a placeholder. | Rotate between capacity estimate, estimated capacity path, output--capital equation, and utilization path. |
| Do not import Bernanke--Blanchard’s theoretical frame. | Their framework is neoclassical/New Keynesian, not the surplus approach. | Import only their exposition sequence: question, simple equation, evidence, finding, implication. |
| Do not replace surplus-theoretic language with generic macro language. | That weakens the conceptual framework. | Use surplus terms after defining the empirical object: productive capacity, closure, exploitation rate, wage share, unbalanced growth. |
| Do not write sentences that explain the presentation instead of making the point. | It sounds procedural. | State the empirical claim directly. |
| Do not add transition phrases that only say “this matters because.” | They often add words without pressure. | Let the next empirical result show why it matters. |
| Do not use figure redesign issues as blockers for exposition. | The current task is clarity of sequence, not full visual repair. | Log graphical fixes separately and keep the slide text self-contained. |

---

## Crosswalk: lessons to negative rules

| Positive lesson | Corresponding negative rule | Operational implication |
|---|---|---|
| Start from the empirical object | Do not begin with chapter architecture | Open with observed output, unobserved capacity, and constructed utilization. |
| Name the thing before theorizing it | Do not use “object” before naming the variable | Use productive capacity, utilization path, output--capital relation, system relation. |
| Separate verbs precisely | Do not say “derive utilization” when capacity is estimated | Use estimate \(\hat{Y}^p\), construct \(\hat{\mu}\). |
| Keep surplus approach, simplify entry | Do not introduce closure vocabulary too early | Define \(Y\), \(Y^p\), \(\mu\), \(\theta\), then discuss closure. |
| Explain economic meaning before estimator | Do not let ARDL/VECM/FM-OLS carry the meaning | Say what the relation estimates and what \(\theta\) means before naming the estimator. |
| Present ARDL as conditional | Do not treat ARDL as a black box | Explain output is modeled conditional on capital. |
| Present VECM as joint system | Do not say “system admissibility” without translation | Explain output and capital are estimated jointly. |
| Avoid overclaiming distribution | Do not say “without distributional effects” | Say “without an explicit distributional variable.” |
| Use precise system language | Do not say “bilateral system” | Say “bivariate output--capital system.” |
| State findings as bounded | Do not say “Shaikh fails” or “solves” | Say “approximately reconstructed, but not unique.” |
| Explain figures plainly | Do not let figures stand alone | Give each figure one reading sentence. |
| Use closure language | Do not say “long-run discipline” | Say balanced-growth closure or unbalanced-growth closure. |
| Avoid unearned theory payloads | Do not introduce Chile with premature claims | Present Chile as a second case testing portability unless the slide has already established stronger claims. |
| Slide titles should be empirical | Do not use vague titles | Title slides by result or task. |
| Keep one task per slide | Do not overload slides | One claim, one equation/table, one interpretation. |
| Use Bernanke--Blanchard as style, not theory | Do not import their model assumptions | Import only their exposition rhythm. |

---

## Enforcement rules by deliverable type

### For dissertation prose

Before rewriting a paragraph, identify the empirical object of the paragraph. If the paragraph begins with architecture, metacommentary, or theory labels before naming the object, rewrite the opening sentence.

Every empirical paragraph should answer at least one of these questions:

- What is observed?
- What is unobserved?
- What is estimated?
- What does the coefficient mean?
- What test is performed?
- What result changes the next step?

Do not remove surplus-theoretic language. Sequence it after the empirical object is clear.

### For slides

Each slide must have one claim, one equation/table/visual maximum, and one interpretation sentence.

If a slide introduces a symbol, define it on the same slide.

If a slide uses a figure, include a reading sentence that tells Michael what to see.

Do not use slide titles that describe the architecture of the chapter. Use titles that state the result or empirical task.

### For advisor-facing summaries

Use compact empirical paragraphs.

Avoid internal workflow language.

State findings in bounded form.

Preferred structure:

1. The empirical problem.
2. The estimated relation.
3. The test.
4. The result.
5. The implication for the next chapter or section.

### For prompts and future editing sessions

Whenever editing a deliverable for Michael-facing clarity, first run this checklist:

- Does the piece begin with what is observed and what is unobserved?
- Are all symbols defined before use?
- Is the economic interpretation stated before the estimator?
- Are findings stated as bounded results?
- Is surplus vocabulary preserved but sequenced after the empirical object?
- Are there any unearned theory claims smuggled into slides or transitions?
- Are ARDL and VECM explained in terms of what relation they test?

If any answer is no, revise before polishing style.

---

## Required rewriting pattern

When fixing writing, slides, or another deliverable for Michael’s understanding, rewrite toward this pattern:

1. **Empirical object:** name the variable or relation.
2. **Observed/unobserved status:** state what is observed and what must be estimated.
3. **Equation:** present the simplest equation that carries the claim.
4. **Economic interpretation:** explain the coefficient or relation in surplus-theoretic terms.
5. **Test:** state what is being varied, relaxed, or compared.
6. **Finding:** state the result in bounded form.
7. **Implication:** state what the next section, slide, or chapter must do.

Do not skip directly from theory to estimator.

Do not skip directly from estimator to theoretical implication.

Do not ask the reader to infer the economic object from the notation.

---

## Project-level style command

For all writing in this shell of the project:

Use Bernanke--Blanchard clarity of presentation without importing Bernanke--Blanchard theory.

Preserve the surplus approach to political economy.

Start from variables and relations.

Define observed and unobserved terms.

State the estimating equation simply.

Translate coefficients into political-economic meaning.

Report findings as bounded results.

Only then introduce broader closure, reproduction, distribution, and center/periphery implications.