from __future__ import annotations

import csv
from collections import Counter, defaultdict
from io import StringIO
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ASSET_ROOT = REPO / "docs" / "chile_project_assets"
WS_ROOT = REPO / "docs" / "data_sources_WS_corridor"

REGISTRY_PATH = ASSET_ROOT / "00_index" / "ws_asset_integration_registry.csv"
INTEGRATION_MAP_PATH = ASSET_ROOT / "05_links_to_corridors" / "ws_support_integration_map.md"
DIM_MAP_PATH = WS_ROOT / "04_mappings" / "ws_support_asset_to_dimension_map.csv"
MECH_MAP_PATH = WS_ROOT / "04_mappings" / "ws_support_asset_to_mechanism_map.csv"
SUMMARY_PATH = WS_ROOT / "06_exports" / "ws_support_asset_summary.md"

REGISTRY_FIELDS = [
    "asset_id",
    "relative_path",
    "asset_title",
    "asset_family",
    "asset_function",
    "supports_ws_corridor",
    "supports_ar_corridor",
    "supports_overlap",
    "ws_dimension_primary",
    "ws_dimension_secondary",
    "mechanism_family",
    "support_role",
    "evidentiary_role",
    "drafting_role",
    "periodization_role",
    "usable_for_codex",
    "usable_for_deepread_prioritization",
    "usable_for_variable_hardening",
    "translation_risk",
    "status",
    "comments",
]

DIM_FIELDS = [
    "asset_id",
    "asset_title",
    "ws_dimension",
    "support_role",
    "mechanism_family",
    "why_relevant",
    "thin_dimension_helped",
    "confidence",
]

MECH_FIELDS = [
    "asset_id",
    "mechanism_family",
    "support_type",
    "candidate_observables_helped",
    "candidate_variables_helped",
    "role_in_hardening",
    "confidence",
]

THIN_DIMENSIONS = {
    "U.S. interventionism",
    "Crisis of Atlantic Fordism / world monetary disorder",
    "External constraint / balance-of-payments / trade dependency",
    "Transnational capital / multinational corporate power",
    "Strategic commodities / copper / resource sovereignty",
    "Diplomatic isolation, blockade, recognition, and alliance structure",
}

ACTIVE_STATUSES = {"keep_active", "reserve", "context_only"}

GENERATED_PATHS = {
    REGISTRY_PATH.relative_to(REPO).as_posix(),
    INTEGRATION_MAP_PATH.relative_to(REPO).as_posix(),
    "docs/chile_project_assets/00_index/ws_asset_integration.py",
}


def parse_tsv(text: str) -> list[dict[str, str]]:
    return list(csv.DictReader(StringIO(text.strip()), delimiter="\t"))


def write_csv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


