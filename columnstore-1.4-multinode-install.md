# ColumnStore 1.4 Multinode Installation

This guide will guide us on installing and configuring ColumnStore 1.4 using the MariaDB 10.4 Enterprise Server. 

## Dependencies

There are some dependencies that need to be fulfilled before proceeding with the isntallation.

Perform the following on all the nodes 

```
[root@cs-61]# localedef -i en_US -f UTF-8 en_US.UTF-8

[root@cs-61]# yum -Y install epel-release

[root@cs-61]# yum -y install boost expect perl perl-DBI openssl zlib file sudo libaio rsync snappy net-tools numactl-libs nmap jemalloc
```

Once dependencies are installed, download and untar the MariaDB 10.4 enterprise server all the servers.

The extracted TAR file will have the following listing.

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

Install the RPM files on all the nodes.

- galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm
- MariaDB-compat-10.4.12_6-1.el7.x86_64.rpm
- MariaDB-common-10.4.12_6-1.el7.x86_64.rpm
- MariaDB-shared-10.4.12_6-1.el7.x86_64.rpm
- MariaDB-client-10.4.12_6-1.el7.x86_64.rpm
- MariaDB-server-10.4.12_6-1.el7.x86_64.rpm

Once these 6 rpm files have been install on all the nodes, the following 3 additional rpm files needs to be installed as well on all the nodes.

- **mariadb-columnstore-libs**
  - MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm
- **mariadb-columnstore-platform**
  - MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm
- **mariadb-columnstore-engine**
  - MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm

Installation Log:

