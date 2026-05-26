-- EXERCISE 1: Define Team Velocity
-- Question:
-- Management wants to compare how fast each team completes work.
-- They ask for "team velocity".

-- Answer:
-- For this exercise, I define team velocity as completed tasks per team member.
-- I use completed tasks because velocity should show finished work, not only assigned work.
-- I normalize it by the number of users in each team because Product and Engineering may not
-- have the same team size. This makes the KPI more fair, but it can still be misleading
-- because we do not have story points or task complexity.

-- Business question:
-- Which team is completing more work compared to its team size?

-- Exact definition:
-- Count tasks with status = 'completed' assigned to users of each team,
-- then divide by the number of users in that team.

-- Edge cases:
-- Teams with zero users should not break the query.
-- Teams with no completed tasks should appear with zero velocity.

-- Unit:
-- Completed tasks per team member.
--
-- Misleading case:
-- A team with small easy tasks can look faster than a team with fewer but harder tasks.

WITH team_metrics AS (
    SELECT
        t.id AS team_id,
        t.name AS team_name,
        COUNT(DISTINCT u.id) AS team_members,
        COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END) AS completed_tasks,
        ROUND(
            COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END)
            / NULLIF(COUNT(DISTINCT u.id), 0),
            2
        ) AS velocity_per_member
    FROM teams t
    LEFT JOIN users u
        ON u.team_id = t.id
    LEFT JOIN tasks ts
        ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
),
overall_avg AS (
    SELECT AVG(velocity_per_member) AS avg_velocity
    FROM team_metrics
)
SELECT
    tm.team_name,
    tm.team_members,
    tm.completed_tasks,
    tm.velocity_per_member,
    ROUND(oa.avg_velocity, 2) AS overall_average_velocity,
    CASE
        WHEN tm.velocity_per_member < oa.avg_velocity THEN 'Below average'
        ELSE 'At or above average'
    END AS velocity_flag
FROM team_metrics tm
CROSS JOIN overall_avg oa
ORDER BY tm.velocity_per_member DESC;

-- EXERCISE 2: Define On-Time Delivery Rate

-- Question:
-- The product manager wants to know if deadlines are being met.
-- They ask for an "on-time delivery rate".

-- Answer:
-- I define on-time delivery as completed tasks where completed_at happened before
-- the end of the due date. This means a task completed at 23:59 on the due date
-- is still on time, but one completed at 00:01 the next day is late.

-- Business question:
-- What percentage of completed tasks were finished on time, grouped by priority?

-- Exact definition:
-- Only completed tasks with due_date and completed_at are included.
-- A task is on time when completed_at < due_date + 1 day.

-- Edge cases:
-- Tasks without due_date are excluded because there is no deadline.
-- Tasks without completed_at are excluded because we cannot calculate delivery.
-- Cancelled tasks are excluded because they were not delivered.

-- Unit:
-- Percentage.

-- Misleading case:
-- This metric does not include task difficulty, so simple tasks can improve the result too much.

