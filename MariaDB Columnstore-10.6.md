# MariaDB Enterprise ColumnStore 10.6

## Multi-Node Install

## Assumptions

The base assumption are:

- MariaDB Enterprise Server 10.6.12 or higher is used with the latest CMAPI
- RHEL/Rocky Linux 8 or higher
- Firewals open between all the nodes for the ports `3306, 8600 - 8800`
  - We will disable firewall completely for this setup
- SELinux is in `permissive` mode
- Customer Download Token is ready
  - Token can be retrieved using MariaDB customer account at: https://customers.mariadb.com/downloads/token/

## Nodes

The nodes used in this guide are as follows

- MaxScale 23.02 (172.31.21.126)
  - ColumnStore Node 1 (172.31.18.239)
  - ColumnStore Node 2 (172.31.28.97)
  - ColumnStore Node 3 (172.31.28.224)


172.31.21.126	mxs
172.31.18.239	mcs1
172.31.28.97	mcs2
172.31.28.224	mcs3

## Preperation of the ColumnStore Nodes

Connect to all three ColumnStore nodes and create a new file `/etc/sysctl.d/90-mariadb-enterprise-columnstore.conf`

Add the following block to this file

```txt
# minimize swapping
vm.swappiness = 1

# Increase the TCP max buffer size
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Increase the TCP buffer limits
# min, default, and max number of bytes to use
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# don't cache ssthresh from previous connection
net.ipv4.tcp_no_metrics_save = 1

# for 1 GigE, increase this to 2500
# for 10 GigE, increase this to 30000
net.core.netdev_max_backlog = 2500
```

Once saved, load this setup using 

```txt
shell> sysctl --load=/etc/sysctl.d/90-mariadb-enterprise-columnstore.conf

vm.swappiness = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 2500
```

The above output will confirm the optimizations have been loaded successfully.

### Temporarily Disable Security

Set the SELinux to `permissive` 

```
shell> setenforce permissive
```

Edit the `/etc/selinux/config` and change `SELINUX=permissive`, save and exit.

### Temporarily Disable Firewall

Temporarily disable the `firewalld` service for the installation by execuding `systemctl stop firewalld && systemctl disable firewalld`.

ColumnStore requires the following ports to be opened between all the nodes, make sure these ports are opened between all the nodes for two way communication.

- 3306 - Port used for MariaDB Client traffic
- 8600-8630 - Port range used for inter-node communication
- 8640 - Port used by CMAPI
- 8700 - Port used for inter-node communication
- 8800 - Port used for inter-node communication

### Character Encoding Setup

On RHEL8/Rocky8 install the dependencies

```
shell> yum install glibc-locale-source glibc-langpack-en -y
```

The system's locale is to be done on any version of Linux

```
shell> localedef -i en_US -f UTF-8 en_US.UTF-8
```

### Hostname Setup

On all the nodes including the MaxScale node, edit the `/etc/hosts` and append the following table

```
172.31.21.126	mxs1
172.31.18.239	mcs1
172.31.28.97	mcs2
172.31.28.224	mcs3
```

### Prepare the shared storage (NFS)

On the NFS storage, create and mount the following three folders

- `/var/lib/columnstore/data1`
- `/var/lib/columnstore/data2`
- `/var/lib/columnstore/data3`

These three folders should be available and mounted on all the three nodes for HA.

## Install MariaDB ES

### Setup MariaDB ES Repositories

Either we setup the repositories or downlad the RPM package from mariadb.comn, both methods are fine.

Perform this on all the three ColumnStore nodes

```
shell> yum install wget -y && wget https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup && chmod +x mariadb_es_repo_setup
shell> ./mariadb_es_repo_setup --token="**Customer-Download-Token**" --apply \
      --skip-maxscale \
      --skip-tools \
      --mariadb-server-version="10.6"
```

Install the dependencies

