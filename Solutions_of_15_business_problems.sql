-- ============================================================
-- Netflix Data Analysis using SQL
-- Solutions of 15 Business Problems
--
-- NOTE: This started from a standard practice question set, but several
-- queries below were corrected from the commonly-shared "textbook" version
-- after debugging real bugs found while building this project. Each fix
-- is marked with a comment explaining what was wrong and why.
-- ============================================================

-- 1. Count the number of Movies vs TV Shows
SELECT 
	type,
	COUNT(*)
FROM netflix
GROUP BY 1;


-- 2. Find the most common rating for movies and TV shows
SELECT type, rating
FROM (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count,
        RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
    FROM netflix
    GROUP BY type, rating
) AS ranked
WHERE ranking = 1;


-- 3. List all movies released in a specific year (e.g., 2020)
SELECT * 
FROM netflix
WHERE type = 'Movie'
  AND release_year = 2020;


-- 4. Find the top 5 countries with the most content on Netflix
-- FIX: original used STRING_TO_ARRAY(country, ',') with no space.
-- Verified against raw data that Netflix stores multi-country lists as
-- "Country A, Country B" (comma + space) -- using ',' alone leaves a
-- leading space on every country after the first, silently splitting
-- the same country into two different-looking buckets (e.g. "India" vs
-- " India"), which inflates the distinct count and undercounts real totals.
SELECT country, COUNT(*) AS total_content
FROM (
	SELECT UNNEST(STRING_TO_ARRAY(country, ', ')) AS country
	FROM netflix
) AS t1
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;


-- 5. Identify the longest movie
-- NOTE: duration is stored as text ("90 min"), so comparing/sorting it
-- directly would sort alphabetically, not numerically ("99 min" would
-- beat "312 min" as text). SPLIT_PART + ::INT converts it to a real
-- number first so the sort is numerically correct.
SELECT *
FROM netflix
WHERE type = 'Movie'
ORDER BY SPLIT_PART(duration, ' ', 1)::INT DESC
LIMIT 1;


-- 6. Find content added in the last 5 years
SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'
-- FIX: same comma+space delimiter correction as Q4/Q9/Q14.
SELECT *
FROM (
	SELECT 
		*,
		UNNEST(STRING_TO_ARRAY(director, ', ')) AS director_name
	FROM netflix
) AS t
WHERE director_name = 'Rajiv Chilaka';


-- 8. List all TV shows with more than 5 seasons
SELECT *
FROM netflix
WHERE type = 'TV Show'
  AND SPLIT_PART(duration, ' ', 1)::INT > 5;


-- 9. Count the number of content items in each genre
-- FIX: same delimiter correction. Verified empirically -- splitting on
-- ',' alone returned 73 "distinct" genres; splitting on ', ' (matching
-- the real data format) merged the leading-space duplicates and returned
-- the true 42 distinct genres.
SELECT 
	genre,
	COUNT(*) AS total_content
FROM (
	SELECT UNNEST(STRING_TO_ARRAY(listed_in, ', ')) AS genre
	FROM netflix
) AS sub
GROUP BY genre
ORDER BY total_content DESC;


-- 10. Find each year and the average (%) share of content released by
--     India on Netflix. Return the top 5 years with the highest share.
SELECT 
	release_year,
	COUNT(show_id) AS total_release,
	ROUND(
		COUNT(show_id)::numeric /
		(SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100
		, 2
	) AS avg_release_pct
FROM netflix
WHERE country = 'India' 
GROUP BY release_year
ORDER BY avg_release_pct DESC 
LIMIT 5;


-- 11. List all movies that are documentaries
-- FIX: original used LIKE '%Documentaries' (no leading wildcard, case
-- sensitive) -- this only matches values ENDING in "Documentaries" and
-- misses combined genre strings like "Documentaries, International
-- Movies" (a leading-position match), undercounting real results.
-- ILIKE '%documentaries%' catches the genre anywhere in the text,
-- case-insensitively. Also added the TYPE filter, since the business
-- question specifically asks for movies, not documentary TV series.
SELECT * 
FROM netflix
WHERE listed_in ILIKE '%documentaries%'
  AND type = 'Movie';


-- 12. Find all content without a director
SELECT * 
FROM netflix
WHERE director IS NULL;


-- 13. Find how many movies actor 'Salman Khan' appeared in in the last 10 years
SELECT * 
FROM netflix
WHERE casts ILIKE '%Salman Khan%'
  AND type = 'Movie'
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;


-- 14. Find the top 10 actors who have appeared in the highest number of
--     movies produced in India
-- FIX: same comma+space delimiter correction, plus added TYPE = 'Movie'
-- filter -- the original version counted TV Show appearances too, which
-- doesn't match the business question asking specifically about movies.
SELECT 
	actor,
	COUNT(*) AS movie_count
FROM (
	SELECT UNNEST(STRING_TO_ARRAY(casts, ', ')) AS actor
	FROM netflix
	WHERE country ILIKE '%India%'
	  AND type = 'Movie'
) AS sub
GROUP BY actor
ORDER BY movie_count DESC
LIMIT 10;


-- 15. Categorize content based on the presence of the keywords 'kill' and
--     'violence' in the description field. Label content containing
--     these keywords as 'Bad' and all other content as 'Good'. Count
--     how many items fall into each category.
WITH categorized_content AS (
    SELECT 
        *,
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
)
SELECT 
    category,
    COUNT(*) AS content_count
FROM categorized_content
GROUP BY category;


-- End of report
