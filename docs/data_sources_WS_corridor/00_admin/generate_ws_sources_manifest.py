from __future__ import annotations

import csv
import re
import unicodedata
from collections import Counter
from datetime import datetime
from difflib import SequenceMatcher
from pathlib import Path

import pdfplumber


SCRIPT_PATH = Path(__file__).resolve()
TARGET_DIR = SCRIPT_PATH.parent
REPO_ROOT = SCRIPT_PATH.parents[2]
CSV_OUTPUT = TARGET_DIR / "WS_sources_manifest.csv"
MD_OUTPUT = TARGET_DIR / "WS_sources_manifest.md"

SOURCE_EXTENSIONS = {".pdf", ".md", ".txt", ".doc", ".docx", ".bib", ".bibtex", ".csv", ".xlsx"}
NOTE_EXTENSIONS = {".md"}
BIB_EXTENSIONS = {".bib", ".bibtex"}
LEDGER_HINTS = {"ledger", "registry", "manifest", "source", "sources", "bibliography", "catalog", "inventory"}
EXCLUDED_FILENAMES = {SCRIPT_PATH.name.lower(), CSV_OUTPUT.name.lower(), MD_OUTPUT.name.lower(), ".ds_store", "thumbs.db"}
STATUS_PRIORITY = ["duplicate_candidate", "unclear_relevance", "needs_manual_review", "missing_metadata", "note_missing", "bib_missing", "ok"]
ROLE_ORDER = ["theory", "historiography", "evidence", "operationalization", "mixed", "unknown"]
DIMENSION_ORDER = [
    "Cold War geopolitics",
    "U.S. interventionism",
    "Third World / Non-Aligned Movement / NIEO politics",
    "Crisis of Atlantic Fordism / world monetary disorder",
    "External constraint / balance-of-payments / trade dependency",
    "Transnational capital / multinational corporate power",
    "Strategic commodities / copper / resource sovereignty",
    "Inter-American order / hemispheric security doctrine",
    "Diplomatic isolation, blockade, recognition, and alliance structure",
    "unknown",
]
CSV_FIELDS = [
    "ws_id",
    "file_name",
    "relative_path",
    "file_type",
    "folder_cluster",
    "title_guess",
    "author_guess",
    "year_guess",
    "citekey_guess",
    "source_type",
    "probable_dimension_primary",
    "probable_dimension_secondary",
    "probable_source_role",
    "probable_evidentiary_status",
    "probable_corridor_scope",
    "has_bib_entry",
    "related_note_exists",
    "related_note_path",
    "file_size_kb",
    "last_modified",
    "status_flag",
    "notes",
]


def normalize_text(value: str) -> str:
    text = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-zA-Z0-9]+", " ", text.lower())
    return re.sub(r"\s+", " ", text).strip()


def tokenize(value: str) -> list[str]:
    stopwords = {"a", "an", "and", "article", "book", "cold", "doc", "edited", "editors", "in", "journal", "new", "of", "review", "the", "war"}
    return [token for token in normalize_text(value).split() if len(token) > 2 and token not in stopwords]


def similarity(left: str, right: str) -> float:
    return SequenceMatcher(None, normalize_text(left), normalize_text(right)).ratio()


def has_keyword(normalized_text: str, keyword: str) -> bool:
    normalized_keyword = normalize_text(keyword)
    if not normalized_keyword:
        return False
    return re.search(rf"\b{re.escape(normalized_keyword)}\b", normalized_text) is not None


def is_temp_or_system(path: Path) -> bool:
    name = path.name.lower()
    return name in EXCLUDED_FILENAMES or name.startswith("~$") or name.endswith((".tmp", ".temp", ".bak", ".swp"))


def is_ledger(path: Path) -> bool:
    normalized = normalize_text(path.stem)
    return any(hint in normalized for hint in LEDGER_HINTS)


def is_source_file(path: Path) -> bool:
    if is_temp_or_system(path) or path.suffix.lower() not in SOURCE_EXTENSIONS:
        return False
    if path.suffix.lower() in {".csv", ".xlsx"} and not is_ledger(path):
        return False
    return True


def split_camel_case(value: str) -> list[str]:
    return re.findall(r"[A-Z][a-z]+|[A-Z]{2,}(?=[A-Z][a-z]|$)|[a-z]+|\d{4}", value)


