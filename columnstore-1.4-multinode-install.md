# ColumnStore 1.4 Multinode Installation

This guide will guide us on installing and configuring ColumnStore 1.4 using the MariaDB 10.4 Enterprise Server. 

## Assumptions

- OS `root` user is used to install and configure the MariaDB Platform X4 (MariaDB Server 10.4 & ColumnStore 1.4)

- The password for the `root` user is kept identical for both nodes. This is a **temporary** requirement and needed only for the `postConfigure` script.
  - After the installation, passwords for the `root` user on both nodes can be changed back to normal.
- `/etc/sudoers` file is modified to grant START/STOP/RESTART of the ColunmnStore & MariaDB services to the non-root user

## Dependencies

There are some dependencies that need to be fulfilled before proceeding with the isntallation.

Perform the following on both of the nodes 

```
[root@cs-61 ~]# localedef -i en_US -f UTF-8 en_US.UTF-8

[root@cs-61 ~]# export LC_ALL=C

[root@cs-61 ~]# yum -y install epel-release

[root@cs-61 ~]# yum -y install boost expect perl perl-DBI openssl zlib file sudo libaio rsync snappy net-tools numactl-libs nmap jemalloc
```

Once dependencies are installed, download and untar the MariaDB 10.4 enterprise server all the servers.

The extracted TAR file will have the following listing on both nodes.

```
[root@cs-61 mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# ls -rlt
total 346848
-rw-rw-r-- 1 mariadbadm mariadbadm  4872416 Mar  1 20:20 MariaDB-test-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 31744156 Mar  1 20:20 MariaDB-test-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm   430096 Mar  1 20:20 MariaDB-shared-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm   115316 Mar  1 20:20 MariaDB-shared-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 62938388 Mar  1 20:20 MariaDB-server-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 22494404 Mar  1 20:20 MariaDB-server-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 63335528 Mar  1 20:20 MariaDB-rocksdb-engine-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  4963772 Mar  1 20:20 MariaDB-rocksdb-engine-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  1426892 Mar  1 20:20 MariaDB-oqgraph-engine-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm    71456 Mar  1 20:20 MariaDB-oqgraph-engine-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm    31528 Mar  1 20:20 MariaDB-gssapi-server-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm    10288 Mar  1 20:20 MariaDB-gssapi-server-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm     8840 Mar  1 20:20 MariaDB-devel-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  1255648 Mar  1 20:20 MariaDB-devel-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm    19752 Mar  1 20:20 MariaDB-cracklib-password-check-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm     7416 Mar  1 20:20 MariaDB-cracklib-password-check-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  2987012 Mar  1 20:20 MariaDB-connect-engine-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm   484564 Mar  1 20:20 MariaDB-connect-engine-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  2257484 Mar  1 20:20 MariaDB-compat-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm   185424 Mar  1 20:20 MariaDB-common-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm    83892 Mar  1 20:20 MariaDB-common-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 27198748 Mar  1 20:20 MariaDB-columnstore-platform-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  2766012 Mar  1 20:20 MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 39623420 Mar  1 20:20 MariaDB-columnstore-libs-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  3578216 Mar  1 20:20 MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  7449180 Mar  1 20:20 MariaDB-columnstore-engine-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm   464300 Mar  1 20:20 MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  8458444 Mar  1 20:20 MariaDB-client-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  6679248 Mar  1 20:20 MariaDB-client-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 41826988 Mar  1 20:20 MariaDB-backup-debuginfo-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm  6930324 Mar  1 20:20 MariaDB-backup-10.4.12_6-1.el7.x86_64.rpm
-rw-rw-r-- 1 mariadbadm mariadbadm 10391620 Mar  1 20:20 galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm
-rwxrwxr-x 1 mariadbadm mariadbadm     1012 Mar  1 20:20 setup_repository
drwxrwxr-x 2 mariadbadm mariadbadm     4096 Mar  1 20:20 repodata
-rw-rw-r-- 1 mariadbadm mariadbadm     1794 Mar  1 20:20 README
```

The tar will contain all the required tar files that are needed to be installed. The method is the standard server install procedure.

### Installation

Install the RPM files on both of the nodes as `root` user.

- `rpm -ivh galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm`
- `rpm -ivh MariaDB-compat-10.4.12_6-1.el7.x86_64.rpm MariaDB-common-10.4.12_6-1.el7.x86_64.rpm`
  - These two are to be installed together thrugh a single `rpm -ivh` command.
