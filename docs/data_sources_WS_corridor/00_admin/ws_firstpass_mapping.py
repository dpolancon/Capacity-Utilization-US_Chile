from __future__ import annotations

import csv
import hashlib
import re
import unicodedata
from collections import Counter, defaultdict
from io import StringIO
from pathlib import Path

import pdfplumber


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "01_sources_raw" / "flat_current_corpus"
NOTES_DIR = ROOT / "02_notes" / "sources"
DIM_DIR = ROOT / "02_notes" / "dimensions"
MECH_DIR = ROOT / "02_notes" / "mechanisms"
ADMIN_DIR = ROOT / "00_admin"
MAP_DIR = ROOT / "04_mappings"
BIB_DIR = ROOT / "03_bibliography"
EXPORT_DIR = ROOT / "06_exports"
REGISTRY_PATH = ADMIN_DIR / "ws_registry_master.csv"
QUEUE_PATH = ADMIN_DIR / "ws_reading_queue.md"
SUMMARY_PATH = EXPORT_DIR / "firstpass_summary.md"

DIMENSIONS = {
    "D01": "Cold War geopolitics",
    "D02": "U.S. interventionism",
    "D03": "Third World / Non-Aligned Movement / NIEO politics",
    "D04": "Crisis of Atlantic Fordism / world monetary disorder",
    "D05": "External constraint / balance-of-payments / trade dependency",
    "D06": "Transnational capital / multinational corporate power",
    "D07": "Strategic commodities / copper / resource sovereignty",
    "D08": "Inter-American order / hemispheric security doctrine",
    "D09": "Diplomatic isolation, blockade, recognition, and alliance structure",
}
DIM_CODE_BY_LABEL = {label: code for code, label in DIMENSIONS.items()}

MECHANISMS = {
    "coercive_state_pressure": ("M01", "Coercive State Pressure"),
    "diplomatic_isolation": ("M02", "Diplomatic Isolation"),
    "financial_strangulation": ("M03", "Financial Strangulation"),
    "trade_channel_disruption": ("M04", "Trade Channel Disruption"),
    "transnational_corporate_retaliation": ("M05", "Transnational Corporate Retaliation"),
    "commodity_sovereignty_conflict": ("M06", "Commodity Sovereignty Conflict"),
    "counter_hegemonic_alignment": ("M07", "Counter-Hegemonic Alignment"),
    "security_doctrine_legitimation": ("M08", "Security Doctrine Legitimation"),
}

OBSERVABLE_BY_MECHANISM = {
    "coercive_state_pressure": "documented episodes of direct or indirect state pressure",
    "diplomatic_isolation": "recognition shifts, OAS/UN positioning, or bilateral distancing",
    "financial_strangulation": "credit denial, sanctions, or financing pressure",
    "trade_channel_disruption": "trade interruptions, embargoes, or channel restrictions",
    "transnational_corporate_retaliation": "multinational lobbying, disinvestment, or corporate-state coordination",
    "commodity_sovereignty_conflict": "resource nationalization or copper-sovereignty disputes",
    "counter_hegemonic_alignment": "efforts to build non-hegemonic international alignment",
    "security_doctrine_legitimation": "anticommunist or hemispheric-security legitimation frames",
}

VARIABLE_BY_MECHANISM = {
    "coercive_state_pressure": ("pressure_episode_count", "event count"),
    "diplomatic_isolation": ("diplomatic_isolation_episode", "binary/event marker"),
    "financial_strangulation": ("credit_sanctions_episode", "binary/event marker"),
    "trade_channel_disruption": ("trade_disruption_episode", "binary/event marker"),
    "transnational_corporate_retaliation": ("corporate_retaliation_episode", "event count"),
    "commodity_sovereignty_conflict": ("resource_sovereignty_conflict", "event marker"),
    "counter_hegemonic_alignment": ("alignment_reference_count", "reference count"),
    "security_doctrine_legitimation": ("security_doctrine_invocation_count", "reference count"),
}

EVIDENCE_MARKERS = {
    "EM_ARCHIVAL_SOVIET": ("archival", "archival Soviet-party or Soviet-state documentary reference"),
    "EM_PARTY_FINANCE": ("financial", "direct mention of party finance, transfers, or material aid"),
    "EM_ALIGNMENT_REFERENCE": ("diplomatic", "reference to alignment, non-alignment, or bloc positioning"),
    "EM_POLICY_PRESSURE": ("policy", "reference to overt policy pressure or coercive measures"),
    "EM_SECURITY_FRAME": ("discursive", "security or anticommunist legitimation frame"),
    "EM_CREDIT_SANCTIONS": ("economic", "credit, sanctions, or financing-pressure reference"),
    "EM_RESOURCE_SOVEREIGNTY": ("economic", "resource sovereignty or copper-nationalization reference"),
    "EM_TRADE_CHANNEL": ("economic", "trade-channel disruption or embargo reference"),
    "EM_BOOK_REVIEW": ("review", "book-review style evaluative source rather than primary research article"),
    "EM_DECOLONIZATION_FRAME": ("conceptual", "decolonization or Third World autonomy frame"),
}

DIMENSION_FILES = {
    "D01": "D01_cold_war_geopolitics.md",
    "D02": "D02_us_interventionism.md",
    "D03": "D03_nam_nieo.md",
    "D04": "D04_atlantic_fordism_world_disorder.md",
    "D05": "D05_external_constraint_bop.md",
    "D06": "D06_transnational_capital.md",
    "D07": "D07_strategic_commodities_copper.md",
    "D08": "D08_inter_american_order.md",
    "D09": "D09_diplomatic_isolation_alliances.md",
}