def join_tokens(tokens: list[str]) -> str:
    cleaned = []
    for token in tokens:
        if token.isupper() or re.fullmatch(r"\d{4}", token):
            cleaned.append(token)
        else:
            cleaned.append(token.replace("Alligned", "Aligned"))
    return re.sub(r"\s+", " ", " ".join(cleaned)).strip(" -_")


def clean_display(value: str) -> str:
    text = value.replace("_", " ").replace("Alligned", "Aligned")
    text = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", text)
    return re.sub(r"\s+", " ", text).strip(" -_")


def sanitize_filename_title(value: str) -> str:
    title = clean_display(value)
    title = re.sub(r"\b(inSpanish|in Spanish|BookReview|Boook|Book|Article|CIA|DeclassifiedDoc)\b", "", title, flags=re.IGNORECASE)
    title = re.sub(r"\b[A-Z][a-z]+(?:[A-Z][a-z]+)+\d{4}\b", "", title)
    title = re.sub(r"\b[A-Z][a-z]+\d{4}\b", "", title)
    title = re.sub(r"\bReviewInternationalPoliticalEconomy\b", "", title, flags=re.IGNORECASE)
    title = re.sub(r"\b(?:RIL Editores|InstitutoIDEA)\b", "", title, flags=re.IGNORECASE)
    title = re.sub(r"\bInstituto IDEA\b", "", title, flags=re.IGNORECASE)
    title = re.sub(r"\b\d{4}\b", "", title)
    title = re.sub(r"\b\d{4}\s*-\s*\d{4}\b", "", title)
    title = re.sub(r"\s+", " ", title).strip(" -_,")
    return title


def infer_source_type(path: Path) -> str:
    name = normalize_text(path.name)
    if path.suffix.lower() in BIB_EXTENSIONS:
        return "bibliography"
    if path.suffix.lower() in NOTE_EXTENSIONS:
        return "markdown note"
    if path.suffix.lower() == ".txt":
        return "text note"
    if path.suffix.lower() in {".csv", ".xlsx"}:
        return "source ledger"
    if "declassified" in name or "cia" in name:
        return "declassified document"
    if "bookreview" in name:
        return "book review"
    if "journalcoldwar" in name:
        return "journal article"
    if name.startswith("book"):
        return "edited volume" if "edited" in name or "editors" in name else "book"
    if name.startswith("article"):
        return "article"
    return "pdf source" if path.suffix.lower() == ".pdf" else path.suffix.lower().lstrip(".")


def infer_year(path: Path) -> str:
    years = re.findall(r"(?<!\d)(18\d{2}|19\d{2}|20\d{2})(?!\d)", path.name)
    return years[-1] if years else "unknown"


def infer_folder_cluster(path: Path) -> str:
    relative_parent = path.relative_to(TARGET_DIR).parent
    return "root" if str(relative_parent) == "." else relative_parent.parts[-1]


def infer_author_from_filename(stem: str) -> str:
    bare = re.sub(r"\s*\([^)]*\)$", "", stem)
    bare = re.sub(r"^\[[^\]]+\]\s*", "", bare)
    if " - " in bare:
        parts = [part.strip() for part in bare.split(" - ") if part.strip()]
        if len(parts) >= 2:
            head = parts[:-1]
            if head and head[0].startswith("Book"):
                head[0] = re.sub(r"^Book(?:_[^_]+)*_", "", head[0]).strip("_ ")
            author_text = "; ".join(item.strip(" _-") for item in head if item.strip(" _-"))
            if author_text:
                author_text = re.sub(r"^\[[^\]]+\]\s*", "", author_text).strip()
                return author_text

    tokens = stem.split("_")
    if tokens[:1] == ["JournalColdWar"] and len(tokens) >= 3:
        return join_tokens(split_camel_case(re.sub(r"\d{4}$", "", tokens[2]))) or "unknown"
    if tokens[:1] == ["Bolshevik"] and len(tokens) >= 3:
        authors = [join_tokens(split_camel_case(token)) for token in tokens[1:3]]
        authors = [author for author in authors if author]
        return "; ".join(authors) if authors else "unknown"
    if stem.startswith("BookReview_") or stem.startswith("CIA_"):
        return "unknown"

    for index, token in enumerate(tokens):
        if token in {"Boook", "Book", "Article", "CIA"}:
            continue
        if re.search(r"\d{4}$", token):
            return join_tokens(split_camel_case(re.sub(r"\d{4}$", "", token))) or "unknown"
        if index + 1 < len(tokens) and tokens[index + 1] in {"Editors", "Edited"}:
            return join_tokens(split_camel_case(token)) or "unknown"
    return "unknown"


