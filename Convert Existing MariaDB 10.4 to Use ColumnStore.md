# Setup ColumnStore 1.4.x on the Existing MariaDB 10.4.x

## Assumptions

For this to work, it is required to have viersions of both MariaDB and ColumnStore same or higher than:

- MariaDB 10.4.12
- CS 1.4.3

## Dependencies

There are some dependencies that need to be fulfilled before proceeding with the isntallation.

Perform the following on all the nodes. Take note that the **`epel-release`** is to be installed first before continuing with the remaining.

```
[root@cs-61]# localedef -i en_US -f UTF-8 en_US.UTF-8

[root@cs-61]# yum -Y install epel-release
...
...
[root@cs-61]# yum -y install boost
...
...
[root@cs-61]# yum -y expect
...
...
[root@cs-61]# yum -y perl
...
...
[root@cs-61]# yum -y perl-DBI
...
...
[root@cs-61]# yum -y openssl
...
...
[root@cs-61]# yum -y zlib
...
...
[root@cs-61]# yum -y file
...
...
[root@cs-61]# yum -y sudo
...
...
[root@cs-61]# yum -y libaio
...
...
[root@cs-61]# yum -y rsync
...
...
[root@cs-61]# yum -y snappy
...
...
[root@cs-61]# yum -y net-tools
...
...
[root@cs-61]# yum -y numactl-libs
...
...
[root@cs-61]# yum -y nmap
...
...
[root@cs-61]# yum -y jemalloc
...
...
```

Once dependencies are installed, download and untar the MariaDB 10.4 enterprise server all the servers.

### Installation

#### Assumption

It is assumed that the MariaDB 10.4.12 is installed and runing on two servers with standard Replication already in place and the servers are running.

#### ColumnStore Install

The following 3 additional rpm files needs to be installed on both of the nodes. 

- **mariadb-columnstore-libs**
  - MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm
- **mariadb-columnstore-platform**
  - MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm
- **mariadb-columnstore-engine**
  - MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm

Installation Log:

