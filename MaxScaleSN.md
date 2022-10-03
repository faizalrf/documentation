# MaxScale 6.x Setup

This document is meant to be a guide on how to best setup MaxScale 6 so that it can be used with a ServiceNow deployment and MariaDB 10.4+ versions. 

All the MariaDB Servers should have the following confugration in the `server.cnf` or the `my.cnf` files, other than the default application specific configuration.  

```cnf
[mariadb]
log_error=server.log
gtid_domain_id=<DomainID>
server_id=<ServerID>
gtid_strict_mode=1
log_bin = mariadb-bin
log_bin_index = mariadb-bin.index
relay_log_recovery = 1
shutdown_wait_for_slaves = 1
binlog_format = ROW
log_slave_updates = 1
bind_address = 0.0.0.0
```

Here the `gtid_domain_id` is an integer value, generally `1` which should remain the same across all the nodex. 

Everything else including the `gtid_domain_id` remains the same in all the MariaDB servers except for the `server_id` parameter, which is generally configured as **1000** for primnary, **2000** for secondary, **3000**, **4000**, and so on.

Once this is done, proceed to configure the replication as per normal using GTID Based replication (`MASTER_USE_GTID=slave_pos`).

## MaxScale 6 User Account Setup
  
MaxScale needs to have two accounts created in the database. Execute the following statements on the PrimaryDB (Master) so that these get replicated on all the slaves.

```sql
# USER (maxuser): ReadWrite-Splitter user, this user is going to be a
# part of the basic configuration
# Following Grants are required for MariaDB 

MariaDB [(none)]> CREATE USER maxuser@'%' IDENTIFIED BY '<SecretPassword>';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.* TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SHOW DATABASES ON *.* TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

# USER (maxmon): MariaDBMon user
# user created for the monitor MariaDBMon, to pull state,
# do the failover, switchover and rejoin servers part of existing clusters

MariaDB [(none)]> CREATE USER maxmon@'%' IDENTIFIED BY '<SecretPassword>';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SUPER, RELOAD, PROCESS, SHOW DATABASES, EVENT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'maxmon'@'%';
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.* TO 'maxmon'@'%';
Query OK, 0 rows affected (0.000 sec)
```

Once the accounts are created on the Primary database node, verify that these are replciated on the secondary nodes as well. Proceed to configure the MaxScale server.

## MaxScale 6 Setup

Download MaxScale from either the community MariaDB downloads page or the Enterprise link, both are same.

- <https://mariadb.com/downloads/enterprise/enterprise-maxscale/>
- <https://mariadb.com/downloads/community/maxscale/>

Once the RPM/DEB package has been downloaded, install it as per the OS process.

Edit the `/etc/maxscale.cnf` file and delete all the contents to do a clean start. Add the following to the `/etc/maxscale.cnf` file.

The following config is assuming there are three nodes in the setup.
- Primary
  - Replica 1
  - Replica 2

```
[maxscale]
threads=auto
log_info=false

## Servers
[Server-1]
type=server
address=172.31.21.171
port=3306
protocol=MariaDBBackend

[Server-2]
type=server
address=172.31.30.226
port=3306
protocol=MariaDBBackend

[Server-3]
type=server
address=172.31.29.182
port=3306
protocol=MariaDBBackend

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=Server-1, Server-2, Server-3
user=maxmon
password=<SecretPassword>

monitor_interval=2000
verify_master_failure=true
enforce_read_only_slaves=true

auto_failover=true
auto_rejoin=true

cooperative_monitoring_locks=majority_of_all

## This is the replication-rwsplit-service
[Read-Write-Service]
type=service
router=readwritesplit
servers=Server-1, Server-2, Server-3
master_accept_reads=true

user=maxuser
password=<SecretPassword>

master_reconnection=true
transaction_replay=true
transaction_replay_max_size = 10Mi
transaction_replay_attempts = 10
delayed_retry=ON
delayed_retry_timeout=240s
prune_sescmd_history=true
slave_selection_criteria=ADAPTIVE_ROUTING

## For Read Consistency, test this with the value "local" and "global" to always use Slaves for reading
# GLOBAL is recommended for ServiceNow as it can detect changes in multiple connections and decide to read from master or from slave.
# causal_reads=global
## 

# The following is a fast alternative instead of causal_reads, we force MaxScale to only connect to the primary node for all routing
max_slave_connections=0

## The following needs to be tested but it's a nice feature to automatically retry a transaction failed due to deadlock, uncomment to enable.
transaction_replay_retry_on_deadlock=true

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port = 4007
address = 0.0.0.0
```

The `Read-Write-Listener` points to `4007` as the port number, user defined, the applications/clients must connect to this port to get access to the databases.

- **`causal_reads=fast`** 
  - If the current connection does any data changes, insert, update, delete, MaxScale will check if no slaves have the data replicated, the subsequent SELECT query will be straight away routed to the Master node.
  - This is the fastest way but in case of the always lagging slaves, master will be constantly pounded by all the reads.
- **`causal_reads=local`**
  - If the current connection does any data changes, insert, update, delete, MaxScale will wait up to `causal_reads_timeout=10s` seconds to see if the slaves get that data before running the SELECT query on the slave, 
  - This can slowdown the application if the slaves are always lagging behind. Applicable to writes done on the user's own connection.
  - But if the replicaiton is fast enough, this can provided great READ scaling.
- **`causal_reads=global`**
  - This behaves exactly the same way as `local` with one major change. Instead of considering on the current user connection, MaxScale will identify changes from all the other users who might do some data change and then decide weather to send the SELECT query to a particular slave or to the master node
  - Can be good if read scaling is needed and data consistency across the server is important.
  - But of course, it slows down all the users SELECT tasks even if they are not doing any data changes
    - `causal_reads_timeout=10s` is still applicable and can be configured within MaxScale as to how long to wait for the replication of that particular transaction to catch up.
- **`max_slave_connections=0`**
  - Instead of `causal_reads` this is the fast alternative as there is no waits or delays and all the reads and writes simply go to the primary node without across the connections.
  
Once the configuration is ready, restart trhe MaxScale `systemctl restart maxscale` and execute the command to verify the server's are visible by executing the command: `maxctrl list servers` and `maxctrl list services` to see the running services.

**Note:** With MaxScale 2.5+, there is no need to use thirdparty products like KeepAliveD or Corosync/Pacemaker etc, MaxScale alreay has built in "Cooperative Monotiring" capabilities. <https://mariadb.com/kb/en/mariadb-maxscale-6-mariadb-monitor/#cooperative_monitoring_locks>

Refer to my YouTube video for an explanation on how Cooperative monitoring works: https://youtu.be/6wc_5O8jHjc

## Than you!