MECHANISM_FILES = {
    "coercive_state_pressure": "M01_coercive_state_pressure.md",
    "diplomatic_isolation": "M02_diplomatic_isolation.md",
    "financial_strangulation": "M03_financial_strangulation.md",
    "trade_channel_disruption": "M04_trade_channel_disruption.md",
    "transnational_corporate_retaliation": "M05_transnational_corporate_retaliation.md",
    "commodity_sovereignty_conflict": "M06_commodity_sovereignty_conflict.md",
    "counter_hegemonic_alignment": "M07_counter_hegemonic_alignment.md",
    "security_doctrine_legitimation": "M08_security_doctrine_legitimation.md",
}


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-z0-9]+", " ", text.lower())
    return re.sub(r"\s+", " ", text).strip()


def safe_page_text(page) -> str:
    try:
        return page.extract_text() or ""
    except Exception:
        return ""


def first_text_page(texts: list[str]) -> int:
    for idx, text in enumerate(texts, start=1):
        if text.strip():
            return idx
    return 1


def keyword_page(texts: list[str], keyword: str) -> int | None:
    needle = normalize(keyword)
    if not needle:
        return None
    for idx, text in enumerate(texts, start=1):
        if needle in normalize(text):
            return idx
    return None


def short_line(text: str, limit: int = 100) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) <= limit else text[: limit - 3].rstrip() + "..."


def intro_lines(texts: list[str], max_lines: int = 4) -> list[str]:
    lines: list[str] = []
    for text in texts[:3]:
        for line in text.splitlines():
            line = re.sub(r"\s+", " ", line).strip()
            if line:
                lines.append(line)
            if len(lines) >= max_lines:
                return lines
    return lines


def confidence(grade: str, secondary: bool = False) -> str:
    if grade == "A":
        return "high" if not secondary else "medium"
    if grade == "B":
        return "medium" if not secondary else "low"
    return "low"


def scope_relation(scope: str) -> str:
    if scope == "overlap":
        return "Direct overlap with the AR corridor via Chile-specific material."
    if scope == "WS-only":
        return "AR relation is indirect and comparative rather than source-internal."
    return "AR relation is not yet established from the first-pass evidence."


