# XPAND With MariaDB X5

Setup 3 EC2 instances (RHEL 7.6)

- ssh -i "CentOS.pem" centos@ec2-13-212-128-120.ap-southeast-1.compute.amazonaws.com
- ssh -i "CentOS.pem" centos@ec2-18-141-195-239.ap-southeast-1.compute.amazonaws.com
- ssh -i "CentOS.pem" centos@ec2-13-212-131-111.ap-southeast-1.compute.amazonaws.com

***Note:** All the following steps are to be done on all the nodes unless otherwise specified*
***Note:** The filesystem on all the nodes must be `ext4`*

## Assumptions

- SELinux and firewalld has to be disabled
- the nodes should be able to communicate with each other
- filesystem on all the nodes used is `ext4` others are not supported by Xpand as shown here
  ```
  =====   ERROR:   =====
  Filesystem 'xfs' on /data/clustrix (mount point: /) is not supported.
    Suggest using ext4 filesystem
  ======================
  ```

For more details, refer to <https://mariadb.com/docs/deploy/xpand-node/>

## Installation

Install Dependencies

for RHEL 7
- sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
- sudo yum-config-manager --enable rhui-REGION-rhel-server-optional

for CentOS 7
- sudo yum -y install epel-release

After installing epel-release and optional packages, install the dependencies.

```
[shell]$ sudo yum -y install bzip2 xz wget screen ntp ntpdate htop mdadm

Dependencies Resolved

==============================================================================================================================================================================================================================================================
 Package                                                      Arch                                           Version                                                                    Repository                                                       Size
==============================================================================================================================================================================================================================================================
Installing:
 bzip2                                                        x86_64                                         1.0.6-13.el7                                                               rhel-7-server-rhui-rpms                                          52 k
 htop                                                         x86_64                                         2.2.0-3.el7                                                                epel                                                            103 k
 mdadm                                                        x86_64                                         4.1-4.el7                                                                  rhel-7-server-rhui-rpms                                         439 k
 ntp                                                          x86_64                                         4.2.6p5-29.el7_8.2                                                         rhel-7-server-rhui-rpms                                         549 k
 ntpdate                                                      x86_64                                         4.2.6p5-29.el7_8.2                                                         rhel-7-server-rhui-rpms                                          87 k
 screen                                                       x86_64                                         4.1.0-0.25.20120314git3c2946.el7                                           rhel-7-server-rhui-rpms                                         552 k
 wget                                                         x86_64                                         1.14-18.el7_6.1                                                            rhel-7-server-rhui-rpms                                         547 k
Installing for dependencies:
 autogen-libopts                                              x86_64                                         5.18-5.el7                                                                 rhel-7-server-rhui-rpms                                          66 k
 libreport-filesystem                                         x86_64                                         2.1.11-53.el7                                                              rhel-7-server-rhui-rpms                                          41 k

Transaction Summary
==============================================================================================================================================================================================================================================================
Install  7 Packages (+2 Dependent packages)
Installed:
  bzip2.x86_64 0:1.0.6-13.el7    htop.x86_64 0:2.2.0-3.el7    mdadm.x86_64 0:4.1-4.el7    ntp.x86_64 0:4.2.6p5-29.el7_8.2    ntpdate.x86_64 0:4.2.6p5-29.el7_8.2    screen.x86_64 0:4.1.0-0.25.20120314git3c2946.el7    wget.x86_64 0:1.14-18.el7_6.1   

Dependency Installed:
  autogen-libopts.x86_64 0:5.18-5.el7                                                                                       libreport-filesystem.x86_64 0:2.1.11-53.el7                                                                                      

Complete!
```

Enable NTP process on all three nodes

```
[shell]$ sudo systemctl start ntpd
[shell]$ sudo systemctl enable ntpd
```

## Download the XPAND binaries

Download the XPAND Binaries from <https://dlm.mariadb.com/1154560/xpand-staging/xpand-5.3.11/xpand-5.3.11_rc.el7.tar.bz2> and transfer to all the Xpand nodes

Once transferred, un-tar the file and install.

