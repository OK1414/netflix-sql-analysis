# Netflix Movies and TV Shows — SQL Data Analysis
![Netflix Logo]()

A SQL (PostgreSQL) analysis of the Netflix titles dataset, working through
15 business questions from data exploration through to business insight.

*Question set adapted from the widely-used "Netflix SQL Project" practice
set (originally by [Zero Analyst](https://www.youtube.com/@zero_analyst));
all queries below were independently written, debugged, and corrected
while working through this project — see "Debugging notes" below for the
specific bugs found and fixed.*

## Overview

This project analyzes Netflix's movies and TV shows data using SQL to
extract insights and answer real business questions — content
distribution, ratings, genres, geography, and keyword-based
categorization.

## Objectives

- Analyze the distribution of content types (Movies vs TV Shows)
- Identify the most common ratings for movies and TV shows
- Analyze content by release year, country, genre, and duration
- Categorize content based on specific keyword criteria

## Dataset

- Source: [Kaggle — Netflix Movies and TV Shows](https://www.kaggle.com/datasets/shivamb/netflix-shows)
- ~8,800 rows, 12 columns

## Files

| File | Purpose |
|---|---|
| `Schemas.sql` | Table creation |
| `Business_Problems_Netflix.sql` | The 15 business questions |
| `Solutions_of_15_business_problems.sql` | Final, corrected SQL solutions |

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id       VARCHAR(5),
    type          VARCHAR(10),
    title         VARCHAR(250),
    director      VARCHAR(550),
    casts         VARCHAR(1050),
    country       VARCHAR(550),
    date_added    VARCHAR(55),
    release_year  INT,
    rating        VARCHAR(15),
    duration      VARCHAR(15),
    listed_in     VARCHAR(250),
    description   VARCHAR(550)
);
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT type, COUNT(*)
FROM netflix
GROUP BY 1;
```
**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```
**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT * 
FROM netflix
WHERE type = 'Movie'
  AND release_year = 2020;
```
**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
SELECT country, COUNT(*) AS total_content
FROM (
    SELECT UNNEST(STRING_TO_ARRAY(country, ', ')) AS country
    FROM netflix
) AS t1
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;
```
**Objective:** Identify the top 5 countries with the highest number of content items.
**Fixed:** split delimiter corrected from `','` to `', '` — see Debugging notes.

### 5. Identify the Longest Movie

```sql
SELECT *
FROM netflix
WHERE type = 'Movie'
ORDER BY SPLIT_PART(duration, ' ', 1)::INT DESC
LIMIT 1;
```
**Objective:** Find the movie with the longest duration.
**Note:** `duration` is stored as text (`"90 min"`), so it must be cast to
an integer before sorting — sorting the raw text would order values
alphabetically, not numerically.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';
```
**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT *
FROM (
    SELECT *, UNNEST(STRING_TO_ARRAY(director, ', ')) AS director_name
    FROM netflix
) AS t
WHERE director_name = 'Rajiv Chilaka';
```
**Objective:** List all content directed by 'Rajiv Chilaka'.
**Fixed:** same delimiter correction as Q4.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT *
FROM netflix
WHERE type = 'TV Show'
  AND SPLIT_PART(duration, ' ', 1)::INT > 5;
```
**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
SELECT genre, COUNT(*) AS total_content
FROM (
    SELECT UNNEST(STRING_TO_ARRAY(listed_in, ', ')) AS genre
    FROM netflix
) AS sub
GROUP BY genre
ORDER BY total_content DESC;
```
**Objective:** Count the number of content items in each genre.
**Fixed:** delimiter correction — this is the one that turned up the
73-vs-42 genre discrepancy documented below.

### 10. Find Each Year and the Average (%) Share of Content Released by India — Top 5 Years

```sql
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
```
**Objective:** Calculate and rank years by India's share of total content releases.

### 11. List All Movies that are Documentaries

```sql
SELECT * 
FROM netflix
WHERE listed_in ILIKE '%documentaries%'
  AND type = 'Movie';
```
**Objective:** Retrieve all movies classified as documentaries.
**Fixed:** `LIKE '%Documentaries'` (suffix-only match) → `ILIKE '%documentaries%'`
(matches anywhere, case-insensitive) + added `type = 'Movie'` filter — see
Debugging notes.

### 12. Find All Content Without a Director

```sql
SELECT * 
FROM netflix
WHERE director IS NULL;
```
**Objective:** List content that does not have a director credited.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT * 
FROM netflix
WHERE casts ILIKE '%Salman Khan%'
  AND type = 'Movie'
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;
```
**Objective:** Count movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors in the Highest Number of Movies Produced in India

```sql
SELECT actor, COUNT(*) AS movie_count
FROM (
    SELECT UNNEST(STRING_TO_ARRAY(casts, ', ')) AS actor
    FROM netflix
    WHERE country ILIKE '%India%'
      AND type = 'Movie'
) AS sub
GROUP BY actor
ORDER BY movie_count DESC
LIMIT 10;
```
**Objective:** Identify the top 10 actors with the most appearances in
Indian-produced movies.
**Fixed:** delimiter correction + added missing `type = 'Movie'` filter
(original counted TV Show appearances too).

### 15. Categorize Content Based on 'Kill' and 'Violence' Keywords

```sql
WITH categorized_content AS (
    SELECT *,
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
)
SELECT category, COUNT(*) AS content_count
FROM categorized_content
GROUP BY category;
```
**Objective:** Categorize content as 'Bad' if it contains 'kill' or
'violence' in the description, 'Good' otherwise, and count each category.

## Debugging notes — what I fixed and why

Working through this project turned up a few real bugs worth documenting,
since they're easy to miss and silently produce wrong numbers:

**1. Comma delimiter on multi-value columns (`country`, `listed_in`, `casts`, `director`)**
The raw data separates multi-value fields with `", "` (comma **+ space**),
not just `","`. Splitting on `","` alone leaves a leading space on every
value after the first, so the same real-world value gets counted as two
different "distinct" values (e.g. `"Comedies"` and `" Comedies"`).

- Genre count using `','` → 73 "distinct" genres (wrong — inflated by duplicates)
- Genre count using `', '` → 42 distinct genres (correct)
- Spot check: `"Comedies"` was split into `" Comedies"` (464) and `"Comedies"`
  (1210) under the buggy delimiter — the true count is 1674.

**2. Exact/suffix match vs partial match on multi-value text**
`WHERE listed_in LIKE '%Documentaries'` only matches strings *ending in*
`"Documentaries"` — it silently misses combined genre tags like
`"Documentaries, International Movies"`. Switched to
`ILIKE '%documentaries%'` (case-insensitive, matches anywhere in the
string) plus an explicit `type = 'Movie'` filter.

**3. Missing type filters**
The "top 10 actors in India-produced movies" question technically needs
`type = 'Movie'`, otherwise TV Show cast appearances get mixed into the
count — added that filter explicitly.

## Key Findings and Conclusion

- **Content Distribution:** Movies outnumber TV Shows roughly 2:1 in the catalog.
- **Common Ratings:** `TV-MA` is the most common rating for both Movies and TV Shows.
- **Genre Landscape:** the dataset has 42 true distinct genres once the
  delimiter is handled correctly (see Debugging notes).
- **Geographical Insights:** India-heavy release years and frequently
  appearing actors (e.g. Anupam Kher, Shah Rukh Khan) stand out clearly
  once the `country`/`casts` columns are split correctly.
- **Content Categorization:** content flagged as containing "kill" or
  "violence" in its description is a small minority of the overall catalog.

This analysis provides a comprehensive view of Netflix's content and the
kind of SQL debugging discipline needed to trust the numbers behind it.

## Tools

PostgreSQL (pgAdmin / DBeaver)

## Next Steps

Re-solving these same 15 questions in Python (pandas) for a direct
SQL-vs-pandas comparison, followed by light statistics and a Gen AI
project (natural-language-to-SQL) built on this dataset.