MANUAL_TSV = """relative_path	asset_title	asset_family	asset_function	supports_ws_corridor	supports_ar_corridor	supports_overlap	ws_dimension_primary	ws_dimension_secondary	mechanism_family	support_role	evidentiary_role	drafting_role	periodization_role	usable_for_codex	usable_for_deepread_prioritization	usable_for_variable_hardening	translation_risk	status	comments
docs/chile_project_assets/README.md	Chile Project Assets README	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	none	yes	no	no	low	context_only	Package orientation only. Useful for entry and guardrails but not for WS evidence or variable hardening.
docs/chile_project_assets/00_index/chile_assets_integration_log.md	Chile Assets Integration Log	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	none	with_caution	no	no	low	context_only	Explains the curation logic of the bundle. Keep as provenance, not as operational support.
docs/chile_project_assets/00_index/chile_assets_master_index.md	Chile Assets Master Index	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	low	yes	yes	no	low	keep_active	Best discovery index for the active asset layer and the fastest Codex entry point before routing assets by function.
docs/chile_project_assets/01_source_control/bibliografia_y_auditoria.md	Bibliografia y auditoria	source_control	bibliography_audit	yes	yes	yes	External constraint / balance-of-payments / trade dependency	U.S. interventionism	financial_strangulation	source_routing	indirect	low	low	yes	yes	partial	low	keep_active	Best bibliographic cleanup aid for Harmer, Griffith-Jones, Palma, and adjacent thin-dimension anchors.
docs/chile_project_assets/01_source_control/ledger_de_fuentes.md	Ledger de fuentes	source_control	ledger	yes	yes	yes	External constraint / balance-of-payments / trade dependency	Transnational capital / multinational corporate power	financial_strangulation	source_routing	indirect	low	medium	yes	yes	partial	low	keep_active	Functional source ledger that surfaces finance, dominant-class, and transition-to-socialism references.
docs/chile_project_assets/01_source_control/corpus_backbone_maps/source_integration_map_1925_1958.md	Source Integration Map 1925-1958 Backbone	source_control	source_integration_map	yes	yes	yes	Inter-American order / hemispheric security doctrine	U.S. interventionism	security_doctrine_legitimation	periodization_support	indirect	low	high	yes	yes	no	low	keep_active	Best pre-UP sequencing aid for anti-communist reformism, state formation, and the 1957 threshold.
docs/chile_project_assets/01_source_control/reference_master_ledgers/industrial_patronage_reference_master_ledger.md	Industrial Patronage Reference Master Ledger	source_control	ledger	yes	yes	yes	Transnational capital / multinational corporate power	External constraint / balance-of-payments / trade dependency	transnational_corporate_retaliation	source_routing	indirect	medium	medium	yes	yes	yes	low	keep_active	High-value literature router for Atlantic Fordism, dependency, finance, raw materials, and class formation.
docs/chile_project_assets/01_source_control/reference_master_ledgers/master_ledger.md	Master Ledger: Schools of Thought on the Political Economy of the UP	source_control	ledger	yes	yes	yes	External constraint / balance-of-payments / trade dependency	Crisis of Atlantic Fordism / world monetary disorder	financial_strangulation	overlap_support	indirect	medium	medium	with_caution	yes	partial	medium	reserve	Useful historiographic router, but it points to a wider literature bundle and should not outrank corridor materials.
docs/chile_project_assets/02_argument_architecture/argument_evidence_matrix.md	Argument-Evidence Matrix	argument_architecture	argument_map	yes	yes	yes	External constraint / balance-of-payments / trade dependency	Strategic commodities / copper / resource sovereignty	financial_strangulation	variable_support	secondary_support	medium	high	yes	yes	yes	low	keep_active	Best anti-drift asset for converting mechanisms into observables and keeping claims tied to evidentiary burden.
docs/chile_project_assets/02_argument_architecture/dissertation_reframing_workbench.md	Dissertation Reframing Workbench	argument_architecture	reframing_workbench	yes	yes	yes	Crisis of Atlantic Fordism / world monetary disorder	Transnational capital / multinational corporate power	unclear	overlap_support	none	high	medium	with_caution	yes	partial	medium	reserve	Useful comparative-relational framing notebook. Keep it subordinate to source-first extraction.
docs/chile_project_assets/02_argument_architecture/mapa_argumental.md	Mapa argumental	argument_architecture	argument_map	yes	yes	yes	External constraint / balance-of-payments / trade dependency	Strategic commodities / copper / resource sovereignty	trade_channel_disruption	mechanism_support	indirect	medium	medium	yes	yes	yes	low	keep_active	Strong mechanism skeleton for blockage, shortage, sabotage, copper, and external pressure.
docs/chile_project_assets/02_argument_architecture/paper_conversion_blueprint.md	Paper Conversion Blueprint	argument_architecture	argument_map	yes	yes	yes	unclear	unclear	unclear	drafting_support	none	high	low	with_caution	no	no	medium	context_only	Drafting conversion aid. It helps packaging, not WS source control.
docs/chile_project_assets/02_argument_architecture/periodization_control_sheet.md	Periodization Control Sheet	argument_architecture	periodization_control	yes	yes	yes	External constraint / balance-of-payments / trade dependency	Crisis of Atlantic Fordism / world monetary disorder	financial_strangulation	periodization_support	secondary_support	medium	high	yes	yes	yes	low	keep_active	Best sequencing aid for foreign-exchange pressure, anti-communist containment, and 1970-1973 turbulence.
docs/chile_project_assets/03_manuscript_reservoir/industrial_patronage_english_apa.md	Industrial Patronage English APA Manuscript Reservoir	manuscript_reservoir	manuscript	yes	yes	yes	Transnational capital / multinational corporate power	Strategic commodities / copper / resource sovereignty	commodity_sovereignty_conflict	drafting_support	secondary_support	high	medium	with_caution	yes	partial	high	reserve	Citation-rich prose reservoir with useful pointers on copper, spare parts, dollar scarcity, and corporate retaliation. Do not treat as evidence.
docs/chile_project_assets/03_manuscript_reservoir/nota_maestra.md	Nota maestra	manuscript_reservoir	manuscript	yes	yes	yes	External constraint / balance-of-payments / trade dependency	unclear	unclear	drafting_support	none	high	medium	with_caution	no	partial	high	reserve	Stable prose reservoir and synthesis notebook. Useful for memory, not for evidence claims.
docs/chile_project_assets/04_communication/abstracts_and_pitch_versions.md	Abstracts and Pitch Versions	communication	talk_script	yes	yes	yes	unclear	unclear	unclear	drafting_support	none	high	none	no	no	no	high	context_only	Communication packaging only. Keep out of WS operations and evidence claims.
docs/chile_project_assets/04_communication/handout_one_page.md	Handout One Page	communication	handout	yes	yes	yes	unclear	unclear	unclear	drafting_support	none	high	none	no	no	no	high	context_only	Handout packaging only. Useful for presentations, not for source routing.
docs/chile_project_assets/04_communication/talk_script_12_minutes.md	Talk Script 12 Minutes	communication	talk_script	yes	yes	yes	unclear	unclear	unclear	drafting_support	none	high	none	no	no	no	high	context_only	Talk script only. It should stay outside evidence and variable-building workflows.
docs/chile_project_assets/05_links_to_corridors/ar_support_assets.md	AR Support Assets	bridge_note	support_note	no	yes	yes	unclear	unclear	unclear	overlap_support	none	low	low	with_caution	no	no	medium	context_only	Thin AR bridge note. Retain as reminder, not as WS operational asset.
docs/chile_project_assets/05_links_to_corridors/overlap_hinge_assets.md	Overlap Hinge Assets	bridge_note	support_note	yes	yes	yes	Diplomatic isolation, blockade, recognition, and alliance structure	External constraint / balance-of-payments / trade dependency	diplomatic_isolation	overlap_support	none	low	medium	yes	yes	partial	low	keep_active	Best bridge note for overlap routing between corridor materials and AR-facing hinge work.
docs/chile_project_assets/05_links_to_corridors/ws_support_assets.md	WS Support Assets	bridge_note	support_note	yes	no	yes	External constraint / balance-of-payments / trade dependency	Diplomatic isolation, blockade, recognition, and alliance structure	financial_strangulation	workflow_control	none	low	medium	yes	yes	partial	low	keep_active	Explicit bridge note for how the asset layer should support, not replace, the WS corridor.
docs/chile_project_assets/06_original_bundle_mirror/industrial_patronage/industrial_patronage_artifact_pack_index.md	Industrial Patronage Artifact Pack Index	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	none	with_caution	no	no	low	reserve	Unique mirror-side index. Preserve for provenance, but it does not add operational support beyond the curated layer.
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/00_PLAN_DE_ARTIFACTO.md	Unidad Popular Plan de Artefacto	other	support_note	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	medium	low	with_caution	no	no	medium	reserve	Backlog and package-planning note from the original bundle. Useful for provenance and sequencing memory only.
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/05_REGISTRO_DE_TABLAS_Y_FIGURAS.md	Registro de tablas y figuras	argument_architecture	index	yes	yes	yes	External constraint / balance-of-payments / trade dependency	Strategic commodities / copper / resource sovereignty	unclear	variable_support	indirect	medium	medium	yes	no	yes	low	keep_active	Unique variable-hardening aid for tables and figures around distribution, profitability, sector structure, and macro constraints.
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/06_PROXIMOS_PASOS.md	Unidad Popular Proximos Pasos	other	support_note	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	medium	low	with_caution	no	partial	medium	reserve	Backlog note that can help sequence future intake, but it should not drive classification.
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/README.md	Unidad Popular Mirror README	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	none	with_caution	no	no	low	reserve	Provenance readme for the mirror bundle. Keep for traceability only.
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/assets/README.md	Unidad Popular Assets README	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	none	no	no	no	low	reserve	Naming and file-convention note for the mirror assets folder. Not operational for WS.
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/source/apunte_HistoriaSocial_19571973.pdf	Apunte Historia Social 1957-1973 Mirror PDF	manuscript_reservoir	support_note	yes	yes	yes	U.S. interventionism	Inter-American order / hemispheric security doctrine	security_doctrine_legitimation	context_only	none	medium	medium	with_caution	no	no	high	reserve	Background PDF stored inside the mirror bundle. Treat as reservoir or follow-up candidate, not as WS evidence by default.
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/README_asset_pack.md	UP Asset Pack README	other	index	yes	yes	yes	unclear	unclear	unclear	workflow_control	none	low	none	with_caution	no	no	low	reserve	Packaging readme for the original asset pack. Preserve for provenance only.
"""