```
[shell]$ wget https://dlm.mariadb.com/3d8175a3-5418-49d1-bdb4-cec450ed92df/1154560/xpand-staging/xpand-5.3.11/xpand-5.3.11_rc.el7.tar.bz2

[shell]$ ls -rlt
total 128816
-rwxr-xr-x 1 root root 131905837 Sep 28 06:31 xpand-5.3.11_rc.el7.tar.bz2

[shell]$ tar -xvf xpand-5.3.11_rc.el7.tar.bz2
xpand-5.3.11_rc.el7/
xpand-5.3.11_rc.el7/xpand-xpdnode-5.3.11_rc-1.el7.x86_64.rpm
xpand-5.3.11_rc.el7/clxdbi-combined-2.2.1-962.el7.tar.bz2
xpand-5.3.11_rc.el7/README
xpand-5.3.11_rc.el7/clxgui-combined-2.2.1-703.el7.tar.bz2
xpand-5.3.11_rc.el7/xpand-common-glassbutte-1068.el7.x86_64.rpm
xpand-5.3.11_rc.el7/xpand-utils-5.3.11_rc-1.el7.x86_64.rpm
xpand-5.3.11_rc.el7/clxgui_configure.sh
xpand-5.3.11_rc.el7/clxdbi_configure.sh
xpand-5.3.11_rc.el7/LICENSE-SWDL
xpand-5.3.11_rc.el7/checksums.md5
xpand-5.3.11_rc.el7/xpdnode_install.py
```

### Install the XPAND binaries

Installing Xpand binaries on all the nodes as follows

