# Excercise 1

In this exercise, I used the prefeined schema Academic(AD) from freesql, using user_objects and I identified the different types of objects that exist in it. The results show that it has 7 tables and 8 indexes, which makes sense because indexes are usually created to optimize queries on tables. I also found 2 sequences, which are typically used for generating unique IDs, along with 1 procedure and 1 trigger, meaning there is some logic implemented at the database level. Additionally, there is 1 LOB object, which suggests that some tables may store large data like text or files. Also, most objects were created around the same time. 

# Excercise 2

In this exercise, I used DBMS_METADATA.GET_DDL to extract the structure of one of my tables (AD_COURSE_DETAILS). The output shows the full CREATE TABLE statement, including column names, data types, and constraints. I was able to identify how Oracle defines each column, whether it allows null values, and how primary keys or relationships are established. This helped me understand that DDL represents the exact structure of the database and can be used to recreate the table in another environment.

# Excercise 3

# Excercise 4

# Excercise 5