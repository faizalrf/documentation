# MariaDB 10.5 Enterprise - Galera Architecture

## Assumptions

This guide is meant to be used with MariaDB 10.5 Enterprise Server on RHEL/CentOS 7 operating systems, however the setup on RHEL/CentOS 8 should not be much different. 

## Architecture

The requirement is simple, setup 2 Galera clusters (3 nodes each) on two data centers. Setup MaxScale 2.5 binlog router to replicate data from Galera cluster on the primary data cetner to the the other Galera cluster on the secondary data center. 

Same way, a reverse replication is is to be set up from the Secondary data center to the primary data cetners using MaxScale binlog router.

ref: **Image-1**
![image info](./Images/GaleraArchitecture-3.png)

Reference Architecture using MaxScale's new Binlog router to replicate a 10.5 Galera cluster using asynchronous replication for maximum performance.

A stretched Galera cluster can be setup but if the latency numbers are bad between the two DC, galera cluster's performance will drop. It is recommended to set up two clusters instead using asyhcnronous replication for an **Active/Passive** site setup.

## Servers

We will setup the following servers in this workbook.

- MaxScale-70 (192.168.56.70) **(2.5)**
  - Galear-71 (192.168.56.71) **(10.5)**
  - Galear-72 (192.168.56.72) **(10.5)**
  - Galear-73 (192.168.56.73) **(10.5)**
- MaxScale-80 (192.168.56.80) **(2.5)**
  - Galear-81 (192.168.56.81) **(10.5)**
  - Galear-82 (192.168.56.82) **(10.5)**
  - Galear-83 (192.168.56.83) **(10.5)**

## Galera Cluster

### Install MariaDB 10.5 Enterprise Server

```
➜  yum -y install MariaDB-server MariaDB-backup galera-enterprise-4         

Dependencies Resolved

==============================================================================================================================================================================================
 Package                                               Arch                                 Version                                       Repository                                     Size
==============================================================================================================================================================================================
Installing:
 MariaDB-backup                                        x86_64                               10.5.5_3-1.el7                                mariadb-es-main                               7.0 M
 MariaDB-server                                        x86_64                               10.5.5_3-1.el7                                mariadb-es-main                                21 M
 galera-enterprise-4                                   x86_64                               26.4.5-1.el7.8                                mariadb-es-main                               9.9 M
Installing for dependencies:
 MariaDB-client                                        x86_64                               10.5.5_3-1.el7                                mariadb-es-main                               7.0 M
 boost-program-options                                 x86_64                               1.53.0-28.el7                                 base                                          156 k
 lsof                                                  x86_64                               4.87-6.el7                                    base                                          331 k
 perl-Compress-Raw-Bzip2                               x86_64                               2.061-3.el7                                   base                                           32 k
 perl-Compress-Raw-Zlib                                x86_64                               1:2.061-4.el7                                 base                                           57 k
 perl-DBI                                              x86_64                               1.627-4.el7                                   base                                          802 k
 perl-Data-Dumper                                      x86_64                               2.145-3.el7                                   base                                           47 k
 perl-IO-Compress                                      noarch                               2.061-2.el7                                   base                                          260 k
 perl-Net-Daemon                                       noarch                               0.48-5.el7                                    base                                           51 k
 perl-PlRPC                                            noarch                               0.2020-14.el7                                 base                                           36 k
 socat                                                 x86_64                               1.7.3.2-2.el7                                 base                                          290 k

Transaction Summary
==============================================================================================================================================================================================
..
..
Complete!
```

Verify the installation on all 6 nodes

```
➜  rpm -qa | grep -i mariadb
MariaDB-common-10.5.5_3-1.el7.x86_64
MariaDB-compat-10.5.5_3-1.el7.x86_64
MariaDB-client-10.5.5_3-1.el7.x86_64
MariaDB-server-10.5.5_3-1.el7.x86_64
MariaDB-backup-10.5.5_3-1.el7.x86_64

➜  rpm -qa | grep -i galera 
galera-enterprise-4-26.4.5-1.el7.8.x86_64
```

All the required binaries are insalled on all the 6 galera nodes. 

#### Galera Configuration

Now that Galera Cluster has been installed on all 6 nodes, we can now configure those as 2 separate Galera clusters, here is a reference configuration for both clusters

The following needs to be edited in the `/etc/my.cnf.d/server.cnf` file

