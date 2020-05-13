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

### Setup X4 for InnoDB to ColumnStore replication

Edit the `/etc/my.cnf.d/server.cnf` file and adjust the `innodb_buffer_pool_size` to be 40% of the total memory.

Edit the `/etc/my.cnf.d/columnstore.cnf` file on the **PM1** node and add the following to it.

```shell
replicate_same_server_id      = 1
log_slave_updates             = OFF
binlog_format                 = STATEMENT
columnstore_replication_slave = ON
```

- **`replicate_same_server_id`**
  - Enable this option to include binlog events that have the same server_id in replication, allowing the Server to replicate to itself through MariaDB MaxScale.
- **`log_slave_updates`**
  - Logs updates from the replica thread to the Binary Log. Must be turned OFF in an HTAP deployment.
- **`binlog_format`**
  - Set the binary log format to perform statement-based replication. This is one of the requirements as of now with X4, ROW based replication will not work.
- **`columnstore_replication_slave`**
  - Enables replication of MariaDB Enterprise Server binlog events to MariaDB ColumnStore.
  
We are going to be using MaxScale as the Binlog Filter which will pull all the binary log events from InnoDB and push them back to the PM1 node as ColumnStore events, while the normal "Primary - PM1" to "Replica - PM2" will prodceed as per norrmal.

Take note, in a default configuration, PM1 will be `server_id=1` and PM2 will be `server_id=2`, this can be verified by looking at the `/etc/my.cnf.d/columnstore.cnf` file on both nodes.

Restart the X4 using `mcsadmin shutdownsystem y && mcsadmin startsystem` from PM1 node.

Now we can get the MaxScale related user account and configuration done.

### User Account Setup for MaxScale 2.4

MaxScale needs to have two accounts created in the database. Execute the following statements on the PrimaryDB (Master) so that these get replicated on all the slaves.

```sql
# USER (maxuser): ReadWrite-Splitter user, this user is going to be a
# part of the basic configuration
# Following Grants are required for MariaDB 10.3.x 

MariaDB [(none)]> CREATE USER 'maxuser'@'%' IDENTIFIED BY 'SecretPassword!123';
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

MariaDB [(none)]> CREATE USER maxmon@'%' IDENTIFIED BY 'SecretPassword!123';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SUPER, RELOAD, REPLICATION CLIENT ON *.* TO maxmon@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

Once the accounts are created on the Primary database node, verify that these are replciated on the secondary nodes as well. Proceed to configure the MaxScale server.

### MaxScale 2.4 Setup

Open the `/etc/maxscale.cnf` file and delete all the contents to do a clean start. Add the following to the empty config file.

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
module=csmon
servers=PM1-Node, PM2-Node
user=maxmon
password=P@ssw0rd
primary=PM1-Node
monitor_interval=2000ms

## This is the replication-rwsplit-service
[Read-Write-Service]
type=service
router=readwritesplit
servers=PM1-Node, PM2-Node
user=maxuser
password=SecretPassword!123
master_reconnection=true
master_failure_mode=error_on_write
transaction_replay=true
slave_selection_criteria=ADAPTIVE_ROUTING

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=5001
```

The above configuration:

- Defines 2 nodes **`PM1-Node`** & **`PM2-Node`**
- Defines a ColumnStore monitor `csmon` to mnitor the two nodes.
- Defines a Read/Write split service that handle transactions running on failed nodes and also connection failover etc.
- Defines a Read/Write listener which end users or apps will connect to using the defined **`5001`** port. 
  - All the users connected to MaxScale IP and this port, will be using `Read-Write-Service` automatically

These services uses two MariaDB accounts, `maxmon` and `maxuser` which we have already crearted in the previous section.

Once the configuration is ready, restart trhe MaxScale `systemctl restart maxscale` and execute the command to verify the server's are visible by executing the command: `maxctrl list servers` and `maxctrl list services` to see the running services.

Let's verify the servers and services that are currently known to MaxScale.

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

MaxScale is now configured and ready with the `Read-Write-Service` for the Two X4 nodes. 

