-- =========================================================
-- UPDATE
-- =========================================================

-- Corregimos duraciones erróneas de "tvSeries" añadiendo un tiempo por defecto
UPDATE FACT_TITLES
SET runtime_minutes = 100
WHERE runtime_minutes IS NULL
  AND title_type = 'tvSeries';


-- =========================================================
-- DELETE
-- =========================================================

-- Eliminar títulos sin "start_year", no sirve para el análisis temporal
DELETE FROM FACT_TITLES 
WHERE start_year IS NULL;

-- =========================================================
-- CONVERSIÓN DE TIPOS (CAST)
-- =========================================================

-- Convertimos año a texto para reporting
SELECT
    primary_title,
    CAST(start_year AS TEXT) AS start_year_text
FROM FACT_TITLES;

-- Antigüedad del título (Años desde que se lanzó)
SELECT
    primary_title,
    CAST(strftime('%Y','now') AS INTEGER) - start_year AS years_since_release
FROM FACT_TITLES
WHERE start_year IS NOT NULL;


-- =========================================================
-- AGREGACIONES (COUNT, SUM, AVG)
-- =========================================================

-- Cantidad de títulos
SELECT COUNT(*) AS total_titles
FROM FACT_TITLES;

-- Promedio de duración
SELECT AVG(runtime_minutes) AS avg_runtime
FROM FACT_TITLES;

-- Total de votos acumulados
SELECT SUM(num_votes) AS total_votes
FROM DIM_TITLE_RATINGS;


-- =========================================================
-- SUBQUERY
-- =========================================================

-- Películas con rating superior al promedio
SELECT t.primary_title, r.average_rating
FROM FACT_TITLES t
JOIN DIM_TITLE_RATINGS r ON t.tconst = r.tconst
WHERE r.average_rating > (
    SELECT AVG(average_rating)
    FROM DIM_TITLE_RATINGS
);


-- =========================================================
-- TRANSACCIONES
-- =========================================================

-- Insertar un género nuevo (si no existe)
BEGIN TRANSACTION;
INSERT INTO DIM_GENRES (name)
VALUES ('Experimental');
COMMIT;

-- Insertar un nuevo título audiovisual
BEGIN TRANSACTION;
INSERT INTO FACT_TITLES (tconst, title_type, primary_title, original_title, start_year)
VALUES ('tt9999999', 'movie', 'Temp Movie', 'Temp Movie', 2025);
ROLLBACK; -- Error lógico simulado → revertimos

-- Verificamos que no quedó insertado
SELECT * FROM FACT_TITLES WHERE tconst = 'tt9999999';