***Note:*** Don't forget to add **`log_error=/var/lib/mysql/server.log`** under the **`[mariadb]`** section for all MariaDB nodes. 

- Primary Data Center

    ```
    [galera]
    wsrep_on=ON
    wsrep_gtid_mode=ON
    wsrep_gtid_domain_id=70
    wsrep_auto_increment_control=0
    wsrep_provider=/usr/lib64/galera-enterprise-4/libgalera_enterprise_smm.so
    wsrep_cluster_address=gcomm://192.168.56.71,192.168.56.72,192.168.56.73
    wsrep_cluster_name=DC

    # Local node setup
    wsrep_node_address=192.168.56.71
    wsrep_node_name=galera-71

    ## Data Streaming for large transactions, activate if needed
    wsrep_trx_fragment_unit=rows
    wsrep_trx_fragment_size=10000

    #Galera Cache setup for performance as 5 GB, default location is on `datadir`
    wsrep_provider_options="gcache.size=5G; gcache.keep_pages_size=5G; gcache.recover=yes; gcs.fc_factor=0.8;"

    binlog_format=row
    log_slave_updates=ON

    log_bin
    skip-slave-start=ON

    gtid_domain_id=71
    gtid-ignore-duplicates=ON
    server_id=7000
    default_storage_engine=InnoDB
    innodb_autoinc_lock_mode=2
    innodb_lock_schedule_algorithm=FCFS
    innodb_flush_log_at_trx_commit=2
    innodb_buffer_pool_size=512M
    innodb_log_file_size=512M

    auto_increment_offset=1
    auto_increment_increment=6

    character-set-server = utf8
    collation-server = utf8_unicode_ci

    ## Allow server to accept connections on all interfaces.
    bind-address=0.0.0.0
    ```

- DR Data Center

    ```
    [galera]
    wsrep_on=ON
    wsrep_gtid_mode=ON
    wsrep_gtid_domain_id=80
    wsrep_auto_increment_control=0
    wsrep_provider=/usr/lib64/galera-enterprise-4/libgalera_enterprise_smm.so
    wsrep_cluster_address=gcomm://192.168.56.81,192.168.56.82,192.168.56.83
    wsrep_cluster_name=DR

    # Local node setup
    wsrep_node_address=192.168.56.81
    wsrep_node_name=galera-81

    # Data Streaming for large transactions
    wsrep_trx_fragment_unit=rows
    wsrep_trx_fragment_size=10000

    #Galera Cache setup for performance as 5 GB, default location is on `datadir`
    wsrep_provider_options="gcache.size=5G; gcache.keep_pages_size=5G; gcache.recover=yes; gcs.fc_factor=0.8;"

    binlog_format=row
    log_slave_updates=ON

    log_bin
    skip-slave-start=ON

    gtid_domain_id=81
    gtid-ignore-duplicates=ON
    server_id=8000
    default_storage_engine=InnoDB
    innodb_autoinc_lock_mode=2
    innodb_lock_schedule_algorithm=FCFS
    innodb_flush_log_at_trx_commit=0
    innodb_buffer_pool_size=512M
    innodb_log_file_size=512M

    auto_increment_offset=4
    auto_increment_increment=6

    character-set-server = utf8
    collation-server = utf8_unicode_ci

    ## Allow server to accept connections on all interfaces.
    bind-address=0.0.0.0
    ```

***Note:** `wsrep_cluster_address` should not have any white spaces between the IP addresses!*

Referring to the above two configurations:

- **`wsrep_gtid_domain_id`** needs to be configured the with same value for each cluster.
  - We will be using **`wsrep_gtid_domain_id=70`** for all three nodes in the first cluster.
  - We will be using **`wsrep_gtid_domain_id=80`** for all three ndoes in the second cluster.
- **`server_id`** needs to be configured the with same value for each cluster.
  - We will be using **`server_id=7000`** for all the three nodes of the first cluster.
  - We will be using **`server_id=8000`** for all the three nodes of the second cluster.
- **`gtid_domain_id`** needs to be setup as different values for each node in the cluster
  - We will be using **`gtid_domain_id=71`**, **`gtid_domain_id=72`** & **`gtid_domain_id=73`** for all three nodes of the first cluster.
  - We will be using **`gtid_domain_id=81`**, **`gtid_domain_id=82`** & **`gtid_domain_id=83`** for all three nodes of the second cluster.
