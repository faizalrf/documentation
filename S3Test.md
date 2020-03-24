# S3 Partitions

## Assumptions

A Table is created in S3 with pre-defined partitions to store data for the entire year

Asuming that the table `salary` has a `timestamp` column `dt`, we need to create a partitioned table using InnoDB with 12 partitions pre-defined to store data for each month. For DBS test case, create and define the partition according to the test scenario. If data is to be stored for 7 years, We would need to create partitions for 7 years in advance. This requirement will be fixed in the next release, but for now, we have to create those partitions on the S3 table in advance.

```SQL
MariaDB [testdb]> CREATE TABLE salary
(id int unsigned not null,
emp_id int,
salary double(18,2),
dt timestamp not null,
PRIMARY KEY (id)) ENGINE=InnoDB;

Query OK, 0 rows affected (1.233 sec)


MariaDB [testdb]> CREATE TABLE s3_salary
(id int unsigned not null,
emp_id int,
salary double(18,2),
dt timestamp not null,
PRIMARY KEY (id, dt)) ENGINE=InnoDB
PARTITION BY RANGE(UNIX_TIMESTAMP(dt))
(
PARTITION P01 VALUES LESS THAN (UNIX_TIMESTAMP('2020-02-01 00:00:00')),
PARTITION P02 VALUES LESS THAN (UNIX_TIMESTAMP('2020-03-01 00:00:00')),
PARTITION P03 VALUES LESS THAN (UNIX_TIMESTAMP('2020-04-01 00:00:00')),
PARTITION P04 VALUES LESS THAN (UNIX_TIMESTAMP('2020-05-01 00:00:00')),
PARTITION P05 VALUES LESS THAN (UNIX_TIMESTAMP('2020-06-01 00:00:00')),
PARTITION P06 VALUES LESS THAN (UNIX_TIMESTAMP('2020-07-01 00:00:00')),
PARTITION P07 VALUES LESS THAN (UNIX_TIMESTAMP('2020-08-01 00:00:00')),
PARTITION P08 VALUES LESS THAN (UNIX_TIMESTAMP('2020-09-01 00:00:00')),
PARTITION P09 VALUES LESS THAN (UNIX_TIMESTAMP('2020-10-01 00:00:00')),
PARTITION P10 VALUES LESS THAN (UNIX_TIMESTAMP('2020-11-01 00:00:00')),
PARTITION P11 VALUES LESS THAN (UNIX_TIMESTAMP('2020-12-01 00:00:00')),
PARTITION P12 VALUES LESS THAN (UNIX_TIMESTAMP('2021-01-01 00:00:00'))
);

Query OK, 0 rows affected (2.210 sec)


MariaDB [testdb]> ALTER TABLE s3_salary ENGINE=S3;
Query OK, 0 rows affected (35.865 sec)             
Records: 0  Duplicates: 0  Warnings: 0
```

Now we have the archival s3_salary table already moved to S3 with existing  parittions covering 1 year.

Insert some data into the InnoDB table `salary` which is priamary table locally.

```SQL
MariaDB [testdb]> INSERT INTO salary (id, emp_id, salary, dt) 
                    VALUES (1, 1, 100, '2020-01-15 00:00:00'), 
                            (2, 1, 101.10, '2020-02-15 00:00:00'), 
                            (3, 1, 100, '2020-03-15 00:00:00'), 
                            (4, 1, 200, '2020-04-15 00:00:00'), 
                            (5, 1, 210.5, '2020-05-15 00:00:00'), 
                            (6, 1, 210, '2020-06-15 00:00:00'), 
                            (7, 1, 230, '2020-07-15 00:00:00'), 
                            (8, 1, 300, '2020-08-15 00:00:00'), 
                            (9, 1, 375.99, '2020-09-15 00:00:00'), 
                            (10, 1, 540, '2020-10-15 00:00:00'), 
                            (11, 1, 600, '2020-11-15 00:00:00'), 
                            (12, 1, 630, '2020-12-15 00:00:00');
Query OK, 12 rows affected (0.019 sec)
Records: 12  Duplicates: 0  Warnings: 0

MariaDB [test]> SELECT * FROM salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 100.00 | 2020-01-15 00:00:00 |
|  2 |      1 | 101.10 | 2020-02-15 00:00:00 |
|  3 |      1 | 100.00 | 2020-03-15 00:00:00 |
|  4 |      1 | 200.00 | 2020-04-15 00:00:00 |
|  5 |      1 | 210.50 | 2020-05-15 00:00:00 |
|  6 |      1 | 210.00 | 2020-06-15 00:00:00 |
|  7 |      1 | 230.00 | 2020-07-15 00:00:00 |
|  8 |      1 | 300.00 | 2020-08-15 00:00:00 |
|  9 |      1 | 375.99 | 2020-09-15 00:00:00 |
| 10 |      1 | 540.00 | 2020-10-15 00:00:00 |
| 11 |      1 | 600.00 | 2020-11-15 00:00:00 |
| 12 |      1 | 630.00 | 2020-12-15 00:00:00 |
+----+--------+--------+---------------------+
12 rows in set (0.000 sec)
```

