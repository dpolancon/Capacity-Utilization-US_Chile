#!/usr/bin/env python3
"""
standardize_chapter2_vault_frontmatter.py

Standardizes YAML frontmatter across chapter2_vault/*.md to a common 10-field
schema (type, status, country, stage_scope, last_updated, depends_on, blocks,
layer, scope, priority) while preserving locked authority files, non-template
fields (role, tags, subtype, etc.), and drifted dependency field names.

See C:\\Users\\User\\.claude\\plans\\generate-a-script-that-sorted-stroustrup.md
for the full design rationale and mapping tables this implements.

Usage:
    python scripts/standardize_chapter2_vault_frontmatter.py --dry-run
    python scripts/standardize_chapter2_vault_frontmatter.py --apply
"""

import argparse
import datetime
import os
import re
import sys

import yaml

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VAULT_ROOT = os.path.join(REPO_ROOT, "chapter2_vault")
TODAY = datetime.date.today().isoformat()

TEMPLATE_KEYS = [
    "type", "status", "country", "stage_scope", "last_updated",
    "depends_on", "blocks", "layer", "scope", "priority",
]

DRIFT_DEPENDENCY_FIELDS = {"authority_files", "dependencies"}

# Stray duplicate files noticed during exploration — flagged only, never written.
STRAY_DUPLICATE_FILES = {
    "05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol 1.md",
    "99_inactive/H01_Cajas_to_Transformation_Elasticity 1.md",
}

# Directory prefix -> (type, status_if_new, layer, scope, priority, confidence)
# Order matters: first (longest/most-specific) prefix match wins.
DIR_RULES = [
    ("02_analyitical_foundation/_legacy", ("theory", "deprecated", "theory", "chapter2", "legacy", "high")),
    ("02_analyitical_foundation", ("theory", "active", "theory", "chapter2", "reference", "high")),
    ("00_constitutive_core", ("theory", "active", "theory", "chapter2", "core", "high")),
    ("01_contradictory_utilization_configurations", ("theory", "active", "theory", "chapter2", "reference", "high")),
    ("03_econometrics/_legacy", ("econometrics", "deprecated", "empirics", "chapter2", "legacy", "high")),
    ("03_econometrics/99_archive", ("econometrics", "archived", "archive", "chapter2", "legacy", "high")),
    ("03_econometrics", ("econometrics", "active", "empirics", "chapter2", "reference", "high")),
    ("04_data_measurement", ("research_note", "active", "empirics", "chapter2", "reference", "high")),
    ("05_codes_implementation", ("code_governance", "active", "implementation", "chapter2", "reference", "high")),
    ("06_paper_facing/drafts", ("paper_facing", "draft", "design", "chapter2", "context", "high")),
    ("06_paper_facing/_legacy", ("paper_facing", "deprecated", "design", "chapter2", "legacy", "high")),
    ("06_paper_facing/others", ("paper_facing", "draft", "design", "chapter2", "context", "low")),
    ("06_paper_facing", ("paper_facing", "locked", "design", "chapter2", "core", "high")),
    ("07_WrittingSkills_and_Rules", ("research_note", "active", "design", "chapter2", "reference", "low")),
    ("08_audits", ("research_note", "active", "archive", "chapter2", "context", "high")),
    ("09_legacy", ("research_note", "deprecated", "archive", "chapter2", "legacy", "high")),
    ("80_Prompts/handoffs", ("research_note", "archived", "implementation", "chapter2", "context", "high")),
    ("80_Prompts", ("research_note", "active", "implementation", "chapter2", "context", "high")),
    ("85_reports", ("research_note", "active", "design", "chapter2", "reference", "high")),
    ("99_inactive", ("research_note", "archived", "archive", "chapter2", "legacy", "high")),
]

# existing status value (lowercased) -> normalized status, or None = flag-only (leave untouched)
STATUS_REMAP = {
    "active": "active",
    "draft": "draft",
    "locked": "locked",
    "superseded": "deprecated",
    "legacy": "deprecated",
    "inactive": "archived",
    "archived": "archived",
    "draft_for_review": "draft",
    "ready_to_fire": None,
    "active_advisory_ledger": None,
    "reconstructed_from_current_tex": None,
    "pending_resolution": None,
    "vif-safe": None,
    "vif-admissible with caution": None,
}

NORMALIZED_STATUSES = {"active", "locked", "deprecated", "archived", "draft"}
NORMALIZED_TYPES = {"research_note", "theory", "econometrics", "code_governance", "paper_facing"}


def dir_rule_for(rel_path):
    rel_posix = rel_path.replace(os.sep, "/")
    for prefix, rule in DIR_RULES:
        if rel_posix == prefix or rel_posix.startswith(prefix + "/"):
            return rule
    return ("research_note", "active", "design", "chapter2", "reference", "low")


