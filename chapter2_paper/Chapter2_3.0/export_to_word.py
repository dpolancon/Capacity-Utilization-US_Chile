"""
export_to_word.py
-----------------
Converts the LaTeX manuscript for Chapter 2 into a high-fidelity Microsoft Word (.docx)
document that visually mirrors the compiled PDF (Chapter2_V3.0.pdf).

Key Visual Fidelity Features:
- Native Microsoft Word OMML equations using latex2word
- True native bottom-of-page Word Footnotes (injected via OpenXML footnotes.xml)
- Hierarchical section, subsection, and subsubsection numbering matching the PDF
- Two-pass cross-reference resolver for all Table, Figure, Section, and Equation labels
- Centered display equations with flush-right equation numbering (1), (2)...
- Inline bold paragraph lead-ins (e.g. "**Title.** Paragraph body...") avoiding spoiler headings
- Strict line spacing (1.15) and consistent paragraph spacing (6pt after, 0pt before)
- Academic booktabs table formatting with shaded repeating headers, cantSplit rows, and bottom notes
- Sequentially numbered Figure and Table captions (Figure 1, Table 1, ...)
- Title page with Abstract banner, Keywords, JEL codes, and Word dynamic Table of Contents field
- Full References section from main.bbl with 0.5-inch hanging indent
"""

import os
import re
import sys
import shutil
import zipfile
from pathlib import Path

import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import qn, nsdecls

from latex2word import LatexToWordElement


# ==============================================================================
# 1. NOTATION MACROS AND PREPROCESSING
# ==============================================================================

NOTATION_MACROS = {
    r'\mut': r'\mu_t',
    r'\chit': r'\chi_t',
    r'\kapt': r'\kappa_t',
    r'\knrc': r'k^{\text{NRC}}',
    r'\kme': r'k^{\text{ME}}',
    r'\Ypot': r'Y^{p}',
    r'\mech': r'q',
    r'\pkap': r'p_t^{\kappa}',
    r'\impint': r'\nu',
    r'\deprec': r'\delta',
    r'\discard': r'z',
    r'\stepD': r'\boldsymbol{\gamma}^\prime\mathbf{D}_t',
    r'\stepDsys': r'\boldsymbol{\Gamma}\mathbf{D}_t',
    r'\MPF': r'Mechanization Productive Frontier',
}

def expand_macros(text: str) -> str:
    for macro, repl in NOTATION_MACROS.items():
        text = text.replace(macro, repl)
    return text


# ==============================================================================
# 2. BIBLIOGRAPHY & CITATION ENGINE
# ==============================================================================

class BibliographyEngine:
    def __init__(self, bbl_path: str, bib_path: str = None):
        self.entries = {}
        self.load_bbl(bbl_path)
        if bib_path and os.path.exists(bib_path):
            self.load_bib_fallback(bib_path)

    def load_bbl(self, bbl_path: str):
        if not os.path.exists(bbl_path):
            return
        with open(bbl_path, 'r', encoding='utf-8') as f:
            content = f.read()

        pattern = re.compile(
            r'\\bibitem\[(.*?)\]\{(.*?)\}(.*?)(?=\\bibitem|\\end\{thebibliography\}|$)',
            re.DOTALL
        )
        for disp, key, text in pattern.findall(content):
            key = key.strip()
            disp = disp.strip()
            disp_clean = disp.replace('~', ' ')
            
            year_match = re.search(r'(\d{4}[a-z]?)', disp_clean)
            year = year_match.group(1) if year_match else ""
            author = re.sub(r'[,~]?\s*\d{4}[a-z]?', '', disp_clean).strip()
            
            cleaned_entry = self.clean_bib_text(text)
            self.entries[key] = {
                'display': disp_clean,
                'author': author,
                'year': year,
                'full_text': cleaned_entry
            }

    def load_bib_fallback(self, bib_path: str):
        with open(bib_path, 'r', encoding='utf-8') as f:
            content = f.read()
        entries = re.split(r'@\w+\s*\{', content)
        for block in entries[1:]:
            parts = block.split(',', 1)
            if len(parts) < 2:
                continue
            key = parts[0].strip()
            if key not in self.entries:
                author_m = re.search(r'author\s*=\s*\{([^}]+)\}', parts[1], re.IGNORECASE)
                year_m = re.search(r'year\s*=\s*\{?(\d{4})\}?', parts[1], re.IGNORECASE)
                title_m = re.search(r'title\s*=\s*\{([^}]+)\}', parts[1], re.IGNORECASE)
                
                auth = author_m.group(1) if author_m else key
                auth_short = auth.split(' and ')[0].split(',')[0].strip()
                yr = year_m.group(1) if year_m else "n.d."
                self.entries[key] = {
                    'display': f"{auth_short}, {yr}",
                    'author': auth_short,
                    'year': yr,
                    'full_text': f"{auth} ({yr}). {title_m.group(1) if title_m else ''}."
                }

    def clean_bib_text(self, text: str) -> str:
        t = text.strip()
        t = re.sub(r'\\newblock', ' ', t)
        t = re.sub(r'\\em(?:ph)?\s*\{([^}]+)\}', r'\1', t)
        t = re.sub(r'\{\\em\s+([^}]+)\}', r'\1', t)
        t = re.sub(r'\\textit\{([^}]+)\}', r'\1', t)
        t = re.sub(r'\\textbf\{([^}]+)\}', r'\1', t)
        t = re.sub(r'\\url\{([^}]+)\}', r'\1', t)
        t = re.sub(r'\\href\{[^}]+\}\{([^}]+)\}', r'\1', t)
        t = re.sub(r'\\&', '&', t)
        t = re.sub(r'\\%', '%', t)
        t = re.sub(r'\\_', '_', t)
        t = re.sub(r'[\{\}]', '', t)
        t = re.sub(r'\s+', ' ', t)
        t = t.replace('~', ' ')
        return t.strip()

    def format_citation(self, cite_cmd: str, cite_args: str, cite_opts: str = "") -> str:
        keys = [k.strip() for k in cite_args.split(',') if k.strip()]
        if not keys:
            return ""

        prefix = ""
        suffix = ""
        opt_matches = re.findall(r'\[(.*?)\]', cite_opts)
        if len(opt_matches) == 1:
            suffix = opt_matches[0].strip()
        elif len(opt_matches) >= 2:
            prefix = opt_matches[0].strip()
            suffix = opt_matches[1].strip()

        if cite_cmd in ('citep', 'cite', 'citealp'):
            items = []
            for k in keys:
                if k in self.entries:
                    items.append(self.entries[k]['display'])
                else:
                    items.append(k)
            inner = "; ".join(items)
            if prefix and suffix:
                res = f"{prefix} {inner}, {suffix}"
            elif prefix:
                res = f"{prefix} {inner}"
            elif suffix:
                res = f"{inner}, {suffix}"
            else:
                res = inner
            return f"({res})" if cite_cmd != 'citealp' else res

        elif cite_cmd in ('citet', 'citealt'):
            items = []
            for k in keys:
                if k in self.entries:
                    auth = self.entries[k]['author']
                    yr = self.entries[k]['year']
                    if suffix:
                        items.append(f"{auth} ({yr}, {suffix})")
                    else:
                        items.append(f"{auth} ({yr})")
                else:
                    items.append(f"{k}")
            return " and ".join(items)

        elif cite_cmd == 'citeyear':
            yrs = [self.entries[k]['year'] if k in self.entries else k for k in keys]
            return ", ".join(yrs)

        elif cite_cmd == 'citeyearpar':
            yrs = [self.entries[k]['year'] if k in self.entries else k for k in keys]
            return f"({', '.join(yrs)})"

        return f"({', '.join(keys)})"


