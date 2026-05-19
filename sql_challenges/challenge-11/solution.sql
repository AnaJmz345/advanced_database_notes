-- Exercise 1 / Exercise 2
-- Create comments table
-- Each comment belongs to one task and one user.

CREATE TABLE comments (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id     NUMBER NOT NULL,
    user_id     NUMBER NOT NULL,
    content     VARCHAR2(1000) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comments_task
        FOREIGN KEY (task_id) REFERENCES tasks(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id),

    CONSTRAINT ck_comments_content_not_empty
        CHECK (content <> '')
);

-- Optional verification


SELECT table_name
FROM user_tables
WHERE table_name = 'COMMENTS';


-- Exercise 4
-- Example of the bad migration: adding estimated_hours


ALTER TABLE tasks
ADD estimated_hours NUMBER;

-- SQL equivalent of rollback for the bad column
-- This removes the column and its data.

ALTER TABLE tasks
DROP COLUMN estimated_hours;

COMMIT;