```txt
[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm: galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64
Marking galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package galera-enterprise-4.x86_64 0:26.4.4-1.rhel7.5.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                              Arch                                    Version                                                  Repository                                                                         Size
===============================================================================================================================================================================================================================================
Installing:
 galera-enterprise-4                                  x86_64                                  26.4.4-1.rhel7.5.el7                                     /galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64                                   42 M

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package

Total size: 42 M
Installed size: 42 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64                                                                                                                                                                             1/1 
  Verifying  : galera-enterprise-4-26.4.4-1.rhel7.5.el7.x86_64                                                                                                                                                                             1/1 

Installed:
  galera-enterprise-4.x86_64 0:26.4.4-1.rhel7.5.el7                                                                                                                                                                                            

Complete!

[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-compat-10.4.12_6-1.el7.x86_64.rpm MariaDB-common-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-compat-10.4.12_6-1.el7.x86_64.rpm: MariaDB-compat-10.4.12_6-1.el7.x86_64
Marking MariaDB-compat-10.4.12_6-1.el7.x86_64.rpm to be installed
Examining MariaDB-common-10.4.12_6-1.el7.x86_64.rpm: MariaDB-common-10.4.12_6-1.el7.x86_64
Marking MariaDB-common-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-common.x86_64 0:10.4.12_6-1.el7 will be installed
---> Package MariaDB-compat.x86_64 0:10.4.12_6-1.el7 will be obsoleting
---> Package mariadb-libs.x86_64 1:5.5.60-1.el7_5 will be obsoleted
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                              Arch                                         Version                                                  Repository                                                                    Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-common                                       x86_64                                       10.4.12_6-1.el7                                          /MariaDB-common-10.4.12_6-1.el7.x86_64                                       305 k
 MariaDB-compat                                       x86_64                                       10.4.12_6-1.el7                                          /MariaDB-compat-10.4.12_6-1.el7.x86_64                                        11 M
     replacing  mariadb-libs.x86_64 1:5.5.60-1.el7_5

Transaction Summary
===============================================================================================================================================================================================================================================
Install  2 Packages

Total size: 12 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-compat-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/3 
  Installing : MariaDB-common-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       2/3 
  Erasing    : 1:mariadb-libs-5.5.60-1.el7_5.x86_64                                                                                                                                                                                        3/3 
  Verifying  : MariaDB-common-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/3 
  Verifying  : MariaDB-compat-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       2/3 
  Verifying  : 1:mariadb-libs-5.5.60-1.el7_5.x86_64                                                                                                                                                                                        3/3 

Installed:
  MariaDB-common.x86_64 0:10.4.12_6-1.el7                                                                                MariaDB-compat.x86_64 0:10.4.12_6-1.el7                                                                               

Replaced:
  mariadb-libs.x86_64 1:5.5.60-1.el7_5                                                                                                                                                                                                         

Complete!

[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-shared-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-shared-10.4.12_6-1.el7.x86_64.rpm: MariaDB-shared-10.4.12_6-1.el7.x86_64
Marking MariaDB-shared-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-shared.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                              Arch                                         Version                                                  Repository                                                                    Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-shared                                       x86_64                                       10.4.12_6-1.el7                                          /MariaDB-shared-10.4.12_6-1.el7.x86_64                                       343 k

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package

Total size: 343 k
Installed size: 343 k
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-shared-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/1 
  Verifying  : MariaDB-shared-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/1 

Installed:
  MariaDB-shared.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                                                      

Complete!

[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-client-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-client-10.4.12_6-1.el7.x86_64.rpm: MariaDB-client-10.4.12_6-1.el7.x86_64
Marking MariaDB-client-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-client.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                              Arch                                         Version                                                  Repository                                                                    Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-client                                       x86_64                                       10.4.12_6-1.el7                                          /MariaDB-client-10.4.12_6-1.el7.x86_64                                        38 M

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package

Total size: 38 M
Installed size: 38 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-client-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/1 
  Verifying  : MariaDB-client-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/1 

Installed:
  MariaDB-client.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                                                      

Complete!

[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-server-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-server-10.4.12_6-1.el7.x86_64.rpm: MariaDB-server-10.4.12_6-1.el7.x86_64
Marking MariaDB-server-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-server.x86_64 0:10.4.12_6-1.el7 will be installed
--> Processing Dependency: lsof for package: MariaDB-server-10.4.12_6-1.el7.x86_64
Loading mirror speeds from cached hostfile
 * base: mirror.0x.sg
 * epel: my.fedora.ipserverone.com
 * extras: mirror.0x.sg
 * updates: mirror.0x.sg
--> Running transaction check
---> Package lsof.x86_64 0:4.87-6.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                              Arch                                         Version                                                  Repository                                                                    Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-server                                       x86_64                                       10.4.12_6-1.el7                                          /MariaDB-server-10.4.12_6-1.el7.x86_64                                       109 M
Installing for dependencies:
 lsof                                                 x86_64                                       4.87-6.el7                                               base                                                                         331 k

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package (+1 Dependent package)

Total size: 109 M
Total download size: 331 k
Installed size: 110 M
Downloading packages:
lsof-4.87-6.el7.x86_64.rpm                                                                                                                                                                                              | 331 kB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : lsof-4.87-6.el7.x86_64                                                                                                                                                                                                      1/2 
  Installing : MariaDB-server-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       2/2 
2020-03-04  4:48:07 server_audit: MariaDB Audit Plugin version 2.0.2 STARTED.
2020-03-04  4:48:07 server_audit: Query cache is enabled with the TABLE events. Some table reads can be veiled.
2020-03-04  4:48:08 server_audit: STOPPED


Two all-privilege accounts were created.
One is root@localhost, it has no password, but you need to
be system 'root' user to connect. Use, for example, sudo mysql
The second is mysql@localhost, it has no password either, but
you need to be the system 'mysql' user to connect.
After connecting you can set the password, if you would need to be
able to connect as any of these users with a password and without sudo

See the MariaDB Knowledgebase at http://mariadb.com/kb or the
MySQL manual for more instructions.

As a MariaDB Corporation subscription customer please contact us
via https://support.mariadb.com/ to report problems.
You also can get consultative guidance on questions specific to your deployment,
such as how to tune for performance, high availability, security audits, and code review.

You also find detailed documentation about how to use MariaDB Enterprise Server at https://mariadb.com/docs/.
The latest information about MariaDB Server is available at https://mariadb.com/kb/en/library/release-notes/.

  Verifying  : MariaDB-server-10.4.12_6-1.el7.x86_64                                                                                                                                                                                       1/2 
  Verifying  : lsof-4.87-6.el7.x86_64                                                                                                                                                                                                      2/2 

Installed:
  MariaDB-server.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                                                      

Dependency Installed:
  lsof.x86_64 0:4.87-6.el7                                                                                                                                                                                                                     

Complete!

[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm: MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64
Marking MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-columnstore-libs.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                                   Arch                                    Version                                             Repository                                                                         Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-columnstore-libs                                  x86_64                                  10.4.12_6-1.el7                                     /MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64                                   14 M

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package

Total size: 14 M
Installed size: 14 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64                                                                                                                                                                             1/1 
  Verifying  : MariaDB-columnstore-libs-10.4.12_6-1.el7.x86_64                                                                                                                                                                             1/1 

Installed:
  MariaDB-columnstore-libs.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                                            

Complete!

[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm: MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64
Marking MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-columnstore-platform.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                                     Arch                                  Version                                           Repository                                                                           Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-columnstore-platform                                x86_64                                10.4.12_6-1.el7                                   /MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64                                 11 M

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package

Total size: 11 M
Installed size: 11 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64                                                                                                                                                                         1/1 
The next step on the node that will become PM1:

postConfigure


  Verifying  : MariaDB-columnstore-platform-10.4.12_6-1.el7.x86_64                                                                                                                                                                         1/1 

Installed:
  MariaDB-columnstore-platform.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                                        

Complete!
[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
No such command: MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm. Please use /usr/bin/yum --help
[root@cs-61]# mariadb-enterprise-10.4.12-6-centos-7-x86_64-rpms]# yum -y install MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm
Loaded plugins: fastestmirror
Examining MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm: MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64
Marking MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package MariaDB-columnstore-engine.x86_64 0:10.4.12_6-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================================================================================================================================================
 Package                                                    Arch                                   Version                                            Repository                                                                          Size
===============================================================================================================================================================================================================================================
Installing:
 MariaDB-columnstore-engine                                 x86_64                                 10.4.12_6-1.el7                                    /MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64                                 1.4 M

Transaction Summary
===============================================================================================================================================================================================================================================
Install  1 Package

Total size: 1.4 M
Installed size: 1.4 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64                                                                                                                                                                           1/1 
  Verifying  : MariaDB-columnstore-engine-10.4.12_6-1.el7.x86_64                                                                                                                                                                           1/1 

Installed:
  MariaDB-columnstore-engine.x86_64 0:10.4.12_6-1.el7                                                                                                                                                                                          

Complete!
```

