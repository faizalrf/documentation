# MariaDB Enterprise Server 10.6

This guide discusses how to Install MariaDB enterprise using `**localinstall**` without internet access on the database servers.

## Assumptions

- 1 x RHEL 7/8 VM or Servers are available with `root` user access
- Latest MariaDB 10.6 ES RPM package already downloaded to the servers

## Install MariaDB 10.6

To install MariaDB, we need a `root` user account. Extract the RPM tar package to `/tmp` folder.

- Downloads
  - MariaDB <https://mariadb.com/downloads/enterprise/enterprise-server/>
  - MaxScale <https://mariadb.com/downloads/enterprise/enterprise-maxscale/>

Download the OS appropriate package from the above links and transfer to the respective servers.

Untar the rpm package 

```
[server1 tmp]# ls -lrt maria*
-rw-r--r--. 1 ec2-user ec2-user 85094400 Feb  8 13:47 mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms.tar

[server1 tmp]# tar -xvf mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms.tar
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-shared-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-spider-engine-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-columnstore-cmapi-23.02.4.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/README
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/setup_repository
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/jemalloc-devel-5.2.1-2.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-s3-engine-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-columnstore-engine-10.6.14_9_23.02.4-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-client-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-gssapi-server-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-server-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-common-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-hashicorp-key-management-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/jemalloc-5.2.1-2.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-cracklib-password-check-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/f62625d60df41bde682279891d4cd12bb70251b63639a9ddb9a2830cb8269194-filelists.sqlite.bz2
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/4a49637cf127c2a38036b85610a9e14bc62b89905e6430c208cd10ba0a330217-primary.xml.gz
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/2ee51f65c2785b129fab5e2213da4611ada171e2f561157ab21d8e1d04a26c39-primary.sqlite.bz2
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/380035f82fee2bb6086796e805ccd9f0724fcf4a64fef9d31463fb116ece55da-other.xml.gz
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/6a0c438d66ef82ba464050a432021cfbfc06979a9dbf7c9027f2336ef55011da-other.sqlite.bz2
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/83aa4bfa7e4ed056dea6fb87ec14bddbd269675340a29941852260f18efdb0a8-filelists.xml.gz
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/repodata/repomd.xml
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-rocksdb-engine-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-compat-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-devel-10.6.14_9-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/galera-enterprise-4-26.4.14-1.el8.x86_64.rpm
mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms/MariaDB-backup-10.6.14_9-1.el8.x86_64.rpm
```

Go to the extracted folder verify the listing.

```
[root@ip-172-31-30-37 mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms]# ls -rlt
total 123712
-rw-rw-r--. 1 1002 1002   445324 Jul  2 22:54 MariaDB-spider-engine-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002   128724 Jul  2 22:54 MariaDB-shared-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002 20747900 Jul  2 22:54 MariaDB-server-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002   932940 Jul  2 22:54 MariaDB-s3-engine-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002  6199192 Jul  2 22:54 MariaDB-rocksdb-engine-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002    40860 Jul  2 22:54 MariaDB-hashicorp-key-management-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002    14888 Jul  2 22:54 MariaDB-gssapi-server-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002  1487636 Jul  2 22:54 MariaDB-devel-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002    12308 Jul  2 22:54 MariaDB-cracklib-password-check-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002  2262668 Jul  2 22:54 MariaDB-compat-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002    90288 Jul  2 22:54 MariaDB-common-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002  9773916 Jul  2 22:54 MariaDB-columnstore-engine-10.6.14_9_23.02.4-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002 65680808 Jul  2 22:54 MariaDB-columnstore-cmapi-23.02.4.x86_64.rpm
-rw-rw-r--. 1 1002 1002  9232112 Jul  2 22:54 MariaDB-client-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002  7621396 Jul  2 22:54 MariaDB-backup-10.6.14_9-1.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002    90620 Jul  2 22:54 jemalloc-devel-5.2.1-2.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002   233524 Jul  2 22:54 jemalloc-5.2.1-2.el8.x86_64.rpm
-rw-rw-r--. 1 1002 1002  1630828 Jul  2 22:54 galera-enterprise-4-26.4.14-1.el8.x86_64.rpm
-rwxrwxr-x. 1 1002 1002     1057 Jul  2 22:54 setup_repository
drwxrwxr-x. 2 1002 1002     4096 Jul  2 22:54 repodata
-rw-rw-r--. 1 1002 1002     1791 Jul  2 22:54 README
```

Before installation, make sure that the Default linux repositories are configured for the dedependencies. These should point to `BaseOS` and `AppStream`. The following is on a RHEL 8.4 linux on AWS but your listing may warry, we just need to ensure that there are references of BaseOS and AppStream both. 

