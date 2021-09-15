# MaxScale 2.5 Setup

All the MariaDB Servers should have the following confugration in the `server.cnf` file 

```cnf
[mariadb]
innodb_flush_log_at_trx_commit=2
server_id=1000
log_bin = mariadb-bin
log_bin_index = mariadb-bin.index
binlog_format = MIXED
gtid_strict_mode = 1
log_slave_updates = 1
bind_address = 0.0.0.0
log_error

# MariaDB Replication Durability but may slow down the replication on very heavy write environments
sync_binlog = 1
sync_master_info = 1
sync_relay_log = 1
sync_relay_log_info = 1

[mysql]
prompt=\H [\d]>\
```

Everything remains the same in all the MariaDB servers except for the `server_id` parameter, configure it as **1000** for primnary, **2000** for secondary, **3000** for third database and **4000** for the backup server.

Once this is done, proceed to configure the replication as per normal.

## MaxScale 2.5 User Account Setup

MaxScale needs to have two accounts created in the database. Execute the following statements on the PrimaryDB (Master) so that these get replicated on all the slaves.

```sql
# USER (maxuser): ReadWrite-Splitter user, this user is going to be a
# part of the basic configuration
# Following Grants are required for MariaDB 10.3.x 

MariaDB [(none)]> CREATE USER 'maxuser'@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.* TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SHOW DATABASES ON *.* TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

# USER (maxmon): MariaDBMon user
# user created for the monitor MariaDBMon, to pull state,
# do the failover, switchover and rejoin servers part of existing clusters

MariaDB [(none)]> CREATE USER maxmon@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SUPER, RELOAD, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO maxmon@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

Once the accounts are created on the Primary database node, verify that these are replciated on the secondary nodes as well. Proceed to configure the MaxScale server.

## MaxScale 2.5 Setup

Edit the `/etc/maxscale.cnf` file and delete all the contents to do a clean start. Add the following to the `/etc/maxscale.cnf` file

```txt
[maxscale]
threads=auto
log_info=false

## Servers
[Server-1]
type=server
address=<ip address>
port=3306
protocol=MariaDBBackend

[Server-2]
type=server
address=<ip address>
port=3306
protocol=MariaDBBackend

[Server-3]
type=server
address=<ip address>
port=3306
protocol=MariaDBBackend

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=Server-1, Server-2, Server-3
user=maxmon
password=secretpassword

monitor_interval=1500
failcount=5
failover_timeout=120s
switchover_timeout=120s
verify_master_failure=true
master_failure_timeout=30s
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
password=secretpassword

master_reconnection=true
master_failure_mode=error_on_write
transaction_replay=true
slave_selection_criteria=ADAPTIVE_ROUTING

# For Read Consistency, test this with the value "local" and "global" to always use Slaves for reading 
causal_reads=fast

## The following needs to be tested but it's a nice feature to automatically retry a transaction failed due to deadlock, uncomment to enable.
# transaction_replay_retry_on_deadlock=true

## To send all the stored procedure calls to Primary DB Server!
# strict_sp_calls=true

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=4009
address=0.0.0.0
```

The `Read-Write-Listener` points to `4009` as the port number, this is the port that the application should connect to.

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

Once the configuration is ready, restart trhe MaxScale `systemctl restart maxscale` and execute the command to verify the server's are visible by executing the command: `maxctrl list servers` and `maxctrl list services` to see the running services.

**Note:** With MaxScale 2.5, there is no need to use thirdparty products like KeepAliveD or Corosync/Pacemaker etc, MaxScale alreay has built in "Cooperative Monotiring" capabilities. <https://mariadb.com/kb/en/mariadb-maxscale-25-mariadb-monitor/#cooperative-monitoring>

Refer to my YouTube video for an explanation on how Cooperative monitoring works: https://youtu.be/6wc_5O8jHjc

## Than you!