SELECT
    priority,
    COUNT(*) AS completed_tasks_with_due_date,
    SUM(
        CASE
            WHEN completed_at < CAST(due_date + 1 AS TIMESTAMP) THEN 1
            ELSE 0
        END
    ) AS on_time_tasks,
    ROUND(
        100 * SUM(
            CASE
                WHEN completed_at < CAST(due_date + 1 AS TIMESTAMP) THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_rate,
    ROUND(
        AVG(
            CASE
                WHEN completed_at >= CAST(due_date + 1 AS TIMESTAMP) THEN
                    EXTRACT(DAY FROM (completed_at - CAST(due_date + 1 AS TIMESTAMP))) * 24
                    + EXTRACT(HOUR FROM (completed_at - CAST(due_date + 1 AS TIMESTAMP)))
                    + EXTRACT(MINUTE FROM (completed_at - CAST(due_date + 1 AS TIMESTAMP))) / 60
                ELSE NULL
            END
        ),
        2
    ) AS avg_lateness_hours
FROM tasks
WHERE status = 'completed'
  AND due_date IS NOT NULL
  AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END;
-- EXERCISE 3: Improve Tasks per Team


-- Question:
-- The original KPI counts all tasks assigned to each team, including completed
-- and cancelled tasks. This can make a team look busy even if the work is already done.

-- Answer:
-- I rewrote the KPI to show total tasks, active tasks, completion rate, and a health score.
-- Active tasks are open, in_progress, and blocked. Completion rate excludes cancelled tasks
-- because cancelled work should not count as delivered or unfinished work.

-- Business question:
-- What is the real workload of each team right now?

-- Exact definition:
-- total_tasks = all tasks assigned to users in the team.
-- active_tasks = tasks with status open, in_progress, or blocked.
-- completion_rate = completed tasks divided by non-cancelled tasks.

-- Edge cases:
-- Teams with no tasks should still appear.
-- Cancelled tasks are excluded from completion rate.

-- Unit:
-- Count and percentage.

-- Misleading case:
-- Health score only uses number of active tasks, but does not consider task complexity.

SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(
        CASE
            WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN ts.id
        END
    ) AS active_tasks,
    ROUND(
        100 * COUNT(
            CASE
                WHEN ts.status = 'completed' THEN ts.id
            END
        ) / NULLIF(
            COUNT(
                CASE
                    WHEN ts.status <> 'cancelled' THEN ts.id
                END
            ),
            0
        ),
        2
    ) AS completion_rate,
    CASE
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN ts.id END) > 10
            THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN ts.id END) BETWEEN 5 AND 10
            THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM teams t
LEFT JOIN users u
    ON u.team_id = t.id
LEFT JOIN tasks ts
    ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;


-- EXERCISE 4: Improve Average Resolution Time

-- Question:
-- The original KPI averages all completed tasks together, but that hides differences
-- between critical tasks and low priority tasks.

-- Answer:
-- I improved the KPI by grouping resolution time by priority. I also added average,
-- median, fastest, slowest, completed task count, and a target met flag based on SLA.

-- Business question:
-- How long does each priority level take to be completed?

-- Exact definition:
-- Use completed tasks with completed_at not null.
-- Resolution time is completed_at minus created_at, converted to hours.

-- Edge cases:
-- If a priority has only one completed task, the average is not very reliable.
-- Missing completed_at values are excluded.

-- Unit:
-- Hours.

-- Misleading case:
-- Average can be affected by very slow or very fast tasks, so median helps compare better.

WITH completed_resolution AS (
    SELECT
        priority,
        (
            EXTRACT(DAY FROM (completed_at - created_at)) * 24
            + EXTRACT(HOUR FROM (completed_at - created_at))
            + EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        ) AS resolution_hours
    FROM tasks
    WHERE status = 'completed'
      AND completed_at IS NOT NULL
      AND created_at IS NOT NULL
)
SELECT
    priority,
    COUNT(*) AS completed_task_count,
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours),
        2
    ) AS median_resolution_hours,
    ROUND(MIN(resolution_hours), 2) AS fastest_resolution_hours,
    ROUND(MAX(resolution_hours), 2) AS slowest_resolution_hours,
    CASE
        WHEN priority = 'critical' AND AVG(resolution_hours) <= 24 THEN 'Target met'
        WHEN priority = 'high' AND AVG(resolution_hours) <= 72 THEN 'Target met'
        WHEN priority = 'medium' AND AVG(resolution_hours) <= 168 THEN 'Target met'
        WHEN priority = 'low' AND AVG(resolution_hours) <= 336 THEN 'Target met'
        ELSE 'Target missed'
    END AS target_met,
    CASE
        WHEN COUNT(*) = 1 THEN 'Careful: only one task'
        ELSE 'Sample looks better'
    END AS reliability_note
