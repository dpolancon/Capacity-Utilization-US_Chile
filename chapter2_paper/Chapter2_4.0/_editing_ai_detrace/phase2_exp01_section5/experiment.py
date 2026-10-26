from pathlib import Path
import hashlib,json,re,subprocess,tempfile,shutil,sys,difflib,collections
sys.dont_write_bytecode=True
OUT=Path(__file__).resolve().parent
ROOT=OUT.parent.parent
PHASE1=OUT.parent/'phase1_ledger'
TARGETS=[f'CH2-S05-P{n:03}' for n in [1,2,4,6,8,10,12]]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True,encoding='utf-8').rstrip()
def snapshot():
    return {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in ROOT.rglob('*') if p.is_file() and not any(x in p.parts for x in ['phase2_exp01_section5','.venv','.prism','.claudeprism','__pycache__'])}
def init():
    assert not (OUT/'01_BASELINE_SECTION5.tex').exists(),'Existing experiment: preserve it'
    state={'branch':git('branch','--show-current'),'root':git('rev-parse','--show-toplevel'),'status':git('status','--short'),'hashes':snapshot()}
    assert state['branch']=='main'
    (OUT/'initial_state.json').write_text(json.dumps(state,indent=2),encoding='utf-8')
    shutil.copyfile(ROOT/'section5.tex',OUT/'01_BASELINE_SECTION5.tex')
    tex=set();assets=set()
    def follow(name):
        if name in tex:return
        tex.add(name);s=(ROOT/name).read_text(encoding='utf-8-sig');s=re.sub(r'(?m)(?<!\\)%.*','',s)
        for p in re.findall(r'\\(?:input|include)\{([^}]+)\}',s):follow(p if Path(p).suffix else p+'.tex')
        assets.update(re.findall(r'\\includegraphics(?:\[[^]]*\])?\{([^}]+)\}',s))
        for names in re.findall(r'\\bibliography\{([^}]+)\}',s):assets.update(n+'.bib' for n in names.split(','))
    follow('main.tex')
    closure=sorted(tex|assets)
    for name in closure:
        p=(ROOT/name).resolve();assert p.is_relative_to(ROOT.resolve()),name
        assert p.is_file(),name
    temp=Path(tempfile.mkdtemp(prefix='ch2_exp01_'))
    assert not temp.resolve().is_relative_to(Path(state['root']).resolve())
    for variant in ['baseline','candidate']:
        dst=temp/variant;dst.mkdir()
        for name in closure:
            (dst/name).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/name,dst/name)
    (OUT/'compile_workspace.json').write_text(json.dumps({'directory':str(temp),'closure':closure},indent=2),encoding='utf-8')
    print(json.dumps({'baseline_sha256':sha(OUT/'01_BASELINE_SECTION5.tex'),'protected_files':len(state['hashes']),'closure_files':len(closure),'temp':str(temp)}))
def compile_variant(variant):
    config=json.loads((OUT/'compile_workspace.json').read_text(encoding='utf-8'));cwd=Path(config['directory'])/variant
    if variant=='candidate':
        v=json.loads((OUT/'source_validation.json').read_text(encoding='utf-8'));assert v['verdict']=='PASS'
        shutil.copyfile(OUT/'02_CANDIDATE_SECTION5.tex',cwd/'section5.tex')
    commands=[['pdflatex','-interaction=nonstopmode','-halt-on-error','-file-line-error','-no-shell-escape','main.tex'],['bibtex','main'],['pdflatex','-interaction=nonstopmode','-halt-on-error','-file-line-error','-no-shell-escape','main.tex'],['pdflatex','-interaction=nonstopmode','-halt-on-error','-file-line-error','-no-shell-escape','main.tex']]
    results=[]
    for i,cmd in enumerate(commands,1):
        log=cwd/f'build_pass_{i}.txt'
        with log.open('w',encoding='utf-8') as f:r=subprocess.run(cmd,cwd=cwd,stdout=f,stderr=subprocess.STDOUT,text=True)
        results.append({'pass':i,'command':cmd,'exit_code':r.returncode})
        if r.returncode:
            print(log.read_text(encoding='utf-8',errors='replace')[-6000:]);break
    verdict='PASS' if len(results)==4 and all(r['exit_code']==0 for r in results) else 'ISOLATED_COMPILE_BLOCKED'
    (OUT/f'{variant}_compile.json').write_text(json.dumps({'verdict':verdict,'results':results},indent=2),encoding='utf-8')
    print(variant,verdict)
    if verdict=='PASS' and variant=='candidate':shutil.copyfile(cwd/'main.pdf',OUT/'EXP01_CANDIDATE_CHAPTER2.pdf')
