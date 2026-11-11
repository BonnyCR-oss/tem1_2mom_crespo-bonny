# Dataset

Fuente: [Superstore Dataset, Vivek468, Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final).

`./scripts/resolver.sh` descarga automáticamente el ZIP público cuando falta el CSV. Extrae únicamente `Sample - Superstore.csv` y lo guarda como `datos/Sample-Superstore.csv`; comprueba SHA-256 antes de guardarlo. La versión usada contiene 9.994 registros y 21 campos, y fue verificada el 11 de noviembre de 2026.

SHA-256 del original: `58fb59c63089e564d835e4aabe19d371757de1137a5bf1888243ae386c4b7a97`.

Alternativa manual: descargar el ZIP desde Kaggle, descomprimirlo y guardar ese CSV con el nombre indicado. El script prepara la copia UTF-8 sin modificar el original. Consultar la licencia vigente en la ficha de Kaggle antes de redistribuir el dataset. Los CSV no se suben a Git.
