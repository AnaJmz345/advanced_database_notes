-- Lesson 6

-- 1.Find the domestic and international sales for each movie 

SELECT title,domestic_sales,international_sales FROM movies INNER JOIN Boxoffice ON movies.id =  Boxoffice.Movie_Id;

-- 2.Show the sales numbers for each movie that did better internationally rather than domestically
SELECT title,domestic_sales,international_sales FROM movies INNER JOIN Boxoffice ON movies.id =  Boxoffice.Movie_Id WHERE international_sales > domestic_sales;

-- 3.List all the movies by their ratings in descending order
SELECT title,rating FROM movies INNER JOIN Boxoffice ON movies.id =  Boxoffice.Movie_Id ORDER BY rating DESC


-- Lesson 7

-- 1. Find the list of all buildings that have employees

SELECT DISTINCT building FROM employees;

-- 2. Find the list of all buildings and their capacity

SELECT * FROM buildings;

-- 3. List all buildings and the distinct employee roles in each building (including empty buildings)
SELECT DISTINCT buildings.building_name,employees.role FROM buildings LEFT JOIN employees ON buildings.building_name = employees.building;



-- Interview question
-- Assume you're given two tables containing data about Facebook Pages and their respective likes (as in "Like a Facebook Page").

-- Write a query to return the IDs of the Facebook pages that have zero likes. The output should be sorted in ascending order based on the page IDs.


SELECT pages.page_id FROM pages LEFT OUTER JOIN page_likes ON pages.page_id = page_likes.page_id WHERE page_likes.page_id IS NULL ORDER BY pages.page_id;