Assuming we want to archive the January 2020's salary record(s) to `s3_salary` as a new partition, we know the S3 partition name for January 2020 is `P01`

Here is what we have to do 

- Create a table with the same structure as the partitioned table `s3_salary` but without partitioning using InnoDB/Aria storage engine. 
- Copy January's salary record(s) to a new Aria/InnoDB table
- Alter that table to use S3 storage
- Alter the `s3_salary` table and replace the existing `P01` partition with this new table
- Drop the temporary s3 table

Let's see how, extract the structure of the s3_salary table and use it to create a local InnoDB table with a different name, easier to define a good naming convention to follow year/month as follows.

```SQL
MariaDB [test]> SHOW CREATE TABLE s3_salary\G
*************************** 1. row ***************************
       Table: s3_salary
Create Table: CREATE TABLE `s3_salary` (
  `id` int(10) unsigned NOT NULL,
  `emp_id` int(11) DEFAULT NULL,
  `salary` double(18,2) DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`,`dt`)
) ENGINE=S3 DEFAULT CHARSET=latin1
 PARTITION BY RANGE (unix_timestamp(`dt`))
(PARTITION `P01` VALUES LESS THAN (1580533200) ENGINE = S3,
 PARTITION `P02` VALUES LESS THAN (1583038800) ENGINE = S3,
 PARTITION `P03` VALUES LESS THAN (1585713600) ENGINE = S3,
 PARTITION `P04` VALUES LESS THAN (1588305600) ENGINE = S3,
 PARTITION `P05` VALUES LESS THAN (1590984000) ENGINE = S3,
 PARTITION `P06` VALUES LESS THAN (1593576000) ENGINE = S3,
 PARTITION `P07` VALUES LESS THAN (1596254400) ENGINE = S3,
 PARTITION `P08` VALUES LESS THAN (1598932800) ENGINE = S3,
 PARTITION `P09` VALUES LESS THAN (1601524800) ENGINE = S3,
 PARTITION `P10` VALUES LESS THAN (1604203200) ENGINE = S3,
 PARTITION `P11` VALUES LESS THAN (1606798800) ENGINE = S3,
 PARTITION `P12` VALUES LESS THAN (1609477200) ENGINE = S3)
1 row in set (0.000 sec)

-- Create a new Table to store January's Salary
MariaDB [testdb]> CREATE TABLE `s3_salary_2020_01` (
  `id` int(10) unsigned NOT NULL,
  `emp_id` int(11) DEFAULT NULL,
  `salary` double(18,2) DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`,`dt`)
) ENGINE=InnoDB;
Query OK, 0 rows affected (2.850 sec)
```

Copy data that is meant to be archived into this local InnoDB table that is newly created. This is going to be temporary table that we will drop once it's job is done.

```SQL
MariaDB [testdb]> INSERT INTO s3_salary_2020_01 SELECT * FROM salary WHERE dt < '2020-02-01';
Query OK, 1 row affected (0.020 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> ALTER TABLE s3_salary_2020_01 engine=S3;
Query OK, 1 row affected (4.557 sec)               
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> ALTER TABLE s3_salary EXCHANGE PARTITION P01 WITH TABLE s3_salary_2020_01;
Query OK, 0 rows affected (14.637 sec)

MariaDB [test]> DROP TABLE s3_salary_2020_01;
Query OK, 0 rows affected (0.408 sec)
```

Now the January 2020's data can be deleted from the InnoDB table.

```SQL
MariaDB [testdb]> DELETE FROM salary where dt < '2020-02-01';
Query OK, 1 row affected (0.016 sec)

MariaDB [testdb]> SELECT * FROM s3_salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 100.00 | 2020-01-15 00:00:00 |
+----+--------+--------+---------------------+
1 row in set (1.176 sec)
```

Next, we can now move February data as `s3_salary_2020_02` table to S3 partition tabe `s3_salary`, follow the same steps as previously done for January's data.

```SQL
MariaDB [testdb]> CREATE TABLE `s3_salary_2020_02` (
  `id` int(10) unsigned NOT NULL,
  `emp_id` int(11) DEFAULT NULL,
  `salary` double(18,2) DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`,`dt`)
) ENGINE=InnoDB;

