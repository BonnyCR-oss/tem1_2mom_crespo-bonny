USE examen_superstore;
SELECT * FROM p07_tendencias WHERE puesto_mayor_venta<=3 OR puesto_menor_venta<=3 ORDER BY ventas DESC;
