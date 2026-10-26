from pathlib import Path
import json,re,csv,collections,sys
sys.dont_write_bytecode=True
from ledger_tools import HERE,ROOT,sha,git,snapshot,extract,uncomment

data=json.loads((HERE/'paragraph_inventory.json').read_text(encoding='utf-8'))
inventory=data['paragraphs']; byid={r['paragraph_id']:r for r in inventory}
with (HERE/'01_PARAGRAPH_LEDGER.csv').open(encoding='utf-8-sig',newline='') as f: rows=list(csv.DictReader(f))
baseline=json.loads((HERE/'baseline.json').read_text(encoding='utf-8'))
assert set(byid)=={r['paragraph_id'] for r in rows} and len(rows)==len(byid)
statuses=['KEEP','LIGHT','COMPRESS','REWRITE','DELETE-SCAFFOLD']
codes=dict(SCF='generic academic scaffolding / metadiscourse',CERT='repeated certification or evidentiary self-congratulation',CONTR='unnecessary binary contrast',INT='adjectival or adverbial intensification',ABSN='abstract-noun stacking',RHYTH='overly regular sentence/paragraph cadence',TMPL='templated empirical paragraph architecture',REP='redundant nearby restatement',FIG='generic figure/table narration',VOICE='abrupt authorial-register discontinuity',META='unnecessary reader instruction',QUAL='excessive defensive qualification',MET='metaphor density / rhetorical overheating',TERM='conceptual terminology overloaded into one sentence',SYN='syntax/grammar obstructing reading',TYPO='obvious typographic/mechanical defect')
for r in rows:
    assert r['status'] in statuses and r['change_risk'] in ['LOW','MEDIUM','HIGH']
    assert set(filter(None,r['issue_codes'].split(';')))<=set(codes)
    assert all(r[x].strip() for x in ['diagnosis','preserve_invariants','recommended_operation','opening_fingerprint'])
    assert 8<=len(r['opening_fingerprint'].split())<=14 or len(byid[r['paragraph_id']]['text'].split())<8
    assert int(r['line_start'])<=int(r['line_end'])

def write(name,lines): (HERE/name).write_text('\n'.join(lines)+'\n',encoding='utf-8')
def esc(s):return s.replace('|','\\|').replace('\n',' ')
def groupkey(r):return 'Abstract' if r['section']=='Abstract' else (r['subsection'] or r['section'])
def belongs(r,key):return groupkey(r)==key or groupkey(r).startswith(key+'.')
def summary(rs):
    c=collections.Counter(r['status'] for r in rs); issues=collections.Counter(x for r in rs for x in r['issue_codes'].split(';') if x)
    return c,issues,(len(rs)-c['KEEP'])/len(rs) if rs else 0

# Dependency closure follows only uncommented source directives.
edges=[]; visited=set()
def visit(name):
    if name in visited:return
    visited.add(name)
    text='\n'.join(uncomment(x) for x in ROOT.joinpath(name).read_text(encoding='utf-8-sig').splitlines())
    for kind,target in re.findall(r'\\(input|include)\{([^}]+)\}',text):
        path=target if Path(target).suffix else target+'.tex'
        assert ROOT.joinpath(path).is_file(),path
        edges.append((name,path,kind));visit(path)
visit('main.tex')
assert len(visited)==19,(len(visited),visited)
write('source_dependency_graph.md',['# Active source dependency graph','',*['- `'+a+'` → `'+b+'` (`\\'+k+'`) ' for a,b,k in edges],'- `main.tex` → `references.bib` (`\\bibliography{references}`); generated bibliography: `main.bbl`.','',f'Compiled context: main.log names main.tex and records main.pdf, 103 pages. Both supplied PDFs have the same SHA-256: `{sha(ROOT/"main.pdf")}`.' if sha(ROOT/'main.pdf')==sha(ROOT/'Chapter2_V3.0.pdf') else 'The supplied PDFs differ; main.pdf is the log-supported compile output.'])

# Independent lexical coverage check: every source line with readable prose must
# lie in a ledger span or an explicitly excluded heading/environment/front matter.
uncovered=[]; span_overlaps=[]; short_units=[]
for name in ['main.tex']+[f'section{i}.tex' for i in range(1,7)]:
    source=ROOT.joinpath(name).read_text(encoding='utf-8-sig'); lines=source.splitlines()
    masked='\n'.join(uncomment(x) for x in lines)
    def blank(m):return ''.join('\n' if c=='\n' else ' ' for c in m.group())
    if name=='main.tex':
        start=masked.index(r'\begin{abstract}')+len(r'\begin{abstract}');end=masked.index(r'\end{abstract}')
        masked=''.join('\n' if c=='\n' else ' ' for c in masked[:start])+masked[start:end]+''.join('\n' if c=='\n' else ' ' for c in masked[end:])
    masked=re.sub(r'\\begin\{(equation\*?|align\*?|gather\*?|table\*?|figure\*?|longtable)\}.*?\\end\{\1\}',blank,masked,flags=re.S)
    # Balanced heading arguments, including nested math braces.
    starts=list(re.finditer(r'\\(?:section|subsection|subsubsection|paragraph)\*?\{',masked))
    chars=list(masked)
    for m in starts:
        depth=1;j=m.end()
        while j<len(masked) and depth:
            if masked[j]=='{':depth+=1
            elif masked[j]=='}':depth-=1
            j+=1
        for i in range(m.start(),j):
            if chars[i]!='\n':chars[i]=' '
    masked=''.join(chars)
    masked=re.sub(r'\\(?:label|input|include|begin|end|vspace|setcounter)\{[^}]*\}(?:\{[^}]*\})?',blank,masked)
    masked=re.sub(r'\\(?:FloatBarrier|clearpage|pagebreak|newpage|centering|noindent)\b','',masked)
    covered=collections.Counter()
    for r in rows:
        if r['source_file']==name:
            for i in range(int(r['line_start']),int(r['line_end'])+1):covered[i]+=1
    for n,line in enumerate(masked.splitlines(),1):
        if re.search(r'[A-Za-z]{2}',line) and not covered[n]:uncovered.append({'file':name,'line':n,'text':line.strip()})
    span_overlaps.extend((name,n) for n,count in covered.items() if count>1)
