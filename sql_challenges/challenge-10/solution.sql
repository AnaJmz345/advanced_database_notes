-- Excercise 1

-- I ran these 2 queries on the predefined schema Academic (AD) from oracle free sql
-- List all the objects in your schema:
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

-- Also get details:
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;


-- Excercise 2
-- Execute configuration to display clearly the output
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/
SET LONG 100000
SET PAGESIZE 0

-- Saw all my tables 
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;

-- Excercise 3 - db migration

-- Executed this to erase the name of the schema and other thing in hte DDL so it is portable and can be used in otheer schemas.}
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Ran this
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;

-- and got as a result this:
CREATE TABLE "ACCOUNTS"
-- instead of the previous create I had with my schema name:
CREATE TABLE "A01644532_SCHEMA_N2SGD"."ACCOUNTS"

-- Excercise 4

-- Get DDL of a table that has foreign keys
SELECT DBMS_METADATA.GET_DDL('TABLE', 'SALE_ITEM')
FROM DUAL;

-- It will return this: FOREIGN KEY ("SALES_ID")
	 --                  REFERENCES "A01644532_SCHEMA_N2SGD"."CUSTOMER_SALE" ("SALES_ID") ENABLE, 
	 --                  FOREIGN KEY ("PRODUCT_ID")
	--                    REFERENCES "A01644532_SCHEMA_N2SGD"."PRODUCT" ("PRODUCT_ID") ENABLE

  -- Review all the schema foreign keys
  SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';

-- Check thsat the DDL says
REFERENCES "PRODUCT" ("PRODUCT_ID")
-- or this
REFERENCES "NEW_SCHEMA"."PRODUCT" ("PRODUCT_ID")

-- and not
"A01644532_SCHEMA_N2SGD"."PRODUCT"

-- Write migration list
--Migration checklist:
--1. Export all table DDL using DBMS_METADATA.
--2. Use EMIT_SCHEMA = false to remove the old schema name.
--3. Review all foreign key constraints.
--4. Check if any REFERENCES clause points to the old schema.
--5. Update schema references if needed.
--6. Reload objects in the correct order: tables, constraints, indexes, views, and code.
--7. Verify that all tables and relationships were created correctly.

-- Excercise 5

-- Check all schema's dependencies (what pobjects depend on what other objects)

SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name;

-- check what objects depend on tables to know which objects need that the tables exist first

SELECT name, type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name FROM user_tables
)
ORDER BY type, name;