```
shell> yum install epel-release -y
shell> yum install jemalloc jq curl -y
shell> yum install MariaDB-server \
   MariaDB-backup \
   MariaDB-shared \
   MariaDB-client \
   MariaDB-columnstore-engine \
   MariaDB-columnstore-cmapi -y
```

This will install MariaDB + ColunStore engine on all the three ColumnStore nodes

Edit the `/etc/my.cnf.d/server.cnf` file and append the following under `[mariadb]` header

**`mcs1`**
```
[mariadb]
bind_address                           = 0.0.0.0
log_error                              = mariadbd.err
character_set_server                   = utf8
collation_server                       = utf8_general_ci
log_bin                                = mariadb-bin
log_bin_index                          = mariadb-bin.index
relay_log                              = mariadb-relay
relay_log_index                        = mariadb-relay.index
log_slave_updates                      = ON
gtid_strict_mode                       = ON
columnstore_use_import_for_batchinsert = ALWAYS
columnstore_cache_inserts              = ON

# This must be unique on each Enterprise ColumnStore node
server_id                              = 1000
```

**`mcs2`**
```
[mariadb]
bind_address                           = 0.0.0.0
log_error                              = mariadbd.err
character_set_server                   = utf8
collation_server                       = utf8_general_ci
log_bin                                = mariadb-bin
log_bin_index                          = mariadb-bin.index
relay_log                              = mariadb-relay
relay_log_index                        = mariadb-relay.index
log_slave_updates                      = ON
gtid_strict_mode                       = ON
columnstore_use_import_for_batchinsert = ALWAYS
columnstore_cache_inserts              = ON

# This must be unique on each Enterprise ColumnStore node
server_id                              = 2000
```

**`mcs3`**
```
[mariadb]
bind_address                           = 0.0.0.0
log_error                              = mariadbd.err
character_set_server                   = utf8
collation_server                       = utf8_general_ci
log_bin                                = mariadb-bin
log_bin_index                          = mariadb-bin.index
relay_log                              = mariadb-relay
relay_log_index                        = mariadb-relay.index
log_slave_updates                      = ON
gtid_strict_mode                       = ON
columnstore_use_import_for_batchinsert = ALWAYS
columnstore_cache_inserts              = ON

# This must be unique on each Enterprise ColumnStore node
server_id                              = 3000
```

On each of the Three MariaDB ES nodes perform the following

```
shell> systemctl restart mariadb
shell> systemctl enable mariadb
shell> systemctl stop mariadb-columnstore
shell> systemctl restart mariadb-columnstore-cmapi
shell> systemctl enable mariadb-columnstore-cmapi
```

## Configure The Database

### Create Utility User

The utility user is used for internal communication and for queries which perform cross engine joins

On the primary server **`mcs1`** connect to MariaDB client and perform the following

```
MariaDB> CREATE USER 'util_user'@'127.0.0.1' IDENTIFIED BY 'SecretPassword1!';
MariaDB> GRANT SELECT, PROCESS ON *.* TO 'util_user'@'127.0.0.1';
```

On each of the MariaDB ColumnStore nodes perform the following tasks

```
shell> mcsSetConfig CrossEngineSupport Host 127.0.0.1
shell> mcsSetConfig CrossEngineSupport Port 3306
shell> mcsSetConfig CrossEngineSupport User util_user
```

On the Primary server **`mcs1`** generate the encrypted password for the `util_user`

```
shell> cskeys
Permissions of '/var/lib/columnstore/.secrets' set to owner:read.
Ownership of '/var/lib/columnstore/.secrets' given to mysql.
```

The above `cskeys` would have generated a `/var/lib/columnstore/.secrets` on the Primary server, we would need to copy it manually to the remaining two ColumnStore nodes.

```
shell> cspasswd SecretPassword1!
DDB2E0675546ECD99C778389CEF4E54DF10D5BC452BCE6C6D281E389F82E9A0E78CABFD70E2A0F78C47A7CA3DC423678
```

