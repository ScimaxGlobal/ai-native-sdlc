"""Generate GitHub wiki pages from the repo docs.

Usage: python tools/mkwiki.py <wiki-checkout-dir>
Env:   GITHUB_REPOSITORY (owner/repo), default ScimaxGlobal/ai-native-sdlc
"""
import os,re,shutil,sys,glob,subprocess
SRC=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.abspath(sys.argv[1])
REPO=os.environ.get("GITHUB_REPOSITORY","ScimaxGlobal/ai-native-sdlc")
BLOB=f"https://github.com/{REPO}/blob/main/"; TREE=f"https://github.com/{REPO}/tree/main/"
RAW=f"https://raw.githubusercontent.com/wiki/{REPO}/images/"
SEC={"00-Playbook":"Playbook","01-Stages":"Stages","02-Guides":"Guides","03-Templates":"Templates","04-Governance":"Governance","05-Diagrams":"Diagrams","06-Checklists":"Checklists","07-Reference":"Reference"}
import subprocess
files=subprocess.check_output(["git","ls-files"],cwd=SRC,text=True).splitlines()
mds=[f for f in files if f.endswith(".md")]
def page(f):
    if f=="README.md": return "Home"
    parts=f[:-3].split("/"); d,b="-".join(parts[1:]) and parts[0],"-".join(parts[1:]) if len(parts)>2 else parts[-1]
    if b=="README": return SEC[d]+"-Overview"
    return SEC[d]+"-"+b.replace(".","-")
pm={f:page(f) for f in mds}
imgs={f for f in files if f.startswith("05-Diagrams/png/") and f.endswith(".png")}|{f for f in files if f.startswith("05-Diagrams/") and f.endswith(".svg")}
def rewrite(f,text):
    base=os.path.dirname(f); out=[]; fence=False
    for line in text.split("\n"):
        if line.lstrip().startswith("```"): fence=not fence
        if not fence:
            def sub(m):
                pre,url=m.group(1),m.group(2)
                if re.match(r"^(https?:|mailto:|#)",url): return m.group(0)
                path,_,anc=url.partition("#"); anc=("#"+anc) if anc else ""
                t=os.path.normpath(os.path.join(base,path)).replace("\\","/")
                if t in pm: return f"{pre}({pm[t]}{anc})"
                if t in imgs: return f"{pre}({RAW}{os.path.basename(t)})" if t.endswith(".svg") or "/png/" not in t else f"{pre}({RAW}png-{os.path.basename(t)})"
                if t in files: return f"{pre}({BLOB}{t}{anc})"
                if os.path.isdir(os.path.join(SRC,t)): return f"{pre}({TREE}{t})"
                return m.group(0)
            line=re.sub(r"(\]|\]\s)\(([^)\s]+)\)",sub,line)
        out.append(line)
    return "\n".join(out)
for old in glob.glob(OUT+"/*.md")+glob.glob(OUT+"/images/*"): os.remove(old)
os.makedirs(OUT+"/images",exist_ok=True)
for f in imgs:
    n=os.path.basename(f); n=("png-"+n) if "/png/" in f else n
    shutil.copy(os.path.join(SRC,f),os.path.join(OUT,"images",n))
for f,p in pm.items():
    t=open(os.path.join(SRC,f),encoding="utf-8").read()
    t=rewrite(f,t)
    if f.startswith("03-Templates/") or True:
        t+=f"\n\n---\n*Source: [`{f}`]({BLOB}{f})*\n"
    open(os.path.join(OUT,p+".md"),"w",encoding="utf-8",newline="\n").write(t)
if "Diagrams-Overview" in pm.values():
    g = "\n## Gallery\n"
    for f in sorted(x for x in imgs if x.endswith(".svg")):
        n = os.path.basename(f)[:-4]
        g += f"\n### {n}\n![{n}]({RAW}{n}.svg)\n"
    with open(OUT + "/Diagrams-Overview.md", "a", encoding="utf-8", newline="\n") as fh:
        fh.write(g)
# sidebar
sb=["**[Home](Home)**\n"]
for d,l in SEC.items():
    sb.append(f"\n**{l}**")
    for f in sorted(mds):
        if f.split("/")[0]==d:
            n=pm[f][len(SEC[d])+1:]; n="Overview" if n=="README" else n.replace("-"," ")
            sb.append(f"- [{n}]({pm[f]})")
    if d=="05-Diagrams" and not any(f.startswith(d) for f in mds): pass
open(OUT+"/_Sidebar.md","w",encoding="utf-8",newline="\n").write("\n".join(sb)+"\n")
print(len(pm),"pages",len(imgs),"images")
