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