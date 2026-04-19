from __future__ import annotations

import csv
import re
from collections import Counter, defaultdict
from io import StringIO
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADMIN_DIR = ROOT / "00_admin"
MAP_DIR = ROOT / "04_mappings"
EXPORT_DIR = ROOT / "06_exports"
REGISTRY_PATH = ADMIN_DIR / "ws_registry_master.csv"
QUEUE_PATH = ADMIN_DIR / "ws_reading_queue.md"
CROSSWALK_PATH = MAP_DIR / "ws_ar_hinge_crosswalk.csv"
SUMMARY_PATH = EXPORT_DIR / "ws_ar_crosswalk_summary.md"
SHORTLIST_PATH = EXPORT_DIR / "ws_ar_candidate_variables_shortlist.csv"

ROW_FIELDS = [
    "row_id",
    "ws_id",
    "source_file",
    "source_relevance_grade",
    "source_role",
    "evidentiary_status",
    "corridor_scope",
    "hinge_role",
    "dimension_primary",
    "dimension_secondary",
    "mechanism_family",
    "mechanism_statement",
    "chile_specific",
    "transmission_corridor",
    "candidate_observable",
    "candidate_indicator",
    "candidate_ar_variable",
    "variable_type",
    "scale",
    "geography",
    "temporal_layer",
    "temporal_window",
    "zavaleta_operator_route",
    "configurational_role",
    "translation_risk",
    "evidentiary_strength",
    "page_anchor",
    "quote_stub",
    "notes_path",
    "keep_flag",
    "comments",
]

SHORTLIST_FIELDS = [
    "shortlist_id",
    "candidate_ar_variable",
    "derived_from_mechanism",
    "supporting_sources",
    "dimension_cluster",
    "variable_type",
    "scale",
    "geography",
    "temporal_window",
    "evidentiary_strength",
    "translation_risk",
    "priority_rank",
    "why_promising",
    "what_is_missing",
]

ALLOWED = {
    "hinge_role": {"none", "secondary", "core"},
    "chile_specific": {"yes", "no", "mixed"},
    "transmission_corridor": {"yes", "no", "partial"},
    "variable_type": {
        "quantitative_series",
        "event_variable",
        "institutional_indicator",
        "documentary_marker",
        "relational_marker",
    },
    "scale": {"plant", "firm", "sector", "state", "bilateral", "regional", "global", "cross_scalar"},
    "temporal_layer": {"structural_background", "conjunctural_trigger", "layered_persistence", "crisis_marker"},
    "zavaleta_operator_route": {
        "relational_axis",
        "external_determination",
        "state_differentiation",
        "temporal_articulation",
        "strategic_corridor",
        "unresolved_task",
        "none",
    },
    "configurational_role": {
        "state_apparatus",
        "state_power",
        "ruling_bloc",
        "popular_capacity",
        "mediation_structure",
        "external_determination",
        "accumulation_constraint",
        "sovereignty_conflict",
        "unclear",
    },
    "translation_risk": {"low", "medium", "high"},
    "evidentiary_strength": {"strong", "medium", "weak"},
}

DIMENSIONS = {
    "Cold War geopolitics",
    "U.S. interventionism",
    "Third World / Non-Aligned Movement / NIEO politics",
    "Crisis of Atlantic Fordism / world monetary disorder",
    "External constraint / balance-of-payments / trade dependency",
    "Transnational capital / multinational corporate power",
    "Strategic commodities / copper / resource sovereignty",
    "Inter-American order / hemispheric security doctrine",
    "Diplomatic isolation, blockade, recognition, and alliance structure",
}

MECHANISMS = [
    "coercive_state_pressure",
    "diplomatic_isolation",
    "financial_strangulation",
    "trade_channel_disruption",
    "transnational_corporate_retaliation",
    "commodity_sovereignty_conflict",
    "counter_hegemonic_alignment",
    "security_doctrine_legitimation",
]