FROM completed_resolution
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END;

-- EXERCISE 5: Improve Overdue Tasks
-- Question:
-- The original KPI only counts overdue tasks. It does not show who owns them,
-- how overdue they are, or their business impact.

-- Answer:
-- I rewrote it as a detailed overdue report with task title, assignee, team,
-- priority, due date, days overdue, and severity. I also added summary rows
-- by severity at the bottom.

-- Business question:
-- Which overdue tasks need attention first?

-- Exact definition:
-- A task is overdue when due_date is before today and status is not completed
-- or cancelled.

-- Edge cases:
-- Tasks with null due_date are excluded.
-- Completed and cancelled tasks are not overdue.

-- Unit:
-- Days overdue and count.

-- Misleading case:
-- This metric uses priority and days overdue, but it still does not know real business value.

WITH overdue_details AS (
    SELECT
        ts.title,
        u.full_name AS assignee,
        t.name AS team_name,
        ts.priority,
        ts.due_date,
        TRUNC(SYSDATE) - ts.due_date AS days_overdue,
        CASE
            WHEN ts.priority = 'critical'
                 AND TRUNC(SYSDATE) - ts.due_date > 0 THEN 'CRITICAL'
            WHEN ts.priority = 'high'
                 AND TRUNC(SYSDATE) - ts.due_date > 2 THEN 'HIGH'
            WHEN ts.priority = 'medium'
                 AND TRUNC(SYSDATE) - ts.due_date > 5 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS severity
    FROM tasks ts
    LEFT JOIN users u
        ON ts.assigned_to = u.id
    LEFT JOIN teams t
        ON u.team_id = t.id
    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
)
SELECT
    'DETAIL' AS row_type,
    title,
    assignee,
    team_name,
    priority,
    due_date,
    days_overdue,
    severity,
    NULL AS overdue_count,
    NULL AS avg_days_overdue
FROM overdue_details

UNION ALL

SELECT
    'SUMMARY' AS row_type,
    'Total for ' || severity AS title,
    NULL AS assignee,
    NULL AS team_name,
    NULL AS priority,
    NULL AS due_date,
    NULL AS days_overdue,
    severity,
    COUNT(*) AS overdue_count,
    ROUND(AVG(days_overdue), 2) AS avg_days_overdue
FROM overdue_details
GROUP BY severity

ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END,
    row_type,
    days_overdue DESC;

-- EXERCISE 6: Fix the Productivity Score

-- Question:
-- The bad query counts assigned tasks per user and calls it productivity.

-- Answer:
-- This is a bad KPI because assigned tasks are not the same as completed work.
-- A user can have many assigned tasks but complete none. It also ignores priority
-- and does not measure actual delivery. I rewrote it as weighted completed tasks
-- per active day.

-- Business question:
-- Which users are completing more meaningful work?

-- Exact definition:
-- Count only completed tasks and give more weight to higher priorities:
-- critical = 4, high = 3, medium = 2, low = 1.
-- Divide the weighted score by the number of active days between first and last completed task.

-- Edge cases:
-- Users with no completed tasks should still appear.
-- If a user completed tasks in only one day, use 1 day to avoid division by zero.

-- Unit:
-- Weighted completed tasks per day.

-- Misleading case:
-- This still does not include real task complexity, only priority.

WITH user_completed AS (
    SELECT
        u.id AS user_id,
        u.full_name,
        ts.id AS task_id,
        ts.completed_at,
        CASE ts.priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
            ELSE 0
        END AS priority_weight
    FROM users u
    LEFT JOIN tasks ts
        ON ts.assigned_to = u.id
       AND ts.status = 'completed'
       AND ts.completed_at IS NOT NULL
),
user_scores AS (
    SELECT
        user_id,
        full_name,
        COUNT(task_id) AS completed_tasks,
        SUM(priority_weight) AS weighted_completed_score,
        GREATEST(
            TRUNC(MAX(completed_at)) - TRUNC(MIN(completed_at)) + 1,
            1
        ) AS active_days
    FROM user_completed
    GROUP BY user_id, full_name
)
SELECT
    full_name,
    completed_tasks,
    NVL(weighted_completed_score, 0) AS weighted_completed_score,
    active_days,
    ROUND(NVL(weighted_completed_score, 0) / active_days, 2) AS productivity_score
