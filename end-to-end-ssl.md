# TLS For MariaDB & MaxScale

## Background

Security has been a major requirement when dealing with any data. Just having the database encrypted at rest is not enough. The data in transit from Client connections to the Database should also be encrypted end-to-end.

This encryption of data in transit also includes the replication streams from Primary to Replica nodes. 

## Introduction 

In this guide, we will discusses how to secure the connections to the database. The topics discussed include the following.

- Create a self-signed CA Cert
- Create a certificate for Servers
- Create a certificate for Clients
- Encrypt the data from client connections to MaxScale 
- Encrypt the data in transit from MaxScale to MariaDB servers
- Encrypt the data in transit from MariaDB Primary to Replica nodes (Encrypted Replication)

We are using self signed certs only for the sake of this guide, the CA should be an official one in production environments and certificates renewed based on the organiational policies. For instance, if using AWS infrastructure, we could use the AWS ACM to generate CA and the other certificates instead of self signing.

## Assumptions

We assume that

- MariaDB server is the Enterprise 10.6 or higher
- MariaDB MaxScale is 23.02 or higher
- The `root`/`sudo` access is available for this setup. 
- MaxScale and MariaDB servers are already in place with MaxScale and MariaDB binaries already installed with replication configuration.
- The replication has not been set up previously. If it has, we will need to ALTER the existing replication user instead of creating one.
- OpenSSL is installed on the nodes.

### Nodes

- MaxScale
- MariaDB Primary
- MariaDB Replica

## Creating Certificates

Connect to the MaxScale node and create the directory `/certs`. Generate the following certificates in the same directory. The server certificates will be moved out to individual nodes while the MaxScale and Client certs will remain on the MaxScale node.

#### CA Cert

For the CA certificate, the lifetime is 3 years, it's a good practice to have the CA live from one to five years depending on the organisation's security standards.

```
shell> mkdir -pv /certs
shell> cd /certs
shell> openssl genrsa 2048 > ca-key.pem
shell> openssl req -new -x509 -nodes -days 1095 -key ca-key.pem > ca-cert.pem
```

Subsequent certificates will be using this `ca-cert.pem` file for signing.

#### Server Certs

For the following two certs, Server and Client, make sure to key in different values for `Common Name` when prompted. Everything else can remain default or the values of your choice. If the `Common Name` also known as `CN` is not unique for both certs the verification step will fail.

```
shell> openssl req -newkey rsa:2048 -days 1000 -nodes -keyout server-key.pem > server-req.pem
shell> openssl x509 -req -in server-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
```

#### Client Certs

```
shell> openssl req -newkey rsa:2048 -days 3600 -nodes -keyout client-key.pem -out client-req.pem
shell> openssl rsa -in client-key.pem -out client-key.pem
shell> openssl x509 -req -in client-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
```

#### MaxScale Admin/Listener Certs

```
shell> openssl req -newkey rsa:2048 -days 3600 -nodes -keyout maxscale-key.pem -out maxscale-req.pem
shell> openssl rsa -in maxscale-key.pem -out maxscale-key.pem
shell> openssl x509 -req -in maxscale-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out maxscale-cert.pem
```

#### Certs Verification

Once the above two certs have been generated, let's verify to see if the certificates are valid. The following output confirms a successful verification.

```
shell> openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem maxscale-cert.pem
server-cert.pem: OK
client-cert.pem: OK
maxscale-cert.pem: OK
```

As mentioned above, if the CN/Common Name is not unique across the two certificates, the following error can be observed

```
shell> openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem maxscale-cert.pem
server-cert.pem: C = BR, ST = MG, L = BH, O = WBC, OU = WB, CN = WB, emailAddress = me@all.com
error 18 at 0 depth lookup:self signed certificate
OK
client-cert.pem: C = BR, ST = MG, L = BH, O = WBC, OU = WB, CN = WB, emailAddress = me@all.com
error 18 at 0 depth lookup:self signed certificate
OK
maxscale-cert.pem: C = BR, ST = MG, L = BH, O = WBC, OU = WB, CN = WB, emailAddress = me@all.com
error 18 at 0 depth lookup:self signed certificate
OK
```