```
[root@x4-61 mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm: MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64
Marking MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-columnstore-libs.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=====================================================================================================================================================================================================================
 Package                                             Arch                              Version                                     Repository                                                                   Size
=====================================================================================================================================================================================================================
Installing:
 MariaDB-columnstore-libs                            x86_64                            10.4.12_6-1.el7                             /MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64                             14 M

Transaction Summary
=====================================================================================================================================================================================================================
Install  1 Package

Total size: 14 M
Installed size: 14 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64                                                                                                                                                   1/1 
  Verifying  : MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64                                                                                                                                                   1/1 

Installed:
  MariaDB-columnstore-libs.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                  

Complete!


[root@x4-61 mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
Marking MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-columnstore-platform.x86_64 0:10.4.12_6-1.el7 will be installed
--> Processing Dependency: /usr/bin/expect for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                                                                                                                          | 9.0 kB  00:00:00     
 * base: centos.usonyx.net
 * epel: my.fedora.ipserverone.com
 * extras: centos.usonyx.net
 * updates: centos.usonyx.net
epel                                                                                                                                                                                          | 5.3 kB  00:00:00     
(1/3): epel/x86_64/group_gz                                                                                                                                                                   |  90 kB  00:00:00     
(2/3): epel/x86_64/updateinfo                                                                                                                                                                 | 1.0 MB  00:00:01     
(3/3): epel/x86_64/primary_db                                                                                                                                                                 | 6.7 MB  00:00:01     
--> Processing Dependency: libboost_atomic-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_chrono-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_chrono.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_date_time-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_filesystem-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_filesystem.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_regex-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_regex.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_system-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_system.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Processing Dependency: libboost_thread-mt.so.1.53.0()(64bit) for package: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
--> Running transaction check
---> Package boost-atomic.x86_64 0:1.53.0-27.el7 will be installed
---> Package boost-chrono.x86_64 0:1.53.0-27.el7 will be installed
---> Package boost-date-time.x86_64 0:1.53.0-27.el7 will be installed
---> Package boost-filesystem.x86_64 0:1.53.0-27.el7 will be installed
---> Package boost-regex.x86_64 0:1.53.0-27.el7 will be installed
--> Processing Dependency: libicuuc.so.50()(64bit) for package: boost-regex-1.53.0-27.el7.x86_64
--> Processing Dependency: libicui18n.so.50()(64bit) for package: boost-regex-1.53.0-27.el7.x86_64
--> Processing Dependency: libicudata.so.50()(64bit) for package: boost-regex-1.53.0-27.el7.x86_64
---> Package boost-system.x86_64 0:1.53.0-27.el7 will be installed
---> Package boost-thread.x86_64 0:1.53.0-27.el7 will be installed
---> Package expect.x86_64 0:5.45-14.el7_1 will be installed
--> Processing Dependency: libtcl8.5.so()(64bit) for package: expect-5.45-14.el7_1.x86_64
--> Running transaction check
---> Package libicu.x86_64 0:50.2-3.el7 will be installed
---> Package tcl.x86_64 1:8.5.13-8.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=====================================================================================================================================================================================================================
 Package                                               Arch                            Version                                   Repository                                                                     Size
=====================================================================================================================================================================================================================
Installing:
 MariaDB-columnstore-platform                          x86_64                          10.4.12_6-1.el7                           /MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64                           11 M
Installing for dependencies:
 boost-atomic                                          x86_64                          1.53.0-27.el7                             base                                                                           35 k
 boost-chrono                                          x86_64                          1.53.0-27.el7                             base                                                                           44 k
 boost-date-time                                       x86_64                          1.53.0-27.el7                             base                                                                           52 k
 boost-filesystem                                      x86_64                          1.53.0-27.el7                             base                                                                           68 k
 boost-regex                                           x86_64                          1.53.0-27.el7                             base                                                                          300 k
 boost-system                                          x86_64                          1.53.0-27.el7                             base                                                                           40 k
 boost-thread                                          x86_64                          1.53.0-27.el7                             base                                                                           57 k
 expect                                                x86_64                          5.45-14.el7_1                             base                                                                          262 k
 libicu                                                x86_64                          50.2-3.el7                                base                                                                          6.9 M
 tcl                                                   x86_64                          1:8.5.13-8.el7                            base                                                                          1.9 M

Transaction Summary
=====================================================================================================================================================================================================================
Install  1 Package (+10 Dependent packages)

Total size: 20 M
Total download size: 9.6 M
Installed size: 42 M
Downloading packages:
(1/10): boost-atomic-1.53.0-27.el7.x86_64.rpm                                                                                                                                                 |  35 kB  00:00:00     
(2/10): boost-chrono-1.53.0-27.el7.x86_64.rpm                                                                                                                                                 |  44 kB  00:00:00     
(3/10): boost-date-time-1.53.0-27.el7.x86_64.rpm                                                                                                                                              |  52 kB  00:00:00     
(4/10): boost-filesystem-1.53.0-27.el7.x86_64.rpm                                                                                                                                             |  68 kB  00:00:00     
(5/10): boost-system-1.53.0-27.el7.x86_64.rpm                                                                                                                                                 |  40 kB  00:00:00     
(6/10): boost-thread-1.53.0-27.el7.x86_64.rpm                                                                                                                                                 |  57 kB  00:00:00     
(7/10): boost-regex-1.53.0-27.el7.x86_64.rpm                                                                                                                                                  | 300 kB  00:00:00     
(8/10): expect-5.45-14.el7_1.x86_64.rpm                                                                                                                                                       | 262 kB  00:00:00     
(9/10): tcl-8.5.13-8.el7.x86_64.rpm                                                                                                                                                           | 1.9 MB  00:00:00     
(10/10): libicu-50.2-3.el7.x86_64.rpm                                                                                                                                                         | 6.9 MB  00:00:01     
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                5.1 MB/s | 9.6 MB  00:00:01     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : boost-system-1.53.0-27.el7.x86_64                                                                                                                                                                1/11 
  Installing : boost-chrono-1.53.0-27.el7.x86_64                                                                                                                                                                2/11 
  Installing : boost-thread-1.53.0-27.el7.x86_64                                                                                                                                                                3/11 
  Installing : boost-filesystem-1.53.0-27.el7.x86_64                                                                                                                                                            4/11 
  Installing : boost-atomic-1.53.0-27.el7.x86_64                                                                                                                                                                5/11 
  Installing : 1:tcl-8.5.13-8.el7.x86_64                                                                                                                                                                        6/11 
  Installing : expect-5.45-14.el7_1.x86_64                                                                                                                                                                      7/11 
  Installing : libicu-50.2-3.el7.x86_64                                                                                                                                                                         8/11 
  Installing : boost-regex-1.53.0-27.el7.x86_64                                                                                                                                                                 9/11 
  Installing : boost-date-time-1.53.0-27.el7.x86_64                                                                                                                                                            10/11 
  Installing : MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64                                                                                                                                             11/11 
The next step on the node that will become PM1:

postConfigure


  Verifying  : boost-system-1.53.0-27.el7.x86_64                                                                                                                                                                1/11 
  Verifying  : boost-date-time-1.53.0-27.el7.x86_64                                                                                                                                                             2/11 
  Verifying  : boost-regex-1.53.0-27.el7.x86_64                                                                                                                                                                 3/11 
  Verifying  : libicu-50.2-3.el7.x86_64                                                                                                                                                                         4/11 
  Verifying  : 1:tcl-8.5.13-8.el7.x86_64                                                                                                                                                                        5/11 
  Verifying  : expect-5.45-14.el7_1.x86_64                                                                                                                                                                      6/11 
  Verifying  : boost-chrono-1.53.0-27.el7.x86_64                                                                                                                                                                7/11 
  Verifying  : boost-thread-1.53.0-27.el7.x86_64                                                                                                                                                                8/11 
  Verifying  : MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64                                                                                                                                              9/11 
  Verifying  : boost-atomic-1.53.0-27.el7.x86_64                                                                                                                                                               10/11 
  Verifying  : boost-filesystem-1.53.0-27.el7.x86_64                                                                                                                                                           11/11 

Installed:
  MariaDB-columnstore-platform.x86_64 0:10.4.12_6-1.el7                                                                                                                                                              

Dependency Installed:
  boost-atomic.x86_64 0:1.53.0-27.el7      boost-chrono.x86_64 0:1.53.0-27.el7      boost-date-time.x86_64 0:1.53.0-27.el7      boost-filesystem.x86_64 0:1.53.0-27.el7      boost-regex.x86_64 0:1.53.0-27.el7     
  boost-system.x86_64 0:1.53.0-27.el7      boost-thread.x86_64 0:1.53.0-27.el7      expect.x86_64 0:5.45-14.el7_1               libicu.x86_64 0:50.2-3.el7                   tcl.x86_64 1:8.5.13-8.el7              

Complete!


[root@x4-61 mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm: MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64
Marking MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-columnstore-engine.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=====================================================================================================================================================================================================================
 Package                                              Arch                             Version                                    Repository                                                                    Size
=====================================================================================================================================================================================================================
Installing:
 MariaDB-columnstore-engine                           x86_64                           10.4.12_6-1.el7                            /MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64                           1.4 M

Transaction Summary
=====================================================================================================================================================================================================================
Install  1 Package

Total size: 1.4 M
Installed size: 1.4 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64                                                                                                                                                 1/1 
  Verifying  : MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64                                                                                                                                                 1/1 

Installed:
  MariaDB-columnstore-engine.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                

Complete!
```

