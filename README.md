# 📊 **Evolve – Proyecto 2: Diseño de BBDDs Relacionales (EDA)**
![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat-square)
![SQL](https://img.shields.io/badge/SQL-Database-orange?style=flat-square)
![Status](https://img.shields.io/badge/Status-En%20desarrollo-yellow?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)

---

## 🧪 **Descripción**

Este proyecto consiste en realizar un **Diseño, implementación y análisis exploratorio (EDA)** de una **base de datos relacional**, con 2 **tablas de hechos** y 15 **tablas de dimensiones**.

El objetivo principal es:
- Construir un **modelo normalizado**.
- Garantizar la **integradad de los datos**.
- Extraer **insight de negocio relevantes** utilizando SQL

El proyecto simula un entorno realista, permitiendo practicar diseño de bases de datos, carga de datos, limpieza y análisis analítico mediante SQL.

---

## 📁 **Estructura del repositorio**

**[`01_schema.sql`](01_schema.sql)**
Creación de la tablas, vistas e índices, y sus restricciones.

**[`02_data.sql`](02_data.sql)**
Updates y Deletes para garantizar la integridad de los datos, y pruebas de SQL para demostrar conocimientos adquiridos (Subquery, funciones ventana, etc.)

**[`03_eda.sql`](03_eda.sql)**
Análisis Exploratorio de los Datos de la base de datos. JOINs, CTEs, etc.

**[`insert_data.py`](insert_data.py)**
Programa encargado de normalizar los ficheros, procesando los datos e insertandolos en la base de datos correctamente.

---

## 🚀 **Cómo ejecutar el proyecto**

1. Clonar el repositorio:

```bash
git clone https://github.com/tu_usuario/tu_repositorio_sql.git
cd tu_repositorio_sql
```

2. Descarga de los datos:
Debido al gran tamaño de los datos hay que descargarlos directamente dentro desde la página oficial de IMDB:
[Dataset](https://datasets.imdbws.com)

Descargar los ficheros y extraer el fichero `.tsv`. Para que funcione correctamente, guardar los ficheros dentro de la carpeta [`/data`](./data).

3. Crear y cargar base de datos:
Crear un fichero llamado `imdb.sqlite` y ejecuta el fichero [`insert_data.py`](insert_data.py):

```bash
# Crear un entorno virtual
python3 -m venv venv

# Activar el entorno virtual
source venv/bin/activate

# Actualizar pip (opcional pero recomendado)
pip install --upgrade pip

# Instalar dependencias desde requirements.txt
pip install -r requirements.txt

# Crear el fichero vacío de la base de datos
touch imdb.sqlite

# Ejecutar el script de Python
python3 insert_data.py
```