```
[root@ip-172-31-26-216 yum.repos.d]# egrep -i "appstream|baseos" *.repo
redhat-rhui-ha.repo:[rhel-8-appstream-rhui-debug-rpms]
redhat-rhui-ha.repo:name=Red Hat Enterprise Linux 8 for $basearch - AppStream from RHUI (Debug RPMs)
redhat-rhui-ha.repo:mirrorlist=https://rhui.REGION.aws.ce.redhat.com/pulp/mirror/content/dist/rhel8/rhui/$releasever/$basearch/appstream/debug
redhat-rhui-ha.repo:[rhel-8-appstream-rhui-rpms]
redhat-rhui-ha.repo:name=Red Hat Enterprise Linux 8 for $basearch - AppStream from RHUI (RPMs)
redhat-rhui-ha.repo:mirrorlist=https://rhui.REGION.aws.ce.redhat.com/pulp/mirror/content/dist/rhel8/rhui/$releasever/$basearch/appstream/os
redhat-rhui-ha.repo:[rhel-8-appstream-rhui-source-rpms]
redhat-rhui-ha.repo:name=Red Hat Enterprise Linux 8 for $basearch - AppStream from RHUI (Source RPMs)
redhat-rhui-ha.repo:mirrorlist=https://rhui.REGION.aws.ce.redhat.com/pulp/mirror/content/dist/rhel8/rhui/$releasever/$basearch/appstream/source/SRPMS
redhat-rhui-ha.repo:[rhel-8-baseos-rhui-debug-rpms]
redhat-rhui-ha.repo:name=Red Hat Enterprise Linux 8 for $basearch - BaseOS from RHUI (Debug RPMs)
redhat-rhui-ha.repo:mirrorlist=https://rhui.REGION.aws.ce.redhat.com/pulp/mirror/content/dist/rhel8/rhui/$releasever/$basearch/baseos/debug
redhat-rhui-ha.repo:[rhel-8-baseos-rhui-rpms]
redhat-rhui-ha.repo:name=Red Hat Enterprise Linux 8 for $basearch - BaseOS from RHUI (RPMs)
redhat-rhui-ha.repo:mirrorlist=https://rhui.REGION.aws.ce.redhat.com/pulp/mirror/content/dist/rhel8/rhui/$releasever/$basearch/baseos/os
redhat-rhui-ha.repo:[rhel-8-baseos-rhui-source-rpms]
redhat-rhui-ha.repo:name=Red Hat Enterprise Linux 8 for $basearch - BaseOS from RHUI (Source RPMs)
redhat-rhui-ha.repo:mirrorlist=https://rhui.REGION.aws.ce.redhat.com/pulp/mirror/content/dist/rhel8/rhui/$releasever/$basearch/baseos/source/SRPMS
```

### Install MariaDB Server

Execute the following `dnf localinstall` command in the same order from the extracted RPM folder.