Now restart the MariaDB service and logon to the client to verify the ColumnStore engine

```
[root@x4-61 mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 10
Server version: 10.4.12-6-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

x4-61 [(none)]> show engines;
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

The engine is available but not ready to be used just yet. We will need to configure it first with a set of steps.

### ColumnStore additional configurations

#### Setup Host file

Add your hostname and IP addresses of both nodes to the `/etc/hosts` file on both servers.

My `/etc/hosts` file looks like this after adding the to servers

```txt
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.56.61 x4-61
192.168.56.62 x4-62
```

#### Setup `ulimit`

Do the following on both servers.

```txt
[root@x4-61]# echo "@mcsadm hard nofile 65536" >> /etc/security/limits.conf
[root@x4-61]# echo "@mcsadm soft nofile 65536" >> /etc/security/limits.conf
```

#### Setup SSH

Generate SSH Keys on the Node 1 and copy it to the second node

```txt
[root@x4-61 ~]# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:M4vgpvEdUvA6h+f8ECcxenQ+q3zfu35THDyAa2SFOrI root@x4-61
The key's randomart image is:
+---[RSA 2048]----+
|            +.   |
|           = .   |
|    . + . + . o  |
|     = * o o   + |
|    o * S o    .o|
|   . * E *      o|
|  . B * o      . |
|   = X +.  .  o  |
|  . . *o....=+ . |
+----[SHA256]-----+