CONFIG_TSV = """ws_id	citekey	title	author	year	source_type	corridor_scope	source_role	evidentiary_status	dimension_primary	dimension_secondary	relevance_grade	mechanism_1	mechanism_2	mechanism_3	evidence_marker_1	evidence_marker_2	keep_flag	bib_status	tier	fit_reason	anchor_1	anchor_2	anchor_3	follow_up
WS_001	ulianova2000unidadpopular	La Unidad Popular y el golpe militar en Chile: percepciones y analisis sovieticos	Olga Ulianova	2000	article	overlap	historiography	historiographic	Cold War geopolitics	unclear	A	counter_hegemonic_alignment	security_doctrine_legitimation	unclear	EM_ARCHIVAL_SOVIET	EM_SECURITY_FRAME	keep	verified	2	Directly addresses Soviet readings of Popular Unity and the 1973 coup in Chile.	allende	urss	cuba	Verify whether specific Soviet assessments can be coded by actor and date.
WS_002	ulianova2003lonquimay	Levantamiento campesino de Lonquimay y la Internacional Comunista	Olga Ulianova	2003	article	unclear	historiography	historiographic	unclear	unclear	C	counter_hegemonic_alignment	unclear	unclear	EM_ALIGNMENT_REFERENCE		peripheral	verified	3	Chile-Comintern linkage is relevant as background, but the case predates the dissertation corridor and remains indirect.	chile	internacional	moscu	Only revisit if early communist international linkages become analytically necessary.
WS_003	ulianovafediakova1998ayuda	Algunos aspectos de la ayuda financiera del Partido Comunista de la URSS al comunismo chileno durante la Guerra Fria	Olga Ulianova; Eugenia Fediakova	1998	article	overlap	evidence	archival	Cold War geopolitics	unclear	A	counter_hegemonic_alignment	diplomatic_isolation	unclear	EM_ARCHIVAL_SOVIET	EM_PARTY_FINANCE	keep	verified	1	Provides direct evidence on Soviet financial support to Chilean communism during the Cold War.	ayuda	urss	allende	Capture concrete aid episodes and recipient channels for later coding.
WS_004	ahumada2025destiny	True master of our own destiny: the Third World and the decolonisation of political freedom	Jose Miguel Ahumada	2025	article	WS-only	theory	conceptual	Third World / Non-Aligned Movement / NIEO politics	unclear	A	counter_hegemonic_alignment	unclear	unclear	EM_DECOLONIZATION_FRAME	EM_ALIGNMENT_REFERENCE	keep	verified	1	Supplies a direct conceptual frame for Third World autonomy and decolonizing political freedom.	third world	allende	intervention	Use for ontology framing rather than empirical coding claims.
WS_005	rasmussenknutsen2020reforming	Reforming to Survive: The Bolshevik Origins of Social Policies	Magnus Bergli Rasmussen; Carl Henrik Knutsen	2020	working paper	unclear	theory	conceptual	unclear	unclear	C	coercive_state_pressure	unclear	unclear	EM_POLICY_PRESSURE		defer	verified	3	Useful only as distant background on threat-induced reform logic, not as a corridor source.	revolution	soviet	chile	Defer unless a coercion-to-reform mechanism requires external conceptual support.
WS_006	prashad2008darker	The darker nations: a people's history of the Third World	Vijay Prashad	2008	book	WS-only	historiography	historiographic	Third World / Non-Aligned Movement / NIEO politics	Cold War geopolitics	A	counter_hegemonic_alignment	diplomatic_isolation	commodity_sovereignty_conflict	EM_DECOLONIZATION_FRAME	EM_RESOURCE_SOVEREIGNTY	keep	verified	1	Strong background source for Third World alignment politics and resource-sovereignty debates.	non-alignment	allende	copper	Extract specific chapters and pages on Chile, copper, and Third World political economy.
WS_007	harmer2011allende	Allende's Chile and the Inter-American Cold War	Tanya Harmer	2011	book	overlap	historiography	historiographic	Inter-American order / hemispheric security doctrine	U.S. interventionism	A	coercive_state_pressure	diplomatic_isolation	financial_strangulation	EM_POLICY_PRESSURE	EM_CREDIT_SANCTIONS	keep	verified	1	Direct anchor source for Chile, inter-American politics, and the regional Cold War setting of pressure on Allende.	allende	oas	sanctions	Deep-read the Chile-, OAS-, and economic-pressure chapters for episode coding.
WS_008	harmerriquelme2014chileglobal	Chile y la Guerra Fria global	Tanya Harmer; Alfredo Riquelme Segovia (eds.)	2014	edited volume	overlap	historiography	historiographic	Cold War geopolitics	Inter-American order / hemispheric security doctrine	B	diplomatic_isolation	security_doctrine_legitimation	trade_channel_disruption	EM_ALIGNMENT_REFERENCE	EM_TRADE_CHANNEL	keep	verified	2	Edited volume gives broad Chile-focused global Cold War context and likely chapter-level coverage of multiple mechanisms.	allende	oas	copper	Identify which chapters are most directly relevant to trade, diplomacy, and security framing.
WS_009	ulianovaloyolaalvarez2012siglo	1912-2012 El siglo de los comunistas chilenos	Olga Ulianova; Manuel Loyola; Rolando Alvarez (eds.)	2012	edited volume	overlap	historiography	historiographic	Cold War geopolitics	unclear	B	counter_hegemonic_alignment	security_doctrine_legitimation	unclear	EM_ALIGNMENT_REFERENCE		keep	verified	2	Useful overlap source on Chilean communism, but broader than the WS corridor and not exclusively Cold War externality.	urss	allende	cuba	Locate Cold War chapters that directly treat foreign links, aid, or bloc positioning.
WS_010	cavoski2022summits	Non-Aligned Movement Summits: A History	Jovan Cavoski	2022	book	WS-only	historiography	historiographic	Third World / Non-Aligned Movement / NIEO politics	Diplomatic isolation, blockade, recognition, and alliance structure	A	counter_hegemonic_alignment	diplomatic_isolation	security_doctrine_legitimation	EM_ALIGNMENT_REFERENCE	EM_SECURITY_FRAME	keep	verified	1	Core source for NAM summit politics and collective diplomatic positioning.	non-alignment	chile	allende	Trace Chile-, Allende-, and sanctions-related summit references.
WS_011	westad2017coldwar	The Cold War: A World History	Odd Arne Westad	2017	book	WS-only	historiography	historiographic	Cold War geopolitics	Third World / Non-Aligned Movement / NIEO politics	B	security_doctrine_legitimation	counter_hegemonic_alignment	commodity_sovereignty_conflict	EM_SECURITY_FRAME	EM_RESOURCE_SOVEREIGNTY	keep	verified	1	General Cold War anchor that supplies global geopolitical context for Chile-facing mechanism work.	allende	non-aligned	copper	Use selectively for global framing and comparative Cold War positioning.
WS_012	ws012huneeusreview	La Guerra Fria Chilena: Gabriel Gonzalez Videla y la Ley Maldita	Alfonso Salgado	unknown	book review	overlap	historiography	historiographic	Cold War geopolitics	Inter-American order / hemispheric security doctrine	C	security_doctrine_legitimation	coercive_state_pressure	unclear	EM_BOOK_REVIEW	EM_SECURITY_FRAME	peripheral	unresolved	3	Useful as a pointer to a more substantial Chilean Cold War monograph, but the review itself is not an anchor source.	anticomunista	gonzalez	chile	Recover publication year and journal metadata if the review itself needs to be cited.
WS_013	ulianova2020archivossovieticos	Chile en los archivos sovieticos: anos 60	Olga Ulianova (comp.)	2020	edited volume	overlap	evidence	archival	Cold War geopolitics	unclear	B	counter_hegemonic_alignment	diplomatic_isolation	unclear	EM_ARCHIVAL_SOVIET	EM_ALIGNMENT_REFERENCE	keep	verified	2	Document collection with direct Soviet archival material on Chile in the 1960s.	urss	allende	copper	Identify specific document clusters on diplomacy, party ties, and commodity politics.
WS_014	ciaNonalignedUndated	THE NONALIGNED MOVEMENT: DYNAMICS AND PROSPECTS <Sanitized>	unknown	unknown	declassified document	WS-only	evidence	archival	Third World / Non-Aligned Movement / NIEO politics	Diplomatic isolation, blockade, recognition, and alliance structure	A	diplomatic_isolation	counter_hegemonic_alignment	security_doctrine_legitimation	EM_POLICY_PRESSURE	EM_ALIGNMENT_REFERENCE	keep	unresolved	1	Direct documentary source on how a U.S. intelligence actor framed the Non-Aligned Movement.	nonaligned	prospects	security	Manual OCR or visual review is needed because local text extraction is unavailable.
WS_015	allcock2014alliance	The First Alliance for Progress? Reshaping the Eisenhower Administration's Policy toward Latin America	Thomas Tunstall Allcock	2014	journal article	overlap	historiography	historiographic	Inter-American order / hemispheric security doctrine	U.S. interventionism	B	coercive_state_pressure	security_doctrine_legitimation	unclear	EM_POLICY_PRESSURE	EM_SECURITY_FRAME	keep	verified	2	Important hemispheric-policy background for U.S. regional strategy before the Chilean case.	eisenhower	intervention	chile	Use for early hemispheric doctrine and pre-Allende policy context.
WS_016	friedman2018enemy	The Enemy of My Enemy: The Soviet Union, East Germany, and the Iranian Tudeh Party's Support for Ayatollah Khomeini	Jeremy Friedman	2018	journal article	WS-only	historiography	historiographic	Cold War geopolitics	unclear	C	counter_hegemonic_alignment	unclear	unclear	EM_ALIGNMENT_REFERENCE		peripheral	verified	3	Relevant only as comparative Cold War alignment material; Chile relevance is indirect.	soviet	allende	intervention	Retain as a comparative non-Chile case only if alignment analogies are later needed.
WS_017	buclin2017swiss	Swiss Intellectuals and the Cold War: Anti-Communist Policies in a Neutral Country	Hadrien Buclin	2017	journal article	WS-only	historiography	historiographic	Cold War geopolitics	unclear	C	security_doctrine_legitimation	coercive_state_pressure	unclear	EM_SECURITY_FRAME	EM_POLICY_PRESSURE	peripheral	verified	3	General anti-communist comparison source rather than a corridor-specific Chile or NAM source.	anti-communist	neutral	swiss	Only revisit if neutral-country comparison becomes analytically useful.
WS_018	henrichfranke2014crosscurtain	Cross-Curtain Radio Cooperation and New International Alignments during the Cold War	Christian Henrich-Franke	2014	journal article	WS-only	historiography	historiographic	Cold War geopolitics	Third World / Non-Aligned Movement / NIEO politics	C	diplomatic_isolation	counter_hegemonic_alignment	unclear	EM_ALIGNMENT_REFERENCE		defer	verified	3	Potentially useful for Third World voting and global-alignments background, but only indirectly tied to the corridor.	third world	alignments	cold war	Revisit only if communications governance becomes relevant to alliance-structure work.
WS_019	zivoticcavoski2014belgrade	On the Road to Belgrade: Yugoslavia, Third World Neutrals, and the Evolution of Global Non-Alignment, 1954-1961	Aleksandar Zivotic; Jovan Cavoski	2014	journal article	WS-only	historiography	historiographic	Third World / Non-Aligned Movement / NIEO politics	Diplomatic isolation, blockade, recognition, and alliance structure	B	counter_hegemonic_alignment	diplomatic_isolation	unclear	EM_ALIGNMENT_REFERENCE		keep	verified	1	Central article on the formation of global non-alignment and the diplomatic logic behind it.	non-alignment	yugoslavia	diplomacy	Use to map formative NAM mechanisms and alliance-structure language.
WS_020	luthi2016nam	The Non-Aligned Movement and the Cold War, 1961-1973	Lorenz M. Luthi	2016	journal article	WS-only	historiography	historiographic	Third World / Non-Aligned Movement / NIEO politics	Diplomatic isolation, blockade, recognition, and alliance structure	A	counter_hegemonic_alignment	diplomatic_isolation	security_doctrine_legitimation	EM_ALIGNMENT_REFERENCE	EM_SECURITY_FRAME	keep	verified	1	Directly tracks the NAM as a Cold War actor and is central for the WS corridor ontology.	non-aligned	diplomacy	cuba	Deep-read for NAM agenda items and constraints that can be operationalized.
WS_021	ulianova1998primeroscontactos	Primeros contactos entre el Partido Comunista de Chile y Komintern	Olga Ulianova	1998	article	unclear	historiography	historiographic	unclear	unclear	C	counter_hegemonic_alignment	unclear	unclear	EM_ALIGNMENT_REFERENCE		peripheral	verified	3	Background on early Chile-Komintern contact; useful only if the genealogy of external communist ties becomes necessary.	komintern	chile	contactos	Keep as a background genealogy source rather than a core corridor item.
"""


