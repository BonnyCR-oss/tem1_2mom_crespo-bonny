USE examen_superstore;
DROP TABLE IF EXISTS p05_productos;
CREATE TABLE p05_productos STORED AS ORC AS
WITH a AS (
 SELECT product_id,MAX(product_name) AS product_name,category,
 SUM(sales) AS ventas,SUM(profit) AS ganancias,SUM(quantity) AS unidades
 FROM superstore GROUP BY product_id,category
), b AS (SELECT *,100.0*ganancias/ventas AS margen FROM a)
SELECT *,ROUND(margen,4) AS margen_pct,
 RANK() OVER(PARTITION BY category ORDER BY ganancias DESC) AS rank_ganancia_categoria,
 DENSE_RANK() OVER(PARTITION BY category ORDER BY ganancias DESC) AS dense_rank_categoria,
 ROW_NUMBER() OVER(PARTITION BY category ORDER BY ganancias DESC,product_id) AS top5_categoria,
 ROW_NUMBER() OVER(ORDER BY unidades DESC,product_id) AS top5_volumen,
 RANK() OVER(ORDER BY unidades DESC) AS rank_volumen,
 ROW_NUMBER() OVER(ORDER BY margen ASC,product_id) AS top5_menor_margen,
 ROW_NUMBER() OVER(ORDER BY ganancias ASC,product_id) AS top5_mayor_perdida,
 SUM(ganancias) OVER(PARTITION BY category ORDER BY ganancias DESC,product_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ganancia_acumulada_categoria
FROM b;
SELECT * FROM p05_productos ORDER BY category,top5_categoria;