The above will generate an encrpted password for the util_user, copy that encrypted value and excute the following on **all three** ColumnStore nodes

```
shell> mcsSetConfig CrossEngineSupport Password DDB2E0675546ECD99C778389CEF4E54DF10D5BC452BCE6C6D281E389F82E9A0E78CABFD70E2A0F78C47A7CA3DC423678
```

### Create Replication User

Replication user does not replicate ColumnStore data, ColumbnStore will handle that on it's own. This user is to synchronise all non ColumnStore related objects, such as users, grants, databases, stored procedures, views, etc. 

Execute the following on the Primary node **`mcs1`** only.

```
MariaDB> CREATE USER 'repl'@'172.31.%' IDENTIFIED BY 'SecretPassword1!';
MariaDB> GRANT REPLICA MONITOR,
   REPLICATION REPLICA,
   REPLICATION REPLICA ADMIN,
   REPLICATION MASTER ADMIN
ON *.* TO 'repl'@'172.31.%';
```

### Create MaxScale User

The MaxScale user will be used for MaxScale monitoring, query routinng and high availability. Execute the following on the Primary node **`mcs1`** only.

```
MariaDB> CREATE USER 'mxs'@'172.31.%' IDENTIFIED BY 'SecretPassword1!';
MariaDB> GRANT SHOW DATABASES ON *.* TO 'mxs'@'172.31.%';
MariaDB> GRANT SELECT ON mysql.* TO 'mxs'@'172.31.%';
MariaDB> GRANT BINLOG ADMIN,
   READ_ONLY ADMIN,
   RELOAD,
   REPLICA MONITOR,
   REPLICATION MASTER ADMIN,
   REPLICATION REPLICA ADMIN,
   REPLICATION REPLICA,
   SHOW DATABASES,
   SELECT
ON *.* TO 'mxs'@'172.31.%';
```

### MariaDB Replication

Now that the replication user has been created, execute the following steps on **`mcs2`** and **`mcs3`** nodes to start the replication from **`mcs1`**

```
MariaDB> CHANGE MASTER TO
   MASTER_HOST='172.31.18.239',
   MASTER_USER='repl',
   MASTER_PASSWORD='SecretPassword1!',
   MASTER_USE_GTID=slave_pos;
MariaDB> SET GLOBAL read_only=ON;
MariaDB> START REPLICA;
MariaDB> SHOW REPLICA STATUS\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 172.31.18.239
                   Master_User: repl
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mariadb-bin.000001
           Read_Master_Log_Pos: 1927
                Relay_Log_File: mariadb-relay.000002
                 Relay_Log_Pos: 2228
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
           Exec_Master_Log_Pos: 1927
               Relay_Log_Space: 2535
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
                    Using_Gtid: Slave_Pos
                   Gtid_IO_Pos: 0-1000-8
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
              Slave_DDL_Groups: 8
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.000 sec)
```

The `SHOW REPLICA STATUS` will give the replication status report, we should be able to see SQL thread and IO threads running with `YES`, this confirms the replication is now working between `mcs1`, `mcs2` and, `mcs3` nodes.

## Initiate CMAPI on the Prmary server

We need to create a unique API key for CMAPI, as an example using the `openssl rand` is a great way to get a unique 256 bit key. Perform the following on Primary node **`mcs1`**.

```
shell> openssl rand -hex 32
12aed3a198e5696dd394fa0ce6ae2cb0e2b5ace8def9ec8dd1b9842bb28c2473
```

The above key will be user for this guide.

### Add the Primary Node to CMAPI

ColumnStore uses CMAPI for cluster management like, start, stop, status, add node, etc. The API uses `curl` to talk to the nodes.