def infer_title_from_filename(stem: str) -> tuple[str, str]:
    bare = re.sub(r"\s*\([^)]*\)$", "", stem)
    bare = re.sub(r"^\[[^\]]+\]\s*", "", bare)
    if " - " in bare:
        parts = [part.strip() for part in bare.split(" - ") if part.strip()]
        if len(parts) >= 2:
            title = sanitize_filename_title(parts[-1])
            return (title, "filename") if len(title) >= 12 else ("unknown", "unknown")

    tokens = [token for token in stem.split("_") if token]
    if tokens[:1] in (["JournalColdWar"], ["Bolshevik"]):
        return "unknown", "unknown"

    filtered: list[str] = []
    for token in tokens:
        normalized = normalize_text(token)
        if normalized in {"article", "book", "journalcoldwar", "bookreview", "declassifieddoc", "cia", "reviewinternationalpoliticaleconomy"}:
            continue
        if re.fullmatch(r"\d{2}", token) or re.fullmatch(r"\d{4}", token):
            continue
        if re.search(r"\d{4}$", token) and not filtered:
            continue
        filtered.append(token)
    if "Editors" in filtered:
        filtered = filtered[filtered.index("Editors") + 1 :]
    if "Edited" in filtered:
        filtered = filtered[filtered.index("Edited") + 1 :]
    title = sanitize_filename_title("_".join(filtered))
    return (title, "filename") if len(title) >= 12 else ("unknown", "unknown")


def clean_metadata_title(value: str) -> str:
    candidate = re.sub(r"\s+", " ", value).strip()
    bad_patterns = [r"^\d+[_-]\d+\.pdf$", r"^vol\d+num\d+\.pdf$", r"pdfdrive"]
    if any(re.search(pattern, candidate, re.IGNORECASE) for pattern in bad_patterns):
        return ""
    candidate = candidate.replace("PDFDrive.com", "").replace(" - ", ": ").strip(" -:")
    return candidate


def read_pdf_metadata(path: Path) -> dict[str, str]:
    try:
        with pdfplumber.open(path) as pdf:
            metadata = pdf.metadata or {}
        return {str(key): str(value) for key, value in metadata.items() if value is not None}
    except Exception:
        return {}


def is_probable_author_line(line: str) -> bool:
    cleaned = line.replace("✣", "").strip()
    if not cleaned or len(cleaned) > 60 or re.search(r"\d", cleaned):
        return False
    if ":" in cleaned or ("," in cleaned and cleaned.count(",") > 1):
        return False
    words = cleaned.split()
    if not 1 <= len(words) <= 5:
        return False
    alpha_words = [word for word in words if re.search(r"[A-Za-z]", word)]
    if not alpha_words:
        return False
    capitals = sum(word[:1].isupper() for word in alpha_words)
    return capitals >= max(1, len(alpha_words) - 1)


def is_garbled_line(line: str) -> bool:
    words = re.findall(r"[A-Za-z]+", line)
    weird_words = 0
    for word in words:
        if len(word) < 4:
            continue
        if re.search(r"[a-z][A-Z]", word) or re.search(r"[A-Z]{2}[a-z]{2,}", word):
            weird_words += 1
    return weird_words >= 2


def infer_title_from_first_page(path: Path) -> str:
    try:
        with pdfplumber.open(path) as pdf:
            if not pdf.pages:
                return ""
            text = pdf.pages[0].extract_text() or ""
    except Exception:
        return ""

    lines = [re.sub(r"\s+", " ", line).strip() for line in text.splitlines()]
    lines = [line for line in lines if line]
    title_lines: list[str] = []
    for index, line in enumerate(lines[:10]):
        lowered = line.lower()
        if any(marker in lowered for marker in ["isbn", "copyright", "doi", "issn"]):
            if title_lines:
                break
            continue
        if "reseña" in lowered and not title_lines:
            continue
        if re.fullmatch(r"[✣*•]+", line):
            continue
        if "✣" in line and title_lines:
            break
        if title_lines and is_probable_author_line(line):
            break
        if not title_lines and is_garbled_line(line):
            continue
        if not title_lines and index + 1 < len(lines) and similarity(line, lines[index + 1]) >= 0.7:
            continue
        if len(line) <= 170:
            title_lines.append(line)
        if len(title_lines) >= 3:
            break
    candidate = re.sub(r"\s+", " ", " ".join(title_lines)).strip()
    return candidate if len(candidate) >= 12 else ""