```
[root@ip-172-31-26-216 mariadb-enterprise-10.6.14-9-rhel-8-x86_64-rpms]# dnf localinstall MariaDB-common-10.6.14_9-1.el8.x86_64.rpm \
                                                                            MariaDB-compat-10.6.14_9-1.el8.x86_64.rpm \
                                                                            MariaDB-client-10.6.14_9-1.el8.x86_64.rpm \
                                                                            MariaDB-shared-10.6.14_9-1.el8.x86_64.rpm \
                                                                            MariaDB-backup-10.6.14_9-1.el8.x86_64.rpm \
                                                                            galera-enterprise-4-26.4.14-1.el8.x86_64.rpm \
                                                                            MariaDB-server-10.6.14_9-1.el8.x86_64.rpm

Last metadata expiration check: 0:11:49 ago on Sun 03 Sep 2023 05:48:54 PM UTC.
Dependencies resolved.
=====================================================================================================================================================================================
 Package                                   Architecture               Version                                                   Repository                                      Size
=====================================================================================================================================================================================
Installing:
 MariaDB-backup                            x86_64                     10.6.14_9-1.el8                                           @commandline                                   7.3 M
 MariaDB-client                            x86_64                     10.6.14_9-1.el8                                           @commandline                                   8.8 M
 MariaDB-common                            x86_64                     10.6.14_9-1.el8                                           @commandline                                    88 k
 MariaDB-compat                            x86_64                     10.6.14_9-1.el8                                           @commandline                                   2.2 M
 MariaDB-server                            x86_64                     10.6.14_9-1.el8                                           @commandline                                    20 M
 MariaDB-shared                            x86_64                     10.6.14_9-1.el8                                           @commandline                                   126 k
 galera-enterprise-4                       x86_64                     26.4.14-1.el8                                             @commandline                                   1.6 M
Installing dependencies:
 boost-program-options                     x86_64                     1.66.0-13.el8                                             rhel-8-appstream-rhui-rpms                     141 k
 compat-openssl10                          x86_64                     1:1.0.2o-4.el8_6                                          rhel-8-appstream-rhui-rpms                     1.1 M
 libnsl                                    x86_64                     2.28-225.el8                                              rhel-8-baseos-rhui-rpms                        105 k
 lsof                                      x86_64                     4.93.2-1.el8                                              rhel-8-baseos-rhui-rpms                        253 k
 make                                      x86_64                     1:4.2.1-11.el8                                            rhel-8-baseos-rhui-rpms                        498 k
 perl-DBI                                  x86_64                     1.641-4.module+el8.6.0+13388+70c0920f                     rhel-8-appstream-rhui-rpms                     741 k
 perl-Math-BigInt                          noarch                     1:1.9998.11-7.el8                                         rhel-8-baseos-rhui-rpms                        196 k
 perl-Math-Complex                         noarch                     1.59-422.el8                                              rhel-8-baseos-rhui-rpms                        109 k
 socat                                     x86_64                     1.7.4.1-1.el8                                             rhel-8-appstream-rhui-rpms                     323 k

Transaction Summary
=====================================================================================================================================================================================
Install  16 Packages

Total size: 43 M
Total download size: 3.4 M
Installed size: 204 M
Is this ok [y/N]: y
Downloading Packages:
(1/9): perl-DBI-1.641-4.module+el8.6.0+13388+70c0920f.x86_64.rpm                                                                                      10 MB/s | 741 kB     00:00
(2/9): socat-1.7.4.1-1.el8.x86_64.rpm                                                                                                                4.0 MB/s | 323 kB     00:00
(3/9): compat-openssl10-1.0.2o-4.el8_6.x86_64.rpm                                                                                                     11 MB/s | 1.1 MB     00:00
(4/9): boost-program-options-1.66.0-13.el8.x86_64.rpm                                                                                                4.2 MB/s | 141 kB     00:00
(5/9): perl-Math-BigInt-1.9998.11-7.el8.noarch.rpm                                                                                                   6.0 MB/s | 196 kB     00:00
(6/9): lsof-4.93.2-1.el8.x86_64.rpm                                                                                                                   12 MB/s | 253 kB     00:00
(7/9): libnsl-2.28-225.el8.x86_64.rpm                                                                                                                7.0 MB/s | 105 kB     00:00
(8/9): make-4.2.1-11.el8.x86_64.rpm                                                                                                                   18 MB/s | 498 kB     00:00
(9/9): perl-Math-Complex-1.59-422.el8.noarch.rpm                                                                                                     7.8 MB/s | 109 kB     00:00
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                 17 MB/s | 3.4 MB     00:00
Running transaction check
Transaction check succeeded.
...
...
...
Installed:
  MariaDB-backup-10.6.14_9-1.el8.x86_64                               MariaDB-client-10.6.14_9-1.el8.x86_64                   MariaDB-common-10.6.14_9-1.el8.x86_64
  MariaDB-compat-10.6.14_9-1.el8.x86_64                               MariaDB-server-10.6.14_9-1.el8.x86_64                   MariaDB-shared-10.6.14_9-1.el8.x86_64
  boost-program-options-1.66.0-13.el8.x86_64                          compat-openssl10-1:1.0.2o-4.el8_6.x86_64                galera-enterprise-4-26.4.14-1.el8.x86_64
  libnsl-2.28-225.el8.x86_64                                          lsof-4.93.2-1.el8.x86_64                                make-1:4.2.1-11.el8.x86_64
  perl-DBI-1.641-4.module+el8.6.0+13388+70c0920f.x86_64               perl-Math-BigInt-1:1.9998.11-7.el8.noarch               perl-Math-Complex-1.59-422.el8.noarch
  socat-1.7.4.1-1.el8.x86_64

Complete!
```

### Start The MariaDB Server

Start the MariaDB server with `systemctl start mariadb` and execute the secure installation step.

```
[server1 ~]# systemctl start mariadb

[server1 ~]# systemctl status mariadb
● mariadb.service - MariaDB 10.6.14-9 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Sun 2023-09-03 18:06:15 UTC; 54s ago
     Docs: man:mariadbd(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 72263 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 72203 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/..; /usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment >
  Process: 72201 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 72249 (mariadbd)
   Status: "Taking your SQL requests now..."
    Tasks: 13 (limit: 4624)
   Memory: 90.0M
   CGroup: /system.slice/mariadb.service
           └─72249 /usr/sbin/mariadbd

Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 0 [Note] Plugin 'FEEDBACK' is disabled.
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 server_audit: MariaDB Audit Plugin version 2.4.1 STARTED.
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 server_audit: Query cache is enabled with the TABLE events. Some table reads c>
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 0 [Note] InnoDB: Buffer pool(s) load completed at 230903 18:06:15
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 0 [Note] Server socket created on IP: '0.0.0.0'.
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 0 [Note] Server socket created on IP: '::'.
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: 2023-09-03 18:06:15 0 [Note] /usr/sbin/mariadbd: ready for connections.
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal mariadbd[72249]: Version: '10.6.14-9-MariaDB-enterprise'  socket: '/var/lib/mysql/mysql.sock'  port: 3306  MariaDB >
Sep 03 18:06:15 ip-172-31-26-216.ap-southeast-1.compute.internal systemd[1]: Started MariaDB 10.6.14-9 database server.
```

