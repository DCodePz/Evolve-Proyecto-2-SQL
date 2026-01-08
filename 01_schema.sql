-- =========================================================
-- TABLA FACT_TITLES
-- Tabla de hechos principal que representa títulos audiovisuales
-- Granularidad: 1 fila = 1 título audiovisual único
-- =========================================================
DROP TABLE IF EXISTS FACT_TITLES;
CREATE TABLE IF NOT EXISTS FACT_TITLES (
    tconst TEXT PRIMARY KEY,                    					-- Identificador único IMDB
    title_type TEXT NOT NULL,                   					-- movie, tvSeries, tvEpisode, etc.
    primary_title TEXT NOT NULL,
    original_title TEXT NOT NULL,
    is_adult INTEGER NOT NULL DEFAULT 0 CHECK (is_adult IN (0,1)),	-- 0 no es, 1 si es
    start_year INTEGER CHECK (start_year >= 1800),   				
    end_year INTEGER CHECK (end_year >= start_year),				-- Año en que termina no puede ser anterior al aña en que empieza
    runtime_minutes INTEGER CHECK (runtime_minutes > 0)  			-- No puede durar tiempo negativo
);

-- =========================================================
-- DIM_GENRES
-- Catálogo de géneros
-- Granularidad: 1 fila = 1 género único
-- =========================================================
DROP TABLE IF EXISTS DIM_GENRES;
CREATE TABLE IF NOT EXISTS DIM_GENRES (
    genre_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE					-- Evita repetición de géneros
);

-- =========================================================
-- RELACIÓN N:M entre títulos y géneros
-- Granularidad: 1 fila = 1 relación título - género
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_GENRES;
CREATE TABLE IF NOT EXISTS DIM_TITLE_GENRES (
    tconst TEXT NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (tconst, genre_id),
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst),
    FOREIGN KEY (genre_id) REFERENCES DIM_GENRES(genre_id)
);

-- =========================================================
-- DIM_TITLE_AKAS
-- Títulos alternativos por región/idioma
-- Granularidad: 1 fila = 1 título alternativo de un audiovisual
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_AKAS;
CREATE TABLE IF NOT EXISTS DIM_TITLE_AKAS (
    akas_id INTEGER PRIMARY KEY AUTOINCREMENT,
    tconst TEXT NOT NULL,
    ordering INTEGER NOT NULL CHECK (ordering > 0),
    title TEXT NOT NULL,
    region TEXT,
    language TEXT,
    is_original_title INTEGER NOT NULL DEFAULT 0 CHECK (is_original_title IN (0,1)), -- 0 no es, 1 si es
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst)
);

-- =========================================================
-- DIM_AKAS_TYPES
-- Catálogo de tipos de títulos alternativos
-- Granularidad: 1 fila = 1 tipo de título alternativo
-- =========================================================
DROP TABLE IF EXISTS DIM_AKAS_TYPES;
CREATE TABLE IF NOT EXISTS DIM_AKAS_TYPES (
    type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE					-- Evita repetición de tipos
);

-- =========================================================
-- Relación N:M entre AKAS y tipos
-- Granularidad: 1 fila = 1 relación tipo título alterativo - título alternativo
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_AKAS_TYPES;
CREATE TABLE IF NOT EXISTS DIM_TITLE_AKAS_TYPES (
    akas_id INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    PRIMARY KEY (akas_id, type_id),
    FOREIGN KEY (akas_id) REFERENCES DIM_TITLE_AKAS(akas_id),
    FOREIGN KEY (type_id) REFERENCES DIM_AKAS_TYPES(type_id)
);

-- =========================================================
-- DIM_AKAS_ATTRIBUTES
-- Catálogo de atributos (DVD title, short title, etc.)
-- Granularidad: 1 fila = 1 atributo único
-- =========================================================
DROP TABLE IF EXISTS DIM_AKAS_ATTRIBUTES;
CREATE TABLE IF NOT EXISTS DIM_AKAS_ATTRIBUTES (
    attribute_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE						-- Evita repetición de atributos
);

