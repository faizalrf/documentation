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
MariaDB [testdb]> select * from salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 365.00 | 2020-01-15 00:00:00 |
|  2 |      1 | 365.00 | 2020-02-15 00:00:00 |
|  3 |      1 | 368.00 | 2020-03-15 00:00:00 |
|  4 |      1 | 368.00 | 2020-04-15 00:00:00 |
|  5 |      1 | 368.00 | 2020-05-15 00:00:00 |
|  6 |      1 | 368.00 | 2020-06-15 00:00:00 |
|  7 |      1 | 370.00 | 2020-07-15 00:00:00 |
|  8 |      1 | 370.00 | 2020-08-15 00:00:00 |
|  9 |      1 | 401.00 | 2020-09-15 00:00:00 |
| 10 |      1 | 401.00 | 2020-10-15 00:00:00 |
| 11 |      1 | 401.00 | 2020-11-15 00:00:00 |
| 12 |      1 | 401.00 | 2020-12-15 00:00:00 |
+----+--------+--------+---------------------+
12 rows in set (0.000 sec)
```

Assuming we want to archive the January 2020's salary record(s) to `s3_salary` as a new partition, we know the S3 partition name for January 2020 is `P01`

Here is what we have to do 

- Create a table with the same structure as the partitioned table `s3_salary` but without partitioning using InnoDB/Aria storage engine. 
- Copy January's salary record(s) to a new Aria/InnoDB table
- Alter that table to use S3 storage
- Alter the `s3_salary` table and replace the existing `P01` partition with this new table

Let's see how

```SQL
MariaDB [testdb]> CREATE TABLE `s3_salary_2020_01` (
  `id` int(10) unsigned NOT NULL,
  `emp_id` int(11) DEFAULT NULL,
  `salary` double(18,2) DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`,`dt`)
) ENGINE=InnoDB;

Query OK, 0 rows affected (2.850 sec)

MariaDB [testdb]> insert into s3_salary_2020_01 select * from salary where dt < '2020-02-01';
Query OK, 1 row affected (0.020 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> alter table s3_salary_2020_01 engine=S3;
Query OK, 1 row affected (4.557 sec)               
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> alter table s3_salary exchange partition P01 with table s3_salary_2020_01;
Query OK, 0 rows affected (14.637 sec)
```

Now the January 2020's data can be deleted from the InnoDB table.

```SQL
MariaDB [testdb]> DELETE FROM salary where dt < '2020-02-01';
Query OK, 1 row affected (0.016 sec)

MariaDB [testdb]> SELECT * FROM s3_salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 365.00 | 2020-01-15 00:00:00 |
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

MariaDB [testdb]> insert into s3_salary_2020_02 select * from salary where dt < '2020-03-01';
Query OK, 1 row affected (0.016 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> ALTER TABLE s3_salary_2020_02 engine=S3;
Query OK, 1 row affected (4.374 sec)               
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [testdb]> alter table s3_salary exchange partition P02 with table s3_salary_2020_02;
Query OK, 0 rows affected (15.075 sec)

MariaDB [testdb]> DELETE FROM salary where dt < '2020-03-01';
Query OK, 1 row affected (0.015 sec)
```

Now the primary `salary` table has no data for Jan 2020 and Feb 2020, that has been moved to S3 to the partitioned table `s3_salary`.

We can now see that the `salary` table has 10 rows, `s3_salary` has 2 rows and a simple **UNION ALL** sql between the two table returns the full set. 

```SQL
MariaDB [testdb]> select * from s3_salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 365.00 | 2020-01-15 00:00:00 |
|  2 |      1 | 365.00 | 2020-02-15 00:00:00 |
+----+--------+--------+---------------------+
2 rows in set (2.889 sec)

MariaDB [testdb]> select * from salary;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  3 |      1 | 368.00 | 2020-03-15 00:00:00 |
|  4 |      1 | 368.00 | 2020-04-15 00:00:00 |
|  5 |      1 | 368.00 | 2020-05-15 00:00:00 |
|  6 |      1 | 368.00 | 2020-06-15 00:00:00 |
|  7 |      1 | 370.00 | 2020-07-15 00:00:00 |
|  8 |      1 | 370.00 | 2020-08-15 00:00:00 |
|  9 |      1 | 401.00 | 2020-09-15 00:00:00 |
| 10 |      1 | 401.00 | 2020-10-15 00:00:00 |
| 11 |      1 | 401.00 | 2020-11-15 00:00:00 |
| 12 |      1 | 401.00 | 2020-12-15 00:00:00 |
+----+--------+--------+---------------------+
10 rows in set (0.000 sec)

MariaDB [testdb]> select * from salary union all select * from s3_salary order by dt;
+----+--------+--------+---------------------+
| id | emp_id | salary | dt                  |
+----+--------+--------+---------------------+
|  1 |      1 | 365.00 | 2020-01-15 00:00:00 |
|  2 |      1 | 365.00 | 2020-02-15 00:00:00 |
|  3 |      1 | 368.00 | 2020-03-15 00:00:00 |
|  4 |      1 | 368.00 | 2020-04-15 00:00:00 |
|  5 |      1 | 368.00 | 2020-05-15 00:00:00 |
|  6 |      1 | 368.00 | 2020-06-15 00:00:00 |
|  7 |      1 | 370.00 | 2020-07-15 00:00:00 |
|  8 |      1 | 370.00 | 2020-08-15 00:00:00 |
|  9 |      1 | 401.00 | 2020-09-15 00:00:00 |
| 10 |      1 | 401.00 | 2020-10-15 00:00:00 |
| 11 |      1 | 401.00 | 2020-11-15 00:00:00 |
| 12 |      1 | 401.00 | 2020-12-15 00:00:00 |
+----+--------+--------+---------------------+
12 rows in set (0.001 sec)
```

Thank you!