for r in rows:
    if len(r['opening_fingerprint'].split())<8:short_units.append(r['paragraph_id'])
assert not uncovered,uncovered
assert not span_overlaps,span_overlaps
reextracted,_,_=extract()
assert reextracted==inventory
coverage={'eligible':len(inventory),'classified':len(rows),'unique_ids':len(set(r['paragraph_id'] for r in rows)),'uncovered_prose_lines':uncovered,'overlapping_locator_spans':span_overlaps,'short_units_with_full_opening':short_units,'list_items':sum(ROOT.joinpath(r['source_file']).read_text(encoding='utf-8-sig').splitlines()[int(r['line_start'])-1].strip().startswith(r'\item') for r in rows),'extraction_reproducible':True}
(HERE/'coverage_validation.json').write_text(json.dumps(coverage,indent=2),encoding='utf-8')

scope=['# Phase 1 scope and locks','','Date: 2026-09-29 (task-local date). Diagnostic pass only.','','## Repository and initial Git observations','',f'- Working directory: `{ROOT}`',f'- Repository root: `{baseline["toplevel"]}`',f'- Current branch: `{baseline["branch"]}`','- The three requested read-only Git commands were run from Chapter2_3.0 immediately after reading the attached request. The working tree was already dirty. The status was persisted after source reconnaissance; no Git mutation occurred. Chapter2_3.0 was already represented by `?? ./`, so short status does not enumerate new diagnostics inside it.','', '```text',baseline['status'],'```','','## Source of truth and reconnaissance','','`main.tex` is the active root, supported by its input chain and main.log. Active main-text prose is split across section1.tex–section6.tex; the abstract is in main.tex. references.bib is the active bibliography, confirmed by main.blg. Six appendix files and six table files are input by the root or Section 4. The exact dependency closure is in source_dependency_graph.md. Figures are read-only dependencies named by includegraphics. main.pdf and Chapter2_V3.0.pdf are byte-identical 103-page PDFs. PDF pages 44 and 78 were rendered and visually inspected only for context: displayed mathematics remains within its prose unit and the Conclusion opening is present. This is not a PDF-wide layout audit.','', 'The existing compile_chapter2.py is a Markdown-to-LaTeX generator that would overwrite active sources; it was inspected but never run. Its upstream drafts are not substituted for active LaTeX. section4_old.tex, references_long.tex, and 99_archive are outside the active source chain. Existing directories include 99_archive, figures, tables, .prism, .claudeprism, .venv, and __pycache__; no existing equivalent Phase 1 directory was found. Repository audit/style locations identified include chapter2_vault/08_audits_handoffs and chapter2_vault/07_WrittingSkills_and_Rules. No prior artifacts were overwritten.','','## Scope and counting convention','','Abstract; Sections 1–2; Section 3 prose around formal material; Sections 4.1–4.6; Discussion; Conclusion. Source numbering is generated by section/subsection/subsubsection commands, consistent with main.toc, not inferred from stale cross-references inside prose.','',f'{len(rows)} prose units include {coverage["list_items"]} substantive list items. Each blank-line-delimited prose paragraph, run-in-heading body, or substantive list item is one unit. A displayed equation does not by itself split a paragraph: adjoining prose separated only by the display remains one unit. Genuine blank-line-separated equation introductions/continuations have their own IDs. Paragraph headings are not counted as prose. Formal statement prose is inventoried conservatively, with the formal claim protected; local explanatory grammar flags never authorize changing a proposition. Attached footnotes remain with their host paragraph and are not separately counted.','', 'IDs reset by the deepest numbered section/subsection/subsubsection. Bare section-level prose retains its own counter when child sections begin. Source file, inclusive approximate line span, and the first 12 whitespace-separated opening source tokens identify each unit. LaTeX symbols/citations may remain in fingerprints to improve source search. For prose units shorter than eight tokens, the complete opening is used and listed in coverage_validation.json. IDs are fixed to this snapshot; future edits should match ID + fingerprint + source, not renumber the entire ledger.','','Exclusions: title/author disclosures, keywords/JEL, contents, headings, references, appendix prose, standalone equations, equation content within prose units, all tables, notes, figures, captions and bibliography entries. Captions were screened: none contains unusually substantial argumentative prose requiring a separate row. Appendix files were inspected only for dependency closure, not classified or evaluated.','','## Absolute substantive locks','','No assessment or change to specifications, estimator choice, identification, integration orders, cointegration, breaks, thresholds, Monte Carlo inference, estimates, SEs, statistics, numerical values, equations, derivations, propositions, formal claims, figures/tables/data, stock construction, GPIM, historical or causal claims, theory, center–periphery architecture, choice of technique, theta/mu interpretation, Okishio/Vidal/Prebisch/Kaldor frameworks, citations, bibliography, or references. No fact-checking, external literature search, citation addition/removal/relocation, or new estimator/model/history recommendation. Existing author-written future-work proposals are preserved as existing content, not proposed by this diagnosis. A KEEP may retain issue codes when meaning-drift risk outweighs stylistic gain.','','All later operations are proposals only. No replacement sentences or revised paragraphs are supplied. A compression recommendation must preserve the claim even when deleting its duplicated certification; it cannot weaken or strengthen uncertainty or causality. Citations remain locked in place. Historical violence, class agency, dead labor, and theoretical metaphors are not defects merely because they are forceful.','','## Benchmarks and method','','Primary: Section 6, especially its reports/produces opening and estimate → economic mechanism sequence. Secondary: Section 1 on observed output/unobserved capacity, the three conventional treatments, and the Chapter 1 bridge. Technical sections retain their technical register. No journal template, word limit, AI detector, provenance inference, or aesthetic score was used. Automated extraction and lexical counts support a contextual, paragraph-specific editorial reading; keyword matches did not assign statuses.','','Blocks A–D were read and classified sequentially. After each block the CSV/Markdown ledger was saved, unique IDs validated, and hashes checked. progress.jsonl records 95, 169, 248, and 267 completed units. baseline.json snapshots 155 pre-existing chapter files outside environment/build internals, including all active sources, bibliography, tables, figures, PDFs, and build-context files. No original file in that snapshot changed.','','## Skills and precedence','','The prose-register-critic skill supplied a narrow scaffolding/register lens; econ-write supplied mechanics only; the repository political-economy/UMass guidance supplied the framing constraint. The PDF skill was used only for two context pages. The user request overrides skill instructions to purge prose, impose neutral vocabulary, produce referee perspectives/scores, audit economics, add literature, or write outside this diagnostic directory. No such wider workflow was run and no agents were spawned. The latest explicit artifact location overrides the general reports-directory convention. Vault notes and maps were untouched.','','## Issue codes','',*['- **'+k+'**: '+v+'.' for k,v in codes.items()],'','SYN/TYPO are copyediting observations, not stylistic AI-trace findings. No new codes were added.','','## Status, risk and priority','','KEEP protects working prose or consequential wording; LIGHT permits local repair; COMPRESS targets duplicate or non-substantive framing; REWRITE is sparse and preserves the full claim set; DELETE-SCAFFOLD is confined to a content-free sentence. HIGH risk protects estimates, causal interpretation, formal mappings, and attribution. MEDIUM concerns substantive navigation or removable implementation vocabulary. LOW is limited to simple navigation/scaffold. P0 = no edit/benchmark; P1 = highest-value architectural/compression intervention; P2 = useful local intervention; P3 = optional cleanup. Actual row values govern.','','## Deviations and limits','','No substantive or Git deviation. Supporting scripts, inventories, hashes, decisions, validation files, and two PDF context images are additional diagnostic artifacts inside the authorized folder. Very short list/continuation units cannot supply eight words; their full openings are preserved. The inventory is based on LaTeX source paragraph boundaries, not PDF block detection. The source snapshot is the coverage denominator. The one high-risk ambiguous passage (CH2-S04.05.02-P006) remains KEEP with an explicit author-dependent hold; this does not block completion of Phase 1. No Phase 2 work was begun.']
write('00_PHASE1_SCOPE_AND_LOCKS.md',scope)

