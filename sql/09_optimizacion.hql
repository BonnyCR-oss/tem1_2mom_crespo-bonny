USE examen_superstore;
ANALYZE TABLE superstore COMPUTE STATISTICS;
ANALYZE TABLE superstore COMPUTE STATISTICS FOR COLUMNS;
EXPLAIN SELECT region,SUM(sales),SUM(profit) FROM superstore WHERE order_date>='2017-01-01' GROUP BY region;
