# WS Corridor Reference Bank — Workflow Protocol

## Purpose

This protocol governs the construction of the **world-systemic (WS) corridor** as a reproducible research component. Its purpose is to build a disciplined reference bank that supports the methodological operationalization of the WS corridor through a structured process of source ingestion, extraction, variable discovery, and conceptual adjudication.

The protocol is designed to prevent three recurrent problems:

1. treating the WS corridor as an undifferentiated “external factors” box;
2. searching prematurely for econometric variables without first specifying mechanisms and observables;
3. producing source notes that are not reproducible across sessions, chapter drafting, or repository workflows.

The WS corridor must therefore be built through a staged discovery process in which **dimensions precede mechanisms, mechanisms precede observables, and observables precede variables or indicators**.

---

## Governing rule

In the WS corridor, discovery proceeds from:

**dimensions → mechanisms → observables → variables / indicators**.

This order is mandatory. It avoids methodological drift and preserves alignment with the project’s broader architecture, in which quantitative results function as structured diagnostics embedded inside process tracing rather than as autonomous causal proof.

---

## Division of labor

The workflow uses a hybrid architecture.

### Repo / Codex side

Use the repository and Codex-style automation for:

- corpus intake;
- PDF ingestion;
- metadata extraction;
- BibTeX draft generation;
- markdown note generation;
- quote extraction with page anchors;
- creation of registry rows;
- bulk search across the corpus for candidate mechanisms, observables, and variables.

### Chat side

Use chat for:

- dimensional design;
- methodological adjudication;
- deciding whether a candidate belongs to the WS corridor, AR corridor, or overlap zone;
- collapsing duplicates across dimensions;
- distinguishing conceptual, evidentiary, historiographic, and archival source roles;
- refining the ontology of the corridor;
- producing chapter-ready syntheses and mechanism sheets.

**Rule:** repo/Codex is the intake machine; chat is the adjudication machine.

---

## Initial WS dimensions

Begin with the following provisional dimensions. These are not final in a metaphysical sense, but they are the working ontology from which discovery should start:

1. Cold War geopolitics
2. U.S. interventionism
3. Third World / Non-Aligned Movement / NIEO politics
4. Crisis of Atlantic Fordism / world monetary disorder
5. External constraint / balance-of-payments / trade dependency
6. Transnational capital / multinational corporate power
7. Strategic commodities / copper / resource sovereignty
8. Inter-American order / hemispheric security doctrine
9. Diplomatic isolation, blockade, recognition, and alliance structure

These dimensions can later be merged, split, or refined, but all source processing should initially map into at least one of them.

---

## Core object grammar

Every source processed for the WS corridor must be translated into the following grammar:

**source → dimension → mechanism → observable → possible variable / indicator → evidentiary status**

This grammar is the backbone of the registry. It ensures that sources are not merely summarized, but converted into reusable methodological objects.

### Definitions

#### Dimension
The broad world-systemic field to which the source contributes.

#### Mechanism
The causal process claimed or implied by the source. Example: credit restriction as geopolitical pressure.

#### Observable
What one should be able to detect if the mechanism is operating. Example: interrupted lending, diplomatic pressure, coordinated public statements, shifts in external reserves, sanctions, covert destabilization episodes.

#### Variable / indicator
A candidate empirical representation of the observable. This may be quantitative, categorical, event-based, institutional, or documentary.

#### Evidentiary status
The role of the source for the project. Suggested categories:

- conceptual / theoretical
- historiographic / synthetic
- evidentiary / empirical secondary
- archival / documentary
- quantitative / statistical
- mixed

---

## Acceptable variable types

The WS corridor should not be reduced to numeric macro series. Candidate variables may belong to different types:

1. **quantitative series** — e.g., trade balances, reserves, copper prices, external debt, import compression, aid flows;
2. **event variables** — e.g., sanctions, embargo threats, diplomatic ruptures, covert operations, alliance shifts;
3. **institutional-state indicators** — e.g., lending decisions, multilateral veto behavior, policy doctrine changes, military-security coordination;
4. **documentary evidentiary markers** — e.g., statements, memoranda, declassified directives, official communiqués, conference declarations.

A candidate is valid even if it is not a clean time series, provided it contributes to mechanism identification.

---

## Required outputs per source

Each source added to the corpus should generate four linked outputs:

1. **BibTeX entry** compatible with natbib;
2. **markdown reading note**;
3. **variable-extraction note**;
4. **registry row** in the master WS corridor ledger.

### Minimum fields for the BibTeX draft

- citation key
- author(s)
- year
- title
- publisher or journal
- source type
- file path
- tags
- optional note field for corridor relevance

### Minimum fields for the markdown reading note

- full citation
- source type
- dimension tags
- short summary
- main argument
- contribution to WS corridor
- direct quotes with page numbers
- notes on methodological relevance

### Minimum fields for the variable-extraction note

- source citation key
- dimension(s)
- mechanism(s)
- observable(s)
- candidate variable(s)
- variable type(s)
- suggested evidence lane
- confidence / usefulness note
- overlap note: WS-only, AR-only, or overlap

### Minimum fields for the registry row

- citation key
- title
- authors
- year
- source type
- primary dimension
- secondary dimension(s)
- primary mechanism
- observable category
- variable candidates
- evidence lane
- evidentiary status
- note status (draft / reviewed / locked)

