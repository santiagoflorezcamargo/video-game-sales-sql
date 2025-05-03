-- PROJECT: Video Game Sales Analysis
-- Author: Santiago A. Flórez Camargo
-- Date: April 2025

-- Database and table creation
DROP DATABASE IF EXISTS video_game_sales;
CREATE DATABASE IF NOT EXISTS video_game_sales;
USE video_game_sales;
DROP TABLE IF EXISTS vgsales;
CREATE TABLE IF NOT EXISTS vgsales (
	`rank` INT,
    `name` VARCHAR(300),
    platform VARCHAR(100),
    `year` SMALLINT,
    genre VARCHAR(100),
    publisher VARCHAR(100),
    north_america_sales DECIMAL(15, 5),
    europe_sales DECIMAL(15, 5),
    japan_sales DECIMAL(15, 5),
    other_sales DECIMAL(15, 5),
    global_sales DECIMAL(15, 5)
    );
    
SELECT * FROM vgsales LIMIT 10; -- Checking the contents of the table

-- Checking the total number of rows
SELECT count(*) FROM vgsales;

-- Checking for NULL values in any column
SELECT * FROM vgsales WHERE `rank`IS NULL OR `name` IS NULL OR platform IS NULL OR genre IS NULL OR publisher IS NULL OR north_america_sales IS NULL
OR europe_sales IS NULL OR japan_sales IS NULL OR other_sales IS NULL OR global_sales IS NULL;

-- Checking for duplicate values in the 'rank' column
SELECT `rank`, COUNT(`rank`) AS frequency FROM vgsales GROUP BY `rank` HAVING frequency > 1; 

-- Checking for inconsistencies in game names or other columns.
-- Example: "Super Mario Bros" vs. "Super Mario Bros."
SELECT DISTINCT(`name`) AS name_d FROM vgsales GROUP BY name_d ORDER BY name_d;
SELECT DISTINCT(platform) AS platform_d FROM vgsales GROUP BY platform_d ORDER BY platform_d;
SELECT DISTINCT(`year`) AS year_d FROM vgsales GROUP BY year_d ORDER BY year_d;
SELECT DISTINCT(genre) AS genre_d FROM vgsales GROUP BY genre_d ORDER BY genre_d;
SELECT DISTINCT(publisher) AS publisher_d FROM vgsales GROUP BY publisher_d ORDER BY publisher_d;

-- Setting the 'rank' column as the Primary Key
ALTER TABLE vgsales
ADD CONSTRAINT pk_vgsales PRIMARY KEY (`rank`);

-- Adding indexes to improve query performance
CREATE INDEX index_platform ON vgsales(platform);
CREATE INDEX index_year ON vgsales(`year`);
CREATE INDEX index_genre ON vgsales(genre);
CREATE INDEX index_publisher ON vgsales(publisher);


-- Maximum, minimum, average, standard deviation, and coefficient of variation of sales by region and globally.
SELECT "North_America" AS region, ROUND(MAX(north_america_sales), 2) AS max_sale, ROUND(MIN(north_america_sales), 2) AS min_sale, ROUND(AVG(north_america_sales), 4) AS average_sale, ROUND(STDDEV_POP(north_america_sales), 4) AS standard_desviation, ROUND((STDDEV_POP(north_america_sales)/AVG(north_america_sales))*100, 2) AS coefficient_of_variation FROM vgsales
	UNION
SELECT "Europe", ROUND(MAX(europe_sales), 2), ROUND(MIN(europe_sales), 2), ROUND(AVG(europe_sales), 4), ROUND(STDDEV_POP(europe_sales), 4), ROUND((STDDEV_POP(europe_sales)/AVG(europe_sales))*100, 2) FROM vgsales
	UNION
SELECT "Japan", ROUND(MAX(japan_sales), 2), ROUND(MIN(japan_sales), 2), ROUND(AVG(japan_sales), 4), ROUND(STDDEV_POP(japan_sales), 4), ROUND((STDDEV_POP(japan_sales)/AVG(japan_sales))*100, 2) FROM vgsales
	UNION 
SELECT "Others", ROUND(MAX(other_sales), 2), ROUND(MIN(other_sales), 2), ROUND(AVG(other_sales), 4), ROUND(STDDEV_POP(other_sales), 4), ROUND((STDDEV_POP(other_sales)/AVG(other_sales))*100, 2) FROM vgsales
	UNION
