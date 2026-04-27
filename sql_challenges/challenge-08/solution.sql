-- Excercise 1 - Find the slow query
SELECT * FROM patient_visits WHERE site_id = 3;

-- Questions:
-- a) What scan type do you see? Why?
-- It uses a full scan table becaause there are no indexes created in the analyzed table (patient_visits).

-- b) site_id has values 1–5. Is this high or low cardinality?
-- It has low cardinality because there aare only 5 elegible values for that column, meaning that many rows will share the same value.

-- c) Would adding an index on site_id help? Why or why not?
-- No, due to its low cardinality,  many rows match the condition (site_id = 3). So, the database would still need to access a 
-- large portion of the table, making a full table scan more efficient than using the index.

-- Exercise 2 — Create an index and see if it helps

-- 1. Create an index on visit_date.
CREATE INDEX idx_pv_visit_date
ON patient_visits(visit_date);

-- 2.Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- 3. Run the query
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- 4. Questions

-- a) Does Oracle use the index for this range?

EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY); 

--With this query, it returned that Oracle didn't use the index because it showed TABLE ACCESS FULL,
-- and that Oracle estimated that the query would return around 2,125 rows, so it decided that scanning the full table 
-- was cheaper than using the index and then accessing the table rows. This shows that creating an index does not guarantee
-- that Oracle will use it; the optimizer chooses the plan with the lowest estimated cost.


-- b) Change the range to the last 7 days. Does the plan change?
-- The execution plan shows a TABLE ACCESS FULL again, even though the estimated rows decreased from around 2,125 rows to 547 rows.
-- This means that Oracle still considered the full table scan cheaper than using the visit_date index. So the range became more selective,
-- but not enough for the optimizer to choose the index.

-- c) Change to the last 700 days. What happens?
--The query returns a much larger number of rows, almost the entire table. In this case, Oracle does not use the index and 
-- performs a TABLE ACCESS FULL, because using the index would require accessing many rows anyway, making it less efficient than 
-- scanning the whole table directly.

-- d) Why does the range size affect whether Oracle uses the index?
--The range size affects selectivity. Smaller ranges return fewer rows, so the index helps reduce the amount of data that needs
-- to be read. However, larger ranges return many rows, so the benefit of the index decreases. At that point, Oracle prefers a 
-- full table scan because it is cheaper than using the index and then accessing many rows from the table.
--In this specific case, Oracle used a full table scan in all scenarios because the table is relatively small, so scanning the
-- entire table is still cheaper than using the index, even for smaller ranges.

-- Excercise 3 - Composite index

-- Common query:
WHERE patient_id = 1234 AND visit_date > SYSDATE - 90

-- Composite index:
CREATE INDEX idx_pv_patient_date 
ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Query
SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

  -- Questions:
-- a) Does the plan use the composite index?
-- Yes, Oracle uses the composite index because the query matches both columns in the same order as the index.

-- b) Now try querying ONLY on visit_date (no patient_id).
SELECT * FROM patient_visits 
WHERE visit_date > SYSDATE - 90;

--    Does the composite index get used? Why not?
-- The composite index cannot be used because visit_date is not the first column in the index. Oracle can 
-- only use the index starting from the leftmost column.

-- c) What's the rule about column order in composite indexes?

--In a composite index, the column order matters. The database can only use the index starting from the 
--leftmost column.

-- Excercise 4

-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;

-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- Why the previouse query didn't use the index,a) what scan type did it use and b) why does warapping a column in a function 
--break index use?

--Applying a function to a column breaks index usage because the index is built on the original values of that 
--column, not on the transformed result. In this case, the index stores patient_id as numeric values, but when
-- using TO_CHAR(patient_id), Oracle has to convert every row into a string before comparing it. Since the index
-- does not contain these converted values, Oracle cannot use it and instead performs a full table scan. This means
-- it has to evaluate the function for every row, which is much slower than directly searching the indexed values.

 -- c) How would you rewrite the second query to allow index use?
 SELECT * 
FROM patient_visits 
WHERE patient_id = 5432;

-- Rewrite it by not applying the function to the column and comparing it with the correct data type,Because patient_id
-- is a NUMBER, the value should stay numeric, not as a string like '5432'.


-- Exercise 5 — Discussion: real-world scenarios