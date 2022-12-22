# MariaDB Primary Replica Topology

## Assumptions

MariaDB Binaries have been installed on the two or more nodes and the MariaDB server is able to start individually on all nodes.

## MariaDB Configuration

All the MariaDB Servers should have the following confugration in the `/etc/my.cnf.d/server.cnf` file for the Replication to work properly. 

```cnf
[mariadb]
gtid_domain_id=1
server_id=1000
log_bin = mariadb-bin
log_bin_index = mariadb-bin.index
binlog_format = MIXED
gtid_strict_mode = 1
bind_address = 0.0.0.0
log_slave_updates=1
log_error=server.log
session_track_system_variables=last_gtid

[mysql]
prompt=\H [\d]>\_
```

The `server_id` must have a unique value on all nodes, in this case, we will use `1000` for the first node and `2000` for the second node. 

Once this is done, proceed to configure the replication as per normal.

## Replication Setup

Create a replication user on the server with `server_id=1000` as follows

```sql
server1 [(none)]> CREATE USER 'repl'@'%' IDENTIFIED BY 'P@ssw0rd';
Query OK, 0 rows affected (0.001 sec)

server1 [(none)]> GRANT REPLICA MONITOR,
   REPLICATION REPLICA,
   REPLICATION REPLICA ADMIN,
   REPLICATION MASTER ADMIN
ON *.* TO 'repl'@'%';
Query OK, 0 rows affected (0.001 sec)
```

Once the user accounts are created on the Primary database node, connect to the second node with `server_id=2000` and set up replication. 

```sql
server2 [(none)]> set global gtid_slave_pos="";
Query OK, 0 rows affected (0.098 sec)

server2 [(none)]> show global variables like 'gtid_slave_pos';
+----------------+-------+
| Variable_name  | Value |
+----------------+-------+
| gtid_slave_pos |       |
+----------------+-------+
1 row in set (0.001 sec)

server2 [(none)]> CHANGE MASTER TO MASTER_HOST='192.168.56.61', MASTER_PORT=3306, MASTER_USER='repl', MASTER_PASSWORD='P@ssw0rd', MASTER_USE_GTID=slave_pos;
Query OK, 0 rows affected (0.088 sec)

server2 [(none)]> start slave;
Query OK, 0 rows affected (0.063 sec)

server2 [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 192.168.56.61
                   Master_User: repl
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mariadb-bin.000001
           Read_Master_Log_Pos: 129955
                Relay_Log_File: server2-relay-bin.000002
                 Relay_Log_Pos: 130256
         Relay_Master_Log_File: mariadb-bin.000001
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
               Replicate_Do_DB: 
           Replicate_Ignore_DB: 
            Replicate_Do_Table: 
        Replicate_Ignore_Table: 
       Replicate_Wild_Do_Table: 
   Replicate_Wild_Ignore_Table: 
                    Last_Errno: 0
                    Last_Error: 
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 129955
               Relay_Log_Space: 130565
               Until_Condition: None
                Until_Log_File: 
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File: 
            Master_SSL_CA_Path: 
               Master_SSL_Cert: 
             Master_SSL_Cipher: 
                Master_SSL_Key: 
         Seconds_Behind_Master: 0
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error: 
                Last_SQL_Errno: 0
                Last_SQL_Error: 
   Replicate_Ignore_Server_Ids: 
              Master_Server_Id: 1000
                Master_SSL_Crl: 
            Master_SSL_Crlpath: 
                    Using_Gtid: Current_Pos
                   Gtid_IO_Pos: 1-1000-10
       Replicate_Do_Domain_Ids: 
   Replicate_Ignore_Domain_Ids: 
                 Parallel_Mode: conservative
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for the slave I/O thread to update it
              Slave_DDL_Groups: 7
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 3
1 row in set (0.000 sec)
```

Note: The above assumes that the Primary server with `server_id=1000` has `192.168.56.61` IP address, that's why the `CHANGE MASTE$R` command points to it for replicaiton setup. 

`MASTER_USE_GTID=slave_pos` tells the MariaDB replica node to start with the current position which was set as empty string.

From the `show slave status\G` output we can also see the replica is using `Using_Gtid: Current_Pos` and it is already synced up to `Gtid_IO_Pos: 1-1000-10`

This confims that MariaDB is using GTID based replication which is required by MaxScale and is more efficient vs the traditional BINLOG position based replication.

Continue with the MaxScale guide <https://github.com/mariadb-faisalsaeed/documentation/blob/master/MaxScale.md>

## Than you!
