# Upgrade to MariaDB Enterprise

## Install MariaDB 10.4.13 Community

Download the binaries from <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/centos74-amd64/rpms/>

Currently the Latest Community version is 10.4.14 while the Enterprise version is at 10.4.13, make sure to download the following RPM files for the 10.4.13 and not the 10.4.14.

Files to download from the above URL are:

- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/centos74-amd64/rpms/MariaDB-backup-10.4.13-1.el7.centos.x86_64.rpm>
- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/centos74-amd64/rpms/MariaDB-client-10.4.13-1.el7.centos.x86_64.rpm>
- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/rhel74-amd64/rpms/MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm>
- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/rhel74-amd64/rpms/MariaDB-compat-10.4.13-1.el7.centos.x86_64.rpm>
- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/rhel74-amd64/rpms/MariaDB-rocksdb-engine-10.4.13-1.el7.centos.x86_64.rpm>
- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/rhel74-amd64/rpms/MariaDB-shared-10.4.13-1.el7.centos.x86_64.rpm>
- <https://downloads.mariadb.com/MariaDB/mariadb-10.4.13/yum/rhel74-amd64/rpms/galera-4-26.4.4-1.rhel7.el7.centos.x86_64.rpm>

File listing should be the following, take note the versions for RHEL 7 are also named as `centos.x86_64`

```txt
➜  ls -rlt
total 413008
-rw-r--r-- 1 root root    115668 May 11 18:16 MariaDB-shared-10.4.13-1.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root   6798244 Aug 20 07:21 MariaDB-backup-10.4.13-1.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root  12338948 Aug 20 07:21 MariaDB-client-10.4.13-1.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root     82500 Aug 20 07:21 MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root   2257084 Aug 20 07:21 MariaDB-compat-10.4.13-1.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root  26939944 Aug 20 07:21 MariaDB-server-10.4.13-1.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root   9985628 Feb 20 16:05 galera-4-26.4.4-1.rhel7.el7.centos.x86_64.rpm
-rw-r--r-- 1 root root   5377432 Aug 20 07:21 MariaDB-rocksdb-engine-10.4.13-1.el7.centos.x86_64.rpm
```

Remove the old `mariadb-libs` from the server

```txt
➜  yum -y remove mariadb-libs
Loaded plugins: fastestmirror
Resolving Dependencies
--> Running transaction check
---> Package mariadb-libs.x86_64 1:5.5.65-1.el7 will be erased
--> Processing Dependency: libmysqlclient.so.18()(64bit) for package: 2:postfix-2.10.1-9.el7.x86_64
--> Processing Dependency: libmysqlclient.so.18(libmysqlclient_18)(64bit) for package: 2:postfix-2.10.1-9.el7.x86_64
--> Running transaction check
---> Package postfix.x86_64 2:2.10.1-9.el7 will be erased
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================================================================================================================================================================================================================= Package                                                              Arch                                                           Version                                                                 Repository                                                     Size =================================================================================================================================================================================================================================================================================Removing:
 mariadb-libs                                                         x86_64                                                         1:5.5.65-1.el7                                                          @base                                                         4.4 M Removing for dependencies:
 postfix                                                              x86_64                                                         2:2.10.1-9.el7                                                          @base                                                          12 M

Transaction Summary
=================================================================================================================================================================================================================================================================================Remove  1 Package (+1 Dependent package)

Installed size: 17 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Erasing    : 2:postfix-2.10.1-9.el7.x86_64                                                                                                                                                                                                                                 1/2
  Erasing    : 1:mariadb-libs-5.5.65-1.el7.x86_64                                                                                                                                                                                                                            2/2
  Verifying  : 1:mariadb-libs-5.5.65-1.el7.x86_64                                                                                                                                                                                                                            1/2
  Verifying  : 2:postfix-2.10.1-9.el7.x86_64                                                                                                                                                                                                                                 2/2

Removed:
  mariadb-libs.x86_64 1:5.5.65-1.el7

Dependency Removed:
  postfix.x86_64 2:2.10.1-9.el7

Complete!
```

