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

_**Note:** There is no Spider storage engine requirement on this server._

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

MariaDB [testdb]> grant all on testdb.* to spider@'%';
Query OK, 0 rows affected (0.003 sec)

MariaDB [testdb]> CREATE TABLE spider_cs (id int, c1 varchar(100)) ENGINE=ColumnStore;
Query OK, 0 rows affected (0.005 sec)

MariaDB [testdb]> INSERT INTO spider_cs SELECT ordinal_position, column_name from information_schema.columns;
...
...
...
```

On the primary node, create a Spider table. This table will be a virtual table without any data and the `COMMENT` section will be defined to connect to the ColumnStore node using the new `spider@%` user account, take note that the IP address should be pointing to the MariaDB servers that will connect to ColumnStore using Spider engine, in this case we are using `%` to keep it simple.

Before we do that, we need to define the remote server using `CREATE SERVER` command and then use that server in the `COMMENT` section as shown bellow. This is asuming the privarte IP is `10.0.0.52`

```
es-201 [mydb]> CREATE SERVER node FOREIGN DATA WRAPPER mysql
OPTIONS (
   HOST '10.0.0.52',
   DATABASE 'testdb',
   USER 'spider',
   PASSWORD 'P@ssw0rd',
   PORT 3306);

Query OK, 0 rows affected (0.003 sec)   

es-201 [mydb]> CREATE TABLE spider_tab
(id int, c1 varchar(100)) ENGINE=Spider
COMMENT='wrapper "mysql", srv "node", table "spider_cs"';

Query OK, 0 rows affected (0.004 sec)

es-201 [mydb]> show create table spider_tab\G
*************************** 1. row ***************************
       Table: spider_tab
Create Table: CREATE TABLE `spider_tab` (
  `id` int(11) DEFAULT NULL,
  `c1` varchar(100) DEFAULT NULL
) ENGINE=SPIDER DEFAULT CHARSET=latin1 COMMENT='wrapper "mysql", srv "node", table "spider_cs"'
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

### Configuring Multiple tables

Let's say we want to configure two tables under one spider node

- Spider table `acct_detail` joining the following two
  - InnoDB table `acct_detail_curr` that contains current live data
  - ColumnStore table `acct_detail_hist` that containts histical data

The application wants to access these two tables seamlessly without worring about where the data is coming from.

Asume we have the following two table already created on our current database setup

```sql
es-201 [mydb]> SHOW CREATE TABLE acct_detail_curr\G
*************************** 1. row ***************************
       Table: acct_detail_curr
Create Table: CREATE TABLE `acct_detail_curr` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `c1` varchar(100) DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36856 DEFAULT CHARSET=latin1
1 row in set (0.001 sec)

es-201 [mydb]> SHOW CREATE TABLE acct_detail_hist\G
*************************** 1. row ***************************
       Table: acct_detail_hist
Create Table: CREATE TABLE `acct_detail_hist` (
  `id` bigint(20) DEFAULT NULL,
  `c1` varchar(100) DEFAULT NULL,
  `dt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=Columnstore DEFAULT CHARSET=latin1
1 row in set (0.000 sec)
```

We can now create a spider node, using the already created `node` wrapper.

```sql
es-201 [mydb]> CREATE TABLE acct_detail (id SERIAL, c1 VARCHAR(100), dt TIMESTAMP)
                ENGINE=Spider COMMENT='wrapper "mysql", srv "node"'
                PARTITION BY KEY (`id`)
                (
                  PARTITION pt_current COMMENT = 'table "acct_detail_curr"',
                  PARTITION pt_historic COMMENT = 'table "acct_detail_hist"'
                );

Query OK, 0 rows affected (0.073 sec)
```

Let's execute a `SELECT` statement on our spider node

```sql
es-201 [mydb]> SELECT * FROM acct_detail LIMIT 10;
ERROR 12720 (HY000): Host:127.0.0.1 and Port:3306 aim self server. Please change spider_same_server_link parameter if this link is required.
```

Since SPIDER node is connecting to itself, we need to add the requested parameter `spider_same_server_link` in the `/etc/my.cnf.d/server.cnf` file's `[mariadb]` section.

```sql
es-201 [mydb]> SELECT dt, COUNT(*) FROM acct_detail GROUP BY dt;
+---------------------+----------+
| dt                  | count(*) |
+---------------------+----------+
| 2020-04-24 20:39:02 |     2077 |
| 2020-04-24 20:44:54 |     2074 |
| 2020-05-24 19:10:22 |  2123776 |
| 2020-06-24 19:10:29 |  2123776 |
| 2020-07-24 19:10:33 |  2123776 |
| 2020-08-24 19:10:37 |  2123776 |
| 2020-09-24 19:10:40 |  2123776 |
| 2020-10-24 19:10:45 |  2123776 |
| 2020-11-24 19:10:54 |  2123776 |
+---------------------+----------+
9 rows in set (0.388 sec)

es-201 [mydb]> select max(id), min(id) from acct_detail;
+---------+---------+
| max(id) | min(id) |
+---------+---------+
|   34834 |       1 |
+---------+---------+
1 row in set (0.741 sec)
```

Now accessing the data from the spider node, retrives the data from both InnoDB `acct_detail_curr` and ColumnStore `acct_detail_hist` tables, this is done in parallel and delivers great performance. The data from 2020-05-24 and onwards is actually coming from teh ColumnStore node while the data from April 2020 is from InnoDB, it all works seamlessly with good performance.

Thank You!