def diagnosis(key):
    if key=='Abstract':return 'Dense but purposeful findings summary; protected.'
    if key=='1':return 'Strong internal voice benchmark; substantive contrasts and roadmap retained.'
    if key=='6':return 'Primary benchmark; all seven paragraphs protected.'
    if key=='5':return 'Metaphor/amplifier accumulation and repeated framing; retain class and center–periphery argument.'
    if key.startswith('4.3'):return 'Technical sequencing and null distinctions justify repetition; protected.'
    if key.startswith('4.2'):return 'Repeated figure-first entries and descriptive roadmaps; several local grammar faults.'
    if key.startswith('4.4'):return 'Repeated certification and mechanism recaps around estimates; recovery/history prose often works.'
    if key.startswith('4.5'):return 'Selective result-recap compression; one overloaded example and one protected ambiguity.'
    if key.startswith('4.6'):return 'Mostly direct regime interpretation; preserve limits and technical definitions.'
    if key.startswith('4.1'):return 'Mostly necessary construction/provenance detail; local grammar and one overloaded sentence.'
    if key.startswith('3'):return 'Formal exposition protected; local grammar distinct from technical density.'
    if key.startswith('2'):return 'Selective repeated-premise compression and ordinary grammar repair; no neutralization of theory.'
    return 'See paragraph-level decisions.'