Install the Common and Compact using `rpm -ivh` as a single install, all the others can be installed as per normal using `yum -y install`

```txt
➜  rpm -ivh MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm MariaDB-compat-10.4.13-1.el7.centos.x86_64.rpm
warning: MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 1bb943db: NOKEY
Preparing...                          ################################# [100%]
Updating / installing...
   1:MariaDB-compat-10.4.13-1.el7.cent################################# [ 50%]
   2:MariaDB-common-10.4.13-1.el7.cent################################# [100%]
```

Install the remaining in the following order

- `yum -y install MariaDB-backup-10.4.13-1.el7.centos.x86_64.rpm`
- `yum -y install MariaDB-shared-10.4.13-1.el7.centos.x86_64.rpm`
- `yum -y install MariaDB-client-10.4.13-1.el7.centos.x86_64.rpm`
- `yum -y install MariaDB-rocksdb-engine-10.4.13-1.el7.centos.x86_64.rpm`
- `yum -y install galera-4-26.4.4-1.rhel7.el7.centos.x86_64.rpm`
- `yum -y install MariaDB-server-10.4.13-1.el7.centos.x86_64.rpm`

Buy the end, we should have the following output

```txt
➜  rpm -qa | grep -i mariadb
MariaDB-common-10.4.13-1.el7.centos.x86_64
MariaDB-server-10.4.13-1.el7.centos.x86_64
MariaDB-compat-10.4.13-1.el7.centos.x86_64
MariaDB-rocksdb-engine-10.4.13-1.el7.centos.x86_64
MariaDB-backup-10.4.13-1.el7.centos.x86_64
MariaDB-client-10.4.13-1.el7.centos.x86_64
MariaDB-shared-10.4.13-1.el7.centos.x86_64

➜  rpm -qa | grep -i galera
galera-4-26.4.4-1.rhel7.el7.centos.x86_64
```

Start MariaDB service and verify that RocksDB engine is already available

```txt
➜  systemctl start mariadb
➜  mariadb
MariaDB [(none)]> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| ROCKSDB            | YES     | RocksDB storage engine                                                                          | YES          | YES  | YES        |
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

RocksDB engine is available, now execute `mariadb-secure-installation` to secure the server before proceeding further

```txt
➜  mariadb-secure-installation

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
New password:
Re-enter new password:
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

Take note, that we can set MariaDB `root` user password and still use unix_socket to authenticate as done above during the `mariadb-secure-installation` process.

Let's create RocksDB tables with some data and then perform the `mariadb-upgrade` to 10.4.13 Enterprise version.

```txt
➜  mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 20
Server version: 10.4.13-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database testdb;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> use testdb;
Database changed
MariaDB [testdb]> create table tab_r(id serial, c1 varchar(100), c2 timestamp(6)) engine=RocksDB;
Query OK, 0 rows affected (0.011 sec)

MariaDB [testdb]> create table tab_i(id serial, c1 varchar(100), c2 timestamp(6)) engine=InnoDB;
Query OK, 0 rows affected (0.012 sec)

MariaDB [testdb]> insert into tab_i(c1) select column_name from information_schema.columns;
Query OK, 1928 rows affected (0.025 sec)
Records: 1928  Duplicates: 0  Warnings: 0

MariaDB [testdb]> insert into tab_r(c1) select column_name from information_schema.columns;
Query OK, 1928 rows affected (0.016 sec)
Records: 1928  Duplicates: 0  Warnings: 0

MariaDB [testdb]> select count(*) from tab_r inner join tab_i on tab_r.id = tab_i.id;
+----------+
| count(*) |
+----------+
|     1928 |
+----------+
1 row in set (0.003 sec)
```

Looking at the data directory `/var/lib/mysql` 