# ==============================================================================
# 3. LABEL PRE-SCANNER (CROSS-REFERENCE RESOLVER)
# ==============================================================================

def prescan_labels(base_dir: Path):
    """
    Scans all LaTeX files and builds an exact label -> number/title mapping
    so that \\ref, \\eqref, \\cref resolve directly to Figure N, Table N, Section N, (N).
    """
    label_map = {}
    
    section_files = [base_dir / f"section{i}.tex" for i in range(1, 7)]
    appendix_files = [base_dir / f"appendix{c}.tex" for c in 'ABCDEF']
    all_files = section_files + appendix_files

    sec_cnt = 0
    subsec_cnt = 0
    subsubsec_cnt = 0
    fig_cnt = 0
    tab_cnt = 0
    eq_cnt = 0

    for tf in all_files:
        if not tf.exists():
            continue
        content = tf.read_text(encoding='utf-8')
        is_app = 'appendix' in tf.name
        app_letter = tf.name.replace('appendix', '').replace('.tex', '') if is_app else ""

        # Tokenize by structural commands to track counters
        pattern = re.compile(
            r'('
            r'\\section\*?\{[^}]+\}|'
            r'\\subsection\*?\{[^}]+\}|'
            r'\\subsubsection\*?\{[^}]+\}|'
            r'\\begin\{figure\}.*?\\end\{figure\}|'
            r'\\begin\{table\}.*?\\end\{table\}|'
            r'\\input\{tables/[^}]+\}|'
            r'\\begin\{(?:equation|align|gather)\*?\}.*?\\end\{(?:equation|align|gather)\*?\}|'
            r'\\\[.*?\\\]'
            r')',
            re.DOTALL
        )

        for block in pattern.findall(content):
            # Section
            if block.startswith(r'\section'):
                if not is_app:
                    sec_cnt += 1
                    subsec_cnt = 0
                    subsubsec_cnt = 0
                    cur_sec_str = f"Section {sec_cnt}"
                else:
                    subsec_cnt = 0
                    subsubsec_cnt = 0
                    cur_sec_str = f"Appendix {app_letter}"
                # Check label immediately following
                lbl_m = re.search(r'\\label\{([^}]+)\}', block)
                if lbl_m:
                    label_map[lbl_m.group(1)] = cur_sec_str

            elif block.startswith(r'\subsection'):
                subsec_cnt += 1
                subsubsec_cnt = 0
                cur_sub_str = f"{sec_cnt}.{subsec_cnt}" if not is_app else f"{app_letter}.{subsec_cnt}"
                lbl_m = re.search(r'\\label\{([^}]+)\}', block)
                if lbl_m:
                    label_map[lbl_m.group(1)] = f"Section {cur_sub_str}"

            elif block.startswith(r'\subsubsection'):
                subsubsec_cnt += 1
                cur_subsub_str = f"{sec_cnt}.{subsec_cnt}.{subsubsec_cnt}" if not is_app else f"{app_letter}.{subsec_cnt}.{subsubsec_cnt}"
                lbl_m = re.search(r'\\label\{([^}]+)\}', block)
                if lbl_m:
                    label_map[lbl_m.group(1)] = f"Section {cur_subsub_str}"

            elif block.startswith(r'\begin{figure}'):
                fig_cnt += 1
                lbl_m = re.search(r'\\label\{([^}]+)\}', block)
                if lbl_m:
                    label_map[lbl_m.group(1)] = f"Figure {fig_cnt}"

            elif block.startswith(r'\begin{table}'):
                tab_cnt += 1
                lbl_m = re.search(r'\\label\{([^}]+)\}', block)
                if lbl_m:
                    label_map[lbl_m.group(1)] = f"Table {tab_cnt}"

            elif block.startswith(r'\input{tables/'):
                m_t = re.match(r'\\input\{(tables/[^}]+)\}', block)
                if m_t:
                    t_path = base_dir / m_t.group(1)
                    if not t_path.suffix:
                        t_path = t_path.with_suffix('.tex')
                    if t_path.exists():
                        t_str = t_path.read_text(encoding='utf-8')
                        tab_cnt += 1
                        lbl_m = re.search(r'\\label\{([^}]+)\}', t_str)
                        if lbl_m:
                            label_map[lbl_m.group(1)] = f"Table {tab_cnt}"

            elif block.startswith(r'\begin{equation') or block.startswith(r'\begin{align') or block.startswith(r'\begin{gather'):
                if '*' not in block:
                    eq_cnt += 1
                    lbl_m = re.search(r'\\label\{([^}]+)\}', block)
                    if lbl_m:
                        label_map[lbl_m.group(1)] = f"({eq_cnt})"

        # Also search remaining label occurrences in text (e.g. \label right after \section)
        for lbl_m in re.finditer(r'\\label\{([^}]+)\}', content):
            k = lbl_m.group(1)
            if k not in label_map:
                if k.startswith('sec:'):
                    label_map[k] = f"Section"
                elif k.startswith('tab:'):
                    label_map[k] = f"Table"
                elif k.startswith('fig:'):
                    label_map[k] = f"Figure"
                elif k.startswith('eq:'):
                    label_map[k] = f"Equation"

    return label_map


# ==============================================================================
# 4. MATH CLEANING AND EQUATION CONVERTER
# ==============================================================================

def clean_math_string(latex_math: str) -> str:
    m = latex_math.strip()
    m = re.sub(r'\\label\{[^}]+\}', '', m).strip()
    m = re.sub(r'\\underbrace\{([^}]+)\}_\{([^}]+)\}', r'(\1)_{\\text{\2}}', m)
    m = re.sub(r'\\underbrace\{([^}]+)\}', r'(\1)', m)
    m = re.sub(r'\\overbrace\{([^}]+)\}\^\{([^}]+)\}', r'(\1)^{\\text{\2}}', m)
    m = re.sub(r'\\overbrace\{([^}]+)\}', r'(\1)', m)
    m = m.replace(r'\left.', '').replace(r'\right.', '')
    m = re.sub(r'\\(?:q?quad|;|:|,)', ' ', m)
    m = re.sub(r'\\textbf\{([^}]+)\}', r'\\mathbf{\1}', m)
    return m.strip()


