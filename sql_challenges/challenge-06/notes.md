# 1ST TRIGGER
## Result
![alt text](image.png)
## Explanation
I learned tht the current time can be obtained with SYSTIMESTAMP and the user can be also get with USER keyword. Also, I learned how to throw an exception in a trigger.

Also, I got  abetter idea of how a trigger actually works:

In a BEFORE INSERT trigger, the database does not execute the insert immediately.
Instead, it first takes the row that the query is trying to insert and holds it temporarily.

At this point, the row is not yet stored in the table.

Then, the trigger runs and can modify that row using :NEW, for example by adding the current timestamp or the current user.

Only after the trigger finishes successfully (no errors), the database proceeds to execute the insert and saves the final modified row into the table.

- Key idea:
 ```
 The BEFORE trigger acts like a checkpoint:

1. The query builds the row
2. The trigger modifies/validates it
3. Only then the row is actually inserted

*If an error occurs in the trigger → the insert is never executed*
 ```


# 2nd TRIGGER
## Result
![alt text](image.png)
## Explanation

In a BEFORE UPDATE trigger, the database does not apply the update immediately.
Instead, it first prepares:

:OLD → the current values in the table
:NEW → the new values coming from the UPDATE query

At this point, the row is not yet updated in the table.

Then, the trigger runs and can:

- compare old vs new values
- validate permissions
- modify the new row (:NEW)

More especifically, this trigger intercepts an update before it is applied and checks whether the current user is the same as the one who previously updated the row. It compares the value in :OLD.UPDATED_BY_USER with the current database user (USER). If they match, the update is allowed and the trigger automatically updates the audit fields by setting the current timestamp and user in :NEW. If they do not match, the trigger raises an error and the update is canceled, so the row remains unchanged.

# 3th TRIGGER
## Result
![alt text](image.png)
## Explanation
In a BEFORE DELETE trigger, the database does not delete the row immediately.
Instead, it first identifies the row that is about to be deleted and makes it available as :OLD.

At this point, the row is still in the table.

Then, the trigger runs and can:
- validate conditions
- check permissions
- decide whether the delete should proceed

Since there is no :NEW (because the row will be removed), the trigger cannot modify the row, only validate it.

If the trigger finishes successfully, the database proceeds to execute the delete.
If an error is raised, the delete is canceled and the row remains unchanged.

This trigger does:
This trigger intercepts a delete operation before it is executed and checks the current database user. If the user is 'JOEMANAGER', the trigger does nothing (NULL;) and allows the delete to continue normally. If the user is different, the trigger raises an error using RAISE_APPLICATION_ERROR, which cancels the delete operation. As a result, only the user 'JOEMANAGER' is allowed to delete rows from the table, and any other user will be blocked.