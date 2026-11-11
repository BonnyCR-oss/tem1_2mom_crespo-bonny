-- Prueba de infraestructura; no es una respuesta del examen.
-- Verifica metastore, escritura ORC en HDFS y lectura mediante Hive.
CREATE DATABASE IF NOT EXISTS examen_superstore;
CREATE TABLE IF NOT EXISTS examen_superstore.__prueba_entorno (
  id INT,
  mensaje STRING
) STORED AS ORC;
INSERT OVERWRITE TABLE examen_superstore.__prueba_entorno
SELECT 1, 'Hive y HDFS operativos';
SELECT * FROM examen_superstore.__prueba_entorno;
DROP TABLE examen_superstore.__prueba_entorno;
