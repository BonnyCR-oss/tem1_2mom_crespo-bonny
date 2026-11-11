USE examen_superstore;
SELECT CASE WHEN top5_categoria<=5 THEN 'mayor_ganancia_categoria' END AS seleccion,p.* FROM p05_productos p WHERE top5_categoria<=5
UNION ALL SELECT 'mayor_volumen_unidades',p.* FROM p05_productos p WHERE top5_volumen<=5
UNION ALL SELECT 'menor_margen',p.* FROM p05_productos p WHERE top5_menor_margen<=5
UNION ALL SELECT 'mayor_perdida_absoluta',p.* FROM p05_productos p WHERE top5_mayor_perdida<=5;