- `rpm -ivh MariaDB-shared-10.4.12_6-1.el7.x86_64.rpm`
- `rpm -ivh MariaDB-client-10.4.12_6-1.el7.x86_64.rpm`
- `rpm -ivh MariaDB-server-10.4.12_6-1.el7.x86_64.rpm`

Once these 6 rpm files have been install on all the nodes, the following 3 additional rpm files needs to be installed as well on all the nodes.

- **mariadb-columnstore-libs**
  - `rpm -ivh MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm`
- **mariadb-columnstore-platform**
  - `rpm -ivh MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm`
- **mariadb-columnstore-engine**
  - `rpm -ivh MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm`

### Create the `mcsadm` User

Create a user as `mcsadm` and setup `/etc/sudoers` file so that the user can manage ColumnStore services.

```txt
[root@localhost ~] groupadd mcsadm
[root@localhost ~] useradd -g mcsadm mcsadm

[root@localhost ~] passwd mcsadm
Changing password for user mcsadm.
New password: **********
Retype new password: **********
passwd: all authentication tokens updated successfully.
```

There is no need to setup the SSH for the `mcsadm` user.



### postConfigure

Stop MariaDB server on both nodes and proceed

```txt
[root@cs-61 ~]# systemctl stop mariadb.service
```

Execute the post install script on both the nodes

```txt
[root@cs-61 ~]# export LC_ALL=C
[root@cs-61 ~]# columnstore-post-install
The next step on the node that will become PM1:

postConfigure


```

Now we are ready to configure S3 storage followed by `postConfigure` script execution wihch will actually install ColumnStore and connect to S3 storage.

#### Configure S3 Storage

Make sure to have an S3/ObjectStore storage bucket ready with and firewall has been opened to access the end point. Following S3 related information is required before proceeding

- S3 Bucket Name `bucket`
- S3 End Point URL `endpoint`
- AWS Access Key ID `aws_access_key_id`
- AWS Secret Access Key `aws_secret_access_key`

Edit the **`/etc/columnstore/storagemanager.cnf`** file and modify the following variable under the **`[ObjectStorage]`** section, this will tell ColumnStore to use S3 as the default storage manager.

- `service = LocalStorage` should be changed to 
  - `service = S3`

Refer to the **`[S3]`** section in the `storagemanager.cnf` file and define the S3 related configrations

- `region = some_region` shuld be changed to empty since it's a local S3 storage setup
  - `region =` and regions are not available.
- `bucket = some_bucket` should be changed to the actual bucket name.
- `endpoint = storage.googleapis.com` should point to the S3 URL within DBS.
- `aws_access_key_id =` should point to the access key provided by the S3 storage team.
- `aws_secret_access_key =` should point to the "secret" access key provided by the S3 storage team.

Once the above are configured and saved we can now execute `postConfigure` script.

During the postConfigure setup, storage config will be done

```txt
Columnstore supports the following storage options...
  1 - internal.  This uses the linux VFS to access files and does
      not manage the filesystem.
  2 - external *.  If you have other mountable filesystems you would
      like ColumnStore to use & manage, select this option.
  3 - GlusterFS *  Note: glusterd service must be running and enabled on
      all PMs.
  4 - S3-compatible cloud storage *.  Note: that should be configured
      before running postConfigure (see storagemanager.cnf)
  * - This option enables data replication and server failover in a
      multi-node configuration.
```

Here **4** is a new option added to let ColumnStore use the S3 configuration defined earlier. 

Execute the `postConfigure` script on the Primary node. This will take you through a set of inputs, including the one mentioned above regarding the storage setup.

***Note:** When prompted for **"Enter password, hit 'enter' to default to using an ssh key, or 'exit' >"**, key in the OS `root` password, the password is asumed to be the same for both servers.*

