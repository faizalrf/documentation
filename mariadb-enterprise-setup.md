# MariaDB Enterprise Server 10.6

This guide discusses how to implement MariaDB 10.6 enterprise with 100% acid compliance and Semi-Sync replication between two nodes.

## Assumptions

- 3 x RHEL 7/8 VM or Servers are available with `root` user access
- MariaDB 10.6 ES RPM package already downloaded to the servers
- MariaDB MaxScale 6.1 has also been downloaded to a third server used for MaxScale

## Install MariaDB 10.6

To install MariaDB, we need a `root` user account. Extract the RPM tar package to /tmp/mariadb folder and set up a local repository so that `yum install` can be done.

- Downloads
  - MariaDB <https://mariadb.com/downloads/enterprise/enterprise-server/>
  - MaxScale <https://mariadb.com/downloads/enterprise/enterprise-maxscale/>

Download and transfer the two RPM TAR packages to the respective servers.

Please take note that the installation process of MariaDB server is the same for both nodes, all the following steps are to be repeated for both MariaDB servers in UAT & PROD where Master/Slave setup is needed.

Untar the rpm package 

```
[server1 tmp]# ls -lrt maria*
-rw-r--r--. 1 ec2-user ec2-user 85094400 Feb  8 13:47 mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms.tar

[server1 tmp]# tar -xvf mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms.tar
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/galera-enterprise-4-26.4.10-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-columnstore-cmapi-1.6.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/jemalloc-3.6.0-1.el7.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/jemalloc-devel-3.6.0-1.el7.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-backup-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-client-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-columnstore-engine-10.6.5_2_6.2.2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-common-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-compat-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-cracklib-password-check-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-devel-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-gssapi-server-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-hashicorp-key-management-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-rocksdb-engine-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-s3-engine-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-server-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-shared-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-spider-engine-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/MariaDB-xpand-engine-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/setup_repository
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/unsupported/
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/unsupported/MariaDB-connect-engine-10.6.5_2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/b88ad400315ff846298f54c97e330587a9802f996b683a205dbd26c47ed6ae75-primary.xml.gz
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/1170744a97cd22531737af6c295ba5fbbf40785a3728d4ebbe0da152486443e8-filelists.xml.gz
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/a52ff7195726e785c55f3ddaab97d3caaccbc171db1a1c212c62b7496bb7e1f9-other.xml.gz
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/d63f5b532d780f85e5ec8dd3870be899a274790b8336985a26acd486215f3769-filelists.sqlite.bz2
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/repomd.xml
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/e572e2617222ad0f89e8364f92b7e5744ad2c0ad949d3047dbc91394bc5ce44e-other.sqlite.bz2
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/repodata/820e2b0f1e7e08914a78186a070507a1dd65763c2ae6d3b5cf9c3704ea73aaa7-primary.sqlite.bz2
mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms/README
```

One of the extracted files is `setup_repository`, this is an executable script. Execute this to create a local repository on your server. 

```
[server1 tmp]# cd mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms

[server1 mariadb-enterprise-10.6.5-2-rhel-7-x86_64-rpms]# ./setup_repository
Repository file successfully created! Please install MariaDB Server with this command:

   yum install MariaDB-server
```

Repository is ready, as instructed by the output above, we can now Install the MariaDB 10.6 enterprise on to both of the servers.

We need to install `MariaDB-server` and `MariaDB-backup` for all the servers running MariaDB