def load_config() -> dict[str, dict[str, str]]:
    reader = csv.DictReader(StringIO(CONFIG_TSV), delimiter="\t")
    data: dict[str, dict[str, str]] = {}
    for row in reader:
        row["tier"] = int(row["tier"])
        data[row["ws_id"]] = row
    return data


def note_path_for(ws_id: str) -> Path:
    return NOTES_DIR / f"{ws_id}.md"


def repo_relative(path: Path) -> str:
    return path.relative_to(ROOT.parent.parent).as_posix()


def mechanism_list(config: dict[str, str]) -> list[str]:
    return [config["mechanism_1"], config["mechanism_2"], config["mechanism_3"]]


def marker_list(config: dict[str, str]) -> list[str]:
    return [marker for marker in [config["evidence_marker_1"], config["evidence_marker_2"]] if marker]


def variable_blocks(config: dict[str, str]) -> list[dict[str, str]]:
    blocks: list[dict[str, str]] = []
    geography = "Chile" if config["corridor_scope"] == "overlap" else "transnational / comparative" if config["corridor_scope"] == "WS-only" else "unclear"
    period = "Fordist era / source-specific" if config["corridor_scope"] in {"overlap", "WS-only"} else "unclear"
    for mechanism in mechanism_list(config):
        if mechanism == "unclear":
            continue
        var_name, var_type = VARIABLE_BY_MECHANISM[mechanism]
        blocks.append(
            {
                "variable": var_name,
                "type": var_type,
                "geography": geography,
                "period": period,
                "evidentiary_status": config["evidentiary_status"],
            }
        )
        if len(blocks) == 2:
            break
    if not blocks:
        blocks.append(
            {
                "variable": "unclear",
                "type": "unclear",
                "geography": geography,
                "period": period,
                "evidentiary_status": config["evidentiary_status"],
            }
        )
    return blocks


def observable_list(config: dict[str, str]) -> list[str]:
    observables: list[str] = []
    for mechanism in mechanism_list(config):
        if mechanism == "unclear":
            continue
        item = OBSERVABLE_BY_MECHANISM[mechanism]
        if item not in observables:
            observables.append(item)
        if len(observables) == 3:
            break
    while len(observables) < 3:
        observables.append("unclear / requires deeper reading")
    return observables


