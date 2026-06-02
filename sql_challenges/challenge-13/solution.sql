
-- SOURCE TABLES (OLTP)
-- Business idea:
-- tickets stores the current state of each ticket.
-- ticket_assignments stores the historical assignment timeline.
-- This is useful because the current assigned_to value can change,
-- but reporting needs to know who owned the ticket at creation time
-- and who owned it when it was resolved.

-- Clean up if re-running
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE tickets (
    ticket_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200) NOT NULL,
    status       VARCHAR2(20)  DEFAULT 'open' NOT NULL,
    priority     VARCHAR2(10)  DEFAULT 'medium' NOT NULL,
    created_at   TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at  TIMESTAMP,
    assigned_to  NUMBER        NOT NULL,
    CONSTRAINT chk_ticket_status CHECK (
        status IN ('open', 'in_progress', 'blocked', 'resolved', 'cancelled')
    ),
    CONSTRAINT chk_ticket_priority CHECK (
        priority IN ('low', 'medium', 'high', 'critical')
    )
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER    NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER    NOT NULL,
    assigned_by   NUMBER,
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);

CREATE INDEX idx_ticket_assignments_lookup
ON ticket_assignments (ticket_id, valid_from, valid_to);

-- TRIGGER
-- On INSERT, the trigger records the first assigned agent.
-- On UPDATE of assigned_to, it closes the previous active assignment
-- and opens a new one.
--
-- For INSERT, I use created_at as valid_from because the first assignment
-- starts when the ticket is created.
-- For UPDATE, I use SYSTIMESTAMP because the reassignment happens now.

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO ticket_assignments (
            ticket_id, assigned_to, assigned_by, valid_from, valid_to
        )
        VALUES (
            :NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at, NULL
        );
    ELSIF UPDATING THEN
        UPDATE ticket_assignments
           SET valid_to = SYSTIMESTAMP
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        INSERT INTO ticket_assignments (
            ticket_id, assigned_to, assigned_by, valid_from, valid_to
        )
        VALUES (
            :NEW.ticket_id, :NEW.assigned_to, NULL, SYSTIMESTAMP, NULL
        );
    END IF;
END;
/

--SAMPLE DATA
-- These tickets use agent ids 1 to 4.
-- Later, those same ids are inserted into dim_agent.

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to) VALUES
('Cannot access account after password reset', 'resolved', 'high',
 TIMESTAMP '2026-05-01 09:00:00', TIMESTAMP '2026-05-01 15:00:00', 1);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to) VALUES
('Payment receipt not generated', 'resolved', 'critical',
 TIMESTAMP '2026-05-02 10:00:00', TIMESTAMP '2026-05-02 18:00:00', 2);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to) VALUES
('Mobile app crashes on login', 'in_progress', 'high',
 TIMESTAMP '2026-05-03 11:00:00', NULL, 3);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to) VALUES
('Change email notification settings', 'open', 'low',
 TIMESTAMP '2026-05-04 12:00:00', NULL, 4);

INSERT INTO tickets (title, status, priority, created_at, resolved_at, assigned_to) VALUES
('Dashboard data is not refreshing', 'resolved', 'medium',
 TIMESTAMP '2026-05-05 13:00:00', TIMESTAMP '2026-05-06 09:00:00', 1);

COMMIT;

-- Test reassignment:
-- Ticket 5 was originally assigned to agent 1.
-- After this update, the current assigned_to becomes agent 3,
-- and the trigger records both the old and new assignment.
UPDATE tickets
   SET assigned_to = 3
 WHERE ticket_id = 5;

COMMIT;

-- Confirm assignment history for the reassigned ticket
SELECT
    ta.ticket_id,
    t.title,
    ta.assigned_to,
    ta.valid_from,
    ta.valid_to,
    CASE
        WHEN ta.valid_to IS NULL THEN 'current'
        ELSE 'historical'
    END AS assignment_status
FROM ticket_assignments ta
JOIN tickets t
    ON t.ticket_id = ta.ticket_id
WHERE ta.ticket_id = 5
ORDER BY ta.valid_from;

-- DATA WAREHOUSE TABLES (STAR SCHEMA)
-- dim_agent is the dimension table.
-- fact_ticket_daily is the fact table.
-- The grain is one row per date, agent, status, and priority.

CREATE TABLE dim_agent (
    agent_key  NUMBER PRIMARY KEY,
    agent_name VARCHAR2(100) NOT NULL,
    team       VARCHAR2(50)  NOT NULL
);

CREATE TABLE fact_ticket_daily (
    date_key         NUMBER       NOT NULL,
    agent_key        NUMBER       NOT NULL REFERENCES dim_agent(agent_key),
    status           VARCHAR2(20) NOT NULL,
    priority         VARCHAR2(10) NOT NULL,
    tickets_created  NUMBER       DEFAULT 0,
    tickets_resolved NUMBER       DEFAULT 0,
    CONSTRAINT pk_fact_ticket_daily PRIMARY KEY (date_key, agent_key, status, priority)
);

-- POPULATE DIM_AGENT