---

## Folder structure

Suggested repository structure:

```text
/ws_corridor/
  /pdfs/
    /books/
    /articles/
    /chapters/
  /bib/
    ws_corridor.bib
  /notes/
    /reading_notes/
    /variable_notes/
  /registry/
    ws_corridor_registry.csv
    ws_corridor_dimension_matrix.csv
    ws_corridor_variable_menu.csv
  /prompts/
    ws_corridor_extraction_prompt.md
    ws_corridor_session_prompt.md
  /logs/
    ingestion_log.md
```

This structure may be adapted, but the separation between source files, notes, bib, registry, and prompts should be preserved.

---

## Workflow stages

## Stage 1 — Corpus intake

Add PDF or chapter files to the corpus.

For each source:

- assign a stable filename;
- place it in the appropriate source folder;
- log intake date;
- record preliminary bibliographic metadata;
- assign provisional dimension tag(s).

Goal: build the raw source base.

---

## Stage 2 — Reading-note generation

For each source, generate a markdown reading note.

The note should identify:

- what the source is about;
- which WS dimension(s) it speaks to;
- whether it contributes mechanisms, observables, variables, historiography, or only background context;
- page-anchored quotes for later verification and writing.

Goal: transform PDFs into reviewable notes.

---

## Stage 3 — Variable discovery extraction

Using the reading note and source text, produce a variable-extraction note.

This note must not begin by forcing the source into a narrow variable slot. Instead, it must identify:

- candidate mechanisms;
- observables implied by those mechanisms;
- possible empirical indicators;
- whether the source supports an event variable, a macro series, a documentary marker, or an institutional indicator.

Goal: discover candidate empirical objects without prematurely reducing the source.

---

## Stage 4 — Registry consolidation

Insert the source into the master WS corridor registry.

At this stage, normalize naming conventions across sources:

- dimension names;
- mechanism labels;
- observable categories;
- variable types;
- evidence lane labels.

Goal: turn individual notes into a searchable bank.

---

## Stage 5 — Cross-source adjudication

This stage should be done in chat, not only in automation.

Tasks:

- collapse duplicate mechanisms and variables across sources;
- identify clusters by dimension;
- detect overlap between WS and AR corridors;
- distinguish strong candidate variables from weak or merely contextual mentions;
- refine dimension definitions;
- decide which mechanisms require dedicated evidence lanes.

Goal: convert extraction into methodology.

---

## Stage 6 — Matrix construction

Build a dimension-variable matrix.

### Rows
Candidate variables / indicators / documentary markers.

### Columns
WS dimensions.

### Suggested additional columns

- mechanism family
- observable category
- variable type
- frequency / temporality
- source support count
- corridor classification (WS-only / AR-only / overlap)
- readiness status (candidate / reviewed / locked)

Goal: build the menu of the WS corridor.

---

## Stage 7 — Methodological integration

Only after the matrix is mature should the material be integrated into the methodology chapter or the mechanism sheets.

At this stage, each major dimension should produce:

- a short dimensional note;
- a mechanism summary;
- a variable menu;
- a note on evidence limits;
- a note on how it contributes to hypothesis-family adjudication.

Goal: translate the bank into chapter-ready methodological architecture.

---

## Decision rules

### Rule 1 — No premature quantification
A source does not need to yield a numeric series to be useful.

### Rule 2 — No dimension without mechanism
Do not retain a dimension merely because it sounds historically important. It must correspond to identifiable causal processes.

### Rule 3 — No variable without observable
A variable candidate must be linked to an observable that makes substantive sense.

### Rule 4 — No source summary without corridor assignment
Every source must be assigned at least one provisional dimension.

### Rule 5 — Preserve overlap
If an object belongs to both WS and AR, mark it as overlap rather than forcing a false separation.

### Rule 6 — Page-anchored traceability
All important claims extracted from PDFs should retain page references when possible.

---

## Recommended registry files

### 1. `ws_corridor_registry.csv`
Master source ledger.

### 2. `ws_corridor_dimension_matrix.csv`
Crosswalk of dimensions and sources.

### 3. `ws_corridor_variable_menu.csv`
Crosswalk of mechanisms, observables, and candidate variables.

### 4. `ws_corridor_bib_key_map.csv`
Optional map linking filenames, citation keys, and note files.

---

## Recommended markdown note naming

```text
reading_<citekey>.md
variable_<citekey>.md
```

Example:

```text
reading_kolko1972.md
variable_kolko1972.md
```

---

## Recommended session cadence

Use the workflow in batches.

A strong cycle is:

1. ingest 5–15 sources into the repo;
2. generate or refine reading notes;
3. generate variable-extraction notes;
4. review the batch in chat;
5. consolidate the matrix;
6. lock refined dimensions or variable classes only after several batches.

This helps avoid freezing the ontology too early.

---

## Immediate next tasks

1. finalize the folder and registry schema;
2. prepare the initial extraction prompt for Codex;
3. seed the first source batch;
4. generate the first registry files;
5. open a new session dedicated exclusively to WS corridor construction.

---

## Final operational principle

The WS corridor is not a residual external appendix. It is a structured causal field. Its reference bank must therefore be built as a reproducible methodological component capable of supporting process tracing, variable discovery, and later chapter writing without conceptual drift.
