# Spider Engine Setup

## Assumptions

- The Enterprise server version is 10.4.12 or higher
- Primary/Replica setup
- Additional 3rd node which is running the Enterprise ColumnStore 1.4 or higher

## Installing Spider Engine

Logon to MariaDB client on the primary node and execute the spider scripts `/usr/share/mysql/install_spider.sql` which are natively privided with the server. This script will install Spider engine on the server.

```txt
es-201 [mydb]> SOURCE /usr/share/mysql/install_spider.sql
Query OK, 0 rows affected, 1 warning (0.000 sec)

Query OK, 0 rows affected (0.005 sec)

Empty set (0.007 sec)

Empty set (0.007 sec)

Query OK, 0 rows affected (0.008 sec)

Query OK, 0 rows affected (0.003 sec)

es-201 [mydb]> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| SPIDER             | YES     | Spider storage engine                                                                           | YES          | YES  | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
| S3                 | NO      | Read only table stored in S3. Created by running ALTER TABLE table_name ENGINE=s3               | NULL         | NULL | NULL       |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| wsrep              | YES     | Wsrep replication plugin                                                                        | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
11 rows in set (0.000 sec)
```

On the ColumnStore server, create a dedicated user to be used for Spider engine connectivity and grant all privileges to the database which will be accessed through Spider engine.

Second step is to create a new table using ColumnStore engine on this node and insert some dummy data. 

```txt
MariaDB [testdb]> create user spider@'192.168.56.%' identified by 'P@ssw0rd';
Query OK, 0 rows affected (0.004 sec)

MariaDB [testdb]> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Columnstore        | YES     | ColumnStore storage engine                                                                      | YES          | NO   | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
| S3                 | NO      | Read only table stored in S3. Created by running ALTER TABLE table_name ENGINE=s3               | NULL         | NULL | NULL       |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| wsrep              | YES     | Wsrep replication plugin                                                                        | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
11 rows in set (0.000 sec)

MariaDB [testdb]> grant all on testdb.* to spider@'192.168.56.%';
Query OK, 0 rows affected (0.003 sec)

MariaDB [testdb]> CREATE TABLE spider_cs (id int, c1 varchar(100)) ENGINE=ColumnStore;
Query OK, 0 rows affected (0.005 sec)

MariaDB [testdb]> INSERT INTO spider_cs SELECT ordinal_position, column_name from information_schema.columns;
...
...
...
```

On the primary node, create a Spider table. This table will be a virtual table without any data and the `COMMENT` section will be defined to connect to the ColumnStore node using the new `spider@192.168.56.%` user account.

Before we do that, we need to define the remote server using `CREATE SERVER` command and then use that server in the `COMMENT` section as shown bellow.

```
es-201 [mydb]> CREATE SERVER cs_node FOREIGN DATA WRAPPER mysql
OPTIONS (
   HOST '192.168.56.203',
   DATABASE 'testdb',
   USER 'spider',
   PASSWORD 'P@ssw0rd',
   PORT 3306);

Query OK, 0 rows affected (0.003 sec)   

es-201 [mydb]> CREATE TABLE spider_tab
(id int, c1 varchar(100)) ENGINE=Spider
COMMENT='wrapper "mysql", srv "cs_node", table "spider_cs"';

Query OK, 0 rows affected (0.004 sec)

es-201 [mydb]> show create table spider_tab\G
*************************** 1. row ***************************
       Table: spider_tab
Create Table: CREATE TABLE `spider_tab` (
  `id` int(11) DEFAULT NULL,
  `c1` varchar(100) DEFAULT NULL
) ENGINE=SPIDER DEFAULT CHARSET=latin1 COMMENT='wrapper "mysql", srv "cs_node", table "spider_cs"'
1 row in set (0.003 sec)
```

Spider virtual table is ready, lets do a quick test and try to select some data;

```txt
es-201 [mydb]> select count(*) from spider_tab;
+----------+
| count(*) |
+----------+
|   498688 |
+----------+
1 row in set (0.113 sec) 
```

This data is indeed coming from the ColumnStore table on a remote server which we created in advance. 

In this example, we are joining a local InnoDB table with a Spider table which internally is connected to a UM node of a ColumnStore setup :)

InnoDB = Spider->UM1->ColumnStore(PM Nodes)

```
es-201 [mydb]> select * from spider_tab a inner join innodb_tx b on a.id = b.id where a.id < 100 limit 100;
+------+----------------------------+----+------------------+
| id   | c1                         | id | c1               |
+------+----------------------------+----+------------------+
|   16 | avgrowlen                  | 16 | IS_GRANTABLE     |
|   97 | db_name                    | 97 | FILE_TYPE        |
|   77 | PAGES_NOT_MADE_YOUNG       | 77 | EVENT_DEFINITION |
|   95 | compress_ops               | 95 | FILE_ID          |
|   77 | Name                       | 77 | EVENT_DEFINITION |
|   82 | MAX_TIMER_WAIT             | 82 | SQL_MODE         |
|   73 | ACTION_REFERENCE_OLD_TABLE | 73 | EVENT_NAME       |
|   86 | TREE_OBJECT_ID             | 86 | ON_COMPLETION    |
|   29 | SUM_SELECT_FULL_RANGE_JOIN | 29 | ID               |
|   52 | WRITE_LOCKED_BY_THREAD_ID  | 52 | EXTRA            |
+------+----------------------------+----+------------------+
10 rows in set (0.351 sec)
```

Thank You!