def anchor_lines(config: dict[str, str], texts: list[str]) -> list[str]:
    lines = intro_lines(texts)
    opening_page = first_text_page(texts)
    anchors: list[str] = []
    if lines:
        anchors.append(f'- p. {opening_page}: opening/title framing: {short_line(" ".join(lines[:2]), 110)}')
    else:
        anchors.append(f"- p. {opening_page}: opening framing not extractable from local text layer; manual visual review needed.")
    used_pages = {opening_page}
    for keyword in [config["anchor_1"], config["anchor_2"], config["anchor_3"]]:
        page = keyword_page(texts, keyword)
        if page is None or page in used_pages:
            continue
        anchors.append(f'- p. {page}: first extracted hit for "{keyword}".')
        used_pages.add(page)
        if len(anchors) == 3:
            break
    while len(anchors) < 3:
        fallback_page = min(len(texts) if texts else 1, len(used_pages) + 1)
        note = "text extraction unavailable; manual OCR needed." if not any(text.strip() for text in texts) else "additional page anchor reserved for manual follow-up."
        anchors.append(f"- p. {fallback_page}: {note}")
        used_pages.add(fallback_page)
    return anchors[:3]


def note_text(ws_id: str, row: dict[str, str], config: dict[str, str], page_count: int, checksum: str, texts: list[str]) -> str:
    observables = observable_list(config)
    variables = variable_blocks(config)
    dim_links = []
    if config["dimension_primary"] != "unclear":
        dim_links.append(DIM_CODE_BY_LABEL[config["dimension_primary"]])
    if config["dimension_secondary"] != "unclear":
        dim_links.append(DIM_CODE_BY_LABEL[config["dimension_secondary"]])
    mech_links = [MECHANISMS[item][0] for item in mechanism_list(config) if item != "unclear"]
    lines = [
        "---",
        f"ws_id: {ws_id}",
        f"citekey: {config['citekey']}",
        f"file_name: {row['file_name']}",
        f"source_type: {config['source_type']}",
        f"author: {config['author']}",
        f"year: {config['year']}",
        f"title: {config['title']}",
        f"corridor_scope: {config['corridor_scope']}",
        f"source_role: {config['source_role']}",
        f"evidentiary_status: {config['evidentiary_status']}",
        f"dimension_primary: {config['dimension_primary']}",
        f"dimension_secondary: {config['dimension_secondary']}",
        f"relevance_grade: {config['relevance_grade']}",
        "read_status: first_pass_complete",
        "---",
        "",
        "# Bibliographic verification",
        f"- verified title: {config['title']}",
        f"- verified author: {config['author']}",
        f"- verified year: {config['year']}",
        f"- pages: {page_count}",
        f"- checksum: {checksum}",
        "",
        "# Corridor fit",
        f"- WS-only / overlap / unclear: {config['corridor_scope']}",
        f"- why this source belongs or may belong in the WS corridor: {config['fit_reason']}",
        "",
        "# Mechanism candidates",
        f"1. {config['mechanism_1']}",
        f"2. {config['mechanism_2']}",
        f"3. {config['mechanism_3']}",
        "",
        "# Observables implied",
        f"- {observables[0]}",
        f"- {observables[1]}",
        f"- {observables[2]}",
        "",
        "# Candidate variables / indicators",
    ]
    for block in variables:
        lines.extend(
            [
                f"- variable: {block['variable']}",
                f"  type: {block['type']}",
                f"  geography: {block['geography']}",
                f"  period: {block['period']}",
                f"  evidentiary status: {block['evidentiary_status']}",
            ]
        )
    lines.extend(
        [
            "",
            "# Key page-anchored extracts",
            *anchor_lines(config, texts),
            "",
            "# Adjudication notes",
            f"- {config['keep_flag']}",
            f"- relation to AR corridor: {scope_relation(config['corridor_scope'])}",
            f"- cross-links to dimensions: {', '.join(dim_links) if dim_links else 'unclear'}",
            f"- cross-links to mechanism notes: {', '.join(mech_links) if mech_links else 'unclear'}",
            "",
            "# Next action",
            f"- add to dimension file: {', '.join(dim_links) if dim_links else 'unclear'}",
            f"- add to mechanism file: {', '.join(mech_links) if mech_links else 'unclear'}",
            f"- bib status: {config['bib_status']}",
            f"- follow-up needed: {config['follow_up']}",
            "",
        ]
    )
    return "\n".join(lines)


def bib_entry(config: dict[str, str], relative_path: str, ws_id: str) -> str:
    lines = [f"@misc{{{config['citekey']},"]
    if config["author"] != "unknown":
        lines.append(f"  author = {{{config['author']}}},")
    if config["title"] != "unknown":
        lines.append(f"  title = {{{config['title']}}},")
    if config["year"] != "unknown":
        lines.append(f"  year = {{{config['year']}}},")
    note = "First-pass verified local PDF" if config["bib_status"] == "verified" else "Metadata unresolved in first-pass review"
    lines.append(f"  note = {{{note}; ws_id={ws_id}}},")
    lines.append(f"  file = {{{relative_path}}}")
    lines.append("}")
    return "\n".join(lines)