#### Listing the Certs

The `*-req.pem` files can be removed from the folder tls folder.

```
shell> pwd
/certs

shell> rm -rf *-req.pem

shell> ls -lrt
total 32
-rw-r--r--. 1 root root 1675 Dec  9 14:09 ca-key.pem
-rw-r--r--. 1 root root 1273 Dec  9 14:09 ca-cert.pem
-rw-------. 1 root root 1704 Dec  9 14:09 server-key.pem
-rw-r--r--. 1 root root 1131 Dec  9 14:10 server-cert.pem
-rw-------. 1 root root 1675 Dec  9 14:11 client-key.pem
-rw-r--r--. 1 root root 1131 Dec  9 14:11 client-cert.pem
-rw-------. 1 root root 1679 Dec  9 14:12 maxscale-key.pem
-rw-r--r--. 1 root root 1135 Dec  9 14:12 maxscale-cert.pem
```

It's super important to set up proper security of the folders and files to protect the certificates and the keys to be owned by `maxscale:maxscale`.

```
shell> chown -R maxscale:maxscale /certs
shell> chmod -R 500 /certs
shell> chmod 400 /certs/*
shell> ls -lrt
total 32
-r--------. 1 maxscale maxscale 1675 Dec  9 14:09 ca-key.pem
-r--------. 1 maxscale maxscale 1273 Dec  9 14:09 ca-cert.pem
-r--------. 1 maxscale maxscale 1704 Dec  9 14:09 server-key.pem
-r--------. 1 maxscale maxscale 1131 Dec  9 14:10 server-cert.pem
-r--------. 1 maxscale maxscale 1675 Dec  9 14:11 client-key.pem
-r--------. 1 maxscale maxscale 1131 Dec  9 14:11 client-cert.pem
-r--------. 1 maxscale maxscale 1679 Dec  9 14:12 maxscale-key.pem
-r--------. 1 maxscale maxscale 1135 Dec  9 14:12 maxscale-cert.pem
```

#### Copy Certs to Database Nodes

Now that the TLS certificates are ready, we will have to transfer the certs to the Primary and Replica nodes securely. Keep the files in the `/etc/my.cnf.d/tls` directory. The files to copy will include the following list

- ca-cert.pem
- ca-key.pem
- server-cert.pem
- server-key.pem
- client-cert.pem
- client-key.pem

Assume the above listed files are already transferred to both MariaDB nodes, set permissions of the `/etc/my.cnf.d/tls` folder and it's contents to least privileged and owned by `mysql:mysql`.

```
shell> chown -R mysql:mysql /etc/my.cnf.d/tls
shell> chmod 500 /etc/my.cnf.d/tls
shell> ls -lrt
total 24
-r--------. 1 mysql mysql 1273 Dec  9 15:10 ca-cert.pem
-r--------. 1 mysql mysql 1675 Dec  9 15:10 ca-key.pem
-r--------. 1 mysql mysql 1131 Dec  9 15:10 client-cert.pem
-r--------. 1 mysql mysql 1675 Dec  9 15:10 client-key.pem
-r--------. 1 mysql mysql 1131 Dec  9 15:10 server-cert.pem
-r--------. 1 mysql mysql 1704 Dec  9 15:10 server-key.pem
```

## Preparing the MariaDB servers

Now that the certs are ready on both MariaDB servers, let's begin the setup.

The first thing to check would be if the current MariaDB server has TLS support and what are the TLS versions supported. Security requirements might require us to only use TLSv1.2 or TLSv1.3, we need to make sure those are available and supported by the server. 

These verifications can be done through the following two steps. 

```
MariaDB [(none)]> show global variables like 'have_ssl';
+---------------------+---------------------------+
| Variable_name       | Value                     |
+---------------------+---------------------------+
| have_ssl            | DISABLED                  |
+---------------------+---------------------------+
1 rows in set (0.001 sec)
```

