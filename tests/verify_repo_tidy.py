#!/usr/bin/env python3
"""
verify_repo_tidy.py
Automated Verification Script for Repository Tidiness Rules in Python.
Checks:
1. codes/ contains no subdirectories other than legacy/ and runs/
2. data/metadata/data_provenance_manifest.md exists and has valid YAML header with 6 mandatory fields
3. All markdown files in chapter2_vault/, reports/, drafts/ contain valid YAML headers with 6 mandatory fields
"""

import sys
import os
import glob
import re
import yaml

GREEN = "\033[32m"
RED = "\033[31m"
BOLD = "\033[1m"
RESET = "\033[0m"

MANDATORY_FIELDS = {"type", "status", "depends_on", "stage_scope", "country", "last_updated"}

def parse_yaml_frontmatter(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        return False, f"File read error: {e}", None

    content = content.lstrip('\ufeff')
    match = re.match(r'^---\s*\n(.*?)\n---\s*(\n|$)', content, re.DOTALL)
    if not match:
        return False, "File does not start with valid '---' YAML frontmatter block", None

    yaml_str = match.group(1)
    try:
        parsed = yaml.safe_load(yaml_str)
    except Exception as e:
        return False, f"YAML parse error: {e}", None

    if not isinstance(parsed, dict):
        return False, "YAML frontmatter did not parse as a key-value dictionary", None

    missing = MANDATORY_FIELDS - set(parsed.keys())
    if missing:
        return False, f"Missing mandatory field(s): {', '.join(sorted(missing))}", parsed

    return True, "OK", parsed

def main():
    print(f"{BOLD}===================================================={RESET}")
    print(f"{BOLD}  REPOSITORY TIDINESS VERIFICATION REPORT (Python){RESET}")
    print(f"{BOLD}===================================================={RESET}\n")

    all_passed = True

    # ----------------------------------------------------
    # Check 1: Subdirectories of codes/
    # ----------------------------------------------------
    print(f"{BOLD}[Check 1] Verify codes/ contains no subdirectories other than 'legacy/' and 'runs/'{RESET}")
    codes_dir = "codes"
    if not os.path.isdir(codes_dir):
        print(f"  Status: {RED}FAIL{RESET} - Directory '{codes_dir}' does not exist.\n")
        all_passed = False
    else:
        subdirs = [d for d in os.listdir(codes_dir) if os.path.isdir(os.path.join(codes_dir, d))]
        allowed_subdirs = {"legacy", "runs"}
        disallowed_subdirs = set(subdirs) - allowed_subdirs

        if disallowed_subdirs:
            print(f"  Status: {RED}FAIL{RESET} - Found disallowed subdirectories in codes/: {', '.join(sorted(disallowed_subdirs))}\n")
            all_passed = False
        else:
            print(f"  Status: {GREEN}PASS{RESET} - Top-level subdirectories in codes/ are restricted to 'legacy/' and 'runs/'.")
            print(f"          Found subdirectories: {', '.join(sorted(subdirs))}\n")

    # ----------------------------------------------------
    # Check 2: data/metadata/data_provenance_manifest.md
    # ----------------------------------------------------
    print(f"{BOLD}[Check 2] Verify data/metadata/data_provenance_manifest.md exists & has valid YAML header{RESET}")
    manifest_path = os.path.join("data", "metadata", "data_provenance_manifest.md")
    if not os.path.isfile(manifest_path):
        print(f"  Status: {RED}FAIL{RESET} - Manifest file '{manifest_path}' does not exist.\n")
        all_passed = False
    else:
        valid, msg, parsed = parse_yaml_frontmatter(manifest_path)
        if not valid:
            print(f"  Status: {RED}FAIL{RESET} - {msg}\n")
            all_passed = False
        else:
            print(f"  Status: {GREEN}PASS{RESET} - data_provenance_manifest.md exists and contains all 6 mandatory YAML fields:")
            print(f"          ({', '.join(sorted(MANDATORY_FIELDS))})\n")

    # ----------------------------------------------------
    # Check 3: Active vault & reports/drafts markdown frontmatter
    # ----------------------------------------------------
    print(f"{BOLD}[Check 3] Verify all markdown files in chapter2_vault/, reports/, drafts/ have valid 6-field YAML headers{RESET}")
    search_dirs = ["chapter2_vault", "reports", "drafts"]
    existing_dirs = [d for d in search_dirs if os.path.isdir(d)]

    md_files = []
    for d in existing_dirs:
        md_files.extend(glob.glob(os.path.join(d, "**", "*.md"), recursive=True))

    if not md_files:
        print(f"  Status: {RED}FAIL{RESET} - No markdown files found in target directories.\n")
        all_passed = False
    else:
        failed_files = {}
        for f in md_files:
            valid, msg, _ = parse_yaml_frontmatter(f)
            if not valid:
                failed_files[f] = msg

        if failed_files:
            print(f"  Status: {RED}FAIL{RESET} - {len(failed_files)} file(s) failed YAML header verification:")
            for fn, err in failed_files.items():
                print(f"          - {fn}: {err}")
            print()
            all_passed = False
        else:
            print(f"  Status: {GREEN}PASS{RESET} - Checked {len(md_files)} markdown files across {', '.join(existing_dirs)}.")
            print(f"          All {len(md_files)} files contain valid YAML headers with all 6 mandatory fields.\n")

    # ----------------------------------------------------
    # Summary Report & Exit
    # ----------------------------------------------------
    print(f"{BOLD}----------------------------------------------------{RESET}")
    if all_passed:
        print(f"  OVERALL VERIFICATION STATUS: {GREEN}PASS (ALL CHECKS OK){RESET}")
        print(f"{BOLD}===================================================={RESET}\n")
        sys.exit(0)
    else:
        print(f"  OVERALL VERIFICATION STATUS: {RED}FAIL{RESET}")
        print(f"{BOLD}===================================================={RESET}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