```
[shell]$ cd xpand-5.3.11_rc.el7
[shell]$ sudo ./xpdnode_install.py --mysql-port 5001 --force

=== Warning: ===
DATA_PATH should not be on the same storage volume (/) as ROOT.
================


=== Warning: ===
LOG_PATH should not be on the same storage volume (/) as DATA_PATH.
================


MariaDB Xpand successfully configured!
Loaded plugins: amazon-id, rhui-lb, search-disabled-repos
Examining /home/ec2-user/xpand-5.3.11_rc.el7/xpand-common-glassbutte-1068.el7.x86_64.rpm: xpand-common-glassbutte-1068.el7.x86_64
Marking /home/ec2-user/xpand-5.3.11_rc.el7/xpand-common-glassbutte-1068.el7.x86_64.rpm to be installed
Resolving Dependencies

==============================================================================================================================================================================================================================================================
 Package                                                       Arch                                          Version                                                    Repository                                                                       Size
==============================================================================================================================================================================================================================================================
Installing:
 xpand-common                                                  x86_64                                        glassbutte-1068.el7                                        /xpand-common-glassbutte-1068.el7.x86_64                                         44 M
Installing for dependencies:
 MySQL-python                                                  x86_64                                        1.2.5-1.el7                                                rhui-REGION-rhel-server-releases                                                 90 k
 libaio                                                        x86_64                                        0.3.109-13.el7                                             rhui-REGION-rhel-server-releases                                                 24 k
 libdwarf                                                      x86_64                                        20130207-4.el7                                             rhui-REGION-rhel-server-releases                                                109 k
 libdwarf-tools                                                x86_64                                        20130207-4.el7                                             rhui-REGION-rhel-server-optional                                                161 k
 libicu                                                        x86_64                                        50.2-4.el7_7                                               rhui-REGION-rhel-server-releases                                                6.9 M
 mariadb                                                       x86_64                                        1:5.5.65-1.el7                                             rhui-REGION-rhel-server-releases                                                9.0 M
 perl                                                          x86_64                                        4:5.16.3-295.el7                                           rhui-REGION-rhel-server-releases                                                8.0 M
 perl-Carp                                                     noarch                                        1.26-244.el7                                               rhui-REGION-rhel-server-releases                                                 19 k
 perl-Encode                                                   x86_64                                        2.51-7.el7                                                 rhui-REGION-rhel-server-releases                                                1.5 M
 perl-Exporter                                                 noarch                                        5.68-3.el7                                                 rhui-REGION-rhel-server-releases                                                 28 k
 perl-File-Path                                                noarch                                        2.09-2.el7                                                 rhui-REGION-rhel-server-releases                                                 27 k
 perl-File-Temp                                                noarch                                        0.23.01-3.el7                                              rhui-REGION-rhel-server-releases                                                 56 k
 perl-Filter                                                   x86_64                                        1.49-3.el7                                                 rhui-REGION-rhel-server-releases                                                 76 k
 perl-Getopt-Long                                              noarch                                        2.40-3.el7                                                 rhui-REGION-rhel-server-releases                                                 56 k
 perl-HTTP-Tiny                                                noarch                                        0.033-3.el7                                                rhui-REGION-rhel-server-releases                                                 38 k
 perl-PathTools                                                x86_64                                        3.40-5.el7                                                 rhui-REGION-rhel-server-releases                                                 83 k
 perl-Pod-Escapes                                              noarch                                        1:1.04-295.el7                                             rhui-REGION-rhel-server-releases                                                 51 k
 perl-Pod-Perldoc                                              noarch                                        3.20-4.el7                                                 rhui-REGION-rhel-server-releases                                                 87 k
 perl-Pod-Simple                                               noarch                                        1:3.28-4.el7                                               rhui-REGION-rhel-server-releases                                                216 k
 perl-Pod-Usage                                                noarch                                        1.63-3.el7                                                 rhui-REGION-rhel-server-releases                                                 27 k
 perl-Scalar-List-Utils                                        x86_64                                        1.27-248.el7                                               rhui-REGION-rhel-server-releases                                                 36 k
 perl-Socket                                                   x86_64                                        2.010-5.el7                                                rhui-REGION-rhel-server-releases                                                 49 k
 perl-Storable                                                 x86_64                                        2.45-3.el7                                                 rhui-REGION-rhel-server-releases                                                 77 k
 perl-Text-ParseWords                                          noarch                                        3.29-4.el7                                                 rhui-REGION-rhel-server-releases                                                 14 k
 perl-Time-HiRes                                               x86_64                                        4:1.9725-3.el7                                             rhui-REGION-rhel-server-releases                                                 45 k
 perl-Time-Local                                               noarch                                        1.2300-2.el7                                               rhui-REGION-rhel-server-releases                                                 24 k
 perl-constant                                                 noarch                                        1.27-2.el7                                                 rhui-REGION-rhel-server-releases                                                 19 k
 perl-libs                                                     x86_64                                        4:5.16.3-295.el7                                           rhui-REGION-rhel-server-releases                                                689 k
 perl-macros                                                   x86_64                                        4:5.16.3-295.el7                                           rhui-REGION-rhel-server-releases                                                 44 k
 perl-parent                                                   noarch                                        1:0.225-244.el7                                            rhui-REGION-rhel-server-releases                                                 12 k
 perl-podlators                                                noarch                                        2.5.1-3.el7                                                rhui-REGION-rhel-server-releases                                                112 k
 perl-threads                                                  x86_64                                        1.87-4.el7                                                 rhui-REGION-rhel-server-releases                                                 49 k
 perl-threads-shared                                           x86_64                                        1.43-6.el7                                                 rhui-REGION-rhel-server-releases                                                 39 k
 psmisc                                                        x86_64                                        22.20-16.el7                                               rhui-REGION-rhel-server-releases                                                141 k
 yajl                                                          x86_64                                        2.0.4-4.el7                                                rhui-REGION-rhel-server-releases                                                 39 k
Updating for dependencies:
 mariadb-libs                                                  x86_64                                        1:5.5.65-1.el7                                             rhui-REGION-rhel-server-releases                                                759 k

Transaction Summary
==============================================================================================================================================================================================================================================================

Complete!

Loaded plugins: amazon-id, rhui-lb, search-disabled-repos
Examining /home/ec2-user/xpand-5.3.11_rc.el7/xpand-xpdnode-5.3.11_rc-1.el7.x86_64.rpm: xpand-xpdnode-5.3.11_rc-1.el7.x86_64
Marking /home/ec2-user/xpand-5.3.11_rc.el7/xpand-xpdnode-5.3.11_rc-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package xpand-xpdnode.x86_64 0:5.3.11_rc-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================================================================================================================================================
 Package                                                  Arch                                              Version                                                    Repository                                                                        Size
==============================================================================================================================================================================================================================================================
Installing:
 xpand-xpdnode                                            x86_64                                            5.3.11_rc-1.el7                                            /xpand-xpdnode-5.3.11_rc-1.el7.x86_64                                            333 M

Transaction Summary
==============================================================================================================================================================================================================================================================

Complete!

Loaded plugins: amazon-id, rhui-lb, search-disabled-repos
Examining /home/ec2-user/xpand-5.3.11_rc.el7/xpand-utils-5.3.11_rc-1.el7.x86_64.rpm: xpand-utils-5.3.11_rc-1.el7.x86_64
Marking /home/ec2-user/xpand-5.3.11_rc.el7/xpand-utils-5.3.11_rc-1.el7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package xpand-utils.x86_64 0:5.3.11_rc-1.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================================================================================================================================================
 Package                                                 Arch                                               Version                                                     Repository                                                                       Size
==============================================================================================================================================================================================================================================================
Installing:
 xpand-utils                                             x86_64                                             5.3.11_rc-1.el7                                             /xpand-utils-5.3.11_rc-1.el7.x86_64                                              15 M

Transaction Summary
==============================================================================================================================================================================================================================================================
                                                                                                          

Complete!

MariaDB Xpand RPMs installed successfully
MariaDB Xpand service started... Please wait for the database to
  initialize (This will take a minute.)
.......................
MariaDB Xpand initialized.

MariaDB Xpand is now ready for use.
checking options
setting config path
reading settings from /etc/clustrix/clxdbi.conf
reading settings from environment
checking settings from /etc/clustrix/clxnode.conf
checking built-in default settings
settings complete
checking /etc/clustrix
checking /etc/clustrix/clxdbi.conf
writing config
seeking local archive
found ./clxdbi-combined-2.2.1-962.el7.tar.bz2
probing for existing /opt/clustrix/clxdbi
checking /var/tmp/clxdbi-extract-1601319180
extracting ./clxdbi-combined-2.2.1-962.el7.tar to /var/tmp/clxdbi-extract-1601319180
checking /opt/clustrix/clxdbi
extracting clxdbi to /opt/clustrix/clxdbi
extracting common code to /opt/clustrix/clxui-common
cleaning up /var/tmp/clxdbi-extract-1601319180
using install opts --start
installing
no log file, buffering log output

starting clxdbi installation
warning: vendor/rpm/libpcap-1.5.3-8.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
installing rpms
Failed to set locale, defaulting to C
updating links...
links updated
starting server
preparing clxdbi for first run
/opt/clustrix/clxdbi/vendor/bundle/ruby/2.6.0/gems/get_process_mem-0.2.1/lib/get_process_mem.rb:10: warning: BigDecimal.new is deprecated; use BigDecimal() method instead.
linking to clustrixdb nanny
clxdbi install completed
checking /etc/logrotate.d
adding /etc/logrotate.d/clxdbi
writing tmpfiles conf
checking options
setting config path
reading settings from /etc/clustrix/clxgui.conf
reading settings from environment
checking built-in default settings
settings complete
checking /etc/clustrix
checking /etc/clustrix/clxgui.conf
writing config
seeking local archive
found ./clxgui-combined-2.2.1-703.el7.tar.bz2
probing for existing /opt/clustrix/clxgui
checking /var/tmp/clxgui-extract-1601319219
extracting ./clxgui-combined-2.2.1-703.el7.tar to /var/tmp/clxgui-extract-1601319219
checking /opt/clustrix/clxgui
extracting clxgui to /opt/clustrix/clxgui
extracting common code to /opt/clustrix/clxui-common
cleaning up /var/tmp/clxgui-extract-1601319219
using install opts --start
installing

starting clxgui installation
warning: vendor/rpm/libxslt-1.1.28-5.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
rpms already installed
updating links...done
starting server
preparing clxgui for first run
linking to clustrixdb nanny
clxgui install completed
checking /etc/logrotate.d
adding /etc/logrotate.d/clxgui
writing tmpfiles conf

*** This Node's IP (Needed later during cluster configuration): 172.31.20.172
For easiest use of the `clx` cluster management tool, configure passwordless ssh between all nodes for these users: xpand, xpandm
```

