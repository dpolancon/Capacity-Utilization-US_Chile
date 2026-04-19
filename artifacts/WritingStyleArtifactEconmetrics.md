# Writing Style Artifact

**Name:** WrittingLikeMe Academic Style Vector  
**Author:** Diego Polanco  
**Version:** WLM 3.1 (calibrated)  
**Artifact type:** Academic writing style embedding  
**Vector space:** 16-dimension academic writing basis  
**Scale:** Continuous 0–10 bounded scale  
**Status:** Fully self-contained portable artifact

Purpose:  
This artifact stores a calibrated vector representation of Diego Polanco’s academic writing style together with the vectorization model, calibration parameters, and operational rules required to interpret and apply the style embedding.

The artifact functions as a **portable measurement instrument for academic writing style**.

---

# 1. Foundational Ontology (Structural Constraints)

All applications of this artifact assume the following intellectual commitments:

1. **Relational ontology**  
    Economic dynamics arise from historically specific configurations of social relations.
    
2. **Endogenous instability**  
    Crisis is a structural outcome of regime dynamics rather than an external disturbance.
    
3. **Theory-disciplined empirics**  
    Empirical claims must be admissible within the theoretical architecture being used.
    
4. **Measurement as institutional infrastructure**  
    Quantitative indicators function as historically embedded governance devices.
    
5. **Institutional mediation**  
    Accumulation, distribution, and crisis are mediated through institutional architectures.
    

These constraints define the **conceptual environment** within which the writing style operates.

---

# 2. Vector Space Definition

Academic writing style is represented in a **16-dimensional vector space**.

Each dimension is scored on a **0–10 scale**.

|Code|Dimension|
|---|---|
|AA|Argument Architecture Clarity|
|TS|Topic Sentence Strength|
|TR|Transition Coherence|
|CD|Concept Definition Discipline|
|TP|Theoretical Positioning Precision|
|EA|Empirical Admissibility Discipline|
|FI|Formal-Interpretive Bridge Quality|
|LB|Load-Bearing Sentence Ratio|
|RR|Redundancy Control|
|CH|Citation Hygiene|
|SG|Signposting Quality|
|PC|Paragraph Cohesion|
|CE|Compression Efficiency|
|TC|Tone Calibration|
|TS2|Terminology Stability|
|NC|Non-Claim Discipline|

Interpretation of scale:

0–3 → weak / inconsistent  
4–6 → moderate competence  
7–8 → strong professional writing  
9–10 → exceptional academic discipline

---

# 3. Vectorization Model Specification

The writing style vector is produced by a **rule-based semantic embedding model**.

### Model type

Interpretive feature-extraction model for academic writing structure.

### Corpus inputs

Author corpus (published papers, dissertation chapters)  
Editorial exemplar corpus (high-quality academic writing)

### Feature extraction

Text is analyzed for signals corresponding to the 16 dimensions, including:

- structural signals (argument hierarchy, section logic)
    
- rhetorical signals (claim clarity, transitions)
    
- density signals (compression, redundancy)
    
- terminological stability
    
- citation management
    

Dimension scores are estimated using weighted combinations of these signals.

Example scoring rule:

score_d = w₁ structural signal  
     + w₂ rhetorical signal  
     + w₃ density signal

Weights are normalized.

The result is the **baseline author vector** s₀.

---

# 4. Refinement Model

Editorial refinement is extracted from exemplar texts.

Importantly, exemplar writing is **not imitated**.

Instead, the system estimates **directional editorial corrections**.

Refinement vector:

r = mentor editorial style − author baseline style

Each dimension receives a refinement adjustment in the range:

−1 ≤ r_d ≤ 1

Positive values indicate potential improvement directions.

---

# 5. Calibration Transformation

The calibrated writing vector is obtained through a linear transformation.

Transformation rule:

s₁ = clip(s₀ + α · 10 · r , 0 , 10)

Where:

s₀ = baseline author vector  
r = refinement vector  
α = calibration intensity parameter  
clip() enforces the 0–10 bounds

---

# 6. Calibration Parameters

Calibration parameter:

α = 0.6

Interpretation:

The calibrated vector incorporates **moderate editorial refinement** while preserving authorial style identity.

Scale bounds:

0 ≤ s_d ≤ 10

---

# 7. Calibrated Writing Style Vector (s₁)

| Dimension | Score |
| --------- | ----- |
| AA        | 8.8   |
| TS        | 8.2   |
| TR        | 8.3   |
| CD        | 9.3   |
| TP        | 9.6   |
| EA        | 9.5   |
| FI        | 9.2   |
| LB        | 8.5   |
| RR        | 8.0   |
| CH        | 7.9   |
| SG        | 7.8   |
| PC        | 8.7   |
| CE        | 7.9   |
| TC        | 8.6   |
| TS2       | 9.6   |
| NC        | 8.3   |

# 8. Style Interpretation

### Core strengths

TP – theoretical positioning  
EA – empirical admissibility discipline  
TS2 – terminology stability  
CD – conceptual definition discipline  
FI – formal-interpretive bridging

These dimensions define the **core intellectual identity** of the writing.

### Supporting strengths

AA – argument architecture  
PC – paragraph cohesion  
TC – tone calibration  
LB – load-bearing sentence ratio

### Primary revision targets

SG – signposting clarity  
CH – citation hygiene  
CE – compression efficiency  
RR – redundancy control

### Secondary revision targets

TS – topic sentence sharpness  
TR – transition coherence

---

# 9. Style Fingerprint

The calibrated vector corresponds to the following style profile:

High-theory academic prose characterized by strong conceptual discipline, clear theoretical positioning, stable terminology, and strict empirical admissibility constraints.  
Editorial improvements should prioritize navigational clarity, compression efficiency, redundancy reduction, and citation discipline rather than increasing conceptual density.

---

# 10. Execution Rules

When the artifact is used for drafting, revision, or auditing:

1. Dimensions ≥ 9 are treated as **protected strengths**.
    
2. Editorial improvement should focus on dimensions < 8.
    
3. Revisions must not improve clarity by weakening TP, EA, CD, FI, or TS2.
    
4. Gains in readability should come from compression, signposting, and citation discipline rather than additional theoretical exposition.
    
5. Terminology must remain stable across sections.
    

---

# 11. Intended Uses

This artifact can be used to:

- audit academic writing quality
    
- guide revision priorities
    
- calibrate writing assistance systems
    
- enforce stylistic consistency across long documents
    
- support dissertation-level writing workflows
    

The artifact is portable across platforms because it contains:

• the vector space definition  
• the vectorization model  
• the calibration parameters  
• the calibrated vector  
• the interpretation layer  
• the operational rules

No external prompt logic is required to interpret the artifact.