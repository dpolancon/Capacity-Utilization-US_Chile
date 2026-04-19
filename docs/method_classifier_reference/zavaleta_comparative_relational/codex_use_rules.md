# Codex Use Rules

## Status
This folder is a **reference classifier**, not a raw source archive.

## Hard rules
1. Use this pack to classify and route candidate objects.
2. Do not use this pack as direct historical evidence.
3. Do not generate AR variables from theory notes alone.
4. Prefer source-derived candidate objects over concept-derived candidates.
5. Keep the sequence:
   source -> source family -> scale -> operator route -> mechanism -> candidate variable
6. If translation risk is high, do not promote the candidate variable without human review.
7. If AR relevance is peripheral or exclude, do not include it in the AR variable menu.
8. When uncertain, mark `needs_manual_review`.

## Minimal admissibility test for a proposed AR variable
A candidate variable should only be proposed if Codex can state:
- what source family generated it
- what relation it is tracking
- at what scale it operates
- which operator route justifies it
- what evidentiary type it has
- why it is AR-core or AR-supportive

## Required output fields for each candidate object
- candidate_object
- source_id
- source_family
- scale
- mechanism_family
- configurational_role
- temporal_layer
- evidentiary_type
- operator_route
- translation_risk
- ar_relevance
- notes

## Escalation rule
Send an item for manual review if any of the following holds:
- multiple incompatible operator routes
- unclear scale
- unsupported leap from concept to variable
- missing source anchor
- high translation risk
- ambiguous AR relevance