allkeys=['Abstract']
for i in range(1,7):
    allkeys.append(str(i))
    subs=sorted(set(r['subsection'] for r in rows if r['section']==str(i) and r['subsection']),key=lambda x:list(map(int,x.split('.'))))
    for s in subs:
        parent='.'.join(s.split('.')[:2])
        if parent not in allkeys:allkeys.append(parent)
        if s not in allkeys:allkeys.append(s)
heat=['# Section heatmap','','Intervention density = non-KEEP / eligible paragraphs. Counts include grammar-only cases; they are not AI-likelihood or aesthetic scores. Parent rows aggregate children and must not be added to child rows.','', '| Section | Eligible | KEEP | LIGHT | COMPRESS | REWRITE | DELETE-SCAFFOLD | Dominant codes | Density | Diagnosis |','|---|---:|---:|---:|---:|---:|---:|---|---:|---|']
groupstats={}
for key in allkeys:
    rs=[r for r in rows if belongs(r,key)];c,issues,density=summary(rs);groupstats[key]={'n':len(rs),'counts':dict(c),'density':density}
    heat.append('| '+key+' | '+str(len(rs))+' | '+' | '.join(str(c[x]) for x in statuses)+' | '+(', '.join(k+':'+str(v) for k,v in issues.most_common(4)) or 'none')+' | '+f'{density:.1%}'+' | '+diagnosis(key)+' |')
heat+=['','Codes can appear in protected KEEP rows (formal claims or unresolved meaning risk). Those flags do not increase intervention density. Small one-paragraph subsections can reach 100% with one local grammar recommendation; broad-section ranking is more informative.','', 'The expected Tier 1 order is partly supported: Discussion, 4.2, and 4.4 are the leading broad units. Section 4.5 warrants selective work, not blanket rewriting. Section 2 has substantial grammar-only repair. Section 4.6 is largely KEEP; the abstract requires no intervention. Sections 4.3, 6, and 1 remain protected.']
write('02_SECTION_HEATMAP.md',heat)

def remove_command(s,name):
    pattern=re.compile(r'\\'+name+r'(?:\[[^]]*\])*\{')
    while True:
        m=pattern.search(s)
        if not m:return s
        depth=1;j=m.end()
        while j<len(s) and depth:
            if s[j]=='{':depth+=1
            elif s[j]=='}':depth-=1
            j+=1
        s=s[:m.start()]+' '+s[j:]
def plain(s):
    for name in ['footnote','citep','citet','citeyearpar','ref','cref','Cref','eqref','label']:
        s=remove_command(s,name)
    s=re.sub(r'(?<!\\)\$.*?(?<!\\)\$',' [math] ',s)
    s=re.sub(r'\\(?:textbf|textit|emph|textnormal)\{','',s)
    s=s.replace('~',' ').replace('{','').replace('}','')
    return ' '.join(s.split())
texts={r['paragraph_id']:plain(r['text']) for r in inventory}
patterns={
 'Certification verbs':r'\b(?:confirm(?:s|ed|ing|ation)?|demonstrat(?:e|es|ed|ing|ion)|establish(?:es|ed|ing)?|validat(?:e|es|ed|ing|ion)|reveal(?:s|ed|ing)?|rules? out|provides? (?:direct |empirical )?evidence)\b',
 'rather than':r'\brather than\b',
 'not-X-but-Y candidates (same sentence)':r'\bnot\b[^.!?]*?\bbut\b',
 'not merely / not simply':r'\bnot (?:merely|simply)\b',
 'instead of / unlike / less-X-than-Y candidates':r'\binstead of\b|\bunlike\b|\bless\b[^.!?]*?\bthan\b',
 'structural (exact word)':r'\bstructural\b',
 'structurally (separate)':r'\bstructurally\b',
 'Intensifier candidates':r'\b(?:fundamental(?:ly)?|crucial(?:ly)?|precisely|directly|strictly|radical(?:ly)?|dramatic(?:ally)?|violent(?:ly)?|systemic|profound(?:ly)?|decisive(?:ly)?|massive|severely|severe|catastrophic|robustly)\b',
 'Figure + reference + shows/plots/displays/traces/illustrates':r'\bFigures?\s+(?:shows?|plots?|displays?|traces?|illustrates?)\b',
 'First enumeration marker':r'\bFirst\s*[,.:]', 'Second enumeration marker':r'\bSecond\s*[,.:]',
 'This confirms / establishes / demonstrates':r'\bThis\s+(?:confirms|establishes|demonstrates)\b',
 'Transition candidates':r'\b(?:Taken together|Against this background|In this sense|More broadly|Crucially|Importantly|By contrast)\b',
 'Em-dash constructions (dash marks, not pairs)':r'---|—',
}
matches={name:{pid:list(re.finditer(pat,t,re.I)) for pid,t in texts.items() if re.search(pat,t,re.I)} for name,pat in patterns.items()}
freq=['# Pattern frequencies','','These are lexical diagnostics, not verdicts on individual passages or provenance. Counts are case-insensitive matches in eligible prose, excluding display mathematics, inline mathematics, attached footnote text, citation/reference command arguments, headings, captions, tables, appendices and bibliography. Formatting commands are simplified. Numbers and dates are not sentences for editorial judgment. Regex contrast candidates can include genuine analytical contrasts; only ledger decisions propose intervention.','', '| Pattern | Occurrences | Paragraphs | Locations |','|---|---:|---:|---|']
for name,loc in matches.items():freq.append('| '+name+' | '+str(sum(len(v) for v in loc.values()))+' | '+str(len(loc))+' | '+', '.join(pid+(f' ×{len(ms)}' if len(ms)>1 else '') for pid,ms in loc.items())+' |')
freq+=['','## Distribution by broad unit','','| Unit | Certification | rather than | not/but candidates | structural | Intensifiers | Figure formulas |','|---|---:|---:|---:|---:|---:|---:|']
for key in ['Abstract','1','2','3','4.1','4.2','4.3','4.4','4.5','4.6','5','6']:
    ids={r['paragraph_id'] for r in rows if belongs(r,key)}
    names=list(patterns);cols=[names[i] for i in [0,1,2,5,7,8]]
    freq.append('| '+key+' | '+' | '.join(str(sum(len(v) for p,v in matches[k].items() if p in ids)) for k in cols)+' |')
