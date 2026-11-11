USE examen_superstore;
DROP TABLE IF EXISTS p04_rfm;
CREATE TABLE p04_rfm STORED AS ORC AS
WITH ref AS (SELECT MAX(order_date) AS fecha_referencia FROM superstore),
a AS (
 SELECT customer_id, MAX(customer_name) AS customer_name, MAX(order_date) AS ultima_compra,
 COUNT(DISTINCT order_id) AS frequency, SUM(sales) AS monetary
 FROM superstore GROUP BY customer_id
), b AS (SELECT a.*,ref.fecha_referencia,DATEDIFF(ref.fecha_referencia,a.ultima_compra) AS recency FROM a CROSS JOIN ref),
c AS (SELECT *,
 6-NTILE(5) OVER(ORDER BY recency ASC,customer_id) AS r_score,
 NTILE(5) OVER(ORDER BY frequency ASC,customer_id) AS f_score,
 NTILE(5) OVER(ORDER BY monetary ASC,customer_id) AS m_score FROM b)
SELECT *,CONCAT(CAST(r_score AS STRING),CAST(f_score AS STRING),CAST(m_score AS STRING)) AS codigo_rfm,
 CASE WHEN r_score<=2 AND (f_score>=4 OR m_score>=4) THEN 'En riesgo'
 WHEN r_score>=4 AND f_score>=4 AND m_score>=4 THEN 'Alto valor'
 WHEN f_score>=4 THEN 'Recurrentes'
 WHEN r_score>=4 AND f_score<=2 THEN 'Recientes poco frecuentes'
 ELSE 'Otros' END AS segmento_rfm FROM c;
SELECT * FROM p04_rfm ORDER BY monetary DESC,customer_id;