def generate():
    baseline=(OUT/'01_BASELINE_SECTION5.tex').read_bytes()
    assert baseline==(ROOT/'section5.tex').read_bytes()
    lines=baseline.splitlines(keepends=True)
    inv=json.loads((PHASE1/'paragraph_inventory.json').read_text(encoding='utf-8'))['paragraphs']
    paras=[r for r in inv if r['section']=='5']
    replacements=json.loads((OUT/'candidate_paragraphs.json').read_text(encoding='utf-8'))
    assert set(replacements)==set(TARGETS)
    replaced=list(lines);results=[]
    for r in paras:
        pid=r['paragraph_id'];a=r['line_start']-1;b=r['line_end'];assert b==a+1
        old=lines[a];line=old.decode('utf-8');body=line.rstrip('\r\n').rstrip(' \t');suffix=old[len(body.encode('utf-8')):]
        # Require the fixed Phase 1 fingerprint to match this current source unit.
        assert ' '.join(body.split()[:6])==' '.join(r['opening_fingerprint'].split()[:6]),pid
        if pid in replacements:replaced[a]=replacements[pid].encode('utf-8')+suffix
    candidate=b''.join(replaced)
    (OUT/'02_CANDIDATE_SECTION5.tex').write_bytes(candidate)
    diff=''.join(difflib.unified_diff(baseline.decode('utf-8').splitlines(keepends=True),candidate.decode('utf-8').splitlines(keepends=True),fromfile='01_BASELINE_SECTION5.tex',tofile='02_CANDIDATE_SECTION5.tex'))
    (OUT/'03_EXP01_PATCH.diff').write_bytes(diff.encode('utf-8'))
    changed=[i+1 for i,(a,b) in enumerate(zip(lines,replaced)) if a!=b]
    expected=[r['line_start'] for r in paras if r['paragraph_id'] in TARGETS]
    problems=[]
    if changed!=expected or len(lines)!=len(replaced):problems.append('Non-authorized line difference')
    def tokens(s):
        return {'citations':re.findall(r'\\cite\w*(?:\[[^]]*\])*\{[^}]*\}',s),
                'numbers':re.findall(r'\d+(?:\.\d+)?',s),
                'math':re.findall(r'(?<!\\)\$.*?(?<!\\)\$',s),
                'refs':re.findall(r'\\(?:label|ref|cref|Cref|eqref)\{[^}]*\}',s),
                'commands':re.findall(r'\\(?:[A-Za-z]+|[^A-Za-z])',s)}
    for r in paras:
        i=r['line_start']-1;old=lines[i].decode('utf-8');new=replaced[i].decode('utf-8')
        checks={k:collections.Counter(v)==collections.Counter(tokens(new)[k]) for k,v in tokens(old).items()}
        entry={'id':r['paragraph_id'],'changed':old!=new,'checks':checks,'original_tokens':tokens(old),'candidate_tokens':tokens(new)}
        results.append(entry)
        if not all(checks.values()):problems.append(entry['id']+' token invariant failed')
        if entry['id'] not in TARGETS and entry['changed']:problems.append(entry['id']+' protected bytes changed')
    validation={'verdict':'FAIL' if problems else 'PASS','changed_line_numbers':changed,'expected_line_numbers':expected,'all_other_bytes_identical':changed==expected,'paragraphs':results,'problems':problems}
    (OUT/'source_validation.json').write_text(json.dumps(validation,indent=2),encoding='utf-8')
    print(json.dumps({'verdict':validation['verdict'],'changed':changed,'problems':problems}))
    if problems:
        (OUT/'07_EXP01_SELF_AUDIT.md').write_text('# EXP_01 FAILED\n\n'+str(problems)+'\nBaseline, candidate and attempted diff preserved. No further editing authorized.\n',encoding='utf-8');sys.exit(1)
if __name__=='__main__':
    if sys.argv[1]=='init':init()
    elif sys.argv[1]=='compile':compile_variant(sys.argv[2])
    elif sys.argv[1]=='generate':generate()