def normalize_status(existing_status):
    """Returns (normalized_status, status_detail_or_None, flagged_reason_or_None)."""
    if existing_status is None:
        return None, None, None
    s = str(existing_status).strip()
    key = s.lower()
    if "lock" in key and key not in STATUS_REMAP:
        return "locked", (s if s != "locked" else None), None
    if key in STATUS_REMAP:
        mapped = STATUS_REMAP[key]
        if mapped is None:
            return s, None, f"unmapped status value '{s}' — left as-is, needs manual review"
        detail = s if mapped != s else None
        return mapped, detail, None
    return s, None, f"unrecognized status value '{s}' — left as-is, needs manual review"


def split_frontmatter(content):
    """Strictly detect top-of-file frontmatter. Returns (yaml_text, body, has_fm)."""
    lines = content.splitlines(keepends=True)
    idx = 0
    while idx < len(lines) and lines[idx].strip() == "":
        idx += 1
    if idx >= len(lines) or lines[idx].strip() != "---":
        return None, content, False
    start = idx + 1
    close = None
    for i in range(start, len(lines)):
        if lines[i].strip() == "---":
            close = i
            break
    if close is None:
        return None, content, False
    yaml_text = "".join(lines[start:close])
    body = "".join(lines[close + 1:])
    return yaml_text, body, True


def dump_scalar(v):
    """Canonical single-line YAML rendering of a scalar (bool/int/float/str/None),
    e.g. keeps booleans lowercase (true/false) instead of Python's True/False.
    width is set huge to disable PyYAML's automatic line-folding: a folded
    continuation line for a list item lands at the same indent as its '-'
    marker, which is invalid YAML for a sequence entry (confirmed corrupting
    chapter2_vault/80_Prompts/handoffs/2026-07-25_vecm_vs_..._synthesis.md)."""
    s = yaml.safe_dump(v, default_flow_style=True, width=10**6).rstrip("\n")
    if s.endswith("..."):
        s = s[:-3].rstrip("\n").rstrip()
    return s