def safe_convert_math(latex_math: str):
    m_clean = clean_math_string(latex_math)
    if not m_clean:
        return None
    try:
        elt = LatexToWordElement(m_clean)
        return elt.element()
    except Exception:
        try:
            m_simple = m_clean.replace('&', '').replace(r'\\', ' ')
            elt = LatexToWordElement(m_simple)
            return elt.element()
        except Exception:
            return None


# ==============================================================================
# 5. WORD DOCUMENT STYLING AND XML HELPERS
# ==============================================================================

def configure_document_styles(doc: Document):
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.page_width = Inches(8.5)
        section.page_height = Inches(11.0)
        
        footer = section.footer
        p_ft = footer.paragraphs[0]
        p_ft.alignment = WD_ALIGN_PARAGRAPH.CENTER
        w_ns = nsdecls('w')
        p_ft._element.append(parse_xml(f'<w:fldSimple {w_ns} w:instr="PAGE"/>'))

    normal_style = doc.styles['Normal']
    normal_font = normal_style.font
    normal_font.name = 'Times New Roman'
    normal_font.size = Pt(11)
    normal_font.color.rgb = RGBColor(0x22, 0x22, 0x22)
    normal_style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.MULTIPLE
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(6)
    normal_style.paragraph_format.space_before = Pt(0)

    h1 = doc.styles['Heading 1']
    h1.font.name = 'Times New Roman'
    h1.font.size = Pt(15)
    h1.font.bold = True
    h1.font.color.rgb = RGBColor(0x11, 0x11, 0x11)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)
    h1.paragraph_format.keep_with_next = True

    h2 = doc.styles['Heading 2']
    h2.font.name = 'Times New Roman'
    h2.font.size = Pt(13)
    h2.font.bold = True
    h2.font.color.rgb = RGBColor(0x22, 0x22, 0x22)
    h2.paragraph_format.space_before = Pt(10)
    h2.paragraph_format.space_after = Pt(4)
    h2.paragraph_format.keep_with_next = True

    h3 = doc.styles['Heading 3']
    h3.font.name = 'Times New Roman'
    h3.font.size = Pt(11.5)
    h3.font.bold = True
    h3.font.italic = True
    h3.font.color.rgb = RGBColor(0x33, 0x33, 0x33)
    h3.paragraph_format.space_before = Pt(8)
    h3.paragraph_format.space_after = Pt(2)
    h3.paragraph_format.keep_with_next = True


def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._element.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)


def set_cell_shading(cell, color_hex="F4F4F4"):
    tcPr = cell._element.get_or_add_tcPr()
    w_ns = nsdecls('w')
    shd = parse_xml(f'<w:shd {w_ns} w:val="clear" w:color="auto" w:fill="{color_hex}"/>')
    tcPr.append(shd)


def set_table_horizontal_borders(table):
    tblPr = table._element.xpath('w:tblPr')
    if tblPr:
        w_ns = nsdecls('w')
        borders = parse_xml(
            f'<w:tblBorders {w_ns}>\n'
            f'  <w:top w:val="single" w:sz="8" w:space="0" w:color="333333"/>\n'
            f'  <w:bottom w:val="single" w:sz="8" w:space="0" w:color="333333"/>\n'
            f'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/>\n'
            f'  <w:insideV w:val="none"/>\n'
            f'  <w:left w:val="none"/>\n'
            f'  <w:right w:val="none"/>\n'
            f'</w:tblBorders>'
        )
        tblPr[0].append(borders)


# ==============================================================================
# 6. TEXT PARSER AND RUN FORMATTER
# ==============================================================================

def unicode_math_fallback(tex_str: str) -> str:
    t = tex_str
    replacements = [
        (r'\theta', 'θ'), (r'\mu', 'μ'), (r'\kappa', 'κ'), (r'\omega', 'ω'),
        (r'\iota', 'ι'), (r'\gamma', 'γ'), (r'\alpha', 'α'), (r'\beta', 'β'),
        (r'\delta', 'δ'), (r'\nu', 'ν'), (r'\chi', 'χ'), (r'\lambda', 'λ'),
        (r'\sigma', 'σ'), (r'\Delta', 'Δ'), (r'\Gamma', 'Γ'), (r'\Psi', 'Ψ'),
        (r'\Phi', 'Φ'), (r'\approx', '≈'), (r'\le', '≤'), (r'\ge', '≥'),
        (r'\equiv', '≡'), (r'\times', '×'), (r'\pm', '±'), (r'\to', '→'),
        (r'\in', '∈'), (r'\partial', '∂'), (r'\sum', '∑'), (r'\int', '∫'),
        (r'\infty', '∞'), (r'\hat{\theta}', 'θ̂'), (r'\hat{\gamma}', 'γ̂'),
        (r'\bar{\kappa}', 'κ̄'), (r'\bar{\omega}', 'ω̄'), (r'\bar{\tau}', 'τ̄'),
        (r'\text{ME}', 'ME'), (r'\text{NRC}', 'NRC'), (r'\text{NFC}', 'NFC'),
        (r'\text{GVA}', 'GVA'), (r'\text{NVA}', 'NVA'), (r'\text{cap}', 'cap'),
        (r'\text{gross}', 'gross'), (r'\text{net}', 'net'), (r'\text{slack}', 'slack'),
        (r'\text{bind}', 'bind'), (r'\_', '_'), (r'\%', '%'), (r'\&', '&'),
    ]
    for k, v in replacements:
        t = t.replace(k, v)
    t = re.sub(r'[\{\}\$]', '', t)
    return t