```
[server1 ~]# yum -y install MariaDB-server MariaDB-backup

Resolving Dependencies
--> Running transaction check
...
...
Dependencies Resolved

==============================================================================================================================================================================================================================================================================================
 Package                                                                    Arch                                                      Version                                                                Repository                                                                  Size
==============================================================================================================================================================================================================================================================================================
Installing:
 MariaDB-backup                                                             x86_64                                                    10.6.5_2-1.el7_9                                                       MariaDB                                                                    7.0 M
 MariaDB-compat                                                             x86_64                                                    10.6.5_2-1.el7_9                                                       MariaDB                                                                    2.2 M
     replacing  mariadb-libs.x86_64 1:5.5.68-1.el7
 MariaDB-server                                                             x86_64                                                    10.6.5_2-1.el7_9                                                       MariaDB                                                                     19 M
Installing for dependencies:
 MariaDB-client                                                             x86_64                                                    10.6.5_2-1.el7_9                                                       MariaDB                                                                    8.6 M
 MariaDB-common                                                             x86_64                                                    10.6.5_2-1.el7_9                                                       MariaDB                                                                     82 k
 galera-enterprise-4                                                        x86_64                                                    26.4.10-1.el7_9                                                        MariaDB                                                                    1.2 M
...
...
...
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                                          19 MB/s |  52 MB  00:00:02
Retrieving key from https://downloads.mariadb.com/MariaDB/MariaDB-Enterprise-GPG-KEY
Importing GPG key 0xE3C94F49:
 Userid     : "MariaDB Enterprise Signing Key <signing-key@mariadb.com>"
 Fingerprint: 4c47 0fff efc4 d3dc 5977 8655 ce1a 3dd5 e3c9 4f49
 From       : https://downloads.mariadb.com/MariaDB/MariaDB-Enterprise-GPG-KEY
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-common-10.6.5_2-1.el7_9.x86_64                                                                                                                                                                                                                                    3/45
  Installing : MariaDB-compat-10.6.5_2-1.el7_9.x86_64                                                                                                                                                                                                                                    4/45
  Installing : MariaDB-client-10.6.5_2-1.el7_9.x86_64                                                                                                                        
  Installing : galera-enterprise-4-26.4.10-1.el7_9.x86_64                                                                                                                                                                                                                               42/45
  Installing : MariaDB-server-10.6.5_2-1.el7_9.x86_64                                                                                                                                                                                                                                   43/45
  Installing : MariaDB-backup-10.6.5_2-1.el7_9.x86_64                                                                                                                                                                                                                                   44/45
  Erasing    : 1:mariadb-libs-5.5.68-1.el7.x86_64                                                                                                                                                                                                                                       45/45
  ...
  ...                                                                                                               45/45

Dependency Installed:
  MariaDB-client.x86_64 0:10.6.5_2-1.el7_9       MariaDB-common.x86_64 0:10.6.5_2-1.el7_9       boost-program-options.x86_64 0:1.53.0-28.el7       galera-enterprise-4.x86_64 0:26.4.10-1.el7_9       libaio.x86_64 0:0.3.109-13.el7            lsof.x86_64 0:4.87-6.el7
  perl.x86_64 4:5.16.3-299.el7_9                 perl-Carp.noarch 0:1.26-244.el7                perl-Compress-Raw-Bzip2.x86_64 0:2.061-3.el7       perl-Compress-Raw-Zlib.x86_64 1:2.061-4.el7        perl-DBI.x86_64 0:1.627-4.el7             perl-Data-Dumper.x86_64 0:2.145-3.el7
  perl-Encode.x86_64 0:2.51-7.el7                perl-Exporter.noarch 0:5.68-3.el7              perl-File-Path.noarch 0:2.09-2.el7                 perl-File-Temp.noarch 0:0.23.01-3.el7              perl-Filter.x86_64 0:1.49-3.el7           perl-Getopt-Long.noarch 0:2.40-3.el7
  perl-HTTP-Tiny.noarch 0:0.033-3.el7            perl-IO-Compress.noarch 0:2.061-2.el7          perl-Net-Daemon.noarch 0:0.48-5.el7                perl-PathTools.x86_64 0:3.40-5.el7                 perl-PlRPC.noarch 0:0.2020-14.el7         perl-Pod-Escapes.noarch 1:1.04-299.el7_9
  perl-Pod-Perldoc.noarch 0:3.20-4.el7           perl-Pod-Simple.noarch 1:3.28-4.el7            perl-Pod-Usage.noarch 0:1.63-3.el7                 perl-Scalar-List-Utils.x86_64 0:1.27-248.el7       perl-Socket.x86_64 0:2.010-5.el7          perl-Storable.x86_64 0:2.45-3.el7
  perl-Text-ParseWords.noarch 0:3.29-4.el7       perl-Time-HiRes.x86_64 4:1.9725-3.el7          perl-Time-Local.noarch 0:1.2300-2.el7              perl-constant.noarch 0:1.27-2.el7                  perl-libs.x86_64 4:5.16.3-299.el7_9       perl-macros.x86_64 4:5.16.3-299.el7_9
  perl-parent.noarch 1:0.225-244.el7             perl-podlators.noarch 0:2.5.1-3.el7            perl-threads.x86_64 0:1.87-4.el7                   perl-threads-shared.x86_64 0:1.43-6.el7            socat.x86_64 0:1.7.3.2-2.el7

Replaced:
  mariadb-libs.x86_64 1:5.5.68-1.el7

Complete!
```

