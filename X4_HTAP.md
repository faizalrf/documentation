# X4 HTAP Setup

## Assumptions

- X4 with ColumnStore is already up and running on a single-node or multi-node setup
- Standard replication (schema sync) between the nodes is configured & working
- Additional 3rd node is available with MaxScale 2.4 installed (Blank configuration)

## Setup

To configure HTAP (Hybnrid Transactional & Analytical Processing) setup, we will need use MaxScale 2.4 or higher. and condfigure it with standard Read/Write splitting service for the two node X4 setup.

Asuming we have the following three nodes

- MaxScale 2.4 (192.168.56.201)
  - MariaDB X4 (192.168.56.101) - Primary
  - MariaDB X4 (192.168.56.102) - Replica

### MaxScale 2.4 User Account Setup

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

### MaXsCALE 2.4 Setup

Edit the /`etc/maxscale.cnf` file and delete all the contents to do a clean start. Add the following to the empty config file.

```txt
[maxscale]
threads=auto
log_info=1

## Servers
[PM1-Node]
type=server
address=192.168.56.101
port=3306
protocol=MariaDBBackend

[PM2-Node]
type=server
address=192.168.56.102
port=3306
protocol=MariaDBBackend

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=PM1-Node, PM2-Node
user=maxmon
password=secretpassword
monitor_interval=1500ms
verify_master_failure=true
enforce_read_only_slaves=true
auto_failover=true
auto_rejoin=true

## If a node is to be kept out of the auto promotion to Primary, that node can be defined as:
# servers_no_promotion = Backup-Node

## This is the replication-rwsplit-service
[Read-Write-Service]
type=service
router=readwritesplit
servers=PM1-Node, PM2-Node
user=maxuser
password=secretpassword
master_reconnection=true
master_failure_mode=error_on_write
transaction_replay=true
slave_selection_criteria=ADAPTIVE_ROUTING

## The following needs to be tested but it's a nice feature to automatically retry a transaction failed due to deadlock, uncomment to enable.
transaction_replay_retry_on_deadlock=true

## To send all the stored procedure calls to Master!
strict_sp_calls=true

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=5001
```

The above configuration:

- Defines 2 nodes **`PM1-Node`** & **`PM2-Node`**
- Defines a MariaDB Monitor to mnitor the two node's health and perform auto-failover of the backend nodes if needed
- Defines a Read/Write split service that handle transactions running on failed nodes and also connection failover etc.
- Defines a Read/Write listener which end users or apps will connect to using the defined **`5001`** port. 
  - All the users connected to MaxScale IP and this port, will be using `Read-Write-Service` automatically

These services uses two MariaDB accounts, `maxmon` and `maxuser` which we have already crearted in the previous section.

Once the configuration is ready, restart trhe MaxScale `systemctl restart maxscale` and execute the command to verify the server's are visible by executing the command: `maxctrl list servers` and `maxctrl list services` to see the running services.

Let's verify the servers and services currently known to MaxScale.

```txt
shell> maxctrl list servers;
┌──────────┬────────────────┬──────┬─────────────┬─────────────────┬────────┐
│ Server   │ Address        │ Port │ Connections │ State           │ GTID   │
├──────────┼────────────────┼──────┼─────────────┼─────────────────┼────────┤
│ PM1-Node │ 192.168.56.101 │ 3306 │ 0           │ Master, Running │ 0-1-15 │
├──────────┼────────────────┼──────┼─────────────┼─────────────────┼────────┤
│ PM2-Node │ 192.168.56.102 │ 3306 │ 0           │ Slave, Running  │ 0-1-15 │
└──────────┴────────────────┴──────┴─────────────┴─────────────────┴────────┘

shell> maxctrl list services;
┌────────────────────┬────────────────┬─────────────┬───────────────────┬────────────────────┐
│ Service            │ Router         │ Connections │ Total Connections │ Servers            │
├────────────────────┼────────────────┼─────────────┼───────────────────┼────────────────────┤
│ Read-Write-Service │ readwritesplit │ 0           │ 0                 │ PM1-Node, PM2-Node │
└────────────────────┴────────────────┴─────────────┴───────────────────┴────────────────────┘
```