### Setup SSH

Generate SSH Keys on the Node 1 and copy it to the other nodes

```
[root@cs-61 ~]# sudo ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:LNoELZnh/3PIUBc12cSKKXb67vvOCiCIas1bu7Puz9A root@cs-61
The key's randomart image is:
+---[RSA 2048]----+
|    .     ..o=.  |
|   . =     ...o  |
|    * . . .o .   |
| . . + oo.+ .    |
|. . . *.S+       |
|. o  =.*..       |
|.. o.o.E*..      |
|.   o.+  +..     |
|   .o*=o o==+    |
+----[SHA256]-----+

[root@cs-61 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.56.62
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.62 (192.168.56.62)' can't be established.
ECDSA key fingerprint is SHA256:EeFtyGQ5pFX/BY/DSRLOBj7d4PNUVyoPcfcGqxS/XHc.
ECDSA key fingerprint is MD5:c5:58:a6:8f:4b:4e:4b:fc:ff:22:de:a3:f2:4a:2a:01.
Are you sure you want to continue connecting (yes/no)? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@192.168.56.62's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.56.62'"
and check to make sure that only the key(s) you wanted were added.

[root@cs-61 ~]# ssh 192.168.56.62
Last login: Wed Mar  4 05:24:31 2020 from 192.168.56.1
[root@cs-62 ~]# 

[root@cs-62 ~]# exit
logout
Connection to 192.168.56.62 closed.
```

Add the two node's host name and IP addresses in the **`/etc/hosts`** file of both nodes before proceeding

Test SSH to the second node using IP address and hostname, make sure it works without a password.

Installation loads software to the system. This software requires post-install actions and configuration before the database server is ready for use.

MariaDB ColumnStore post-installation scripts fail if they find MariaDB Enterprise Server running on the system. Stop the Server and disable the service after installing the packages:

```txt
[root@cs-61 ~]# systemctl stop mariadb.service
[root@cs-61 ~]# systemctl disable mariadb.service
```

Execute the post install script on the primary node

```txt
[root@cs-61 ~]# columnstore-post-install
The next step on the node that will become PM1:

postConfigure


[root@cs-61 ~]#
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

Enter password, hit 'enter' to default to using an ssh key, or 'exit' > 

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

Now check MariaDB status on both the nodes. It should be running as per normal

```txt
[root@cs-62 ~]# systemctl status mariadb
● mariadb.service - MariaDB 10.4.12-6 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Wed 2020-03-04 06:25:30 EST; 4min 25s ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 5152 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 5038 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`/usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 5036 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 5116 (mysqld)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─5116 /usr/sbin/mysqld

Mar 04 06:25:30 cs-62 mysqld[5116]: 2020-03-04  6:25:30 0 [Note] Added new Master_info '' to hash table
Mar 04 06:25:30 cs-62 mysqld[5116]: 2020-03-04  6:25:30 0 [Note] /usr/sbin/mysqld: ready for connections.
Mar 04 06:25:30 cs-62 mysqld[5116]: Version: '10.4.12-6-MariaDB-enterprise-log'  socket: '/var/lib/mysql/mysql.sock'  port: 3306  MariaDB Enterprise Server
Mar 04 06:25:30 cs-62 systemd[1]: Started MariaDB 10.4.12-6 database server.
Mar 04 06:25:35 cs-62 mysqld[5116]: 2020-03-04  6:25:35 10 [Note] Master connection name: ''  Master_info_file: 'master.info'  Relay_info_file: 'relay-log.info'
Mar 04 06:25:35 cs-62 mysqld[5116]: 2020-03-04  6:25:35 10 [Warning] Neither --relay-log nor --relay-log-index were used; so replication may break when this MySQL server acts as a slave and has his hostname changed!! P...void this problem.
Mar 04 06:25:35 cs-62 mysqld[5116]: 2020-03-04  6:25:35 10 [Note] 'CHANGE MASTER TO executed'. Previous state master_host='', master_port='3306', master_log_file='', master_log_pos='4'. New state master_host='192.168.5...er_log_pos='1918'.
Mar 04 06:25:35 cs-62 mysqld[5116]: 2020-03-04  6:25:35 12 [Note] Slave I/O thread: Start asynchronous replication to master 'idbrep@192.168.56.61:3306' in log 'cs-61-bin.000001' at position 1918
Mar 04 06:25:35 cs-62 mysqld[5116]: 2020-03-04  6:25:35 13 [Note] Slave SQL thread initialized, starting replication in log 'cs-61-bin.000001' at position 1918, relay log './cs-62-relay-bin.000001' position: 4
Mar 04 06:25:35 cs-62 mysqld[5116]: 2020-03-04  6:25:35 12 [Note] Slave I/O thread: connected to master 'idbrep@192.168.56.61:3306',replication started in log 'cs-61-bin.000001' at position 1918
Hint: Some lines were ellipsized, use -l to show in full.
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

Lets test replication between Node1 and Node2, Node1 should be the Master

```
MariaDB [(none)]> show databases;
+---------------------+
| Database            |
+---------------------+
| calpontsys          |
| columnstore_info    |
| infinidb_querystats |
| information_schema  |
| mysql               |
| performance_schema  |
+---------------------+
6 rows in set (0.009 sec)

MariaDB [(none)]> create database testdb;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| cs-61      |
+------------+
1 row in set (0.000 sec)
```

See the databases on Node 2 to see if the replication is done

```
MariaDB [(none)]> show databases;
+---------------------+
| Database            |
+---------------------+
| calpontsys          |
| columnstore_info    |
| infinidb_querystats |
| information_schema  |
| mysql               |
| performance_schema  |
| testdb              |
+---------------------+
7 rows in set (0.008 sec)

MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| cs-62      |
+------------+
1 row in set (0.000 sec)
```

Create a first columnstore table on Node 1 and see if  it's visible from Node 2

```
MariaDB [(none)]> use testdb;
Database changed
MariaDB [testdb]> create table cs_tab1(id int, c1 varchar(10)) engine=ColumnStore;
Query OK, 0 rows affected (2.096 sec)

MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| cs-61      |
+------------+
1 row in set (0.000 sec)
```

Verify on the Node 2

```
MariaDB [(none)]> use testdb;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [testdb]> show tables;
+------------------+
| Tables_in_testdb |
+------------------+
| cs_tab1          |
+------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| cs-62      |
+------------+
1 row in set (0.001 sec)
```

Now finally on Node 1 which is also the `PM1` node, test the ColumnStore `mcsadmin` commands

```
[root@cs-61 ~]# mcsadmin getSystemInfo
getsysteminfo   Wed Mar  4 06:38:04 2020

System columnstore-1

System and Module statuses

Component     Status                       Last Status Change
------------  --------------------------   ------------------------
System        ACTIVE                       Wed Mar  4 06:25:17 2020

Module pm1    ACTIVE                       Wed Mar  4 06:25:07 2020
Module pm2    ACTIVE                       Wed Mar  4 06:24:57 2020

Active Parent OAM Performance Module is 'pm1'
Primary Front-End MariaDB ColumnStore Module is 'pm1'
MariaDB ColumnStore Replication Feature is enabled

MariaDB ColumnStore Process statuses

Process             Module    Status            Last Status Change        Process ID
------------------  ------    ---------------   ------------------------  ----------
ProcessMonitor      pm1       ACTIVE            Wed Mar  4 06:23:39 2020       16570
ProcessManager      pm1       ACTIVE            Wed Mar  4 06:23:46 2020       16650
DBRMControllerNode  pm1       ACTIVE            Wed Mar  4 06:24:37 2020       17514
ServerMonitor       pm1       ACTIVE            Wed Mar  4 06:24:40 2020       17542
DBRMWorkerNode      pm1       ACTIVE            Wed Mar  4 06:24:40 2020       17571
PrimProc            pm1       ACTIVE            Wed Mar  4 06:24:44 2020       17668
ExeMgr              pm1       ACTIVE            Wed Mar  4 06:24:53 2020       18094
WriteEngineServer   pm1       ACTIVE            Wed Mar  4 06:24:58 2020       18221
DDLProc             pm1       ACTIVE            Wed Mar  4 06:25:06 2020       18525
DMLProc             pm1       ACTIVE            Wed Mar  4 06:25:16 2020       18766
mysqld              pm1       ACTIVE            Wed Mar  4 06:25:22 2020       19328

ProcessMonitor      pm2       ACTIVE            Wed Mar  4 06:24:26 2020        4517
ProcessManager      pm2       HOT_STANDBY       Wed Mar  4 06:24:32 2020        4569
DBRMControllerNode  pm2       COLD_STANDBY      Wed Mar  4 06:24:49 2020
ServerMonitor       pm2       ACTIVE            Wed Mar  4 06:24:44 2020        4705
DBRMWorkerNode      pm2       ACTIVE            Wed Mar  4 06:24:45 2020        4719
PrimProc            pm2       ACTIVE            Wed Mar  4 06:24:48 2020        4742
ExeMgr              pm2       ACTIVE            Wed Mar  4 06:24:55 2020        4822
WriteEngineServer   pm2       ACTIVE            Wed Mar  4 06:24:59 2020        4848
DDLProc             pm2       COLD_STANDBY      Wed Mar  4 06:24:57 2020
DMLProc             pm2       COLD_STANDBY      Wed Mar  4 06:24:57 2020
mysqld              pm2       ACTIVE            Wed Mar  4 06:25:30 2020        5116

Active Alarm Counts: Critical = 0, Major = 0, Minor = 0, Warning = 0, Info = 0
```

ColumnStore service can be shutdown normally using the `mcsadmin shutdownsystem y` command

```
[root@cs-61 ~]# mcsadmin shutdownsystem y
shutdownsystem   Wed Mar  4 06:42:47 2020

This command stops the processing of applications on all Modules within the MariaDB ColumnStore System

   Checking for active transactions

   Stopping System...
   Successful stop of System 

   Shutting Down System...
   Successful shutdown of System 
```

This will shutdown MariaDB and ColumnStore on all the nodes automatically.

