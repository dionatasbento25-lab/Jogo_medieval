#!/usr/bin/env python3
"""Gera o arquivo único Reinos_City_Builder.html a partir de src/ e assets/."""
import pathlib
R = pathlib.Path(__file__).resolve().parent
src = R / 'src'
css = (src / 'style.css').read_text(encoding='utf-8')
body = (src / 'body.html').read_text(encoding='utf-8')
data = (R / 'assets' / 'map_data.js').read_text(encoding='utf-8')
js = '\n'.join((src / f).read_text(encoding='utf-8') for f in ['engine.js', 'models.js', 'game.js', 'main.js'])
html = ('<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">'
        '<meta name="theme-color" content="#14271d"><title>Reinos 3D — City Builder</title>'
        f'<style>\n{css}</style></head><body>{body}<script>\n{data}\n(()=>{{\n{js}\n}})();\n</script></body></html>\n')
out = R.parent / 'Reinos_City_Builder.html'
out.write_text(html, encoding='utf-8')
print(out, len(html))