```
➜  cd /var/lib/mysql
➜  mysql ls -rlt
total 122944
-rw-rw---- 1 mysql mysql 50331648 Aug 20 07:43 ib_logfile1
drwx------ 2 mysql mysql     4096 Aug 20 07:43 mysql
drwx------ 2 mysql mysql       20 Aug 20 07:43 performance_schema
-rw-rw---- 1 mysql mysql      972 Aug 20 07:43 ib_buffer_pool
-rw-rw---- 1 mysql mysql       52 Aug 20 07:43 aria_log_control
drwxr-x--x 2 mysql mysql      168 Aug 20 07:46 #rocksdb
-rw-rw---- 1 mysql mysql    24576 Aug 20 07:46 tc.log
srwxrwxrwx 1 mysql mysql        0 Aug 20 07:46 mysql.sock
-rw-rw---- 1 mysql mysql        6 Aug 20 07:46 ge-101.pid
-rw-rw---- 1 mysql mysql        0 Aug 20 07:46 multi-master.info
-rw-rw---- 1 mysql mysql 12582912 Aug 20 07:46 ibtmp1
-rw-rw---- 1 mysql mysql    24576 Aug 20 07:50 aria_log.00000001
drwx------ 2 mysql mysql       71 Aug 20 07:53 testdb
-rw-rw---- 1 mysql mysql 12582912 Aug 20 07:54 ibdata1
-rw-rw---- 1 mysql mysql 50331648 Aug 20 07:54 ib_logfile0
```

## Install MariaDB 10.4.13 Enterprise

We need to go through the following steps in order to upgrade from the 10.4.13 Community -> 10.4.13 Enterprise, the same steps are valid from all version upgrades

- Stop MariaDB service `systemctl stop mariadb`
- Remove the current MariaDB binaries `yum remove`
- Install the the new binaries
- Start MariaDB service `systemctl start mariadb`
- execute `mariadb-upgrade` 

Let's see the above in action, assuming the MariaDB 10.4.13 enterprise server tar file is already downloaded to the server.

Untar the downloaded MariaDB Enterprise rpm package.

```txt
➜  tar -xvf mariadb-enterprise-10.4.13-7-centos-7-x86_64-rpms.tar
```

Stop MariaDB service and remove MariaDB Community

- `cp /etc/my.cnf.d/server.cnf /tmp/server.cnf`
  - Take a backup of the existing MariaDB configuration
- `systemctl stop mariadb`
- `yum -y remove MariaDB-server`
- `yum -y remove MariaDB-common`
- `yum -y remove galera-4-26.4.4-1.rhel7.el7.centos.x86_64`

The above should remove MariaDB Community version from the server.

Verify there are no more MariaDB binaries installed, both of the following should not return anything.

```
➜  rpm -qa | grep -i mariadb

➜  rpm -qa | grep -i galera
```

change directory into the untar'ed folder of the MariaDB enterprise and install the binaries as done during the Community installation.

```
➜  rpm -ivh MariaDB-common-10.4.13_7-1.el7.x86_64.rpm MariaDB-compat-10.4.13_7-1.el7.x86_64.rpm
warning: MariaDB-common-10.4.13_7-1.el7.x86_64.rpm: Header V4 RSA/SHA512 Signature, key ID e3c94f49: NOKEY
Preparing...                          ################################# [100%]
Updating / installing...
   1:MariaDB-compat-10.4.13_7-1.el7   ################################# [ 50%]
   2:MariaDB-common-10.4.13_7-1.el7   ################################# [100%]
```

Followed by yum -y install of the remaining rpm files.

- `yum -y install mariadb-enterprise-10.4.13-7-centos-7-x86_64-rpms`
- `yum -y install MariaDB-shared-10.4.13_7-1.el7.x86_64.rpm`
- `yum -y install MariaDB-client-10.4.13_7-1.el7.x86_64.rpm`
- `yum -y install MariaDB-backup-10.4.13_7-1.el7.x86_64.rpm`
- `yum -y install MariaDB-rocksdb-engine-10.4.13_7-1.el7.x86_64.rpm`
- `yum -y install galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm`
- `yum -y install MariaDB-server-10.4.13_7-1.el7.x86_64.rpm`

Verify the installation, using `rpm -qa`