-- =========================================================
-- Relación N:M entre AKAS y atributos
-- Granularidad: 1 fila = 1 relación de título alternativo - atributo
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_AKAS_ATTRIBUTES;
CREATE TABLE IF NOT EXISTS DIM_TITLE_AKAS_ATTRIBUTES (
    akas_id INTEGER NOT NULL,
    attribute_id INTEGER NOT NULL,
    PRIMARY KEY (akas_id, attribute_id),
    FOREIGN KEY (akas_id) REFERENCES DIM_TITLE_AKAS(akas_id),
    FOREIGN KEY (attribute_id) REFERENCES DIM_AKAS_ATTRIBUTES(attribute_id)
);

-- =========================================================
-- DIM_EPISODES
-- Manejo de jerarquía serie → episodio
-- Granularidad: 1 fila = 1 episocio de una serie
-- =========================================================
DROP TABLE IF EXISTS DIM_EPISODES;
CREATE TABLE IF NOT EXISTS DIM_EPISODES (
    tconst TEXT PRIMARY KEY,
    parent_tconst TEXT NOT NULL,
    season_number INTEGER CHECK (season_number > 0),			-- Número de temporada no puede ser negativo
    episode_number INTEGER CHECK (episode_number > 0),			-- Número de episodio no puede ser negativo
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst),
    FOREIGN KEY (parent_tconst) REFERENCES FACT_TITLES(tconst)
);

-- =========================================================
-- FACT_NAMES
-- Personas (actores, directores, escritores, etc.)
-- Granularidad: 1 fila = 1 persona única
-- =========================================================
DROP TABLE IF EXISTS FACT_NAMES;
CREATE TABLE IF NOT EXISTS FACT_NAMES (
    nconst TEXT PRIMARY KEY,
    primary_name TEXT NOT NULL,
    birth_year INTEGER CHECK (birth_year >= 1800),
    death_year INTEGER CHECK (death_year >= birth_year)	-- Año de fallecimiento no puede ser anterior al año de nacimiento
);

-- =========================================================
-- DIM_PROFESSIONS
-- Catálogo de profesiones
-- Granularidad: 1 fila = 1 profesión
-- =========================================================
DROP TABLE IF EXISTS DIM_PROFESSIONS;
CREATE TABLE IF NOT EXISTS DIM_PROFESSIONS (
    profession_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE							-- Evita repetición de profesiones
);

-- =========================================================
-- Relación N:M entre personas y profesiones
-- Granularidad: 1 fila = 1 relación persona - profesión
-- =========================================================
DROP TABLE IF EXISTS DIM_NAME_PROFESSIONS;
CREATE TABLE IF NOT EXISTS DIM_NAME_PROFESSIONS (
    nconst TEXT NOT NULL,
    profession_id INTEGER NOT NULL,
    PRIMARY KEY (nconst, profession_id),
    FOREIGN KEY (nconst) REFERENCES FACT_NAMES(nconst),
    FOREIGN KEY (profession_id) REFERENCES DIM_PROFESSIONS(profession_id)
);

-- =========================================================
-- DIM_KNOWN_FOR_TITLES
-- Relación N:M personas ↔ títulos conocidos
-- Granularidad: 1 fila = 1 relación persona - título
-- =========================================================
DROP TABLE IF EXISTS DIM_KNOWN_FOR_TITLES;
CREATE TABLE IF NOT EXISTS DIM_KNOWN_FOR_TITLES (
    nconst TEXT NOT NULL,
    tconst TEXT NOT NULL,
    PRIMARY KEY (nconst, tconst),
    FOREIGN KEY (nconst) REFERENCES FACT_NAMES(nconst),
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst)
);

-- =========================================================
-- DIM_TITLE_DIRECTORS
-- Relación N:M título ↔ directores
-- Granularidad: 1 fila = 1 relación persona - título
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_DIRECTORS;
CREATE TABLE IF NOT EXISTS DIM_TITLE_DIRECTORS (
    tconst TEXT NOT NULL,
    nconst TEXT NOT NULL,
    PRIMARY KEY (tconst, nconst),
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst),
    FOREIGN KEY (nconst) REFERENCES FACT_NAMES(nconst)
);