[root@x4-61 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.56.62
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.62 (192.168.56.62)' can't be established.
ECDSA key fingerprint is SHA256:EeFtyGQ5pFX/BY/DSRLOBj7d4PNUVyoPcfcGqxS/XHc.
ECDSA key fingerprint is MD5:c5:58:a6:8f:4b:4e:4b:fc:ff:22:de:a3:f2:4a:2a:01.
Are you sure you want to continue connecting (yes/no)? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@192.168.56.62's password: **********

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.56.62'"
and check to make sure that only the key(s) you wanted were added.
```

Key in the password one time to connect to the second node as shown above.

Now connect to the server2 using SSH with both the IP and the HOSTNAME to ensure that SSH connectivity works without passwords.

```
[root@x4-61 ~]# ssh 192.168.56.62
Last login: Wed Mar 11 03:23:23 2020 from 192.168.56.1
[root@x4-62 ~]# 
[root@x4-62 ~]# 
[root@x4-62 ~]# exit
logout
Connection to 192.168.56.62 closed.
[root@x4-61 ~]# 
[root@x4-61 ~]# ssh x4-62
The authenticity of host 'x4-62 (192.168.56.62)' can't be established.
ECDSA key fingerprint is SHA256:EeFtyGQ5pFX/BY/DSRLOBj7d4PNUVyoPcfcGqxS/XHc.
ECDSA key fingerprint is MD5:c5:58:a6:8f:4b:4e:4b:fc:ff:22:de:a3:f2:4a:2a:01.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'x4-62' (ECDSA) to the list of known hosts.
Last login: Wed Mar 11 04:41:03 2020 from x4-61
```

SSH with IP works without any promot, but when connecting via hostname, it prompted to save the key, just respond with `yes` and it's done.

Now we are ready to run the configuration scripts.

### ColumnStore Config Scripts

Installation loads software to the system. This software requires post-install actions and configuration before the database server is ready for use.

MariaDB ColumnStore post-installation scripts fail if they find MariaDB Enterprise Server running on the system. Stop the Server and disable the service before proceeding. This must be done on both the nodes.

```txt
[root@x4-61 ~]# systemctl stop mariadb.service
[root@x4-61 ~]# systemctl disable mariadb.service
```

Execute the post install script on the primary node

```txt
[root@x4-61 ~]# columnstore-post-install
The next step on the node that will become PM1:

postConfigure


[root@x4-61 ~]# 
```

Now we are ready to configure S3 storage followed by `postConfigure` script execution wihch will actually install ColumnStore and connect to S3 storage.

### Configure S3 Storage

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

```txt
[root@x4-61 ~]# postConfigure

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

Select the type of System Module Install [1=separate, 2=combined] (1) > 2

Combined Server Installation will be performed.
The Server will be configured as a Performance Module.
All MariaDB ColumnStore Processes will run on the Performance Modules.

NOTE: The MariaDB ColumnStore Schema Sync feature will replicate all of the
      schemas and InnoDB tables across the User Module nodes. This feature can be enabled
      or disabled, for example, if you wish to configure your own replication post installation.

MariaDB ColumnStore Schema Sync feature, do you want to enable? [y,n] (y) > n


NOTE: MariaDB ColumnStore Replication Feature will not be enabled

Enter System Name (columnstore-1) > DBS-3G-CS


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
Select the type of data storage (1) > 1

===== Setup Memory Configuration =====


NOTE: Setting 'NumBlocksPct' to 50%
      Setting 'TotalUmMemory' to 25%


===== Setup the Module Configuration =====


----- Performance Module Configuration -----

Enter number of Performance Modules [1,1024] (1) > 2

*** Parent OAM Module Performance Module #1 Configuration ***

Enter Nic Interface #1 Host Name (x4-61) > x4-61
Enter Nic Interface #1 IP Address or hostname of x4-61 (192.168.56.61) > 192.168.56.61
Enter Nic Interface #2 Host Name (unassigned) > 
Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm1' (1) > 1

*** Performance Module #2 Configuration ***

Enter Nic Interface #1 Host Name (unassigned) > x4-62
Enter Nic Interface #1 IP Address or hostname of x4-62 (192.168.56.62) > 192.168.56.62
Enter Nic Interface #2 Host Name (unassigned) > 
Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm2' () > 2

===== Running the MariaDB ColumnStore MariaDB Server setup scripts =====
sh: netstat: command not found

post-mysqld-install Successfully Completed
post-mysql-install Successfully Completed

Next step is to enter the password to access the other Servers.
This is either user password or you can default to using an ssh key
If using a user password, the password needs to be the same on all Servers.

Enter password, hit 'enter' to default to using an ssh key, or 'exit' > 

----- Performing Install on 'pm2 / x4-62' -----

Install log file is located here: /tmp/columnstore_tmp_files/pm2_binary_install.log


===== Checking MariaDB ColumnStore System Logging Functionality =====

The MariaDB ColumnStore system logging is setup and working on local server

MariaDB ColumnStore System Configuration and Installation is Completed


===== MariaDB ColumnStore System Startup =====

System Configuration is complete.
Performing System Installation.

----- Starting MariaDB ColumnStore on local server -----

MariaDB ColumnStore successfully started

MariaDB ColumnStore Database Platform Starting, please wait ............. DONE

System Catalog Successfully Created

Run MariaDB ColumnStore Replication Setup..  DONE

MariaDB ColumnStore Install Successfully Completed, System is Active

Enter the following command to define MariaDB ColumnStore Alias Commands

. /etc/profile.d/columnstoreAlias.sh

Enter 'mariadb' to access the MariaDB ColumnStore SQL console
Enter 'mcsadmin' to access the MariaDB ColumnStore Admin console

NOTE: The MariaDB ColumnStore Alias Commands are in /etc/profile.d/columnstoreAlias.sh
```

The above process takes us through the following questions

- `Select the type of System Server install [1=single, 2=multi] (2) > 2`
  - Input **2** here as we want a multi node setup
- `Select the type of System Module Install [1=separate, 2=combined] (1) > 2`
  - Input **2** here as we want to combine the UM/PM nodes, this is the new way of setting up ColumnStore
- `MariaDB ColumnStore Schema Sync feature, do you want to enable? [y,n] (y) > n`
  - This should be answered as **n** because we want to keep the current replication setup between the two nodes.
- `Enter System Name (columnstore-1) > DBS-3G-CS`
  - This is just the name of the ColumnStore system. Not of any significance. Can be named as any name. 
- `Select the type of data storage (1) > 4`
  - This is where we select **S3** as the storage option. Make sure that the **`/etc/columnstore/storagemanager.cnf`** file has already been configured with S3 related parameters before we do this.
- `Enter number of Performance Modules [1,1024] (1) > 2`
  - Since we have two nodes that we are working with, we need to input **2** here. Next steps will be related to these 2 servers.
- **Node 1** Configration
  - `Enter Nic Interface #1 Host Name (x4-61) > x4-61`
    - Input the Hostname for the first server, I have used `x4-61` based on my **/etc/hosts** file config.
  - `Enter Nic Interface #1 IP Address or hostname of x4-61 (192.168.56.61) > 192.168.56.61`
    - Followed by the IP of the first node
  - `Enter Nic Interface #2 Host Name (unassigned) >`
    - This is configurin the second network interface if available, just leave it empty since we only have 1 network interface.
  - `Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm1' (1) > 1`
    - This is the root configration for the first node, key in **1** here to denote that this is going to be the first database root for ColumnStore.
- **Node 2** Configration
  - `Enter Nic Interface #1 Host Name (unassigned) > x4-62`
    - Input the Hostname for the second server, take note that it shows as (unassigned) at first, I have used `x4-62` based on my **/etc/hosts** file config.
  - `Enter Nic Interface #1 IP Address or hostname of x4-62 (192.168.56.62) > 192.168.56.62`
    - Followed by the IP of the second node
  - `Enter Nic Interface #2 Host Name (unassigned) >`
    - This is configurin the second network interface for the second server if available, just leave it empty since we only have 1 network interface.
  - `Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm2' () > 2`
    - This is the root configration for the second node, key in **2** here to denote that this is going to be the first database root for ColumnStore.
- `Enter password, hit 'enter' to default to using an ssh key, or 'exit' >`
  - Since we have already configured SSH, we can jsut press enter here.
  - After this, postConfigure will continue to setup replication and all the other processes that are required for it to work properly.

Once the process completes successfully, it will display the following as a confirmation:

```txt
===== MariaDB ColumnStore System Startup =====

System Configuration is complete.
Performing System Installation.

----- Starting MariaDB ColumnStore on local server -----

MariaDB ColumnStore successfully started

MariaDB ColumnStore Database Platform Starting, please wait ............. DONE

System Catalog Successfully Created

Run MariaDB ColumnStore Replication Setup..  DONE

MariaDB ColumnStore Install Successfully Completed, System is Active
```

_**Note:** In case of issues with the postConfigure, it should be executed again._

#### Verification 

First thing to verify is `mcsadmin getSystemInfo` from Node 1 (PM1) to see that both nodes are active and all the sub-processes are running properly.

```
[root@x4-61 ~]# mcsadmin getSystemInfo
getsysteminfo   Wed Mar 11 05:36:01 2020

System DBS-3G-CS

System and Module statuses

Component     Status                       Last Status Change
------------  --------------------------   ------------------------
System        ACTIVE                       Wed Mar 11 05:30:53 2020

Module pm1    ACTIVE                       Wed Mar 11 05:30:43 2020
Module pm2    ACTIVE                       Wed Mar 11 05:30:33 2020

Active Parent OAM Performance Module is 'pm1'
Primary Front-End MariaDB ColumnStore Module is 'pm1'
MariaDB ColumnStore Replication Feature is enabled

MariaDB ColumnStore Process statuses

Process             Module    Status            Last Status Change        Process ID
------------------  ------    ---------------   ------------------------  ----------
ProcessMonitor      pm1       ACTIVE            Wed Mar 11 05:29:15 2020        4537
ProcessManager      pm1       ACTIVE            Wed Mar 11 05:29:22 2020        4608
DBRMControllerNode  pm1       ACTIVE            Wed Mar 11 05:30:13 2020        5446
ServerMonitor       pm1       ACTIVE            Wed Mar 11 05:30:16 2020        5473
DBRMWorkerNode      pm1       ACTIVE            Wed Mar 11 05:30:16 2020        5502
PrimProc            pm1       ACTIVE            Wed Mar 11 05:30:20 2020        5598
ExeMgr              pm1       ACTIVE            Wed Mar 11 05:30:30 2020        6144
WriteEngineServer   pm1       ACTIVE            Wed Mar 11 05:30:34 2020        6250
DDLProc             pm1       ACTIVE            Wed Mar 11 05:30:41 2020        6522
DMLProc             pm1       ACTIVE            Wed Mar 11 05:30:51 2020        6768
mysqld              pm1       ACTIVE            Wed Mar 11 05:31:00 2020        7388

ProcessMonitor      pm2       ACTIVE            Wed Mar 11 05:30:02 2020        4001
ProcessManager      pm2       HOT_STANDBY       Wed Mar 11 05:30:08 2020        4053
DBRMControllerNode  pm2       COLD_STANDBY      Wed Mar 11 05:30:25 2020
ServerMonitor       pm2       ACTIVE            Wed Mar 11 05:30:20 2020        4216
DBRMWorkerNode      pm2       ACTIVE            Wed Mar 11 05:30:21 2020        4230
PrimProc            pm2       ACTIVE            Wed Mar 11 05:30:24 2020        4253
ExeMgr              pm2       ACTIVE            Wed Mar 11 05:30:31 2020        4333
WriteEngineServer   pm2       ACTIVE            Wed Mar 11 05:30:35 2020        4357
DDLProc             pm2       COLD_STANDBY      Wed Mar 11 05:30:33 2020
DMLProc             pm2       COLD_STANDBY      Wed Mar 11 05:30:33 2020
mysqld              pm2       ACTIVE            Wed Mar 11 05:31:09 2020        4656

Active Alarm Counts: Critical = 0, Major = 0, Minor = 0, Warning = 0, Info = 0
```
This confirms that both nodes are working fine.

Connect to the Replica Node (PM2) and verify that the replicaiton is still working and is based on GTID

_**Note:** Since this is a combined multi-node setup, we can connect from any node. But just like a standard replication setup, Replica node (PM2) will be in a read-only mode for InnoDB tables but data loading on the columnstore tables can be done from any node._

```txt
[root@x4-62 ~] mariadb -uroot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 18
Server version: 10.4.12-6-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

x4-62 [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 192.168.56.61
                   Master_User: idbrep
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mariadb-bin.000006
           Read_Master_Log_Pos: 1934
                Relay_Log_File: x4-62-relay-bin.000002
                 Relay_Log_Pos: 557
         Relay_Master_Log_File: mariadb-bin.000006
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
           Exec_Master_Log_Pos: 1934
               Relay_Log_Space: 866
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
                    Using_Gtid: No
                   Gtid_IO_Pos: 0-2000-85
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

The Replica node is connected and slave runnign without problems.

##### Create ColumnStore Tables

Connect to Primary Node (PM1) using `mariadb` commandline client and try creating a table using `columnstore` as the engine. 

***Note:** InnoDB is the default engine on the server even thogh we have ColumnStore installed.*

```txt
[root@x4-61 ~]# mariadb -uapp_user -p
Enter password: ******** 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 10
Server version: 10.4.12-6-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

x4-61 [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| 3g_db              |
| information_schema |
+--------------------+
2 rows in set (0.001 sec)

x4-61 [(none)]> use 3g_db;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
x4-61 [3g_db]> CREATE TABLE cs_tab1(id int, c1 varchar(10)) Engine=ColumnStore;
Query OK, 0 rows affected (2.137 sec)

x4-61 [3g_db]> SHOW CREATE TABLE cs_tab1\G
*************************** 1. row ***************************
       Table: cs_tab1
Create Table: CREATE TABLE `cs_tab1` (
  `id` int(11) DEFAULT NULL,
  `c1` varchar(10) DEFAULT NULL
) ENGINE=Columnstore DEFAULT CHARSET=latin1
1 row in set (0.001 sec)

x4-61 [3g_db]> insert into cs_tab1 (id, c1) values (1, 'Data 1'), (2, 'Data 2'), (3, 'Data 3');
Query OK, 3 rows affected (0.557 sec)
Records: 3  Duplicates: 0  Warnings: 0

x4-61 [3g_db]> select * from cs_tab1;
+------+--------+
| id   | c1     |
+------+--------+
|    1 | Data 1 |
|    2 | Data 2 |
|    3 | Data 3 |
+------+--------+
3 rows in set (0.079 sec)
```

Connect to Node 2 and verify this table is accessible

```txt
[root@x4-62 ~]# mariadb -uapp_user -p
Enter password: ********
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 12
Server version: 10.4.12-6-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

x4-62 [(none)]> use 3g_db;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
x4-62 [3g_db]> show tables;
+-----------------+
| Tables_in_3g_db |
+-----------------+
| cs_tab1         |
| tab1            |
| tab2            |
+-----------------+
3 rows in set (0.001 sec)

x4-62 [3g_db]> select * from cs_tab1;
+------+--------+
| id   | c1     |
+------+--------+
|    1 | Data 1 |
|    2 | Data 2 |
|    3 | Data 3 |
+------+--------+
3 rows in set (0.053 sec)
```

#### CrossEngineJoin

By default, the user is not able to join InnoDB and ColumnStore tables in a single query. There is a special configuration required for the specific user that will be running such queries.

Edit the `/etc/columnstore/Columnstore.xml` configuration file and edit the following section with the user details who is supposed to be running such cross engine join based queris with ColumnStore.

***Note:** Only ONE user can be configured to use Cross Engine Joins at this time.*

```txt
<CrossEngineSupport>
        <Host>192.168.56.61</Host>
        <Port>3306</Port>
        <User>app_user</User>
        <Password>P@ssw0rd</Password>
        <TLSCA/>
        <TLSClientCert/>
        <TLSClientKey/>
</CrossEngineSupport>
```

I have configured `app_user` here, the `Host` will always be the Primary node.

Restart the ColumnStore system once the file has been modified

```txt
[root@x4-61 ~]# mcsadmin restartSystem y
restartsystem   Wed Mar 11 06:29:41 2020

   System being restarted now ...
   Successful restart of System 
```

Verify that the cross engine based queries work.

```
x4-61 [3g_db]> select * from tab1 a inner join cs_tab1 b ON a.ID=b.ID;
+----+----------------+------+--------+
| id | c1             | id   | c1     |
+----+----------------+------+--------+
|  1 | PLUGIN_NAME    |    1 | Data 1 |
|  2 | PLUGIN_VERSION |    2 | Data 2 |
|  3 | PLUGIN_STATUS  |    3 | Data 3 |
|  1 | PLUGIN_NAME    |    1 | Data 1 |
|  2 | PLUGIN_VERSION |    2 | Data 5 |
|  6 | PLUGIN_LIBRARY |    6 | Data 6 |
+----+----------------+------+--------+
6 rows in set (0.116 sec)

x4-61 [3g_db]> show create table cs_tab1\G
*************************** 1. row ***************************
       Table: cs_tab1
Create Table: CREATE TABLE `cs_tab1` (
  `id` int(11) DEFAULT NULL,
  `c1` varchar(10) DEFAULT NULL
) ENGINE=Columnstore DEFAULT CHARSET=latin1
1 row in set (0.001 sec)

x4-61 [3g_db]> show create table tab1\G
*************************** 1. row ***************************
       Table: tab1
Create Table: CREATE TABLE `tab1` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `c1` varchar(100) DEFAULT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1846 DEFAULT CHARSET=latin1
1 row in set (0.000 sec)
```

#### Maintenance (System Start/Shutdown)

ColumnStore service can be shutdown normally using the `mcsadmin shutdownSystem y` command and started up using `mcsadmin startSystem`

These admin commands can only be done from the Primary node (PM1). 

```txt
[root@x4-61 ~]# mcsadmin shutdownSystem y
shutdownsystem   Wed Mar 11 05:51:50 2020

This command stops the processing of applications on all Modules within the MariaDB ColumnStore System

   Checking for active transactions

   Stopping System...
   Successful stop of System 

   Shutting Down System...
   Successful shutdown of System 
```

This will shutdown MariaDB and ColumnStore on all the nodes automatically.

Executing the getSystemInfo command after the ColumnStore has been shutdown completely will result in the following:

```txt
[root@x4-61 ~]# mcsadmin getSystemInfo
getsysteminfo   Wed Mar 11 05:53:11 2020

System DBS-3G-CS

System and Module statuses

Component     Status                       Last Status Change
------------  --------------------------   ------------------------
System        MAN_OFFLINE                                          


MariaDB ColumnStore Replication Feature is enabled

MariaDB ColumnStore Process statuses

Process             Module    Status            Last Status Change        Process ID
------------------  ------    ---------------   ------------------------  ----------

**** printProcessStatus Failed =  API Failure return in getProcessStatus API
```

Starting up of the ColumnStore system

```txt
[root@x4-61 ~]# mcsadmin startSystem
startsystem   Wed Mar 11 05:54:33 2020

startSystem command, 'columnstore' service is down, sending command to
start the 'columnstore' service on all modules


   System being started, please wait..........
   Successful start of System 
```