- **`auto_increment_increment=6`** for all nodes
- `auto_increment_offset` for each node will be a `+ 1`
  - DC Node 1 = **`auto_increment_offset=1`**
  - DC Node 2 = **`auto_increment_offset=2`**
  - DC Node 3 = **`auto_increment_offset=3`**
  - DR Node 1 = **`auto_increment_offset=4`**
  - DR Node 2 = **`auto_increment_offset=5`**
  - DR Node 3 = **`auto_increment_offset=6`**
- **`innodb_buffer_pool_size`** to be calculated at 60% to 70% of the total memory size on each node. Since our setup here is very small, 1GB RAM for each node, I have calculated InnoDB Buffer Pool as 50% instead.
- **`innodb_flush_log_at_trx_commit=0`** worth mentioning that setting this to `0` imporoves Galera's TPS while still keeping the cluster ACID compliant thanks to it's replication nature.

***Note:** the **`wsrep_provider`** points to a different path/file for the Community version as `wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so`*

The above setup will enable Galera based GTID for each node and because of the `log_slave_upates=ON` we will get a consistent GTID for respective to each galera cluster individually.

Once all the nodes have been configured correctly using the `/etc/my.cnf.d/server/cnf` file, bootstrap the Galera cluster using `galera_new_cluster` from the first node on each data center

```
➜  galera_new_cluster
➜  mariadb -uroot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 10.5.5-3-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select version();
+---------------------------------+
| version()                       |
+---------------------------------+
| 10.5.5-3-MariaDB-enterprise-log |
+---------------------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> show global status like 'wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+
1 row in set (0.002 sec)
```

We can see bootstrap is successful and cluster size is currently 1 for the first data center. Let's start other 2 nodes normally using `systemctl start mariadb` on the primary data center.

```
MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| galera-71  |
+------------+
1 row in set (0.000 sec)

MariaDB [(none)]> show global status like 'wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
1 row in set (0.003 sec)
```

Now we can see all the three nodes are in the cluster on the primary data center. Repeat the same on the **second data center**. 

- Bootstrap Galera using `galera_new_cluster` from node 1 (Galera-81)
- Start the other two nodes using `systemctl start mariadb`
- Verify the cluster size using `show global status like 'wsrep_cluster_size';` to ensure it's 3

The two independent clusters are ready!

## Setup MaxScale 2.5

Install MaxScale RPM on both MaxScale nodes

```txt
➜  yum -y install maxscale

Dependencies Resolved

==============================================================================================================================================================================================
 Package                                Arch                                Version                                        Repository                                                    Size
==============================================================================================================================================================================================
Updating:
 maxscale                               x86_64                              2.5.3-2.rhel.7                                 /maxscale-2.5.3-2.rhel.7.x86_64                              168 M
Installing for dependencies:
 libatomic                              x86_64                              4.8.5-39.el7                                   base                                                          50 k

Transaction Summary
==============================================================================================================================================================================================
..
..                                                                                                                                                            
Complete!
```

Edit the `/etc/maxscale.cnf` file on **both data centers** and define the respective Galera clusters, take note of the IP addresses and Node names need to be defined accordingly, the following is for the **Primary** data center, similarly just duplicate it and edit the respective IP / node names for the **DR** data center.