-- =========================================================
-- DIM_TITLE_WRITERS
-- Relación N:M título ↔ guionistas
-- Granularidad: 1 fila = 1 relación persona - título
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_WRITERS;
CREATE TABLE IF NOT EXISTS DIM_TITLE_WRITERS (
    tconst TEXT NOT NULL,
    nconst TEXT NOT NULL,
    PRIMARY KEY (tconst, nconst),
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst),
    FOREIGN KEY (nconst) REFERENCES FACT_NAMES(nconst)
);

-- =========================================================
-- DIM_TITLE_PRINCIPALS
-- Personas que participan en un título (cast & crew principal)
-- Granularidad: 1 fila = 1 relación persona - título
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_PRINCIPALS;
CREATE TABLE IF NOT EXISTS DIM_TITLE_PRINCIPALS (
    principal_id INTEGER PRIMARY KEY AUTOINCREMENT,
    tconst TEXT NOT NULL,
    ordering INTEGER NOT NULL CHECK (ordering > 0),
    nconst TEXT NOT NULL,
    category TEXT NOT NULL,          						-- actor, actress, director, producer, etc.
    job TEXT,                        						-- rol específico (opcional)
    characters TEXT,                 						-- personajes interpretados
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst),
    FOREIGN KEY (nconst) REFERENCES FACT_NAMES(nconst),
    UNIQUE (tconst, ordering)        						-- Evita duplicados en el orden de créditos
);

-- =========================================================
-- DIM_TITLE_RATINGS
-- Métricas agregadas del título
-- Granularidad: 1 fila = 1 ranking para un título
-- =========================================================
DROP TABLE IF EXISTS DIM_TITLE_RATINGS;
CREATE TABLE IF NOT EXISTS DIM_TITLE_RATINGS (
    tconst TEXT PRIMARY KEY,
    average_rating REAL NOT NULL CHECK (average_rating BETWEEN 0 AND 10),	-- Limita la valoraciones a valores entre 0 y 10
    num_votes INTEGER NOT NULL CHECK (num_votes >= 0),						-- No puede tener valoraciones negativas
    FOREIGN KEY (tconst) REFERENCES FACT_TITLES(tconst)
);





-- =========================================================
-- ÍNDICES
-- =========================================================

-- Índice para búsquedas temporales y por tipo de título
-- Cuando se busca, se suelen colocar filtros tipo: "WHERE title_type = 'movie' AND start_year >= 2010"
DROP INDEX IF EXISTS idx_fact_titles_type_year;
CREATE INDEX idx_fact_titles_type_year
ON FACT_TITLES (title_type, start_year);

-- Índice para el JOIN típico de títulos y sus géneros
DROP INDEX IF EXISTS idx_title_genres_tconst;
CREATE INDEX idx_title_genres_tconst
ON DIM_TITLE_GENRES (tconst);

-- Índice JOIN frecuente entre títulos y ratings
DROP INDEX IF EXISTS idx_title_ratings_tconst;
CREATE INDEX IF NOT EXISTS idx_title_ratings_tconst
ON DIM_TITLE_RATINGS (tconst);

-- Índice para búsquedas por género
-- Útil para conteos o rankings por género
DROP INDEX IF EXISTS idx_title_genres_genre;
CREATE INDEX IF NOT EXISTS idx_title_genres_genre
ON DIM_TITLE_GENRES (genre_id);





-- =========================================================
-- VIEWS
-- =========================================================

-- Vista con la información báse de un título
-- Base para la mayoría de los análisis
DROP VIEW IF EXISTS vw_titles_base;
CREATE VIEW IF NOT EXISTS vw_titles_base AS
SELECT
    t.tconst,
    t.primary_title,
    t.title_type,
    t.start_year,
    t.runtime_minutes,
    r.average_rating,
    r.num_votes
FROM FACT_TITLES t
LEFT JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst;

-- Vista de personal en títulos
-- Agrupa a todo el personal en una misma consulta
DROP VIEW IF EXISTS vw_persons_title_roles;
CREATE VIEW IF NOT EXISTS vw_persons_title_roles AS
SELECT
    p.nconst,
    p.primary_name,
    tp.category,
    tp.job,
    t.primary_title,
    t.title_type,
    t.start_year
FROM DIM_TITLE_PRINCIPALS tp
JOIN FACT_NAMES p ON tp.nconst = p.nconst
JOIN FACT_TITLES t ON tp.tconst = t.tconst;