### MaxScale Replicaiton Filter and Firewall Filter

Assuming we have two tables that we want to replicate from InnoDB to ColumnStore, we will configure those two tables in the `binlogfilter` using regex expression.

Along with the `binlogfilter` we also need to configure a `dbfwfilter`, this filter will block all the DDL statements from replicating and also the "DELETE" statements.

Add the following blocks in `/etc/maxscale.cnf` file

```txt
[replication-filter]
type         = filter
module       = binlogfilter
#match        = ((?i)(\binsert\b.*orders\b)|(\bupdate\b.*orders\b)|(\binsert\b.*payments\b)|(\bupdate\b.*payments\b)(?-i))
match        = /[.]orders|[.]payments/
rewrite_src  = innodb
rewrite_dest = columnstore
```

- `type`
  - Set the module type for each service, in this case this service is a filter, for filtering binary logs to replicate.
- `module`
  - Use the binlogfilter module. This will read all the binary log events as mentioned above.
- `match`
  - Regular Expression indicating the tables you want to replicate. In the example, the `orders` and `payments` are the two tables we want replicated from InnoDB to ColumnStore.
    - This expression says that, if only replicate if we have `insert` or `update` for the two tables in the statement.
- `rewrite_src`
  - Regular Expression indicating the database you want to replicate data from.
- `rewrite_dest`
  - Replacement string for the database the filter replicates into.

In the example configuration, the Binary Log Filter would replicate writes to the `3g_innodb.orders` and `3g_innodb.payments` tables into the `3g_columnstore.orders` and `3g_columnstore.payments` respectively.

### MaxScale Router Configuration

Services control how MariaDB MaxScale routes traffic from listeners to MariaDB Enterprise Servers. In an HTAP deployment, the MaxScale Instance requires two routers: one for database connections `Read-Write-Service`, as configured earlier, and one for replication.

The replication routing service receives client connections from the listener on a non-standard port, passes the operation through the Binary Log Filter, and then routes them back to the Server.

Add the following to the MaxScale config `/etc/maxscale.cnf`

```
[replication-router]
type     = service
router   = readconnroute
servers  = PM1-Node
user     = maxmon
password = SecretPassword!123
filters  = replication-filter
```

- `type`
  - Set the module type for each service
- `router`
  - Use the `readconnroute`. This will read all the binary log events to a specific node, PM1 in our case.
- `servers`
  - The server we are going to route all the filtered binary log events to, `PM1-Node` for instance.
- `user` & `password`
  - The user and password that can perform replication, this is the same user as user in the MariaDB-Monitor
- `filters`
  - This points back to the filterswe configured earlier, `replication-filter` for the two tables.

### MaxScale Filter Lister

The replication listener receives client connection from the MariaDB Enterprise Server and passes them to the replication router configured above. The router then uses the Binary Log Filter to rename the database before sending the connection back to the Server.

Add the following to the MaxScale config `/etc/maxscale.cnf`

```
[replication-listener]
type     = listener
service  = replication-router
protocol = MariaDBClient
port     = 4409
```

The port **`4409`** will be used as the listener port, we will use this port when 
executing `CHANGE MASTER` command.

Aftrer the three configurations (`replication-filter`, `replication-router`, `replication-listener`) have been added to the `/etc/maxscale.cnf` we can now restart maxscale service using `systemctl restart maxscale` and verify the replication router is up and running along with the read write service.

```
shell> maxctrl list services;
┌────────────────────┬────────────────┬─────────────┬───────────────────┬────────────────────┐
│ Service            │ Router         │ Connections │ Total Connections │ Servers            │
├────────────────────┼────────────────┼─────────────┼───────────────────┼────────────────────┤
│ Read-Write-Service │ readwritesplit │ 0           │ 0                 │ PM1-Node, PM2-Node │
├────────────────────┼────────────────┼─────────────┼───────────────────┼────────────────────┤
│ replication-router │ readconnroute  │ 0           │ 0                 │ PM1-Node           │
└────────────────────┴────────────────┴─────────────┴───────────────────┴────────────────────┘
```