```txt
[maxscale]
# The number of worker threads that are handling the events coming from the kernel.
threads=auto
# Enable or disable the substitution of environment variables in the MaxScale configuration file
substitute_variables=true
# Send output to Syslog 0 Disabled / 1 Enabled
syslog=0
# Enable or disable the logging of messages whose syslog priority is info
log_info=off
# Enable or disable the logging of messages whose syslog priority is notice
log_notice=on
# Enable or disable the logging of messages whose syslog priority is warning
log_warning=off
# Enable or disable the logging of messages whose syslog priority is debug
log_debug=off

# List of servers in the Cluster
[Galera-71]
type=server
address=192.168.56.71
port=3306
protocol=MariaDBBackend
priority=1

[Galera-72]
type=server
address=192.168.56.72
port=3306
protocol=MariaDBBackend
priority=2

[Galera-73]
type=server
address=192.168.56.73
port=3306
protocol=MariaDBBackend
priority=3

# Monitoring for the Galera server nodes
[Galera-Monitor]
type=monitor
module=galeramon
servers=Galera-71,Galera-72,Galera-73
user=maxuser
password=SecretP@ssw0rd
monitor_interval=2000
use_priority=true
available_when_donor=true

# This will ensure that the current master remains the master as long as it's up and dunning
disable_master_failback=true
backend_connect_timeout=3s
backend_write_timeout=3s
backend_read_timeout=3s

# Failver script for setting up dynamic slaves to a remove MaxScale node
script=/var/lib/maxscale/monitor.sh --initiator=$INITIATOR --parent=$PARENT --children=$CHILDREN --event=$EVENT --node_list=$NODELIST --list=$LIST --master_list=$MASTERLIST --slave_list=$SLAVELIST --synced_list=$SYNCEDLIST

# Galera Read/Write Splitter service
[Galera-RW-Service]
type=service
router=readwritesplit
servers=Galera-71,Galera-72,Galera-73
user=maxuser
password=SecretP@ssw0rd
master_reconnection=true
transaction_replay=true
transaction_replay_retry_on_deadlock=true
master_failure_mode=error_on_write
slave_selection_criteria=ADAPTIVE_ROUTING

# Galera cluster listener
[Galera-Listener]
type=listener
service=Galera-RW-Service
protocol=MariaDBClient
port=4006
address=0.0.0.0

[Replication-Service]
type=service
router=readconnroute
router_options=master
servers=Galera-71,Galera-72,Galera-73
user=maxuser
password=SecretP@ssw0rd

[Replication-Listener]
type=listener
service=Replication-Service
protocol=MariaDBClient
port=4007
address=0.0.0.0
```

**Refer to:** [script=/var/lib/maxscale/monitor.sh](monitor.sh) for the source.

***Note:** Best to encrypt the Passwords in the `maxscale.cnf` file, but we are keeping it simple here.*

This setup gives us the basic read/write split, standard monitoring and a connection router used for replication across DC.

### Configure MaxScale & Replication Users

We need to create the **`maxuser`** & **`repl_user`** accounts with a password of `SecretP@ssw0rd` (As defined in the `maxscale.cnf`), we will also create a **`mariabackup`** to use for SST, this needs to be done on both **Primary DC** and **DR DC**.

```
MariaDB [(none)]> CREATE USER maxuser@'%' IDENTIFIED BY 'SecretP@ssw0rd';
Query OK, 0 rows affected (0.058 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.* TO maxuser@'%';
Query OK, 0 rows affected (0.054 sec)

MariaDB [(none)]> GRANT SHOW DATABASES ON *.* TO maxuser@'%';
Query OK, 0 rows affected (0.054 sec)

MariaDB [(none)]> CREATE USER repl_user@'%' IDENTIFIED BY 'SecretP@ssw0rd';
Query OK, 0 rows affected (0.051 sec)

MariaDB [(none)]> GRANT REPLICATION SLAVE, REPLICATION SLAVE ADMIN ON *.* TO repl_user@'%';
Query OK, 0 rows affected (0.051 sec)

MariaDB [(none)]> CREATE USER mariabackup@localhost IDENTIFIED VIA unix_socket;
Query OK, 0 rows affected (0.004 sec)

MariaDB [(none)]> GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO mariabackup@localhost;
Query OK, 0 rows affected (0.004 sec)
```

Now we can start MaxScale node on the **Primary DC** and verify the cluster status.

```
➜  systemctl start maxscale
➜  maxctrl list servers 
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬───────────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼───────────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Master, Synced, Running │ 70-7000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼───────────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 0           │ Slave, Synced, Running  │ 70-7000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼───────────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 0           │ Slave, Synced, Running  │ 70-7000-5 │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴───────────┘
```

We can see the clust is healthy with GTID / Domain & Server IDs showing up as per our configuration. At this point the GTID should be `70-7000-5` since we have only performed 5 transactions on this cluster, the DR DC should also be at the same state `80-8000-5`

Let's verify if the service has already started or not

```
➜  maxctrl list services 
┌─────────────────────┬────────────────┬─────────────┬───────────────────┬─────────────────────────────────┐
│ Service             │ Router         │ Connections │ Total Connections │ Servers                         │
├─────────────────────┼────────────────┼─────────────┼───────────────────┼─────────────────────────────────┤
│ Replication-Service │ readconnroute  │ 1           │ 3                 │ Galera-71, Galera-72, Galera-73 │
├─────────────────────┼────────────────┼─────────────┼───────────────────┼─────────────────────────────────┤
│ Galera-RW-Service   │ readwritesplit │ 0           │ 0                 │ Galera-71, Galera-72, Galera-73 │
└─────────────────────┴────────────────┴─────────────┴───────────────────┴─────────────────────────────────┘
```

