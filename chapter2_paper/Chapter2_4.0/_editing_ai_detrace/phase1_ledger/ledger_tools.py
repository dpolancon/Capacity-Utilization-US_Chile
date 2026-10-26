from pathlib import Path
import re, json, hashlib, subprocess, csv, collections
HERE=Path(__file__).resolve().parent
ROOT=HERE.parent.parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args): return subprocess.check_output(['git',*args],cwd=ROOT,text=True,encoding='utf-8').rstrip()
def uncomment(s): return re.sub(r'(?<!\\)%.*','',s)
def snapshot():
    paths=[p for p in ROOT.rglob('*') if p.is_file() and not any(x in p.parts for x in ['_editing_ai_detrace','.venv','.prism','.claudeprism','__pycache__'])]
    return {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in paths}
def clean(s):
    s=re.sub(r'\\label\{[^}]*\}', '', s)
    s=re.sub(r'\\(?:noindent|smallskip|medskip|bigskip)\b','',s)
    s=re.sub(r'\\(?:emph|textit|textbf|textnormal)\{([^{}]*)\}',r'\1',s)
    return ' '.join(s.split()).strip()
def extract():
    rows=[]; counts=collections.Counter(); headings={}; excluded=[]
    for file in ['main.tex']+[f'section{i}.tex' for i in range(1,7)]:
        lines=ROOT.joinpath(file).read_text(encoding='utf-8-sig').splitlines()
        sec=0 if file=='main.tex' else int(file[7]); sub=0; subsub=0; active=file!='main.tex'; env=None; heading=None; buf=[]; loc=[]
        def flush():
            nonlocal buf,loc
            text=clean(' '.join(buf)); buf=[]
            if not text or not re.search('[A-Za-z]{2}',text): loc=[]; return
            key='ABS' if sec==0 else 'S'+'.'.join(f'{i:02}' for i in ([sec]+([sub] if sub else [])+([subsub] if subsub else [])))
            counts[key]+=1
            rows.append(dict(paragraph_id=f'CH2-{key}-P{counts[key]:03}',section='Abstract' if sec==0 else str(sec),subsection='' if not sub else '.'.join(map(str,[sec,sub]+([subsub] if subsub else []))),source_file=file,line_start=min(loc),line_end=max(loc),opening_fingerprint=' '.join(text.split()[:12]),text=text,heading=headings.get(key,'')))
            loc=[]
        for n,raw in enumerate(lines,1):
            s=uncomment(raw).strip()
            if file=='main.tex':
                if r'\begin{abstract}' in s: active=True; continue
                if r'\end{abstract}' in s: flush(); active=False; continue
                if not active: continue
            if env:
                if re.search(r'\\end\{'+re.escape(env)+r'\}',s) or (env=='DISPLAY' and r'\]' in s): env=None
                continue
            if heading:
                heading+= ' '+s
                if heading.count('{')==heading.count('}'):
                    key='S'+'.'.join(f'{i:02}' for i in [sec]+([sub] if sub else [])+([subsub] if subsub else []))
                    headings[key]=heading; heading=None
                continue
            m=re.match(r'\\(section|subsection|subsubsection|paragraph)\*?\{',s)
            if m:
                flush(); typ=m[1]
                if typ=='subsection': sub+=1; subsub=0
                elif typ=='subsubsection': subsub+=1
                end=0; depth=0
                for j,c in enumerate(s[s.index('{'):],s.index('{')):
                    if c=='{': depth+=1
                    if c=='}':
                        depth-=1
                        if depth==0: end=j+1; break
                if not end: heading=s; continue
                if typ!='paragraph':
                    key='S'+'.'.join(f'{i:02}' for i in [sec]+([sub] if sub else [])+([subsub] if subsub else []))
                    headings[key]=s[:end]
                s=s[end:].strip()
                if not s: continue
            m=re.search(r'\\begin\{(equation\*?|align\*?|gather\*?|table\*?|figure\*?|tabular|longtable)\}',s)
            if m or s.startswith(r'\['):
                e=m[1] if m else 'DISPLAY'; excluded.append(dict(file=file,line=n,environment=e))
                if e.startswith(('table','figure','tabular','longtable')): flush()
                env=e
                if (m and r'\end{'+e+'}' in s) or (not m and r'\]' in s):env=None
                continue
            if re.match(r'\\(?:begin|end)\{(?:enumerate|itemize)\}',s): flush();continue
            if s.startswith(r'\item'):
                flush(); s=re.sub(r'^\\item(?:\[[^]]*\])?\s*','',s)
            if re.match(r'^\\(?:label|input|include|FloatBarrier|pagebreak|clearpage|newpage|vspace|setcounter|centering)\b',s):continue
            if not s:
                if not raw.strip().startswith('%'): flush()
                continue
            buf.append(s);loc.append(n)
        flush()
    return rows,headings,excluded