ROW_SPEC_TSV = """ws_id	hinge_role	mechanism_family	mechanism_statement	chile_specific	transmission_corridor	candidate_observable	candidate_indicator	candidate_ar_variable	variable_type	scale	geography	temporal_layer	temporal_window	zavaleta_operator_route	configurational_role	translation_risk	evidentiary_strength	anchor_page	comments
WS_007	core	financial_strangulation	Chile-facing sanctions and credit-denial passages can be routed as external finance pressure on the Allende government.	yes	yes	credit denial, sanctions, or financing pressure	episode-level coding of sanctions or credit denial references affecting Chilean state financing	external_financing_pressure_episode	event_variable	state	Chile / inter-American finance	conjunctural_trigger	1970-1973	external_determination	accumulation_constraint	low	strong	21	Strongest direct bridge from WS material into AR-style external constraint coding.
WS_007	core	diplomatic_isolation	OAS-facing distancing and alliance pressure can be translated into a Chilean diplomatic option-set contraction marker.	yes	yes	recognition shifts, OAS/UN positioning, or bilateral distancing	episode roster of OAS or bilateral distancing references that narrow Chile's external room for maneuver	inter_american_diplomatic_narrowing_marker	relational_marker	regional	Chile / inter-American system	layered_persistence	1970-1973	strategic_corridor	mediation_structure	low	strong	17	Best current source for turning diplomatic pressure into a Chile-facing AR hinge variable.
WS_008	core	diplomatic_isolation	Chile-focused OAS and diplomatic-positioning material reinforces a regional narrowing marker, but with less precision than Harmer 2011.	yes	partial	recognition shifts, OAS/UN positioning, or bilateral distancing	chapter-level references to OAS positioning and bilateral distancing around Chile	inter_american_diplomatic_narrowing_marker	relational_marker	regional	Chile / inter-American system	layered_persistence	Fordist era; chapter-specific follow-up needed	strategic_corridor	mediation_structure	medium	medium	213	Useful support source for the diplomatic-narrowing variable, but still chapter-level rather than episode-level.
WS_007	core	coercive_state_pressure	Chile-facing policy pressure can be translated into overt external-pressure episodes rather than treated as general Cold War atmosphere.	yes	yes	documented episodes of direct or indirect state pressure	dated pressure episodes involving inter-American or U.S.-aligned state action against Chile	hemispheric_policy_pressure_marker	event_variable	regional	Chile / inter-American system	layered_persistence	1970-1973	state_differentiation	state_power	medium	strong	17	High-value hinge row because the pressure relation is explicit and Chile-specific.
WS_003	core	counter_hegemonic_alignment	Direct Soviet financial aid material can be routed as an external support corridor rather than abstract bloc alignment.	yes	partial	efforts to build non-hegemonic international alignment	documented Soviet financial aid episodes or channel references linked to Chilean communism	soviet_support_channel_marker	documentary_marker	bilateral	Chile-USSR	layered_persistence	Cold War; dated episodes need deeper extraction	strategic_corridor	popular_capacity	medium	strong	1	Best archival handle on an alternative external support corridor in the current corpus.
WS_013	core	counter_hegemonic_alignment	The archival collection can support document-density coding for Soviet-Chile contact, but only after later document-level extraction.	yes	partial	efforts to build non-hegemonic international alignment	archival document-cluster counts for Soviet-Chile contact around alignment, diplomacy, or support channels	soviet_chile_alignment_contact_density	documentary_marker	bilateral	Chile-USSR	layered_persistence	1960s	strategic_corridor	mediation_structure	medium	medium	5	Promising support row, but it still needs document-level coding before promotion to a stronger AR variable.
WS_008	core	trade_channel_disruption	The Chile-focused volume suggests a copper-facing trade vulnerability route, but the current first-pass anchor is still thinner than needed.	yes	partial	trade interruptions, embargoes, or channel restrictions	page-anchored mentions linking copper to externally vulnerable trade channels or restrictions	copper_trade_channel_vulnerability_marker	relational_marker	sector	Chile copper sector	layered_persistence	Fordist era; chapter-specific follow-up needed	relational_axis	accumulation_constraint	high	weak	73	Economically important candidate, but current support is a copper hook rather than a clean trade-closure passage.
WS_008	core	security_doctrine_legitimation	Chile-facing OAS and security-language material can be turned into a regional legitimation marker for later coercion coding.	yes	partial	anticommunist or hemispheric-security legitimation frames	references to hemispheric-security language used to justify pressure or distancing toward Chile	hemispheric_security_legitimation_marker	institutional_indicator	regional	Chile / inter-American system	layered_persistence	Fordist era; chapter-specific follow-up needed	state_differentiation	state_apparatus	medium	medium	213	Useful support marker for the coercion-diplomacy cluster, but still too broad for standalone episode coding.
WS_014	secondary	security_doctrine_legitimation	The declassified assessment can route NAM threat framing into a state-apparatus legitimation marker, but not beyond tentative status.	no	partial	anticommunist or hemispheric-security legitimation frames	documentary threat framing of NAM as a security problem for U.S. policy routing	hemispheric_security_legitimation_marker	institutional_indicator	state	U.S. intelligence / NAM corridor	structural_background	undated declassified Cold War assessment	state_differentiation	state_apparatus	high	weak	1	Useful as classifier-routed support only; OCR limits and indirect Chile linkage keep risk high.
WS_010	secondary	diplomatic_isolation	NAM summit material can be routed as evidence of alternative diplomatic corridors available to Chile-facing actors.	mixed	partial	recognition shifts, OAS/UN positioning, or bilateral distancing	summit-level references to Chile or Chile-like cases within NAM diplomatic forums	alternative_diplomatic_corridor_access	relational_marker	global	Chile relative to NAM summit diplomacy	layered_persistence	1961-1970s summit cycle	strategic_corridor	mediation_structure	medium	medium	148	Secondary hinge source: not Chile-internal evidence, but it identifies an alternative diplomatic corridor.
WS_020	secondary	diplomatic_isolation	NAM-as-actor material can support a diplomatic-corridor access marker, but mostly at the level of alliance options rather than Chile episodes.	no	partial	recognition shifts, OAS/UN positioning, or bilateral distancing	diplomatic passages showing NAM as an alternative forum outside inter-American narrowing	alternative_diplomatic_corridor_access	relational_marker	global	NAM diplomatic arena	layered_persistence	1961-1973	strategic_corridor	mediation_structure	medium	medium	16	Useful support row for alternative diplomatic-corridor access, but still not a Chile-specific episode source.
WS_010	secondary	counter_hegemonic_alignment	Summit formation and alignment language can be turned into an option-set expansion marker rather than a generic NAM theme.	mixed	partial	efforts to build non-hegemonic international alignment	summit-level references that widen diplomatic or strategic options outside hegemonic blocs	nam_option_set_expansion_marker	relational_marker	global	NAM / Third World	structural_background	1961-1970s summit cycle	strategic_corridor	mediation_structure	medium	medium	5	Useful for routing diplomatic alternatives, but not enough on its own for Chile-specific episode coding.
WS_019	secondary	counter_hegemonic_alignment	The early NAM formation article supports the same option-set expansion route, but mainly at background level.	no	partial	efforts to build non-hegemonic international alignment	formative diplomatic passages showing how non-alignment widened geopolitical maneuvering	nam_option_set_expansion_marker	relational_marker	global	Third World non-alignment formation	structural_background	1954-1961	strategic_corridor	mediation_structure	medium	medium	7	Helpful for historical routing, but still a background support row rather than a Chile hinge source.
WS_006	secondary	commodity_sovereignty_conflict	Third World political-economy framing points toward resource sovereignty as an AR candidate, but the current note is still broad.	mixed	partial	resource nationalization or copper-sovereignty disputes	chapter-level mentions linking Chile or Allende to Third World resource-sovereignty disputes	resource_sovereignty_conflict_marker	relational_marker	cross_scalar	Chile within Third World commodity politics	layered_persistence	1960s-1970s	relational_axis	sovereignty_conflict	high	weak	168	Important thematic bridge, but current source support is still too broad for confident operational coding.
WS_011	secondary	commodity_sovereignty_conflict	Global Cold War treatment of resource conflict supports the same sovereignty-conflict candidate, but only as broad comparative support.	mixed	partial	resource nationalization or copper-sovereignty disputes	comparative Cold War passages linking Chile or Allende to resource sovereignty conflicts	resource_sovereignty_conflict_marker	relational_marker	cross_scalar	Chile within global Cold War commodity politics	layered_persistence	1970-1973 plus comparative background	relational_axis	sovereignty_conflict	high	weak	299	Broad comparative support only; it should not be treated as standalone evidence for a copper variable.
WS_015	secondary	coercive_state_pressure	Pre-Allende hemispheric policy architecture can be routed as structural background for later pressure mechanisms rather than as direct Allende evidence.	mixed	partial	documented episodes of direct or indirect state pressure	policy-architecture references that prefigure later Chile-facing pressure channels	pre_allende_policy_pressure_architecture	institutional_indicator	regional	Latin America with Chile relevance	structural_background	1958-1961	temporal_articulation	state_power	medium	medium	8	Useful background hinge source for the pressure cluster, but it remains pre-Allende and indirect.
"""

