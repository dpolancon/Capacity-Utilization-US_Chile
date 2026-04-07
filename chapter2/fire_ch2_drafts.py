"""
fire_ch2_drafts.py
==================
Fires all Ch2 theory section prompts to claude-opus-4-6 concurrently.
Writes draft outputs to agents/drafts/.

Usage (from repo root via Claude Code):
    python agents/fire_ch2_drafts.py

Requirements: anthropic Python SDK (pip install anthropic)
Reads prompts from: agents/ch2_section_prompts.md
Writes drafts to:   agents/drafts/ch2_<section>_draft_v1.md

All sections fired concurrently. Wall time = longest single section (~3-5 min).
"""

import anthropic
import asyncio
import re
import os
from pathlib import Path
from datetime import datetime

# ── Config ──────────────────────────────────────────────────────────────────

MODEL = "claude-opus-4-6"
MAX_TOKENS = 4000
OUTPUT_DIR = Path("agents/drafts")
PROMPTS_FILE = Path("agents/ch2_section_prompts.md")

# Sections to fire (subset: theory-complete only; skip LATEX CONTEXT BLOCK)
SECTION_IDS = [
    "§2.1",
    "§2.2.1",
    "§2.2.2",
    "§2.2.3",
    "§2.2.4",
    "§2.2.5",
    "§2.3.1",
    "§2.3.2",
    "§2.3.3",
    "§2.4",
    "§2.5.1",
    "§2.5.2",
    "§2.5.3",
    "§2.5.4",
    "§2.5.5",
    "§2.7.1-§2.7.6",
    "§2.9",
]

# ── Parse prompts file ───────────────────────────────────────────────────────

def parse_prompts(path: Path) -> dict[str, str]:
    """Extract section_id -> prompt text from the prompts markdown file."""
    text = path.read_text(encoding="utf-8")
    prompts = {}

    # Find all PROMPT blocks: ## PROMPT §X.X — Title ... ``` ... ```
    pattern = re.compile(
        r"^## PROMPT (§[\d\.\-]+[^)\n]*)\n\n```\n(.*?)```",
        re.MULTILINE | re.DOTALL
    )
    for match in pattern.finditer(text):
        header = match.group(1).strip()
        body = match.group(2).strip()
        # Extract section ID from header (e.g. "§2.3.2 — Layer 1..." → "§2.3.2")
        sec_id = re.match(r"(§[\d\.\-]+)", header)
        if sec_id:
            prompts[sec_id.group(1)] = body

    return prompts

# ── Fire one section ─────────────────────────────────────────────────────────

async def fire_section(
    client: anthropic.AsyncAnthropic,
    section_id: str,
    prompt: str,
    sem: asyncio.Semaphore,
) -> tuple[str, str]:
    """Fire one section prompt and return (section_id, draft_text)."""
    async with sem:
        print(f"  → firing {section_id}...")
        message = await client.messages.create(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            messages=[{"role": "user", "content": prompt}],
        )
        draft = message.content[0].text
        print(f"  ✓ {section_id} done ({len(draft.split())} words)")
        return section_id, draft

# ── Write output ─────────────────────────────────────────────────────────────

def write_draft(section_id: str, draft: str, output_dir: Path) -> Path:
    """Write draft to agents/drafts/ch2_<sec>_draft_v1.md."""
    safe_id = section_id.replace("§", "sec").replace(".", "_").replace("-", "_")
    filename = output_dir / f"ch2_{safe_id}_draft_v1.md"
    header = (
        f"# Draft: {section_id}\n"
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        f"Model: {MODEL}\n"
        f"Status: FIRST DRAFT — review required\n\n"
        f"---\n\n"
    )
    filename.write_text(header + draft, encoding="utf-8")
    return filename

# ── Main ─────────────────────────────────────────────────────────────────────

async def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    if not PROMPTS_FILE.exists():
        raise FileNotFoundError(
            f"Prompts file not found: {PROMPTS_FILE}\n"
            "Copy agents/ch2_section_prompts.md from outputs/ to agents/ first."
        )

    print(f"Parsing prompts from {PROMPTS_FILE}...")
    all_prompts = parse_prompts(PROMPTS_FILE)

    # Filter to sections we want to fire
    to_fire = {
        sid: all_prompts[sid]
        for sid in SECTION_IDS
        if sid in all_prompts
    }
    missing = [sid for sid in SECTION_IDS if sid not in all_prompts]
    if missing:
        print(f"WARNING: sections not found in prompts file: {missing}")

    print(f"Firing {len(to_fire)} sections concurrently → {OUTPUT_DIR}/\n")

    client = anthropic.AsyncAnthropic()
    # Limit concurrency to 5 to avoid rate limits
    sem = asyncio.Semaphore(5)

    tasks = [
        fire_section(client, sid, prompt, sem)
        for sid, prompt in to_fire.items()
    ]

    start = datetime.now()
    results = await asyncio.gather(*tasks, return_exceptions=True)
    elapsed = (datetime.now() - start).seconds

    print(f"\nAll sections complete in {elapsed}s. Writing files...")
    written = []
    errors = []
    for result in results:
        if isinstance(result, Exception):
            errors.append(str(result))
        else:
            sid, draft = result
            path = write_draft(sid, draft, OUTPUT_DIR)
            written.append(str(path))

    print(f"\n✓ {len(written)} drafts written to {OUTPUT_DIR}/")
    for f in sorted(written):
        print(f"  {f}")
    if errors:
        print(f"\n✗ {len(errors)} errors:")
        for e in errors:
            print(f"  {e}")

    print(f"\nNext step: review drafts, then assemble into ch2_draft_v1.tex")


if __name__ == "__main__":
    asyncio.run(main())