MariaDB Xpand engine is installed successfully, now we can install the MariaDB server and the Xpand plugin.

## Install MariaDB 10.5 Enterprise

Install MariaDB Enterprise server & XPAND plugin on all the nodes.

```
[shell]$ sudo yum -y install MariaDB-server MariaDB-backup MariaDB-xpand-engine

Dependencies Resolved

==============================================================================================================================================================================================================================================================
 Package                                                             Arch                                               Version                                                     Repository                                                           Size
==============================================================================================================================================================================================================================================================
Installing:
 MariaDB-backup                                                      x86_64                                             10.5.5_3-1.el7                                              mariadb-es-main                                                     7.0 M
 MariaDB-server                                                      x86_64                                             10.5.5_3-1.el7                                              mariadb-es-main                                                      21 M
 MariaDB-xpand-engine                                                x86_64                                             10.5.5_3-1.el7                                              mariadb-es-main                                                      67 k
Installing for dependencies:
 boost-program-options                                               x86_64                                             1.53.0-28.el7                                               rhel-7-server-rhui-rpms                                             156 k
 galera-enterprise-4                                                 x86_64                                             26.4.5-1.el7.8                                              mariadb-es-main                                                     9.9 M
 lsof                                                                x86_64                                             4.87-6.el7                                                  rhel-7-server-rhui-rpms                                             331 k
 perl-Compress-Raw-Bzip2                                             x86_64                                             2.061-3.el7                                                 rhel-7-server-rhui-rpms                                              32 k
 perl-Compress-Raw-Zlib                                              x86_64                                             1:2.061-4.el7                                               rhel-7-server-rhui-rpms                                              57 k
 perl-DBI                                                            x86_64                                             1.627-4.el7                                                 rhel-7-server-rhui-rpms                                             802 k
 perl-Data-Dumper                                                    x86_64                                             2.145-3.el7                                                 rhel-7-server-rhui-rpms                                              47 k
 perl-IO-Compress                                                    noarch                                             2.061-2.el7                                                 rhel-7-server-rhui-rpms                                             260 k
 perl-Net-Daemon                                                     noarch                                             0.48-5.el7                                                  rhel-7-server-rhui-rpms                                              51 k
 perl-PlRPC                                                          noarch                                             0.2020-14.el7                                               rhel-7-server-rhui-rpms                                              36 k
 socat                                                               x86_64                                             1.7.3.2-2.el7                                               rhel-7-server-rhui-rpms                                             290 k

Transaction Summary
==============================================================================================================================================================================================================================================================
...
...
Dependency Installed:
  boost-program-options.x86_64 0:1.53.0-28.el7  galera-enterprise-4.x86_64 0:26.4.5-1.el7.8  lsof.x86_64 0:4.87-6.el7             perl-Compress-Raw-Bzip2.x86_64 0:2.061-3.el7  perl-Compress-Raw-Zlib.x86_64 1:2.061-4.el7  perl-DBI.x86_64 0:1.627-4.el7 
  perl-Data-Dumper.x86_64 0:2.145-3.el7         perl-IO-Compress.noarch 0:2.061-2.el7        perl-Net-Daemon.noarch 0:0.48-5.el7  perl-PlRPC.noarch 0:0.2020-14.el7             socat.x86_64 0:1.7.3.2-2.el7                

Complete!
```