Now we are ready to setup Replication between PM1 -> MaxScale -> PM1 nodes.

### Replication Configuration

In the HTAP deployment, the MariaDB Enterprise Server treats MariaDB MaxScale as a Primary Server. The Replica Server process connects to the MaxScale Instance where it's routed back to the Server to retrieve binary log events. Those writes are then filtered, changing the database name before they replicate back to the same Server on a different database.

To configure the Server `PM1-Node` to replicate from MariaDB MaxScale, use a CHANGE MASTER statement, execute this from the Primary node **`PM1`**, this will make PM1 a slve to MaxScale node.

```sql
CHANGE MASTER TO
   MASTER_USER = "maxmon",
   MASTER_HOST = "192.168.56.201",
   MASTER_PORT = 4409,
   MASTER_PASSWORD = "P@ssw0rd",
   MASTER_USE_GTID = current_pos;
```

Note the MASTER_HOST (`192.168.56.201`) option is set to the IP address of the MaxScale Instance. The MASTER_PORT option is set to the `replication-listener` port, which we configured as **`4409`** in the replication listener section.

At this point, you can start replication using the `START SLAVE` command:

The Server connects to the Binary Log Router on the MaxScale Instance. Writes in InnoDB are then routed through this service back to the Server and written in the MariaDB ColumnStore table.

Check for replciation status using `SHOW SLAVE STATUS\G` from PM1 node to see it's connected and replicating from MaxScale binlog router

On `PM1` Node.

```txt
MariaDB [(none)]> start slave;
Query OK, 0 rows affected (0.051 sec)

MariaDB [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 192.168.56.201
                   Master_User: maxmon
                   Master_Port: 4409
                 Connect_Retry: 60
               Master_Log_File: es-101-bin.000004
           Read_Master_Log_Pos: 343
                Relay_Log_File: es-101-relay-bin.000002
                 Relay_Log_Pos: 643
         Relay_Master_Log_File: es-101-bin.000004
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
           Exec_Master_Log_Pos: 343
               Relay_Log_Space: 953
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
              Master_Server_Id: 1
                Master_SSL_Crl: 
            Master_SSL_Crlpath: 
                    Using_Gtid: Current_Pos
                   Gtid_IO_Pos: 0-1-15
       Replicate_Do_Domain_Ids: 
   Replicate_Ignore_Domain_Ids: 
                 Parallel_Mode: conservative
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for the slave I/O thread to update it
              Slave_DDL_Groups: 0
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.001 sec)
```

The above output confirms that the replication between PM1 and MaxScale (binlogfilter) is underway using the specialized port **`4409`**.

Executing the `slave status` on the PM2 node will show that PM2 is connected to PM1 node as a normal read-only replica which is what we expect.

Similarly, we can check the output of the `maxctrl list servers` on the MaxScale node to see some interesting output.

```txt
shell> maxctrl list servers;
┌──────────┬────────────────┬──────┬─────────────┬───────────────────────────────────────────┬────────┐
│ Server   │ Address        │ Port │ Connections │ State                                     │ GTID   │
├──────────┼────────────────┼──────┼─────────────┼───────────────────────────────────────────┼────────┤
│ PM1-Node │ 192.168.56.101 │ 3306 │ 1           │ Master, Slave of External Server, Running │ 0-1-15 │
├──────────┼────────────────┼──────┼─────────────┼───────────────────────────────────────────┼────────┤
│ PM2-Node │ 192.168.56.102 │ 3306 │ 0           │ Slave, Running                            │ 0-1-15 │
└──────────┴────────────────┴──────┴─────────────┴───────────────────────────────────────────┴────────┘
```

This shows that, while PM1-Node is a Master to PM2-Node, it is also a slave to an External master. That External server is MaxScale itself, since we have not configured localost as one of the servers, it does not know of it's existence.

The 1 connection on the PM1 node is actually from MaxScale's binlog filter.