FIELDS='paragraph_id section subsection source_file line_start line_end opening_fingerprint status change_risk issue_codes diagnosis preserve_invariants recommended_operation priority notes'.split()
def build_ledger():
    inventory=json.loads((HERE/'paragraph_inventory.json').read_text(encoding='utf-8'))['paragraphs']
    decisions={}
    for p in sorted(HERE.glob('decisions_*.tsv')):
        for line in p.read_text(encoding='utf-8').splitlines():
            if not line.strip() or line.startswith('#'):continue
            parts=line.split('\t'); assert len(parts)==7,(p,line,len(parts))
            ident,status,risk,codes,diagnosis,invariants,operation=parts
            ident='CH2-'+ident
            assert ident not in decisions,ident
            decisions[ident]=(status,risk,codes,diagnosis,invariants,operation)
    out=[]
    for r in inventory:
        if r['paragraph_id'] not in decisions:continue
        status,risk,codes,diagnosis,invariants,operation=decisions[r['paragraph_id']]
        row={k:r[k] for k in FIELDS[:7]}
        row.update(status=status,change_risk=risk,issue_codes=codes,diagnosis=diagnosis,preserve_invariants=invariants+' Preserve all source numbers, symbols, citations, attribution, temporal scope, causal direction, and uncertainty strength; equations remain untouched.',recommended_operation=operation,priority='P0' if status=='KEEP' else ('P1' if status in ['COMPRESS','REWRITE','DELETE-SCAFFOLD'] else 'P3'),notes='Prose around displays is assessed with its equations in place; omitted displays are not missing prose.' if r['source_file']=='section3.tex' else '')
        if codes and set(codes.split(';')) <= {'SYN','TYPO'}:row['notes']+=' Mechanical/grammatical diagnosis only; not a stylistic AI-trace diagnosis.'
        if status=='LIGHT' and set(codes.split(';')) & {'SYN','FIG'}:row['priority']='P2'
        out.append(row)
    assert len(out)==len(decisions),'Unknown decision ID'
    with (HERE/'01_PARAGRAPH_LEDGER.csv').open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=FIELDS);w.writeheader();w.writerows(out)
    md=['# Phase 1 paragraph ledger','',f'{len(out)} of {len(inventory)} inventoried prose units classified. No replacement prose is supplied.','']
    last=None
    for r in out:
        key=r['subsection'] or r['section']
        if key!=last:md.extend(['',f'## {key}','']);last=key
        md.extend([f"### {r['paragraph_id']} — {r['status']} / {r['change_risk']} / {r['priority']}",f"- Locator: `{r['source_file']}:{r['line_start']}-{r['line_end']}`",f"- Opening: {r['opening_fingerprint']}",f"- Codes: {r['issue_codes'] or 'none'}",f"- Diagnosis: {r['diagnosis']}",f"- Preserve: {r['preserve_invariants']}",f"- Later operation: {r['recommended_operation']}",f"- Notes: {r['notes'] or 'No additional restriction.'}",''])
    (HERE/'01_PARAGRAPH_LEDGER.md').write_text('\n'.join(md),encoding='utf-8')
    baseline=json.loads((HERE/'baseline.json').read_text(encoding='utf-8'))
    current=snapshot();changed=[p for p,h in baseline['hashes'].items() if current.get(p)!=h];added=sorted(set(current)-set(baseline['hashes']))
    assert not changed and not added,(changed,added)
    progress={'classified':len(out),'eligible':len(inventory),'unique_ids':len(set(r['paragraph_id'] for r in out)),'status_counts':dict(collections.Counter(r['status'] for r in out)),'source_hashes_unchanged':True,'protected_files':len(current)}
    with (HERE/'progress.jsonl').open('a',encoding='utf-8') as f:f.write(json.dumps(progress)+'\n')
    print(json.dumps(progress))
if __name__=='__main__':
    import sys
    if sys.argv[1]=='init':
        baseline={'branch':git('branch','--show-current'),'toplevel':git('rev-parse','--show-toplevel'),'status':git('status','--short'),'hashes':snapshot()}
        (HERE/'baseline.json').write_text(json.dumps(baseline,indent=2),encoding='utf-8')
        rows,heads,ex=extract()
        (HERE/'paragraph_inventory.json').write_text(json.dumps({'paragraphs':rows,'headings':heads,'excluded_environments':ex},indent=2,ensure_ascii=False),encoding='utf-8')
        print('Inventory:',len(rows),collections.Counter(r['section'] for r in rows))
    elif sys.argv[1]=='read':
        data=json.loads((HERE/'paragraph_inventory.json').read_text(encoding='utf-8'))
        for r in data['paragraphs']:
            if any(r['paragraph_id'].startswith('CH2-'+x) for x in sys.argv[2:]):print(f"\n{r['paragraph_id']} | {r['source_file']}:{r['line_start']}-{r['line_end']}\n{r['text']}")
    elif sys.argv[1]=='build':build_ledger()