```
shell> curl -k -s -X PUT https://mcs1:8640/cmapi/0.4.0/cluster/node \
   --header 'Content-Type:application/json' \
   --header 'x-api-key:12aed3a198e5696dd394fa0ce6ae2cb0e2b5ace8def9ec8dd1b9842bb28c2473' \
   --data '{"timeout":120, "node": "172.31.18.239"}' \
   | jq .

{
  "timestamp": "2023-04-14 02:01:30.243852",
  "node_id": "172.31.18.239"
}
```

Here the `PUT` represents the `mcs1` node and it will remain the same for all other commands. 
`x-api-key` represents the Key that we generated earlier using `openssl rand`
the `"node":` at the last line represents the IP of the node we are trying to add to the CMAPI, in this case the IP is for the primary node **`mcs1`**. The last three lines between the curly brackets are the output of the curl command to add node. This output returns a successful status since there is no error reported.

Let's check the status of the cluster as of now

```
shell> curl -k -s https://mcs1:8640/cmapi/0.4.0/cluster/status \
   --header 'Content-Type:application/json' \
   --header 'x-api-key:12aed3a198e5696dd394fa0ce6ae2cb0e2b5ace8def9ec8dd1b9842bb28c2473' \
   | jq .

{
  "timestamp": "2023-04-14 02:02:01.447150",
  "172.31.18.239": {
    "timestamp": "2023-04-14 02:02:01.462003",
    "uptime": 8496,
    "dbrm_mode": "master",
    "cluster_mode": "readwrite",
    "dbroots": [
      "1"
    ],
    "module_id": 1,
    "services": [
      {
        "name": "workernode",
        "pid": 41105
      },
      {
        "name": "controllernode",
        "pid": 41116
      },
      {
        "name": "PrimProc",
        "pid": 41133
      },
      {
        "name": "WriteEngine",
        "pid": 41164
      },
      {
        "name": "DMLProc",
        "pid": 41173
      },
      {
        "name": "DDLProc",
        "pid": 41195
      }
    ]
  },
  "num_nodes": 1
}
```

The output will be a nicely formatted JSON structure which will explain the node1 as a part of the cluster. 

### Add replicas to CMAPI

Now that the Primary node has been added, we will add the remaining two nodes `mcs2` and `mcs3` to the clsuter. Execute the following from the Primary node **`mcs1`**.

```
shell> curl -k -s -X PUT https://mcs1:8640/cmapi/0.4.0/cluster/node \
   --header 'Content-Type:application/json' \
   --header 'x-api-key:12aed3a198e5696dd394fa0ce6ae2cb0e2b5ace8def9ec8dd1b9842bb28c2473' \
   --data '{"timeout":120, "node": "172.31.28.97"}' \
   | jq .

{
  "timestamp": "2023-04-14 02:07:52.796284",
  "node_id": "172.31.28.97"
}

shell> curl -k -s -X PUT https://mcs1:8640/cmapi/0.4.0/cluster/node \
   --header 'Content-Type:application/json' \
   --header 'x-api-key:12aed3a198e5696dd394fa0ce6ae2cb0e2b5ace8def9ec8dd1b9842bb28c2473' \
   --data '{"timeout":120, "node": "172.31.28.224"}' \
   | jq .

{
  "timestamp": "2023-04-14 02:09:00.519374",
  "node_id": "172.31.28.224"
}
```

The two replica nodes successfully added to the CMAPI. Let's check the status of the cluster