This is a combined setup, with MariaDB ES and Xpand engine running on the same server, To connect to the Xpand backend node, we can use the Xpand socket `mariadb --socket /data/clustrix/mysql.sock` and to connect to the MariaDB node, we can directly connect without any socket parameter.

***Note:** The following is to be done only on the 1st Xpand node!*

First thing to do would be to install the license provided by the MariaDB team using the `set global license='JSON Text';` syntax. This needs to be done on the Xpand node directly and not on the MariaDB server.

```
[shell]$ sudo mariadb --socket /data/clustrix/mysql.sock

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 37889
Server version: 5.0.45-Xpand-5.3.11_rc 

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> set global license='{"expiration":"2020-11-01 00:00:00","maxnodes":"3","company":"MariaDB","maxcores":"32","email":"Faisal.Saeed@mariadb.com","person":"Faisal Saeed","signature":"...signature_key_string..."}';
Query OK, 0 rows affected (0.024 sec)
```

Set the password for the user xpand@'%' and xpand@'localhost' and set the required grants for Xpand plugin

```
MySQL [(none)]> grant all on *.* to xpand@'%';
Query OK, 0 rows affected (0.005 sec)

MySQL [(none)]> set password for xpand@'%' = password('SecretPassword');
Query OK, 0 rows affected (0.005 sec)

MySQL [(none)]> grant all on *.* to xpand@'localhost';
Query OK, 0 rows affected (0.005 sec)

MySQL [(none)]> set password for xpand@'localhost' = password('SecretPassword');
Query OK, 0 rows affected (0.005 sec)
```