FROM user_scores
ORDER BY productivity_score DESC;

-- EXERCISE 7: Fix the Team Efficiency

-- Question:
-- The bad query calculates AVG(task id) and calls it team efficiency.

-- Answer:
-- This is mathematically wrong because an id is only an identifier, not a value
-- that represents performance. The average task id does not explain anything
-- about efficiency. I rewrote it as completed tasks divided by total non-cancelled tasks.

-- Business question:
-- Which teams finish the highest percentage of their assigned work?

-- Exact definition:
-- Team efficiency = completed tasks / total tasks excluding cancelled tasks.

-- Edge cases:
-- Teams with no tasks should still appear.
-- Cancelled tasks are excluded because they do not represent delivered work.

-- Unit:
-- Percentage.

-- Misleading case:
-- A team with few easy tasks may look more efficient than a team with harder work.

SELECT
    t.name AS team_name,
    COUNT(
        CASE
            WHEN ts.status <> 'cancelled' THEN ts.id
        END
    ) AS total_non_cancelled_tasks,
    COUNT(
        CASE
            WHEN ts.status = 'completed' THEN ts.id
        END
    ) AS completed_tasks,
    ROUND(
        100 * COUNT(
            CASE
                WHEN ts.status = 'completed' THEN ts.id
            END
        ) / NULLIF(
            COUNT(
                CASE
                    WHEN ts.status <> 'cancelled' THEN ts.id
                END
            ),
            0
        ),
        2
    ) AS team_efficiency_rate
FROM teams t
LEFT JOIN users u
    ON u.team_id = t.id
LEFT JOIN tasks ts
    ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY team_efficiency_rate DESC NULLS LAST;

-- EXERCISE 8: Fix the Urgency Index
-- Question:
-- The bad query tries to multiply priority by 10 and add due_date.

-- Answer:
-- This is wrong because priority is text, not a number. Also, adding a date
-- directly to a score does not create a meaningful urgency index. I rewrote it
-- by converting priority to a numeric weight and combining it with due date pressure.

-- Business question:
-- Which tasks should be handled first?

-- Exact definition:
-- Urgency score gives more points to high priority tasks and to tasks that are
-- overdue or due soon. Completed and cancelled tasks are excluded.

-- Edge cases:
-- Tasks with no due_date get a lower due date pressure because we cannot know urgency.
-- Overdue tasks get a bigger score.

-- Unit:
-- Numeric score.

-- Misleading case:
-- The score is useful for sorting, but it is still a simplified rule and not a full
-- business priority model.

SELECT
    title,
    priority,
    due_date,
    status,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
        ELSE 0
    END AS priority_weight,
    CASE
        WHEN due_date IS NULL THEN 0
        WHEN due_date < TRUNC(SYSDATE) THEN 10 + (TRUNC(SYSDATE) - due_date)
        ELSE GREATEST(0, 10 - (due_date - TRUNC(SYSDATE)))
    END AS due_date_pressure,
    (
        CASE priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
            ELSE 0
        END * 10
        +
        CASE
            WHEN due_date IS NULL THEN 0
            WHEN due_date < TRUNC(SYSDATE) THEN 10 + (TRUNC(SYSDATE) - due_date)
            ELSE GREATEST(0, 10 - (due_date - TRUNC(SYSDATE)))
        END
    ) AS urgency_index
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
ORDER BY urgency_index DESC, due_date ASC NULLS LAST;
