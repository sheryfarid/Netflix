
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
	show_id	VARCHAR(6),
	type    VARCHAR(10),
	title	VARCHAR(150),
	director VARCHAR(550),
	casts	VARCHAR(1050),
	country	VARCHAR(550),
	date_added	VARCHAR(55),
	release_year	INT,
	rating	VARCHAR(15),
	duration	VARCHAR(15),
	listed_in	VARCHAR(250),
	description VARCHAR(550)
);

select count(*) from netflix
-- How many shows are there by type? 
select type , count(*) as type_count from netflix
group by type order by type_count desc

-- What are the top 5 genres listed on Netflix?
with genre_exploaded AS 
(SELECT unnest(string_to_array(listed_in, ', ')) AS genre  FROM netflix) , 
genre_count as ( select genre , count(*) as total_count from genre_exploaded group by genre order by total_count desc limit 5)
select * from genre_count

-- How has the number of shows released changed over the years?
-- What are the peak years for content addition?
SELECT EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year, COUNT(*) AS show_count
FROM netflix 
WHERE date_added IS NOT NULL
GROUP BY year  ORDER BY show_count desc  ;

-- Which months typically see the most content being added?
SELECT TO_CHAR(TO_DATE(date_added, 'Month DD, YYYY'), 'Month') AS month_name,COUNT(*) AS show_count
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(MONTH FROM TO_DATE(date_added, 'Month DD, YYYY')),
         TO_CHAR(TO_DATE(date_added, 'Month DD, YYYY'), 'Month')
ORDER BY EXTRACT(MONTH FROM TO_DATE(date_added, 'Month DD, YYYY')) desc;

-- Who are the top 10 most frequent directors on Netflix?
select director , count(*) as show_conduct from netflix 
where director is not null
group by director order by show_conduct desc  limit 10

-- Which actors/actresses appear most frequently in Netflix content?
with cast_exploaded as (SELECT unnest(string_to_array(casts, ', ')) AS actors  FROM netflix) ,
cast_count as (select actors , count(*) as show_count from cast_exploaded group by actors order by show_count desc )
select * from cast_count

-- What is the distribution of content ratings  on Netflix?
select rating , count(*)from netflix where rating is not null group by rating order by 2 desc;

-- What is the average duration of movies and TV shows?
SELECT 
    CASE 
        WHEN duration LIKE '%Season%' THEN 'TV Show'
        ELSE 'Movie'
    END AS content_type,
    Round(AVG(CASE 
        WHEN duration LIKE '%Season%' THEN CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) -- Average number of seasons
        ELSE CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) -- Average duration in minutes
    END),2) AS average_duration
FROM 
    netflix
GROUP BY 
    content_type;

-- Which countries have contributed the most content to Netflix?
with country_exploaded as (SELECT unnest(string_to_array(country, ', ')) AS country  FROM netflix) ,
cuntry_count as (select country , count(*) as show_count from country_exploaded group by country order by show_count desc limit 5 )
select * from cuntry_count; 

-- Are there any genres that are particularly popular in certain countries?
WITH genre_counts AS (
    SELECT 
        country, 
        unnest(string_to_array(listed_in, ', ')) AS genre,
        COUNT(*) AS genre_count
    FROM 
        netflix
    WHERE 
        country IS NOT NULL
    GROUP BY 
        country, genre
),
max_genre_per_country AS (
    SELECT 
        country,
        genre,
        genre_count,
        RANK() OVER (PARTITION BY country ORDER BY genre_count DESC) AS rank
    FROM 
        genre_counts
)
SELECT 
    country, 
    genre AS top_genre, 
    genre_count
FROM 
    max_genre_per_country
WHERE 
    rank = 1
ORDER BY 
    genre_count desc limit 5;

-- How many shows have been added to Netflix in the last year?
SELECT COUNT(*) AS shows_added_in_2021 FROM  netflix
WHERE EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) = 2021;

-- What is the distribution of these shows by type and genre?
WITH genre_totals AS (
    SELECT 
        CASE 
            WHEN duration LIKE '%Season%' THEN 'TV Show'
            ELSE 'Movie'
        END AS content_type,
        unnest(string_to_array(listed_in, ', ')) AS genre,
        COUNT(*) AS genre_count
    FROM  netflix  GROUP BY  content_type, genre
),
ranked_genres AS (
    SELECT  content_type, genre,genre_count,
    ROW_NUMBER() OVER (PARTITION BY content_type ORDER BY genre_count DESC) AS genre_rank
    FROM  genre_totals
)
SELECT  content_type, genre,genre_count
FROM  ranked_genres
WHERE  genre_rank <= 3 -- Select only the top 3 genres per content type
ORDER BY content_type, genre_count DESC;

-- What are the top genres in each release year on Netflix?
WITH GenreCounts AS (
    SELECT
        release_year,
        listed_in as genre,
        COUNT(*) AS genre_count
    FROM
        netflix
    GROUP BY
        release_year,
        genre
)
SELECT
    release_year,
    genre,
    genre_count
FROM
    GenreCounts g1
WHERE
    genre_count = (
        SELECT MAX(genre_count)
        FROM GenreCounts g2
        WHERE g2.release_year = g1.release_year
    )
ORDER BY
 genre_count DESC limit 5 ;

-- to remove ',' from country from start
select distinct country from netflix where country like ',%'
SELECT DISTINCT country, 
       LTRIM(country, ',') AS trimmed_country
FROM netflix;

UPDATE netflix
SET country = LTRIM(country, ',')
where country like  ',%';


