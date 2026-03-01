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


