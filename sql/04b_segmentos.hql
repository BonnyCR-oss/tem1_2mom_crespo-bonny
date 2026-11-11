USE examen_superstore;
SELECT segmento_rfm,COUNT(*) AS clientes,SUM(monetary) AS ventas,
ROUND(AVG(recency),2) AS recency_promedio,ROUND(AVG(frequency),2) AS frecuencia_promedio
FROM p04_rfm GROUP BY segmento_rfm ORDER BY ventas DESC;
