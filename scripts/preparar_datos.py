#!/usr/bin/env python3
"""Verifica el original y produce una copia UTF-8 sin alterar los valores."""
import csv,datetime,hashlib,io,json
from pathlib import Path
p=Path('datos/Sample-Superstore.csv')
if not p.exists(): raise SystemExit('Descarga Sample - Superstore.csv de la fuente indicada en datos/README.md y guárdalo como datos/Sample-Superstore.csv')
b=p.read_bytes()
try: text=b.decode('utf-8-sig'); encoding='utf-8-sig'
except UnicodeDecodeError: text=b.decode('cp1252');encoding='cp1252'
rows=list(csv.reader(io.StringIO(text,newline='')))
expected=['Row ID','Order ID','Order Date','Ship Date','Ship Mode','Customer ID','Customer Name','Segment','Country','City','State','Postal Code','Region','Product ID','Category','Sub-Category','Product Name','Sales','Quantity','Discount','Profit']
if rows[0]!=expected: raise SystemExit('Cabecera inesperada; revisar antes de cargar')
if any(len(r)!=21 for r in rows): raise SystemExit('Hay filas con cantidad de columnas distinta de 21')
if any('\n' in v or '\r' in v for row in rows for v in row): raise SystemExit('OpenCSVSerde no admite saltos de línea dentro de campos')
# Validación estricta: unix_timestamp puede normalizar fechas inválidas. No cargar esas fechas silenciosamente.
for n,row in enumerate(rows[1:],2):
 for i in (2,3):
  try: datetime.datetime.strptime(row[i],'%m/%d/%Y')
  except ValueError: raise SystemExit(f'Fecha inválida en fila {n}, columna {expected[i]}: {row[i]!r}; requiere tratamiento documentado')
out=Path('datos/Sample-Superstore-utf8.csv'); out.write_bytes(text.encode('utf-8'))
info={'original':str(p),'codificacion_detectada':encoding,'sha256_original':hashlib.sha256(b).hexdigest(),'utf8':str(out),'sha256_utf8':hashlib.sha256(out.read_bytes()).hexdigest(),'registros':len(rows)-1,'columnas':21,'fechas_estrictamente_validas':True,'multilinea':False,'separador':',','comillas':'"','formato_fecha':'M/d/yyyy'}
Path('evidencias/perfil_fuente.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
print('CSV verificado:',len(rows)-1,'registros; original:',encoding)