```
shell> curl -k -s https://mcs1:8640/cmapi/0.4.0/cluster/status \
   --header 'Content-Type:application/json' \
   --header 'x-api-key:12aed3a198e5696dd394fa0ce6ae2cb0e2b5ace8def9ec8dd1b9842bb28c2473' \
   | jq .

{
  "timestamp": "2023-04-14 02:11:17.467983",
  "172.31.18.239": {
    "timestamp": "2023-04-14 02:11:17.479769",
    "uptime": 9052,
    "dbrm_mode": "master",
    "cluster_mode": "readwrite",
    "dbroots": [
      "1"
    ],
    "module_id": 1,
    "services": [
      {
        "name": "workernode",
        "pid": 41781
      },
      {
        "name": "controllernode",
        "pid": 41792
      },
      {
        "name": "PrimProc",
        "pid": 41809
      },
      {
        "name": "WriteEngine",
        "pid": 41844
      },
      {
        "name": "DMLProc",
        "pid": 41854
      },
      {
        "name": "DDLProc",
        "pid": 41885
      }
    ]
  },
  "172.31.28.97": {
    "timestamp": "2023-04-14 02:11:17.543271",
    "uptime": 9052,
    "dbrm_mode": "slave",
    "cluster_mode": "readonly",
    "dbroots": [
      "2"
    ],
    "module_id": 2,
    "services": [
      {
        "name": "workernode",
        "pid": 41139
      },
      {
        "name": "PrimProc",
        "pid": 41161
      },
      {
        "name": "WriteEngine",
        "pid": 41187
      }
    ]
  },
  "172.31.28.224": {
    "timestamp": "2023-04-14 02:11:17.587608",
    "uptime": 9052,
    "dbrm_mode": "slave",
    "cluster_mode": "readonly",
    "dbroots": [
      "3"
    ],
    "module_id": 3,
    "services": [
      {
        "name": "workernode",
        "pid": 41090
      },
      {
        "name": "PrimProc",
        "pid": 41112
      },
      {
        "name": "WriteEngine",
        "pid": 41138
      }
    ]
  },
  "num_nodes": 3
}
```

Let's test ColumnStore!

## Test ColumnStore

Now that three nodes have been added to the cluster, we can connect to the Primary node and perform some transactions. Remember it's still a Primary/Replica setup and the replica nodes should not be used for transactions. Only primary nodes is going to be used for "Write" operations, replica nodes can be used for "Reads".

```
MariaDB> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Columnstore        | YES     | ColumnStore storage engine                                                                      | YES          | NO   | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
9 rows in set (0.000 sec)
```

ColumnStore engine is avialable. 

```
MariaDB [(none)]> CREATE DATABASE testdb;
Query OK, 1 row affected (0.000 sec)

MariaDB> USE testdb;
Database changed
MariaDB [testdb]> CREATE TABLE t_cs(id int, c char(10)) ENGINE=ColumnStore;
Query OK, 0 rows affected (0.480 sec)

MariaDB> INSERT INTO t_cs SELECT seq, Concat('D-', seq) from seq_1_to_10000000;
Query OK, 10000000 rows affected (12.415 sec)
Records: 10000000  Duplicates: 0  Warnings: 0

MariaDB> SELECT COUNT(*) FROM t_cs;
+----------+
| COUNT(*) |
+----------+
| 10000000 |
+----------+
1 row in set (0.370 sec)
```

10 million rows inserted in 12.45 seconds, COUNT(*) less than half a second. Comparing this with InnoDB.

```
MariaDB> CREATE TABLE t_inno(id int, c char(10)) ENGINE=InnoDB;
Query OK, 0 rows affected (0.008 sec)

MariaDB> INSERT INTO t_inno SELECT seq, Concat('D-', seq) from seq_1_to_10000000;
Query OK, 10000000 rows affected (25.871 sec)
Records: 10000000  Duplicates: 0  Warnings: 0

MariaDB> SELECT COUNT(*) FROM t_inno;
+----------+
| COUNT(*) |
+----------+
| 10000000 |
+----------+
1 row in set (14.473 sec)
```

The timing is drastically different.

## MaxScale

Refer to the following for Installing and Configuring MaxScale 22.08

- <https://mariadb.com/docs/server/deploy/topologies/columnstore-shared-local-storage/enterprise-server-10-6/install-mxs/>
- <https://mariadb.com/docs/server/deploy/topologies/columnstore-shared-local-storage/enterprise-server-10-6/config-mxs/>

### Thank You!