def add_formatted_text_to_paragraph(paragraph, text: str, bib_engine: BibliographyEngine, footnotes_list: list = None, label_map: dict = None):
    text = expand_macros(text)

    # 1. Extract footnotes and record for native injection
    def extract_footnote(m):
        fn_content = m.group(1).strip()
        if footnotes_list is not None:
            fn_idx = len(footnotes_list) + 1
            fn_clean = unicode_math_fallback(clean_raw_text(fn_content))
            footnotes_list.append((fn_idx, fn_clean))
            return f" [NATIVEFOOTNOTE_{fn_idx}]"
        return ""

    text = re.sub(r'\\footnote\{((?:[^{}]|{[^{}]*})*)\}', extract_footnote, text)

    # 2. Process citations
    cite_pattern = re.compile(r'\\(citep|citet|citealp|citealt|citeyear|citeyearpar|cite)(\[[^\]]*\])?(\[[^\]]*\])?\{([^}]+)\}')
    def replace_citation(m):
        cmd = m.group(1)
        opt1 = m.group(2) or ""
        opt2 = m.group(3) or ""
        opts = opt1 + opt2
        keys = m.group(4)
        return bib_engine.format_citation(cmd, keys, opts)

    text = cite_pattern.sub(replace_citation, text)

    # 3. Process cross-references using pre-scanned label map
    def resolve_ref(m):
        cmd = m.group(1)
        ref_key = m.group(2).strip()
        if label_map and ref_key in label_map:
            val = label_map[ref_key]
            # If command was \eqref, ensure parentheses format
            if cmd == 'eqref':
                return val if val.startswith('(') else f"({val})"
            # If text had "Table~\ref{tab:xxx}", resolve cleanly
            return val.replace('Table ', '').replace('Figure ', '').replace('Section ', '')
        return ref_key

    # Handle "Table~\ref{...}" or "Figure~\ref{...}"
    text = re.sub(r'(?:Table|Figure|Section|Equation)~\s*\\(?:ref|cref|Cref)\{([^}]+)\}', lambda m: label_map.get(m.group(1), m.group(1)) if label_map else m.group(1), text)
    text = re.sub(r'\\(eqref|cref|Cref|ref)\{([^}]+)\}', resolve_ref, text)

    # 4. Tokenize text into segments
    token_pattern = re.compile(
        r'('
        r'\$(?:[^\$]|\\\$)+\$|'
        r'\\textbf\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|'
        r'\\textit\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|'
        r'\\emph\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|'
        r'\\texttt\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|'
        r'\[NATIVEFOOTNOTE_\d+\]'
        r')',
        re.DOTALL
    )

    parts = token_pattern.split(text)
    for part in parts:
        if not part:
            continue

        # Inline math
        if part.startswith('$') and part.endswith('$') and len(part) >= 2:
            math_content = part[1:-1].strip()
            math_elt = safe_convert_math(math_content)
            if math_elt is not None:
                paragraph._element.append(math_elt)
            else:
                run = paragraph.add_run(unicode_math_fallback(math_content))
                run.italic = True

        # Bold
        elif part.startswith(r'\textbf{') and part.endswith('}'):
            inner = part[8:-1]
            run = paragraph.add_run(clean_raw_text(inner))
            run.bold = True

        # Italic / Emph
        elif (part.startswith(r'\textit{') or part.startswith(r'\emph{')) and part.endswith('}'):
            inner = part[8:-1] if part.startswith(r'\textit{') else part[6:-1]
            run = paragraph.add_run(clean_raw_text(inner))
            run.italic = True

        # Monospace / Teletype
        elif part.startswith(r'\texttt{') and part.endswith('}'):
            inner = part[8:-1]
            run = paragraph.add_run(clean_raw_text(inner))
            run.font.name = 'Consolas'
            run.font.size = Pt(9.5)

        # Native Footnote Marker
        elif re.match(r'\[NATIVEFOOTNOTE_(\d+)\]', part):
            fn_num = re.match(r'\[NATIVEFOOTNOTE_(\d+)\]', part).group(1)
            w_ns = nsdecls('w')
            fn_ref_xml = parse_xml(f'<w:r {w_ns}><w:rPr><w:rStyle w:val="FootnoteReference"/></w:rPr><w:footnoteReference w:id="{fn_num}"/></w:r>')
            paragraph._element.append(fn_ref_xml)

        # Regular text
        else:
            cleaned = clean_raw_text(part)
            if cleaned:
                paragraph.add_run(cleaned)


def clean_raw_text(text: str) -> str:
    t = text
    t = t.replace(r'\%', '%')
    t = t.replace(r'\_', '_')
    t = t.replace(r'\&', '&')
    t = t.replace(r'\$', '$')
    t = t.replace(r'\{', '{')
    t = t.replace(r'\}', '}')
    t = t.replace(r'\#', '#')
    t = t.replace('---', '—')
    t = t.replace('--', '–')
    t = t.replace('``', '"').replace("''", '"')
    t = t.replace('~', ' ')
    t = re.sub(r'\\(?:noindent|pagebreak|newpage|FloatBarrier|clearpage)\s*', '', t)
    t = re.sub(r'\\label\{[^}]+\}', '', t)
    t = re.sub(r'\\par\b', ' ', t)
    return t


# ==============================================================================
# 7. TABLE PARSER & BUILDER
# ==============================================================================

def clean_cell_latex(cell_text: str) -> str:
    t = cell_text.strip()
    t = re.sub(r'\\textbf\s*\{([^}]+)\}', r'\1', t)
    t = re.sub(r'\\textit\s*\{([^}]+)\}', r'\1', t)
    t = re.sub(r'\\emph\s*\{([^}]+)\}', r'\1', t)
    t = re.sub(r'\\texttt\s*\{([^}]+)\}', r'\1', t)
    t = re.sub(r'\\textbf\b', '', t)
    t = re.sub(r'\\textit\b', '', t)
    t = re.sub(r'\\(?:tiny|small|footnotesize|scriptsize|large|Large)\b', '', t)
    t = unicode_math_fallback(t)
    t = clean_raw_text(t)
    return t.strip()


def extract_tabular_spec_and_body(tex: str):
    idx = tex.find(r'\begin{tabular}')
    if idx == -1:
        return None, None
    after = tex[idx + len(r'\begin{tabular}'):].strip()
    if not after.startswith('{'):
        return None, None
    depth = 0
    spec_end = -1
    for i, ch in enumerate(after):
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                spec_end = i
                break
    if spec_end == -1:
        return None, None
    spec = after[1:spec_end]
    body = after[spec_end + 1:]
    end_idx = body.find(r'\end{tabular}')
    if end_idx != -1:
        body = body[:end_idx]
    return spec, body