SELECT "Global", ROUND(MAX(global_sales), 2), ROUND(MIN(global_sales), 2), ROUND(AVG(global_sales), 4), ROUND(STDDEV_POP(global_sales), 4), ROUND((STDDEV_POP(global_sales)/AVG(global_sales))*100, 2) FROM vgsales
ORDER BY max_sale DESC;



-- Global-level analysis:

/* Retrieve the top-selling games worldwide using a subquery, treating games with the same name but released on different platforms as distinct entries. 
   Example: "Super Mario Bros. - NES" and "Super Mario Bros. - GB" are considered different. */
SELECT a.`name`,  a.platform,  a.`year`, a.genre, a.publisher, ROUND(a.global_sales, 2) AS global_sales FROM
(SELECT * FROM vgsales ORDER BY global_sales DESC) AS a LIMIT 10;

/* Top-selling games worldwide. In this case, sales are aggregated for games released on multiple platforms but considered the same game.
   Example: "Super Mario Bros. - NES: 40.24" and "Super Mario Bros. - GB: 5.07" are combined as "Super Mario Bros.: 45.31". */
SELECT `name`, ROUND(SUM(global_sales), 2) AS max_global_sales FROM vgsales GROUP BY `name` LIMIT 10;

-- Genres with the highest total global sales
SELECT genre, ROUND(SUM(global_sales), 2) AS total_global_sales FROM vgsales
GROUP BY genre ORDER BY total_global_sales DESC;

-- Platforms with the highest total global sales
SELECT platform, ROUND(SUM(global_sales), 2) AS total_global_sales FROM vgsales
GROUP BY platform ORDER BY total_global_sales DESC LIMIT 10;

-- Publishers with the highest total global sales
SELECT publisher, ROUND(SUM(global_sales), 2) AS total_global_sales FROM vgsales
GROUP BY publisher ORDER BY total_global_sales DESC LIMIT 10;

-- Years with the highest global sales
SELECT `year`, ROUND(SUM(global_sales), 2) AS total_global_sales FROM vgsales
GROUP BY `year` ORDER BY total_global_sales DESC LIMIT 10;


-- Which platforms dominated each year
SELECT b.* FROM (
SELECT a.*, DENSE_RANK() OVER(PARTITION BY `year` ORDER BY total_global_sales DESC) AS rank_ FROM (
SELECT `year`, SUM(global_sales) AS total_global_sales, platform  FROM vgsales
GROUP BY `year`, platform) AS a) AS b
WHERE b.rank_ = 1;


-- Top-selling games within each genre
SELECT b.* FROM (
SELECT a.*, DENSE_RANK() OVER(PARTITION BY genre ORDER BY total_sales DESC) AS rank_ FROM(
SELECT `name`, genre, ROUND(SUM(global_sales), 2) AS total_sales FROM vgsales
GROUP BY `name`, genre) AS a) AS b
WHERE b.rank_ <= 5;


-- Which publishers dominated each year
SELECT b.* FROM (
SELECT a.*, DENSE_RANK() OVER(PARTITION BY `year` ORDER BY total_sales DESC) AS rank_ FROM (
SELECT `year`, publisher, ROUND(SUM(global_sales), 2) AS total_sales FROM vgsales
GROUP BY `year`, publisher ORDER BY `year`) AS a) AS b
WHERE rank_ = 1;


-- Which games dominated throughout the years
SELECT b.* FROM (
SELECT a.*, DENSE_RANK() OVER(PARTITION BY `year` ORDER BY total_sales DESC) AS rank_names FROM(
SELECT `year`, `name`, ROUND(SUM(global_sales), 2) AS total_sales FROM vgsales
GROUP BY `year`, `name` ORDER BY `year`) AS a) AS b 
WHERE rank_names = 1;


-- Relative frequency of sales by game
SELECT `name`, 
ROUND(SUM(global_sales), 2) AS sales_by_game, 
ROUND(SUM(global_sales)/(SELECT SUM(global_sales) FROM vgsales)*100, 2) AS relative_frequency_percent
FROM vgsales 
GROUP BY `name` 
ORDER BY relative_frequency_percent DESC LIMIT 10;


