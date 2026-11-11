USE examen_superstore;
-- Dos capas: CSV fiel al origen y tabla tipada ORC. Restricciones auditadas en P2.
CREATE TABLE IF NOT EXISTS superstore_raw (
  row_id STRING,
  order_id STRING,
  order_date STRING,
  ship_date STRING,
  ship_mode STRING,
  customer_id STRING,
  customer_name STRING,
  segment STRING,
  country STRING,
  city STRING,
  state STRING,
  postal_code STRING,
  region STRING,
  product_id STRING,
  category STRING,
  sub_category STRING,
  product_name STRING,
  sales STRING,
  quantity STRING,
  discount STRING,
  profit STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar'=',', 'quoteChar'='"', 'escapeChar'='\\')
STORED AS TEXTFILE TBLPROPERTIES ('skip.header.line.count'='1');
CREATE TABLE IF NOT EXISTS superstore (
  row_id INT,
  order_id STRING,
  order_date DATE,
  ship_date DATE,
  ship_mode STRING,
  customer_id STRING,
  customer_name STRING,
  segment STRING,
  country STRING,
  city STRING,
  state STRING,
  postal_code STRING,
  region STRING,
  product_id STRING,
  category STRING,
  sub_category STRING,
  product_name STRING,
  sales DECIMAL(18,4),
  quantity INT,
  discount DECIMAL(8,4),
  profit DECIMAL(18,4)
)
STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY');
