-- Lesson 10

-- 1.Find the longest time that an employee has been at the studio 
SELECT MAX(years_employed) FROM employees;

-- 2. For each role, find the average number of years employed by employees in that role
SELECT role,AVG(years_employed) As average FROM employees GROUP BY role;

--3. Find the total number of employee years worked in each building
SELECT building, SUM(years_employed) As average FROM employees GROUP BY building;


-- Lesson 11

--1. Find the number of Artists in the studio (without a HAVING clause)

SELECT COUNT(role) AS "# artists" FROM employees WHERE role="Artist";

-- 2. Find the number of Employees of each role in the studio 
SELECT role,COUNT(role)  FROM employees GROUP BY role;

--3. Find the total number of years employed by all Engineers
SELECT role, SUM(years_employed) FROM employees GROUP BY role HAVING role = "Engineer";


-- Oracle free
-- 1. Complete the following query to return the:

-- Number of different shapes
-- The standard deviation (stddev) of the unique weights

select COUNT( distinct shape) AS number_of_shapes,
       stddev(distinct weight) AS distinct_weight_stddev
from   bricks;

-- 2. Complete the following query to return the total weight for each shape stored in the bricks table:

select shape, SUM(weight) as shape_weight
from   bricks
GROUP BY shape;

-- 3. Complete the following query to find the shapes which have a total weight less than four:
select shape, sum ( weight ) as shape_weight
from   bricks
group  by shape
HAVING sum ( weight )<4;