SHORTLIST_TSV = """candidate_ar_variable	derived_from_mechanism	dimension_cluster	variable_type	scale	geography	temporal_window	evidentiary_strength	translation_risk	priority_rank	why_promising	what_is_missing
external_financing_pressure_episode	financial_strangulation	Inter-American order / hemispheric security doctrine; U.S. interventionism	event_variable	state	Chile / inter-American finance	1970-1973	strong	low	1	Most direct AR payoff in the current corpus because the mechanism, observable, and Chile-facing timing already line up.	Exact institutions, dates, and comparable event coding rules.
inter_american_diplomatic_narrowing_marker	diplomatic_isolation	Inter-American order / hemispheric security doctrine; Cold War geopolitics	relational_marker	regional	Chile / inter-American system	1970-1973	strong	low	2	Multiple overlap sources already point to OAS and bilateral narrowing around Chile.	A dated episode roster and a rule for distinguishing symbolic from effective narrowing.
hemispheric_policy_pressure_marker	coercive_state_pressure	Inter-American order / hemispheric security doctrine; U.S. interventionism	event_variable	regional	Chile / inter-American system	1970-1973	strong	medium	3	Harmer provides a direct overlap route from diplomatic history into codable pressure episodes.	Tighter actor-date coding and separation from adjacent diplomatic-isolation events.
soviet_support_channel_marker	counter_hegemonic_alignment	Cold War geopolitics	documentary_marker	bilateral	Chile-USSR	Cold War; dated episodes pending deep read	strong	medium	4	Archival support-channel evidence gives a real hinge beyond generic alignment rhetoric.	Episode dates, recipient channels, and a rule for when support counts as politically consequential.
copper_trade_channel_vulnerability_marker	trade_channel_disruption	Cold War geopolitics; Strategic commodities / copper / resource sovereignty	relational_marker	sector	Chile copper sector	Fordist era; chapter-specific follow-up needed	weak	high	5	This is one of the few routes from the current WS pass into a copper-facing AR candidate.	Direct embargo, trade, or shipment passages tied to specific copper channels.
pre_allende_policy_pressure_architecture	coercive_state_pressure	Inter-American order / hemispheric security doctrine; U.S. interventionism	institutional_indicator	regional	Latin America with Chile relevance	1958-1961	medium	medium	6	Useful for periodizing the pressure architecture that predates the Allende years.	A cleaner link from this architecture to later Chile-specific episodes.
alternative_diplomatic_corridor_access	diplomatic_isolation	Third World / Non-Aligned Movement / NIEO politics; Diplomatic isolation, blockade, recognition, and alliance structure	relational_marker	global	Chile relative to NAM diplomacy	1961-1973 plus summit follow-up	medium	medium	7	The current corpus does support diplomatic alternatives outside the inter-American corridor.	Chile-specific summit passages and clearer evidence that the corridor was actionable rather than symbolic.
nam_option_set_expansion_marker	counter_hegemonic_alignment	Third World / Non-Aligned Movement / NIEO politics	relational_marker	global	NAM / Third World	1954-1970s	medium	medium	8	This captures how NAM widened external strategic possibilities without assuming immediate material transmission.	A stronger Chile-facing bridge and a rule for moving from diplomatic option-set to AR relevance.
hemispheric_security_legitimation_marker	security_doctrine_legitimation	Inter-American order / hemispheric security doctrine; Diplomatic isolation, blockade, recognition, and alliance structure	institutional_indicator	regional	Chile / inter-American system	Cold War; source-specific	medium	medium	9	This variable can organize pressure and diplomacy coding under a common legitimation layer.	Better separation between rhetoric, doctrine, and actual coercive implementation.
soviet_chile_alignment_contact_density	counter_hegemonic_alignment	Cold War geopolitics	documentary_marker	bilateral	Chile-USSR	1960s	medium	medium	10	The archival collection suggests a codable document-density measure for external alignment contacts.	Document-level extraction rules and a consistent denominator for density coding.
resource_sovereignty_conflict_marker	commodity_sovereignty_conflict	Strategic commodities / copper / resource sovereignty; Third World / Non-Aligned Movement / NIEO politics	relational_marker	cross_scalar	Chile within global commodity politics	1960s-1970s	weak	high	11	This is the current corpus's main route into sovereignty-conflict coding, even if still weak.	Chile-specific copper passages, actor-level episodes, and a cleaner link to measurable external constraints.
"""


