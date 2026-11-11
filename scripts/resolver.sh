#!/usr/bin/env bash
# Ejecuta las ocho preguntas y conserva una salida CSV por pregunta.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p evidencias resultados
python3 - <<'PY'
import csv,datetime,io
from pathlib import Path
p=Path('datos/Sample-Superstore.csv')
if not p.exists():raise SystemExit('Descarga el CSV indicado en datos/README.md y guárdalo como datos/Sample-Superstore.csv')
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
registro=evidencias/ejecucion.txt
printf 'Ejecución de las ocho preguntas\n' > "$registro"
archivos=(01_modelo_carga 02_calidad 03_regiones 04_rfm 05_productos 06_descuentos 07_tendencias 08_pareto)
salidas=(p01_carga p02_calidad p03_regiones p04_rfm p05_productos p06_descuentos p07_tendencias p08_pareto)
for i in "${!archivos[@]}"; do
  archivo="sql/${archivos[$i]}.hql"
  salida="resultados/${salidas[$i]}.csv"
  printf '\n%s | %s\n' "$(TZ=America/La_Paz date --iso-8601=seconds)" "$archivo" >> "$registro"
  echo "Ejecutando $archivo"
  if ./scripts/ejecutar.sh "$archivo" > "$salida" 2>> "$registro"; then
    printf 'Código de salida: 0\n' >> "$registro"
    sha256sum "$archivo" "$salida" >> "$registro"
  else
    codigo=$?
    printf 'Código de salida: %s\n' "$codigo" >> "$registro"
    echo "Falló $archivo. Revisa $registro" >&2
    exit "$codigo"
  fi
done
# Guardar el plan como parte del análisis de optimización, sin crear otro archivo.
docker compose exec -T -e HADOOP_CLIENT_OPTS=-Ddisable.quoting.for.sv=false master beeline \
  -u jdbc:hive2://localhost:10000 -n root --silent=true \
  -e "USE examen_superstore; ANALYZE TABLE superstore COMPUTE STATISTICS; ANALYZE TABLE superstore COMPUTE STATISTICS FOR COLUMNS; EXPLAIN SELECT region,SUM(sales),SUM(profit) FROM superstore WHERE order_date>='2017-01-01' GROUP BY region;" >> "$registro" 2>&1
printf 'Ejecución completada: ocho CSV en resultados/.\n'
