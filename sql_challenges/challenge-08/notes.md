## Exercise 1 — Find the slow query

```sql
SELECT * FROM patient_visits
WHERE site_id = 3;
```

- From this excercise I learned that if a query returns a large percentage of the table, the database prefers a full table scan instead of using an index.


## Excercise 2 - 

```sql
CREATE INDEX idx_pv_visit_date
ON patient_visits(visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/
```
In this excercise I created an index and executed the gather stats stament. 

### Why is it important to execute gather stats?
Gathering stats is how Oracle learns about the table. When you run DBMS_STATS.GATHER_TABLE_STATS, the database analyzes the data and collects information like how many rows there are, how values are distributed, and how selective each column is. The query optimizer uses these statistics to decide the best execution plan. For example, it decides whether to use an index or do a full table scan. Without accurate stats, Oracle is guessing, and it may choose a bad plan even if an index exists. So even if you create an index, Oracle might not use it unless the stats are updated. That’s why after inserting data or creating indexes, we run gather stats again, so the optimizer has correct information and can make better decisions.

Also I saw first hand how Oracle really analyzes the effectiveness and doesn't always use indexes only for being created and available, it chooses the best option.

## Excercise 3 - Composite index
In this excercise I visualized how the column order matters in composite index, if it doesn't follow the lefmost column being first, Oracle will ignore the index and use a full scan. 

## Exercise 4 — Function that breaks an index

I learned that indexes only work when the query uses the column exactly as it is stored. If I apply a function to the column, like TO_CHAR, I am changing the values, so the index no longer matches and Oracle cannot use it. This forces a full table scan, even if an index exists. So the key idea is to avoid wrapping indexed columns in functions and instead write queries that compare the original values directly, otherwise the index becomes useless.