#### Create mariabackup OS user on all Galera nodes

We can now add `mariabackup` OS user on all the MariaDB Galera nodes and set it's group as `mysql` followed by a secure password. This username must be identical to the backup user created previously.

```
➜  groupadd mariabackup

➜  useradd -g mysql mariabackup

➜  id mariabackup
uid=1001(mariabackup) gid=994(mysql) groups=994(mysql)

➜  passwd mariabackup
Changing password for user mariabackup.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.
```

This will create the `mariabackup` user under the `mysql` user group.

Edit the `/etc/my.cnf.d/server.cnf` file on all the nodes and add the following to the **`[galera]`** section

```
wsrep_sst_method=mariabackup
wsrep_sst_auth=mariabackup:
```

This will tell MariaDB Galera to use MariaDB Backup for SST, this will improve the cluster availability and stability. Once defined, restart all the nodes `systemctl restart mariadb` on **both data centers** one by one.

### Setting up GTID_SLAVE_POS

Take note of the GTID from the **DR Cluster** as that GTID will be required to set up on all the **Primary DC** nodes.

```
MariaDB [(none)]> SET GLOBAL GTID_SLAVE_POS='80-8000-5';
Query OK, 0 rows affected (0.048 sec)
```

At this time, the **Primary MaxScale** will show the following status since we have already set gtid_slave_pos on all the nodes:

```
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬─────────────────────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID                │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Master, Synced, Running │ 70-7000-5,80-8000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-72 │ 192.168.56.71 │ 3306 │ 0           │ Slave, Synced, Running  │ 70-7000-5,80-8000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-73 │ 192.168.56.71 │ 3306 │ 0           │ Slave, Synced, Running  │ 70-7000-5,80-8000-5 │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴─────────────────────┘
```

Similarly, set up the the GTID_SLAVE_POS on all the nodes on the **DR Cluster** based on the GTID from Primary Cluster

```
MariaDB [(none)]> SET GLOBAL GTID_SLAVE_POS='70-7000-5';
Query OK, 0 rows affected (0.048 sec)
```

At this time, the **DR MaxScale** will show the following status since we have already set gtid_slave_pos on all the nodes:

```
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬─────────────────────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID                │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-81 │ 192.168.56.81 │ 3306 │ 0           │ Master, Synced, Running │ 70-7000-5,80-8000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-82 │ 192.168.56.82 │ 3306 │ 0           │ Slave, Synced, Running  │ 70-7000-5,80-8000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-83 │ 192.168.56.83 │ 3306 │ 0           │ Slave, Synced, Running  │ 70-7000-5,80-8000-5 │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴─────────────────────┘
```

### Setting up Replication

Since we have the monitor script already in place which is triggered as soon as there is an even trigger on MaxScale, we just need to Stop the "Master" nodes on both **data centers** and that Monitoring script will automatically set up replication between the two clusters.

Use `systemctl stop mariadb` on both Master Nodes on DC Clusters

```
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬─────────────────────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID                │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Down                    │                     │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 1           │ Master, Synced, Running │ 70-7000-6,80-8000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 1           │ Slave, Synced, Running  │ 70-7000-7,80-8000-5 │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴─────────────────────┘
```

The New selected Master on the Primary DC cluster will show the following

