USE examen_superstore;
CREATE OR REPLACE VIEW v_descuentos AS
SELECT *, CASE WHEN discount=0 THEN '0 Sin descuento'
 WHEN discount>0 AND discount<=0.2 THEN '1 Bajo (0,20%]'
 WHEN discount>0.2 AND discount<=0.5 THEN '2 Medio (20%,50%]'
 WHEN discount>0.5 AND discount<=1 THEN '3 Alto (50%,100%]'
 ELSE '4 Invalido' END AS rango_descuento FROM superstore;
DROP TABLE IF EXISTS p06_descuentos;
CREATE TABLE p06_descuentos STORED AS ORC AS
SELECT rango_descuento,COUNT(*) AS registros,SUM(sales) AS ventas,SUM(profit) AS ganancias,
ROUND(100.0*SUM(profit)/SUM(sales),4) AS margen_pct,
SUM(CASE WHEN profit<0 THEN 1 ELSE 0 END) AS registros_con_perdida,
ROUND(100.0*SUM(CASE WHEN profit<0 THEN 1 ELSE 0 END)/COUNT(*),4) AS no_rentables_pct,
ROUND(100.0*AVG(discount),4) AS descuento_promedio_pct
FROM v_descuentos GROUP BY rango_descuento;
DROP TABLE IF EXISTS p06_afectadas;
CREATE TABLE p06_afectadas STORED AS ORC AS
WITH a AS (
 SELECT 'categoria' AS nivel,category,CAST(NULL AS STRING) AS sub_category,rango_descuento,
 COUNT(*) AS registros,SUM(sales) AS ventas,SUM(profit) AS ganancias,
 SUM(CASE WHEN profit<0 THEN 1 ELSE 0 END) AS perdidas FROM v_descuentos GROUP BY category,rango_descuento
 UNION ALL
 SELECT 'subcategoria',category,sub_category,rango_descuento,COUNT(*),SUM(sales),SUM(profit),
 SUM(CASE WHEN profit<0 THEN 1 ELSE 0 END) FROM v_descuentos GROUP BY category,sub_category,rango_descuento
),b AS (SELECT *,ROUND(100.0*ganancias/ventas,4) AS margen_pct,ROUND(100.0*perdidas/registros,4) AS no_rentables_pct FROM a)
SELECT *,RANK() OVER(PARTITION BY nivel,rango_descuento ORDER BY ganancias ASC) AS puesto_afectacion FROM b;
SELECT * FROM p06_descuentos ORDER BY rango_descuento;
