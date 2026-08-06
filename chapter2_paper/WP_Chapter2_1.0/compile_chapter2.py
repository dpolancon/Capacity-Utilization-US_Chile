# compile_chapter2.py
import os
import re
from pathlib import Path

def index_to_letters(n):
    """
    Converts a 0-based integer to spreadsheet-style letters:
    0 -> A, 25 -> Z, 26 -> AA, 27 -> AB, etc.
    """
    letters = ""
    while n >= 0:
        letters = chr(65 + (n % 26)) + letters
        n = (n // 26) - 1
    return letters

def parse_footnotes(content):
    """
    Finds and extracts footnote definitions [^id]: text and stores them in a dict.
    Strips them from the text.
    """
    footnote_defs = {}
    pattern = re.compile(r'^\[\^([^\]]+)\]:\s*(.+)$', re.MULTILINE)
    matches = pattern.findall(content)
    for fn_id, text in matches:
        footnote_defs[fn_id.strip()] = text.strip()
    
    cleaned_content = pattern.sub('', content)
    return cleaned_content, footnote_defs

def tokenize_math(text):
    """
    Protects all math, code, and footnote blocks by replacing them with alphanumeric placeholders.
    Converts $$...$$ to \[...\] and `code` to \texttt{code} with escaped special chars.
    """
    pattern = re.compile(
        r'('
        r'\$\$.*?\$\$|'
        r'(?<!\\)\$.*?(?<!\\)\$|'
        r'\\\[.*?\\\]|'
        r'\\\(.*?\\\)|'
        r'`[^`]+`|'
        r'\[\^[^\]]+\]|'
        r'\\begin\{[^}]+\}.*?\\end\{[^}]+\}'
        r')', 
        re.DOTALL
    )
    
    parts = []
    last_end = 0
    placeholders = {}
    
    for idx, match in enumerate(pattern.finditer(text)):
        start, end = match.span()
        parts.append(text[last_end:start])
        ph = f"MATHPLACEHOLDER{idx}XYZ"
        parts.append(ph)
        
        math_text = match.group(0)
        # Convert $$ to \[ \]
        if math_text.startswith('$$') and math_text.endswith('$$'):
            math_text = '\\[' + math_text[2:-2] + '\\]'
        # Convert `code` to \texttt{code} and escape special characters
        elif math_text.startswith('`') and math_text.endswith('`'):
            inner_text = math_text[1:-1]
            inner_text = inner_text.replace('_', '\\_').replace('%', '\\%').replace('&', '\\&')
            math_text = f"\\texttt{{{inner_text}}}"
            
        placeholders[ph] = math_text
        last_end = end
        
    parts.append(text[last_end:])
    return "".join(parts), placeholders

def tokenize_latex_commands(text, placeholders):
    """
    Protects raw LaTeX control sequences and their braced arguments.

    Several drafts contain literal LaTeX -- \\ref, \\PLACEHOLDER, \\texttt, \\emph --
    and the escaping passes below would otherwise rewrite "\\ref{fig:specA_elasticity}"
    as "\\ref{fig:specA\\_elasticity}", which is a compile error. Brace groups are
    matched by counting, so nested arguments survive intact.
    """
    out = []
    i, n, idx = 0, len(text), len(placeholders)
    while i < n:
        if text[i] == '\\' and i + 1 < n and text[i + 1].isalpha():
            j = i + 1
            while j < n and text[j].isalpha():
                j += 1
            k = j
            while k < n and text[k] == '{':          # consume balanced argument groups
                depth = 0
                while k < n:
                    if text[k] == '{':
                        depth += 1
                    elif text[k] == '}':
                        depth -= 1
                        if depth == 0:
                            k += 1
                            break
                    k += 1
                if depth != 0:                        # unbalanced: leave the rest alone
                    k = j
                    break
            ph = f"LATEXPLACEHOLDER{idx}XYZ"
            placeholders[ph] = text[i:k]
            out.append(ph)
            idx += 1
            i = k
        else:
            out.append(text[i])
            i += 1
    return ''.join(out)


def clean_formatting(text, footnotes):
    """
    Translates basic markdown formatting to LaTeX.
    Protects math blocks and raw LaTeX from being corrupted by the escaping passes.
    """
    # 1. Protect math blocks, then raw LaTeX control sequences
    text, math_placeholders = tokenize_math(text)
    text = tokenize_latex_commands(text, math_placeholders)
    
    # 2-3. Bold and italics.
    #
    # Both patterns require the emphasised span to contain at least one character that
    # is not itself a delimiter, and to begin and end on non-whitespace. Without those
    # guards a run of significance stars is misread: the old bold pattern matched from
    # the "**" inside "0.58***" all the way to the "**" in a later "0.60**", and the old
    # italic pattern turned the leftover star into an empty "\textit{}". That is the
    # origin of the "0.58\textit{}* (0.02)" artifacts in the generated sections.
    # Significance stars in prose are now left intact.
    text = re.sub(r'(?<!\*)\*\*(?!\s)([^*]+?)(?<!\s)\*\*(?!\*)', r'\\textbf{\1}', text)
    text = re.sub(r'(?<!_)__(?!\s)([^_]+?)(?<!\s)__(?!_)', r'\\textbf{\1}', text)

    text = re.sub(r'(?<![*\\])\*(?!\s)([^*]+?)(?<!\s)\*(?!\*)', r'\\textit{\1}', text)
    text = re.sub(r'(?<![\w\\_])_(?!\s)([^_]+?)(?<!\s)_(?![\w_])', r'\\textit{\1}', text)
    
    # 4. Strip Obsidian double bracket links [[Note]] or [[Note|label]]
    text = re.sub(r'\[\[([^\]|]+)\|([^\]]+)\]\]', r'\2', text)
    text = re.sub(r'\[\[([^\]]+)\]\]', r'\1', text)
    
    # 5. Markdown links [label](url) -> \href{url}{label}
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\\href{\2}{\1}', text)
    
    # 6. Handle percentage signs % -> \% (unless already escaped or inside a placeholder)
    text = re.sub(r'(?<!\\)%', r'\%', text)
    
    # 6.3. Strip Obsidian block anchors (e.g. ^block-id)
    text = re.sub(r'(?<!\\)\^[a-zA-Z0-9-]+', '', text)
    
    # 6.5. Escape remaining raw underscores and ampersands in normal text
    text = re.sub(r'(?<!\\)_', r'\\_', text)
    text = re.sub(r'(?<!\\)&', r'\\&', text)
    
    # 7. Restore math blocks
    for ph, math_text in math_placeholders.items():
        text = text.replace(ph, math_text)
        
    # 8. Inline footnote markers [^id] -> \footnote{text}
    def replace_footnote(match):
        fn_id = match.group(1).strip()
        if fn_id in footnotes:
            # Clean inside the footnote recursively
            fn_text = clean_formatting(footnotes[fn_id], {})
            return f"\\footnote{{{fn_text}}}"
        return f"[^{fn_id}]"
        
    text = re.sub(r'\[\^([^\]]+)\]', replace_footnote, text)
    
    return text

def strip_manual_number(title):
    """
    Removes a hand-typed heading number so it cannot collide with LaTeX's own counter.

    Covers both the body form ("4.2 Empirical Reconstruction...") and the appendix form
    ("D.1 Why the Type 2 test governs"). Left in place, these render as "4.5 4.4 ..." and
    "D.1 D.1 ..." once LaTeX adds its own numbering.
    """
    title = re.sub(r'^Appendix\s+[A-Z]\s*[:.]\s*', '', title)   # LaTeX supplies the letter
    title = re.sub(r'^[A-Z]\.[0-9]+(?:\.[0-9]+)*\.?\s+', '', title)
    title = re.sub(r'^[0-9]+(?:\.[0-9]+)*\.?\s+', '', title)
    return title.strip()


def resolve_asset_path(path):
    """
    Normalizes a draft's reference to a repo asset into a path relative to the
    manuscript directory (chapter2_paper/WP_Chapter2_1.0/ -> ../../).

    Drafts may write the path as repo-relative ("output/US/fig.png"), as an absolute
    Windows path, or as a file:/// URL. All three resolve to the same include, so the
    markdown keeps a readable wire and the manuscript stays portable.
    """
    p = path.strip().replace('\\', '/')
    p = re.sub(r'^file:///?', '', p)
    p = re.sub(r'^[A-Za-z]:/ReposGitHub/Capacity-Utilization-US_Chile/', '', p)
    p = p.lstrip('/')
    if p.startswith('../'):
        return p
    return '../../' + p


def slugify_label(caption):
    """Derives a stable \\label key from a table caption."""
    slug = re.sub(r'[^a-z0-9]+', '_', caption.lower()).strip('_')
    return f"tab:{slug[:48]}" if slug else "tab:unlabeled"


def parse_markdown_table(block, footnotes, caption=None):
    """
    Converts a markdown table block to a LaTeX table block using booktabs.
    Enforces top caption, bottom note, and explicit p{} sizing for all columns.

    `caption` comes from the nearest preceding "**Table N: ...**" line in the draft.
    It used to be hard-coded, which gave every table in the manuscript the same
    caption and the same \\label, producing "multiply defined" warnings and three
    tables captioned as data they did not contain.
    """
    lines = [l.strip() for l in block.strip().split('\n') if l.strip()]
    if len(lines) < 3:
        return block # Not a valid table
    
    # Header line
    headers = [h.strip() for h in lines[0].split('|')[1:-1]]
    num_cols = len(headers)
    
    # Generate explicit column widths for all columns
    col_widths = []
    for idx in range(num_cols):
        if idx == 0:
            col_widths.append("p{5.5cm}")
        else:
            col_widths.append("p{2.2cm}")
    tabular_align = "".join(col_widths)
    
    # Calculate total width for the bottom note multicolumn
    total_width = 5.5 + 2.2 * (num_cols - 1)
    
    latex_lines = []
    latex_lines.append(r"\begin{table}[H]")
    latex_lines.append(r"\centering")
    caption = caption or "Untitled Table"
    latex_lines.append(r"\caption{" + clean_formatting(caption, {}) + "}")
    latex_lines.append(r"\label{" + slugify_label(caption) + "}")
    latex_lines.append(r"\begin{tabular}{" + tabular_align + "}")
    latex_lines.append(r"\toprule")
    
    # Header cells
    clean_headers = [clean_formatting(h, {}) for h in headers]
    latex_lines.append(" & ".join(clean_headers) + r" \\")
    latex_lines.append(r"\midrule")
    
    # Body rows
    for row in lines[2:]:
        cells = [c.strip() for c in row.split('|')[1:-1]]
        clean_cells = [clean_formatting(c, {}) for c in cells]
        latex_lines.append(" & ".join(clean_cells) + r" \\")
        
    # Check for detailed data provenance footnote to inline as bottom note
    note_content = None
    note_key = None
    for k, v in list(footnotes.items()):
        if 'provenance' in k or 'note' in k:
            note_content = clean_formatting(v, {})
            note_key = k
            break
            
    if note_content:
        # Remove footnote from dict so it isn't compiled as page footnote
        del footnotes[note_key]
        latex_lines.append(r"\midrule")
        latex_lines.append(f"\\multicolumn{{{num_cols}}}{{p{{{total_width}cm}}}}{{\\footnotesize \\textbf{{Note:}} {note_content}}} \\\\")
        
    latex_lines.append(r"\bottomrule")
    latex_lines.append(r"\end{tabular}")
    latex_lines.append(r"\end{table}")
    
    return "\n".join(latex_lines)

def process_file_content(content, section_num, starting_subsection=0, shift_headers=False):
    """
    Parses draft markdown content and generates the body of a LaTeX section.
    Automatically assigns letter-only paragraph headers resetting at subsection/subsubsection.
    """
    # Strip Obsidian frontmatter
    if content.startswith('---'):
        end_idx = content.find('---', 3)
        if end_idx != -1:
            content = content[end_idx + 3:].strip()
            
    # Parse footnotes first
    content, footnotes = parse_footnotes(content)
    
    # Split content into blocks
    raw_blocks = content.split('\n\n')
    blocks = []
    for b in raw_blocks:
        b = b.strip()
        if b:
            blocks.append(b)
            
    latex_blocks = []
    subsec_num = starting_subsection
    para_idx = 0
    pending_caption = None   # nearest preceding "**Table N: ...**" line

    def emit_paragraph(text, idx):
        """Emits a lettered paragraph and returns the next index."""
        latex_blocks.append(f"\\paragraph{{{index_to_letters(idx)}}}\n{clean_formatting(text, footnotes)}")
        return idx + 1

    def split_heading(block, marker_len):
        """
        Returns (heading_line, remainder). Markdown headings are single lines, but
        drafts sometimes omit the blank line after them, which used to swallow the
        entire following paragraph -- and in one case a display equation -- into the
        \\paragraph{} title argument.
        """
        lines = block.split('\n', 1)
        head = lines[0][marker_len:].strip()
        rest = lines[1].strip() if len(lines) > 1 else ''
        return head, rest

    for block in blocks:
        # Table include directive: <!-- TABLE: reports/<folder>/<fragment>.tex -->
        # The binding estimates live in reports/ and are the single source of truth;
        # they are \input, never transcribed.
        m_tab = re.match(r'^<!--\s*TABLE:\s*(.+?)\s*-->$', block.strip())
        if m_tab:
            latex_blocks.append(f"\\input{{{resolve_asset_path(m_tab.group(1))}}}")
            pending_caption = None
            continue

        # Check if block is a heading
        if block.startswith('# '):
            # Section header
            h_text = block[2:].strip()
            h_title = re.sub(r'^Section\s+[0-9.]+\s*[:\s]*-?\s*', '', h_text).strip()
            h_title = strip_manual_number(h_title)
            h_title = re.sub(r'^Empirical\s+Narrative\s+Synthesis\s*[:\s]*-?\s*', '', h_title).strip()
            h_title = re.sub(r'^Econometric\s+Adjudication\s*[:\s]*-?\s*', '', h_title).strip()
            
            if shift_headers:
                latex_blocks.append(f"\\subsection{{{clean_formatting(h_title, {})}}}")
            else:
                latex_blocks.append(f"\\section{{{clean_formatting(h_title, {})}}}")
                
            subsec_num = 0
            para_idx = 0
            continue
            
        elif block.startswith('## '):
            # Subsection header
            h_title, rest = split_heading(block, 3)
            h_title = strip_manual_number(h_title)

            if shift_headers:
                latex_blocks.append(f"\\subsubsection{{{clean_formatting(h_title, {})}}}")
            else:
                latex_blocks.append(f"\\subsection{{{clean_formatting(h_title, {})}}}")

            subsec_num += 1
            para_idx = 0
            if rest:
                para_idx = emit_paragraph(rest, para_idx)
            continue

        elif block.startswith('### '):
            h_title, rest = split_heading(block, 4)
            h_title = strip_manual_number(h_title)

            if shift_headers:
                # Already three levels deep (section -> subsection -> subsubsection), so
                # \paragraph is the only slot left -- and AGENTS.md reserves \paragraph
                # titles for the uppercase-letter counter alone. Emitting the heading text
                # there produced "\paragraph{A. The Fordist Era...}", which both occupies a
                # letter slot and repeats a manual letter. Render it as a bold run-in under
                # a properly lettered paragraph instead.
                h_title = re.sub(r'^[A-Z0-9.]+\s+', '', h_title).strip()
                latex_blocks.append(
                    f"\\paragraph{{{index_to_letters(para_idx)}}}\n"
                    f"\\textbf{{{clean_formatting(h_title, {})}}}"
                    + (f"\n{clean_formatting(rest, footnotes)}" if rest else "")
                )
                para_idx += 1
            else:
                latex_blocks.append(f"\\subsubsection{{{clean_formatting(h_title, {})}}}")
                para_idx = 0   # Reset paragraph count at start of subsubsection
                if rest:
                    para_idx = emit_paragraph(rest, para_idx)
            continue

        elif block.startswith('#'):
            # H4 or lower heading - bold lead-in paragraph under a lettered heading.
            # Only the heading line becomes the lead-in; anything after it is its own
            # paragraph, so the AGENTS.md uppercase-letter convention is preserved and
            # body text never lands inside a \paragraph{} argument.
            first, rest = split_heading(block, 0)
            h_text = re.sub(r'^#+\s*', '', first).strip()
            h_title = re.sub(r'^[A-Z0-9.]+\s*', '', h_text).strip()
            latex_blocks.append(
                f"\\paragraph{{{index_to_letters(para_idx)}}}\n"
                f"\\textbf{{{clean_formatting(h_title, {})}}}"
                + (f"\n{clean_formatting(rest, footnotes)}" if rest else "")
            )
            para_idx += 1
            continue

        elif block.startswith('!['):
            # Markdown image figure. The optional markdown title slot carries an explicit
            # cross-reference key:  ![Caption](path "fig:my_key")
            # Without a key the label is derived from the caption, which is fine for
            # figures nothing refers to but fragile for figures the prose cites.
            m = re.match(r'!\[([^\]]*)\]\(\s*([^)\s"]+)(?:\s+"([^"]*)")?\s*\)', block.strip())
            if m:
                caption, img_path, key = m.group(1), m.group(2), m.group(3)
                # A manual "Figure N:" prefix fights LaTeX's own counter; drop it.
                caption = re.sub(r'^Figure\s+[0-9A-Z.]+\s*[:.]\s*', '', caption).strip()
                label = key if key else f"fig:{slugify_label(caption)[4:]}"
                latex_blocks.append(
                    "\\begin{figure}[H]\n"
                    "\\centering\n"
                    f"\\caption{{{clean_formatting(caption, {})}}}\n"
                    f"\\label{{{label}}}\n"
                    f"\\includegraphics[width=0.85\\textwidth]{{{resolve_asset_path(img_path)}}}\n"
                    "\\end{figure}"
                )
                continue

        elif block.startswith('|') and '|' in block:
            # Markdown table
            latex_blocks.append(parse_markdown_table(block, footnotes, pending_caption))
            pending_caption = None
            continue

        elif block.startswith('$$') or block.startswith('\\['):
            # Math block
            latex_blocks.append(clean_formatting(block, footnotes))
            continue

        elif re.search(r'^\s*(?:[-*]\s|\d+\.\s)', block, re.MULTILINE):
            # List block, possibly introduced by a lead-in sentence in the same block.
            # Detecting only on block.startswith() left lists like "We eliminate:\n* ..."
            # as literal bullet characters in running text.
            lead_in, items, is_ordered = [], [], False
            for line in block.split('\n'):
                line = line.strip()
                if not line:
                    continue
                m_item = re.match(r'^(?:([-*])|(\d+)\.)\s+(.*)$', line)
                if m_item:
                    if not items and m_item.group(2):
                        is_ordered = True
                    items.append(m_item.group(3).strip())
                elif items:
                    items[-1] += ' ' + line     # continuation of the previous item
                else:
                    lead_in.append(line)

            if lead_in:
                para_idx = emit_paragraph(' '.join(lead_in), para_idx)

            env_name = "enumerate" if is_ordered else "itemize"
            list_lines = [f"\\begin{{{env_name}}}"]
            for item in items:
                list_lines.append(f"  \\item {clean_formatting(item, footnotes)}")
            list_lines.append(f"\\end{{{env_name}}}")
            latex_blocks.append("\n".join(list_lines))
            continue

        # A standalone "**Table N: ...**" line captions the table that follows.
        m_cap = re.match(r'^\*\*(Table\s+[^*]+?)\*\*$', block.strip())
        if m_cap:
            pending_caption = re.sub(r'^Table\s+[0-9A-Z.]+\s*[:.]\s*', '', m_cap.group(1)).strip()
            continue

        # Regular text paragraph - letter ordering only
        para_idx = emit_paragraph(block, para_idx)

    return "\n\n".join(latex_blocks), subsec_num

def main():
    repo_root = Path(__file__).resolve().parent.parent.parent
    drafts_dir = repo_root / "chapter2_vault" / "06_paper_facing" / "drafts"
    output_dir = Path(__file__).resolve().parent
    
    print(f"Reading drafts from: {drafts_dir}")
    print(f"Writing LaTeX sections to: {output_dir}")
    
    # ── SECTION 1 ──
    sec1_md = drafts_dir / "ch2_sec1_intro.md"
    if sec1_md.exists():
        content = sec1_md.read_text(encoding='utf-8')
        latex, _ = process_file_content(content, section_num=1)
        (output_dir / "section1.tex").write_text(latex, encoding='utf-8')
        print("  Generated section1.tex")
        
    # ── SECTION 2 ──
    sec2_md = drafts_dir / "ch2_sec2_theoretical_foundations_prelatex.md"
    if sec2_md.exists():
        content = sec2_md.read_text(encoding='utf-8')
        latex, _ = process_file_content(content, section_num=2)
        (output_dir / "section2.tex").write_text(latex, encoding='utf-8')
        print("  Generated section2.tex")
        
    # ── SECTION 3 (Combine 3.1, 3.2, 3.3) ──
    sec3_files = [
        drafts_dir / "ch2_sec3_1_baseline_homogeneous_prelatex.md",
        drafts_dir / "ch2_sec3_2_heterogeneous_capital_prelatex.md",
        drafts_dir / "ch2_sec3_3_peripheral_extension_prelatex.md"
    ]
    sec3_latex = ["\\section{The Hinge Object: $\\theta$ and the Conceptual Framework}"]
    curr_subsec = 0
    for idx, f in enumerate(sec3_files):
        if f.exists():
            content = f.read_text(encoding='utf-8')
            latex, curr_subsec = process_file_content(content, section_num=3, starting_subsection=curr_subsec, shift_headers=True)
            sec3_latex.append(latex)
            
    (output_dir / "section3.tex").write_text("\n\n".join(sec3_latex), encoding='utf-8')
    print("  Generated section3.tex")
    
    # ── SECTION 4 (Combine Data, Specs A/B/C) ──
    sec4_files = [
        drafts_dir / "ch2_sec4_1_data_measurement_prelatex.md",
        drafts_dir / "ch2_sec4_2_baseline_spec_US" / "ch2_sec4_2_1.md",
        drafts_dir / "ch2_sec4_2_baseline_spec_US" / "ch2_sec4_2_2.md",
        drafts_dir / "ch2_sec4_2_baseline_spec_US" / "ch2_sec4_2_3.md",
        drafts_dir / "ch2_sec4_3_heterogeneous_capital_US" / "ch2_sec4_3_1.md",
        drafts_dir / "ch2_sec4_3_heterogeneous_capital_US" / "ch2_sec4_3_2.md",
        drafts_dir / "ch2_sec4_3_heterogeneous_capital_US" / "ch2_sec4_3_3.md",
        drafts_dir / "ch2_sec4_4_peripheral_econometrics_prelatex.md"
    ]
    sec4_latex = ["\\section{Empirical Strategy and Narrative Synthesis}"]
    curr_subsec = 0
    for f in sec4_files:
        if f.exists():
            content = f.read_text(encoding='utf-8')
            latex, curr_subsec = process_file_content(content, section_num=4, starting_subsection=curr_subsec, shift_headers=True)
            sec4_latex.append(latex)
            
    (output_dir / "section4.tex").write_text("\n\n".join(sec4_latex), encoding='utf-8')
    print("  Generated section4.tex")
    
    # ── SECTION 5 (Comparative Determination) ──
    sec5_md = drafts_dir / "ch2_sec5_comparative_determination_prelatex.md"
    if sec5_md.exists():
        content = sec5_md.read_text(encoding='utf-8')
        latex, _ = process_file_content(content, section_num=5)
        (output_dir / "section5.tex").write_text(latex, encoding='utf-8')
        print("  Generated section5.tex")

    # ── SECTION 6 (Bounded Conclusion) ──
    sec6_md = drafts_dir / "ch2_sec6_bounded_conclusion_prelatex.md"
    if sec6_md.exists():
        content = sec6_md.read_text(encoding='utf-8')
        latex, _ = process_file_content(content, section_num=6)
        (output_dir / "section6.tex").write_text(latex, encoding='utf-8')
        print("  Generated section6.tex")

    # ── APPENDICES ──
    # The \section is no longer stripped. Stripping it left the appendix untitled and
    # its subsubsections orphaned under section 6 in the PDF outline.
    appendices = [
        ("appendix_prelatex.md", "appendixA.tex"),
        ("appendixB_data_construction.md", "appendixB.tex"),
        ("appendixC_permutation_space.md", "appendixC.tex"),
        ("appendixD_cointegration_triad.md", "appendixD.tex"),
        ("appendixE_parameter_stability.md", "appendixE.tex"),
    ]
    for src_name, out_name in appendices:
        app_md = drafts_dir / src_name
        if app_md.exists():
            content = app_md.read_text(encoding='utf-8')
            latex, _ = process_file_content(content, section_num=7)
            (output_dir / out_name).write_text(latex.strip(), encoding='utf-8')
            print(f"  Generated {out_name}")

if __name__ == '__main__':
    main()