-- Relative frequency of global sales by genre
SELECT genre,
ROUND(SUM(global_sales), 2) AS sales_by_genre,
ROUND(SUM(global_sales)/(SELECT SUM(global_sales) FROM vgsales) * 100, 2) AS relative_frequency_percent
FROM vgsales
GROUP BY genre
ORDER BY relative_frequency_percent DESC;


-- Relative frequency of global sales by platform
SELECT platform, 
ROUND(SUM(global_sales), 2) AS sales_by_platform,
ROUND(SUM(global_sales) / (SELECT SUM(global_sales) FROM vgsales) * 100, 2) AS relative_frequency_percent
FROM vgsales
GROUP BY platform ORDER BY relative_frequency_percent DESC
LIMIT 10;


-- Relative frequency of sales by region
-- Instead of using a simple SELECT, I decided to use a TEMPORARY TABLE for better visual clarity:

-- Create the temporary table
DROP TABLE IF EXISTS relative_frequency_region;
CREATE TEMPORARY TABLE relative_frequency_region(
region VARCHAR(20),
sales_by_region DECIMAL(10,2),
relative_frequency_percent DECIMAL(10,2)
);

-- Insert values
INSERT INTO relative_frequency_region VALUES
("north_america", (SELECT SUM(north_america_sales) FROM vgsales), ROUND((SELECT SUM(north_america_sales) FROM vgsales)/(SELECT SUM(global_sales) FROM vgsales)*100, 2)),
("europe", (SELECT SUM(europe_sales) FROM vgsales), ROUND((SELECT SUM(europe_sales) FROM vgsales) / (SELECT SUM(global_sales) FROM vgsales)*100, 2)),
("japan", (SELECT SUM(japan_sales) FROM vgsales), ROUND((SELECT SUM(japan_sales) FROM vgsales)/(SELECT SUM(global_sales) FROM vgsales)*100, 2)),
("others", (SELECT SUM(other_sales) FROM vgsales), ROUND((SELECT SUM(other_sales) FROM vgsales)/(SELECT SUM(global_sales) FROM vgsales)*100, 2));

-- Display the table
SELECT * FROM relative_frequency_region;


-- Publishers with the most games in the top 50 best-selling games globally
SELECT publisher, COUNT(publisher) AS publisher_frequency  FROM (
SELECT `name`, global_sales, publisher FROM vgsales
ORDER BY global_sales DESC LIMIT 50) AS a
GROUP BY a.publisher ORDER BY publisher_frequency DESC;



-- ANALISIS POR REGIÓN:

-- REGIONAL ANALYSIS:

/* Top 10 best-selling games in each region. Games with the same name but released on different platforms 
are considered different entries. Example: "Super Mario Bros. - NES" and "Super Mario Bros. - GB" */ 
-- North America:
SELECT `name`, platform, ROUND(north_america_sales, 2) AS north_america_sales FROM vgsales ORDER BY north_america_sales DESC LIMIT 10;
-- Europe:
SELECT `name`, platform, ROUND(europe_sales, 2) AS europe_sales FROM vgsales ORDER BY europe_sales DESC LIMIT 10;
-- Japan:
SELECT `name`, platform, ROUND(japan_sales, 2) AS japan_sales FROM vgsales ORDER BY japan_sales DESC LIMIT 10;
-- Other countries: 
SELECT `name`, platform, ROUND(other_sales, 2) AS other_sales FROM vgsales ORDER BY other_sales DESC LIMIT 10;

/* Top 10 best-selling games by region, and what percentage those sales represent of each game's global total.
   In this case, sales from the same game are aggregated even if it was released on different platforms.
   Example: "Super Mario Bros. - NES: 40.24" + "Super Mario Bros. - GB: 5.07" = "Super Mario Bros.: 45.31"
*/
SELECT `name`, ROUND(SUM(north_america_sales), 2) AS total_na, ROUND((SUM(north_america_sales)/SUM(global_sales))*100, 2) AS na_sales_percentage FROM vgsales GROUP BY `name` ORDER BY total_na DESC LIMIT 10;
SELECT `name`, ROUND(SUM(europe_sales), 2) AS total_eu, ROUND((SUM(europe_sales)/SUM(global_sales))*100, 2) AS eu_sales_percentage FROM vgsales GROUP BY `name` ORDER BY total_eu DESC LIMIT 10;
SELECT `name`, ROUND(SUM(japan_sales), 2) AS total_japan, ROUND((SUM(japan_sales)/SUM(global_sales))*100, 2) AS jp_sales_percentage FROM vgsales GROUP BY `name` ORDER BY total_japan DESC LIMIT 10;
SELECT `name`, ROUND(SUM(other_sales), 2) AS total_others, ROUND((SUM(other_sales)/SUM(global_sales))*100, 2) AS others_sales_percentage FROM vgsales GROUP BY `name` ORDER BY total_others DESC LIMIT 10;

