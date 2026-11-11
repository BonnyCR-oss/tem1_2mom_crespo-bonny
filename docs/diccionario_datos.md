# Diccionario de datos

Grano: una línea de pedido, identificada por `row_id`. Un pedido contiene varias líneas; frecuencia usa órdenes distintas. Importes en USD según la ficha de la fuente. Los 21 campos raw se preservan como STRING; la capa analítica tiene estos tipos. Las restricciones son reglas auditadas, no constraints aplicados por Hive.

| CSV | Columna Hive | Tipo Hive | Descripción | Regla |
|---|---|---|---|---|
| Row ID | row_id | INT | Identificador de fila | Positivo y único |
| Order ID | order_id | STRING | Identificador del pedido | No vacío; puede repetirse en varias líneas |
| Order Date | order_date | DATE | Fecha del pedido | Original M/d/yyyy |
| Ship Date | ship_date | DATE | Fecha de envío | Igual o posterior al pedido |
| Ship Mode | ship_mode | STRING | Modalidad de envío | Categoría del archivo |
| Customer ID | customer_id | STRING | Identificador del cliente | No vacío |
| Customer Name | customer_name | STRING | Nombre del cliente | Texto |
| Segment | segment | STRING | Segmento de cliente | Categoría del archivo |
| Country | country | STRING | País | Texto |
| City | city | STRING | Ciudad | Texto |
| State | state | STRING | Estado | Texto |
| Postal Code | postal_code | STRING | Código postal | Texto para preservar ceros iniciales |
| Region | region | STRING | Región comercial | Categoría del archivo |
| Product ID | product_id | STRING | Identificador de producto | Clave de agregación de productos |
| Category | category | STRING | Categoría | Categoría del archivo |
| Sub-Category | sub_category | STRING | Subcategoría | Categoría del archivo |
| Product Name | product_name | STRING | Nombre del producto | Descriptivo; no usar como clave |
| Sales | sales | DECIMAL(18,4) | Importe de venta de la línea | Esperado > 0; USD |
| Quantity | quantity | INT | Unidades de la línea | Entero positivo |
| Discount | discount | DECIMAL(8,4) | Fracción de descuento | Entre 0 y 1 |
| Profit | profit | DECIMAL(18,4) | Ganancia de la línea | Puede ser negativa; USD |