freq+=['','## Contextual findings','','- Certification is most problematic where it brackets the same evidence twice: 4.4.1 P004/P008/P011 and 4.5.1 P007/P008. In contrast, 6 P002 assigns separate claims to separate authors, and 4.3 explains test outcomes and mathematical independence. Those occurrences remain KEEP.','- The two generic descriptive openers are CH2-S04.02.01-P001 and CH2-S04.02.02-P001. Both are COMPRESS, not DELETE-SCAFFOLD: they also contain sample, variable, or historical distinctions. CH2-S04.01.02-P001 has a smaller duplicated activity announcement. The sole DELETE-SCAFFOLD is CH2-S04.04.01-P009.','- US 4.2.1 P002–P007 repeatedly opens with a Figure reference; Chile 4.2.2 P002–P006 repeats that form. Local variation is proposed selectively. P006/P007 in the US and P005 in Chile retain KEEP where the exposition already has a compact explanatory function.','- First/Second is justified in model channels, IM-OLS operations, accounting checks, and threshold regimes. CH2-S04.02-P001 is different: duplicate Third and mixed measurement/pattern/motivation create a damaged enumeration. In 4.5.2 P003 the two findings are distinct and remain KEEP.','- Genuine binary contrasts remain in 1 P002, 3 P002, the core/periphery mechanisms, and 6 P001/P004/P005. No global replacement of rather than, not/but, or unlike is proposed.','- Discussion P004/P006/P008/P012 combines amplifiers or metaphors with repeated interpretive endings. Historical violence and theoretical dead labor remain invariant. The technical structural-inflation concept is protected.','', '## Rhythm and paragraph architecture','','The most visible uniformity is the exhibit-first cluster in 4.2 and the result → confirmation → mechanism → confirmation cycle in 4.4.1 and selected 4.5.1 paragraphs. The Conclusion uses short opening propositions, longer numerical explanations, and earned interpretive endings; it is not uniform medium-length prose. Em dashes also carry definitions, date contrasts, and source qualifications, so dash frequency alone produces no status. A separate sentence-length score was deliberately not used: inline notation and long LaTeX lines make an automatic score misleading. RHYTH is assigned only to the damaged enumeration in 4.2-P001, not to all technical parallelism.','', '## Every meaningful occurrence of structural','','A = technical/defined referent; B = substantive theoretical or historical use (possibly redundant in its paragraph); C = generic or repeated rhetorical intensification. The following occurrence-level reading covers the exact word structural in the eligible prose. Structurally is counted separately above. Categories are contextual judgments after reading, not a replacement rule.']
structural=[]
cmap={('CH2-S04.02.01-P001',1),('CH2-S04.04.01-P008',2),('CH2-S04.05.02-P006',1),('CH2-S04.05.02-P006',2),('CH2-S05-P001',1),('CH2-S05-P001',3),('CH2-S05-P010',1)}
for pid,ms in matches['structural (exact word)'].items():
    t=texts[pid]
    for j,m in enumerate(ms,1):
        tail=t[m.end():].lower()
        if (pid,j) in cmap:cat='C';why='Repeats emphasis or wraps an already stated result; see paragraph decision, including the protected ambiguity in 4.5.2.'
        elif re.match(r'\s+(?:break|parameter|inflation|base\b|base elasticity|asset-weighted|marginal capacity|elasticity|transformation elasticity|capacity equation|import-intensity|weight\b)',tail) or (pid=='CH2-S04.06.01-P009'):
            cat='A';why='Names a defined econometric, accounting, or theoretical object; retain.'
        else:cat='B';why='Carries an institutional/theoretical distinction; assess local repetition, not the word alone.'
        context=t[max(0,m.start()-40):min(len(t),m.end()+95)]
        structural.append({'paragraph_id':pid,'occurrence':j,'category':cat,'context':context,'reason':why})
freq+=['','| ID / occurrence | Category | Context | Judgment |','|---|---|---|---|']
freq += ['| '+s['paragraph_id']+f' / {s["occurrence"]}'+' | '+s['category']+' | '+esc(s['context'])+' | '+s['reason']+' |' for s in structural]
sc=collections.Counter(s['category'] for s in structural)
freq+=['',f'Structural categories: A={sc["A"]}, B={sc["B"]}, C={sc["C"]}. No global find-and-replace. C occurrences in high-risk passages do not override a KEEP hold.']
write('03_PATTERN_FREQUENCIES.md',freq)