def parse_and_insert_table(doc: Document, table_tex: str, bib_engine: BibliographyEngine, table_counter: list):
    table_tex = expand_macros(table_tex)
    table_counter[0] += 1
    tbl_num = table_counter[0]

    # 1. Caption
    cap_match = re.search(r'\\caption\{([^}]+)\}', table_tex)
    caption_text = cap_match.group(1).strip() if cap_match else f"Table {tbl_num}"
    caption_text = clean_cell_latex(caption_text)
    caption_text = re.sub(r'^(?:Table\s+[0-9A-Z.]+|textbfTable\s+[0-9A-Z.]+)\s*[:.]\s*', '', caption_text).strip()

    cap_p = doc.add_paragraph()
    cap_p.paragraph_format.space_before = Pt(14)
    cap_p.paragraph_format.space_after = Pt(4)
    cap_p.paragraph_format.keep_with_next = True
    r_cap_lbl = cap_p.add_run(f"Table {tbl_num}: ")
    r_cap_lbl.bold = True
    r_cap_lbl.font.size = Pt(10.5)
    r_cap_txt = cap_p.add_run(caption_text)
    r_cap_txt.bold = True
    r_cap_txt.font.size = Pt(10.5)

    # 2. Notes
    note_text = ""
    n_m1 = re.search(r'\\begin\{minipage\}.*?\\(?:textit|textbf)\{Notes?:?\}(.*?)\\end\{minipage\}', table_tex, re.DOTALL)
    if n_m1:
        note_text = n_m1.group(1).strip()
    else:
        n_m2 = re.search(r'\\multicolumn\{\d+\}\{[^}]+\}\{\\footnotesize\s*\\textbf\{Note:\}\s*(.*?)\}', table_tex, re.DOTALL)
        if n_m2:
            note_text = n_m2.group(1).strip()
        else:
            n_m3 = re.search(r'\\textit\{Notes?:?\}(.*?)(?=\\end\{tabular\}|\\end\{table\}|$)', table_tex, re.DOTALL)
            if n_m3:
                note_text = n_m3.group(1).strip()

    note_text = clean_cell_latex(note_text)

    # 3. Tabular block
    col_spec, tab_body = extract_tabular_spec_and_body(table_tex)
    if tab_body is None:
        return

    tab_body = re.sub(r'\\(?:toprule|midrule|bottomrule|hline|hlinehline|hline\s*\\hline)', '', tab_body)
    tab_body = re.sub(r'\\cmidrule(\([^)]*\))?\{[^}]+\}', '', tab_body)
    tab_body = re.sub(r'\\multicolumn\{\d+\}\{[^}]+\}\{\\footnotesize\s*\\textbf\{Note:\}.*?\}', '', tab_body)

    raw_rows = tab_body.split(r'\\')
    table_data = []

    for r in raw_rows:
        r_str = r.strip()
        if not r_str:
            continue
        cells = r_str.split('&')
        row_cells = []
        for c in cells:
            c_str = c.strip()
            mc_match = re.search(r'\\multicolumn\{(\d+)\}\{[^}]+\}\{(.*?)\}', c_str)
            if mc_match:
                span_cnt = int(mc_match.group(1))
                span_txt = clean_cell_latex(mc_match.group(2))
                row_cells.append(span_txt)
                for _ in range(span_cnt - 1):
                    row_cells.append("")
            else:
                row_cells.append(clean_cell_latex(c_str))
        if any(row_cells):
            table_data.append(row_cells)

    if not table_data:
        return

    num_cols = max(len(r) for r in table_data)
    num_rows = len(table_data)

    t = doc.add_table(rows=num_rows, cols=num_cols)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_horizontal_borders(t)

    w_ns = nsdecls('w')

    for r_idx, row in enumerate(table_data):
        tr = t.rows[r_idx]._tr
        trPr = tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {w_ns}/>'))
        
        if r_idx == 0:
            trPr.append(parse_xml(f'<w:tblHeader {w_ns}/>'))

        for c_idx in range(num_cols):
            val = row[c_idx] if c_idx < len(row) else ""
            cell = t.cell(r_idx, c_idx)
            set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.line_spacing = 1.0
            
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(9.0)
            
            if r_idx == 0:
                set_cell_shading(cell, "F2F2F2")
                run.bold = True
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER if c_idx > 0 else WD_ALIGN_PARAGRAPH.LEFT
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.RIGHT if re.match(r'^-?[\d.,]+(\*\*\*)?$', val.strip()) else WD_ALIGN_PARAGRAPH.LEFT

    if note_text:
        note_p = doc.add_paragraph()
        note_p.paragraph_format.space_before = Pt(4)
        note_p.paragraph_format.space_after = Pt(12)
        r_lbl = note_p.add_run("Note: ")
        r_lbl.bold = True
        r_lbl.font.size = Pt(8.5)
        r_lbl.font.italic = True
        r_nt = note_p.add_run(note_text)
        r_nt.font.size = Pt(8.5)
        r_nt.font.italic = True
    else:
        spacer = doc.add_paragraph()
        spacer.paragraph_format.space_after = Pt(8)


# ==============================================================================
# 8. FIGURE PARSER & BUILDER
# ==============================================================================

def parse_and_insert_figure(doc: Document, fig_tex: str, base_dir: Path, fig_counter: list):
    fig_tex = expand_macros(fig_tex)
    fig_counter[0] += 1
    fig_num = fig_counter[0]

    cap_match = re.search(r'\\caption\{([^}]+)\}', fig_tex)
    caption_text = cap_match.group(1).strip() if cap_match else f"Figure {fig_num}"
    caption_text = clean_cell_latex(caption_text)
    caption_text = re.sub(r'^Figure\s+[0-9A-Z.]+\s*[:.]\s*', '', caption_text).strip()

    img_match = re.search(r'\\includegraphics(?:\[.*?\])?\{([^}]+)\}', fig_tex)
    if not img_match:
        return

    img_rel_path = img_match.group(1).strip()
    base_stem = os.path.splitext(img_rel_path)[0]
    png_path = base_dir / (base_stem + '.png')
    
    if not png_path.exists():
        png_path = base_dir / img_rel_path

    cap_p = doc.add_paragraph()
    cap_p.paragraph_format.space_before = Pt(14)
    cap_p.paragraph_format.space_after = Pt(4)
    cap_p.paragraph_format.keep_with_next = True
    cap_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_lbl = cap_p.add_run(f"Figure {fig_num}: ")
    r_lbl.bold = True
    r_lbl.font.size = Pt(10.5)
    r_txt = cap_p.add_run(caption_text)
    r_txt.bold = True
    r_txt.font.size = Pt(10.5)

    if png_path.exists() and png_path.suffix.lower() == '.png':
        img_p = doc.add_paragraph()
        img_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        img_p.paragraph_format.space_after = Pt(10)
        img_run = img_p.add_run()
        img_run.add_picture(str(png_path), width=Inches(6.2))
    else:
        ph_p = doc.add_paragraph(f"[Image: {img_rel_path}]")
        ph_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        ph_p.paragraph_format.space_after = Pt(8)


# ==============================================================================
# 9. SECTION CONTENT PROCESSOR
# ==============================================================================