### Start The MariaDB Server

Start the MariaDB server and excute `mariadb-secure-installation` script to perform base hardening of the server.

```
[server1 ~]# systemctl start mariadb

[server1 ~]# systemctl status mariadb
● mariadb.service - MariaDB 10.6.5-2 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Tue 2022-02-08 14:57:06 UTC; 6s ago
     Docs: man:mariadbd(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 32385 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 32326 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/..; /usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 32324 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 32373 (mariadbd)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─32373 /usr/sbin/mariadbd

Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 0 [Note] Plugin 'FEEDBACK' is disabled.
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 server_audit: MariaDB Audit Plugin version 2.4.1 STARTED.
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 server_audit: Query cache is enabled with the TABLE events. Some table reads can be veiled.
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 0 [Note] Server socket created on IP: '0.0.0.0'.
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 0 [Note] Server socket created on IP: '::'.
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 0 [Note] /usr/sbin/mariadbd: ready for connections.
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: Version: '10.6.5-2-MariaDB-enterprise'  socket: '/var/lib/mysql/mysql.sock'  port: 3306  MariaDB Enterprise Server
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal mariadbd[32373]: 2022-02-08 14:57:06 0 [Note] InnoDB: Buffer pool(s) load completed at 220208 14:57:06
Feb 08 14:57:06 ip-172-31-19-101.ap-southeast-1.compute.internal systemd[1]: Started MariaDB 10.6.5-2 database server.
```

#### Secure MariaDB

Once MariaDB has started successfully with the default config, execute the `mariadb-secure-installation` to secure the server (base hardening). Follow the prompts and answer "Y"