def load_tsv(text: str) -> list[dict[str, str]]:
    return list(csv.DictReader(StringIO(text.strip()), delimiter="\t"))


def load_registry() -> dict[str, dict[str, str]]:
    with REGISTRY_PATH.open("r", encoding="utf-8", newline="") as handle:
        return {row["ws_id"]: row for row in csv.DictReader(handle)}


def load_queue_tiers() -> dict[str, int]:
    tiers: dict[str, int] = {}
    tier = 0
    for line in QUEUE_PATH.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("## Tier 1"):
            tier = 1
            continue
        if stripped.startswith("## Tier 2"):
            tier = 2
            continue
        if stripped.startswith("## Tier 3"):
            tier = 3
            continue
        if stripped.startswith("- `") and tier:
            match = re.match(r"- `([^`]+)`", stripped)
            if match:
                tiers[match.group(1)] = tier
    return tiers


def parse_note_anchors(note_path: Path) -> list[dict[str, str | int]]:
    anchors: list[dict[str, str | int]] = []
    in_section = False
    for line in note_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped == "# Key page-anchored extracts":
            in_section = True
            continue
        if in_section and stripped.startswith("# "):
            break
        if in_section and stripped.startswith("- p. "):
            match = re.match(r"- p\. (\d+): (.+)", stripped)
            if match:
                anchors.append(
                    {
                        "page": int(match.group(1)),
                        "page_anchor": f"p. {match.group(1)}",
                        "quote_stub": match.group(2).strip(),
                    }
                )
    return anchors