DUPLICATE_TSV = """relative_path	source_path
docs/chile_project_assets/06_original_bundle_mirror/industrial_patronage/industrial_patronage_dissertation_reframing_workbench.md	docs/chile_project_assets/02_argument_architecture/dissertation_reframing_workbench.md
docs/chile_project_assets/06_original_bundle_mirror/industrial_patronage/industrial_patronage_english_apa.md	docs/chile_project_assets/03_manuscript_reservoir/industrial_patronage_english_apa.md
docs/chile_project_assets/06_original_bundle_mirror/industrial_patronage/industrial_patronage_reference_master_ledger.md	docs/chile_project_assets/01_source_control/reference_master_ledgers/industrial_patronage_reference_master_ledger.md
docs/chile_project_assets/06_original_bundle_mirror/reusable_ledger/master_ledger.md	docs/chile_project_assets/01_source_control/reference_master_ledgers/master_ledger.md
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/01_NOTA_MAESTRA.md	docs/chile_project_assets/03_manuscript_reservoir/nota_maestra.md
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/02_MAPA_ARGUMENTAL.md	docs/chile_project_assets/02_argument_architecture/mapa_argumental.md
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/03_LEDGER_DE_FUENTES.md	docs/chile_project_assets/01_source_control/ledger_de_fuentes.md
docs/chile_project_assets/06_original_bundle_mirror/Unidad Popular/04_BIBLIOGRAFIA_Y_AUDITORIA.md	docs/chile_project_assets/01_source_control/bibliografia_y_auditoria.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/01_Abstracts_and_Pitch_Versions.md	docs/chile_project_assets/04_communication/abstracts_and_pitch_versions.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/02_Talk_Script_12_Minutes.md	docs/chile_project_assets/04_communication/talk_script_12_minutes.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/03_Argument_Evidence_Matrix.md	docs/chile_project_assets/02_argument_architecture/argument_evidence_matrix.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/04_Periodization_Control_Sheet.md	docs/chile_project_assets/02_argument_architecture/periodization_control_sheet.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/05_Paper_Conversion_Blueprint.md	docs/chile_project_assets/02_argument_architecture/paper_conversion_blueprint.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/06_Handout_One_Page.md	docs/chile_project_assets/04_communication/handout_one_page.md
docs/chile_project_assets/06_original_bundle_mirror/UP_asset_pack/07_Source_Integration_Map_1925_1958.md	docs/chile_project_assets/01_source_control/corpus_backbone_maps/source_integration_map_1925_1958.md
"""


