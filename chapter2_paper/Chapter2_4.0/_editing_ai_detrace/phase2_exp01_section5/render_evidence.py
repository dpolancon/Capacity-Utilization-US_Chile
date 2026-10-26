from pathlib import Path
import json,subprocess,re,collections,fitz
OUT=Path(__file__).resolve().parent
TEMP=Path(json.loads((OUT/'compile_workspace.json').read_text(encoding='utf-8'))['directory'])
records={};docs={}
for variant in ['baseline','candidate']:
    cwd=TEMP/variant
    for extra in range(1,4):
        log=(cwd/'main.log').read_text(encoding='utf-8',errors='replace')
        if 'Label(s) may have changed' not in log and 'Rerun to get' not in log and 'Rerun to get /PageLabels' not in log:break
        with (cwd/f'extra_pass_{extra}.txt').open('w',encoding='utf-8') as f:
            r=subprocess.run(['pdflatex','-interaction=nonstopmode','-halt-on-error','-file-line-error','-no-shell-escape','main.tex'],cwd=cwd,stdout=f,stderr=subprocess.STDOUT)
        assert r.returncode==0,'ISOLATED_COMPILE_BLOCKED'
    log=(cwd/'main.log').read_text(encoding='utf-8',errors='replace')
    assert 'Label(s) may have changed' not in log and 'Rerun to get' not in log
    s=log.index('(./section5.tex');e=log.index('(./section6.tex',s)
    excerpt=log[s:e]
    warnings=[line for line in log.splitlines() if any(p in line for p in ['Warning','Overfull','Underfull','undefined'])]
    (OUT/f'{variant}_section5_build_log.txt').write_text(excerpt,encoding='utf-8')
    d=fitz.open(cwd/'main.pdf');docs[variant]=d
    toc=d.get_toc();start=next(x[2] for x in toc if x[0]==1 and x[1].startswith('Discussion:'))
    end=next(x[2] for x in toc if x[0]==1 and x[1]=='Conclusion')
    images=[]
    for pn in range(start,end+1):
        name=f'{variant}_section5_page_{pn:03}.png';d[pn-1].get_pixmap(matrix=fitz.Matrix(1.3,1.3)).save(OUT/name);images.append(name)
    records[variant]={'pages':len(d),'section5_start':start,'section6_start':end,'rendered_pages':list(range(start,end+1)),'images':images,'section5_warnings':[l for l in excerpt.splitlines() if any(w in l for w in ['Warning','Overfull','Underfull','undefined'])],'all_warnings':warnings,'extra_passes':extra-1}
    if variant=='candidate':(OUT/'EXP01_CANDIDATE_CHAPTER2.pdf').write_bytes((cwd/'main.pdf').read_bytes())
comparison=fitz.open()
for i in range(max(len(x['images']) for x in records.values())):
    page=comparison.new_page(width=1248,height=822)
    for col,variant in enumerate(['baseline','candidate']):
        pn=records[variant]['section5_start']+i
        page.insert_text((18+624*col,18),f'{variant.upper()} — original PDF page {pn}',fontsize=11)
        if pn<=records[variant]['section6_start']:page.show_pdf_page(fitz.Rect(12+624*col,28,624+624*col,820),docs[variant],pn-1)
comparison.save(OUT/'EXP01_SECTION5_COMPARISON.pdf')
records['warning_delta']={'new':list((collections.Counter(records['candidate']['all_warnings'])-collections.Counter(records['baseline']['all_warnings'])).elements()),'removed':list((collections.Counter(records['baseline']['all_warnings'])-collections.Counter(records['candidate']['all_warnings'])).elements())}
(OUT/'render_evidence.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print(json.dumps({k:{x:v[x] for x in ['pages','section5_start','section6_start','section5_warnings','images']} for k,v in records.items() if k!='warning_delta'},indent=2))
print('Warning delta:',records['warning_delta'])