```txt
[root@cs-61 ~]# postConfigure


This is the MariaDB ColumnStore System Configuration and Installation tool.
It will Configure the MariaDB ColumnStore System and will perform a Package
Installation of all of the Servers within the System that is being configured.

IMPORTANT: This tool requires to run on the Performance Module #1

Prompting instructions:

	Press 'enter' to accept a value in (), if available or
	Enter one of the options within [], if available, or
	Enter a new value


===== Setup System Server Type Configuration =====

There are 2 options when configuring the System Server Type: single and multi

  'single'  - Single-Server install is used when there will only be 1 server configured
              on the system. It can also be used for production systems, if the plan is
              to stay single-server.

  'multi'   - Multi-Server install is used when you want to configure multiple servers now or
              in the future. With Multi-Server install, you can still configure just 1 server
              now and add on addition servers/modules in the future.

Select the type of System Server install [1=single, 2=multi] (2) > 2


===== Setup System Module Type Configuration =====

There are 2 options when configuring the System Module Type: separate and combined

  'separate' - User and Performance functionality on separate servers.

  'combined' - User and Performance functionality on the same server

Select the type of System Module Install [1=separate, 2=combined] (2) > 2

Combined Server Installation will be performed.
The Server will be configured as a Performance Module.
All MariaDB ColumnStore Processes will run on the Performance Modules.

NOTE: The MariaDB ColumnStore Schema Sync feature will replicate all of the
      schemas and InnoDB tables across the User Module nodes. This feature can be enabled
      or disabled, for example, if you wish to configure your own replication post installation.

MariaDB ColumnStore Schema Sync feature is Enabled, do you want to leave enabled? [y,n] (y) > y


NOTE: MariaDB ColumnStore Replication Feature is enabled

Enter System Name (columnstore-1) > 


===== Setup Storage Configuration =====


----- Setup Performance Module DBRoot Data Storage Mount Configuration -----

Columnstore supports the following storage options...
  1 - internal.  This uses the linux VFS to access files and does
      not manage the filesystem.
  2 - external *.  If you have other mountable filesystems you would
      like ColumnStore to use & manage, select this option.
  3 - GlusterFS *  Note: glusterd service must be running and enabled on
      all PMs.
  4 - S3-compatible cloud storage *.  Note: that should be configured
      before running postConfigure (see storagemanager.cnf)
  * - This option enables data replication and server failover in a
      multi-node configuration.

These options are available on this system: [1, 2, 4]
Select the type of data storage (1) > 4

===== Setup Memory Configuration =====


NOTE: Setting 'NumBlocksPct' to 50%
      Setting 'TotalUmMemory' to 25%


===== Setup the Module Configuration =====


----- Performance Module Configuration -----

Enter number of Performance Modules [1,1024] (2) > 2

*** Parent OAM Module Performance Module #1 Configuration ***

Enter Nic Interface #1 Host Name (cs-61) > cs-61
Enter Nic Interface #1 IP Address or hostname of cs-61 (192.168.56.61) > 192.168.56.61
Enter Nic Interface #2 Host Name (unassigned) > 
Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm1' (1) > 1

*** Performance Module #2 Configuration ***

Enter Nic Interface #1 Host Name (cs-62) > cs-62
Enter Nic Interface #1 IP Address or hostname of cs-62 (192.168.56.62) > 192.168.56.62
Enter Nic Interface #2 Host Name (unassigned) > 
Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm2' (2) > 2

===== Running the MariaDB ColumnStore MariaDB Server setup scripts =====

post-mysqld-install Successfully Completed
post-mysql-install Successfully Completed

Next step is to enter the password to access the other Servers.
This is either user password or you can default to using an ssh key
If using a user password, the password needs to be the same on all Servers.

Enter password, hit 'enter' to default to using an ssh key, or 'exit' > **********
Confirm password > **********

----- Performing Install on 'pm2 / cs-62' -----

Install log file is located here: /tmp/columnstore_tmp_files/pm2_binary_install.log


===== Checking MariaDB ColumnStore System Logging Functionality =====

The MariaDB ColumnStore system logging is setup and working on local server

MariaDB ColumnStore System Configuration and Installation is Completed

===== MariaDB ColumnStore System Startup =====

System Configuration is complete.
Performing System Installation.

----- Starting MariaDB ColumnStore on local server -----

MariaDB ColumnStore successfully started

MariaDB ColumnStore Database Platform Starting, please wait ............ DONE

System Catalog Successfully Created

Run MariaDB ColumnStore Replication Setup..  DONE

MariaDB ColumnStore Install Successfully Completed, System is Active

Enter the following command to define MariaDB ColumnStore Alias Commands

. /etc/profile.d/columnstoreAlias.sh

Enter 'mariadb' to access the MariaDB ColumnStore SQL console
Enter 'mcsadmin' to access the MariaDB ColumnStore Admin console

NOTE: The MariaDB ColumnStore Alias Commands are in /etc/profile.d/columnstoreAlias.sh
```

Now check MariaDB ColumnStore Status using `mcsadmin getsystemInfo` on Primary Node. It should be running as per normal