def build_registry_rows() -> list[dict[str, str]]:
    manual_rows = parse_tsv(MANUAL_TSV)
    manual_by_path = {row["relative_path"]: row for row in manual_rows}
    duplicate_rows = parse_tsv(DUPLICATE_TSV)

    rows: list[dict[str, str]] = []
    for path in sorted(
        p.relative_to(REPO).as_posix()
        for p in ASSET_ROOT.rglob("*")
        if p.is_file()
        and "__pycache__" not in p.parts
        and p.relative_to(REPO).as_posix() not in GENERATED_PATHS
    ):
        if path in manual_by_path:
            rows.append(dict(manual_by_path[path]))
            continue

        duplicate = next((entry for entry in duplicate_rows if entry["relative_path"] == path), None)
        if duplicate is None:
            raise ValueError(f"No classification rule for {path}")

        source_row = dict(manual_by_path[duplicate["source_path"]])
        title = source_row["asset_title"]
        duplicate_row = dict(source_row)
        duplicate_row["relative_path"] = path
        duplicate_row["asset_title"] = f"{title} (mirror)"
        duplicate_row["status"] = "exclude_from_ws_ops"
        duplicate_row["usable_for_codex"] = "no"
        duplicate_row["usable_for_deepread_prioritization"] = "no"
        duplicate_row["usable_for_variable_hardening"] = "no"
        duplicate_row["translation_risk"] = "high"
        duplicate_row["comments"] = (
            f"Mirror duplicate of {duplicate['source_path']}. "
            "Retain for provenance only and exclude from active WS operations."
        )
        rows.append(duplicate_row)

    for index, row in enumerate(rows, start=1):
        row["asset_id"] = f"ASSET_{index:03d}"

    return rows


