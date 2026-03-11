## Free sql explanations
 3. Try it

    Complete the following query to return the count and average weight of bricks for each shape:
    select b.*,
       count(*) over (partition by shape) bricks_per_shape,
       median (weight) over (partition by shape) median_weight_per_shape
    from   bricks b
    order  by shape, weight, brick_id;
Result
![alt text](image.png)

In here the windows were created according to the shapes, so it counted how many shapes of each one there were and then the average weight of each type of shape.


5. try it
```
Complete the following query to get the running average weight, ordered by brick_id:

select b.brick_id, b.weight,
       round (avg(weight) over (order by brick_id), 2 ) running_average_weight
from   bricks b
order  by brick_id;

```

Result
![alt text](image-1.png)


The ORDER BY brick_id inside OVER() creates a  window from the first row up to the current row.
The function AVG(weight) calculates the average weight of all rows in that window.

Here are the calculations:

* brick_id = 1, window = [1], running_average = 1 / 1 = 1
* brick_id = 2, window = [1,2], running_average = (1 + 2) / 2 = 1.5
* brick_id = 3, window = [1,2,3], running_average = (1 + 2 + 1) / 3 = 1.33
* brick_id = 4, window = [1,2,3,4], running_average = (1 + 2 + 1 + 2) / 4 = 1.5
* brick_id = 5, window = [1,2,3,4,5], running_average = (1 + 2 + 1 + 2 + 3) / 5 = 1.8

