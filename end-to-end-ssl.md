# SSL/TLS For MariaDB

This guide discusses how to secure the connections to the database. The topics discussed include the following.

- Create a self-signed CA Cert
- Create a certificate for Servers
- Create a certificate for Clients
- Encrypt the data from client connections to MaxScale 
- Encrypt the data in transit from MaxScale to MariaDB servers
- Encrypt the data in transit from MariaDB Primary to Replica nodes (Encrypted Replication)

## Assumptions

We assume that `root` user access is available for this setup. MaxScale and MariaDB servers are already in place with MaxScale and MariaDB binaries already installed with replication configuration. The replication has not been set up previously, this last assumption does not make a big difference.

### Nodes

- MaxScale
- MariaDB Primary
- MariaDB Replica

## Creating Certificates

Create the following directories on all of the Nodes

- MaxScale
  - `mkdir -pv /var/lib/maxscale/maxscale.cnf.d/ssl`
- MariaDB Primary and Replica
  - `mkdir -pv /etc/my.cnf.d/ssl`

Connect to the MaxScale node and generate the following three certificates under the `/var/lib/maxscale/maxscale.cnf.d/ssl` directory.

#### CA Key

```
shell> cd /var/lib/maxscale/maxscale.cnf.d/ssl
shell> openssl genrsa 2048 > ca-key.pem
```

#### Server Certs

For the following two certs, Server and Client, make sure to key in different values for `Common Name` when prompted. Everything else can remain default or the values of your choice. If the `Common Name` also known as `CN` is not unique for both certs the verification step will fail.

```
shell> openssl req -new -x509 -nodes -days 9999 -key ca-key.pem > ca-cert.pem
shell> openssl req -newkey rsa:2048 -days 1000 -nodes -keyout server-key.pem > server-req.pem
shell> openssl x509 -req -in server-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
```

#### Client Certs

```
shell> openssl req -newkey rsa:2048 -days 3600 -nodes -keyout client-key.pem -out client-req.pem
shell> openssl rsa -in client-key.pem -out client-key.pem
shell> openssl x509 -req -in client-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
```

#### Certs Verification

Once the above two certs have been generated, let's verify to see if the certificates are valid. The following output confirms a successful verification.

```
shell> openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem
server-cert.pem: OK
client-cert.pem: OK
```

As mentioned above, if the CN/Common Name is not unique across the two certificates, the following error can be observed

```
shell> openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem
server-cert.pem: C = BR, ST = MG, L = BH, O = WBC, OU = WB, CN = WB, emailAddress = me@all.com
error 18 at 0 depth lookup:self signed certificate
OK
client-cert.pem: C = BR, ST = MG, L = BH, O = WBC, OU = WB, CN = WB, emailAddress = me@all.com
error 18 at 0 depth lookup:self signed certificate
OK
```

#### Listing the Certs

```
shell> pwd
/var/lib/maxscale/maxscale.cnf.d/ssl

shell> ls -lhrt
total 32K
-rw-r--r-- 1 root root 1.7K Oct 25 11:41 ca-key.pem
-rw-r--r-- 1 root root 1.3K Oct 25 11:41 ca-cert.pem
-rw-r--r-- 1 root root 1.7K Oct 25 11:41 server-key.pem
-rw-r--r-- 1 root root  980 Oct 25 11:42 server-req.pem
-rw-r--r-- 1 root root 1.2K Oct 25 11:42 server-cert.pem
-rw-r--r-- 1 root root  980 Oct 25 11:42 client-req.pem
-rw-r--r-- 1 root root 1.7K Oct 25 11:43 client-key.pem
-rw-r--r-- 1 root root 1.2K Oct 25 11:43 client-cert.pem
```

#### Copy Certs to Database Nodes

Now that the certificates are ready, we will have to copy the certs to the Primary and Replica nodes. Since the files are already in the MaxScale node, we don't have to worry about this server. 

## Preparing the MariaDB servers

Now that the certs are ready on both MariaDB servers, let's begin the setup.

The first thing to check would be if the current MariaDB server has SSL support and what are the TLS versions supported. Security requirements might require us to only use TLSv1.2 or TLSv1.3, we need to make sure those are available and supported by the server. 

These verifications can be done through the following two steps. 

```
MariaDB [(none)]> show global variables like '%ssl%';
+---------------------+---------------------------+
| Variable_name       | Value                     |
+---------------------+---------------------------+
| have_openssl        | YES                       |
| have_ssl            | DISABLED                  |
| ssl_ca              |                           |
| ssl_capath          |                           |
| ssl_cert            |                           |
| ssl_cipher          |                           |
| ssl_crl             |                           |
| ssl_crlpath         |                           |
| ssl_key             |                           |
| version_ssl_library | OpenSSL 3.0.2 15 Mar 2022 |
| wsrep_ssl_mode      | SERVER                    |
+---------------------+---------------------------+
11 rows in set (0.001 sec)
```