def build_dimension_map(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    output: list[dict[str, str]] = []
    for row in rows:
        if row["status"] == "exclude_from_ws_ops":
            continue
        for field_name in ("ws_dimension_primary", "ws_dimension_secondary"):
            dimension = row[field_name]
            if dimension == "unclear":
                continue
            output.append(
                {
                    "asset_id": row["asset_id"],
                    "asset_title": row["asset_title"],
                    "ws_dimension": dimension,
                    "support_role": row["support_role"],
                    "mechanism_family": row["mechanism_family"],
                    "why_relevant": row["comments"],
                    "thin_dimension_helped": "yes" if dimension in THIN_DIMENSIONS else "no",
                    "confidence": confidence_for_row(row),
                }
            )
    return output


def build_mechanism_map(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    observables = {
        "financial_strangulation": "foreign-exchange pressure; credit denial; debt rollover stress",
        "trade_channel_disruption": "import bottlenecks; spare-parts shortages; shipping disruptions",
        "transnational_corporate_retaliation": "multinational pressure; disinvestment threats; supply leverage",
        "commodity_sovereignty_conflict": "copper revenue shocks; nationalization disputes; royalty claims",
        "diplomatic_isolation": "recognition narrowing; alliance loss; diplomatic signaling",
        "security_doctrine_legitimation": "anti-communist framing; hemispheric security claims; institutional doctrine",
        "unclear": "not mechanism-specific",
    }
    variables = {
        "financial_strangulation": "credit-access marker; foreign-exchange constraint indicator",
        "trade_channel_disruption": "import-delay marker; logistics bottleneck indicator",
        "transnational_corporate_retaliation": "corporate pressure marker; transnational leverage indicator",
        "commodity_sovereignty_conflict": "copper sovereignty conflict marker; export-revenue stress indicator",
        "diplomatic_isolation": "diplomatic narrowing marker; alliance-structure indicator",
        "security_doctrine_legitimation": "security framing marker; coercive institutional indicator",
        "unclear": "unclear",
    }

    output: list[dict[str, str]] = []
    for row in rows:
        mechanism = row["mechanism_family"]
        if row["status"] == "exclude_from_ws_ops" or mechanism == "unclear":
            continue
        output.append(
            {
                "asset_id": row["asset_id"],
                "mechanism_family": mechanism,
                "support_type": row["support_role"],
                "candidate_observables_helped": observables[mechanism],
                "candidate_variables_helped": variables[mechanism],
                "role_in_hardening": row["comments"],
                "confidence": confidence_for_row(row),
            }
        )
    return output


def confidence_for_row(row: dict[str, str]) -> str:
    if row["status"] == "keep_active":
        return "high"
    if row["status"] == "reserve":
        return "medium"
    return "low"


def top_assets_for_dimension(rows: list[dict[str, str]], dimension: str, limit: int = 4) -> list[dict[str, str]]:
    matches = [
        row
        for row in rows
        if row["status"] in ACTIVE_STATUSES
        and dimension in {row["ws_dimension_primary"], row["ws_dimension_secondary"]}
    ]
    order = {"keep_active": 0, "reserve": 1, "context_only": 2}
    return sorted(matches, key=lambda item: (order[item["status"]], item["asset_title"]))[:limit]


def top_codex_assets(rows: list[dict[str, str]], limit: int = 6) -> list[dict[str, str]]:
    candidates = [row for row in rows if row["usable_for_codex"] == "yes"]
    order = {"keep_active": 0, "reserve": 1, "context_only": 2}
    return sorted(candidates, key=lambda item: (order[item["status"]], item["asset_title"]))[:limit]


def quarantine_assets(rows: list[dict[str, str]], limit: int = 8) -> list[dict[str, str]]:
    blocked_families = {"communication", "manuscript_reservoir"}
    candidates = [
        row
        for row in rows
        if row["asset_family"] in blocked_families or row["support_role"] == "drafting_support"
    ]
    order = {"context_only": 0, "reserve": 1, "keep_active": 2, "exclude_from_ws_ops": 3}
    return sorted(candidates, key=lambda item: (order[item["status"]], item["asset_title"]))[:limit]


def summarize_registry(rows: list[dict[str, str]]) -> dict[str, int]:
    directly_useful = sum(
        1 for row in rows if row["status"] == "keep_active" and row["supports_ws_corridor"] == "yes"
    )
    overlap_useful = sum(
        1
        for row in rows
        if row["status"] in {"keep_active", "reserve"} and row["supports_overlap"] == "yes"
    )
    drafting_only = sum(
        1
        for row in rows
        if row["asset_family"] in {"communication", "manuscript_reservoir"}
        or row["support_role"] == "drafting_support"
    )
    return {
        "reviewed": len(rows),
        "directly_useful": directly_useful,
        "overlap_useful": overlap_useful,
        "drafting_only": drafting_only,
    }


def build_integration_map(rows: list[dict[str, str]]) -> str:
    thin_sections = {
        "External constraint / balance-of-payments / trade dependency": top_assets_for_dimension(
            rows, "External constraint / balance-of-payments / trade dependency"
        ),
        "Transnational capital / multinational corporate power": top_assets_for_dimension(
            rows, "Transnational capital / multinational corporate power"
        ),
        "Strategic commodities / copper / resource sovereignty": top_assets_for_dimension(
            rows, "Strategic commodities / copper / resource sovereignty"
        ),
        "Diplomatic isolation, blockade, recognition, and alliance structure": top_assets_for_dimension(
            rows, "Diplomatic isolation, blockade, recognition, and alliance structure"
        ),
        "U.S. interventionism": top_assets_for_dimension(rows, "U.S. interventionism"),
    }
    periodization_assets = top_assets_for_dimension(rows, "Crisis of Atlantic Fordism / world monetary disorder")
    overlap_assets = [
        row for row in rows if row["support_role"] == "overlap_support" and row["status"] != "exclude_from_ws_ops"
    ][:5]
    quarantine = quarantine_assets(rows, limit=10)
    reservoir_only = [
        row
        for row in rows
        if row["asset_family"] == "manuscript_reservoir" and row["status"] in {"reserve", "context_only"}
    ][:5]
    codex_assets = top_codex_assets(rows, limit=7)

    lines = [
        "# WS Support Integration Map",
        "## 1. What this asset layer does for the WS corridor",
        "- It supplies workflow control, source routing, periodization discipline, and variable-hardening support for the WS corridor without entering the raw PDF corpus.",
        "- It is most valuable where the first WS pass stayed thin: external constraint, transnational capital, copper sovereignty, diplomatic isolation, and U.S. interventionism.",
        "- Mirror duplicates remain preserved for provenance, but the curated layer is the operational layer for Codex work.",
        "## 2. Assets that directly strengthen thin WS dimensions",
    ]
    for dimension, assets in thin_sections.items():
        lines.append(f"- `{dimension}`:")
        for asset in assets:
            lines.append(f"  - `{asset['asset_title']}`: {asset['comments']}")
    lines.extend(
        [
            "## 3. Assets that support periodization and sequencing",
        ]
    )
    for asset in periodization_assets:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 4. Assets that help overlap routing with AR")
    for asset in overlap_assets:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 5. Assets that should NOT be treated as evidence")
    for asset in quarantine:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 6. Assets that should remain manuscript reservoir only")
    for asset in reservoir_only:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 7. Immediate Codex-use recommendations")
    for asset in codex_assets:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    return "\n".join(lines) + "\n"


def build_summary(rows: list[dict[str, str]]) -> str:
    counts = summarize_registry(rows)
    weak_point_assets = {
        "external constraint / BoP": top_assets_for_dimension(
            rows, "External constraint / balance-of-payments / trade dependency"
        ),
        "transnational capital": top_assets_for_dimension(
            rows, "Transnational capital / multinational corporate power"
        ),
        "copper / resource sovereignty": top_assets_for_dimension(
            rows, "Strategic commodities / copper / resource sovereignty"
        ),
        "diplomatic isolation": top_assets_for_dimension(
            rows, "Diplomatic isolation, blockade, recognition, and alliance structure"
        ),
        "U.S. interventionism": top_assets_for_dimension(rows, "U.S. interventionism"),
    }
    deep_read_assets = [
        row
        for row in rows
        if row["usable_for_deepread_prioritization"] == "yes" and row["status"] != "exclude_from_ws_ops"
    ][:8]
    variable_assets = [
        row
        for row in rows
        if row["usable_for_variable_hardening"] in {"yes", "partial"} and row["status"] != "exclude_from_ws_ops"
    ][:8]
    quarantine = quarantine_assets(rows, limit=10)

    lines = [
        "# WS Support Asset Summary",
        "## 1. Executive summary",
        f"- Reviewed assets: {counts['reviewed']}",
        f"- Directly useful for WS operations: {counts['directly_useful']}",
        f"- Overlap-useful assets: {counts['overlap_useful']}",
        f"- Drafting-only or reservoir-only assets: {counts['drafting_only']}",
        "- The asset layer works best as workflow control and variable-hardening support. It should not be blended into the raw WS source corpus.",
        "## 2. Best support assets for current WS weak points",
    ]
    for label, assets in weak_point_assets.items():
        lines.append(f"- `{label}`:")
        for asset in assets:
            lines.append(f"  - `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 3. Assets that can guide next deep reads")
    for asset in deep_read_assets:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 4. Assets that can guide next variable hardening")
    for asset in variable_assets:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 5. Assets to quarantine from evidence claims")
    for asset in quarantine:
        lines.append(f"- `{asset['asset_title']}`: {asset['comments']}")
    lines.append("## 6. Recommended next sprint after this one")
    lines.append(
        "- Use the ledgers, the argument-evidence matrix, the periodization sheet, and the tables-and-figures register to drive a targeted intake sprint for external finance, copper sovereignty, multinational retaliation, and diplomatic narrowing sources."
    )
    lines.append(
        "- Keep manuscript reservoirs and communication files outside evidence claims; use them only after new WS evidence is ingested and verified."
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    rows = build_registry_rows()
    write_csv(REGISTRY_PATH, REGISTRY_FIELDS, rows)
    write_csv(DIM_MAP_PATH, DIM_FIELDS, build_dimension_map(rows))
    write_csv(MECH_MAP_PATH, MECH_FIELDS, build_mechanism_map(rows))
    INTEGRATION_MAP_PATH.write_text(build_integration_map(rows), encoding="utf-8")
    SUMMARY_PATH.write_text(build_summary(rows), encoding="utf-8")


if __name__ == "__main__":
    main()