def choose_title(path: Path, metadata: dict[str, str]) -> tuple[str, str]:
    filename_title, filename_source = infer_title_from_filename(path.stem)
    metadata_title = clean_metadata_title(metadata.get("Title", ""))
    first_page_title = infer_title_from_first_page(path) if path.suffix.lower() == ".pdf" else ""
    source_type = infer_source_type(path)
    if source_type in {"journal article", "book review"} and first_page_title:
        return first_page_title, "first_page"
    if source_type == "declassified document" and metadata_title:
        return metadata_title, "pdf_metadata"
    if filename_title != "unknown":
        return filename_title, filename_source
    if metadata_title:
        return metadata_title, "pdf_metadata"
    if first_page_title:
        return first_page_title, "first_page"
    return "unknown", "unknown"


def choose_author(path: Path, source_type: str, metadata: dict[str, str]) -> tuple[str, str]:
    filename_author = infer_author_from_filename(path.stem)
    metadata_author = re.sub(r"\s+", " ", metadata.get("Author", "")).strip()
    bad_metadata_authors = {"ashkarcito", "david parra", "dnunezor"}
    if filename_author != "unknown":
        return filename_author, "filename"
    if source_type != "book review" and metadata_author and normalize_text(metadata_author) not in bad_metadata_authors:
        return metadata_author, "pdf_metadata"
    return "unknown", "unknown"


def choose_citekey(author_guess: str, year_guess: str, title_guess: str) -> str:
    author_tokens = tokenize(author_guess)
    title_tokens = tokenize(title_guess)
    if author_guess == "unknown" or year_guess == "unknown" or title_guess == "unknown" or not author_tokens or not title_tokens:
        return "unknown"
    return f"{author_tokens[0]}{year_guess}{title_tokens[0]}"


def infer_dimensions(text_blob: str) -> tuple[str, str]:
    rules = [
        ("Third World / Non-Aligned Movement / NIEO politics", ["non aligned", "nonaligned", "third world", "darker nations", "decolonisation", "decolonization", "summits", "nieo"]),
        ("Inter-American order / hemispheric security doctrine", ["inter american", "alliance for progress", "hemispheric", "latin america", "western civilization"]),
        ("U.S. interventionism", ["eisenhower", "cia", "united states", "administration", "intervention"]),
        ("Strategic commodities / copper / resource sovereignty", ["copper", "resource sovereignty", "commodity", "commodities", "mining"]),
        ("External constraint / balance-of-payments / trade dependency", ["balance of payments", "balance-of-payments", "trade dependency", "external constraint", "dependency"]),
        ("Transnational capital / multinational corporate power", ["multinational", "corporate power", "transnational capital", "foreign capital"]),
        ("Crisis of Atlantic Fordism / world monetary disorder", ["fordism", "monetary", "bretton woods", "world monetary", "atlantic"]),
        ("Diplomatic isolation, blockade, recognition, and alliance structure", ["alliance structure", "recognition", "blockade", "diplomatic", "isolation"]),
        ("Cold War geopolitics", ["cold war", "guerra fria", "soviet", "urss", "ussr", "communist international", "komintern", "geopolitics"]),
    ]
    normalized = normalize_text(text_blob)
    matches = [label for label, keywords in rules if any(has_keyword(normalized, keyword) for keyword in keywords)]
    if not matches:
        return "unknown", "unknown"
    return matches[0], matches[1] if len(matches) > 1 else "unknown"