The output of `have_ssl` may have a possible of three values

- DISABLED
  - SSL support is available on the MariaDB server but it's disabled and needs to be enabled.
- YES
  - SSL support is available on the MariaDB server and it's enabled.
- NO
  - The MariaDB server was not compiled with SSL support and cannot be enabled/used.


The following confirms the TLS versions that are available to be used. 

```
MariaDB [(none)]> show global variables like '%tls%';
+---------------+-------------------------+
| Variable_name | Value                   |
+---------------+-------------------------+
| tls_version   | TLSv1.1,TLSv1.2,TLSv1.3 |
+---------------+-------------------------+
1 row in set (0.001 sec)
```

We can see the servers we are using can support 1.1, 1.2, and 1.3, if the security requirements demand a certain version we can simply set it in the server.cnf file as

```
[mariadb]
...
tls_version = TLSv1.2,TLSv1.3
```

This will enforce 1.2 and 1.3 versions only and reject any connections using 1.1

### MariaDB Configiration

Now that the verification is completed, we can add a new configuration file specifically for SSL.

Create a new file under the`/etc/my.cnf.d/` directory by the name `ssl.cnf` and add the following contents to it. The location will depend on the LINUX distro being used, for Ubuntu, the path will be `/etc/mysql/mariadb.cnf.d`

```
shell> cat /etc/my.cnf.d/ssl.cnf

[client]
ssl
ssl-ca=/etc/my.cnf.d/ssl/ca-cert.pem
ssl-cert=/etc/my.cnf.d/ssl/client-cert.pem
ssl-key=/etc/my.cnf.d/ssl/client-key.pem

[mariadb]
ssl
ssl-ca=/etc/my.cnf.d/ssl/ca-cert.pem
ssl-cert=/etc/my.cnf.d/ssl/server-cert.pem
ssl-key=/etc/my.cnf.d/ssl/server-key.pem
```

Ensure the above is done on both of the MariaDB servers. Restart the MariaDB nodes and log in to the server to verify.

After a successful restart, we can verify the SSL status 

```
ariaDB [(none)]> show global variables like '%ssl%';
+---------------------+-----------------------------------+
| Variable_name       | Value                             |
+---------------------+-----------------------------------+
| have_openssl        | YES                               |
| have_ssl            | YES                               |
| ssl_ca              | /etc/my.cnf.d/ssl/ca-cert.pem     |
| ssl_capath          |                                   |
| ssl_cert            | /etc/my.cnf.d/ssl/server-cert.pem |
| ssl_cipher          |                                   |
| ssl_crl             |                                   |
| ssl_crlpath         |                                   |
| ssl_key             | /etc/my.cnf.d/ssl/server-key.pem  |
| version_ssl_library | OpenSSL 3.0.2 15 Mar 2022         |
| wsrep_ssl_mode      | SERVER                            |
+---------------------+-----------------------------------+
11 rows in set (0.001 sec)
```

This confirms the `have_ssl` is `YES` which means the SSL has been enabled. The other SSL variables also list the three certificates for the SERVER.

### Setting GTID Based Replication

Now the SSL clients and server certificates are in place on both of the MariaDB servers, we are ready to set up the replicaiton using an encrypted connection. The assumption here is that the servers are new and the replication has not been set up previously.

#### Create Replication User

Create the traditional user account for replicaiton purposes and grant `REPLICATION SLAVE` privileges. This user must also have an additional keyword of `REQUIRE SSL` so that it will not work on an unencrypted connection.

In this setup, the host `Node1` has the private IP `172.31.22.121` and the `Node2` has the private IP `172.31.25.123` We can create the replicaiton user with `172.31.%` as the wildcard instead of wildcarding all hosts.

Connecto the `Node1` and create the following replication user with the replicaiton grant.

```
MariaDB [(none)]> CREATE USER rep_user@'172.31.%' IDENTIFIED BY 'P@ssw0rd' REQUIRE SSL;
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO rep_user@'172.31.%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> SHOW GRANTS FOR rep_user@'172.31.%';
+----------------------------------------------------------------------------------------------------------------------------------------+
| Grants for rep_user@172.31.%                                                                                                           |
+----------------------------------------------------------------------------------------------------------------------------------------+
| GRANT REPLICATION SLAVE ON *.* TO `rep_user`@`172.31.%` IDENTIFIED BY PASSWORD '*8232A1298A49F710DBEE0B330C42EEC825D4190A' REQUIRE SSL |
+----------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.000 sec)
```