```
MariaDB [(none)]> show all slaves status\G
*************************** 1. row ***************************
               Connection_name: DR-RemoteMaxScale
               Slave_SQL_State: 
                Slave_IO_State: 
                   Master_Host: 172.168.56.80
                   Master_User: repl_user
                   Master_Port: 4007
                 Connect_Retry: 10
               Master_Log_File: MariaDB-bin.000017
           Read_Master_Log_Pos: 771
                Relay_Log_File: MariaDB-relay-bin-dc@002dremotemaxscale.000010
                 Relay_Log_Pos: 717
         Relay_Master_Log_File: MariaDB-bin.000017
              Slave_IO_Running: No
             Slave_SQL_Running: No
               Replicate_Do_DB: 
           Replicate_Ignore_DB: 
            Replicate_Do_Table: 
        Replicate_Ignore_Table: 
       Replicate_Wild_Do_Table: 
   Replicate_Wild_Ignore_Table: 
                    Last_Errno: 0
                    Last_Error: 
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 771
               Relay_Log_Space: 1116
               Until_Condition: None
                Until_Log_File: 
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File: 
            Master_SSL_CA_Path: 
               Master_SSL_Cert: 
             Master_SSL_Cipher: 
                Master_SSL_Key: 
         Seconds_Behind_Master: NULL
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error: 
                Last_SQL_Errno: 0
                Last_SQL_Error: 
   Replicate_Ignore_Server_Ids: 
              Master_Server_Id: 7000
                Master_SSL_Crl: 
            Master_SSL_Crlpath: 
                    Using_Gtid: Slave_Pos
                   Gtid_IO_Pos: 70-7000-5,80-8000-5
       Replicate_Do_Domain_Ids: 
   Replicate_Ignore_Domain_Ids: 
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: 
              Slave_DDL_Groups: 1
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
          Retried_transactions: 0
            Max_relay_log_size: 1073741824
          Executed_log_entries: 57
     Slave_received_heartbeats: 0
        Slave_heartbeat_period: 30.000
                Gtid_Slave_Pos: 70-7000-5,80-8000-5
1 row in set (0.000 sec)
```

Similarly, once the Master Galera node is down, the monitor script will automatically set the 2nd Galera node as a Slave to the **Primary DC** MaxScale slave.

```
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬─────────────────────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID                │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-81 │ 192.168.56.81 │ 3306 │ 0           │ Down                    │                     │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-82 │ 192.168.56.82 │ 3306 │ 1           │ Master, Synced, Running │ 70-7000-6,80-8000-5 │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼─────────────────────┤
│ Galera-83 │ 192.168.56.83 │ 3306 │ 1           │ Slave, Synced, Running  │ 70-7000-7,80-8000-5 │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴─────────────────────┘
```

The New selected Master on the Primary DC cluster will show the following, The Galera-82 is now the Master node in this cluster and also a SLAVE to **Primary DC** MaxScale R/W Service.

```
MariaDB [(none)]> show all slaves status\G
*************************** 1. row ***************************
               Connection_name: DC-RemoteMaxScale
               Slave_SQL_State: 
                Slave_IO_State: 
                   Master_Host: 172.168.56.70
                   Master_User: repl_user
                   Master_Port: 4007
                 Connect_Retry: 10
               Master_Log_File: MariaDB-bin.000017
           Read_Master_Log_Pos: 771
                Relay_Log_File: MariaDB-relay-bin-dc@002dremotemaxscale.000010
                 Relay_Log_Pos: 717
         Relay_Master_Log_File: MariaDB-bin.000017
              Slave_IO_Running: No
             Slave_SQL_Running: No
               Replicate_Do_DB: 
           Replicate_Ignore_DB: 
            Replicate_Do_Table: 
        Replicate_Ignore_Table: 
       Replicate_Wild_Do_Table: 
   Replicate_Wild_Ignore_Table: 
                    Last_Errno: 0
                    Last_Error: 
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 771
               Relay_Log_Space: 1116
               Until_Condition: None
                Until_Log_File: 
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File: 
            Master_SSL_CA_Path: 
               Master_SSL_Cert: 
             Master_SSL_Cipher: 
                Master_SSL_Key: 
         Seconds_Behind_Master: NULL
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error: 
                Last_SQL_Errno: 0
                Last_SQL_Error: 
   Replicate_Ignore_Server_Ids: 
              Master_Server_Id: 7000
                Master_SSL_Crl: 
            Master_SSL_Crlpath: 
                    Using_Gtid: Slave_Pos
                   Gtid_IO_Pos: 80-8000-5,70-7000-5
       Replicate_Do_Domain_Ids: 
   Replicate_Ignore_Domain_Ids: 
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: 
              Slave_DDL_Groups: 1
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
          Retried_transactions: 0
            Max_relay_log_size: 1073741824
          Executed_log_entries: 57
     Slave_received_heartbeats: 0
        Slave_heartbeat_period: 30.000
                Gtid_Slave_Pos: 80-8000-5,70-7000-5
1 row in set (0.000 sec)
```

We can now start the stopped Galera nodes using `systemctl start mariadb`

From this point onwards the replication is confirmed between both data centers and also provide HA no matter which node is available / down the monitor script will automatically handle the cluster to cluster replicaiton.

The positive of this setup is that both sides provide an Active environment and can be used for reads and writes. 

## Thank You!