Edit the `/etc/my.cnf.d/xpand.cnf` file and add the Xpand plugin details followed by a `systemctl restart mariadb` on **all** the nodes.

```
[mariadb]
plugin_load_add = ha_xpand.so
plugin_maturity = gamma
xpand_hosts = 127.0.0.1
xpand_port = 5001
xpand_username = xpand
xpand_password = SecretPassword
```

This will set up xpand plugin, define the xpand local host name, xpand port that we define will installing Xpand node and the xpand user name/password

Once MariaDB has been restarted, we can now connect to the enterprise server using the MariaDB command line. 

```
[ec2-user@ip-172-31-20-172 ~]$ sudo mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.5.5-3-MariaDB-enterprise MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show engines;
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                                         | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| XPAND              | YES     | Xpand storage engine                                                                            | YES          | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
9 rows in set (0.000 sec)

MariaDB [(none)]> show plugins;
+-------------------------------+----------+---------------------+--------------------------+---------+
| Name                          | Status   | Type                | Library                  | License |
+-------------------------------+----------+---------------------+--------------------------+---------+
| binlog                        | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| mysql_native_password         | ACTIVE   | AUTHENTICATION      | NULL                     | GPL     |
| mysql_old_password            | ACTIVE   | AUTHENTICATION      | NULL                     | GPL     |
| CSV                           | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| MEMORY                        | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| Aria                          | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| MyISAM                        | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| MRG_MyISAM                    | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| SPATIAL_REF_SYS               | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| GEOMETRY_COLUMNS              | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| inet6                         | ACTIVE   | DATA TYPE           | NULL                     | GPL     |
| inet_aton                     | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| inet_ntoa                     | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| inet6_aton                    | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| inet6_ntoa                    | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| is_ipv4                       | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| is_ipv6                       | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| is_ipv4_compat                | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| is_ipv4_mapped                | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| CLIENT_STATISTICS             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INDEX_STATISTICS              | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| TABLE_STATISTICS              | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| USER_STATISTICS               | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| wsrep                         | ACTIVE   | FUNCTION            | NULL                     | GPL     |
| SQL_SEQUENCE                  | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| InnoDB                        | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| INNODB_TRX                    | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_LOCKS                  | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_LOCK_WAITS             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_CMP                    | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_CMP_RESET              | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_CMPMEM                 | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_CMPMEM_RESET           | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_CMP_PER_INDEX          | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_CMP_PER_INDEX_RESET    | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_BUFFER_PAGE            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_BUFFER_PAGE_LRU        | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_BUFFER_POOL_STATS      | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_METRICS                | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_FT_DEFAULT_STOPWORD    | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_FT_DELETED             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_FT_BEING_DELETED       | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_FT_CONFIG              | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_FT_INDEX_CACHE         | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_FT_INDEX_TABLE         | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_TABLES             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_TABLESTATS         | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_INDEXES            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_COLUMNS            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_FIELDS             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_FOREIGN            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_FOREIGN_COLS       | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_TABLESPACES        | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_DATAFILES          | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_VIRTUAL            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_MUTEXES                | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_SYS_SEMAPHORE_WAITS    | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| INNODB_TABLESPACES_ENCRYPTION | ACTIVE   | INFORMATION SCHEMA  | NULL                     | BSD     |
| PERFORMANCE_SCHEMA            | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| SEQUENCE                      | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| unix_socket                   | ACTIVE   | AUTHENTICATION      | NULL                     | GPL     |
| FEEDBACK                      | DISABLED | INFORMATION SCHEMA  | NULL                     | GPL     |
| user_variables                | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| THREAD_POOL_GROUPS            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| THREAD_POOL_QUEUES            | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| THREAD_POOL_STATS             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| THREAD_POOL_WAITS             | ACTIVE   | INFORMATION SCHEMA  | NULL                     | GPL     |
| partition                     | ACTIVE   | STORAGE ENGINE      | NULL                     | GPL     |
| SERVER_AUDIT                  | ACTIVE   | AUDIT               | server_audit2.so         | GPL     |
| DISKS                         | ACTIVE   | INFORMATION SCHEMA  | disks.so                 | GPL     |
| ed25519                       | ACTIVE   | AUTHENTICATION      | auth_ed25519.so          | GPL     |
| simple_password_check         | ACTIVE   | PASSWORD VALIDATION | simple_password_check.so | GPL     |
| XPAND                         | ACTIVE   | STORAGE ENGINE      | ha_xpand.so              | GPL     |
+-------------------------------+----------+---------------------+--------------------------+---------+
73 rows in set (0.001 sec)
```

