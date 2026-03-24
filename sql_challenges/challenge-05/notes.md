5. Try it
Part 1
UNION combines the results of two queries into one result set and automatically removes duplicates.
So even if the same colour appears multiple times in both tables, it will appear only once in the final result.

Part 2
UNION ALL also combines the results of two queries, but it does NOT remove duplicates.
This means every row from both tables appears in the final result.

10. Try it
Part 1
MINUS returns the rows that exist in the first query but not in the second query.
So here SQL does this:

- take all shapes from my_brick_collection
- compare them with the shapes in your_brick_collection
- keep only the shapes that appear in mine but not in yours

Part 2
MINUS returns the rows that exist in the first query but not in the second query.

So here SQL does this:

- take all shapes from my_brick_collection
- compare them with the shapes in your_brick_collection
- keep only the shapes that appear in mine but not in yours