```txt
[root@cs-61 ~]# mcsadmin getSystemInfo
getsysteminfo   Thu Mar 19 12:04:59 2020

System columnstore-1

System and Module statuses

Component     Status                       Last Status Change
------------  --------------------------   ------------------------
System        ACTIVE                       Thu Mar 19 12:00:36 2020

Module pm1    ACTIVE                       Thu Mar 19 12:00:27 2020
Module pm2    ACTIVE                       Thu Mar 19 12:00:18 2020

Active Parent OAM Performance Module is 'pm1'
Primary Front-End MariaDB ColumnStore Module is 'pm1'
MariaDB ColumnStore Replication Feature is enabled

MariaDB ColumnStore Process statuses

Process             Module    Status            Last Status Change        Process ID
------------------  ------    ---------------   ------------------------  ----------
ProcessMonitor      pm1       ACTIVE            Thu Mar 19 11:58:56 2020       14869
ProcessManager      pm1       ACTIVE            Thu Mar 19 11:59:02 2020       14937
DBRMControllerNode  pm1       ACTIVE            Thu Mar 19 11:59:57 2020       15797
ServerMonitor       pm1       ACTIVE            Thu Mar 19 12:00:00 2020       15824
DBRMWorkerNode      pm1       ACTIVE            Thu Mar 19 12:00:01 2020       15876
PrimProc            pm1       ACTIVE            Thu Mar 19 12:00:04 2020       15943
ExeMgr              pm1       ACTIVE            Thu Mar 19 12:00:14 2020       16441
WriteEngineServer   pm1       ACTIVE            Thu Mar 19 12:00:19 2020       16547
DDLProc             pm1       ACTIVE            Thu Mar 19 12:00:26 2020       16778
DMLProc             pm1       ACTIVE            Thu Mar 19 12:00:36 2020       17029
mysqld              pm1       ACTIVE            Thu Mar 19 12:00:43 2020       17578

ProcessMonitor      pm2       ACTIVE            Thu Mar 19 11:59:44 2020        4793
ProcessManager      pm2       HOT_STANDBY       Thu Mar 19 11:59:50 2020        4846
DBRMControllerNode  pm2       COLD_STANDBY      Thu Mar 19 12:00:10 2020
ServerMonitor       pm2       ACTIVE            Thu Mar 19 12:00:02 2020        4982
DBRMWorkerNode      pm2       ACTIVE            Thu Mar 19 12:00:06 2020        5012
PrimProc            pm2       ACTIVE            Thu Mar 19 12:00:09 2020        5035
ExeMgr              pm2       ACTIVE            Thu Mar 19 12:00:15 2020        5098
WriteEngineServer   pm2       ACTIVE            Thu Mar 19 12:00:18 2020        5124
DDLProc             pm2       COLD_STANDBY      Thu Mar 19 12:00:18 2020
DMLProc             pm2       COLD_STANDBY      Thu Mar 19 12:00:18 2020
mysqld              pm2       ACTIVE            Thu Mar 19 12:00:51 2020        5396

Active Alarm Counts: Critical = 0, Major = 0, Minor = 0, Warning = 0, Info = 0
```

Login to mariadb from first node and verify

```txt
[root@cs-61 ~]# mariadb -uroot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 21
Server version: 10.4.12-6-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select user();
+----------------+
| user()         |
+----------------+
| root@localhost |
+----------------+
1 row in set (0.000 sec)

MariaDB [(none)]> show create user root@localhost;
+----------------------------------------------------------------------------------------------------+
| CREATE USER for root@localhost                                                                     |
+----------------------------------------------------------------------------------------------------+
| CREATE USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING 'invalid' OR unix_socket |
+----------------------------------------------------------------------------------------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Columnstore        | YES     | ColumnStore storage engine                                                                      | YES          | NO   | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
| S3                 | NO      | Read only table stored in S3. Created by running ALTER TABLE table_name ENGINE=s3               | NULL         | NULL | NULL       |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| wsrep              | YES     | Wsrep replication plugin                                                                        | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
11 rows in set (0.001 sec)
```

Verify the same from second node

```txt
[root@cs-62 ~]# mariadb -uroot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 15
Server version: 10.4.12-6-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select user();
+----------------+
| user()         |
+----------------+
| root@localhost |
+----------------+
1 row in set (0.001 sec)

MariaDB [(none)]> show create user root@localhost;
+----------------------------------------------------------------------------------------------------+
| CREATE USER for root@localhost                                                                     |
+----------------------------------------------------------------------------------------------------+
| CREATE USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING 'invalid' OR unix_socket |
+----------------------------------------------------------------------------------------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Columnstore        | YES     | ColumnStore storage engine                                                                      | YES          | NO   | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
| S3                 | NO      | Read only table stored in S3. Created by running ALTER TABLE table_name ENGINE=s3               | NULL         | NULL | NULL       |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| wsrep              | YES     | Wsrep replication plugin                                                                        | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
11 rows in set (0.001 sec)
```

