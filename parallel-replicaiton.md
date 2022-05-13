# Parallel Replication
 
A time comes, well, almost always, when one runs into replication performance issues as the user concurrency grows. One can tune the network, the IOPS of the storage but nothing seems to help. This is the time to implement Parallel replication.
 
There are three parallel replication modes which can be set using the `slave_parallel_mode` variable, In MariaDB 10.5+ Optimistic is the default mode.
 
- Optimistic (In Order Parallel Replication)
- Aggressive (Out of Order Parallel Replication)
- Conservative (In Order Parallel Replication)
 
Refer to <https://mariadb.com/kb/en/parallel-replication/?msclkid=e5e356a3d15711ec8f4e03f95e015af9#parallel-replication-overview> for details about all of the above modes and how the differ.
 
In this guide, we will be discussing how to tune **`Conservative`** parallel replication mode for best performance.
 
The base setting for the MariaDB server is as follows
 
```
[mariadb]
log_error          = server.log
log_bin            = mariadb-bin
log_slave_updates  = 1
gtid_domain_id     = 10
server_id          = 1000
binlog_format      = ROW
sync_binlog        = 1
relay_log_recovery = 1
 
shutdown_wait_for_slaves = 1
 
innodb_buffer_pool_size = 22G
innodb_log_file_size    = 4G
 
innodb_flush_log_at_trx_commit = 1
```
 
The important configuration to take note here are server and binary logs durability settings, specifically the following four.
 
```
sync_binlog        = 1
relay_log_recovery = 1
innodb_flush_log_at_trx_commit = 1
shutdown_wait_for_slaves = 1
```
 
All the nodes in the setup have identical configuration except for the `server_id` which needs to be distinct for each node.
 
On lower concurrency the replication seems fine and there are no noticeable replication lag, but as soon as we push the threads to 16 and beyond the replication starts to struggle and the lag is on the rise constantly.
 
## Understanding Parallel Replication
 
Standard asynchronous replication in MariaDB is single threaded operation by default but we can easily change this behaviour by changing the value of `slave_parallel_threads=<n>` on the Slave node. How can we tell what is the ideal number of threads to use for best Parallel replication results? We could simply set 10 or 16 threads but that might not be optimal and waste resources on the slave node.
 
By default, MariaDB will group transactions in commit groups if the transactions are consecutive/parallel. To calculate how many transactions are being grouped in individual commit groups, we will have to use the formula discussed in this MariaDB KB page <https://mariadb.com/kb/en/group-commit-for-the-binary-log/#measuring-group-commit-ratio>.
 
 
The idea here is to group as many transaction into a single Commit Group as possible so that all of those can be applied in parallel on the slave nodes. The commit group can be visualized with the help of this simple representation
 
```
      <-----------Time------------|
      <T0---T1---T2---T3---T4---Tn|
Txn1: ----> Commit                |
Txn2: --------> Commit            |
Txn3: ------------> Commit        |
Txn4: -------------------> Commit |
Txn5: ---------> Commit           |
      <------ Group Commit ------>|
```
 
Here the 5 transactions are committed within the given timeframe and are combined within a single "Group Commit" into the binary logs. These transaction when applied on the slaves can be applied in parallel provided these many slave threads are available.
 
Based on the formula, we can find out how many transactions are being grouped with single commit group as follows
 
Transactions per Group Commit = `(Binlog_commits (snapshot2) - Binlog_commits (snapshot1)) / (Binlog_group_commits (snapshot2) - Binlog_group_commits (snapshot1))`
 
These values can be retrieved by executing `SHOW GLOBAL STATUS WHERE Variable_name IN ('Binlog_commits', 'Binlog_group_commits');` twice with an interval of 60 seconds or more and using the results in the above mentioned formula.
 
Here is an example:
 
```
MariaDB [(none)]> SHOW GLOBAL STATUS WHERE Variable_name IN ('Binlog_commits', 'Binlog_group_commits'); SELECT sleep(60); SHOW GLOBAL STATUS WHERE Variable_name IN ('Binlog_commits', 'Binlog_group_commits');
+----------------------+-------+
| Variable_name        | Value |
+----------------------+-------+
| Binlog_commits       | 56188 |
| Binlog_group_commits | 33499 |
+----------------------+-------+
2 rows in set (0.001 sec)
 
+-----------+
| sleep(60) |
+-----------+
|         0 |
+-----------+
1 row in set (1 min 0.000 sec)
 
+----------------------+--------+
| Variable_name        | Value  |
+----------------------+--------+
| Binlog_commits       | 145275 |
| Binlog_group_commits | 70471  |
+----------------------+--------+
2 rows in set (0.001 sec)
```
 
