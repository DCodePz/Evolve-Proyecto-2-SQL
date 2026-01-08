-- =========================================================
-- 1. Exploración general
-- =========================================================
SELECT COUNT(*) AS total_titles
FROM FACT_TITLES;


SELECT
    title_type,
    COUNT(*) AS total_titles
FROM FACT_TITLES
GROUP BY title_type
ORDER BY total_titles DESC;

-- Insight:
-- Permite identificar si el dataset está dominado por películas, series o episodios.


-- =========================================================
-- 2. Análisis temporal
-- =========================================================
SELECT
    start_year,
    COUNT(*) AS titles_released
FROM FACT_TITLES
WHERE start_year IS NOT NULL
GROUP BY start_year
ORDER BY start_year;

-- Insight
-- Detecta picos de producción audiovisual y posibles sesgos temporales del dataset.


-- =========================================================
-- 3. JOIN: títulos por género
-- =========================================================
SELECT
    g.name AS genre,
    COUNT(DISTINCT tg.tconst) AS total_titles
FROM DIM_GENRES g
INNER JOIN DIM_TITLE_GENRES tg
    ON g.genre_id = tg.genre_id
GROUP BY g.name
ORDER BY total_titles DESC;

-- Insight
-- Identifica los géneros dominantes del catálogo (útil para estrategia de contenidos o recomendaciones).


-- =========================================================
-- 4. LEFT JOIN: títulos sin rating
-- =========================================================
SELECT
    t.tconst,
    t.primary_title,
    t.start_year
FROM FACT_TITLES t
LEFT JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst
WHERE r.tconst IS NULL
LIMIT 20;

-- Insight
-- Detecta títulos con baja exposición o recién estrenados.


-- =========================================================
-- 5. Métricas agregadas de ratings
-- =========================================================
SELECT
    t.title_type,
    ROUND(AVG(r.average_rating), 2) AS avg_rating,
    SUM(r.num_votes) AS total_votes
FROM FACT_TITLES t
INNER JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst
GROUP BY t.title_type
ORDER BY avg_rating DESC;

-- Insight
-- Permite comparar la calidad percibida entre películas, series y episodios.


-- =========================================================
-- 6. CASE: segmentación por popularidad
-- =========================================================
SELECT
    t.primary_title,
    r.average_rating,
    r.num_votes,
    CASE
        WHEN r.num_votes >= 100000 THEN 'Muy popular'
        WHEN r.num_votes BETWEEN 10000 AND 99999 THEN 'Popular'
        ELSE 'Nicho'
    END AS popularity_segment
FROM FACT_TITLES t
INNER JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst
ORDER BY r.num_votes DESC;

-- Insight
-- Segmentación útil para marketing o promoción.


-- =========================================================
-- 7. CTE simple
-- =========================================================
WITH high_rated_titles AS (
    SELECT
        tconst
    FROM DIM_TITLE_RATINGS
    WHERE average_rating >= 8
)
SELECT COUNT(*) AS total_high_rated_titles
FROM high_rated_titles;

-- Insight
-- Cuantifica el “top tier” del catálogo.


-- =========================================================
-- 8. CTE encadenadas
-- =========================================================
WITH high_rated_titles AS (
    SELECT tconst
    FROM DIM_TITLE_RATINGS
    WHERE average_rating >= 8
),
director_titles AS (
    SELECT
        d.nconst,
        COUNT(*) AS total_titles
    FROM DIM_TITLE_DIRECTORS d
    INNER JOIN high_rated_titles h
        ON d.tconst = h.tconst
    GROUP BY d.nconst
)
SELECT
    n.primary_name,
    dt.total_titles
FROM director_titles dt
INNER JOIN FACT_NAMES n
    ON dt.nconst = n.nconst
ORDER BY dt.total_titles DESC
LIMIT 10;

-- Insight
-- Identifica directores con mayor impacto en títulos de alta calidad.


-- =========================================================
-- 9. Funciones ventana
-- =========================================================
SELECT
    t.title_type,
    t.primary_title,
    r.average_rating,
    RANK() OVER (
        PARTITION BY t.title_type
        ORDER BY r.average_rating DESC
    ) AS ranking_within_type
FROM FACT_TITLES t
INNER JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst
WHERE r.num_votes >= 10000;

-- Insight
-- Permite rankings comparables dentro de cada categoría (películas vs series).


-- =========================================================
-- 10. Subquery
-- =========================================================
SELECT
    t.primary_title,
    r.average_rating
FROM FACT_TITLES t
INNER JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst
WHERE r.average_rating >
    (SELECT AVG(average_rating) FROM DIM_TITLE_RATINGS)
ORDER BY r.average_rating DESC;

-- Insight
-- Detecta títulos “above average” para destacar en catálogos.


-- =========================================================
-- 11. Función ventana + Subquery
-- =========================================================
SELECT *
FROM (
    SELECT
        t.title_type,
        t.primary_title,
        r.average_rating,
        RANK() OVER (
            PARTITION BY t.title_type
            ORDER BY r.average_rating DESC
        ) AS ranking_within_type
    FROM FACT_TITLES t
    INNER JOIN DIM_TITLE_RATINGS r
        ON t.tconst = r.tconst
    WHERE r.num_votes >= 10000
) sub
WHERE ranking_within_type = 1;

-- Insight
-- Devuelve los mejores titulos de cada tipo.


-- =========================================================
-- RESULTADO FINAL
-- Vista ejecutiva para toma de decisiones
-- =========================================================
-- Agrupa los títulos por tipo de contenido y calcula:
-- - Volumen de títulos
-- - Rating medio
-- - Total de votos (engagement)
-- =========================================================

DROP IF EXISTS vw_business_title_summary;
CREATE VIEW IF NOT EXISTS vw_business_title_summary AS
SELECT
    t.title_type                                   AS content_type,
    COUNT(DISTINCT t.tconst)                       AS total_titles,
    COUNT(r.tconst)                                AS titles_with_rating,
    ROUND(AVG(r.average_rating), 2)                AS avg_rating,
    SUM(r.num_votes)                               AS total_votes
FROM FACT_TITLES t
LEFT JOIN DIM_TITLE_RATINGS r
    ON t.tconst = r.tconst
GROUP BY t.title_type;

SELECT *
FROM vw_business_title_summary
ORDER BY avg_rating DESC;

-- content_type: Tipo de título (movie, tvSeries, tvEpisode, etc.)
-- total_titles: Volumen total de contenido disponible
-- titles_with_rating: Títulos con suficiente exposición
-- avg_rating: Calidad media percibida por los usuarios
-- total_votes: Nivel de engagement / popularidad

/* Decisiones de negocio que permite tomar
 * Priorización de inversión
 * Si un tipo de contenido tiene alto rating medio, indica mayor calidad percibida.
 * Útil para decidir en qué formato producir o adquirir más contenido.
 *
 * Estrategia de catálogo
 * Comparar volumen vs calidad:
 * Mucho contenido pero bajo rating → posible saturación.
 * Poco contenido pero alto rating → oportunidad de expansión.
 *
 * Marketing y promoción
 * Tipos con muchos votos → alto engagement.
 * Ideales para campañas de visibilidad o posicionamiento.
 *
 * Optimización del portafolio
 * Detectar tipos con:
 * Bajo rating
 * Bajo engagement → candidatos a despriorizar o revisar calidad.
 */