benchmarks=[
('S01-P001','Short propositions around a concrete numerator/denominator distinction.','Vary sentence length; put the economic object before interpretation.'),
('S01-P002','Three genuinely different treatments converge on a shared premise.','Retain contrasts that perform classification.'),
('S01-P003','The that/how distinction identifies the Chapter 1 extension.','Use a precise substantive bridge.'),
('S02.01-P004','Numerator and denominator have different mechanisms, expressed compactly.','Let a short contrast carry conceptual work.'),
('S02.02-P003','Firms operate, defer, idle, and devalue; costs have named bearers.','Use concrete economic subjects and verbs.'),
('S02.03-P002','Machine speed, maintenance and worker discretion make the mechanism observable.','Explain political economy through actions, not neutralized abstractions.'),
('S03-P001','Mechanism precedes the need for formalization.','Introduce technical work by stating its analytical purpose.'),
('S03-P002','Each nested model adds a distinct margin or constraint.','Use controlled parallelism when model structure warrants it.'),
('S03.02.02-P003','The distributive dividend is defined with timing and an effect direction.','Keep short technical list items short.'),
('S04.01.02-P004','Each accounting term and the implicit-price recursion receives a concrete interpretation.','Allow length where reproducibility needs it.'),
('S04.03-P002','Estimator motivation and the relevant property are stated economically.','Use precise technical problem-to-procedure prose.'),
('S04.03-P003','First/Second tracks the actual mathematical transformation.','Do not mistake procedural symmetry for generic rhythm.'),
('S04.04.01-P006','Named model estimates are reported with uncertainty and no grand recap.','Let the estimates occupy the paragraph.'),
('S04.04.02-P002','The two-year comparison makes the arithmetic and mechanism transparent.','Tie a number to its interpretation, then stop.'),
('S04.06.03-P001','State-specific slopes precede the incentive/means distinction.','Earn the closing force through the result.'),
('S06-P001','Reports/produces cadence introduces a precise identification sequence.','Mix short propositions with a longer explanatory sentence.'),
('S06-P002','Separate attribution gives each framework a distinct role.','Retain certification verbs when they identify actual argument ownership.'),
('S06-P003','Magnitudes and mechanism support the closing institutional interpretation.','Put evidence before rhetorical force.'),
('S06-P004','Threshold arithmetic explains why incentive survives while means disappear.','Translate results into concrete economic constraints.')]
bm=['# Internal KEEP benchmarks','','Nineteen protected paragraphs. These are voice controls, not certificates of empirical or theoretical validity. Later technical prose should retain its own register.','']
for pid,why,learn in benchmarks:
    pid='CH2-'+pid;r=next(r for r in rows if r['paragraph_id']==pid);assert r['status']=='KEEP'
    bm += [f'## {pid}',f'- Location: `{r["source_file"]}:{r["line_start"]}-{r["line_end"]}`.',f'- Opening: {r["opening_fingerprint"]}',f'- Why it works: {why}',f'- Learn selectively: {learn}','']
write('04_KEEP_BENCHMARKS.md',bm)

queue=['# Proposed intervention queue','','This is an authorization map, not an instruction to start Phase 2. Every number, citation, formal claim, causal direction and uncertainty level remains locked. Start with bounded groups and compare each change with the invariants in the ledger.','', '## Order supported by the diagnosis','','1. **Discussion (5)**: P004, P006, P012 for architecture/metaphor density; P001, P002, P008, P010 for compression. Keep P003/P005. Repair grammar separately in P009/P011. Do not depoliticize the chapter or remove dead-labor/valorization content.','2. **Descriptive exposition (4.2)**: the opening enumeration and two long descriptive roadmaps first; then selective figure-entry variation. Preserve numerical and historical patterns.','3. **Baseline US results (4.4.1)**: compress repeated certification in P004/P008/P011 and repeated theory/measurement exposition in P001–P003/P007. The content-free P009 can be removed separately. Protect the counterfactuals and the direct estimate paragraph P006.','4. **Selected heterogeneous-capital prose (4.5)**: P005/P007/P008 of 4.5.1 and P004 of 4.5.2 for repetition; 4.5.2-P007 for the overloaded example. 4.5.2-P006 is a KEEP hold because its malformed relation is meaning-sensitive. Do not infer its intended wording.','5. **Section 2**: target repeated premises in 2.1-P003, 2.2-P001/P004, 2.3-P003; undertake the historical-closure rewrite in 2.5-P004 only with all attribution and history fixed. Keep grammatical repair distinct from AI-trace diagnosis.','6. **Selected 4.1 and 4.6**: 4.1.7-P003 needs sentence restructuring; 4.1.2-P001 has duplicated announcements. In 4.6, most paragraphs remain KEEP; the US-rationale reprise (4.6.2-P002), local grammar, and a few amplifiers are the bounded candidates.','7. **Optional mechanics in 3**: only the rows explicitly marked LIGHT; definitions, propositions and proofs remain locked.','','## Hypothesis test','','The proposed broad Tier 1 candidates are supported, but not uniformly: 4.5 has many useful KEEP paragraphs and an unresolved wording hold. Section 2 intervention density includes ordinary grammar, not just accumulated editorial scaffolding. Section 4.6 needs less stylistic intervention than the initial second-tier hypothesis might imply. The abstract is KEEP rather than a third-tier editing task. All of 4.3, the Introduction, and the Conclusion remain protected.','','## All authorized-candidate rows in suggested order','','These are proposed future candidates only. KEEP rows are intentionally absent, including the high-risk ambiguity.','', '| Order | ID | Status | Risk | Priority | Operation |','|---:|---|---|---|---|---|']
order={'5':0,'4.2':1,'4.4':2,'4.5':3,'2':4,'4.1':5,'4.6':6,'3':7,'Abstract':8,'1':9,'6':10}
def rank(r):
    g=groupkey(r);k='.'.join(g.split('.')[:2]) if g.startswith('4.') else r['section']
    return order[k],0 if r['priority']=='P1' else 1,rows.index(r)
