USE examen_superstore;
DROP TABLE IF EXISTS p07_tendencias;
CREATE TABLE p07_tendencias STORED AS ORC AS
WITH m AS (
 SELECT CAST(trunc(order_date,'MM') AS DATE) AS mes,SUM(sales) AS ventas,SUM(profit) AS ganancias
 FROM superstore GROUP BY CAST(trunc(order_date,'MM') AS DATE)
), b AS (
 SELECT m.*, LAG(ventas) OVER(ORDER BY mes) AS ventas_mes_anterior,
 LAG(ganancias) OVER(ORDER BY mes) AS ganancias_mes_anterior,
 LAG(mes) OVER(ORDER BY mes) AS mes_anterior,
 AVG(ventas) OVER(ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movil_ventas_3m,
 AVG(ganancias) OVER(ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movil_ganancias_3m,
 COUNT(*) OVER(ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS meses_ventana
 FROM m
)
SELECT b.*, y.ventas AS ventas_mismo_mes_anterior_anio,y.ganancias AS ganancias_mismo_mes_anterior_anio,
 CASE WHEN b.mes=add_months(b.mes_anterior,1) AND b.ventas_mes_anterior<>0 THEN ROUND(100.0*(b.ventas-b.ventas_mes_anterior)/ABS(b.ventas_mes_anterior),4) END AS variacion_mensual_ventas_pct,
 CASE WHEN b.mes=add_months(b.mes_anterior,1) AND b.ganancias_mes_anterior<>0 THEN ROUND(100.0*(b.ganancias-b.ganancias_mes_anterior)/ABS(b.ganancias_mes_anterior),4) END AS variacion_mensual_ganancias_pct,
 CASE WHEN y.ventas<>0 THEN ROUND(100.0*(b.ventas-y.ventas)/ABS(y.ventas),4) END AS variacion_interanual_ventas_pct,
 CASE WHEN y.ganancias<>0 THEN ROUND(100.0*(b.ganancias-y.ganancias)/ABS(y.ganancias),4) END AS variacion_interanual_ganancias_pct,
 ROW_NUMBER() OVER(ORDER BY b.ventas DESC,b.mes) AS puesto_mayor_venta,
 ROW_NUMBER() OVER(ORDER BY b.ventas ASC,b.mes) AS puesto_menor_venta
FROM b LEFT JOIN m y ON y.mes=add_months(b.mes,-12);
SELECT * FROM p07_tendencias ORDER BY mes;