INSERT INTO dim_agent (agent_key, agent_name, team) VALUES (1, 'Alice Chen', 'Support');
INSERT INTO dim_agent (agent_key, agent_name, team) VALUES (2, 'Bob Martinez', 'Billing');
INSERT INTO dim_agent (agent_key, agent_name, team) VALUES (3, 'Carol Smith', 'Technical Support');
INSERT INTO dim_agent (agent_key, agent_name, team) VALUES (4, 'Dave Kim', 'Customer Success');
COMMIT;


--  ETL LOGIC (COLAB / PANDAS)
-- This part is meant to be placed in the Colab notebook, not executed in FreeSQL.
-- It shows the extract, transform, and load process using pandas.

/*
import pandas as pd
import oracledb

connection = oracledb.connect(
    user="YOUR_USER",
    password="YOUR_PASSWORD",
    dsn="YOUR_DSN"
)

# 1. Extract
# Read the OLTP tables from FreeSQL.
tickets = pd.read_sql("SELECT * FROM tickets", connection)
assignments = pd.read_sql("SELECT * FROM ticket_assignments", connection)

# Normalize column names because Oracle returns them in uppercase.
tickets.columns = tickets.columns.str.lower()
assignments.columns = assignments.columns.str.lower()

# Convert dates to pandas datetime.
tickets["created_at"] = pd.to_datetime(tickets["created_at"])
tickets["resolved_at"] = pd.to_datetime(tickets["resolved_at"])
assignments["valid_from"] = pd.to_datetime(assignments["valid_from"])
assignments["valid_to"] = pd.to_datetime(assignments["valid_to"])

# Helper function to find who was assigned at a specific point in time.
def find_agent_at_time(ticket_id, event_time):
    if pd.isna(event_time):
        return None

    matches = assignments[
        (assignments["ticket_id"] == ticket_id) &
        (assignments["valid_from"] <= event_time) &
        (
            assignments["valid_to"].isna() |
            (assignments["valid_to"] > event_time)
        )
    ]

    if matches.empty:
        return None

    return int(matches.iloc[0]["assigned_to"])

# 2 and 3. Transform
# Find the agent at creation time and at resolution time.
tickets["created_agent_key"] = tickets.apply(
    lambda row: find_agent_at_time(row["ticket_id"], row["created_at"]),
    axis=1
)

tickets["resolved_agent_key"] = tickets.apply(
    lambda row: find_agent_at_time(row["ticket_id"], row["resolved_at"]),
    axis=1
)

# Build created ticket metrics.
created_metrics = tickets.copy()
created_metrics["date_key"] = created_metrics["created_at"].dt.strftime("%Y%m%d").astype(int)
created_metrics = (
    created_metrics
    .dropna(subset=["created_agent_key"])
    .groupby(["date_key", "created_agent_key", "status", "priority"])
    .size()
    .reset_index(name="tickets_created")
    .rename(columns={"created_agent_key": "agent_key"})
)

# Build resolved ticket metrics.
resolved_metrics = tickets[tickets["resolved_at"].notna()].copy()
resolved_metrics["date_key"] = resolved_metrics["resolved_at"].dt.strftime("%Y%m%d").astype(int)
resolved_metrics = (
    resolved_metrics
    .dropna(subset=["resolved_agent_key"])
    .groupby(["date_key", "resolved_agent_key", "status", "priority"])
    .size()
    .reset_index(name="tickets_resolved")
    .rename(columns={"resolved_agent_key": "agent_key"})
)

# 4. Merge created and resolved counts into one fact dataframe.
fact = pd.merge(
    created_metrics,
    resolved_metrics,
    on=["date_key", "agent_key", "status", "priority"],
    how="outer"
).fillna(0)

fact["agent_key"] = fact["agent_key"].astype(int)
fact["tickets_created"] = fact["tickets_created"].astype(int)
fact["tickets_resolved"] = fact["tickets_resolved"].astype(int)

# 5. Load
# Clear the fact table and insert the transformed rows.
cursor = connection.cursor()
cursor.execute("DELETE FROM fact_ticket_daily")

insert_sql = """
INSERT INTO fact_ticket_daily (
    date_key, agent_key, status, priority, tickets_created, tickets_resolved
) VALUES (:1, :2, :3, :4, :5, :6)
"""

rows = fact[[
    "date_key", "agent_key", "status", "priority",
    "tickets_created", "tickets_resolved"
]].values.tolist()

cursor.executemany(insert_sql, rows)
connection.commit()

print(fact)
*/


--VERIFY
-- This query shows ticket metrics per agent per day.
-- The reassigned ticket should credit creation to the original agent
-- and resolution to the agent assigned at resolution time, depending on
-- the assignment history captured by ticket_assignments.

SELECT
    f.date_key,
    a.agent_name,
    a.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent a
    ON a.agent_key = f.agent_key
ORDER BY f.date_key, a.agent_name, f.priority;

-- Extra verification: current tickets
SELECT
    ticket_id,
    title,
    status,
    priority,
    assigned_to,
    created_at,
    resolved_at
FROM tickets
ORDER BY ticket_id;
