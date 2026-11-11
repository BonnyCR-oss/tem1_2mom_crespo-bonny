# Análisis de Superstore con Apache Hive

Examen práctico individual de Tecnologías Emergentes I, segundo momento.
Autor: Bonny Alberto Crespo Romero.

Procesa el dataset Sample Superstore con Hive: modelo y carga, calidad, regiones, RFM, productos, descuentos, tendencias y Pareto. El PDF del enunciado describe ocho preguntas; la mención de doce en los requisitos no incluye cuatro enunciados adicionales.

## Requisitos y ejecución

Docker Engine/Desktop con Compose v2, Bash, Python 3, `timeout`, `realpath` e internet para descargar imágenes y dependencias. El entorno incluye un master Hadoop/Hive, tres DataNodes y PostgreSQL para el metastore.

1. Descargar el CSV de [Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) y guardarlo como `datos/Sample-Superstore.csv`.
2. Desde la raíz del repositorio:

```bash
./scripts/iniciar.sh
./scripts/ejecutar.sh sql/00_verificar_entorno.hql
./scripts/resolver.sh
```

La prueba debe devolver `1,Hive y HDFS operativos`. El último comando verifica el CSV, crea una copia UTF-8 y ejecuta las ocho preguntas en orden. Genera un CSV por pregunta en `resultados/` y reúne los mensajes, códigos de salida, hashes y EXPLAIN en `evidencias/ejecucion.txt`. Se detiene si una consulta falla.

Para ejecutar una pregunta individual:

```bash
./scripts/ejecutar.sh sql/03_regiones.hql
```

La primera pregunta debe ejecutarse antes de las demás. Todas usan `examen_superstore.superstore`. Repetir la carga utiliza `OVERWRITE` y reconstruye únicamente las tablas de resultados del examen.

## Archivos de la solución

| Pregunta | Script | Contenido |
|---|---|---|
| 1 | `sql/01_modelo_carga.hql` | Tabla raw, tabla ORC, carga tipada y comprobación de registros |
| 2 | `sql/02_calidad.hql` | Integridad, duplicados, fechas, descuentos y NULL por campo |
| 3 | `sql/03_regiones.hql` | Región/año, márgenes, LAG y ranking |
| 4 | `sql/04_rfm.hql` | Recencia, pedidos distintos, ventas y quintiles RFM |
| 5 | `sql/05_productos.hql` | Ganancia, unidades, margen, RANK, DENSE_RANK y acumulados |
| 6 | `sql/06_descuentos.hql` | Rangos de descuento y pérdidas por categoría/subcategoría |
| 7 | `sql/07_tendencias.hql` | Meses, comparación interanual, LAG y media móvil |
| 8 | `sql/08_pareto.hql` | Participación y cantidad mínima de productos para alcanzar 80% |

[Diccionario de los 21 campos](docs/diccionario_datos.md). El grano es una línea de pedido. Fechas originales: `M/d/yyyy`; códigos postales como STRING; importes como DECIMAL(18,4). OpenCSVSerde respeta nombres con comas y comillas. Beeline exporta CSV con comillas habilitadas.

Los CSV fuente y los resultados generados no se versionan. El documento de presentación y sus capturas se entregan en un PDF separado del repositorio.

## Resultados y decisiones

La ejecución sobre el archivo recibido el 11 de noviembre de 2026 importó 9.994 filas, 5.009 pedidos y 793 clientes, entre 2014-01-03 y 2017-12-30. Ventas: 2.297.200,8603 USD; ganancias: 286.397,0217 USD.

No se encontraron identificadores de fila duplicados, NULL en los 21 campos, fechas inválidas, envíos anteriores al pedido, ventas no positivas ni descuentos fuera de [0,1]. Las 1.871 líneas con pérdidas se conservan: son parte del análisis comercial. Una futura inconsistencia debe revisarse en raw antes de excluir o corregir datos; no se imputan identificadores ni se sustituyen valores inválidos por cero.

West lidera por ganancia y Central presenta la menor ganancia y margen acumulados; South tiene las menores ventas. RFM usa la fecha máxima del archivo y cuenta órdenes únicas. Los quintiles se desempatan por ID; a igual recencia/frecuencia puede haber scores distintos cerca del corte. Se identificaron 105 clientes de alto valor y 121 en riesgo.

En productos, volumen significa unidades y menor rentabilidad significa menor margen; el resultado también identifica las mayores pérdidas absolutas. Los descuentos mayores al 50% coinciden con pérdidas en las 856 líneas del rango. Esta asociación descriptiva no demuestra causalidad.

Las tendencias abarcan 48 meses consecutivos. La media móvil contiene hasta tres meses; los dos primeros tienen ventanas incompletas explícitas. Las variaciones sin antecedente quedan NULL. El 80% de las ventas requiere 414 de 1.862 productos; el 80% de la ganancia neta requiere 164. Las pérdidas pueden llevar el Pareto neto por encima de 100% antes del descenso final; se conserva una sensibilidad con ganancias positivas para contextualizarlo.

## Optimización y límites

Se usa ORC con Snappy, conversiones al cargar y agregación previa a ventanas. La auditoría de NULL usa una sola agregación y STACK. `resolver.sh` calcula estadísticas y guarda un EXPLAIN del filtro de fecha y agregación regional. No se particiona este dataset pequeño para evitar archivos diminutos.

Las consultas se ejecutan con MapReduce local para reproducibilidad. Los tres DataNodes almacenan HDFS; esta ejecución no mide procesamiento distribuido ni demuestra escalabilidad. No se afirma una mejora de rendimiento sin un benchmark controlado. Los totales, métricas RFM, rankings, ventanas y Pareto se contrastaron de forma independiente con el CSV usando aritmética decimal.

## Acceso y persistencia

- Hive JDBC: `jdbc:hive2://localhost:11000`.
- HDFS: http://localhost:19870
- YARN: http://localhost:18088

```bash
docker compose exec master beeline -u jdbc:hive2://localhost:10000 -n root
docker compose stop
docker compose start
```

Compose usa el proyecto `examen-superstore-bonny`, red 172.30.0.0/16 y volúmenes propios. `docker compose down` conserva datos; `docker compose down -v` elimina los volúmenes. Hive no tiene autenticación de producción y PostgreSQL usa la contraseña de ejemplo de la imagen: es un laboratorio local.

La imagen deriva de `panovvv/hadoop-hive-spark:2.5.2` y agrega dependencias Tez 0.9.1 verificadas con SHA-256. No necesita archivos de otro proyecto del equipo.

## Diagnóstico

```bash
docker compose ps
docker compose logs --tail=100 master hivemetastore worker1 worker2 worker3
docker compose exec master hdfs dfsadmin -report
docker compose exec master hdfs dfsadmin -safemode get
```

Si Hive rechaza la conexión, esperar a que termine de iniciar y comprobar sus logs. Revisar puertos ocupados o conflictos de subred antes de cambiar Compose. Conservar los volúmenes al diagnosticar. Las comprobaciones de salud verifican los puertos locales de Hive, HDFS y DataNodes.

Referencias: [CSV SerDe](https://hive.apache.org/docs/latest/user/csv-serde/), [ventanas analíticas](https://hive.apache.org/docs/latest/language/languagemanual-windowingandanalytics/), [exportación Beeline](https://hive.apache.org/docs/latest/user/hiveserver2-clients/).
