#!/usr/bin/env python3
"""Gera ../Reinos_City_Builder.html (arquivo único).

Base: o mapa "Reinos 3D — Reinos Independentes" (assets/). Dele aproveitamos, sem mexer na lógica:
  relevo, texturas, rios, províncias, fronteiras, modos de mapa, nomes de regiões, calendário,
  dinastias e ficha dos reinos.
Por cima entram os sistemas do city builder (src/): modelos 3D idle, aldeões, economia, interface.
"""
import pathlib, re
R = pathlib.Path(__file__).resolve().parent
src = R / 'src'
MAP = (R / 'assets' / 'Reinos_3D_Reinos_Independentes.html').read_text(encoding='utf-8').split('\n')
L = lambda a, b: '\n'.join(MAP[a - 1:b])  # linhas a..b (1-based, inclusivo)

def find(pat, start=1):
    for i in range(start - 1, len(MAP)):
        if pat in MAP[i]:
            return i + 1
    raise SystemExit('marcador não encontrado: ' + pat)

# --- recortes do arquivo do mapa (localizados por marcadores, não por número de linha) ---
css_map = L(2, find('<body><div id="app">') - 1).replace('</style></head><style>', '\n').rstrip()
css_map = re.sub(r'</style>\s*$', '', css_map)
data = L(find("const ALBEDO_SRC="), find("FEUDAL.houses.forEach("))
a0 = find("(()=>{'use strict';") + 1
a1 = find('6. MODELOS 3D') - 2          # até antes do bloco de modelos antigos
m0 = find('/* ---------- Nomes das regiões')
m1 = find("let lastKey='';") - 1          # rótulos, rios, calendário, dinastias, ficha do reino
engine = L(a0, a1)
mid = L(m0, m1)

def sub1(s, old, new):
    assert old in s, 'trecho não encontrado: ' + old[:60]
    return s.replace(old, new, 1)

# 1) construções com tinta (prévia verde/vermelha) e cores mais vivas no estilo idle
engine = re.sub(r"const fsO=HP\+LIGHT\+`.*?`;",
  "const fsO=HP+LIGHT+`uniform vec4 uTint;varying vec3 vCol;varying vec3 vNorm;void main(){vec3 n=normalize(vNorm);if(dot(n,uEye-vPos)<0.0)n=-n;float sh;vec3 c=light(vCol,n,1.0,sh);"
  "float l=dot(c,vec3(.3,.59,.11));c=mix(vec3(l),c,1.18)*1.04;c=mix(c,uTint.rgb,uTint.a);gl_FragColor=vec4(fogged(c),1.0);}`;", engine, count=1)
engine = sub1(engine, "const uO=locs(opr,COMMON)", "const uO=locs(opr,COMMON.concat(['uTint']))")
# 2) terreno: grade de construção, área do seu reino e destaque da construção selecionada
engine = sub1(engine, "uniform vec3 uLines;varying vec2 vUv;", "uniform vec3 uLines;uniform vec4 uGrid;uniform vec4 uSel;varying vec2 vUv;")
engine = sub1(engine, " float sh;gl_FragColor=vec4(fogged(light(base,n,nm.b*1.1,sh)),1.0);}`;",
 " {float mine=step(.555,pol.a)*step(pol.a,.62);"
 "if(uGrid.w>0.5)base=mix(base,base*vec3(.58,.58,.64),(1.0-mine)*landP*.6);"
 "if(uGrid.z>0.0){vec2 g=fract(vPos.xz/4.0);vec2 g2=min(g,1.0-g);float ln=1.0-smoothstep(0.0,0.06,min(g2.x,g2.y));"
 "float fade=1.0-smoothstep(uGrid.z*.6,uGrid.z,distance(vPos.xz,uGrid.xy));base=mix(base,vec3(1.0,.97,.85),ln*fade*.35*mine);}"
 "if(uSel.z>0.0){vec2 q=abs(vPos.xz-uSel.xy);float m=max(q.x,q.y);float r=1.0-smoothstep(0.0,0.5,abs(m-uSel.z));base=mix(base,vec3(1.0,.95,.5),r*(.6+.3*sin(uTime*5.0)));}}\n"
 " float sh;gl_FragColor=vec4(fogged(light(base,n,nm.b*1.1,sh)),1.0);}`;")
engine = sub1(engine, "'uFill','uPix','uTexW','uLines']", "'uFill','uPix','uTexW','uLines','uGrid','uSel']")
# 3) mapa político: províncias do jogador marcadas no alfa (150) para o shader saber onde se pode construir
engine = sub1(engine, "d[o+3]=p===selProv?255:128", "d[o+3]=p===selProv?255:(FEUDAL.prov[p][2]===playerKingdom()?150:128)")

css = css_map + '\n' + (src / 'style.css').read_text(encoding='utf-8')
body = (src / 'body.html').read_text(encoding='utf-8')
mine = lambda f: (src / f).read_text(encoding='utf-8')
js = '\n'.join([engine, mine('extra_shaders.js'), mine('models.js'), mine('game.js'), mine('view.js'), mid, mine('main.js')])
head = MAP[0].split('<title>')[0]
html = (f'{head}<title>Reinos 3D — City Builder</title><style>\n{css}\n</style></head><body>{body}<script>\n{data}\n'
        f"(()=>{{'use strict';\n{js}\n}})();\n</script></body></html>\n")
out = R.parent / 'Reinos_City_Builder.html'
out.write_text(html, encoding='utf-8')
print(out, len(html))
