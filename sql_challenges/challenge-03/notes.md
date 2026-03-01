- It was helpful getting to know the clauses order of execution in sql queries so that I could visualize the order in which everyhting needed to be filtered to obtain the expected results. For example in this one: 

-- 2. For each role, find the average number of years employed by employees in that role
SELECT role,AVG(years_employed) As average FROM employees GROUP BY role;

I thought about it first I need to get all the data of table employees with the from, then I need to group them by roles so I get artists, engineers, etc. Then I need to calculate the average years they work eaach role, so with the avg that will be executed after the group by, I can achieve it. After that, I just put the role column in the select so the caaculated average yeaars could be related with their respective role.


- I applied this same thought process with all the sql bolt excercises of this session.