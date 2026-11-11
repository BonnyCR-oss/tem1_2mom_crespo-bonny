#!/usr/bin/env bash
# Ejecuta las ocho preguntas y muestra los resultados en la consola.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 - <<'PY'
import csv,datetime,io,urllib.request,zipfile,hashlib
from pathlib import Path
p=Path('datos/Sample-Superstore.csv')
if not p.exists():
 print('Descargando el CSV público de Kaggle...',flush=True)
 try:
  url='https://www.kaggle.com/api/v1/datasets/download/vivek468/superstore-dataset-final'
  with urllib.request.urlopen(url,timeout=60) as response:
   archive=zipfile.ZipFile(io.BytesIO(response.read()))
  data=archive.read('Sample - Superstore.csv')
  expected_hash='58fb59c63089e564d835e4aabe19d371757de1137a5bf1888243ae386c4b7a97'
  if hashlib.sha256(data).hexdigest()!=expected_hash:
   raise ValueError('La versión publicada cambió; revisar el CSV antes de cargar')
  p.parent.mkdir(exist_ok=True)
  p.write_bytes(data)
 except Exception as e:
  raise SystemExit(f'No se pudo descargar: {e}. Descarga el archivo indicado en datos/README.md y guárdalo como {p}')
b=p.read_bytes()
try:s=b.decode('utf-8-sig')
except UnicodeDecodeError:s=b.decode('cp1252')
rows=list(csv.reader(io.StringIO(s,newline='')))
expected=['Row ID','Order ID','Order Date','Ship Date','Ship Mode','Customer ID','Customer Name','Segment','Country','City','State','Postal Code','Region','Product ID','Category','Sub-Category','Product Name','Sales','Quantity','Discount','Profit']
if rows[0]!=expected or any(len(r)!=21 for r in rows):raise SystemExit('CSV con estructura inesperada')
for row in rows[1:]:
 if any('\n' in v or '\r' in v for v in row):raise SystemExit('No se admiten campos multilínea')
 for i in (2,3):datetime.datetime.strptime(row[i],'%m/%d/%Y')
Path('datos/Sample-Superstore-utf8.csv').write_bytes(s.encode('utf-8'))
print('Fuente verificada:',len(rows)-1,'filas')
PY
archivos=(01_modelo_carga 02_calidad 03_regiones 04_rfm 05_productos 06_descuentos 07_tendencias 08_pareto)
for archivo in "${archivos[@]}"; do
  printf '\nEjecutando sql/%s.hql\n' "$archivo"
  ./scripts/ejecutar.sh "sql/$archivo.hql"
done
# Mostrar las estadísticas y el plan de optimización en la consola.
docker compose exec -T master beeline \
  -u jdbc:hive2://localhost:10000 -n root --silent=true \
  -e "USE examen_superstore; ANALYZE TABLE superstore COMPUTE STATISTICS; ANALYZE TABLE superstore COMPUTE STATISTICS FOR COLUMNS; EXPLAIN SELECT region,SUM(sales),SUM(profit) FROM superstore WHERE order_date>='2017-01-01' GROUP BY region;"
printf 'Ejecución completada: resultados mostrados en consola.\n'
