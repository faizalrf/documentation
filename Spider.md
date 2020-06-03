# New look at HTAP Using SPIDER engine

## Assumptions

- The Enterprise server version is 10.4.12 or higher
- ColumnStore engine already installed

## Installing Spider Engine

Connect to the MariaDB client using the root user or a user with necessary priviliges to be able to install a new plugin/engine. Once connected, execute the spider scripts `/usr/share/mysql/install_spider.sql` which are natively privided with the server. This script will install Spider engine on the server.

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
| Columnstore        | YES     | ColumnStore storage engine                                                                      | YES          | NO   | NO         |
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

Create a dedicated user to be used by the Spider engine and grant all privileges to the database which we want accessed through the Spider engine.

```txt
MariaDB [testdb]> create user spider@'localhost' identified by 'P@ssw0rd';
Query OK, 0 rows affected (0.004 sec)

MariaDB [testdb]> grant all on testdb.* to spider@'localhost';
Query OK, 0 rows affected (0.003 sec)
```

We now need to define a server using `CREATE SERVER`, usually this server points to a remote machine as a traditional setup, but for our case case (HTAP on the same server), we will define our current `node` as the "spidernode" as shown bellow.

Asuming we have a multi-node MariaDB Enterprise platform setup, we need to add the same `spidernode` in both server's host files so that the spider node can be access from either Primary or Replica node without any problems.

`/etc/hosts` file on Primary Node

```
spidernode 10.0.0.1
```

`/etc/hosts` file on Replica Node

```
spidernode 10.0.0.2
```

The above setup will force the following SERVER definitation to look at the current server whichever it may be to access both InnoDB and ColumnStore tables

```
es-201 [mydb]> CREATE SERVER node FOREIGN DATA WRAPPER mysql
OPTIONS (
   HOST 'spidernode',
   DATABASE 'testdb',
   USER 'spider',
   PASSWORD 'P@ssw0rd',
   PORT 3306);

Query OK, 0 rows affected (0.003 sec)   
```

### Creating a Spider table

Now that we have the spider engine and the `server` created by the neame `node`, we can connect to the two underlying tables tables, one using InnoDB to represet current live data for six months to a year and the other table using ColumnStore to represent archived data for multiple years.

- Spider table `acct_detail` joining the following two
  - InnoDB table `acct_detail_curr` that contains current live data
  - ColumnStore table `acct_detail_hist` that containts histical data

The application wants to access these two tables seamlessly without worring about where the data is coming from.

Assumption is that we have the following two table already created on our current database.

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

We can now create a spider node, using the already created server `node` wrapper.

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

Let's execute a `SELECT` statement on our spider (logical) table

```sql
es-201 [mydb]> SELECT * FROM acct_detail LIMIT 10;
ERROR 12720 (HY000): Host:127.0.0.1 and Port:3306 aim self server. Please change spider_same_server_link parameter if this link is required.
```

Since SPIDER node is connecting to itself, both partitions (InnoDB & ColumnStore) on the same MariaDB host, we need to add the requested parameter `spider_same_server_link` in the `/etc/my.cnf.d/server.cnf` file's `[mariadb]` section.

Once added, restart MariaDB server using `mcsadmin restartsystem`

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

This shows that we are accessing data from the spider node, which retrives the data from both InnoDB `acct_detail_curr` and ColumnStore `acct_detail_hist` tables seamlessly, this is done in parallel and delivers great performance. A great usecase for this to archive old data on to a ColumnStore using S3/Object Store storage while still maintaining that data available using the high performance Columnstore engine.

The data in this example setup from 2020-05-24 and onwards is actually coming from the ColumnStore node while the data from April 2020 is from InnoDB, it all works seamlessly with delivers great performance.

All the `SELECT`, `UPDATE` and `DELETE` queries work on the Spider table, however, for `INSERT`, we must use the underlying table tables, `acct_detail_curr` or `acct_detail_hist` instead. 

Thank You!
