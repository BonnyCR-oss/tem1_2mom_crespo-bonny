USE examen_superstore;
-- OVERWRITE permite repetir sin duplicar. El original local se conserva.
LOAD DATA LOCAL INPATH '/data/datos/Sample-Superstore-utf8.csv'
OVERWRITE INTO TABLE superstore_raw;
INSERT OVERWRITE TABLE superstore
SELECT
  CAST(trim(row_id) AS INT) AS row_id,
  CASE WHEN trim(order_id) = '' THEN NULL ELSE trim(order_id) END AS order_id,
  CAST(from_unixtime(unix_timestamp(trim(order_date), 'M/d/yyyy')) AS DATE) AS order_date,
  CAST(from_unixtime(unix_timestamp(trim(ship_date), 'M/d/yyyy')) AS DATE) AS ship_date,
  CASE WHEN trim(ship_mode) = '' THEN NULL ELSE trim(ship_mode) END AS ship_mode,
  CASE WHEN trim(customer_id) = '' THEN NULL ELSE trim(customer_id) END AS customer_id,
  CASE WHEN trim(customer_name) = '' THEN NULL ELSE trim(customer_name) END AS customer_name,
  CASE WHEN trim(segment) = '' THEN NULL ELSE trim(segment) END AS segment,
  CASE WHEN trim(country) = '' THEN NULL ELSE trim(country) END AS country,
  CASE WHEN trim(city) = '' THEN NULL ELSE trim(city) END AS city,
  CASE WHEN trim(state) = '' THEN NULL ELSE trim(state) END AS state,
  CASE WHEN trim(postal_code) = '' THEN NULL ELSE trim(postal_code) END AS postal_code,
  CASE WHEN trim(region) = '' THEN NULL ELSE trim(region) END AS region,
  CASE WHEN trim(product_id) = '' THEN NULL ELSE trim(product_id) END AS product_id,
  CASE WHEN trim(category) = '' THEN NULL ELSE trim(category) END AS category,
  CASE WHEN trim(sub_category) = '' THEN NULL ELSE trim(sub_category) END AS sub_category,
  CASE WHEN trim(product_name) = '' THEN NULL ELSE trim(product_name) END AS product_name,
  CAST(trim(sales) AS DECIMAL(18,4)) AS sales,
  CAST(trim(quantity) AS INT) AS quantity,
  CAST(trim(discount) AS DECIMAL(8,4)) AS discount,
  CAST(trim(profit) AS DECIMAL(18,4)) AS profit
FROM superstore_raw;
DROP TABLE IF EXISTS p01_carga;
CREATE TABLE p01_carga STORED AS ORC AS
SELECT COUNT(*) AS registros, COUNT(DISTINCT row_id) AS filas_unicas,
 COUNT(DISTINCT order_id) AS ordenes, COUNT(DISTINCT customer_id) AS clientes,
 MIN(order_date) AS primera_fecha, MAX(order_date) AS ultima_fecha,
 SUM(sales) AS ventas, SUM(profit) AS ganancias FROM superstore;
SELECT * FROM p01_carga;