```txt
➜  rpm -qa | grep -i mariadb
MariaDB-compat-10.4.13_7-1.el7.x86_64
MariaDB-server-10.4.13_7-1.el7.x86_64
MariaDB-common-10.4.13_7-1.el7.x86_64
MariaDB-rocksdb-engine-10.4.13_7-1.el7.x86_64
MariaDB-backup-10.4.13_7-1.el7.x86_64
MariaDB-client-10.4.13_7-1.el7.x86_64
MariaDB-shared-10.4.13_7-1.el7.x86_64
➜  rpm -qa | grep galera
galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64
```

Finally copy the `server.cnf` file from `/tmp to` to `/etc/my.cnf.d`, you would also notice there is a `rocksdb.cnf` file created under `/etc/my.cnf.d` folder, this contains the `plugin-load-add=ha_rocksdb.so` statement, you can leave it there or move it to server.cnf file along with the remaining RocksDB specific configuration

### Upgrade to Enterprise

Start the MariaDB server using the enterprise binaries

```
➜  systemctl start mariadb
➜  mariadb-upgrade
Phase 1/7: Checking and upgrading mysql database
Processing databases
mysql
mysql.column_stats                                 OK
mysql.columns_priv                                 OK
mysql.db                                           OK
mysql.event                                        OK
mysql.func                                         OK
mysql.global_priv                                  OK
mysql.gtid_slave_pos                               OK
mysql.help_category                                OK
mysql.help_keyword                                 OK
mysql.help_relation                                OK
mysql.help_topic                                   OK
mysql.index_stats                                  OK
mysql.innodb_index_stats                           OK
mysql.innodb_table_stats                           OK
mysql.plugin                                       OK
mysql.proc                                         OK
mysql.procs_priv                                   OK
mysql.proxies_priv                                 OK
mysql.roles_mapping                                OK
mysql.servers                                      OK
mysql.table_stats                                  OK
mysql.tables_priv                                  OK
mysql.time_zone                                    OK
mysql.time_zone_leap_second                        OK
mysql.time_zone_name                               OK
mysql.time_zone_transition                         OK
mysql.time_zone_transition_type                    OK
mysql.transaction_registry                         OK
Phase 2/7: Installing used storage engines... Skipped
Phase 3/7: Fixing views
mysql.user                                         OK
Phase 4/7: Running 'mysql_fix_privilege_tables'
Phase 5/7: Fixing table and database names
Phase 6/7: Checking and upgrading tables
Processing databases
information_schema
performance_schema
testdb
testdb.tab_i                                       OK
testdb.tab_r                                       OK
Phase 7/7: Running 'FLUSH PRIVILEGES'
OK
```

That is all there is to upgrading from community to enterprise version, just like any other version upgrade. We can see the tables under the `testdb` database were also upgraded without problems.

Let's verify

```
➜  mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 22
Server version: 10.4.13-7-MariaDB-enterprise MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> use testdb;
Database changed

MariaDB [testdb]> select version();
+------------------------------+
| version()                    |
+------------------------------+
| 10.4.13-7-MariaDB-enterprise |
+------------------------------+
1 row in set (0.000 sec)

MariaDB [testdb]> show tables;
+------------------+
| Tables_in_testdb |
+------------------+
| tab_i            |
| tab_r            |
+------------------+
2 rows in set (0.000 sec)

MariaDB [testdb]> show create table tab_r\G
*************************** 1. row ***************************
       Table: tab_r
Create Table: CREATE TABLE `tab_r` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `c1` varchar(100) DEFAULT NULL,
  `c2` timestamp(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  UNIQUE KEY `id` (`id`)
) ENGINE=ROCKSDB AUTO_INCREMENT=1929 DEFAULT CHARSET=latin1
1 row in set (0.000 sec)

MariaDB [testdb]>
MariaDB [testdb]> select count(*) from tab_r inner join tab_i on tab_r.id = tab_i.id;
+----------+
| count(*) |
+----------+
|     1928 |
+----------+
1 row in set (0.005 sec)
```

Everything works as it should, upgrade is successful.
