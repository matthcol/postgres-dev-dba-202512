 ## Creation base + user + schema
 User postgres:
 ```
 psql -f 00-initdb.sql
 ```

 ## Tables + data
 User cinema:
 ```
 psql -U cinema -h localhost -d dbcinema -f 00b-import-tables.sql
 ```
