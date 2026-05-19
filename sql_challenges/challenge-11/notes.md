## Exercise 1 — Model Design

### Comment model

```python
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(String(1000), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    __table_args__ = (
        CheckConstraint("content <> ''", name="ck_comments_content_not_empty"),
    )

    task = relationship("Task", back_populates="comments")
    user = relationship("User", back_populates="comments")
```

### Changes needed in Task and User

```python
class Task(Base):
    __tablename__ = "tasks"

    # existing columns...

    comments = relationship(
        "Comment",
        back_populates="task",
        cascade="all, delete-orphan"
    )


class User(Base):
    __tablename__ = "users"

    # existing columns...

    comments = relationship("Comment", back_populates="user")
```

### Questions

**1. What relationships should Comment have?**  
Comment should have a relationship with Task and another one with User. This is because each comment belongs to one task and one user. So, in the model, Comment needs task_id, user_id, task, and user.

**2. Should Task have a comments relationship?**  
Yes. Task should have a comments relationship because one task can have many comments. This makes it easier to do something like task.comments instead of manually writing a query every time.

**3. What should happen to comments when a task is deleted?**  
The comments should also be deleted. It would not make sense to keep comments that belong to a task that no longer exists. That is why I would use cascade="all, delete-orphan" in the ORM and ON DELETE CASCADE in the foreign key.

---

## Exercise 2 — Migration Creation

### Generate migration programmatically

```python
from alembic import command

command.revision(
    alembic_cfg,
    autogenerate=True,
    message="add comments table"
)
```

### Inspect migration files

```python
import glob

migration_files = sorted(
    glob.glob('/content/project/alembic/versions/*.py')
)

for f in migration_files:
    print(f)
```

### Open generated migration

```python
latest = migration_files[-1]

with open(latest) as f:
    print(f.read())
```

### Example of what the generated migration should look like

```python
from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_table(
        "comments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("task_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("content", sa.String(length=1000), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["task_id"], ["tasks.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.CheckConstraint("content <> ''", name="ck_comments_content_not_empty")
    )


def downgrade():
    op.drop_table("comments")
```

### Questions

**1. What does upgrade() do?**  
upgrade() applies the new change to the database. In this case, it creates the comments table with its columns, foreign keys, and the check constraint for the content.

**2. What does downgrade() do?**  
downgrade() reverses the migration. In this case, it removes the comments table from the database.

**3. What happens if you downgrade this migration?**  
If I downgrade this migration, the comments table is deleted. That means the table structure is removed and the comments stored there would also be lost.

### Bonus — CHECK constraint

The check constraint is:

```python
sa.CheckConstraint("content <> ''", name="ck_comments_content_not_empty")
```

This prevents empty comments. So the user cannot save a comment with an empty string as content.


## Exercise 3 — CRUD Challenge

```python
from sqlalchemy.orm import Session

with Session(engine) as session:
    # 1. Create a team called "DevOps"
    devops_team = Team(
        name="DevOps",
        description="Team focused on deployment, automation, and operations"
    )

    # 2. Create a user "diana_ops"
    diana = User(
        username="diana_ops",
        email="diana_ops@example.com",
        full_name="Diana Ops",
        team=devops_team
    )

    # 3. Create 3 tasks with different priorities
    task1 = Task(
        title="Configure CI pipeline",
        description="Create the first version of the CI pipeline",
        status="open",
        priority="high",
        assigned_user=diana
    )

    task2 = Task(
        title="Review server logs",
        description="Check logs to identify possible deployment issues",
        status="open",
        priority="medium",
        assigned_user=diana
    )

    task3 = Task(
        title="Clean old test files",
        description="Remove files that are no longer needed",
        status="open",
        priority="low",
        assigned_user=diana
    )

    session.add(devops_team)
    session.add(diana)
    session.add_all([task1, task2, task3])
    session.commit()

    # 4. Print task count
    task_count = session.query(Task).count()
    print("Task count after creating tasks:", task_count)

    # 5. Close one task
    task1.status = "closed"
    session.commit()
    print("Closed task:", task1.title)

    # 6. Delete the lowest priority task
    lowest_priority_task = (
        session.query(Task)
        .filter(Task.priority == "low")
        .first()
    )

    if lowest_priority_task:
        print("Deleting lowest priority task:", lowest_priority_task.title)
        session.delete(lowest_priority_task)
        session.commit()

    final_count = session.query(Task).count()
    print("Final task count:", final_count)
```

### Explanation

This script uses ORM only because I am creating Python objects instead of writing direct SQL queries. The relationship is used when diana is assigned to the DevOps team and when the tasks are assigned to diana. This makes the code more readable because it works more like the real domain: a team has users, and a user has tasks.

Note: this script assumes that the Task model has a priority column and a relationship like assigned_user. If the model uses another relationship name, for example user, then assigned_user=diana should be changed to user=diana.

## Exercise 4 — Migration Rollback

### Rollback command

```python
from alembic import command

command.downgrade(alembic_cfg, "-1")
```

### Questions

**1. What happens to the column?**  
The bad column estimated_hours is removed because the downgrade reverses the last migration that added it.

**2. What happens to the data?**  
The data inside that column is lost. Even if the rest of the table stays, the values stored in estimated_hours disappear when the column is dropped.

### My understanding

Rollback is useful when a migration was applied but it introduced a mistake. For example, if I added estimated_hours with the wrong type, wrong name, or it was not really needed, I can rollback to return the database to the previous version.

---

## Exercise 5 — Concept Check

**1. Why use ORM instead of raw SQL?**  
ORM is useful because it lets me work with database tables as Python classes and objects. This makes the code easier to read and maintain. Instead of writing SQL for everything, I can create users, tasks, and comments using Python code.

**2. Why use migrations?**  
Migrations are useful because they work like version control for the database. They help track changes in the schema, like creating a table, adding a column, or removing something. This is important because the database structure changes together with the application.

**3. When would you rollback?**  
I would rollback when a migration has a mistake or breaks something. For example, if I added a bad column, created the wrong constraint, or changed the schema in a way that affects the app, I can go back to the previous version.

**4. Difference between add() and commit()?**  
add() puts the object in the session, but it does not save it permanently yet. commit() actually sends the changes to the database and makes them permanent.

**5. Why are relationships useful?**  
Relationships are useful because they connect models in a more natural way. For example, instead of only using task_id manually, I can access comment.task or task.comments. This makes the code clearer and helps avoid writing extra queries.