def infer_role(source_type: str, text_blob: str) -> str:
    normalized = normalize_text(text_blob)
    if source_type == "declassified document":
        return "evidence"
    if source_type == "source ledger":
        return "operationalization"
    if source_type == "book review":
        return "historiography"
    if any(has_keyword(normalized, keyword) for keyword in ["decolonisation", "decolonization", "third world", "political freedom"]):
        return "theory"
    if any(has_keyword(normalized, keyword) for keyword in ["document", "archive", "report"]):
        return "evidence"
    if source_type in {"book", "edited volume", "journal article", "article", "pdf source"} and any(
        has_keyword(normalized, keyword)
        for keyword in ["history", "historia", "cold war", "policy", "summits", "inter american", "soviet", "urss", "ussr", "komintern", "communist", "chile", "third world", "non aligned", "nonaligned"]
    ):
        return "historiography"
    return "unknown"


def infer_evidentiary_status(source_type: str, role: str) -> str:
    if source_type == "declassified document":
        return "archival"
    if source_type == "source ledger":
        return "quantitative"
    if role == "theory":
        return "conceptual"
    if role == "historiography":
        return "historiographic"
    if role == "evidence":
        return "evidentiary"
    return "unknown"


def infer_scope(text_blob: str) -> str:
    normalized = normalize_text(text_blob)
    overlap_tokens = ["chile", "latin america", "inter american", "gabriel gonzalez videla", "pcch", "urss", "ussr"]
    ws_tokens = ["cold war", "third world", "non aligned", "nonaligned", "iranian", "swiss", "world history", "soviet union"]
    if any(has_keyword(normalized, token) for token in overlap_tokens):
        return "overlap"
    if any(has_keyword(normalized, token) for token in ws_tokens):
        return "WS-only"
    return "unclear"


def build_note_index(note_paths: list[Path]) -> list[tuple[Path, set[str]]]:
    return [(path, set(tokenize(path.stem))) for path in note_paths]


def find_related_note(row: dict[str, str], note_index: list[tuple[Path, set[str]]]) -> tuple[str, str]:
    source_tokens = set(tokenize(row["file_name"])) | set(tokenize(row["title_guess"])) | set(tokenize(row["author_guess"]))
    best_score, best_path = 0.0, ""
    for path, note_tokens in note_index:
        if not note_tokens:
            continue
        overlap = len(source_tokens & note_tokens) / max(len(note_tokens), 1)
        score = max(overlap, similarity(row["file_name"], path.stem))
        if score > best_score:
            best_score = score
            best_path = path.relative_to(REPO_ROOT).as_posix()
    return ("true", best_path) if best_score >= 0.55 else ("false", "")


def parse_bib_entries(bib_paths: list[Path]) -> set[str]:
    citekeys: set[str] = set()
    pattern = re.compile(r"@\w+\s*\{\s*([^,\s]+)", re.IGNORECASE)
    for path in bib_paths:
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = path.read_text(encoding="latin-1")
        for match in pattern.finditer(text):
            citekeys.add(match.group(1).strip())
    return citekeys


def has_bib_match(row: dict[str, str], citekeys: set[str]) -> str:
    if not citekeys:
        return "false"
    guesses = {normalize_text(row["file_name"]).replace(" ", "")}
    if row["citekey_guess"] != "unknown":
        guesses.add(normalize_text(row["citekey_guess"]).replace(" ", ""))
    for citekey in citekeys:
        if normalize_text(citekey).replace(" ", "") in guesses:
            return "true"
    return "false"


def identify_duplicates(rows: list[dict[str, str]]) -> dict[str, str]:
    duplicates: dict[str, str] = {}
    for index, left in enumerate(rows):
        if left["title_guess"] == "unknown":
            continue
        left_tokens = set(tokenize(left["title_guess"])) | set(tokenize(left["author_guess"]))
        for right in rows[index + 1 :]:
            if right["title_guess"] == "unknown":
                continue
            right_tokens = set(tokenize(right["title_guess"])) | set(tokenize(right["author_guess"]))
            token_overlap = len(left_tokens & right_tokens)
            minimum = min(len(left_tokens), len(right_tokens)) or 1
            ratio = similarity(left["title_guess"], right["title_guess"])
            same_year = left["year_guess"] != "unknown" and left["year_guess"] == right["year_guess"]
            if ratio >= 0.93 or (same_year and token_overlap >= 3 and token_overlap / minimum >= 0.75):
                duplicates[left["ws_id"]] = right["file_name"]
                duplicates[right["ws_id"]] = left["file_name"]
    return duplicates


