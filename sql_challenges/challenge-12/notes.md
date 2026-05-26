
## Exercise 1 — Team Velocity

In this exercise I learned that a KPI needs a clear definition before writing the query. Team velocity can sound simple, but it depends on what we mean by velocity. Since the database does not have story points, I used completed tasks per team member per active day. This helped me understand that metrics should be fair, especially when teams have different sizes.

## Exercise 2 — On-Time Delivery Rate

In this exercise I learned that dates can change how a metric is interpreted. I decided that a task is on time if it is completed before the end of its due date. This makes the KPI easier to explain because completing something during the due date still counts as on time. I also learned that tasks without due dates should not be included because they do not have a deadline to compare.

## Exercise 3 — Improved Tasks per Team

In this exercise I learned that counting all tasks is not always useful. A team can have many completed or cancelled tasks, but that does not mean they are currently busy. By separating total tasks, active tasks, and completion rate, the metric becomes more useful to understand workload and team health.

## Exercise 4 — Improved Average Resolution Time

In this exercise I learned that averages can hide important details. If we mix critical tasks with low priority tasks, the result does not explain the real performance of the team. Breaking resolution time by priority and adding median, fastest, and slowest times gives a clearer view of how fast work is being solved.

## Exercise 5 — Improved Overdue Tasks

In this exercise I learned that a KPI should give enough context to make decisions. A simple overdue count only says how many tasks are late, but it does not show who owns them or how urgent they are. Adding assignee, team, priority, days overdue, and severity makes the report more useful for management.

## Exercise 6 — Fixed Productivity Score

In this exercise I learned that productivity should not be measured only by the number of assigned tasks. Assigned tasks are not the same as completed work. A better metric is to count completed tasks and give more weight to higher priority tasks, because finishing a critical task should matter more than finishing a low priority one.

## Exercise 7 — Fixed Team Efficiency

In this exercise I learned that not every number in the database is useful for a KPI. Average task ID does not mean anything for team efficiency because an ID is only an identifier. A better metric is the ratio of completed tasks compared to the total non-cancelled tasks, because it actually explains how much work the team finished.

## Exercise 8 — Fixed Urgency Index

In this exercise I learned that a formula has to make sense with the data types. Priority is text, so it cannot be multiplied directly. To create an urgency score, I first converted priorities into numeric weights and then combined that with how close or overdue the due date is. This makes the metric clearer and easier to use for prioritizing work.