def update_registry_row(row: dict[str, str], config: dict[str, str], relative_path: str, page_count: int, checksum: str, note_relative: str) -> None:
    observables = observable_list(config)
    variables = variable_blocks(config)
    dim_links = []
    if config["dimension_primary"] != "unclear":
        dim_links.append(DIM_CODE_BY_LABEL[config["dimension_primary"]])
    if config["dimension_secondary"] != "unclear":
        dim_links.append(DIM_CODE_BY_LABEL[config["dimension_secondary"]])

    row["relative_path"] = relative_path
    row["folder_cluster"] = "flat_current_corpus"
    row["title_guess"] = config["title"]
    row["author_guess"] = config["author"]
    row["year_guess"] = config["year"]
    row["citekey_guess"] = config["citekey"]
    row["source_type"] = config["source_type"]
    row["probable_dimension_primary"] = config["dimension_primary"]
    row["probable_dimension_secondary"] = config["dimension_secondary"]
    row["probable_source_role"] = config["source_role"]
    row["probable_evidentiary_status"] = config["evidentiary_status"]
    row["probable_corridor_scope"] = config["corridor_scope"]
    row["has_bib_entry"] = "true"
    row["related_note_exists"] = "true"
    row["related_note_path"] = note_relative
    row["relevance_grade"] = config["relevance_grade"]
    row["read_status"] = "first_pass_complete"
    row["title_verified"] = config["title"]
    row["author_verified"] = config["author"]
    row["year_verified"] = config["year"]
    row["pages"] = str(page_count)
    row["checksum"] = checksum
    row["dimension_final_primary"] = config["dimension_primary"]
    row["dimension_final_secondary"] = config["dimension_secondary"]
    row["mechanism_1"] = config["mechanism_1"]
    row["mechanism_2"] = config["mechanism_2"]
    row["mechanism_3"] = config["mechanism_3"]
    row["observable_1"] = observables[0]
    row["observable_2"] = observables[1]
    row["observable_3"] = observables[2]
    row["variable_1"] = variables[0]["variable"] if variables else "unclear"
    row["variable_2"] = variables[1]["variable"] if len(variables) > 1 else "unclear"
    row["evidence_marker_1"] = config["evidence_marker_1"]
    row["evidence_marker_2"] = config["evidence_marker_2"]
    row["crosslink_dimensions"] = ";".join(dim_links) if dim_links else "unclear"
    row["keep_flag"] = config["keep_flag"]
    row["notes_path"] = note_relative
    row["bib_status"] = config["bib_status"]
    row["status_flag"] = "ok" if config["relevance_grade"] in {"A", "B"} and config["bib_status"] == "verified" else "needs_manual_review"
    row["notes"] = f"first_pass mapped; tier={config['tier']}; see {note_relative}"


def write_dimension_notes(configs: dict[str, dict[str, str]], rows_by_id: dict[str, dict[str, str]]) -> None:
    primary_by_dim: dict[str, list[str]] = defaultdict(list)
    secondary_by_dim: dict[str, list[str]] = defaultdict(list)
    for ws_id, config in configs.items():
        if config["dimension_primary"] != "unclear":
            primary_by_dim[config["dimension_primary"]].append(ws_id)
        if config["dimension_secondary"] != "unclear":
            secondary_by_dim[config["dimension_secondary"]].append(ws_id)

    for code, label in DIMENSIONS.items():
        primary_ids = primary_by_dim.get(label, [])
        secondary_ids = secondary_by_dim.get(label, [])
        mechanism_counter = Counter(
            mechanism
            for ws_id in primary_ids + secondary_ids
            for mechanism in mechanism_list(configs[ws_id])
            if mechanism != "unclear"
        )
        observable_counter = Counter(
            observable
            for ws_id in primary_ids + secondary_ids
            for observable in [
                rows_by_id[ws_id]["observable_1"],
                rows_by_id[ws_id]["observable_2"],
                rows_by_id[ws_id]["observable_3"],
            ]
            if observable != "unclear / requires deeper reading"
        )
        lines = [
            f"# {code} {label}",
            "",
            "## Scope",
            f"- Working scope label: {label}",
            "- Updated after first-pass reconnaissance; still conservative and non-adjudicative.",
            "",
            "## Mechanism families",
        ]
        if mechanism_counter:
            for mechanism, count in mechanism_counter.most_common():
                lines.append(f"- {mechanism}: {count} mapped source(s)")
        else:
            lines.append("- No mechanism support established in first pass.")
        lines.extend(["", "## Current source coverage"])
        lines.append(f"- Primary support ({len(primary_ids)}): {', '.join(primary_ids) if primary_ids else 'none yet'}")
        lines.append(f"- Secondary support ({len(secondary_ids)}): {', '.join(secondary_ids) if secondary_ids else 'none yet'}")
        lines.extend(["", "## Gaps"])
        if label in {
            "Crisis of Atlantic Fordism / world monetary disorder",
            "External constraint / balance-of-payments / trade dependency",
            "Transnational capital / multinational corporate power",
            "Strategic commodities / copper / resource sovereignty",
        }:
            lines.append("- No primary first-pass source yet; ingestion remains urgent.")
        elif label == "U.S. interventionism":
            lines.append("- Only secondary support is established; still needs direct anchor sources.")
        elif label == "Diplomatic isolation, blockade, recognition, and alliance structure":
            lines.append("- Supported only as a secondary dimension; needs dedicated primary sources.")
        else:
            lines.append("- Coverage exists, but deeper reading is needed for page-level coding.")
        lines.extend(["", "## Candidate observables emerging from current sources"])
        if observable_counter:
            for observable, count in observable_counter.most_common(5):
                lines.append(f"- {observable} ({count})")
        else:
            lines.append("- None yet beyond placeholder observables.")
        lines.extend(["", "## Candidate variable types", "- binary/event markers", "- reference counts", "- episode-level qualitative coding", ""])
        (DIM_DIR / DIMENSION_FILES[code]).write_text("\n".join(lines), encoding="utf-8")