def choose_status(row: dict[str, str], duplicates: dict[str, str]) -> str:
    candidates = []
    if row["ws_id"] in duplicates:
        candidates.append("duplicate_candidate")
    if row["probable_dimension_primary"] == "unknown" or row["probable_corridor_scope"] == "unclear":
        candidates.append("unclear_relevance")
    missing = sum(row[field] == "unknown" for field in ["title_guess", "author_guess", "year_guess"])
    if missing >= 2:
        candidates.append("missing_metadata")
    elif missing == 1:
        candidates.append("needs_manual_review")
    if row["related_note_exists"] == "false":
        candidates.append("note_missing")
    if row["has_bib_entry"] == "false":
        candidates.append("bib_missing")
    if not candidates:
        return "ok"
    for status in STATUS_PRIORITY:
        if status in candidates:
            return status
    return "ok"


def build_notes(row: dict[str, str], title_source: str, author_source: str, duplicates: dict[str, str], metadata: dict[str, str]) -> str:
    notes = []
    notes.append("title inferred from filename" if title_source == "filename" else "title inferred from first-page text" if title_source == "first_page" else "title observed in PDF metadata" if title_source == "pdf_metadata" else "title unresolved")
    notes.append("author inferred from filename" if author_source == "filename" else "author observed in PDF metadata" if author_source == "pdf_metadata" else "author unresolved")
    if metadata.get("Title") and not clean_metadata_title(metadata.get("Title", "")):
        notes.append("PDF title metadata appears noisy")
    if row["related_note_exists"] == "false":
        notes.append("no local note companion")
    if row["has_bib_entry"] == "false":
        notes.append("no local bib companion")
    if row["folder_cluster"] == "root":
        notes.append("flat folder placement")
    if row["ws_id"] in duplicates:
        notes.append(f"possible near-duplicate with {duplicates[row['ws_id']]}")
    if row["file_name"].startswith("Boook_"):
        notes.append("filename prefix typo")
    return "; ".join(notes)


def summarize_counter(counter: Counter[str], order: list[str] | None = None) -> list[tuple[str, int]]:
    if order:
        ordered = [(label, counter.get(label, 0)) for label in order if counter.get(label, 0)]
        seen = {label for label, _ in ordered}
        extras = sorted((label, count) for label, count in counter.items() if label not in seen)
        return ordered + extras
    return sorted(counter.items(), key=lambda item: (-item[1], item[0]))


def inventory_table(rows: list[dict[str, str]], chunk_size: int = 10) -> list[str]:
    lines = ["Full 22-column inventory is in `WS_sources_manifest.csv`; the table below shows the main audit fields."]
    headers = ["ws_id", "file_name", "source_type", "title_guess", "author_guess", "year_guess", "probable_dimension_primary", "probable_source_role", "probable_corridor_scope", "status_flag"]
    for start in range(0, len(rows), chunk_size):
        chunk = rows[start : start + chunk_size]
        if len(rows) > chunk_size:
            lines.append(f"\n### Inventory rows {start + 1}-{start + len(chunk)}")
        lines.append("| " + " | ".join(headers) + " |")
        lines.append("| " + " | ".join(["---"] * len(headers)) + " |")
        for row in chunk:
            lines.append("| " + " | ".join(str(row[header]).replace("|", "\\|") for header in headers) + " |")
    return lines


def strongest_and_weakest(dimension_counter: Counter[str]) -> tuple[list[str], list[str]]:
    dimensions = {label: dimension_counter.get(label, 0) for label in DIMENSION_ORDER if label != "unknown"}
    max_count = max(dimensions.values(), default=0)
    strongest = [label for label, count in dimensions.items() if count == max_count and count > 0]
    weakest = [label for label, count in dimensions.items() if count == 0]
    return strongest, weakest