def anchor_for(anchors: list[dict[str, str | int]], page: int) -> dict[str, str]:
    for anchor in anchors:
        if anchor["page"] == page:
            return {
                "page_anchor": str(anchor["page_anchor"]),
                "quote_stub": str(anchor["quote_stub"]),
            }
    if anchors:
        return {
            "page_anchor": str(anchors[0]["page_anchor"]),
            "quote_stub": str(anchors[0]["quote_stub"]),
        }
    return {"page_anchor": "p. ?", "quote_stub": "page anchor missing in source note"}


def validate_row(row: dict[str, str]) -> None:
    for field, allowed_values in ALLOWED.items():
        if row[field] not in allowed_values:
            raise ValueError(f"{field} has invalid value: {row[field]}")
    if row["dimension_primary"] not in DIMENSIONS:
        raise ValueError(f"Unknown primary dimension: {row['dimension_primary']}")
    if row["dimension_secondary"] != "unclear" and row["dimension_secondary"] not in DIMENSIONS:
        raise ValueError(f"Unknown secondary dimension: {row['dimension_secondary']}")
    if row["mechanism_family"] not in MECHANISMS:
        raise ValueError(f"Unknown mechanism family: {row['mechanism_family']}")


def build_crosswalk_rows(registry: dict[str, dict[str, str]], queue_tiers: dict[str, int]) -> list[dict[str, str]]:
    repo_root = ROOT.parent.parent
    note_cache: dict[str, list[dict[str, str | int]]] = {}
    rows: list[dict[str, str]] = []
    for idx, spec in enumerate(load_tsv(ROW_SPEC_TSV), start=1):
        source = registry[spec["ws_id"]]
        if source["relevance_grade"] not in {"A", "B"}:
            raise ValueError(f"{spec['ws_id']} is not A/B graded.")
        if queue_tiers.get(source["file_name"]) not in {1, 2}:
            raise ValueError(f"{spec['ws_id']} is not in Tier 1 or Tier 2.")
        if spec["ws_id"] not in note_cache:
            note_cache[spec["ws_id"]] = parse_note_anchors(repo_root / source["notes_path"])
        anchor = anchor_for(note_cache[spec["ws_id"]], int(spec["anchor_page"]))
        row = {
            "row_id": f"WSAR_{idx:03d}",
            "ws_id": spec["ws_id"],
            "source_file": source["file_name"],
            "source_relevance_grade": source["relevance_grade"],
            "source_role": source["probable_source_role"],
            "evidentiary_status": source["probable_evidentiary_status"],
            "corridor_scope": source["probable_corridor_scope"],
            "hinge_role": spec["hinge_role"],
            "dimension_primary": source["dimension_final_primary"],
            "dimension_secondary": source["dimension_final_secondary"] or "unclear",
            "mechanism_family": spec["mechanism_family"],
            "mechanism_statement": spec["mechanism_statement"],
            "chile_specific": spec["chile_specific"],
            "transmission_corridor": spec["transmission_corridor"],
            "candidate_observable": spec["candidate_observable"],
            "candidate_indicator": spec["candidate_indicator"],
            "candidate_ar_variable": spec["candidate_ar_variable"],
            "variable_type": spec["variable_type"],
            "scale": spec["scale"],
            "geography": spec["geography"],
            "temporal_layer": spec["temporal_layer"],
            "temporal_window": spec["temporal_window"],
            "zavaleta_operator_route": spec["zavaleta_operator_route"],
            "configurational_role": spec["configurational_role"],
            "translation_risk": spec["translation_risk"],
            "evidentiary_strength": spec["evidentiary_strength"],
            "page_anchor": anchor["page_anchor"],
            "quote_stub": anchor["quote_stub"],
            "notes_path": source["notes_path"],
            "keep_flag": source["keep_flag"],
            "comments": spec["comments"],
        }
        validate_row(row)
        rows.append(row)
    return rows


