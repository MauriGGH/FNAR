import re, sys, os
from weasyprint import HTML
L = sys.argv[1]
src = open(L + '/contenido.html', encoding='utf8').read()

secs = re.findall(r'<section id="(\w+)"[^>]*data-title="([^"]*)"[^>]*>(.*?)</section>', src, re.S)

def prep(body):
    body = body.replace('<!--DESCARGAS-->', '')
    body = re.sub(r'<ol class="toc">.*?</ol>', '', body, flags=re.S)
    body = body.replace('<details class="spoiler">', '<div class="spoiler">').replace('</details>', '</div>')
    body = re.sub(r'<summary>.*?</summary>',
                  '<p class="warn">ALTO. Lo que sigue son los secretos de la historia. Si todavía no terminas las seis noches, salta al capítulo 10.</p>', body, flags=re.S)
    body = re.sub(r' style="[^"]*"', '', body)
    return body

toc = ''.join(f'<li><a href="#{i}"><span class="num">{n}</span><span class="t">{t}</span></a></li>'
              for n, (i, t, _) in enumerate(secs[1:], 1))
parts = []
for i, t, b in secs:
    parts.append(f'<section id="{i}" class="cap" data-t="{t}"><span class="rh">{t}</span>{prep(b)}</section>')

F = 'file://' + L + '/fonts/'
css = f"""
@font-face{{font-family:VT;src:url({F}VT323.ttf)}}
@font-face{{font-family:SE;src:url({F}SpecialElite.ttf)}}
@font-face{{font-family:SP;src:url({F}Spectral-Regular.ttf)}}
@font-face{{font-family:SP;font-style:italic;src:url({F}Spectral-Italic.ttf)}}
@font-face{{font-family:SP;font-weight:600;src:url({F}Spectral-SemiBold.ttf)}}
@font-face{{font-family:SP;font-weight:600;font-style:italic;src:url({F}Spectral-SemiBoldItalic.ttf)}}
@page{{size:139.7mm 215.9mm;margin:17mm 14mm 18mm 16mm;
  @top-center{{content:string(cap);font-family:SE;font-size:7.5pt;color:#8a8170;letter-spacing:.06em}}
  @bottom-center{{content:counter(page);font-family:VT;font-size:12pt;color:#555}}}}
@page :left{{margin-left:14mm;margin-right:16mm}}
@page portada{{margin:0;@top-center{{content:none}}@bottom-center{{content:none}}}}
@page limpia{{@top-center{{content:none}}@bottom-center{{content:none}}}}
@page apertura{{@top-center{{content:none}}}}
html{{font-family:SP;font-size:10pt;line-height:1.5;color:#1d1a16;hyphens:auto}}
body{{margin:0}}
.rh{{string-set:cap content();display:block;height:0;overflow:hidden;font-size:0}}
p{{margin:0 0 .55em;text-align:justify;orphans:2;widows:2}}
h2{{font-family:VT;font-weight:400;font-size:40pt;line-height:.9;margin:0 0 10mm;color:#111}}
h3{{font-family:SE;font-weight:400;font-size:12pt;margin:1.1em 0 .3em;color:#6b4f1d;break-after:avoid}}
.kicker{{font-family:VT;font-size:14pt;color:#2f6b3b;letter-spacing:.1em;margin-top:28mm}}
.lead{{font-size:11pt;font-style:italic;color:#333}}
.small{{font-size:8.5pt;color:#777}}
em{{font-style:italic}}
.cap{{break-before:right;page:apertura}}
#intro{{page:limpia}}
#intro .kicker{{margin-top:0}}
figure{{margin:5mm 0;break-inside:avoid}}
img{{max-width:100%;display:block}}
.shot{{border:.3mm solid #222}}
figcaption{{font-family:SE;font-size:7.5pt;color:#6d6658;margin-top:1.5mm;line-height:1.35}}
.duo figure{{margin:4mm 0}}
.cam{{position:relative}}
.cam .tag{{position:absolute;left:2mm;top:1mm;font-family:VT;font-size:13pt;color:#a8e0b0}}
table{{border-collapse:collapse;width:100%;font-size:8.5pt;margin:3mm 0 5mm;line-height:1.35}}
th,td{{text-align:left;padding:1.4mm 1.6mm;border-bottom:.2mm solid #bbb;vertical-align:top}}
th{{font-family:SE;font-weight:400;font-size:7.5pt;color:#6b4f1d;border-bottom:.4mm solid #333}}
td.n{{font-family:VT;font-size:12pt;color:#2f6b3b}}
tr{{break-inside:avoid}}
.ficha{{break-before:page}}
.ficha .ficha-img{{width:82%;margin:0 auto 4mm}}
.ficha h3{{font-family:VT;font-size:26pt;color:#111;margin:0;line-height:1}}
.role{{font-family:SE;font-size:8pt;color:#a32a22;letter-spacing:.12em;margin-bottom:2mm}}
.facts{{display:block;margin:2mm 0 3mm;padding:2.5mm 3mm;background:#efe8d8;font-size:8.8pt}}
.facts dt{{font-family:SE;font-size:7pt;color:#6b4f1d;letter-spacing:.08em;text-transform:uppercase;margin-top:1mm}}
.facts dt:first-child{{margin-top:0}}
.facts dd{{margin:0 0 0 0}}
.profes + .wide{{break-before:page}}
.clip{{break-inside:avoid;margin:0 0 7mm}}
.clip .date{{font-family:SE;font-size:9pt;color:#6b4f1d}}
.clip .date small{{display:block;color:#888;font-size:7.5pt}}
.clip h3{{margin-top:1mm;font-family:SP;font-weight:600;font-size:11pt;color:#111}}
.clip img{{width:78%;margin:2mm auto 0}}
.timeline .clip:first-child{{break-before:page}}
.sergio{{text-align:center;background:#1a1a17;padding:5mm 0 0;margin:4mm 0}}
.sergio img{{display:inline-block;height:45mm;width:auto;vertical-align:bottom;margin:0 4mm}}
.arcade figure{{margin:0 0 5mm}}
.arcade img{{width:85%;margin:0 auto;border:1.5mm solid #1f1f22;border-radius:3mm;image-rendering:pixelated}}
.arcade figcaption{{width:85%;margin:1.5mm auto 0}}
.spoiler{{break-before:page}}
.warn{{font-family:SE;font-size:9pt;color:#a32a22;border:.4mm dashed #a32a22;padding:3mm;text-align:left}}
.folder{{background:#d6c49e;color:#282019;padding:6mm 5mm 3mm;position:relative;margin-top:5mm}}
.folder h3{{color:#282019;margin-top:0;margin-right:24mm}}
.folder ul{{padding-left:4mm;margin:0}}
.folder li p{{font-size:9pt}}
.stamp{{position:absolute;right:4mm;top:3mm;font-family:SE;color:#b42a22;border:.7mm solid #b42a22;padding:.5mm 2mm;transform:rotate(-8deg);letter-spacing:.12em;font-size:8pt}}
#rarezas figure img{{max-height:52mm;width:auto;margin:0 auto}}
.note{{background:#efe8d8;border-left:1mm solid #2f6b3b;padding:3mm 4mm;margin-top:4mm}}
.note ul{{margin:.3em 0 0;padding-left:5mm}}
.icono{{width:40mm;margin:12mm auto 0;text-align:center}}
.icono img{{border-radius:18%}}
/* portada */
.portada{{page:portada;height:215.9mm;width:139.7mm;position:relative;background:#000;color:#f2ede2;overflow:hidden}}
.portada img{{position:absolute;top:0;left:0;width:139.7mm;height:215.9mm;object-fit:cover;object-position:72% 30%;opacity:.85}}
.portada .velo{{position:absolute;inset:0;background:linear-gradient(rgba(0,0,0,.15) 30%,rgba(0,0,0,.9))}}
.portada .rec{{position:absolute;top:8mm;right:9mm;font-family:VT;font-size:13pt;color:#a8e0b0}}
.portada .rec b{{display:inline-block;width:2.6mm;height:2.6mm;border-radius:50%;background:#b42a22;margin-right:1.5mm}}
.portada .logo{{position:absolute;left:10mm;bottom:30mm;font-family:VT;font-size:54pt;line-height:.82}}
.portada .sub{{position:absolute;left:10mm;right:10mm;bottom:16mm;font-family:SE;font-size:8.5pt;letter-spacing:.1em;text-transform:uppercase;color:#d6c49e}}
.legal{{page:limpia;break-before:page;height:170mm;position:relative}}
.legal div{{position:absolute;bottom:0;font-size:7.5pt;color:#777;line-height:1.5}}
.indice{{page:limpia;break-before:right}}
.indice h2{{margin-top:20mm}}
.indice ol{{list-style:none;padding:0;margin:0}}
.indice li{{margin:0 0 2.6mm;font-size:10.5pt}}
.indice a{{color:inherit;text-decoration:none;display:block}}
.indice .num{{font-family:VT;font-size:14pt;color:#2f6b3b;display:inline-block;width:8mm}}
.indice a::after{{content:leader('. ') target-counter(attr(href),page);color:#555}}
.contra{{page:portada;break-before:left;height:215.9mm;width:139.7mm;background:#0c0d0f;color:#d8d2c4;position:relative}}
.contra .in{{position:absolute;left:14mm;right:14mm;top:40mm;text-align:center}}
.contra img{{width:42mm;margin:0 auto 8mm;border-radius:18%}}
.contra p{{text-align:center;font-size:9.5pt}}
.contra .vt{{font-family:VT;font-size:20pt;color:#a8e0b0;margin-top:8mm}}
"""