def render_report(rows: list[dict[str, str]], duplicates: dict[str, str], note_paths: list[Path], bib_paths: list[Path]) -> str:
    file_type_counter = Counter(row["file_type"] for row in rows)
    role_counter = Counter(row["probable_source_role"] for row in rows)
    dimension_counter = Counter(row["probable_dimension_primary"] for row in rows)
    scope_counter = Counter(row["probable_corridor_scope"] for row in rows)
    prefix_counter = Counter(row["file_name"].split("_")[0] if "_" in row["file_name"] else row["file_name"] for row in rows)
    missing_notes = sum(row["related_note_exists"] == "false" for row in rows)
    missing_bibs = sum(row["has_bib_entry"] == "false" for row in rows)
    missing_metadata = sum(any(row[field] == "unknown" for field in ["title_guess", "author_guess", "year_guess"]) for row in rows)
    unclear = sum(row["probable_dimension_primary"] == "unknown" or row["probable_corridor_scope"] == "unclear" for row in rows)
    strongest, weakest = strongest_and_weakest(dimension_counter)
    strongest_text = ", ".join(strongest) if strongest else "none yet"
    weakest_text = ", ".join(weakest) if weakest else "none"
    role_leader = max(role_counter.items(), key=lambda item: (item[1], item[0]))[0] if role_counter else "unknown"

    def bullets(counter: Counter[str], order: list[str] | None = None) -> list[str]:
        return [f"- {label}: {count}" for label, count in summarize_counter(counter, order)] or ["- none: 0"]

    lines = [
        "# WS Sources Manifest",
        "## 1. Executive summary",
        f"- total files: {len(rows)}",
        "- counts by type:",
        *bullets(file_type_counter),
        "- counts by probable source role:",
        *bullets(role_counter, ROLE_ORDER),
        "- counts by probable WS dimension (primary):",
        *bullets(dimension_counter, DIMENSION_ORDER),
        "- counts by corridor scope:",
        *bullets(scope_counter, ["WS-only", "AR-only", "overlap", "unclear"]),
        "- key issues detected:",
        "- flat folder with no subdirectories under `docs/data_sources_WS_corridor`",
        f"- {missing_notes} items without a local markdown note companion",
        f"- {missing_bibs} items without a local `.bib` / `.bibtex` companion",
        f"- {missing_metadata} items with unresolved core metadata",
        f"- {unclear} items needing manual relevance or dimension review" if unclear else "- no unclear relevance flags",
        f"- {len(duplicates)} items flagged as duplicate candidates" if duplicates else "- no strong duplicate candidates detected",
        "## 2. Folder structure snapshot",
        "The current target folder is flat: there are no nested subfolders under `docs/data_sources_WS_corridor`.",
        "The organizing logic is filename-prefix based rather than folder-cluster based.",
        "Observed prefix families:",
        *bullets(prefix_counter),
        f"Local markdown notes detected: {len(note_paths)}.",
        f"Local bibliography files detected: {len(bib_paths)}.",
        "## 3. Source inventory table",
        *inventory_table(rows),
        "## 4. Duplicates, metadata gaps, and cleanup issues",
    ]

    if duplicates:
        seen_pairs = set()
        for row in rows:
            other = duplicates.get(row["ws_id"])
            if not other:
                continue
            pair = tuple(sorted((row["file_name"], other)))
            if pair in seen_pairs:
                continue
            seen_pairs.add(pair)
            lines.append(f"- {pair[0]} <-> {pair[1]}")
    else:
        lines.append("- No strong duplicate candidates detected under the current similarity thresholds.")

    gaps = [row for row in rows if any(row[field] == "unknown" for field in ["title_guess", "author_guess", "year_guess"])]
    if gaps:
        lines.append("Files with missing or weak metadata:")
        for row in gaps:
            fields = ", ".join(field.replace("_guess", "") for field in ["title_guess", "author_guess", "year_guess"] if row[field] == "unknown")
            lines.append(f"- {row['file_name']}: unresolved {fields}")
    else:
        lines.append("- No core metadata gaps detected.")

    lines.append("- No orphan local notes detected." if not note_paths else "Orphan local notes:")
    if note_paths:
        for path in note_paths:
            lines.append(f"- {path.relative_to(REPO_ROOT).as_posix()}")
    lines.append("- No local bibliography files detected." if not bib_paths else "Local bibliography files for manual cross-check:")
    if bib_paths:
        for path in bib_paths:
            lines.append(f"- {path.relative_to(REPO_ROOT).as_posix()}")
    if any(row["file_name"].startswith("Boook_") for row in rows):
        lines.append("Naming or cleanup issues:")
        for row in rows:
            if row["file_name"].startswith("Boook_"):
                lines.append(f"- {row['file_name']}: inconsistent filename prefix spelling")

    lines.extend(
        [
            "## 5. Preliminary assessment for WS-corridor readiness",
            f"Current holdings are strongest in: {strongest_text}.",
            f"Current holdings are thinnest in: {weakest_text}.",
            f"The present corpus skews toward {role_leader}.",
            "Immediate next ingestion should prioritize thin dimensions with documentary or evidentiary sources, because the current set is dominated by general Cold War and historiographic material.",
        ]
    )
    return "\n".join(lines) + "\n"