for n,r in enumerate(sorted([r for r in rows if r['status']!='KEEP'],key=rank),1):queue.append(f'| {n} | {r["paragraph_id"]} | {r["status"]} | {r["change_risk"]} | {r["priority"]} | {esc(r["recommended_operation"])} |')
write('05_PRIORITY_QUEUE.md',queue)

current=snapshot();assert current==baseline['hashes']
assert git('branch','--show-current')==baseline['branch']
finalgit=git('status','--short')
samegit=finalgit==baseline['status']
added_git=sorted(set(finalgit.splitlines())-set(baseline['status'].splitlines()))
removed_git=sorted(set(baseline['status'].splitlines())-set(finalgit.splitlines()))
gitnote='No change in short Git status.' if samegit else 'Short Git status gained the following pre-existing-workspace observation during the pass: '+repr(added_git)+'. Removed entries: '+repr(removed_git)+'. The sibling directory Chapter2_3.0 - copia was not created or touched by any command in this task. Its appearance is recorded, not normalized or attributed to a particular actor. The authorized Chapter2_3.0 source snapshot remains byte-identical.'
write('final_git_status.txt',[finalgit])
counts=collections.Counter(r['status'] for r in rows);issuecounts=collections.Counter(x for r in rows for x in r['issue_codes'].split(';') if x)
checks=[
('Coverage: every eligible paragraph exactly one status',f'{len(rows)}/{len(inventory)}; independent lexical line audit found no uncovered prose.'),
('Coverage: unique stable IDs',f'{len(byid)} unique IDs; complete decision/inventory set equality.'),
('Coverage: usable source locators','File, inclusive line span and opening fingerprint on every row; no overlapping prose spans; source re-extraction matches.'),
('Restraint: strong prose left alone',f'{counts["KEEP"]} KEEP; 19 internal controls; all Introduction/Conclusion and 4.3 rows protected.'),
('Restraint: technical density distinguished','Most of Sections 3/4.1 and all 4.3 remain KEEP; functional First/Second and contrasts retained.'),
('Restraint: no rewriting','Only diagnosis, invariants and future operations were written; no replacement manuscript prose.'),
('Integrity: no empirical/theoretical audit','No estimator, equation, inference, history, accounting or causal claim was checked or corrected.'),
('Integrity: citations locked','No citation edits, moves, deletions or bibliography changes.'),
('Integrity: no new references','No literature proposed or searched; author-written future-work proposals only recorded as invariants.'),
('Integrity: uncertainty and causal strength','All claims remain byte-identical; proposed operations explicitly preserve uncertainty and causality.'),
('Voice: internal benchmark','Conclusion and strongest Introduction passages govern diagnosis, with technical controls included.'),
('Voice: discontinuity rather than uniformity','Protected theorem prose, legitimate political metaphors and theoretical contrast; localized implementation aside and methodological self-promotion flagged.'),
('Empirics: actual repeated architecture located','4.4.1 P004/P007/P008/P011 and selected 4.5.1 paragraphs specifically identified.'),
('Empirics: no numerical-density penalty','4.4.1 P006, 4.4.2 P002, 4.5.1 P004, and 4.6.3 P002 retained.'),
('Discussion: politics versus overproduction','Class conflict, historical coercion, center–periphery mechanisms and labor/valorization claims retained; competing amplifiers/metaphors diagnosed.'),
('Git: manuscript bytes unchanged',f'All {len(current)} snapshotted pre-existing chapter files have identical SHA-256 hashes, including active sources and assets.'),
('Writes confined to the authorized directory','All task-created files, scripts, ledgers, inventories and context PNGs are under _editing_ai_detrace/phase1_ledger/; no outside write commands issued.'),
('Git: no commit or push','Only read-only Git status/branch/root commands used; no staging, pull, merge, rebase, checkout, reset, stash, clean or configuration change.'),
('Block checkpoints','95 → 169 → 248 → 267 rows saved; unique IDs and source hashes checked at all four milestones.'),
('Stop at Phase 1','No Phase 2 edit performed or requested.')]
audit=['# Phase 1 self-audit','','**Verdict: PASS.** Scope is a prose diagnosis, not certification of the chapter\'s economics.','', '| Item | Verdict | Evidence |','|---|---|---|',*['| '+a+' | PASS | '+b+' |' for a,b in checks],'','## Failure-condition check','','FAIL-01 through FAIL-12: none triggered. No source modification; no substantive correction; no added literature; substantial KEEP; no provenance claims; no density penalty; no reinterpretation; Conclusion protected; 4.3 protected; no monolithic rewrite; no prohibited Git operation.','',f'Final short Git status equals the saved baseline: {samegit}. This comparison is supplementary: the pre-existing untracked Chapter2_3.0 directory is collapsed in short status. File-level SHA-256 comparisons supply the chapter integrity evidence.','', '## Limits and protected uncertainty','','The two-page PDF check establishes context only, not a full rendering or source/PDF equivalence audit. SHA equality establishes that the two supplied PDFs match each other and were unchanged. Equation text is excluded from stylistic classification. Formal claims and conflicting substantive wording are not resolved. CH2-S04.05.02-P006 remains protected pending an author decision about meaning. Short-unit fingerprints use the entire source opening. These are documented limits, not hidden omissions.','', 'Evidence: baseline.json; progress.jsonl; coverage_validation.json; source_dependency_graph.md; pdf_context_check.json; final_git_status.txt.']
write('06_PHASE1_SELF_AUDIT.md',audit)
with (HERE/'06_PHASE1_SELF_AUDIT.md').open('a',encoding='utf-8') as f:f.write('\n## Concurrent repository observation\n\n'+gitnote+'\n')