def process_latex_content(
    doc: Document,
    content: str,
    base_dir: Path,
    bib_engine: BibliographyEngine,
    footnotes_list: list,
    counters: dict,
    label_map: dict,
    is_appendix: bool = False,
    appendix_letter: str = ""
):
    content = expand_macros(content)

    block_pattern = re.compile(
        r'('
        r'\\section\*?\{[^}]+\}|'
        r'\\subsection\*?\{[^}]+\}|'
        r'\\subsubsection\*?\{[^}]+\}|'
        r'\\paragraph\{[^}]+\}|'
        r'\\begin\{figure\}.*?\\end\{figure\}|'
        r'\\begin\{table\}.*?\\end\{table\}|'
        r'\\input\{tables/[^}]+\}|'
        r'\\begin\{(?:equation|align|gather)\*?\}.*?\\end\{(?:equation|align|gather)\*?\}|'
        r'\\\[.*?\\\]|'
        r'\\begin\{itemize\}.*?\\end\{itemize\}|'
        r'\\begin\{enumerate\}.*?\\end\{enumerate\}|'
        r'\\PLACEHOLDER\{[^}]+\}'
        r')',
        re.DOTALL
    )

    chunks = block_pattern.split(content)
    pending_lead_in = None

    for chunk in chunks:
        c = chunk.strip()
        if not c:
            continue

        # Headings
        if c.startswith(r'\section'):
            m = re.match(r'\\section\*?\{([^}]+)\}', c)
            if m:
                raw_title = clean_cell_latex(m.group(1))
                clean_title = re.sub(r'^(?:Section\s+[0-9.]+|Appendix\s+[A-Z]|Appendix:\s+|[0-9.]+\.?\s+)', '', raw_title).strip()
                clean_title = clean_title.lstrip('-: ').strip()
                
                if not is_appendix:
                    counters['section'] += 1
                    counters['subsection'] = 0
                    counters['subsubsection'] = 0
                    sec_title = f"{counters['section']}. {clean_title}"
                else:
                    counters['subsection'] = 0
                    counters['subsubsection'] = 0
                    sec_title = f"Appendix {appendix_letter}: {clean_title}"
                    
                doc.add_paragraph(sec_title, style='Heading 1')
                pending_lead_in = None
                continue

        elif c.startswith(r'\subsection'):
            m = re.match(r'\\subsection\*?\{([^}]+)\}', c)
            if m:
                raw_title = clean_cell_latex(m.group(1))
                clean_title = re.sub(r'^[A-Z0-9.]+\.?\s+', '', raw_title).strip()
                counters['subsection'] += 1
                counters['subsubsection'] = 0
                
                if not is_appendix:
                    subsec_title = f"{counters['section']}.{counters['subsection']} {clean_title}"
                else:
                    subsec_title = f"{appendix_letter}.{counters['subsection']} {clean_title}"
                    
                doc.add_paragraph(subsec_title, style='Heading 2')
                pending_lead_in = None
                continue

        elif c.startswith(r'\subsubsection'):
            m = re.match(r'\\subsubsection\*?\{([^}]+)\}', c)
            if m:
                raw_title = clean_cell_latex(m.group(1))
                clean_title = re.sub(r'^[A-Z0-9.]+\.?\s+', '', raw_title).strip()
                counters['subsubsection'] += 1
                
                if not is_appendix:
                    subsub_title = f"{counters['section']}.{counters['subsection']}.{counters['subsubsection']} {clean_title}"
                else:
                    subsub_title = f"{appendix_letter}.{counters['subsection']}.{counters['subsubsection']} {clean_title}"
                    
                doc.add_paragraph(subsub_title, style='Heading 3')
                pending_lead_in = None
                continue

        elif c.startswith(r'\paragraph'):
            m = re.match(r'\\paragraph\{([^}]+)\}', c)
            if m:
                para_arg = m.group(1).strip()
                # Omit pure letter scaffolding ([A], [B]) to prevent spoiler headers
                if re.match(r'^[A-Z]{1,2}$', para_arg):
                    pending_lead_in = None
                else:
                    clean_p_title = clean_cell_latex(para_arg)
                    pending_lead_in = f"{clean_p_title}. "
                continue

        # Figures
        elif c.startswith(r'\begin{figure}'):
            parse_and_insert_figure(doc, c, base_dir, counters['fig_counter'])
            pending_lead_in = None
            continue

        # Tables (Inline)
        elif c.startswith(r'\begin{table}'):
            parse_and_insert_table(doc, c, bib_engine, counters['table_counter'])
            pending_lead_in = None
            continue

        # Tables (Input)
        elif c.startswith(r'\input{tables/'):
            m = re.match(r'\\input\{(tables/[^}]+)\}', c)
            if m:
                tab_file = base_dir / m.group(1)
                if not tab_file.suffix:
                    tab_file = tab_file.with_suffix('.tex')
                if tab_file.exists():
                    table_content = tab_file.read_text(encoding='utf-8')
                    parse_and_insert_table(doc, table_content, bib_engine, counters['table_counter'])
            pending_lead_in = None
            continue

        # Display Equations with Right-Aligned Numbering
        elif c.startswith(r'\begin{equation') or c.startswith(r'\begin{align') or c.startswith(r'\begin{gather') or c.startswith(r'\['):
            math_body = c
            is_numbered = not ('*' in c or c.startswith(r'\['))
            math_body = re.sub(r'\\begin\{(?:equation|align|gather)\*?\}', '', math_body)
            math_body = re.sub(r'\\end\{(?:equation|align|gather)\*?\}', '', math_body)
            math_body = re.sub(r'^\\\[|\\\]$', '', math_body).strip()
            math_body = re.sub(r'\\label\{[^}]+\}', '', math_body).strip()

            eq_lines = [l.strip() for l in math_body.split(r'\\') if l.strip()]
            for idx, eq_line in enumerate(eq_lines):
                if is_numbered and idx == len(eq_lines) - 1:
                    counters['eq_counter'][0] += 1
                    eq_num_str = f"({counters['eq_counter'][0]})"
                else:
                    eq_num_str = ""

                eq_tbl = doc.add_table(rows=1, cols=2)
                eq_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
                eq_tbl.autofit = False
                
                c_eq = eq_tbl.cell(0, 0)
                c_eq.width = Inches(5.8)
                p_eq = c_eq.paragraphs[0]
                p_eq.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p_eq.paragraph_format.space_before = Pt(4)
                p_eq.paragraph_format.space_after = Pt(4)
                
                omml_elt = safe_convert_math(eq_line)
                if omml_elt is not None:
                    p_eq._element.append(omml_elt)
                else:
                    r_txt = p_eq.add_run(unicode_math_fallback(eq_line))
                    r_txt.italic = True
                    r_txt.font.name = 'Cambria Math'

                c_num = eq_tbl.cell(0, 1)
                c_num.width = Inches(0.7)
                p_num = c_num.paragraphs[0]
                p_num.alignment = WD_ALIGN_PARAGRAPH.RIGHT
                p_num.paragraph_format.space_before = Pt(4)
                p_num.paragraph_format.space_after = Pt(4)
                if eq_num_str:
                    r_num = p_num.add_run(eq_num_str)
                    r_num.font.name = 'Times New Roman'
                    r_num.font.size = Pt(10.5)

            pending_lead_in = None
            continue

        # Lists (Itemize / Enumerate)
        elif c.startswith(r'\begin{itemize}') or c.startswith(r'\begin{enumerate}'):
            is_ordered = c.startswith(r'\begin{enumerate}')
            items = re.findall(r'\\item\s+((?:(?!\\item|\\end).)*)', c, re.DOTALL)
            for idx, itm in enumerate(items, 1):
                p = doc.add_paragraph(style='List Number' if is_ordered else 'List Bullet')
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(3)
                p.paragraph_format.line_spacing = 1.15
                add_formatted_text_to_paragraph(p, itm.strip(), bib_engine, footnotes_list, label_map)
            pending_lead_in = None
            continue

        # Placeholders
        elif c.startswith(r'\PLACEHOLDER'):
            m = re.match(r'\\PLACEHOLDER\{([^}]+)\}', c)
            ph_text = m.group(1).strip() if m else c
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(8)
            p.paragraph_format.space_after = Pt(8)
            r = p.add_run(f"[PLACEHOLDER: {ph_text}]")
            r.bold = True
            r.font.size = Pt(9.5)
            r.font.color.rgb = RGBColor(0x99, 0x00, 0x00)
            pending_lead_in = None
            continue

        # Regular Paragraphs
        else:
            paragraphs = c.split('\n\n')
            for raw_p in paragraphs:
                p_clean = raw_p.strip()
                if not p_clean or p_clean.startswith('%'):
                    continue
                if p_clean in (r'\FloatBarrier', r'\pagebreak', r'\newpage', r'\clearpage'):
                    continue
                
                doc_p = doc.add_paragraph()
                doc_p.paragraph_format.space_before = Pt(0)
                doc_p.paragraph_format.space_after = Pt(6)
                doc_p.paragraph_format.line_spacing = 1.15
                
                if pending_lead_in:
                    r_lead = doc_p.add_run(pending_lead_in)
                    r_lead.bold = True
                    pending_lead_in = None
                    
                add_formatted_text_to_paragraph(doc_p, p_clean, bib_engine, footnotes_list, label_map)