html = f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Five Nights at Rocha's · El expediente</title><style>{css}</style></head><body>
<div class="portada"><img src="img/portada.jpg"><div class="velo"></div>
<div class="rec"><b></b>REC · 12:00 AM</div>
<div class="logo">FIVE<br>NIGHTS<br>AT<br>ROCHA'S</div>
<div class="sub">El expediente de la Coordinación de Sistemas</div></div>
<div class="legal"><div><b>Five Nights at Rocha's · El expediente</b><br>Edición actualizada a la versión 0.9.2 beta del juego.<br>Libro de lore hecho por y para fans, sin fines de lucro.<br>Coordinación de Sistemas · Turno de 12:00 a 6:00 AM.</div></div>
<div class="indice"><h2>Índice</h2><ol>{toc}</ol></div>
{''.join(parts)}
<div class="contra"><div class="in"><img src="img/icono.jpg">
<p>Eres el nuevo guardia nocturno de la Coordinación de Sistemas. Seis noches. Ocho profes que ya no salen del edificio. Y un teléfono que suena cada medianoche.</p>
<div class="vt">¿SOBREVIVIRÁS HASTA LAS 6 AM?</div></div></div>
</body></html>"""
html = html.replace(f'<section id="intro" class="cap" data-t="Léase antes del primer turno">', '<section id="intro" class="cap">')
open(L + '/libro_print.html', 'w', encoding='utf8').write(html)
pass
HTML(L + '/libro_print.html', base_url=L + '/').write_pdf(L + '/../Five_Nights_at_Rochas_Expediente.pdf')
print('ok')