The output of `have_ssl` may have a possible of three values

- DISABLED
  - TLS support is available on the MariaDB server but it's disabled and needs to be enabled.
- YES
  - TLS support is available on the MariaDB server and it's enabled.
- NO
  - The MariaDB server was not compiled with TLS support and cannot be enabled/used.


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

### MariaDB Configuration

Now that the verification is completed, we can add a new configuration file specifically for TLS.

Create a new file under the`/etc/my.cnf.d/` directory by the name `tls.cnf` and add the following contents to it. The location will depend on the LINUX distro being used, for Ubuntu, the path will be `/etc/mysql/mariadb.cnf.d`. Ensure that the new file `/etc/my.cnf.d/tls.cnf` is readable by `mysql` user. 

```
shell> cat /etc/my.cnf.d/tls.cnf

[client]
ssl
ssl-ca=/etc/my.cnf.d/tls/ca-cert.pem
ssl-cert=/etc/my.cnf.d/tls/client-cert.pem
ssl-key=/etc/my.cnf.d/tls/client-key.pem

[mariadb]
ssl
ssl-ca=/etc/my.cnf.d/tls/ca-cert.pem
ssl-cert=/etc/my.cnf.d/tls/server-cert.pem
ssl-key=/etc/my.cnf.d/tls/server-key.pem
```

Ensure the above is done on both of the MariaDB servers. Restart the MariaDB nodes and log in to the server to verify.

After a successful restart, we can verify the TLS status 

```
MariaDB [(none)]> show global variables like '%ssl%';
+---------------------+-----------------------------------+
| Variable_name       | Value                             |
+---------------------+-----------------------------------+
| have_openssl        | YES                               |
| have_ssl            | YES                               |
| ssl_ca              | /etc/my.cnf.d/tls/ca-cert.pem     |
| ssl_capath          |                                   |
| ssl_cert            | /etc/my.cnf.d/tls/server-cert.pem |
| ssl_cipher          |                                   |
| ssl_crl             |                                   |
| ssl_crlpath         |                                   |
| ssl_key             | /etc/my.cnf.d/tls/server-key.pem  |
| version_ssl_library | OpenSSL 1.1.1k  FIPS 25 Mar 2021  |
| wsrep_ssl_mode      | SERVER                            |
+---------------------+-----------------------------------+
11 rows in set (0.001 sec)
```

This confirms the `have_ssl` is `YES` which means the TLS has been enabled. The other TLS variables also list the three certificates for the SERVER.

### Setting GTID Based Replication

Now the TLS clients and server certificates are in place on both of the MariaDB servers, we are ready to set up the replicaiton using an encrypted connection. The assumption here is that the servers are new and the replication has not been set up previously.

#### Create Replication User

Create the traditional user account for replicaiton purposes and grant `REPLICATION SLAVE` privileges. This user must also have an additional keyword of `REQUIRE SSL` so that it will not work on an unencrypted connection. But if we want to have mutual authentication, also known as, two-way TLS authentication setup where all the clients are rquired to present a specific certificate at the time of connection, we should use `REQUIRE X509` instead at the time of user creation. This method is more secured and desirable.

When `REQUIRE X509` is used, it means that:
- The MariaDB server must be configured with TLS, including server certificates.
- The client (user) must also provide a valid TLS certificate when connecting.
- The server will verify the client's certificate against a CA (Certificate Authority) certificate.

This setup is used when security requirements are higher.

In this setup, the host `Node1` has the private IP `172.31.32.197` and the `Node2` has the private IP `172.31.42.232` We can create the replicaiton user with `172.31.%` as the wildcard instead of wildcarding all hosts.

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

Connect to the `Node2` and set up a replicaiton link with TLS certificate paths accordingly.

