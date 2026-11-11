USE examen_superstore;
DROP TABLE IF EXISTS p08_pareto;
CREATE TABLE p08_pareto STORED AS ORC AS
WITH a AS (
 SELECT product_id,MAX(product_name) AS product_name,SUM(sales) AS ventas,SUM(profit) AS ganancias FROM superstore GROUP BY product_id
), b AS (
 SELECT 'ventas' AS analisis,product_id,product_name,CAST(ventas AS DECIMAL(24,4)) AS contribucion FROM a
 UNION ALL SELECT 'ganancia_neta',product_id,product_name,CAST(ganancias AS DECIMAL(24,4)) FROM a
 UNION ALL SELECT 'ganancia_positiva_sensibilidad',product_id,product_name,CAST(ganancias AS DECIMAL(24,4)) FROM a WHERE ganancias>0
), c AS (
 SELECT *,SUM(contribucion) OVER(PARTITION BY analisis) AS total,
 COUNT(*) OVER(PARTITION BY analisis) AS productos_total,
 ROW_NUMBER() OVER(PARTITION BY analisis ORDER BY contribucion DESC,product_id) AS posicion,
 SUM(contribucion) OVER(PARTITION BY analisis ORDER BY contribucion DESC,product_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acumulado FROM b
)
SELECT *,ROUND(100.0*contribucion/total,6) AS participacion_pct,
ROUND(100.0*acumulado/total,6) AS acumulado_pct,
CASE WHEN total>0 AND acumulado-contribucion<0.8*total THEN 1 ELSE 0 END AS incluido_hasta_80
FROM c;
DROP TABLE IF EXISTS p08_resumen;
CREATE TABLE p08_resumen STORED AS ORC AS
WITH k AS (SELECT analisis,MIN(posicion) AS cantidad_productos FROM p08_pareto WHERE acumulado>=0.8*total AND total>0 GROUP BY analisis)
SELECT p.analisis,k.cantidad_productos,p.productos_total,
 ROUND(100.0*k.cantidad_productos/p.productos_total,4) AS productos_pct,
 p.total,p.acumulado,p.acumulado_pct FROM p08_pareto p JOIN k ON p.analisis=k.analisis AND p.posicion=k.cantidad_productos;
SELECT p.*,r.cantidad_productos AS productos_para_80,r.productos_pct AS productos_para_80_pct FROM p08_pareto p JOIN p08_resumen r ON p.analisis=r.analisis ORDER BY p.analisis,p.posicion;