#### Set up Replication

Connect to the `Node2` and set up a replicaiton link with SSL certificate paths accordingly.

```
MariaDB [(none)]> CHANGE MASTER TO MASTER_HOST='172.31.22.12',
    ->   MASTER_USER='rep_user',
    ->   MASTER_PASSWORD='P@ssw0rd',
    ->   MASTER_USE_GTID=SLAVE_POS,
    ->   MASTER_SSL=1,
    ->   MASTER_SSL_CA='/etc/my.cnf.d/ssl/ca-cert.pem',
    ->   MASTER_SSL_CERT='/etc/my.cnf.d/ssl/client-cert.pem',
    ->   MASTER_SSL_KEY='/etc/my.cnf.d/ssl/client-key.pem';
Query OK, 0 rows affected (0.019 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.010 sec)

MariaDB [(none)]> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 172.31.22.12
                   Master_User: rep_user
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mariadb-bin.000001
           Read_Master_Log_Pos: 677
                Relay_Log_File: mysqld-relay-bin.000002
                 Relay_Log_Pos: 978
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
           Exec_Master_Log_Pos: 677
               Relay_Log_Space: 1288
               Until_Condition: None
                Until_Log_File:
                 Until_Log_Pos: 0
            Master_SSL_Allowed: Yes
            Master_SSL_CA_File: /etc/my.cnf.d/ssl/ca-cert.pem
            Master_SSL_CA_Path:
               Master_SSL_Cert: /etc/my.cnf.d/ssl/client-cert.pem
             Master_SSL_Cipher:
                Master_SSL_Key: /etc/my.cnf.d/ssl/client-key.pem
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
                   Gtid_IO_Pos: 0-1000-2
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
              Slave_DDL_Groups: 2
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.000 sec)
```

We can see the replicaiton is now running and the Node2 database has become a replica with it's GTID pos already caught up to `0-1000-2` GTID. The SSL Certs are also visible in the slave status confirming that the connection between the two MariaDB nodes is encrypted. 

## Set up MaxScale

### Create MaxScale User

Connect to the Primary node, `Node1`, and create a MaxScale user with the specific grants required for a MaxScale user. This user should also have the `REQIURE SSL` clause. The MaxScale IP for my setup is `172.31.21.123` the user will be created, and fixed for this specific IP.

```
MariaDB [(none)]> CREATE USER mxs@'172.31.21.123' IDENTIFIED BY 'P@ssw0rd' REQUIRE SSL;
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT SHOW DATABASES ON *.* TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.004 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.columns_priv TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.db TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.procs_priv TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.proxies_priv TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.roles_mapping TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.tables_priv TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.user TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT BINLOG MONITOR, REPLICA MONITOR ON *.* TO mxs@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT BINLOG ADMIN,
    ->    READ_ONLY ADMIN,
    ->    RELOAD,
    ->    REPLICA MONITOR,
    ->    REPLICATION MASTER ADMIN,
    ->    REPLICATION REPLICA ADMIN,
    ->    REPLICATION REPLICA,
    ->    SHOW DATABASES
    -> ON *.* TO 'mxs'@'172.31.21.123';
Query OK, 0 rows affected (0.003 sec)
```

### Configure MaxScale

Connect to the MaxScale Node and generate the encrypted password for the `mxs@'172.31.21.123'` user

At the `bash` prompt, execute the following.

```
shell> maxkeys
Permissions of '/var/lib/maxscale/.secrets' set to owner:read.
Ownership of '/var/lib/maxscale/.secrets' given to maxscale.

shell> maxpasswd P@ssw0rd
884133CF7C041DA712FD4B67C6BA8E96EFE2E2B524726473A4073A3D527584E8
```

The `maxpasswd` generates the encrypted password of the original `P@ssw0rd` value. Keep this value safe.

We will be using the `maxctrl` command line to configure the MaxScale. Before we do that, replace the default `/etc/maxscale.cnf` file with the following content.