# ==============================================================================
# 10. FOOTNOTE OPENXML INJECTOR
# ==============================================================================

def inject_native_footnotes(docx_path: str, footnotes_list: list):
    if not footnotes_list:
        return

    temp_dir = Path(docx_path).parent / "_temp_docx_pack"
    if temp_dir.exists():
        shutil.rmtree(temp_dir)

    with zipfile.ZipFile(docx_path, 'r') as zin:
        zin.extractall(temp_dir)

    ct_path = temp_dir / "[Content_Types].xml"
    ct_content = ct_path.read_text(encoding='utf-8')
    if 'footnotes.xml' not in ct_content:
        ct_content = ct_content.replace(
            '</Types>',
            '<Override PartName="/word/footnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"/></Types>'
        )
        ct_path.write_text(ct_content, encoding='utf-8')

    rels_path = temp_dir / "word" / "_rels" / "document.xml.rels"
    rels_content = rels_path.read_text(encoding='utf-8')
    if 'footnotes.xml' not in rels_content:
        rids = [int(x) for x in re.findall(r'Id="rId(\d+)"', rels_content)]
        next_id = max(rids) + 1 if rids else 100
        rel_entry = f'<Relationship Id="rId{next_id}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes" Target="footnotes.xml"/>'
        rels_content = rels_content.replace('</Relationships>', rel_entry + '</Relationships>')
        rels_path.write_text(rels_content, encoding='utf-8')

    fn_entries = []
    fn_entries.append('<w:footnote w:type="separator" w:id="-1"><w:p><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr><w:r><w:separator/></w:r></w:p></w:footnote>')
    fn_entries.append('<w:footnote w:type="continuationSeparator" w:id="0"><w:p><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr><w:r><w:continuationSeparator/></w:r></w:p></w:footnote>')

    for fn_id, fn_text in footnotes_list:
        safe_fn_text = (
            fn_text.replace('&', '&amp;')
                   .replace('<', '&lt;')
                   .replace('>', '&gt;')
                   .replace('"', '&quot;')
        )
        fn_xml = (
            f'<w:footnote w:id="{fn_id}">'
            f'<w:p>'
            f'<w:pPr><w:pStyle w:val="FootnoteText"/><w:spacing w:before="0" w:after="60" w:line="252" w:lineRule="auto"/></w:pPr>'
            f'<w:r><w:rPr><w:rStyle w:val="FootnoteReference"/></w:rPr><w:footnoteRef/></w:r>'
            f'<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="19"/></w:rPr>'
            f'<w:t xml:space="preserve"> {safe_fn_text}</w:t></w:r>'
            f'</w:p>'
            f'</w:footnote>'
        )
        fn_entries.append(fn_xml)

    footnotes_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:footnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">\n'
        + '\n'.join(fn_entries) +
        '\n</w:footnotes>'
    )

    (temp_dir / "word" / "footnotes.xml").write_text(footnotes_xml, encoding='utf-8')

    with zipfile.ZipFile(docx_path, 'w', zipfile.ZIP_DEFLATED) as zout:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, temp_dir)
                zout.write(full_path, rel_path)

    shutil.rmtree(temp_dir)
    print(f"Injected {len(footnotes_list)} native Word bottom-of-page footnotes.")


# ==============================================================================
# 11. MAIN PIPELINE
# ==============================================================================

