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