```
[root@ip-172-31-19-101 ~]# mariadb-secure-installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] Y
Enabled successfully!
Reloading privilege tables..
 ... Success!


You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] Y

New password: **********
Re-enter new password: **********
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] Y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

By now we had done the following

- `Switch to unix_socket authentication [Y]`
- `Change the root password? [Y]`
- `Remove anonymous users? [Y]`
- `Disallow root login remotely? [Y]`
- `Remove test database and access to it? [Y]`
- `Reload privilege tables now? [Y]`

#### Data Directory

We can now configure custom `datadir` for the MariaDB server, in this exercise we will be using `/mariadb/data/`.

Stop the MariaDB server, create the required path, copy all the contents from `/var/lib/mysql/*` to `/mariadb/data/` path and change the ownbership of `/mariadb` to `mysql:mysql` using the recursive flag `-R` 

```
[server1 ~]# systemctl stop mariadb
[server1 ~]# mkdir -p /mariadb/data
[server1 ~]# cp -r /var/lib/mysql/* /mariadb/data/
[server1 ~]# chown -R mysql:mysql /mariadb
```

Edit the /etc/my.cnf.d/server.cnf file and add the following parameters under the `[mariadb]` section.

`/etc/my.cnf.d/server.cnf`
```
[mariadb]
log_error=server.log
datadir=/mariadb/data
port=3306
lower_case_table_names=1

# How many connections are allowed at any given time?
max_connections=300

query_cache_type=0
query_cache_size=0

max_allowed_packet=1G

tmp_table_size=256M
max_heap_table_size=256M
innodb_log_file_size=1G
innodb_flush_method=O_DIRECT

# This should be configured to 70% of the total RAM in the server.
innodb_buffer_pool_size=???

# Depends on the number of tables in the database
innodb_open_files=1000

# ACID but this will slow down the TPS, can be commented out for better replication performance. 
innodb_flush_log_at_trx_commit=1
sync_binlog=1
sync_master_info=1
sync_relay_log=1
sync_relay_log_info=1
# ACID Config Ends

# Replication
binlog_format=ROW
gtid_strict_mode=ON
log_slave_updates=ON
log_bin=mariadb-bin
log_bin_index=mariadb-bin.index
relay_log=relay-bin
relay_log_index=relay-bin.index
relay_log_info_file=relay-bin.info
server_id=1000
gtid_domain_id=1
shutdown_wait_for_slaves=ON
expire_logs_days=7
session_track_system_variables=last_gtid
# Replication Setup Ends

# Semi-Sync Replication
rpl_semi_sync_master_enabled=ON
rpl_semi_sync_slave_enabled=ON
rpl_semi_sync_master_wait_point=AFTER_SYNC
rpl_semi_sync_master_timeout=10000
# Semi-Sync replicaiton Ends

bind_address = 0.0.0.0

[mysql]
prompt=\H [\d]>\_
```

***Note:** Remember to configure **`innodb_buffer_pool_size`** based on 70% of your server's RAM*

If TPS is critical then set the `sync` variables to ZERO and innodb_flush_log_at_trx_commit=2, this will improve the transaction throughput and replication speeds but at the cost of durability.

```
innodb_flush_log_at_trx_commit=2
sync_binlog=0
sync_master_info=0
sync_relay_log=0
sync_relay_log_info=0
```

For the Slave, all of the above applies, simply change the `server_id` and `gtid_domain_id`

```
server_id=2000
gtid_domain_id=2
```

Other specific configuration if needed, like, password complexity and auditing, refer to the following

- Simple Password Check Plugin
  - <https://mariadb.com/kb/en/simple-password-check-plugin/>
- Enterprise Audit
  - <https://mariadb.com/products/skysql/docs/security/enterprise-audit/#enabling-enterprise-audit>

Once all the required configurations are done, restart both of the MariaDB servers to enable binary logs and other configurations set.

#### User Setup

##### MariaDB Backup User

Create a user with grants to execute MariaDB Backup on the server.

The following user creation is to be done only on the Master node.

```sql
CREATE USER 'mariabackup'@'localhost' IDENTIFIED BY 'mypassword';
GRANT RELOAD, PROCESS, LOCK TABLES, BINLOG MONITOR ON *.* TO 'mariabackup'@'localhost';
```

##### MariaDB Replication User

Create a user with grants to be able to replicate the database from Master to Slave

The following user creation is to be done only on the Master node.

```sql
CREATE USER 'rep_user'@'%' IDENTIFIED BY 'mypassword';
GRANT REPLICATION MASTER ADMIN, REPLICATION SLAVE ADMIN, REPLICATION SLAVE, SLAVE MONITOR ON *.* TO 'rep_user'@'%';
```

##### MariaDB MaxScale Monitor/Router Users

Following two users are needed for MariaDB MaxScale to monitor/handle replication/failover and also do query routing/load balancing

```sql
CREATE USER 'maxmon'@'<maxscale-host-ip>' IDENTIFIED BY 'mypassword';
GRANT SUPER, RELOAD, PROCESS, SHOW DATABASES, EVENT, REPLICATION SLAVE ADMIN ON *.* TO 'maxmon'@'<maxscale-host-ip>';

CREATE USER 'maxuser'@'<maxscale-host-ip>' IDENTIFIED BY 'mypassword';
GRANT SHOW DATABASES ON *.* TO 'maxuser'@'<maxscale-host-ip>';
GRANT SELECT ON mysql.* TO 'maxuser'@'<maxscale-host-ip>';
```

***Note:** Use a secure password, the avove password `mypassword` is just for reference*

Once the above is done, we can verify the users are created by the following SQL.

```
MariaDB [(none)]> select user,host from mysql.user;
+-------------+---------------+
| User        | Host          |
+-------------+---------------+
| rep_user    | %             |
| maxmon      | 172.31.22.229 |
| maxuser     | 172.31.22.229 |
| mariabackup | localhost     |
| mariadb.sys | localhost     |
| mysql       | localhost     |
| root        | localhost     |
+-------------+---------------+
```

***Note:** for this exercise the `maxmon` and `maxuser` were created with `'%'` as host to keep it simple.*

### Replicaiton

Now that all the required users have been created on Master node, we can proceed with setting up the replicaiton. Once the replication has started successfully, all the created users will automatically replicate and sync with the slave node.

To setup the slave node, we shouldd have already Installed MariaDB and all the `server.cnf` file configuration should be already in. 

Take note of the Master server's IP address as we will need it when setting up the slave.

We will execute the following command to set the replicaiton

```sql
SET GLOBAL GTID_SLAVE_POS='';

CHANGE MASTER TO
  MASTER_HOST='<master-ip-adddress>',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='mypassword',
  MASTER_PORT=3306,
  MASTER_USE_GTID=slave_pos,
  MASTER_CONNECT_RETRY=10;

START SLAVE;

SHOW SLAVE STATUS\G
```

The `SHOW SLAVE STATUS\G` should give something like the following output

```
`[(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 172.31.19.101
                   Master_User: rep_user
                   Master_Port: 3306
                 Connect_Retry: 10
               Master_Log_File: mariadb-bin.000001
           Read_Master_Log_Pos: 2224
                Relay_Log_File: relay-bin.000002
                 Relay_Log_Pos: 2525
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
           Exec_Master_Log_Pos: 2224
               Relay_Log_Space: 2828
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
                   Gtid_IO_Pos: 1-1000-11
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
              Slave_DDL_Groups: 11
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.000 sec)
```

Here important factors are the following

```
Using_Gtid: Slave_Pos
Gtid_IO_Pos: 1-1000-11
```

This tells that 11 GTIDs have been pulled from the Master, those will include the varius CREATE USER and GRANT statements.

And the following two

```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

Thesse two should always be "Yes" which means replication is healthy and running.

To verify, we can execute the following on the slave node and confirm the new users are available through replicaiton.

```
MariaDB [(none)]> select user,host from mysql.user;
+-------------+---------------+
| User        | Host          |
+-------------+---------------+
| rep_user    | %             |
| maxmon      | 172.31.22.229 |
| maxuser     | 172.31.22.229 |
| mariabackup | localhost     |
| mariadb.sys | localhost     |
| mysql       | localhost     |
| root        | localhost     |
+-------------+---------------+
```

### MaxScale

Install MaxScale using `yum install` or `rpm -ivh` method with the downloaded MaxScale RPM file

```
[maxscale tmp]# yum install maxscale-6.2.1-1.rhel.7.x86_64.rpm
Resolving Dependencies
--> Running transaction check

Dependencies Resolved

==============================================================================================================================================================================================================================================================================================
 Package                                                        Arch                                                        Version                                                                Repository                                                                            Size
==============================================================================================================================================================================================================================================================================================
Installing:
 maxscale                                                       x86_64                                                      6.2.1-1.rhel.7                                                         /maxscale-6.2.1-1.rhel.7.x86_64                                                      241 M
Installing for dependencies:
 gnutls                                                         x86_64                                                      3.3.29-9.el7_6                                                         rhel-7-server-rhui-rpms                                                              681 k
 libatomic                                                      x86_64                                                      4.8.5-44.el7                                                           rhel-7-server-rhui-rpms                                                               51 k
 nettle                                                         x86_64                                                      2.7.1-9.el7_9                                                          rhel-7-server-rhui-rpms                                                              328 k
 trousers                                                       x86_64                                                      0.3.14-2.el7                                                           rhel-7-server-rhui-rpms                                                              289 k

Installed:
  maxscale.x86_64 0:6.2.1-1.rhel.7

Dependency Installed:
  gnutls.x86_64 0:3.3.29-9.el7_6                                         libatomic.x86_64 0:4.8.5-44.el7                                         nettle.x86_64 0:2.7.1-9.el7_9                                         trousers.x86_64 0:0.3.14-2.el7

Complete!
```

Edit the /etc/maxscale.cnf and remove all the contents, replace with the following block

`/etc/maxscale.cnf`
```
[maxscale]
threads=auto
log_info=false

## Servers
[Server-1]
type=server
address=<Server1-IP>
port=3306
protocol=MariaDBBackend

[Server-2]
type=server
address=<Server1-IP>
port=3306
protocol=MariaDBBackend

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=Server-1, Server-2

user=maxmon
password=mypassword
replication_user=rep_user
replication_password=mypassword

monitor_interval=1500
failcount=5
failover_timeout=120s
switchover_timeout=120s
verify_master_failure=true
master_failure_timeout=30s
enforce_read_only_slaves=true

auto_failover=true
auto_rejoin=true

cooperative_monitoring_locks=majority_of_running

## This is the read-write-split-service
[Read-Write-Service]
type=service
router=readwritesplit
servers=Server-1, Server-2
master_accept_reads=true

user=maxuser
password=mypassword

master_reconnection=true
transaction_replay=true
slave_selection_criteria=ADAPTIVE_ROUTING
causal_reads=true

## Listener to the Read-Write-Service
[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=4009
address=0.0.0.0
```

Change the Listener port from 4009 to whatever is required and open up firewalls accordingly.

Change the passwords withn the maxscale.cnf file based on the user creation earlier. Encrypt the password within MaxScale, refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-encrypting-passwords/>

Restart the MaxScale service by `systemctl restart maxscale` in case of any errors or failure, refer to `/var/lob/maxscale/maxscale.log` file for details.

Check the MariaDB cluster through MaxScale GUI throgh `maxctrl list servers`

```
[maxscale ~]# maxctrl list servers
┌──────────┬───────────────┬──────┬─────────────┬─────────────────┬───────────┐
│ Server   │ Address       │ Port │ Connections │ State           │ GTID      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────┼───────────┤
│ Server-1 │ 172.31.19.101 │ 3306 │ 0           │ Master, Running │ 1-1000-21 │
├──────────┼───────────────┼──────┼─────────────┼─────────────────┼───────────┤
│ Server-2 │ 172.31.17.224 │ 3306 │ 0           │ Slave, Running  │ 1-1000-21 │
└──────────┴───────────────┴──────┴─────────────┴─────────────────┴───────────┘

[maxscale ~]# maxctrl list monitors
┌─────────────────┬─────────┬────────────────────┐
│ Monitor         │ State   │ Servers            │
├─────────────────┼─────────┼────────────────────┤
│ MariaDB-Monitor │ Running │ Server-1, Server-2 │
└─────────────────┴─────────┴────────────────────┘

[maxscale ~]# maxctrl list services
┌────────────────────┬────────────────┬─────────────┬───────────────────┬────────────────────┐
│ Service            │ Router         │ Connections │ Total Connections │ Servers            │
├────────────────────┼────────────────┼─────────────┼───────────────────┼────────────────────┤
│ Read-Write-Service │ readwritesplit │ 0           │ 0                 │ Server-1, Server-2 │
└────────────────────┴────────────────┴─────────────┴───────────────────┴────────────────────┘
```

I highly recommend enabling MaxScale GUI, refer to this detailed guide on how to securely enable MaxGUI for a rich GUI to monitor MaxScale and backend databases and replication status.

Enable MaxSclae GUI, refer to the <https://mariadb.com/resources/blog/getting-started-with-the-mariadb-maxscale-gui/#:~:text=MariaDB%20MaxScale%20is%20an%20advanced,user%20interface%20for%20managing%20MaxScale.>

From this point onwards, clients must should connect to MaxScale IP/PORT to access the database cluster. 

Thank you!