def collect_rows() -> tuple[list[dict[str, str]], list[Path], list[Path], dict[str, dict[str, str]], dict[str, tuple[str, str]]]:
    source_paths = sorted([path for path in TARGET_DIR.rglob("*") if path.is_file() and is_source_file(path)], key=lambda path: str(path.relative_to(REPO_ROOT)).lower())
    note_paths = [path for path in source_paths if path.suffix.lower() in NOTE_EXTENSIONS]
    bib_paths = [path for path in source_paths if path.suffix.lower() in BIB_EXTENSIONS]
    metadata_map: dict[str, dict[str, str]] = {}
    provenance_map: dict[str, tuple[str, str]] = {}
    rows: list[dict[str, str]] = []

    for index, path in enumerate(source_paths, start=1):
        metadata = read_pdf_metadata(path) if path.suffix.lower() == ".pdf" else {}
        title_guess, title_source = choose_title(path, metadata)
        source_type = infer_source_type(path)
        author_guess, author_source = choose_author(path, source_type, metadata)
        year_guess = infer_year(path)
        text_blob = " ".join(value for value in [path.name, "" if title_guess == "unknown" else title_guess, "" if author_guess == "unknown" else author_guess] if value)
        dimension_primary, dimension_secondary = infer_dimensions(text_blob)
        role = infer_role(source_type, text_blob)
        relative_path = path.relative_to(REPO_ROOT).as_posix()
        row = {
            "ws_id": f"WS_{index:03d}",
            "file_name": path.name,
            "relative_path": relative_path,
            "file_type": path.suffix.lower().lstrip("."),
            "folder_cluster": infer_folder_cluster(path),
            "title_guess": title_guess,
            "author_guess": author_guess,
            "year_guess": year_guess,
            "citekey_guess": choose_citekey(author_guess, year_guess, title_guess),
            "source_type": source_type,
            "probable_dimension_primary": dimension_primary,
            "probable_dimension_secondary": dimension_secondary,
            "probable_source_role": role,
            "probable_evidentiary_status": infer_evidentiary_status(source_type, role),
            "probable_corridor_scope": infer_scope(text_blob),
            "has_bib_entry": "false",
            "related_note_exists": "false",
            "related_note_path": "",
            "file_size_kb": f"{path.stat().st_size / 1024:.1f}",
            "last_modified": datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds"),
            "status_flag": "ok",
            "notes": "",
        }
        rows.append(row)
        metadata_map[relative_path] = metadata
        provenance_map[relative_path] = (title_source, author_source)
    return rows, note_paths, bib_paths, metadata_map, provenance_map


def write_csv(rows: list[dict[str, str]]) -> None:
    with CSV_OUTPUT.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    rows, note_paths, bib_paths, metadata_map, provenance_map = collect_rows()
    note_index = build_note_index(note_paths)
    citekeys = parse_bib_entries(bib_paths)
    for row in rows:
        row["related_note_exists"], row["related_note_path"] = find_related_note(row, note_index)
        row["has_bib_entry"] = has_bib_match(row, citekeys)
    duplicates = identify_duplicates(rows)
    for row in rows:
        title_source, author_source = provenance_map[row["relative_path"]]
        row["status_flag"] = choose_status(row, duplicates)
        row["notes"] = build_notes(row, title_source, author_source, duplicates, metadata_map[row["relative_path"]])
    write_csv(rows)
    MD_OUTPUT.write_text(render_report(rows, duplicates, note_paths, bib_paths), encoding="utf-8")
    print(f"Generated {CSV_OUTPUT.relative_to(REPO_ROOT).as_posix()} and {MD_OUTPUT.relative_to(REPO_ROOT).as_posix()}")
    print(f"Total source files: {len(rows)}")
    print(f"Counts by type: {dict(Counter(row['file_type'] for row in rows))}")
    print(f"Counts by probable source role: {dict(Counter(row['probable_source_role'] for row in rows))}")
    print(f"Counts by corridor scope: {dict(Counter(row['probable_corridor_scope'] for row in rows))}")


if __name__ == "__main__":
    main()
