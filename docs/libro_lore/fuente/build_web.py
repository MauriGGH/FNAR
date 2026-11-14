import re,sys
L=sys.argv[1]
o=open(L+'/plantilla_web/index.html',encoding='utf8').read().split('\n')
head='\n'.join(o[1:128])  # line2..128
tail='\n'.join(o[437:])
extra='''
.icono{max-width:260px;margin:40px auto 0;text-align:center}
.icono img{border-radius:18%;margin:0 auto}
.dl{display:flex;flex-wrap:wrap;gap:10px;margin:18px 0 6px}
.dl a{font-family:var(--f-type);font-size:15px;text-decoration:none;color:var(--night);background:var(--paper);padding:8px 14px}
.dl a:hover,.dl a:focus-visible{background:var(--crt)}
'''
mid=open(L+'/contenido.html',encoding='utf8').read()
mid=mid.replace('<!--DESCARGAS-->','<div class="dl"><a href="descargas/Five_Nights_at_Rochas_Expediente.pdf" target="_blank" rel="noopener">Abrir el PDF para imprimir</a></div>')
mid=re.sub(r' data-title="[^"]*"','',mid)
# lazy load images after the first
mid=re.sub(r'<img (?!.*loading)',r'<img loading="lazy" ',mid)
html=head+'\n'+extra+'\n</style>\n'+'\n'.join(o[129:139])+'\n<main>\n'+mid+'\n</main>\n'+tail
html=html.replace('Turno de 12:00 a 6:00 AM</footer>','Turno de 12:00 a 6:00 AM · Edición v0.9.2 beta</footer>')
open(L+'/index.html','w',encoding='utf8').write(html)
print(len(html))