def dump_frontmatter(data, key_order):
    """Emit YAML block preserving key_order, block style for lists."""
    ordered = {}
    for k in key_order:
        if k in data:
            ordered[k] = data[k]
    for k, v in data.items():
        if k not in ordered:
            ordered[k] = v
    lines = ["---"]
    for k, v in ordered.items():
        if isinstance(v, list):
            if len(v) == 0:
                lines.append(f"{k}: []")
            else:
                lines.append(f"{k}:")
                for item in v:
                    lines.append(f"  - {dump_scalar(item)}")
        else:
            lines.append(f"{k}: {dump_scalar(v)}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def process_file(path):
    """Returns a dict describing the action taken/planned for this file."""
    rel = os.path.relpath(path, VAULT_ROOT)
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    type_d, status_d, layer_d, scope_d, priority_d, confidence = dir_rule_for(rel)
    result = {
        "path": rel, "action": None, "flags": [], "old_yaml": None,
        "new_yaml": None, "new_content": None, "confidence": confidence,
    }

    if rel.replace(os.sep, "/") in STRAY_DUPLICATE_FILES:
        result["action"] = "skip"
        result["flags"].append("stray space-suffixed duplicate file — flagged only, not touched")
        return result

    yaml_text, body, has_fm = split_frontmatter(content)

    if not has_fm:
        data = {
            "type": type_d, "status": status_d, "country": "US_CL",
            "stage_scope": "N/A", "last_updated": TODAY,
            "depends_on": [], "blocks": [], "layer": layer_d,
            "scope": scope_d, "priority": priority_d,
        }
        result["action"] = "create"
        result["new_yaml"] = data
        result["new_content"] = dump_frontmatter(data, TEMPLATE_KEYS) + "\n" + body.lstrip("\n")
        if confidence == "low":
            result["flags"].append("low-confidence directory guess for type/layer/priority")
        return result

    try:
        parsed = yaml.safe_load(yaml_text)
    except yaml.YAMLError as e:
        result["action"] = "skip"
        result["flags"].append(f"YAML syntax error: {e}")
        return result

    if not isinstance(parsed, dict):
        result["action"] = "skip"
        result["flags"].append("frontmatter did not parse as a mapping")
        return result

    result["old_yaml"] = parsed
    key_order = list(parsed.keys())

    if DRIFT_DEPENDENCY_FIELDS & set(parsed.keys()):
        drift_fields = DRIFT_DEPENDENCY_FIELDS & set(parsed.keys())
        result["flags"].append(
            f"uses {sorted(drift_fields)} instead of depends_on — flagged, not auto-edited"
        )

    existing_status = parsed.get("status")
    norm_status, status_detail, status_flag = normalize_status(existing_status)
    is_locked = (norm_status == "locked") or (
        isinstance(existing_status, str) and "lock" in existing_status.lower()
    )
    if status_flag:
        result["flags"].append(status_flag)

    new_data = dict(parsed)

    if is_locked:
        result["action"] = "additive-locked"
        for key, default in [
            ("country", "US_CL"), ("stage_scope", "N/A"),
            ("last_updated", parsed.get("last_updated", TODAY)),
            ("depends_on", []), ("blocks", []), ("layer", layer_d),
            ("scope", scope_d), ("priority", priority_d),
        ]:
            if key not in new_data:
                new_data[key] = default
        if "status" not in new_data:
            new_data["status"] = status_d
        if "type" not in new_data:
            new_data["type"] = type_d
        result["flags"].append("locked file — additive-only, no existing values changed")
    else:
        result["action"] = "normalize"
        existing_type = parsed.get("type")
        if existing_type is not None and existing_type != type_d:
            if str(existing_type) not in NORMALIZED_TYPES:
                new_data["subtype"] = existing_type
            new_data["type"] = type_d
        elif existing_type is None:
            new_data["type"] = type_d

        if existing_status is not None:
            new_data["status"] = norm_status
            if status_detail:
                new_data["status_detail"] = status_detail
        else:
            new_data["status"] = status_d

        for key, default in [
            ("country", "US_CL"), ("stage_scope", "N/A"),
            ("last_updated", TODAY),
            ("depends_on", []), ("blocks", []), ("layer", layer_d),
            ("scope", scope_d), ("priority", priority_d),
        ]:
            if key not in new_data:
                new_data[key] = default

    for extra_key in ("subtype", "status_detail"):
        if extra_key in new_data and extra_key not in key_order:
            key_order = key_order + [extra_key]

    result["new_yaml"] = new_data
    result["new_content"] = dump_frontmatter(new_data, key_order) + "\n" + body.lstrip("\n")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="write changes (default is dry-run)")
    args = parser.parse_args()

    md_files = []
    for root, _, files in os.walk(VAULT_ROOT):
        if ".obsidian" in root.replace("\\", "/").split("/"):
            continue
        for fn in files:
            if fn.endswith(".md"):
                md_files.append(os.path.join(root, fn))
    md_files.sort()

    results = [process_file(p) for p in md_files]

    created = [r for r in results if r["action"] == "create"]
    normalized = [r for r in results if r["action"] == "normalize"]
    locked_touched = [r for r in results if r["action"] == "additive-locked"]
    skipped = [r for r in results if r["action"] == "skip"]
    flagged = [r for r in results if r["flags"] and r["action"] != "skip"]

    print("=" * 70)
    print("chapter2_vault frontmatter standardization —", "APPLY" if args.apply else "DRY RUN")
    print("=" * 70)
    print(f"Total .md files scanned: {len(results)}")
    print(f"  No frontmatter -> will create:      {len(created)}")
    print(f"  Existing, non-locked -> normalize:   {len(normalized)}")
    print(f"  Existing, locked -> additive only:   {len(locked_touched)}")
    print(f"  Skipped (parse error / not a dict):  {len(skipped)}")
    print()

    if created:
        print("--- Files with NO frontmatter (will create) ---")
        for r in created:
            note = f"  [{', '.join(r['flags'])}]" if r["flags"] else ""
            print(f"  + {r['path']}{note}")
        print()

    if locked_touched:
        print("--- LOCKED files (additive-only, flagged for manual review) ---")
        for r in locked_touched:
            added = sorted(set(r["new_yaml"]) - set(r["old_yaml"]))
            print(f"  * {r['path']}  (adding: {added if added else 'nothing missing'})")
        print()

    review_worthy = [r for r in normalized if r["flags"]]
    if review_worthy:
        print("--- Normalized files flagged for manual review ---")
        for r in review_worthy:
            print(f"  ! {r['path']}")
            for f in r["flags"]:
                print(f"      - {f}")
        print()

    if skipped:
        print("--- Skipped (manual fix needed) ---")
        for r in skipped:
            print(f"  x {r['path']}")
            for f in r["flags"]:
                print(f"      - {f}")
        print()

    quiet_normalized = [r for r in normalized if not r["flags"]]
    print(f"--- Normalized cleanly, no flags: {len(quiet_normalized)} files ---")
    for r in quiet_normalized:
        print(f"  ~ {r['path']}")
    print()

    if args.apply:
        n_written = 0
        for r in results:
            if r["action"] in ("create", "normalize", "additive-locked"):
                full_path = os.path.join(VAULT_ROOT, r["path"])
                with open(full_path, "w", encoding="utf-8", newline="\n") as f:
                    f.write(r["new_content"])
                n_written += 1
        print(f"APPLIED: wrote {n_written} files.")
    else:
        print("Dry run only — no files written. Re-run with --apply to write changes.")


if __name__ == "__main__":
    main()
