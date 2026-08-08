# Netflix Movies and TV Shows — SQL Data Analysis

A SQL (PostgreSQL) analysis of the Netflix titles dataset, working through
15 business questions from data exploration through to business insight.

*Question set adapted from the widely-used "Netflix SQL Project" practice
set (originally by [Zero Analyst](https://www.youtube.com/@zero_analyst));
all queries below were independently written, debugged, and corrected
while working through this project.*

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
CREATE TABLE netflix (
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

**2. Exact match vs partial match on multi-value text**
`WHERE listed_in LIKE '%Documentaries'` only matches strings *ending in*
`"Documentaries"` — it silently misses combined genre tags like
`"Documentaries, International Movies"`. Switched to
`ILIKE '%documentaries%'` (case-insensitive, matches anywhere in the
string) plus an explicit `type = 'Movie'` filter, since the question asks
for movies specifically.

**3. Missing type filters**
The "top 10 actors in India-produced movies" question technically needs
`type = 'Movie'`, otherwise TV Show cast appearances get mixed into the
count — added that filter explicitly.

## Key findings

- Movies outnumber TV Shows by roughly 2:1 in the catalog.
- `TV-MA` is the most common rating for both Movies and TV Shows.
- The dataset has 42 true distinct genres (see delimiter fix above).
- India-heavy years and frequently-appearing actors (e.g. Anupam Kher,
  Shah Rukh Khan) stand out clearly once the country/cast columns are
  split correctly.
- Content flagged as containing "kill"/"violence" in its description is
  a small minority of the overall catalog.

## Tools

PostgreSQL (pgAdmin / DBeaver)

## Next steps

Re-solving these same 15 questions in Python (pandas) for a direct
SQL-vs-pandas comparison, followed by light statistics and a Gen AI
project (natural-language-to-SQL) built on this dataset.