def write_mechanism_notes(configs: dict[str, dict[str, str]], rows_by_id: dict[str, dict[str, str]]) -> None:
    for mechanism, (code, label) in MECHANISMS.items():
        supporters = [ws_id for ws_id, config in configs.items() if mechanism in mechanism_list(config)]
        linked_dims = sorted(
            {
                DIM_CODE_BY_LABEL[configs[ws_id]["dimension_primary"]]
                for ws_id in supporters
                if configs[ws_id]["dimension_primary"] != "unclear"
            }
            |
            {
                DIM_CODE_BY_LABEL[configs[ws_id]["dimension_secondary"]]
                for ws_id in supporters
                if configs[ws_id]["dimension_secondary"] != "unclear"
            }
        )
        variable_name, variable_type = VARIABLE_BY_MECHANISM[mechanism]
        lines = [
            f"# {code} {label}",
            "",
            "## Definition",
            f"- First-pass mechanism label: {mechanism}.",
            "- Mapping remains provisional until deep reading and adjudication.",
            "",
            "## Linked dimensions",
        ]
        if linked_dims:
            for dim in linked_dims:
                lines.append(f"- {dim}")
        else:
            lines.append("- No linked dimensions established yet.")
        lines.extend(["", "## Observables"])
        lines.append(f"- {OBSERVABLE_BY_MECHANISM[mechanism]}")
        if supporters:
            lines.append("- page-anchored mentions collected in mapped source notes")
            lines.append("- source-specific variants should be refined during deep reading")
        else:
            lines.append("- No source-backed observables yet.")
        lines.extend(["", "## Candidate indicators", f"- {variable_name} ({variable_type})", "- episode-level coding with page anchors where possible", "", "## Source support"])
        if supporters:
            for ws_id in supporters:
                lines.append(f"- {ws_id}: {rows_by_id[ws_id]['file_name']}")
        else:
            lines.append("- No current source support in first pass.")
        lines.extend(["", "## Unresolved questions"])
        if mechanism in {"transnational_corporate_retaliation", "trade_channel_disruption"} and not supporters:
            lines.append("- Current corpus does not yet provide direct first-pass support; ingestion is needed.")
        else:
            lines.append("- Which page ranges best support later operational coding?")
        lines.append("- Which observables are specific enough to distinguish this mechanism from adjacent ones?")
        lines.append("")
        (MECH_DIR / MECHANISM_FILES[mechanism]).write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    configs = load_config()
    with REGISTRY_PATH.open(encoding="utf-8", newline="") as handle:
        registry_rows = list(csv.DictReader(handle))
    fieldnames = list(registry_rows[0].keys())
    rows_by_id = {row["ws_id"]: row for row in registry_rows}

    verified_entries: list[str] = []
    unresolved_entries: list[str] = []
    source_dimension_rows: list[list[str]] = []
    source_mechanism_rows: list[list[str]] = []
    mechanism_observable_rows: set[tuple[str, str, str, str, str, str]] = set()
    variable_rows: set[tuple[str, str, str, str, str, str, str]] = set()

    for ws_id, config in configs.items():
        row = rows_by_id[ws_id]
        path = RAW_DIR / row["file_name"]
        checksum = hashlib.sha256(path.read_bytes()).hexdigest()
        with pdfplumber.open(path) as pdf:
            texts = [safe_page_text(page) for page in pdf.pages]
            page_count = len(pdf.pages)

        note_path = note_path_for(ws_id)
        note_relative = repo_relative(note_path)
        note_path.write_text(note_text(ws_id, row, config, page_count, checksum, texts), encoding="utf-8")

        relative_path = repo_relative(path)
        update_registry_row(row, config, relative_path, page_count, checksum, note_relative)

        if config["dimension_primary"] != "unclear":
            source_dimension_rows.append(
                [
                    ws_id,
                    relative_path,
                    DIM_CODE_BY_LABEL[config["dimension_primary"]],
                    config["dimension_primary"],
                    confidence(config["relevance_grade"]),
                    "first_pass",
                    "primary",
                ]
            )
        if config["dimension_secondary"] != "unclear":
            source_dimension_rows.append(
                [
                    ws_id,
                    relative_path,
                    DIM_CODE_BY_LABEL[config["dimension_secondary"]],
                    config["dimension_secondary"],
                    confidence(config["relevance_grade"], secondary=True),
                    "first_pass",
                    "secondary",
                ]
            )

        observables = observable_list(config)
        for index, mechanism in enumerate(mechanism_list(config), start=1):
            if mechanism == "unclear":
                continue
            mech_code, mech_label = MECHANISMS[mechanism]
            source_mechanism_rows.append([ws_id, relative_path, mech_code, mechanism, confidence(config["relevance_grade"]), "first_pass", f"candidate_{index}"])
            mechanism_observable_rows.add((mech_code, mech_label, f"OBS_{mech_code}_{index}", observables[index - 1], "first_pass", ws_id))
            dim_code = DIM_CODE_BY_LABEL[config["dimension_primary"]] if config["dimension_primary"] != "unclear" else ""
            variable_name, variable_type = VARIABLE_BY_MECHANISM[mechanism]
            variable_rows.add((variable_name.upper(), variable_name, dim_code, mech_code, variable_type, "first_pass", ws_id))

        entry = bib_entry(config, relative_path, ws_id)
        if config["bib_status"] == "verified":
            verified_entries.append(entry)
        else:
            unresolved_entries.append(entry)

    with REGISTRY_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(registry_rows)

    with (BIB_DIR / "ws_corridor.bib").open("w", encoding="utf-8") as handle:
        handle.write("% Verified first-pass BibTeX entries for WS corridor corpus.\n\n")
        handle.write("\n\n".join(verified_entries) + ("\n" if verified_entries else ""))
    with (BIB_DIR / "ws_corridor_unresolved.bib").open("w", encoding="utf-8") as handle:
        handle.write("% Unresolved first-pass BibTeX entries for WS corridor corpus.\n\n")
        handle.write("\n\n".join(unresolved_entries) + ("\n" if unresolved_entries else ""))

    with (MAP_DIR / "ws_source_dimension_map.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["ws_id", "relative_path", "dimension_code", "dimension_label", "confidence", "status", "notes"])
        writer.writerows(source_dimension_rows)
    with (MAP_DIR / "ws_source_mechanism_map.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["ws_id", "relative_path", "mechanism_code", "mechanism_label", "confidence", "status", "notes"])
        writer.writerows(source_mechanism_rows)
    with (MAP_DIR / "ws_mechanism_observable_map.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["mechanism_code", "mechanism_label", "observable_code", "observable_label", "status", "notes"])
        for row in sorted(mechanism_observable_rows):
            writer.writerow(row)
    with (MAP_DIR / "ws_variable_menu.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["variable_code", "variable_label", "dimension_code", "mechanism_code", "variable_type", "status", "notes"])
        for row in sorted(variable_rows):
            writer.writerow(row)

    with (MAP_DIR / "ws_evidence_markers.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["marker_code", "marker_label", "marker_type", "description", "status", "notes"])
        used_markers = sorted({marker for config in configs.values() for marker in marker_list(config)})
        for marker in used_markers:
            marker_type, description = EVIDENCE_MARKERS[marker]
            writer.writerow([marker, marker, marker_type, description, "first_pass", "used in source notes and registry"])

    overlap_rows: list[list[str]] = []
    a_b_ids = [ws_id for ws_id, config in configs.items() if config["relevance_grade"] in {"A", "B"}]
    for index, left_id in enumerate(a_b_ids):
        for right_id in a_b_ids[index + 1 :]:
            left = configs[left_id]
            right = configs[right_id]
            left_dims = {left["dimension_primary"], left["dimension_secondary"]} - {"unclear"}
            right_dims = {right["dimension_primary"], right["dimension_secondary"]} - {"unclear"}
            shared_dims = sorted(left_dims & right_dims)
            shared_mechs = sorted((set(mechanism_list(left)) & set(mechanism_list(right))) - {"unclear"})
            if shared_dims and shared_mechs:
                overlap_rows.append(
                    [
                        left_id,
                        right_id,
                        "shared_dimension_and_mechanism",
                        "; ".join(shared_dims),
                        "first_pass",
                        "; ".join(shared_mechs),
                    ]
                )
    with (MAP_DIR / "ws_overlap_matrix.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["source_a_ws_id", "source_b_ws_id", "overlap_type", "overlap_basis", "status", "notes"])
        writer.writerows(overlap_rows)

    queue_groups: dict[int, list[tuple[str, dict[str, str]]]] = defaultdict(list)
    for ws_id, config in configs.items():
        queue_groups[config["tier"]].append((ws_id, config))
    queue_lines = [
        "# WS Reading Queue",
        "",
        "Three-tier queue after first-pass reconnaissance. Tiers reflect centrality to the current ontology/mechanism pass rather than final chapter importance.",
        "",
        "## Tier 1: anchor sources",
    ]
    for ws_id, config in sorted(queue_groups[1]):
        mechs = ", ".join(item for item in mechanism_list(config) if item != "unclear")
        queue_lines.append(f"- `{rows_by_id[ws_id]['file_name']}` | {config['dimension_primary']} | mechanisms={mechs}")
    queue_lines.extend(["", "## Tier 2: useful support"])
    for ws_id, config in sorted(queue_groups[2]):
        queue_lines.append(f"- `{rows_by_id[ws_id]['file_name']}` | {config['dimension_primary']} | relevance={config['relevance_grade']}")
    queue_lines.extend(["", "## Tier 3: unclear/triage"])
    for ws_id, config in sorted(queue_groups[3]):
        queue_lines.append(f"- `{rows_by_id[ws_id]['file_name']}` | relevance={config['relevance_grade']} | keep_flag={config['keep_flag']} | primary_dimension={config['dimension_primary']}")
    QUEUE_PATH.write_text("\n".join(queue_lines) + "\n", encoding="utf-8")

    write_dimension_notes(configs, rows_by_id)
    write_mechanism_notes(configs, rows_by_id)

    grade_counter = Counter(config["relevance_grade"] for config in configs.values())
    primary_dimension_counter = Counter(config["dimension_primary"] for config in configs.values() if config["dimension_primary"] != "unclear")
    thin_dimensions = [label for label in DIMENSIONS.values() if primary_dimension_counter.get(label, 0) == 0]
    mechanism_support_counter = Counter(
        mechanism for config in configs.values() for mechanism in mechanism_list(config) if mechanism != "unclear"
    )
    summary_lines = [
        "# First-Pass Summary",
        "",
        f"- source notes created: {len(configs)}",
        f"- relevance grades: A={grade_counter.get('A', 0)}, B={grade_counter.get('B', 0)}, C={grade_counter.get('C', 0)}",
        "",
        "## Dimensions with strongest support",
    ]
    for label, count in primary_dimension_counter.most_common():
        summary_lines.append(f"- {label}: {count}")
    summary_lines.extend(["", "## Dimensions that remain thin"])
    for label in thin_dimensions:
        summary_lines.append(f"- {label}")
    summary_lines.extend(["", "## Mechanism families with actual first-pass source support"])
    for mechanism, count in mechanism_support_counter.most_common():
        summary_lines.append(f"- {mechanism}: {count}")
    summary_lines.extend(["", "## Sources to deep-read next"])
    for ws_id, config in sorted(queue_groups[1]):
        summary_lines.append(f"- {rows_by_id[ws_id]['file_name']}")
    SUMMARY_PATH.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print("firstpass_complete")
    print(f"source_notes={len(configs)}")
    print(f"bib_verified={sum(1 for config in configs.values() if config['bib_status'] == 'verified')}")


if __name__ == "__main__":
    main()
