-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- Your SQL here:
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

UPDATE accounts
SET balance = balance - 50
WHERE account_id = 3;

UPDATE accounts
SET balance = balance + 50
WHERE account_id = 1;

COMMIT;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


 -- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

-- Your SQL here:


SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

UPDATE accounts
SET balance = balance - 10000
WHERE account_id = 2;

UPDATE accounts
SET balance = balance + 10000
WHERE account_id = 3;

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

-- Charlie gained the 10,000 but since  Bob didn't have enpugh money, the changes were rolled back and no hcaanges in the money
-- were made (it wasn't committed)

ROLLBACK;

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

 

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

-- Your SQL here:

 SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

UPDATE accounts
SET balance = balance + 25
WHERE account_id = 1;

SAVEPOINT after_alice_deposit;

UPDATE accounts
SET balance = balance - 25
WHERE account_id = 3;

ROLLBACK TO after_alice_deposit;

UPDATE accounts
SET balance = balance - 25
WHERE account_id = 2;

COMMIT;

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;


-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
-- Test it with: EXEC deposit_funds(3, 75);

-- Your SQL here:
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
) AS
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Amount must be greater than 0');
    END IF;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account does not exist');
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

EXEC deposit_funds(3, 75);

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;


 

-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?

-- The actions that should be inside the transaction are reserving the time slot
-- and creating the appointment record, because both affect the database directly.
-- These two operations cannot be left halfway. If the slot is reserved but the
-- appointment is not created, the system would have wrong data. Also, if the
-- appointment is created but the slot is not reserved, another patient could take
-- the same time.

-- The confirmation notification should be outside the transaction because it does
-- not affect the main database consistency. If the notification fails, the
-- appointment can still exist correctly, and the system can retry the notification
-- later.


-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?

-- The problem is that the COMMIT inside the procedure saves the changes
-- immediately, even if the developer's bigger transaction is not finished yet.
-- So if something fails later in the larger transaction, the changes made by the
-- procedure cannot be rolled back anymore.
--
-- This is risky because the developer loses control of the full transaction.
-- It can leave the system with only part of the process saved, which is exactly
-- what transactions are supposed to avoid.


-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?

-- Yes, calculate_copay() can be used inside a SELECT statement because functions
-- are made to return a value. For example, it could calculate how much the patient
-- has to pay and show that result in a query.
--
-- But post_payment() cannot be used inside a SELECT statement because procedures
-- are made to perform actions, like inserting a payment, updating a balance, or
-- changing data. Procedures do not return a value in the same way functions do.

--- 01_setup.sql

-- Lesson 04: Setup
-- Create a simple accounts table for the transfer demo

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250

 

---  02_no_transaction.sql

-- Lesson 04: The Broken Transfer — What Happens Without a Transaction
-- Run this to show the problem. Imagine the server crashes after line 1.

-- Step 1: Debit Alice
UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;

-- >>> IMAGINE THE SERVER CRASHES HERE <<<
-- The UPDATE above is pending (not committed).
-- But in Oracle, DDL statements auto-commit. If something triggers a commit
-- before ROLLBACK, Alice loses $500 that never reaches Bob.

-- Step 2: Credit Bob (never runs if crash happens)
UPDATE accounts SET balance = balance + 500 WHERE account_id = 2;

-- Without wrapping this in a transaction:
-- - If step 1 commits but step 2 never runs → $500 disappears
-- - The database is in an INCONSISTENT state

-- Check current state (run after simulating crash)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Clean up for next demo
ROLLBACK;
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Balances should be back to starting values

 

--  03_with_transaction.sql

-- Lesson 04: Transactions — COMMIT, ROLLBACK, SAVEPOINT

-- ============================================================
-- DEMO 1: Successful transfer with COMMIT
-- ============================================================

-- Start point
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Transfer $200 from Alice to Bob
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;

-- Verify before committing (only visible in this session)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 800, Bob: 700

-- Make it permanent
COMMIT;

-- Now everyone can see it
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- DEMO 2: ROLLBACK — undo everything
-- ============================================================

-- Try to transfer $300 from Alice to Bob, then change mind
UPDATE accounts SET balance = balance - 300 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 300 WHERE account_id = 2;

-- Check state (not committed yet)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 500, Bob: 1000

-- Undo it — ROLLBACK takes us back to the last COMMIT
ROLLBACK;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 800, Bob: 700 — back to post-COMMIT state


-- ============================================================
-- DEMO 3: SAVEPOINT — partial rollback
-- ============================================================

-- Multi-step workflow: update Alice, set a savepoint, update Bob, decide to undo only Bob
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

SAVEPOINT after_alice;

UPDATE accounts SET balance = balance + 100 WHERE account_id = 3;  -- Charlie, not Bob

-- Actually no — wrong account. Roll back to savepoint, not the beginning.
ROLLBACK TO SAVEPOINT after_alice;

-- Alice's change is still pending, Charlie's is undone
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 700 (pending), Bob: 700, Charlie: 250 (restored)

-- Now do the right update
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 700, Bob: 800, Charlie: 250

COMMIT;

 