-- Genres with the highest sales in each region
SELECT genre, ROUND(SUM(north_america_sales), 2) AS total_na FROM vgsales GROUP BY genre ORDER BY total_na DESC; -- North America
SELECT genre, ROUND(SUM(europe_sales), 2) AS total_eu FROM vgsales GROUP BY genre ORDER BY total_eu DESC; -- Europe
SELECT genre, ROUND(SUM(japan_sales), 2) AS total_jp FROM vgsales GROUP BY genre ORDER BY total_jp DESC; -- Japan
SELECT genre, ROUND(SUM(other_sales), 2) AS total_others FROM vgsales GROUP BY genre ORDER BY total_others DESC; -- others

-- Total sales by genre in each region using a CTE
WITH genre_sales AS (
	SELECT genre, ROUND(SUM(north_america_sales), 2) AS total_na, ROUND(SUM(europe_sales), 2) AS total_europe, ROUND(SUM(japan_sales), 2) AS total_japan, ROUND(SUM(other_sales), 2) AS total_others
	FROM vgsales GROUP BY genre)
SELECT * FROM genre_sales ORDER BY genre;


-- Region where each game performed best
WITH performance_by_region AS
	(SELECT `name`, ROUND(SUM(north_america_sales), 2) AS total_na, ROUND(SUM(europe_sales), 2) AS total_eu, ROUND(SUM(japan_sales), 2) AS total_jp, ROUND(SUM(other_sales), 2) AS total_others, ROUND(SUM(global_sales), 2) AS total_global
	FROM vgsales GROUP BY `name`)
SELECT a.*,
CASE
	WHEN total_na > total_eu AND total_na > total_jp AND total_na > total_others THEN 'north_america'
    WHEN total_eu > total_na AND total_eu > total_jp AND total_eu > total_others THEN 'europe'
    WHEN total_jp > total_na AND total_jp > total_eu AND total_jp > total_others THEN 'japan'
    WHEN total_others > total_na AND total_others > total_eu AND total_others > total_jp THEN 'others'
    ELSE 'tie'
END AS biggest_sale
FROM performance_by_region AS a
ORDER BY `name` DESC LIMIT 10;


-- Region where each genre performed best
WITH genre_performance_by_region AS
	(SELECT genre, ROUND(SUM(north_america_sales), 2) AS total_na, ROUND(SUM(europe_sales), 2) AS total_eu, ROUND(SUM(japan_sales), 2) AS total_jp, ROUND(SUM(other_sales), 2) AS total_others 
    FROM vgsales GROUP BY genre)
SELECT a.*, 
CASE
	WHEN total_na > GREATEST(total_eu, total_jp, total_others) THEN 'north_america'
	WHEN total_eu > GREATEST(total_na, total_jp, total_others) THEN 'europe'
	WHEN total_jp > GREATEST(total_na, total_eu, total_others) THEN 'japan'
	WHEN total_others > GREATEST(total_na, total_eu, total_jp) THEN 'others'
	ELSE 'tie'
END AS biggest_sale
FROM genre_performance_by_region AS a;


-- Region where each platform was most successful
WITH platform_performance_by_region AS
	(SELECT platform, ROUND(SUM(north_america_sales), 2) AS total_na, ROUND(SUM(europe_sales), 2) AS total_eu, ROUND(SUM(japan_sales), 2) AS total_jp, ROUND(SUM(other_sales), 2) AS total_others
	FROM vgsales GROUP BY platform)
