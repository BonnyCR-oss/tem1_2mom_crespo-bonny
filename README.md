# Análisis de Superstore con Apache Hive

Proyecto individual del segundo momento de Tecnologías Emergentes I.
Autor: Bonny Alberto Crespo Romero.

El objetivo es cargar Sample Superstore, auditar su calidad y resolver los ocho análisis del examen con HiveQL. Este repositorio incluye un entorno Docker propio para que el docente pueda reproducir el trabajo.

## Requisitos

- Docker Engine o Docker Desktop con Docker Compose v2.
- Linux con Bash, `timeout` y `realpath` para utilizar los scripts auxiliares.
- Internet para descargar imágenes, dependencias y dataset.
- Recursos disponibles para un master Hadoop/Hive, tres workers y PostgreSQL. Si se ejecuta también otro laboratorio, comprobar memoria disponible.

## Arranque desde cero

1. Clonar este repositorio y entrar en su carpeta.
2. Ejecutar:

```bash
./scripts/iniciar.sh
./scripts/ejecutar.sh sql/00_verificar_entorno.hql
```

La primera orden construye la imagen y espera una respuesta de Hive. La segunda verifica creación de tabla, escritura ORC en HDFS y lectura; debe mostrar `1,Hive y HDFS operativos`. Si falla, revisar el error antes de cargar el dataset.

La imagen se basa en el laboratorio previo (`panovvv/hadoop-hive-spark:2.5.2`) y agrega seis dependencias Apache Tez 0.9.1 desde Maven Central, verificadas con SHA-256. No requiere archivos de otro proyecto del equipo. Las consultas se configuran con MapReduce local, adecuado para este dataset pequeño; no se está midiendo ejecución distribuida de consultas.

## Acceso y persistencia

- Hive JDBC desde el anfitrión: `jdbc:hive2://localhost:11000`.
- HDFS: http://localhost:19870
- YARN: http://localhost:18088
- Dentro del contenedor master, Hive conserva su puerto 10000.

Abrir consola Hive:

```bash
docker compose exec master beeline -u jdbc:hive2://localhost:10000 -n root
```

Apagar y volver a arrancar conservando los datos:

```bash
docker compose stop
docker compose start
```

El proyecto Compose `examen-superstore-bonny` utiliza volúmenes propios para PostgreSQL y HDFS, una red 172.30.0.0/16 y puertos de anfitrión distintos al laboratorio anterior. `docker compose down` conserva los volúmenes; `docker compose down -v` los elimina. El entorno es de laboratorio local: PostgreSQL usa la contraseña de ejemplo que espera la imagen base y Hive no tiene autenticación de producción.

## Dataset y scripts del examen

Fuente e instrucciones: [datos/README.md](datos/README.md).

Descargar el CSV, inspeccionar su estructura y guardarlo como `datos/Sample-Superstore.csv`. El CSV no se incluye en Git. Desde HiveServer2 estará disponible como `/data/datos/Sample-Superstore.csv`.

Las carpetas se comparten automáticamente:

| Carpeta del repositorio | Ruta del contenedor |
|---|---|
| `datos/` | `/data/datos/` (lectura) |
| `sql/` | `/data/sql/` (lectura) |
| `resultados/` | `/data/resultados/` |

Por ejemplo, la carga a la futura tabla raw usará:

```sql
LOAD DATA LOCAL INPATH '/data/datos/Sample-Superstore.csv'
OVERWRITE INTO TABLE examen_superstore.superstore_raw;
```

Primero hay que crear esa tabla. Los scripts de solución se añadirán durante el examen en este orden:

1. `sql/01_modelo.hql` y `sql/01_carga.hql`.
2. `sql/02_calidad.hql`.
3. `sql/03_regiones.hql`.
4. `sql/04_rfm.hql`.
5. `sql/05_productos.hql`.
6. `sql/06_descuentos.hql`.
7. `sql/07_tendencias.hql`.
8. `sql/08_pareto.hql`.

Ejecutar cada archivo con `./scripts/ejecutar.sh sql/NOMBRE.hql`. Para exportar una consulta que devuelva una sola tabla:

```bash
./scripts/ejecutar.sh sql/03_regiones.hql > resultados/p03.csv 2> evidencias/p03.stderr.txt
```

Ese archivo de regiones todavía debe desarrollarse. Comprobar el código de salida y los mensajes de error antes de aceptar un CSV como evidencia.

## Documentación de la entrega

Guardar diccionario, decisiones de calidad, interpretación, optimización y conclusiones en `docs/`; resultados en `resultados/` y capturas en `evidencias/`. Registrar avances reales mediante commits durante el examen.

Se versionan Dockerfile, Compose, configuración, scripts y documentación. Los datos internos de los contenedores, JAR descargados y CSV no se suben al repositorio.

## Si falla el entorno

```bash
docker compose ps
docker compose logs --tail=100 master hivemetastore worker1 worker2 worker3
docker compose exec master hdfs dfsadmin -report
docker compose exec master hdfs dfsadmin -safemode get
```

- `permission denied` al socket: comprobar acceso de la sesión al daemon Docker.
- `Connection refused`: revisar logs del master y PostgreSQL, y volver a comprobar cuando Hive termine de iniciar.
- Error descargando dependencias: revisar conexión a Maven Central y repetir `docker compose build`. No omitir la verificación de integridad.
- Puerto ocupado: cambiar el puerto de anfitrión a la izquierda del mapeo y actualizar la URL correspondiente.
- Conflicto de subred: reemplazar 172.30 por una subred libre de forma consistente en todo Compose.
- HDFS sin nodos o en safe mode: revisar los workers; conservar los volúmenes mientras se diagnostica.

## Estado de validación

Validado el 11 de noviembre de 2026: configuración Compose, sintaxis Bash y ejecución real de `sql/00_verificar_entorno.hql`. La prueba creó una tabla ORC en HDFS, insertó y leyó `1,Hive y HDFS operativos`, y eliminó solamente esa tabla de prueba. Salida y mensajes en `evidencias/00_verificar_entorno.csv` y `evidencias/00_verificar_entorno.stderr.txt`.

El primer intento de conexión ocurrió antes de que HiveServer2 terminara de iniciar. Las comprobaciones de salud ahora consultan los puertos locales de Hive/HDFS y de cada DataNode, en lugar del chequeo heredado de la imagen base. La tabla de prueba se llama `prueba_entorno` para respetar la sintaxis de identificadores de Hive.

Las consultas del examen todavía deben desarrollarse.

Referencias: [Dockerfile](https://docs.docker.com/reference/dockerfile/), [aislamiento de proyectos Compose](https://docs.docker.com/compose/how-tos/project-name/).
