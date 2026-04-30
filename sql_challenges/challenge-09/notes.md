# Excercise 1

In oracle, when using transactions, they don't staart with the keyword BEGIN, but they start with the first UPDATE, INSERT OR DELETE that you do.

# Excercise 2
Here I learned what happens when trying to perform an invalid operation, like transferring more money than available. The changes were applied temporarily, but since they were not committed, I could use ROLLBACK to undo everything. This showed me that I can safely test operations and cancel them if they are incorrect.

# Excercise 3
In this exercise, I learned hot to use a savepoint to go back only to the correct point and fixed the error. This helped me understand how savepoints can be used to correct specific mistakes without losing all progress.

# Excercise 4
In this part, I learned how to create a stored procedure to handle logic inside the database. The procedure validates the input, updates the balance, and handles errors using commit and rollback. This showed me that stored procedures are useful for grouping multiple operations, ensuring data integrity, and reusing logic.

# Excercise 5

I learned that only operations that affect database consistency should be inside a transaction, such as reserving a time slot and creating a record. AAlso, using COMMIT inside a stored procedure can cause problems when the procedure is used inside a larger transaction, because it saves changes too early and removes control from the main transaction.