SELECT a.*,
CASE 
	WHEN total_na > GREATEST(total_eu, total_jp, total_others) THEN 'north_america'
    WHEN total_eu > GREATEST(total_na, total_jp, total_others) THEN 'europe'
    WHEN total_jp > GREATEST(total_na, total_eu, total_others) THEN 'japan'
    WHEN total_others > GREATEST(total_na, total_eu, total_jp) THEN 'others'
    ELSE 'tie'
END AS biggest_sales
FROM platform_performance_by_region AS a
LIMIT 15; 


-- Region with the highest sales for each year
WITH sales_by_year AS (
	SELECT `year`, ROUND(SUM(north_america_sales), 2) AS total_na, ROUND(SUM(europe_sales), 2) AS total_eu, ROUND(SUM(japan_sales), 2) AS total_jp, ROUND(SUM(other_sales), 2) AS total_others
    FROM vgsales GROUP BY `year`)
SELECT a.*, 
CASE 
	WHEN total_na > total_eu AND total_na > total_jp AND total_na > total_others THEN 'north_america'
	WHEN total_eu > total_na AND total_eu > total_jp AND total_eu > total_others THEN 'europe'
	WHEN total_jp > total_na AND total_jp > total_eu AND total_jp > total_others THEN 'japan'
	WHEN total_others > total_na AND total_others > total_eu AND total_others > total_jp THEN 'others'
	ELSE 'tie'
END AS biggest_sale
FROM sales_by_year AS a ORDER BY `year`;


-- Games with the most and least balanced sales across regions. This shows whether a game's success depended heavily on one region or was more evenly distributed.
SELECT `name`, na, eu, jp, `others`, `global`, mean,
ROUND(SQRT((POW(na - mean, 2) + POW(eu - mean, 2) + POW(jp - mean, 2) + POW(`others` - mean, 2)) / 4), 2) AS stddev_regiones
FROM (
    SELECT `name`, ROUND(SUM(north_america_sales), 2) AS na, ROUND(SUM(europe_sales), 2) AS eu, ROUND(SUM(japan_sales), 2) AS jp, 
    ROUND(SUM(other_sales), 2) AS `others`, ROUND(SUM(global_sales), 2) AS `global`,
	ROUND((SUM(north_america_sales) + SUM(europe_sales) + SUM(japan_sales) + SUM(other_sales)) / (4), 2) AS mean
    FROM vgsales
    GROUP BY `name`
) AS sales
WHERE `global` >= 1 AND ((na > 0 AND eu > 0) OR (na > 0 AND jp > 0) OR (na > 0 AND `others` > 0) OR (eu > 0 AND jp > 0) OR 
(eu > 0 AND `others` > 0) OR (jp > 0 AND `others` > 0))
ORDER BY stddev_regiones DESC LIMIT 10;


-- So far, we analyzed the best-performing games, genres, publishers, etc. Now let’s take a look at those with the worst global sales.

/* Games with the lowest global sales. As with the top-selling games query, games with the same name but released on different platforms 
are treated as separate entries.
Example: "Super Mario Bros. - NES" and "Super Mario Bros. - GB" are counted individually. */
SELECT `name`, ROUND(global_sales, 2) AS global_sales, platform FROM vgsales ORDER BY global_sales LIMIT 10;

/* Games with the lowest global sales (aggregated). In this case, sales from different platforms are combined if the game name is the same.
Example: "Super Mario Bros. - NES: 40.24" and "Super Mario Bros. - GB: 5.07" become "Super Mario Bros.: 45.31" */
SELECT `name`, ROUND(SUM(global_sales), 3) AS total FROM vgsales GROUP BY `name` ORDER BY total;

-- Genres with the lowest total global sales
SELECT genre, ROUND(SUM(global_sales), 2) AS total FROM vgsales GROUP BY genre ORDER BY total;

-- Platforms with the lowest total global sales
SELECT platform, ROUND(SUM(global_sales), 2) AS total FROM vgsales GROUP BY platform ORDER BY total LIMIT 10;

-- Publishers with the lowest total global sales
SELECT publisher, ROUND(SUM(global_sales), 3) AS total FROM vgsales GROUP BY publisher ORDER BY total LIMIT 10;

-- Years with the lowest total global sales
SELECT `year`, ROUND(SUM(global_sales), 2) AS total FROM vgsales GROUP BY `year` ORDER BY total LIMIT 10;

