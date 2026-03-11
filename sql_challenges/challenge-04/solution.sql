-- ORACLE FREE SQL

-- 3.Try it
--Complete the following query to return the count and average weight of bricks for each shape:
select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median (weight) over (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;



-- 5.Try it
