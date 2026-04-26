## Exercise 1 — Find the slow query

```sql
SELECT * FROM patient_visits
WHERE site_id = 3;
```

- From this excercise I learned that if a query returns a large percentage of the table, the database prefers a full table scan instead of using an index.


## Excercise 2 - 