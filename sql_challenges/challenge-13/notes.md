## Step 1 Source Tables

In this step I learned that the OLTP tables are used to store the operational data of the system. The `tickets` table keeps the current state of every ticket, such as its status, priority, creation date, resolution date, and current assigned agent. The important part is that this table only shows the current assignment, so it is not enough if we want to know who had the ticket before.

The `ticket_assignments` table solves that problem because it stores the history of the assignment changes. Instead of overwriting the old assigned agent, it keeps a timeline using `valid_from` and `valid_to`. This helped me understand why assignment history is important for reporting and auditing.

## Step 2 Sample Data

In this step I inserted sample tickets with different statuses and priorities. I also made sure that at least one ticket was reassigned. This is important because the exercise is not only about storing tickets, but about proving that the system can remember the old assignment and the new assignment.

For example, if a ticket starts with one agent and later moves to another agent, the current `assigned_to` value only shows the latest agent. The assignment history table gives more context because it shows who had the ticket at each moment.

## Step 3 Trigger

In this step I learned that a trigger can automate the assignment history. When a ticket is inserted, the trigger creates the first assignment record. When the `assigned_to` value changes, the trigger closes the previous assignment by setting `valid_to`, and then inserts a new active assignment with `valid_to = NULL`.

This is useful because the application does not need to manually remember to insert the history every time. The database enforces that behavior automatically. I also understood that `valid_to = NULL` means the assignment is still current.

## Step 4 Data Warehouse Tables

In this step I created a small star schema. The `dim_agent` table stores the agent details, and the `fact_ticket_daily` table stores the daily metrics. This separates descriptive data from measurable data.

The fact table is organized by date, agent, status, and priority. This makes the reporting easier because we can count how many tickets were created or resolved for each agent per day.

## Step 5 Populate dim_agent

In this step I inserted the agents into the dimension table. I used the same agent ids that appear in the OLTP data so the ETL process can match tickets with agent details.

This helped me understand that dimensions give meaning to the fact table. Without `dim_agent`, the fact table would only have numeric ids, but with the dimension we can show the agent name and team in the final report.

## Step 6 ETL Logic

In this step I learned the purpose of the ETL process. First, we extract the tickets and ticket assignment history from FreeSQL. Then, we transform the data by finding who was assigned when the ticket was created and who was assigned when the ticket was resolved. Finally, we load the grouped results into the fact table.

The most important part for me was the condition:

`valid_from <= event_time AND (valid_to IS NULL OR valid_to > event_time)`

This condition checks which assignment was active at a specific moment. It is what allows the report to give credit to the correct agent, even if the ticket was reassigned later.

## Step 7 Verify

In this step I used a query that joins `fact_ticket_daily` with `dim_agent`. This final report shows the tickets created and resolved per agent per day.

What I understood is that the reassigned ticket should not be counted only with the current agent. The creation metric should belong to the agent who had the ticket when it was created, and the resolution metric should belong to the agent who had it when it was resolved. This makes the data warehouse more accurate because it uses historical context instead of only the current state.
