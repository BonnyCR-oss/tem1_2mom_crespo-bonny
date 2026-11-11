#!/usr/bin/env bash
# Reconstruye únicamente las tablas de este examen y conserva el CSV original.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p resultados evidencias
python3 scripts/preparar_datos.py
python3 - <<'PY'
import csv,datetime,hashlib,subprocess,time
from pathlib import Path
jobs=[('01_modelo',''),('01_carga','p01_carga'),('02_calidad','p02_calidad'),('02b_nulos','p02_nulos'),('03_regiones','p03_regiones'),('03b_desempeno','p03_desempeno'),('04_rfm','p04_rfm'),('04b_segmentos','p04_segmentos'),('05_productos','p05_productos'),('05b_ranking','p05_ranking'),('06_descuentos','p06_descuentos'),('06b_afectadas','p06_afectadas'),('07_tendencias','p07_tendencias'),('07b_extremos','p07_extremos'),('08_pareto','p08_resumen'),('08b_detalle','p08_detalle'),('09_optimizacion','')]
with open('evidencias/ejecuciones.csv','w') as meta:
 w=csv.writer(meta);w.writerow(['script','inicio','segundos','codigo_salida','salida','sha256_sql','sha256_salida'])
 for script,dest in jobs:
  sql=Path('sql',script+'.hql'); out=Path('resultados',dest+'.csv') if dest else Path('evidencias',script+'.stdout.txt')
  start=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-4))).isoformat(); t=time.monotonic()
  print('Ejecutando',sql,flush=True)
  with out.open('w') as stdout,Path('evidencias',script+'.stderr.txt').open('w') as stderr:
   try: code=subprocess.run(['./scripts/ejecutar.sh',str(sql)],stdout=stdout,stderr=stderr,timeout=600).returncode
   except subprocess.TimeoutExpired: code=124
  w.writerow([sql,start,round(time.monotonic()-t,3),code,out,hashlib.sha256(sql.read_bytes()).hexdigest(),hashlib.sha256(out.read_bytes()).hexdigest()]);meta.flush()
  if code: raise SystemExit(f'Error {code}: revisar evidencias/{script}.stderr.txt')
  if dest and not list(csv.DictReader(out.open())): raise SystemExit(f'Salida vacía: {out}')
PY
python3 scripts/validar_resultados.py
python3 scripts/generar_informe.py
