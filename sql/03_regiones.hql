USE examen_superstore;
DROP TABLE IF EXISTS p03_regiones;
CREATE TABLE p03_regiones STORED AS ORC AS
WITH anual AS (
 SELECT region, YEAR(order_date) AS anio, SUM(sales) AS ventas, SUM(profit) AS ganancias
 FROM superstore GROUP BY region,YEAR(order_date)
), anterior AS (
 SELECT *, LAG(ventas) OVER(PARTITION BY region ORDER BY anio) AS ventas_previas,
 LAG(ganancias) OVER(PARTITION BY region ORDER BY anio) AS ganancias_previas FROM anual
)
SELECT *, ROUND(100.0*ganancias/ventas,4) AS margen_pct,
 CASE WHEN ventas_previas<>0 THEN ROUND(100.0*(ventas-ventas_previas)/ABS(ventas_previas),4) END AS variacion_ventas_pct,
 CASE WHEN ganancias_previas<>0 THEN ROUND(100.0*(ganancias-ganancias_previas)/ABS(ganancias_previas),4) END AS variacion_ganancias_pct,
 RANK() OVER(PARTITION BY anio ORDER BY ganancias DESC) AS puesto_ganancia_anual
FROM anterior;
DROP TABLE IF EXISTS p03_desempeno;
CREATE TABLE p03_desempeno STORED AS ORC AS
WITH r AS (SELECT region, SUM(ventas) AS ventas, SUM(ganancias) AS ganancias FROM p03_regiones GROUP BY region)
SELECT *, ROUND(100.0*ganancias/ventas,4) AS margen_pct,
RANK() OVER(ORDER BY ganancias DESC) AS puesto_ganancia,
RANK() OVER(ORDER BY ventas DESC) AS puesto_ventas FROM r;
SELECT * FROM p03_regiones ORDER BY region,anio;