We can see the Xpand engine and Xpand plugin is available, time to create a test table and see if it works.

```
MariaDB [testdb]> create table tab(id serial, c1 varchar(100)) engine=xpand;
Query OK, 0 rows affected (0.013 sec)

MariaDB [testdb]> show create table tab\G
*************************** 1. row ***************************
       Table: tab
Create Table: CREATE TABLE `tab` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `c1` varchar(100) DEFAULT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=XPAND DEFAULT CHARSET=latin1
1 row in set (0.007 sec)

MariaDB [testdb]> insert into tab(c1) values('Data 1'), ('Data 2'), ('Data 3');
Query OK, 3 rows affected (0.013 sec)
Records: 3  Duplicates: 0  Warnings: 0

MariaDB [testdb]> select * from tab;
+----+--------+
| id | c1     |
+----+--------+
|  1 | Data 1 |
|  2 | Data 2 |
|  3 | Data 3 |
+----+--------+
3 rows in set (0.003 sec)
```

Everything looks good, now we will repeat the same steps for the other nodes and the exact same config file.

Once Xpand nodes are started on all the other nodes in the cluster, connect to Xpand node using Xpand socket and add the other nodes to the cluster

## Setting up the Xpand Cluster

Now that the 1st node is working fine and the other two nodes area ready with MairaDB Enterprise + Xpand Plugin already installed along with Xpand nodes, we can add these two nodes to the Xpand cluster as per follows

Login to the 1st Xpand node using Xpand socket and run the `ALTER CLUSTER ADD 'IP for Node 2', 'IP for Node 3;`

***Note:** This is to be done only on the 1st node where "license" was added*

```
[shell]$ sudo mariadb --socket /data/clustrix/mysql.sock
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 21505
Server version: 5.0.45-Xpand-5.3.11_rc 

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> ALTER CLUSTER ADD '172.31.11.174', '172.31.1.222';
Query OK, 0 rows affected (0.010 sec)
```

Now the cluster is ready, lets verify 

```
[shell]$ sudo /opt/clustrix/bin/clx stat
Cluster Name:    clf7f2bdd19062ac74
Cluster Version: 5.3.11_rc
Cluster Status:   OK 
Cluster Size:    3 nodes - 2 CPUs per Node
Current Node:    ip-172-31-11-253 - nid 1
nid |      Hostname     | Status |   IP Address   | TPS |      Used      | Total 
----+-------------------+--------+----------------+-----+----------------+-------
  1 |  ip-172-31-11-253 |    OK  |  172.31.11.253 |   0 |  20.7M (0.14%) |  14.9G
  2 |   ip-172-31-1-222 |    OK  |   172.31.1.222 |   0 |   9.2M (0.06%) |  14.9G
  3 |  ip-172-31-11-174 |    OK  |  172.31.11.174 |   0 |   9.2M (0.06%) |  14.9G
----+-------------------+--------+----------------+-----+----------------+-------
                                                      0 |  39.1M (0.09%) |  44.6G
```

This confirms that the Xpand is running as a 3 node cluster. Next thing to do would be to set up MariaDB native replication so that the schema can be synchronized between all the MariaDB nodes because that is going to be our front-end for the application connections.

But for now, we can manually create the database `testdb` on all the MariaDB nodes and the table will appear under it automatically.

```
MariaDB [(none)]> create database testdb;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> use testdb;
Database changed

MariaDB [testdb]> show tables;
+------------------+
| Tables_in_testdb |
+------------------+
| tab              |
+------------------+
1 row in set (0.005 sec)
```

this confirms that the table `tab` has already been replicated on all the xpand nodes natively, when we get the standard MariaDB replication going, it will work seamlessly on all MariaDB nodes without us needing to create the databases manually.

## MariaDB Replication Setup

Xpand nodes replication is automatically handled by Xpand engine natively and we don't need to worry about that since we already did the `ALTER CLUSTER ADD ...` this starts to replicate data internally on the Xpand nodes.

We now need to setup replication for the meta-data so that the databases and non Xpand tables, InnoDB, and other objects like databases can be synchronised.

...
...
// TODO //

### Thanks!