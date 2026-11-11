USE examen_superstore;
DROP TABLE IF EXISTS p02_nulos;
CREATE TABLE p02_nulos STORED AS ORC AS
SELECT stack(21,
'row_id', n_row_id,
'order_id', n_order_id,
'order_date', n_order_date,
'ship_date', n_ship_date,
'ship_mode', n_ship_mode,
'customer_id', n_customer_id,
'customer_name', n_customer_name,
'segment', n_segment,
'country', n_country,
'city', n_city,
'state', n_state,
'postal_code', n_postal_code,
'region', n_region,
'product_id', n_product_id,
'category', n_category,
'sub_category', n_sub_category,
'product_name', n_product_name,
'sales', n_sales,
'quantity', n_quantity,
'discount', n_discount,
'profit', n_profit) AS (campo,nulos)
FROM (SELECT
SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS n_row_id,
SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS n_order_id,
SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS n_order_date,
SUM(CASE WHEN ship_date IS NULL THEN 1 ELSE 0 END) AS n_ship_date,
SUM(CASE WHEN ship_mode IS NULL THEN 1 ELSE 0 END) AS n_ship_mode,
SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS n_customer_id,
SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS n_customer_name,
SUM(CASE WHEN segment IS NULL THEN 1 ELSE 0 END) AS n_segment,
SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS n_country,
SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS n_city,
SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS n_state,
SUM(CASE WHEN postal_code IS NULL THEN 1 ELSE 0 END) AS n_postal_code,
SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS n_region,
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS n_product_id,
SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS n_category,
SUM(CASE WHEN sub_category IS NULL THEN 1 ELSE 0 END) AS n_sub_category,
SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS n_product_name,
SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS n_sales,
SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS n_quantity,
SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS n_discount,
SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS n_profit
FROM superstore) a;
DROP TABLE IF EXISTS p02_resumen;
CREATE TABLE p02_resumen STORED AS ORC AS
WITH d AS (SELECT row_id, COUNT(*) AS n FROM superstore GROUP BY row_id HAVING COUNT(*)>1),
a AS (SELECT COUNT(*) AS identificadores_duplicados, COALESCE(SUM(n-1),0) AS filas_duplicadas_excedentes FROM d)
SELECT COUNT(*) AS registros, COUNT(DISTINCT s.order_id) AS ordenes_unicas,
 COUNT(DISTINCT s.customer_id) AS clientes_unicos,
 MAX(a.identificadores_duplicados) AS identificadores_duplicados,
 MAX(a.filas_duplicadas_excedentes) AS filas_duplicadas_excedentes,
 SUM(CASE WHEN s.order_date IS NULL OR s.ship_date IS NULL THEN 1 ELSE 0 END) AS fechas_invalidas,
 SUM(CASE WHEN s.ship_date<s.order_date THEN 1 ELSE 0 END) AS envio_anterior_pedido,
 SUM(CASE WHEN s.sales<=0 THEN 1 ELSE 0 END) AS ventas_no_positivas,
 SUM(CASE WHEN s.discount<0 OR s.discount>1 THEN 1 ELSE 0 END) AS descuentos_fuera_rango,
 SUM(CASE WHEN s.quantity<=0 THEN 1 ELSE 0 END) AS cantidades_no_positivas,
 SUM(CASE WHEN s.profit<0 THEN 1 ELSE 0 END) AS lineas_con_perdida
FROM superstore s CROSS JOIN a;
SELECT * FROM p02_resumen;