#### Secure MariaDB

Once MariaDB has started successfully with the default config, execute the `mariadb-secure-installation` to secure the server (base hardening). Follow the prompts and answer "Y"

This will help us secure the MariaDB server and also set the password for the database `root` user, which is important.

```
[root@ip-172-31-26-216 ~]# mariadb-secure-installation

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

By now we had done the following

- `Switch to unix_socket authentication [Y]`
- `Change the root password? [Y]`
- `Remove anonymous users? [Y]`
- `Disallow root login remotely? [Y]`
- `Remove test database and access to it? [Y]`
- `Reload privilege tables now? [Y]`

#### Data Directory

We can now configure custom `datadir` for the MariaDB server, in this exercise we will be using `/mariadb/data/`. This can be any folder of your choice.

Stop the MariaDB server, create the required path, copy all the contents from `/var/lib/mysql/*` to `/mariadb/data/` path and change the ownership of `/mariadb` to `mysql:mysql` using the recursive flag `-R` 

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
# ACID Config Ends

# Replication
binlog_format=ROW
log_bin=mariadb-bin
log_bin_index=mariadb-bin.index
server_id=1000
gtid_domain_id=1
shutdown_wait_for_slaves=ON
expire_logs_days=7
session_track_system_variables=last_gtid
# Replication Setup Ends

bind_address = 0.0.0.0

[mysql]
prompt=\H [\d]>\_
```

***Note:** Remember to configure **`innodb_buffer_pool_size`** based on 70% of your server's RAM*

In the above config, **`shutdown_wait_for_slaves=ON`** is specific to the MariaDB enteprise server and not avialble in the community build. This is super important parameter that will ensure that all the slaves have replicated properly before shuttind down the Master node. Very useful for busy environments when you have to stop the Master node. 

If TPS is critical then set the `sync` variables to ZERO and innodb_flush_log_at_trx_commit=2, this will improve the transaction throughput and replication speeds but at the cost of durability and can lead to data loss in case of a MariaDB server failure due to any reason.

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

Other specific configurations if needed, like, password complexity and auditing, refer to the following

- Simple Password Check Plugin
  - <https://mariadb.com/kb/en/simple-password-check-plugin/>
- Enterprise Audit
  - <https://mariadb.com/products/skysql/docs/security/enterprise-audit/#enabling-enterprise-audit>

Once all the required configurations are done, restart both of the MariaDB servers to enable binary logs and other configuration sets.

#### User Setup

##### MariaDB Backup User

Create a user with grants to execute MariaDB Backup on the server.

The following user creation is to be done only on the Master node.

```sql
CREATE USER 'mariabackup'@'localhost' IDENTIFIED BY 'Password123!';
GRANT RELOAD, PROCESS, LOCK TABLES, BINLOG MONITOR ON *.* TO 'mariabackup'@'localhost';
```

##### MariaDB Test Application User

```
[root@ip-172-31-26-216 ~]# mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 13
Server version: 10.6.14-9-MariaDB-enterprise MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE DATABASE testdb;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| testdb             |
+--------------------+
5 rows in set (0.002 sec)

MariaDB [(none)]> use testdb;
Database changed
MariaDB [testdb]> CREATE USER 'app_user'@'%' IDENTIFIED BY 'Password123!';
Query OK, 0 rows affected (0.002 sec)

MariaDB [testdb]> GRANT ALL ON testdb.* TO 'app_user'@'@';
Query OK, 0 rows affected (0.001 sec)

MariaDB [testdb]> show grants for app_user@'%';
+---------------------------------------------------------------------------------------------------------+
| Grants for app_user@%                                                                                   |
+---------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `app_user`@`%` IDENTIFIED BY PASSWORD '*4F56EF3FCEF3F995F03D1E37E2D692D420111476' |
| GRANT ALL PRIVILEGES ON `testdb`.* TO `app_user`@`%`                                                    |
+---------------------------------------------------------------------------------------------------------+
2 rows in set (0.000 sec)
```

This concludes our verification and final touches of the setup.

##### Thank you!