```
[maxscale]
threads          = auto
admin_host       = 0.0.0.0
admin_secure_gui = false

[Server-1]
type       = server
address    = 172.31.22.12
port       = 3306
ssl        = true
ssl_cert   = /var/lib/maxscale/maxscale.cnf.d/ssl/client-cert.pem
ssl_key    = /var/lib/maxscale/maxscale.cnf.d/ssl/client-key.pem
ssl_ca     = /var/lib/maxscale/maxscale.cnf.d/ssl/ca-cert.pem

[Server-2]
type       = server
address    = 172.31.25.123
port       = 3306
ssl        = true
ssl_cert   = /var/lib/maxscale/maxscale.cnf.d/ssl/client-cert.pem
ssl_key    = /var/lib/maxscale/maxscale.cnf.d/ssl/client-key.pem
ssl_ca     = /var/lib/maxscale/maxscale.cnf.d/ssl/ca-cert.pem

[MariaDB-Monitor]
type = monitor
module = mariadbmon
servers = Server-1, Server-2
user = mxs
password = 884133CF7C041DA712FD4B67C6BA8E96EFE2E2B524726473A4073A3D527584E8 
monitor_interval = 3s
verify_master_failure = true
enforce_read_only_slaves = true
auto_failover = true
auto_rejoin = true
cooperative_monitoring_locks=majority_of_running

## This is the replication-rwsplit-service
[Read-Write-Service]
type = service
router = readwritesplit
servers = Server-1, Server-2
master_accept_reads = true
user = mxs
password = 884133CF7C041DA712FD4B67C6BA8E96EFE2E2B524726473A4073A3D527584E8
master_reconnection = true
transaction_replay = true
transaction_replay_max_size = 10Mi
transaction_replay_attempts = 10
delayed_retry = ON
delayed_retry_timeout = 240s
prune_sescmd_history = true

# For Read Consistency, test this with the value "local", "global" and "universal" to always use Slaves for reading 
causal_reads = universal
causal_reads_timeout=1s

transaction_replay_retry_on_deadlock = true

## To send all the stored procedure calls to the Primary DB Server!
# strict_sp_calls = true

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port = 4009
address = 0.0.0.0
ssl        = true
ssl_cert   = /var/lib/maxscale/maxscale.cnf.d/ssl/client-cert.pem
ssl_key    = /var/lib/maxscale/maxscale.cnf.d/ssl/client-key.pem
ssl_ca     = /var/lib/maxscale/maxscale.cnf.d/ssl/ca-cert.pem
```

Save and restart MaxScale using `systemctl restart maxscale`

The above is a standard MaxScale configuration but the key points to note are the SSL related parameters under the `Server-1`, `Server-2` and the `Read-Write-Listener` sections. These are all the client certs so that the MaxScale can connect to the MariaDB backend.

#### Test Connectivity

Connect to MariaDB using the MaxScale host IP and listener PORT `4009` 

```
shell> mariadb -urebel -p -h172.31.21.123 -P4009
Enter password:
ERROR 1045 (28000): Access denied for user 'rebel'@'172.31.21.123' (using password: YES)
```

We are unable to connect as MaxScale requires SSL connections. To solve the problem we need to pass in an additional argument to tell the MariaDB client to establish a secure connection using SSL.

```
shell> mariadb -urebel -p -h172.31.21.123 -P4009 --ssl
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 2
Server version: 10.6.15-10-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> STATUS;
--------------
mariadb  Ver 15.1 Distrib 10.6.15-10-MariaDB, for debian-linux-gnu (x86_64) using  EditLine wrapper

Connection id:    7
Current database:
Current user:   rebel@ip-172-31-21-123.ap-southeast-1.compute.internal
SSL:      Cipher in use is TLS_AES_256_GCM_SHA384
Current pager:    stdout
Using outfile:    ''
Using delimiter:  ;
Server:     MariaDB
Server version:   10.6.15-10-MariaDB-enterprise-log MariaDB Enterprise Server
Protocol version: 10
Connection:   172.31.21.123 via TCP/IP
Server characterset:  utf8mb4
Db     characterset:  utf8mb4
Client characterset:  utf8mb3
Conn.  characterset:  utf8mb3
TCP port:   4009
Uptime:     2 hours 1 min 14 sec

Threads: 5  Questions: 1884  Slow queries: 0  Opens: 34  Open tables: 28  Queries per second avg: 0.259
--------------
```

The `SSL:` section shows that the connection is secure using Cipher `TLS_AES_256_GCM_SHA384`, we can also find out the same detail using a simple `SHOW STATUS` command.

```
MariaDB [(none)]> SHOW STATUS LIKE 'Ssl_cipher';
+---------------+------------------------+
| Variable_name | Value                  |
+---------------+------------------------+
| Ssl_cipher    | TLS_AES_256_GCM_SHA384 |
+---------------+------------------------+
1 row in set (0.003 sec)
```

This setup will not let any connection to MaxScale or Database that is not secured by strong TLSv1.2 or TLSv1.3

##### Thank you!