```
MariaDB [(none)]> CHANGE MASTER TO MASTER_HOST='172.31.32.197',
                  MASTER_USER='rep_user',
                  MASTER_PASSWORD='P@ssw0rd',
                  MASTER_USE_GTID=SLAVE_POS,
                  MASTER_SSL=1,
                  MASTER_SSL_CA='/etc/my.cnf.d/tls/ca-cert.pem',
                  MASTER_SSL_CERT='/etc/my.cnf.d/tls/client-cert.pem',
                  MASTER_SSL_KEY='/etc/my.cnf.d/tls/client-key.pem';
Query OK, 0 rows affected (0.019 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.010 sec)

MariaDB [(none)]> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 172.31.32.197
                   Master_User: rep_user
                   Master_Port: 3306
                 Connect_Retry: 60
                              ...
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
                              ...
            Master_SSL_Allowed: Yes
            Master_SSL_CA_File: /etc/my.cnf.d/tls/ca-cert.pem
            Master_SSL_CA_Path:
               Master_SSL_Cert: /etc/my.cnf.d/tls/client-cert.pem
             Master_SSL_Cipher:
                Master_SSL_Key: /etc/my.cnf.d/tls/client-key.pem
                              ...
              Master_Server_Id: 1000
                Master_SSL_Crl:
            Master_SSL_Crlpath:
                    Using_Gtid: Slave_Pos
                   Gtid_IO_Pos: 0-1000-2
                              ...
1 row in set (0.000 sec)
```

We can see the replicaiton is now running and the Node2 database has become a replica with it's GTID pos already caught up to `0-1000-2` GTID. The TLS Certs are also visible in the slave status confirming that the connection between the two MariaDB nodes is encrypted. 

## Set up MaxScale

### Create MaxScale User

Connect to the Primary node, `Node1`, and create a MaxScale user with the specific grants required for a MaxScale user. This user should also have the `REQIURE SSL` clause. The MaxScale IP for my setup is `172.31.21.123` the user will be created, and fixed for this specific IP.

```
MariaDB [(none)]> CREATE USER mxs@'172.31.%' IDENTIFIED BY 'P@ssw0rd' REQUIRE SSL;
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.* TO mxs@'172.31.%';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> GRANT BINLOG ADMIN,
                    READ_ONLY ADMIN,
                    RELOAD,
                    REPLICA MONITOR,
                    REPLICATION MASTER ADMIN,
                    REPLICATION REPLICA ADMIN,
                    REPLICATION REPLICA,
                    BINLOG MONITOR, 
                    REPLICA MONITOR,
                    SHOW DATABASES
                  ON *.* TO 'mxs'@'172.31.%';
Query OK, 0 rows affected (0.003 sec)
```

### Configure MaxScale

Connect to the MaxScale node and create a new admin user and destroy the existing default `admin` user.

```
[root@ip-172-31-46-164 tls]# maxctrl create user secured_admin secret_password --type=admin
OK
[root@ip-172-31-46-164 tls]# maxctrl destroy user admin
OK
```

Now generate the encrypted password for the `mxs@'172.31.%` user

At the `bash` prompt, execute the following.

```
shell> maxkeys
Permissions of '/var/lib/maxscale/.secrets' set to owner:read.
Ownership of '/var/lib/maxscale/.secrets' given to maxscale.

shell> maxpasswd P@ssw0rd
884133CF7C041DA712FD4B67C6BA8E96EFE2E2B524726473A4073A3D527584E8
```

The `maxpasswd` generates the encrypted password of the original `P@ssw0rd` value. Keep this value safe.

Replace the default `/etc/maxscale.cnf` file with the following content. This will configure secure GUI using TLS certificates and also secure connections from Client to MaxScale and MaxScale to the MariaDB nodes using the previously created Client TLS certificates and MaxScale TLS certificates which we will use at the listener section for the clients to connect to MaxScale.