MariaDB [testdb]> INSERT INTO s3_salary_2020_02 SELECT * FROM salary WHERE dt < '2020-03-01';
Query OK, 1 row affected (0.016 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> ALTER TABLE s3_salary_2020_02 engine=S3;
Query OK, 1 row affected (4.374 sec)               
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> ALTER TABLE s3_salary EXCHANGE PARTITION P02 WITH TABLE s3_salary_2020_02;
Query OK, 0 rows affected (15.075 sec)

MariaDB [test]> DROP TABLE s3_salary_2020_02;
Query OK, 0 rows affected (0.408 sec)
```

Now the primary `salary` table has no data for Jan 2020 and Feb 2020, that has been moved to S3 to the partitioned table `s3_salary`.

We can now see that the `salary` table has 10 rows, `s3_salary` has 2 rows and a simple **UNION ALL** sql between the two table returns the full set. 

```SQL
MariaDB [testdb]> DELETE FROM salary where dt < '2020-03-01';
Query OK, 1 row affected (0.015 sec)

MariaDB [test]> SELECT * FROM s3_salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 100.00 | 2020-01-15 00:00:00 |
|  2 |      1 | 101.10 | 2020-02-15 00:00:00 |
+----+--------+--------+---------------------+
2 rows in set (2.083 sec)

MariaDB [test]> SELECT * FROM salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  3 |      1 | 100.00 | 2020-03-15 00:00:00 |
|  4 |      1 | 200.00 | 2020-04-15 00:00:00 |
|  5 |      1 | 210.50 | 2020-05-15 00:00:00 |
|  6 |      1 | 210.00 | 2020-06-15 00:00:00 |
|  7 |      1 | 230.00 | 2020-07-15 00:00:00 |
|  8 |      1 | 300.00 | 2020-08-15 00:00:00 |
|  9 |      1 | 375.99 | 2020-09-15 00:00:00 |
| 10 |      1 | 540.00 | 2020-10-15 00:00:00 |
| 11 |      1 | 600.00 | 2020-11-15 00:00:00 |
| 12 |      1 | 630.00 | 2020-12-15 00:00:00 |
+----+--------+--------+---------------------+
10 rows in set (0.000 sec)

MariaDB [test]> SELECT * FROM salary UNION ALL SELECT * FROM s3_salary ORDER BY dt;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 100.00 | 2020-01-15 00:00:00 |
|  2 |      1 | 101.10 | 2020-02-15 00:00:00 |
|  3 |      1 | 100.00 | 2020-03-15 00:00:00 |
|  4 |      1 | 200.00 | 2020-04-15 00:00:00 |
|  5 |      1 | 210.50 | 2020-05-15 00:00:00 |
|  6 |      1 | 210.00 | 2020-06-15 00:00:00 |
|  7 |      1 | 230.00 | 2020-07-15 00:00:00 |
|  8 |      1 | 300.00 | 2020-08-15 00:00:00 |
|  9 |      1 | 375.99 | 2020-09-15 00:00:00 |
| 10 |      1 | 540.00 | 2020-10-15 00:00:00 |
| 11 |      1 | 600.00 | 2020-11-15 00:00:00 |
| 12 |      1 | 630.00 | 2020-12-15 00:00:00 |
+----+--------+--------+---------------------+
12 rows in set (0.001 sec)
```

Thank you!