### Setup `/etc/sudoers`

Now that the ColumnStore and MariaDB services are running on both nodes, we can setup the non-root user `mcsadm` so that this user is able to start/stop MariaDB and ColumnStore services.

Execute the following on both nodes as the `root` user to add the limited `sudo` priviliges for `mcsadm` user.

```txt
[root@cs-61 ~]# echo "mcsadm ALL=(root) NOPASSWD: /usr/bin/mcsadmin, /usr/bin/systemctl stop columnstore, /usr/bin/systemctl start columnstore, /usr/bin/systemctl stop mariadb, /usr/bin/systemctl start mariadb" >> /etc/sudoers
```

Switch as `mcsadm` user and execute `sudo -l` to verify the priviliges have been ranted.

```txt
[root@cs-61 ~]# su - mcsadm
Last login: Thu Mar 19 12:31:45 EDT 2020 on pts/0
[mcsadm@cs-61 ~]$ 
[mcsadm@cs-61 ~]$ 
[mcsadm@cs-61 ~]$ sudo -l
Matching Defaults entries for mcsadm on cs-61:
    !visiblepw, always_set_home, match_group_by_gid, always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS", env_keep+="MAIL PS1 PS2 QTDIR
    USERNAME LANG LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE",
    env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY", secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User columnstore may run the following commands on cs-61:
    (root) NOPASSWD: /usr/bin/mcsadmin, /usr/bin/systemctl stop columnstore, /usr/bin/systemctl start columnstore, /usr/bin/systemctl stop mariadb, /usr/bin/systemctl start mariadb
```

The above `sudo` privilege can be read as, the user `mcsadm` can execute from any host as the `root` user without needing a password the following commands.

This is very limited privilege and the `mcsadm` user cannot perform anything other than the commands mentioned above.

### ColumnStore filesystem Ownership

Befor proceeding, we must change the ColumnStore filesystem to be owned by the `mcsadm` user.

Execute the following on both nodes as the `root` user to set file ownership and read permissions for the `mcsadm` user.

```txt
[root@cs-61 ~]# chown -R mcsadm:mcsadm /etc/columnstore/ /var/lib/columnstore/ /tmp/columnstore_tmp_files/ /var/log/mariadb

[root@cs-61 ~]# chmod -R g+s /etc/columnstore/ /var/lib/columnstore/ /tmp/columnstore_tmp_files/ /var/log/mariadb
```

ColumnStore service can be shutdown normally using the `sudo mcsadmin shutdownsystem y` command

### StorageManager Filesystem

The following is to be done on both nodes.

Copy the `/root/storagemanager` folder to `/home/mcsadm/` and then change the ownership of those folders to `mcsadm`

```
[root@cs-61 ~]# cp -r /root/storagemanager /home/mcsadm/
[root@cs-61 ~]# chown -R mcsadm:mcsadm /home/mcsadm/
```

Secondly, edit the `/etc/columnstore/storagemanager.cnf` file and replace all the instances of **`${HOME}`** with **`/home/mcsadm/`**

***Note:** This is important else `mcsadm` will not have access to the S3 storage meta-data filesystem.*

### ColumnStore Maintenance

Switch to the `mcsadm` user and perform a shutdown. From this point onwards, all the maintenance tasks can be carried out using the `mcsadm` user.

***Note:** All the commands that have been allowed in the `/etc/sudoers` must be executed with `sudo`*

```txt
[root@cs-61 ~]# su - mcsadm
Last login: Thu Mar 19 12:18:03 EDT 2020 on pts/0
[mcsadm@cs-61 ~]$ 
[mcsadm@cs-61 ~]$ sudo mcsadmin shutdownSystem y
shutdownsystem   Thu Mar 19 12:19:27 2020

This command stops the processing of applications on all Modules within the MariaDB ColumnStore System

   Checking for active transactions

   Stopping System...
   Successful stop of System 

   Shutting Down System...
   Successful shutdown of System 
```

This will shutdown MariaDB and ColumnStore on all the nodes automatically.

To start the service, we need to user `systemctl` on both nodes. 

***Note:** mcsadmin will not be able to start services because we don't have a ssh key setup done. Alternate way is to use systemctl on both nodes as follows*

