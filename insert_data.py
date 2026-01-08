import sqlite3
import csv
import gzip
from tqdm import tqdm
import os
import sys

DB_PATH = "imdb.sqlite"
DATA_PATH = ""

def open_tsv(path):
    if path.endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8")
    return open(path, "r", encoding="utf-8")

def clean(value):
    return None if value == "\\N" else value

def split_array(value):
    if value in (None, "", "\\N"):
        return []
    return value.split(",")

csv.field_size_limit(sys.maxsize)

# Borrar BD anterior si existe
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

#################################
# PRAGMAS (velocidad)
#################################
cur.executescript("""
PRAGMA foreign_keys = OFF;
PRAGMA synchronous = OFF;
PRAGMA journal_mode = MEMORY;
PRAGMA temp_store = MEMORY;
""")

#################################
# CREACIÓN DE TABLAS
#################################
with open('01_schema.sql', 'r') as file:
    sql_script = file.read()
    cur.executescript(sql_script)

conn.commit()

print("Las tablas se han creado correctamente.")

#################################
# CARGA title.basics + genres
#################################
print("Cargando titles...")
with open_tsv(DATA_PATH + "data/title.basics.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        cur.execute("""
            INSERT OR IGNORE INTO FACT_TITLES
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            row["tconst"],
            row["titleType"],
            row["primaryTitle"],
            row["originalTitle"],
            int(row["isAdult"]),
            clean(row["startYear"]),
            clean(row["endYear"]),
            clean(row["runtimeMinutes"])
        ))

        if row["genres"] != "\\N":
            # print(row['genres'])
            for g in split_array(row["genres"]):
                cur.execute("INSERT OR IGNORE INTO DIM_GENRES(name) VALUES (?)", (g,))
                cur.execute("""
                    INSERT OR IGNORE INTO DIM_TITLE_GENRES
                    SELECT ?, genre_id FROM DIM_GENRES WHERE name = ?
                """, (row["tconst"], g))

conn.commit()

#################################
# CARGA name.basics
#################################
print("Cargando names...")
with open_tsv(DATA_PATH + "data/name.basics.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        cur.execute("""
            INSERT OR IGNORE INTO FACT_NAMES
            VALUES (?, ?, ?, ?)
        """, (
            row["nconst"],
            row["primaryName"],
            clean(row["birthYear"]),
            clean(row["deathYear"])
        ))

        if row["primaryProfession"] != "\\N":
            for p in split_array(row["primaryProfession"]):
                cur.execute("INSERT OR IGNORE INTO DIM_PROFESSIONS(name) VALUES (?)", (p,))
                cur.execute("""
                    INSERT OR IGNORE INTO DIM_NAME_PROFESSIONS
                    SELECT ?, profession_id FROM DIM_PROFESSIONS WHERE name = ?
                """, (row["nconst"], p))

        if row["knownForTitles"] != "\\N":
            for t in split_array(row["knownForTitles"]):
                cur.execute("""
                    INSERT OR IGNORE INTO DIM_KNOWN_FOR_TITLES
                    VALUES (?, ?)
                """, (row["nconst"], t))

conn.commit()

#################################
# CARGA title.akas
#################################
print("Cargando akas...")
with open_tsv(DATA_PATH + "data/title.akas.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        cur.execute("""
            INSERT INTO DIM_TITLE_AKAS
            (tconst, ordering, title, region, language, is_original_title)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            row["titleId"],
            row["ordering"],
            row["title"],
            clean(row["region"]),
            clean(row["language"]),
            int(row["isOriginalTitle"])
        ))
        akas_id = cur.lastrowid

        if row["types"] != "\\N":
            for t in split_array(row["types"]):
                cur.execute("INSERT OR IGNORE INTO DIM_AKAS_TYPES(name) VALUES (?)", (t,))
                cur.execute("""
                    INSERT OR IGNORE INTO DIM_TITLE_AKAS_TYPES
                    SELECT ?, type_id FROM DIM_AKAS_TYPES WHERE name = ?
                """, (akas_id, t))

        if row["attributes"] != "\\N":
            for a in split_array(row["attributes"]):
                cur.execute("INSERT OR IGNORE INTO DIM_AKAS_ATTRIBUTES(name) VALUES (?)", (a,))
                cur.execute("""
                    INSERT OR IGNORE INTO DIM_TITLE_AKAS_ATTRIBUTES
                    SELECT ?, attribute_id FROM DIM_AKAS_ATTRIBUTES WHERE name = ?
                """, (akas_id, a))

conn.commit()

#################################
# CARGA episodes
#################################
print("Cargando episodes...")
with open_tsv(DATA_PATH + "data/title.episode.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        cur.execute("""
            INSERT OR IGNORE INTO DIM_EPISODES
            VALUES (?, ?, ?, ?)
        """, (
            row["tconst"],
            row["parentTconst"],
            clean(row["seasonNumber"]),
            clean(row["episodeNumber"])
        ))

conn.commit()

#################################
# CARGA crew
#################################
print("Cargando crew...")
with open_tsv(DATA_PATH + "data/title.crew.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        if row["directors"] != "\\N":
            for d in split_array(row["directors"]):
                cur.execute("INSERT OR IGNORE INTO DIM_TITLE_DIRECTORS VALUES (?, ?)", (row["tconst"], d))
        if row["writers"] != "\\N":
            for w in split_array(row["writers"]):
                cur.execute("INSERT OR IGNORE INTO DIM_TITLE_WRITERS VALUES (?, ?)", (row["tconst"], w))

conn.commit()

#################################
# CARGA principals
#################################
print("Cargando principals...")
with open_tsv(DATA_PATH + "data/title.principals.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        cur.execute("""
            INSERT INTO DIM_TITLE_PRINCIPALS
            (tconst, ordering, nconst, category, job, characters)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            row["tconst"],
            row["ordering"],
            row["nconst"],
            row["category"],
            clean(row["job"]),
            clean(row["characters"])
        ))

conn.commit()

#################################
# CARGA ratings
#################################
print("Cargando ratings...")
with open_tsv(DATA_PATH + "data/title.ratings.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in tqdm(reader):
        cur.execute("""
            INSERT OR REPLACE INTO DIM_TITLE_RATINGS
            VALUES (?, ?, ?)
        """, (
            row["tconst"],
            row["averageRating"],
            row["numVotes"]
        ))

conn.commit()

cur.execute("PRAGMA foreign_keys = ON;")
conn.close()

print("✅ Base de datos IMDb creada y cargada")