The above two snapshots are taken 60 seconds apart. Now using the formula above
 
Transactions per Group Commit = (145275 - 56188) / (70471 - 33499) => 2.4096
 
This means that there are roughly 2.5 transactions per group. This also means that we can set the parallel slave threads to two or three to apply these transaction in parallel on the slave `slave_parallel_threads=3`
 
This is a very low number and will not make any significant impact on the performance. For this particular case, we will have to adjust the group commit frequency so that more transactions can be grouped within a single group.
 
The frequency of group commits can be changed by configuring the `binlog_commit_wait_usec` and `binlog_commit_wait_count` system variables.
 
- `binlog_commit_wait_count`
  - This indicates the number of transaction that we want to group within a single commit group
  - To set this on the Master node, `SET GLOBAL binlog_commit_wait_count=10;` indicates that we want to wait for 10 transactions to be grouped in one commit group.
  - Default for this is `0`
- `binlog_commit_wait_usec`
  - This indicates the amount of time in microseconds the server can delay flushing a committed transaction into binary log
  - This wait is immediately terminated if the `binlog_commit_wait_count` has reached.
  - Default is `100,000 ms`
 
Understandably with high amounts the server transaction throughput will be impacted and overall TPS will drop. However this needs to be carefully measured on a live test environment.
 
A good starting point is the following
 
```
SET GLOBAL binlog_commit_wait_count=10;
SET GLOBAL binlog_commit_wait_usec=10000;
```
 
Remember, these are only to be set on the MASTER and not on the slave. We can use MaxScale's promotion and demotion scripts to execute this SET GLOBAL commands on the new and old master nodes making it seamless.
 
```
[MariaDB-Monitor]
...
...
promotion_sql_file = /var/lib/maxscale/scripts/promotion.sql
demotion_sql_file = /var/lib/maxscale/scripts/demotion.sql
...
```
 
To identify the Group ID within Binary Logs the `cid` in the following GTID header line indicates it. All the transaction blocks with the same `cid` belong to the same group and can be applied in parallel.
 
```
#250339 10:50:19 server id 1000  end_log_pos 20052 	GTID 10-1000-4 cid=750 trans
...
#250339 10:50:19 server id 1000  end_log_pos 20212 	GTID 10-1000-6 cid=750 trans
...
#250339 10:50:19 server id 1000  end_log_pos 20372 	GTID 10-1000-7 cid=750 trans
```

## Tuning the Group Commit Frequency
 
After setting the `SET GLOBAL binlog_commit_wait_count=10;` and `SET GLOBAL binlog_commit_wait_usec=10000;` lets we will continue start the load test again to generate typical transactional load on the Master and measure the Binlog Commits/Binlog Group Commits as previously done.
 
 
```
MariaDB [(none)]> SHOW GLOBAL STATUS WHERE Variable_name IN ('Binlog_commits', 'Binlog_group_commits'); SELECT sleep(60); SHOW GLOBAL STATUS WHERE Variable_name IN ('Binlog_commits', 'Binlog_group_commits');
+----------------------+---------+
| Variable_name        | Value   |
+----------------------+---------+
| Binlog_commits       | 2595621 |
| Binlog_group_commits | 550563  |
+----------------------+---------+
2 rows in set (0.001 sec)
 
+-----------+
| sleep(60) |
+-----------+
|         0 |
+-----------+
1 row in set (1 min 0.000 sec)
 
+----------------------+---------+
| Variable_name        | Value   |
+----------------------+---------+
| Binlog_commits       | 2754749 |
| Binlog_group_commits | 566335  |
+----------------------+---------+
2 rows in set (0.001 sec)
```
 
Based on the above:
 
```
MariaDB [(none)]> SELECT (2754749-2595621)/(566335-550563);
+-----------------------------------+
| (2754749-2595621)/(566335-550563) |
+-----------------------------------+
|                           10.0893 |
+-----------------------------------+
1 row in set (0.000 sec)
```
 
Now we can see that there are 10 transactions being grouped per Commit Group. This also means that we should be able to set the `slave_parallel_threads=10` safely on all the slave nodes. This will ensure that all the 10 threads can apply one transaction each in parallel leading to much faster replication.
 
Another important point to take note here is the above measurement is beast done on expected peak load time so that we are prepared for the worst case scenario.
 
## Thank You!