Node1:
```txt
[mcsadm@cs-61 ~]$ sudo systemctl start columnstore && sudo systemctl start mariadb
```

Node2:
```txt
[mcsadm@cs-61 ~]$ sudo systemctl start columnstore && sudo systemctl start mariadb
```

From Primary Node, verify as the `mcsadm` user that the services have been started on both nodes or now.

```txt
[mcsadm@cs-61 ~]$ sudo mcsadmin getSystemInfo
getsysteminfo   Thu Mar 19 12:24:40 2020

System columnstore-1

System and Module statuses

Component     Status                       Last Status Change
------------  --------------------------   ------------------------
System        ACTIVE                       Thu Mar 19 12:24:39 2020

Module pm1    ACTIVE                       Thu Mar 19 12:24:36 2020
Module pm2    ACTIVE                       Thu Mar 19 12:24:32 2020

Active Parent OAM Performance Module is 'pm1'
Primary Front-End MariaDB ColumnStore Module is 'pm1'
MariaDB ColumnStore Replication Feature is enabled

MariaDB ColumnStore Process statuses

Process             Module    Status            Last Status Change        Process ID
------------------  ------    ---------------   ------------------------  ----------
ProcessMonitor      pm1       ACTIVE            Thu Mar 19 12:23:38 2020        4190
ProcessManager      pm1       ACTIVE            Thu Mar 19 12:23:44 2020        4426
DBRMControllerNode  pm1       ACTIVE            Thu Mar 19 12:24:13 2020        5007
ServerMonitor       pm1       ACTIVE            Thu Mar 19 12:24:15 2020        5038
DBRMWorkerNode      pm1       ACTIVE            Thu Mar 19 12:24:16 2020        5094
PrimProc            pm1       ACTIVE            Thu Mar 19 12:24:20 2020        5225
ExeMgr              pm1       ACTIVE            Thu Mar 19 12:24:25 2020        5407
WriteEngineServer   pm1       ACTIVE            Thu Mar 19 12:24:29 2020        5523
DDLProc             pm1       ACTIVE            Thu Mar 19 12:24:33 2020        5649
DMLProc             pm1       ACTIVE            Thu Mar 19 12:24:37 2020        5758
mysqld              pm1       ACTIVE            Thu Mar 19 12:24:23 2020        4290

ProcessMonitor      pm2       ACTIVE            Thu Mar 19 12:24:04 2020        8554
ProcessManager      pm2       HOT_STANDBY       Thu Mar 19 12:24:09 2020        8736
DBRMControllerNode  pm2       COLD_STANDBY      Thu Mar 19 12:24:14 2020
ServerMonitor       pm2       ACTIVE            Thu Mar 19 12:24:17 2020        8780
DBRMWorkerNode      pm2       ACTIVE            Thu Mar 19 12:24:17 2020        8820
PrimProc            pm2       ACTIVE            Thu Mar 19 12:24:22 2020        8835
ExeMgr              pm2       ACTIVE            Thu Mar 19 12:24:26 2020        8877
WriteEngineServer   pm2       ACTIVE            Thu Mar 19 12:24:30 2020        8911
DDLProc             pm2       COLD_STANDBY      Thu Mar 19 12:24:32 2020
DMLProc             pm2       COLD_STANDBY      Thu Mar 19 12:24:32 2020
mysqld              pm2       ACTIVE            Thu Mar 19 12:24:14 2020        8648

Active Alarm Counts: Critical = 0, Major = 0, Minor = 0, Warning = 0, Info = 0
```

***Note:** `sudo mcsadmin startSystem root-password` can still be used but it will require root user password and the password of the root user must be the same.*

Maintenance flow, shutdown to be done using `sudo mcsadmin shutdownSystsm y` and startup using `systemctl` of both `columnstore` and `mariadb` services on both nodes starting with the Primary node (PM1).

- As `mcsadm` user
  - **`sudo mcsadmin shutdownSystem y`**
    - once services are completely down on both nodes, proceed
  - PM1 (Primary Node)
    - **`sudo systemctl start columnstore && sudo systemctl start mariadb`**
      - These can be executed separately or together as one as shown here
  - PM2 (Replica Node)
    - **`sudo systemctl start columnstore && sudo systemctl start mariadb`**
      - These can be executed separately or together as one as shown here
  - PM1 (Primary Node)
    - **`sudo mcsadmin getSystemInfo`**
      - To verify the environment status

**Note:** All the server logs are under **`/var/log/mariadb`** and **`/var/log/mariadb/columnstore`** folders

Thank You.