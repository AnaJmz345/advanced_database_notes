# Excercise 1

In this exercise, I used the prefeined schema Academic(AD) from freesql, using user_objects and I identified the different types of objects that exist in it. The results show that it has 7 tables and 8 indexes, which makes sense because indexes are usually created to optimize queries on tables. I also found 2 sequences, which are typically used for generating unique IDs, along with 1 procedure and 1 trigger, meaning there is some logic implemented at the database level. Additionally, there is 1 LOB object, which suggests that some tables may store large data like text or files. Also, most objects were created around the same time. 

# Excercise 2

I used DBMS_METADATA.GET_DDL to extract the full DDL of all the tables in my schema. The output shows that my schema has 7 tables: ACCOUNTS, CUSTOMER, CUSTOMER_SALE, DOC_CHUNKS, PET_CARE_LOG, PRODUCT, and SALE_ITEM. Each table includes its column definitions, data types, constraints, and some Oracle storage details. I noticed that most tables use NUMBER columns as identifiers, and several tables have primary keys, such as ACCOUNT_ID, CUST_ID, PRODUCT_ID, and composite primary keys like PRODUCT_ID + LOG_DATETIME in PET_CARE_LOG and SALES_ID + PRODUCT_ID in SALE_ITEM. I also identified foreign key relationships: CUSTOMER_SALE references CUSTOMER, PET_CARE_LOG references PRODUCT, and SALE_ITEM references both CUSTOMER_SALE and PRODUCT. Another important part is that the ACCOUNTS table includes a CHECK constraint to make sure the balance is not negative. Also, the DOC_CHUNKS table is different because it uses an identity column for CHUNK_ID and includes a VECTOR(384, FLOAT32) column, which suggests it may be used for storing embeddings or vector data. 

# Excercise 3

# Excercise 4

# Excercise 5