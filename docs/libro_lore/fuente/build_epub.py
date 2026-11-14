import re, sys, os
from ebooklib import epub
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
    body = re.sub(r'<span class="tag">[^<]*</span>', '', body)
    body = re.sub(r'(<img [^>]*?)>', lambda m: m.group(1) if m.group(1).endswith('/') else m.group(1) + ' />', body)
    body = body.replace('<article', '<div').replace('</article>', '</div>')
    return body

# La portada del EPUB es la primera página del PDF (correr antes build_print.py)
import pypdfium2
_d = pypdfium2.PdfDocument(L + '/../Five_Nights_at_Rochas_Expediente.pdf')
_p = _d[0]; _p.render(scale=1600 / _p.get_size()[0]).to_pil().convert('RGB').save(L + '/img/cover_epub.jpg', quality=88)
b = epub.EpubBook()
b.set_identifier('fnar-expediente-v092')
b.set_title("Five Nights at Rocha's: El expediente")
b.set_language('es')
b.add_author('Equipo de Five Nights at Rocha\'s')
b.set_cover('cover.jpg', open(L + '/img/cover_epub.jpg', 'rb').read())

fonts = ['VT323.ttf', 'SpecialElite.ttf']
for f in fonts:
    b.add_item(epub.EpubItem(uid=f, file_name='fonts/' + f, media_type='font/ttf', content=open(L + '/fonts/' + f, 'rb').read()))
css = """
@font-face{font-family:"VT323";src:url(../fonts/VT323.ttf)}
@font-face{font-family:"Special Elite";src:url(../fonts/SpecialElite.ttf)}
h2{font-family:"VT323",monospace;font-weight:normal;font-size:2.4em;line-height:1;margin:.2em 0 .8em}
h3{font-family:"Special Elite",serif;font-weight:normal;font-size:1.15em;margin:1.3em 0 .3em}
.kicker{font-family:"VT323",monospace;font-size:1.2em;letter-spacing:.1em;margin-top:2em;color:#2f6b3b}
.lead{font-style:italic}
.small,figcaption{font-size:.8em;opacity:.75}
figcaption{font-family:"Special Elite",serif}
figure{margin:1em 0;text-align:center}
img{max-width:100%;height:auto}
.ficha{margin:2em 0;page-break-before:always}
.ficha h3{font-family:"VT323",monospace;font-size:2em;margin:.4em 0 0}
.role{font-family:"Special Elite",serif;font-size:.8em;letter-spacing:.12em;color:#a32a22}
dl.facts{margin:.6em 0;padding:.6em .8em;border-left:3px solid #8a7a50}
dl.facts dt{font-family:"Special Elite",serif;font-size:.7em;text-transform:uppercase;letter-spacing:.08em;margin-top:.4em}
dl.facts dd{margin:0}
table{border-collapse:collapse;width:100%;font-size:.85em;margin:1em 0}
th,td{text-align:left;padding:.3em .4em;border-bottom:1px solid #999;vertical-align:top}
th{font-family:"Special Elite",serif;font-weight:normal}
td.n{font-family:"VT323",monospace;font-size:1.3em}
.clip{margin:1.6em 0}
.clip .date{font-family:"Special Elite",serif;font-size:.9em}
.clip .date small{display:block;opacity:.7}
.sergio{text-align:center}
.sergio img{display:inline;height:9em;width:auto;margin:0 .5em}
.warn{font-family:"Special Elite",serif;color:#a32a22;border:1px dashed #a32a22;padding:.6em}
.folder{border:2px solid #8a7a50;padding:.8em 1em;margin:1em 0}
.stamp{font-family:"Special Elite",serif;color:#b42a22;border:2px solid #b42a22;padding:0 .4em;letter-spacing:.12em;font-size:.8em}
.note{border-left:3px solid #2f6b3b;padding:.4em .8em;margin-top:1em}
.icono img{width:40%;}
"""
st = epub.EpubItem(uid='css', file_name='style/libro.css', media_type='text/css', content=css)
b.add_item(st)

imgs = set(re.findall(r'src="img/([^"]+)"', src))
for f in sorted(imgs):
    mt = 'image/png' if f.endswith('.png') else 'image/jpeg'
    b.add_item(epub.EpubItem(uid='img_' + f.replace('.', '_'), file_name='img/' + f, media_type=mt, content=open(L + '/img/' + f, 'rb').read()))

chs = []
for i, t, body in secs:
    c = epub.EpubHtml(title=t, file_name=f'{i}.xhtml', lang='es')
    body = prep(body)
    # links internos del índice web -> archivos
    body = re.sub(r'href="#(\w+)"', r'href="\1.xhtml"', body)
    c.content = f'<html><head><title>{t}</title></head><body>{body}</body></html>'
    c.add_item(st)
    b.add_item(c); chs.append(c)

b.toc = chs
b.spine = [('cover','yes'), 'nav'] + chs
b.add_item(epub.EpubNcx()); b.add_item(epub.EpubNav())
pass
epub.write_epub(L + '/../Five_Nights_at_Rochas_Expediente.epub', b)
print('ok')
import zipfile, shutil
p = L + '/../Five_Nights_at_Rochas_Expediente.epub'
zin = zipfile.ZipFile(p); tmp = p + '.tmp'
zout = zipfile.ZipFile(tmp, 'w')
for it in zin.infolist():
    d = zin.read(it.filename)
    if it.filename.endswith('content.opf'):
        d = d.replace(b'idref="cover" linear="no"', b'idref="cover"')
    zout.writestr(it, d, compress_type=zipfile.ZIP_STORED if it.filename == 'mimetype' else zipfile.ZIP_DEFLATED)
zout.close(); zin.close(); shutil.move(tmp, p)
print('fixed')
