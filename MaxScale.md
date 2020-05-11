# MaxScale 2.4 Setup

All the MariaDB Servers should have the following confugration in the `server.cnf` file 

```cnf
[mariadb]
server_id=1000
log_bin = mariadb-bin
log_bin_index = mariadb-bin.index
binlog_format = ROW
gtid_strict_mode = 1
bind_address = 0.0.0.0
log_slave_updates=1
log_error
port=5099

rpl_semi_sync_master_enabled=ON
rpl_semi_sync_slave_enabled=ON

# MariaDB Replication Durability
sync_binlog = 1
sync_master_info = 1
sync_relay_log = 1
sync_relay_log_info = 1

## MyRocks Related Config
#rocksdb_block_cache_size = 8GB
#rocksdb_default_cf_options = "compaction_pri=kMinOverlappingRatio; level_compaction_dynamic_level_bytes=true;"
#rocksdb_max_background_jobs = 1
#rocksdb_flush_log_at_trx_commit = 0
#rocksdb_max_open_files = -1

[mysql]
prompt=\H [\d]>\
```

Everything remains the same in all the MariaDB servers except for the `server_id` parameter, configure it as **1000** for primnary, **2000** for secondary, **3000** for third database and **4000** for the backup server.

Also take note of the `port=5099` this defines a non-standard port number for all the databases. The same port is used while configuring MaxScale.

Once this is done, proceed to configure the replication as per normal.

## MaxScale 2.4 User Account Setup

MaxScale needs to have two accounts created in the database. Execute the following statements on the PrimaryDB (Master) so that these get replicated on all the slaves.

```sql
# USER (maxuser): ReadWrite-Splitter user, this user is going to be a
# part of the basic configuration
# Following Grants are required for MariaDB 10.3.x 

MariaDB [(none)]> CREATE USER 'maxuser'@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.user TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.db TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.tables_priv TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.roles_mapping TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SHOW DATABASES ON *.* TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

# USER (maxmon): MariaDBMon user
# user created for the monitor MariaDBMon, to pull state,
# do the failover, switchover and rejoin servers part of existing clusters

MariaDB [(none)]> CREATE USER maxmon@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SUPER, RELOAD, REPLICATION CLIENT ON *.* TO maxmon@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

Once the accounts are created on the Primary database node, verify that these are replciated on the secondary nodes as well. Proceed to configure the MaxScale server.

## MaXsCALE 2.4 Setup

Edit the /`etc/maxscale.cnf` file and delete all the contents to do a clean start. Add the following to the `/etc/maxscale.cnf` file

```txt
[maxscale]
threads=auto
log_info=true

## Servers
[PrimaryDB]
type=server
address=<ip address>
port=5099
protocol=MariaDBBackend

[SecondaryDB-1]
type=server
address=<ip address>
port=5099
protocol=MariaDBBackend

[SecondaryDB-2]
type=server
address=<ip address>
port=5099
protocol=MariaDBBackend

[BackupDB-1]
type=server
address=<ip address>
port=5099
protocol=MariaDBBackend

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=PrimaryDB, SecondaryDB-1, SecondaryDB-2, BackupDB-1
user=maxmon
password=secretpassword

monitor_interval=2500
failcount=15
failover_timeout=120s
switchover_timeout=120s
verify_master_failure=true
master_failure_timeout=30s

enforce_read_only_slaves=true
auto_failover=true
auto_rejoin=true

## This will set the BackupDB as not a failover candidate, also note that BackupDB-1 is not configured int he Read-Write-Service
servers_no_promotion = BackupDB-1

## This is the replication-rwsplit-service
[Read-Write-Service]
type=service
router=readwritesplit
servers=PrimaryDB, SecondaryDB-1, SecondaryDB-2
user=maxuser
password=secretpassword
master_reconnection=true
master_failure_mode=error_on_write
transaction_replay=true
slave_selection_criteria=ADAPTIVE_ROUTING

## The following needs to be tested but it's a nice feature to automatically retry a transaction failed due to deadlock, uncomment to enable.
# transaction_replay_retry_on_deadlock=true

## To send all the stored procedure calls to Master!
strict_sp_calls=true

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=9066
```

The `Read-Write-Listener` points to `9066` as the port number, this is the port that the application should connect to.

Once the configuration is ready, restart trhe MaxScale `systemctl restart maxscale` and execute the command to verify the server's are visible by executing the command: `maxctrl list servers` and `maxctrl list services` to see the running services.

- Execute the command `maxctrl show maxscale | grep -i passive` to see if the server is running in Active/Passive mode.

- Execute the command `maxctrl alter maxscale passive false` to chage the MaxScale to Active mode.

- Execute the command `maxctrl alter maxscale passive true` to chage the MaxScale to Passive mode.

Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-maxscale-failover-with-keepalived-and-maxctrl/> for details on `KeepAliveD` configuration to auto active/passive setup of MaxScale.