```
[maxscale]
threads           = auto
admin_host        = 0.0.0.0
admin_secure_gui  = true
admin_ssl_key     = /certs/maxscale-key.pem
admin_ssl_cert    = /certs/maxscale-cert.pem
admin_ssl_ca_cert = /certs/ca-cert.pem

[Server-1]
type       = server
address    = 172.31.32.197
port       = 3306
ssl        = true
ssl_cert   = /certs/client-cert.pem
ssl_key    = /certs/client-key.pem
ssl_ca     = /certs/ca-cert.pem

[Server-2]
type       = server
address    = 172.31.42.232
port       = 3306
ssl        = true
ssl_cert   = /certs/client-cert.pem
ssl_key    = /certs/client-key.pem
ssl_ca     = /certs/ca-cert.pem

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
causal_reads = global
causal_reads_timeout=1s
max_slave_replication_lag=1s
transaction_replay_retry_on_deadlock = true

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port = 4009
address = 0.0.0.0
ssl        = true
ssl_cert   = /certs/maxscale-cert.pem
ssl_key    = /certs/maxscale-key.pem
ssl_ca     = /certs/ca-cert.pem
```

Save and restart MaxScale using `systemctl restart maxscale`

The above is a standard MaxScale configuration but the key points to note are the TLS related parameters under the `Server-1`, `Server-2` and the `Read-Write-Listener` sections. These are all the client certs so that the MaxScale can connect to the MariaDB backend.

#### Verify TLS on MaxScale

```
bash> maxctrl --user=secured_admin --password='' --secure --tls-ca-cert=/certs/ca-cert.pem --tls-verify-server-cert=false show maxscale | grep admin_ssl
Enter password: ***********
│              │     "admin_ssl_ca": "/certs/ca-cert.pem",                               │
│              │     "admin_ssl_cert": "/certs/maxscale-cert.pem",                       │
│              │     "admin_ssl_key": "/certs/maxscale-key.pem",                         │
│              │     "admin_ssl_version": "MAX",                                         │
```

The above output confirms TLS has been setup successfully for the admin access of MaxScale. 

Verify the MaxScale can now connect to the MariaDB backend servers.

```
[root@ip-172-31-46-164 certs]# maxctrl --user=secured_admin --password='' --secure --tls-ca-cert=/certs/ca-cert.pem --tls-verify-server-cert=false list servers
Enter password: ***********
┌──────────┬───────────────┬──────┬─────────────┬─────────────────┬───────────┬─────────────────┐
│ Server   │ Address       │ Port │ Connections │ State           │ GTID      │ Monitor         │
├──────────┼───────────────┼──────┼─────────────┼─────────────────┼───────────┼─────────────────┤
│ Server-1 │ 172.31.32.197 │ 3306 │ 0           │ Master, Running │ 10-1000-8 │ MariaDB-Monitor │
├──────────┼───────────────┼──────┼─────────────┼─────────────────┼───────────┼─────────────────┤
│ Server-2 │ 172.31.42.232 │ 3306 │ 0           │ Slave, Running  │ 10-1000-8 │ MariaDB-Monitor │
└──────────┴───────────────┴──────┴─────────────┴─────────────────┴───────────┴─────────────────┘
```

Note: For all the `maxctrl` commands, we would now need to use the above format. Best to use the Secured GUI at `https://<maxscale-public-ip>:8989` for monitoring and management. 

#### Test Connectivity

Connect to MariaDB using the MaxScale host IP `172.31.46.164` and listener PORT `4009` 

```
shell> mariadb -urebel -p -h172.31.46.164 -P4009
Enter password:
ERROR 1045 (28000): Access denied for user 'rebel'@'172.31.46.164' (using password: YES)
```

We are unable to connect to the MariaDB backend through MaxSclae as MaxScale requires TLS connections. To solve the problem we need to pass in an additional argument to tell the MariaDB client to establish a secure connection using TLS.

```
shell> mariadb -urebel -p -h172.31.46.164 -P4009 --ssl

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
Connection:   172.31.46.164 via TCP/IP
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

This setup will not let any connection to MaxScale or Database that is not secured by the strong TLSv1.2 or TLSv1.3

##### Thank you!