def build_shortlist(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    grouped_sources: dict[str, set[str]] = defaultdict(set)
    for row in rows:
        grouped_sources[row["candidate_ar_variable"]].add(row["ws_id"])
    shortlist_rows: list[dict[str, str]] = []
    for idx, spec in enumerate(load_tsv(SHORTLIST_TSV), start=1):
        supporting = sorted(grouped_sources[spec["candidate_ar_variable"]])
        if not supporting:
            raise ValueError(f"No supporting rows for {spec['candidate_ar_variable']}")
        shortlist_rows.append(
            {
                "shortlist_id": f"ARV_{idx:03d}",
                "candidate_ar_variable": spec["candidate_ar_variable"],
                "derived_from_mechanism": spec["derived_from_mechanism"],
                "supporting_sources": "; ".join(supporting),
                "dimension_cluster": spec["dimension_cluster"],
                "variable_type": spec["variable_type"],
                "scale": spec["scale"],
                "geography": spec["geography"],
                "temporal_window": spec["temporal_window"],
                "evidentiary_strength": spec["evidentiary_strength"],
                "translation_risk": spec["translation_risk"],
                "priority_rank": spec["priority_rank"],
                "why_promising": spec["why_promising"],
                "what_is_missing": spec["what_is_missing"],
            }
        )
    return shortlist_rows


def write_csv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def mechanism_summary(rows: list[dict[str, str]]) -> dict[str, list[str]]:
    grouped: dict[str, set[str]] = defaultdict(set)
    for row in rows:
        grouped[row["mechanism_family"]].add(row["candidate_ar_variable"])
    return {mechanism: sorted(grouped.get(mechanism, set())) for mechanism in MECHANISMS}


def strongest_hinge_sources(rows: list[dict[str, str]]) -> list[str]:
    scores = Counter()
    for row in rows:
        scores[row["ws_id"]] += 2 if row["hinge_role"] == "core" else 1
        scores[row["ws_id"]] += {"low": 2, "medium": 1, "high": 0}[row["translation_risk"]]
    return [ws_id for ws_id, _score in sorted(scores.items(), key=lambda item: (-item[1], item[0]))]


def write_summary(rows: list[dict[str, str]], shortlist_rows: list[dict[str, str]], registry: dict[str, dict[str, str]]) -> None:
    distinct_sources = sorted({row["ws_id"] for row in rows})
    dim_counts = Counter(row["dimension_primary"] for row in rows)
    mech_counts = Counter(row["mechanism_family"] for row in rows)
    risk_counts = Counter(row["translation_risk"] for row in rows)
    hinge_notes = {
        "WS_007": "Direct Chile-facing pressure, diplomacy, and finance transmission.",
        "WS_003": "Archival support-channel evidence instead of generic Cold War framing.",
        "WS_008": "Chile-specific edited volume with diplomatic and copper-facing hooks.",
        "WS_013": "Archival Soviet-Chile document collection suited to later density coding.",
        "WS_015": "Pre-Allende regional-policy architecture for the pressure cluster.",
        "WS_010": "Best secondary NAM source for alternative diplomatic-corridor routing.",
        "WS_014": "Useful state-apparatus threat framing, but still high-risk and OCR-limited.",
    }
    hinge_lines = []
    preferred_hinge_order = ["WS_007", "WS_003", "WS_008", "WS_013", "WS_015", "WS_010", "WS_014"]
    ranked_hinges = strongest_hinge_sources(rows)
    for ws_id in preferred_hinge_order + [item for item in ranked_hinges if item not in preferred_hinge_order]:
        if ws_id in hinge_notes and len(hinge_lines) < 6:
            hinge_lines.append(f"- `{ws_id}` `{registry[ws_id]['file_name']}`: {hinge_notes[ws_id]}")
    mech_map = mechanism_summary(rows)
    lines = [
        "# WS->AR Crosswalk Summary",
        "",
        "## 1. Executive summary",
        f"- Usable sources for AR translation: {len(distinct_sources)} of 21 current WS source notes.",
        f"- Crosswalk rows created: {len(rows)}.",
        f"- Shortlisted AR candidate variables: {len(shortlist_rows)}.",
        "- Sources promoted into the crosswalk were restricted to A/B items already in Tier 1 or Tier 2; no C-grade or theory-only item was promoted.",
        "- Dimensions translating most successfully right now: Inter-American order / hemispheric security doctrine, Cold War geopolitics, and Third World / Non-Aligned Movement / NIEO politics (the first two because they carry the best Chile-specific hinge rows; the third mainly through alternative diplomatic-corridor routing rather than direct Chile transmission).",
        "- Dimensions still failing translation: Crisis of Atlantic Fordism / world monetary disorder, External constraint / balance-of-payments / trade dependency, and Transnational capital / multinational corporate power have no source-grounded rows; Strategic commodities / copper / resource sovereignty remains only thinly translated; Diplomatic isolation, blockade, recognition, and alliance structure still depends on secondary rather than dedicated primary anchors.",
        f"- Translation risk profile: low={risk_counts['low']}, medium={risk_counts['medium']}, high={risk_counts['high']}.",
        "",
        "## 2. Highest-value hinge sources",
        *hinge_lines,
        "",
        "## 3. Candidate AR variables by mechanism family",
        f"- coercive_state_pressure: {', '.join(mech_map['coercive_state_pressure']) if mech_map['coercive_state_pressure'] else 'no source-grounded candidate yet'}",
        f"- diplomatic_isolation: {', '.join(mech_map['diplomatic_isolation']) if mech_map['diplomatic_isolation'] else 'no source-grounded candidate yet'}",
        f"- financial_strangulation: {', '.join(mech_map['financial_strangulation']) if mech_map['financial_strangulation'] else 'no source-grounded candidate yet'}",
        f"- trade_channel_disruption: {', '.join(mech_map['trade_channel_disruption']) if mech_map['trade_channel_disruption'] else 'no source-grounded candidate yet'}",
        f"- transnational_corporate_retaliation: {', '.join(mech_map['transnational_corporate_retaliation']) if mech_map['transnational_corporate_retaliation'] else 'no source-grounded candidate yet'}",
        f"- commodity_sovereignty_conflict: {', '.join(mech_map['commodity_sovereignty_conflict']) if mech_map['commodity_sovereignty_conflict'] else 'no source-grounded candidate yet'}",
        f"- counter_hegemonic_alignment: {', '.join(mech_map['counter_hegemonic_alignment']) if mech_map['counter_hegemonic_alignment'] else 'no source-grounded candidate yet'}",
        f"- security_doctrine_legitimation: {', '.join(mech_map['security_doctrine_legitimation']) if mech_map['security_doctrine_legitimation'] else 'no source-grounded candidate yet'}",
        "",
        "## 4. Translation risks",
        "- Zavaleta-based routing helped mainly by forcing scale, operator, and configurational-role choices before variable naming, which blocked theory-led promotion of broad Cold War atmosphere into fake AR variables.",
        "- The highest-risk rows are the copper and resource-sovereignty candidates because current first-pass notes still lack direct Chile-specific episode passages on trade blockage, copper channels, or corporate retaliation.",
        "- The CIA NAM document remains useful only as a high-risk classifier-routed support source because OCR is missing and Chile linkage is indirect.",
        "- Soviet support-channel rows are promising but still medium risk because party-finance evidence does not automatically translate into an AR-significant variable without later adjudication.",
        "",
        "## 5. Immediate next deep-read priorities",
        "- `WS_007` for sanctions, credit, OAS, and pressure episode extraction.",
        "- `WS_003` for dated Soviet support-channel episodes and recipient-channel coding.",
        "- `WS_008` for Chile-specific OAS, copper, and trade-channel passages.",
        "- `WS_013` for document-cluster extraction around Soviet-Chile contact in the 1960s.",
        "- `WS_015` for pre-Allende pressure architecture and doctrinal sequencing.",
        "- `WS_010` and `WS_020` for Chile-facing NAM corridor passages that can move from background to codable diplomatic alternatives.",
        "- Immediate ingestion need outside the current crosswalk: dedicated sources on external finance, copper-specific conflict, multinational corporate retaliation, and BoP/trade dependency.",
        "",
        "## Appendix: row counts by primary dimension",
    ]
    for dimension, count in dim_counts.most_common():
        lines.append(f"- {dimension}: {count}")
    lines.extend(["", "## Appendix: row counts by mechanism family"])
    for mechanism, count in mech_counts.items():
        lines.append(f"- {mechanism}: {count}")
    SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    registry = load_registry()
    queue_tiers = load_queue_tiers()
    rows = build_crosswalk_rows(registry, queue_tiers)
    shortlist_rows = build_shortlist(rows)
    write_csv(CROSSWALK_PATH, ROW_FIELDS, rows)
    write_csv(SHORTLIST_PATH, SHORTLIST_FIELDS, shortlist_rows)
    write_summary(rows, shortlist_rows, registry)


if __name__ == "__main__":
    main()