def main():
    base_dir = Path(__file__).resolve().parent
    output_docx_path = base_dir / "Chapter2_V3.0_Review.docx"

    print("=================================================================")
    print(" Compiling Chapter 2 LaTeX to Word (.docx) - PDF Mirroring Mode")
    print("=================================================================")
    print(f"Working Directory: {base_dir}")
    print(f"Target Output:     {output_docx_path}")

    # 1. Initialize Bibliography Engine
    bbl_path = base_dir / "main.bbl"
    bib_path = base_dir / "references.bib"
    print(f"Loading Bibliography from {bbl_path}...")
    bib_engine = BibliographyEngine(str(bbl_path), str(bib_path))
    print(f"Loaded {len(bib_engine.entries)} bibliographic references.")

    # 2. Pre-scan all cross-reference labels
    print("Pre-scanning labels for cross-reference resolution...")
    label_map = prescan_labels(base_dir)
    print(f"Mapped {len(label_map)} labels (Sections, Tables, Figures, Equations).")

    # 3. Create Word Document
    doc = Document()
    configure_document_styles(doc)

    # 4. Document Header / Title Page
    title_p = doc.add_paragraph()
    title_p.paragraph_format.space_before = Pt(20)
    title_p.paragraph_format.space_after = Pt(6)
    title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = title_p.add_run("The Transformation of Accumulation into Productive Capacities:\nCapacity Utilization in the Center and Periphery")
    r_title.bold = True
    r_title.font.size = Pt(17)
    r_title.font.color.rgb = RGBColor(0x11, 0x11, 0x11)

    sub_p = doc.add_paragraph()
    sub_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sub_p.paragraph_format.space_after = Pt(14)
    r_sub = sub_p.add_run("WORK IN PROGRESS — PLEASE DO NOT CIRCULATE")
    r_sub.bold = True
    r_sub.font.size = Pt(10)
    r_sub.font.color.rgb = RGBColor(0x77, 0x77, 0x77)

    # Author
    auth_p = doc.add_paragraph()
    auth_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    auth_p.paragraph_format.space_after = Pt(4)
    r_auth = auth_p.add_run("Diego Polanco")
    r_auth.bold = True
    r_auth.font.size = Pt(12)

    aff_p = doc.add_paragraph()
    aff_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    aff_p.paragraph_format.space_after = Pt(18)
    r_aff = aff_p.add_run("Department of Economics, University of Massachusetts Amherst\nEmail: dpolanconeco@umass.edu")
    r_aff.font.size = Pt(10)
    r_aff.font.italic = True

    # 5. Abstract Block
    abstract_text = (
        "Chapter 1 demonstrated that the bivariate output–capital relation fails system-level cointegration "
        "and that a stable long-run capacity path requires the rate of exploitation to enter the cointegrating "
        "vector, yielding a transformation elasticity below unity (θ̂ < 1) indicative of structural overaccumulation. "
        "This chapter identifies how distribution conditions the conversion of accumulated capital into productive "
        "capacity and extends the analysis to the periphery. I estimate the transformation elasticity "
        "θ ≡ ∂ ln Yᵖ / ∂ ln K as a state-dependent cointegrating relation: for the United States (1931–2024), "
        "using Integrated Modified OLS with fixed-b inference and endogenously dated structural breaks (Vogelsang & Wagner 2024, "
        "Bai & Perron 2003); for Chile (1943–2010), using a threshold Cointegrating Multivariate Polynomial Regression "
        "with a composite balance-of-payments index. In the United States, θ remains strictly below unity throughout the "
        "sample, rising from 0.37 in 1960 to 0.43 in 2024 as effective wage pressure falls with the diversion of investment "
        "into intellectual property. Capacity utilization declines from its 1944 wartime peak to 93.8% in 2024, never "
        "re-anchoring to its Fordist level. In Chile, a balance-of-payments threshold at γ̂ = 0.425 switches the "
        "mechanization response off: the wage-share elasticity of the capital composition gap falls from +3.29 to +0.14 "
        "once foreign exchange binds. Peripheral capitalists retain the incentive to substitute machinery for labor and lose "
        "the means to do so, because the machinery is imported. The center–periphery comparison establishes that the same "
        "transformation relation is mediated by distributive conflict in the center and truncated by the balance-of-payments "
        "constraint in the periphery. Neither economy operates near θ = 1. Capacity utilization is not a norm toward which "
        "economies converge; it is the residual of a politically conditioned conversion of accumulation into productive capacity."
    )

    abs_box = doc.add_table(rows=1, cols=1)
    abs_box.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = abs_box.cell(0, 0)
    set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
    set_cell_shading(cell, "F9F9F9")
    
    p_abs = cell.paragraphs[0]
    p_abs.paragraph_format.line_spacing = 1.12
    p_abs.paragraph_format.space_after = Pt(6)
    r_absh = p_abs.add_run("Abstract\n")
    r_absh.bold = True
    r_absh.font.size = Pt(10.5)
    r_abst = p_abs.add_run(abstract_text)
    r_abst.font.size = Pt(9.5)

    p_kw = cell.add_paragraph()
    p_kw.paragraph_format.space_after = Pt(2)
    r_kwh = p_kw.add_run("Keywords: ")
    r_kwh.bold = True
    r_kwh.font.size = Pt(9.5)
    r_kwt = p_kw.add_run("Capacity Utilization; Transformation Elasticity; Choice of Technique; Cointegration; Okishio Viability; Balance-of-Payments Constraint; Center–Periphery.")
    r_kwt.font.size = Pt(9.5)

    p_jel = cell.add_paragraph()
    p_jel.paragraph_format.space_after = Pt(0)
    r_jelh = p_jel.add_run("JEL Codes: ")
    r_jelh.bold = True
    r_jelh.font.size = Pt(9.5)
    r_jelt = p_jel.add_run("B51; C32; E01; E22; E32; P16.")
    r_jelt.font.size = Pt(9.5)

    doc.add_page_break()

    # 6. Dynamic Table of Contents Page
    p_toc_h = doc.add_paragraph("Table of Contents", style='Heading 1')
    p_toc_h.paragraph_format.space_before = Pt(18)
    p_toc_h.paragraph_format.space_after = Pt(12)
    
    p_toc = doc.add_paragraph()
    w_ns = nsdecls('w')
    p_toc._element.append(parse_xml(f'<w:fldSimple {w_ns} w:instr="TOC \\o &quot;1-3&quot; \\h \\z \\u"/>'))
    
    doc.add_page_break()

    # 7. Global Tracking Counters
    counters = {
        'section': 0,
        'subsection': 0,
        'subsubsection': 0,
        'fig_counter': [0],
        'table_counter': [0],
        'eq_counter': [0],
    }

    footnotes_list = []

    # 8. Process Main Body Sections
    section_files = [
        ("Section 1: Introduction", base_dir / "section1.tex"),
        ("Section 2: Theoretical Foundations", base_dir / "section2.tex"),
        ("Section 3: The Hinge Object: theta", base_dir / "section3.tex"),
        ("Section 4: Empirical Strategy and Results", base_dir / "section4.tex"),
        ("Section 5: Comparative Determination", base_dir / "section5.tex"),
        ("Section 6: Bounded Conclusion", base_dir / "section6.tex"),
    ]

    for sec_label, sec_path in section_files:
        if sec_path.exists():
            print(f"Processing {sec_label} ({sec_path.name})...")
            sec_content = sec_path.read_text(encoding='utf-8')
            process_latex_content(
                doc, sec_content, base_dir, bib_engine, footnotes_list, counters, label_map, is_appendix=False
            )

    # 9. Process Appendices
    appendix_files = [
        ("A", "The Generalized Perpetual Inventory Method: Recursive Construction and Calibration", base_dir / "appendixA.tex"),
        ("B", "United States Specification A Full Estimation Results", base_dir / "appendixB.tex"),
        ("C", "United States Specification B Heterogeneous Capital", base_dir / "appendixC.tex"),
        ("D", "Chile External Constraint and Regime Shifting Results", base_dir / "appendixD.tex"),
        ("E", "Critical Values and Inference for the Cointegration Diagnostics", base_dir / "appendixE.tex"),
        ("F", "Order of Integration and Stochastic Pre-Testing Battery", base_dir / "appendixF.tex"),
    ]

    doc.add_page_break()
    p_app_head = doc.add_paragraph("Appendices", style='Heading 1')
    p_app_head.paragraph_format.space_before = Pt(20)

    for app_letter, app_label, app_path in appendix_files:
        if app_path.exists():
            print(f"Processing Appendix {app_letter}: {app_label} ({app_path.name})...")
            app_content = app_path.read_text(encoding='utf-8')
            process_latex_content(
                doc, app_content, base_dir, bib_engine, footnotes_list, counters, label_map,
                is_appendix=True, appendix_letter=app_letter
            )

    # 10. References / Bibliography Section
    print("Compiling References section...")
    doc.add_page_break()
    p_ref_h = doc.add_paragraph("References", style='Heading 1')
    p_ref_h.paragraph_format.space_before = Pt(20)
    p_ref_h.paragraph_format.space_after = Pt(12)

    sorted_entries = sorted(bib_engine.entries.values(), key=lambda x: x['display'])
    for entry in sorted_entries:
        p_ref = doc.add_paragraph()
        p_ref.paragraph_format.left_indent = Inches(0.5)
        p_ref.paragraph_format.first_line_indent = Inches(-0.5)
        p_ref.paragraph_format.space_before = Pt(0)
        p_ref.paragraph_format.space_after = Pt(5)
        p_ref.paragraph_format.line_spacing = 1.15
        
        r_ref = p_ref.add_run(entry['full_text'])
        r_ref.font.name = 'Times New Roman'
        r_ref.font.size = Pt(10)

    # 11. Save Initial Docx
    doc.save(str(output_docx_path))

    # 12. Inject Native Word Footnotes
    inject_native_footnotes(str(output_docx_path), footnotes_list)

    print("=================================================================")
    print(f" SUCCESS! Word document successfully created (PDF-Mirror Mode):")
    print(f" {output_docx_path}")
    print(f" File Size: {output_docx_path.stat().st_size / 1024 / 1024:.2f} MB")
    print("=================================================================")


if __name__ == '__main__':
    main()