broad=['Abstract','1','2','3','4.1','4.2','4.3','4.4','4.5','4.6','5','6']
ranked=sorted(broad,key=lambda k:groupstats[k]['density'],reverse=True)
complete=['# Phase 1 completion report','',f'- Branch: `{baseline["branch"]}`.',f'- Classified: **{len(rows)}** eligible prose units.', '- Status counts: '+', '.join(f'{k} {counts[k]}' for k in statuses)+'.','- Issue-code counts (paragraph incidences; codes may overlap): '+', '.join(f'{k} {v}' for k,v in issuecounts.most_common())+'.','- Highest broad-unit intervention density: '+', '.join(f'{k}: {groupstats[k]["density"]:.1%} ({groupstats[k]["n"]-groupstats[k]["counts"].get("KEEP",0)}/{groupstats[k]["n"]})' for k in ranked[:5])+'.','- Strongest voice controls: Conclusion, Introduction, selected theory/measurement paragraphs, and 4.3 technical prose. All seven Conclusion paragraphs are KEEP.','- Proposed Phase 2 order: bounded Discussion work; 4.2 roadmaps/entries; 4.4 certification/repetition; selected 4.5; then Section 2 and local 4.1/4.6 mechanics. See the queue for exclusions and invariants.','- Mostly untouched: Abstract, Introduction, Section 3, 4.1, all 4.3, most 4.6, Conclusion.','- Blocking uncertainty: none for Phase 1. One ambiguity is protected from later substantive guessing (CH2-S04.05.02-P006).','', '## Files inspected','','Active root and six main-text sources read for prose; compile_chapter2.py inspected without execution; root/input dependency closure inspected across appendix/table sources; bibliography selection verified in main.tex/main.blg; main.toc and main.log inspected for source numbering/build context. Existing main.pdf rendered at pages 44 and 78 and visually checked; Chapter2_V3.0.pdf verified byte-identical to main.pdf. Caption lines screened for substantial argumentative prose. Historical/archive drafts were not substituted. Git state, repository instructions, applicable skill guidance, and the attached request were read.','', '## Required deliverables','','- 00_PHASE1_SCOPE_AND_LOCKS.md','- 01_PARAGRAPH_LEDGER.csv','- 01_PARAGRAPH_LEDGER.md','- 02_SECTION_HEATMAP.md','- 03_PATTERN_FREQUENCIES.md','- 04_KEEP_BENCHMARKS.md','- 05_PRIORITY_QUEUE.md','- 06_PHASE1_SELF_AUDIT.md','- 07_PHASE1_COMPLETION_REPORT.md','',f'Supporting files retain source dependency evidence, the {len(current)}-file hash snapshot, paragraph inventory, four block decisions/checkpoints, validation, pattern calculations, and two context images. All artifacts are confined to this directory.','', '**Self-audit: PASS. NO MANUSCRIPT EDITS / NO COMMIT / NO PUSH. Phase 1 complete; stop.**']
write('07_PHASE1_COMPLETION_REPORT.md',complete)
with (HERE/'07_PHASE1_COMPLETION_REPORT.md').open('a',encoding='utf-8') as f:f.write('\nRepository observation: '+gitnote+'\n')
(HERE/'report_statistics.json').write_text(json.dumps({'counts':dict(counts),'issues':dict(issuecounts),'groups':groupstats,'structural_categories':dict(sc),'patterns':{k:sum(len(v) for v in loc.values()) for k,loc in matches.items()},'git_status_same':samegit,'coverage':coverage},indent=2),encoding='utf-8')
print(json.dumps({'counts':dict(counts),'highest':[(k,groupstats[k]) for k in ranked[:5]],'coverage':coverage,'structural':dict(sc),'git_status_same':samegit},indent=2))
