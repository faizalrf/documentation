# Setting up Galera Cluster with MaxScale 2.3/2.4

## Environment Setup

Our environment consists of 3 Galera nodes and One MaxScale running CentOS 7 / RHEL 7

- MaxScale-60 (192.168.56.60)
  - Galera-61 (192.168.56.61)
  - Galera-62 (192.168.56.62)
  - Galera-63 (192.168.56.63)

### Disable SELinux

Disable SELinux on the RHEL 7 / CentOS 7 VMs, to do this we will have to edit the SELinux configuration, in the file `/etc/selinux/config`, make sure to change SELINUX=disabled, after the edit is done, the config file should look like this:

```txt
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```

After saving and exiting, we will need to reboot the VM to take permanent effect. Check if the SELinux has actually been disabled, use either of the two commands (sestatus/getenforce) to confirm:

```txt
[root@localhost ~] sestatus
SELinux status:                 disabled

[root@localhost ~] getenforce
Disabled
```

### Disable firewalld

Firewalld is a standard service that is disabled using the command systemctl on the RHEL 7 / CentOS 7. Disable it on all the nodes and check its status using the systemctl status firewalld:

[root@localhost ~] systemctl stop firewalld

[root@localhost ~] systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.

```txt
[root@localhost ~] systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
```

Since this is just a demo, we can disable the firewall completely. In production / other environments where it can't be done, we need to ensure the firewall for the following ports are opened between each of the cluster nodes:

- 3306 For MySQL client connections and State Snapshot Transfer that use the mysqldump method.
- 4567 For Galera Cluster replication traffic, multicast replication uses both UDP transport and TCP on this port.
- 4568 For Incremental State Transfer.
- 4444 For all other State Snapshot Transfer.

Once the above are done, reboot the VM, this has to be done on all the 3 Galera VM nodes.

## Install MariaDB Server

If internet access is available on the servers, we can directly setup MariaDB repositories on the server and install. Else we will need to download the MariaDB 10.3 rpm files from <https://mariadb.com/downloads/> we will assume the later as this is the case for almost all the secure environments.

### Download MariaDB Server

Go to <https://mariadb.com/downloads/> and select the desired OS / Release. We are going to select CentOS 7 MariaDB 10.3.14 as its the latest GA version available.

Once the version and OS has been selected, click the _Download_ button and download the tar file in a desired folder. Once, downloaded, we can transfer the file to all the Galera VM under /tmp folder. 

Use `wget https://downloads.mariadb.com/MariaDB/mariadb-10.3.14/yum/centos/mariadb-10.3.14-rhel-7-x86_64-rpms.tar` under /tmp folder to download the file directly on the VM just for the sake of convenience.

```txt
[root@galera-61 tmp]# wget https://downloads.mariadb.com/MariaDB/mariadb-10.3.14/yum/centos/mariadb-10.3.14-rhel-7-x86_64-rpms.tar
--2019-04-24 13:50:31--  https://downloads.mariadb.com/MariaDB/mariadb-10.3.14/yum/centos/mariadb-10.3.14-rhel-7-x86_64-rpms.tar
Resolving downloads.mariadb.com (downloads.mariadb.com)... 51.255.85.11
Connecting to downloads.mariadb.com (downloads.mariadb.com)|51.255.85.11|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 476805120 (455M) [application/octet-stream]
Saving to: ‘mariadb-10.3.14-rhel-7-x86_64-rpms.tar’

100%[================================================================================================>] 476,805,120 7.49MB/s   in 81s    

2019-04-24 13:51:55 (5.59 MB/s) - ‘mariadb-10.3.14-rhel-7-x86_64-rpms.tar’ saved [476805120/476805120]

[root@galera-61 tmp]# ls -lrt
total 465684
-rw-r--r-- 1 root root 476805120 Apr  1 23:51 mariadb-10.3.14-rhel-7-x86_64-rpms.tar
drwx------ 3 root root        17 Apr 24 12:56 systemd-private-34032af87d2042ee810848c9e3c37cc7-chronyd.service-FNIlYr
drwx------ 3 root root        17 Apr 24 13:16 systemd-private-4a06002ef5034f7daba1e424b040a892-chronyd.service-xr6nOK
```

### Check for Old MariaDB Libraries

Use rpm -qa to check if the old 5.x libraries are present, these must be removed before we proceed with the installation. Copy the output from the rpm -q command and use it in the next command to remove the old libraries using rpm -e --nodeps

```txt
[root@galera-61 ~]# rpm -qa | grep -i mariadb
mariadb-libs-5.5.60-1.el7_5.x86_64
[root@galera-61 ~]# 
[root@galera-61 ~]# rpm -e --nodeps mariadb-libs-5.5.60-1.el7_5.x86_64
[root@galera-61 ~]# 
```

Now untar the MariaDB rpm.tar file

```txt
[root@galera-61 tmp]# ls -rlt
total 465632
-rw-r--r-- 1 root root 476805120 Apr  1 23:51 mariadb-10.3.14-rhel-7-x86_64-rpms.tar
drwx------ 3 root root        17 Apr 24 12:56 systemd-private-34032af87d2042ee810848c9e3c37cc7-chronyd.service-FNIlYr
drwx------ 3 root root        17 Apr 24 13:16 systemd-private-4a06002ef5034f7daba1e424b040a892-chronyd.service-xr6nOK
[root@galera-61 tmp]# tar -xvf mariadb-10.3.14-rhel-7-x86_64-rpms.tar 
mariadb-10.3.14-rhel-7-x86_64-rpms/
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/550d446e467bee2440d49af715bd3c8ed6f97d450ce362671091ab84427a58d9-primary.xml.gz
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/8e951c964064090f2f57dbcba5ba6ffe5a0d3a0a99b603d4d15dce5cb05f8975-filelists.xml.gz
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/147f1b0e736f2207d789c53af782c263ce5df3ab7a5aff9b9583092073545977-other.xml.gz
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/repomd.xml
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/5e00446fe1a51a573ea04247bb43fd607275d81dacb5422dfc6e71cb16350ae6-other.sqlite.bz2
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/c6d74b96a367e6b64e9fba62252f1fc654a125b28f55914556b680efcfece7a6-filelists.sqlite.bz2
mariadb-10.3.14-rhel-7-x86_64-rpms/repodata/d29693075048a23791debb6f9312f7a3cedb102bf45d0522a5903435f3f03649-primary.sqlite.bz2
mariadb-10.3.14-rhel-7-x86_64-rpms/README
mariadb-10.3.14-rhel-7-x86_64-rpms/setup_repository
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-cassandra-engine-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-backup-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-backup-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-cassandra-engine-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-client-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-client-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-common-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-common-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-connect-engine-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-compat-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-connect-engine-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-cracklib-password-check-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-devel-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-cracklib-password-check-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-devel-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-gssapi-server-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-gssapi-server-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-oqgraph-engine-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-oqgraph-engine-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-rocksdb-engine-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-rocksdb-engine-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-server-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-server-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-shared-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-shared-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-test-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-test-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-tokudb-engine-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-tokudb-engine-debuginfo-10.3.14-1.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/galera-25.3.25-1.rhel7.el7.centos.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/jemalloc-3.6.0-1.el7.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/jemalloc-devel-3.6.0-1.el7.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/libzstd-1.3.4-1.el7.x86_64.rpm
mariadb-10.3.14-rhel-7-x86_64-rpms/MariaDB-10.3.14-1.el7.centos.src.rpm
[root@galera-61 tmp]# 
```

A bunch of RPM files will be extracted. We are going to install a specific set of RPMs and keep the others for later if needed, such as `cracklib password check`, `rocksdb engine` etc.

### Install The MariaDB Server

Follow the sequence, use RPM commandline to install `compact and common` RPM files with a single command

```txt
[root@galera-61 tmp]# rpm -ivh MariaDB-common-10.3.14-1.el7.centos.x86_64.rpm MariaDB-compat-10.3.14-1.el7.centos.x86_64.rpm
key ID 1bb943db: NOKEY
Preparing...                          ################################# [100%]
Updating / installing...
   1:MariaDB-compat-10.3.14-1.el7.cent################################# [ 50%]
   2:MariaDB-common-10.3.14-1.el7.cent################################# [100%]
[root@galera-61 tmp]# 
```

Install the remaining using `yum -y install`

- yum -y install MariaDB-client-10.3.14-1.el7.centos.x86_64.rpm
- yum -y install MariaDB-backup-10.3.14-1.el7.centos.x86_64.rpm
- yum -y install MariaDB-shared-10.3.14-1.el7.centos.x86_64.rpm
- yum -y install galera-25.3.25-1.rhel7.el7.centos.x86_64.rpm
- yum -y install MariaDB-server-10.3.14-1.el7.centos.x86_64.rpm

Once all have been installed, we can validate using `rpm -qa` query tool.

```txt
[root@galera-61 mariadb-10.3.14-rhel-7-x86_64-rpms]# rpm -qa | grep -i mariadb
MariaDB-backup-10.3.14-1.el7.centos.x86_64
MariaDB-common-10.3.14-1.el7.centos.x86_64
MariaDB-client-10.3.14-1.el7.centos.x86_64
MariaDB-shared-10.3.14-1.el7.centos.x86_64
MariaDB-server-10.3.14-1.el7.centos.x86_64
MariaDB-compat-10.3.14-1.el7.centos.x86_64

[root@galera-61 mariadb-10.3.14-rhel-7-x86_64-rpms]# rpm -qa | grep -i galera
galera-25.3.25-1.rhel7.el7.centos.x86_64
```

### Start MariaDB server and Secure its Installation

Lets start MariaDB server normally and verify its status through `systemctl status` 

```txt
[root@galera-61 ~]# systemctl start mariadb
[root@galera-61 ~]# 
[root@galera-61 ~]# systemctl status mariadb
● mariadb.service - MariaDB 10.3.14 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Wed 2019-04-24 14:19:46 EDT; 18s ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 4434 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 4390 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`/usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 4388 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 4402 (mysqld)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─4402 /usr/sbin/mysqld

Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] InnoDB: 10.3.14 started; log sequence number 1630815; trans...n id 21
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] InnoDB: Buffer pool(s) load completed at 190424 14:19:46
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] Plugin 'FEEDBACK' is disabled.
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] Server socket created on IP: '::'.
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] Reading of all Master_info entries succeded
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] Added new Master_info '' to hash table
Apr 24 14:19:46 galera-61 mysqld[4402]: 2019-04-24 14:19:46 0 [Note] /usr/sbin/mysqld: ready for connections.
Apr 24 14:19:46 galera-61 mysqld[4402]: Version: '10.3.14-MariaDB'  socket: '/var/lib/mysql/mysql.sock'  port: 3306  MariaDB Server
Apr 24 14:19:46 galera-61 systemd[1]: Started MariaDB 10.3.14 database server.
Hint: Some lines were ellipsized, use -l to show in full.
```

MariaDB server has been successfully started, it's time to secure the MariaDB using `mysql_secure_installation`

Follow the prompts, It will ask for existing `root` password, just press *enter* since we don't have any password for the first time. Provide a new `root` password and continue with remaining question with the a "Y" for each.

```txt
[root@galera-61 ~]# mysql_secure_installation 

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none): 
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] Y
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
[root@galera-61 ~]# 
```

Installation is secure now, we can no longer log in to the server without a password.

```txt
[root@galera-61 ~]# mysql
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
```

Lets try to login with new root password we provided during `mysql_secure_installation`

```txt
[root@galera-61 ~]# mysql -uroot -p
Enter password: **********
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 18
Server version: 10.3.14-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select version();
+-----------------+
| version()       |
+-----------------+
| 10.3.14-MariaDB |
+-----------------+
1 row in set (0.000 sec)
```

Our server is ready now, time to stop MariaDB process and configure Galera specific configurations

Edit the /etc/my.cnf.d/server.cnf file and edit the `[mysqld]` section as follows

```txt
[mysqld]
log_error
```

This will enable error logging on the server in, always a good idea to keep this enabled to monitor the server properly.

Edit the `[galera]` section as follows

```txt
[galera]
## Mandatory settings
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address=gcomm://192.168.56.61,192.168.56.62,192.168.56.63
wsrep_provider_options="pc.weight=2"
wsrep_sst_method=mariabackup
wsrep_sst_auth=backupuser:secretpassword

binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=512M
innodb_log_file_size=512M
max_allowed_packet=256M


## Galera Node Configuration
wsrep_node_address=192.168.56.61
wsrep_node_name=galera-61

## Allow server to accept connections on all interfaces.
bind-address=0.0.0.0
```

Let's look through the above section and explain what is the purpose for each line.

- **`wsrep_on=ON`**
  - This enables Galera service on the node
- **`wsrep_provider=/usr/lib64/galera/libgalera_smm.so`**
  - This tells Galera on the location of the Galera libraries. In case you have a custom path selected for installation, this should point to the specific location. Ensure that the `libgalera_smm.so` is available at the location selected.
- **`wsrep_cluster_address=gcomm://192.168.56.61,192.168.56.62,192.168.56.63`**
  - This holds the list of all the IP addresses of each node in the galera cluster. At the moment we have only one node available, but we have provided 3 different IP as we are going to setup the other two after this.
- **`wsrep_provider_options="pc.weight=2"`**
  - This is **important** for a two data center setup. Set this to `pc.weight=2` for the two nodes in one data center, and `pc.weight=1` for the two nodes on the DR data center. This will define that the primary data center will have the higher weightage and will help establish quorum.
- **`wsrep_sst_method=mariabackup`**
  - This is very important, this is used to define how the new nodes or SST is handled. Configure it as using `mariabackup` this will make sure that the node is always available even when it's playing the part of a Doner's.
    - Refer to <https://mariadb.com/kb/en/mariabackup-sst-method/> for full details on this process.
- **`wsrep_sst_auth=backupuser:secretpassword`**
  - This let's Galera know how to execute Mariabackup for internal SST events. For this we will have to create a special user to run MariaBackup, that user and password should be defined in the config.
- **`binlog_format=row`**
  - Bionary logging is required by the Galera cluster, it does not write these logs on disk because we have not specified any `log_bin` parameter. Galera will just use the transaction logs internally for sending the transaction to the other nodes.
- **`default_storage_engine=InnoDB`**
  - Since Galera cluster can only support InnoDB engine, its a good idea to keep it as a default.
- **`innodb_autoinc_lock_mode=2`**
  - This is an important parameter specifically for auto increment keys. If this parameter is set to any other values, inserts on AUTO_INCREMENT enabled tables may face deadlocks
- **`innodb_flush_log_at_trx_commit=1`**
  - To Ensure no data loss in case of power failure.
- **`innodb_buffer_pool_size=256M`**
  - This must be set to **70%** of the total physical RAM in the server. This is quite critical for performance. We are using 512M here because of the tiny server configuration.
- **`innodb_log_file_size=512M`**
  - Another important parameter for improving **write** performance. This defines the redo log file size on the server, keep it as big as possible to avoid frequent flushing and IO. On a production server, This can be safely set to 1GB or more depending on the transaction volume size. 
- **`max_allowed_packet=256M`**
  - This controlls what is the max size of a single transaction. Having a large enough value can improve **write** performance a good measure would be set it as large as the largest BLOB / CLOB (TEXT) that can be written to the server. This ensure the data goes to the server in one single trip.
- **`wsrep_node_address=192.168.56.61`**
  - This is important, this parameter tells galera the IP of this particular node. Each node will have their specific IP mentioned for this property.
- **`wsrep_node_name=galera-61`**
  - The name of this Galera Node, its up to us to chose what we want.
- **`bind-address=0.0.0.0`**
  - Allows connection from any interface, ensure we dont bind the server to 127.0.0.1

We can't yet start the server because it will now look for the other two Galera nodes which are not ready yet.

We will now repeat the above setup on all three nodes and make sure to change `wsrep_node_address` & `wsrep_node_name` for each node accordingly.

Asuming that we have 4 nodes in total, 2 nodes on Primary DC and 2 nodes on DR DC. The weightage needs to setup as `wsrep_provider_options="pc.weight=2"` for the two primary nodes and `wsrep_provider_options="pc.weight=1"` for the two nodes in the secondary DC.

But if we have a setup on a single DC with three nodes then this weightage is not very important. It is only important if the servers are spread across data centers with even number of nodes in total.

The `/etc/my.cnf.d/server.cnf` can simply be copied to all the other nodes and just modify the above three parameters accordingly (`wsrep_node_address`, `wsrep_node_name` & `wsrep_provider_options="pc.weight=2"`)

### Start Galera Cluster

Once the other two nodes have been setup as per above, its time to bootstrap the galera cluster from the first node.

execute `galera_new_cluster` on the first VM and verify the server error log file under the /var/lib/mysql location. If the command completes successfully without errors, it meaans Galera is now ready for new nodes.

```txt
[root@galera-61 ~]# galera_new_cluster
```

Connect to mysql client and check Galera cluster status

```txt
[root@galera-61 ~]# mysql -uroot -p
Enter password: **********
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 10
Server version: 10.3.14-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show global status like '%wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+
1 row in set (0.002 sec)
```

This indicates that Galera is running and it has 1 node in the cluster, which is itself. Lets start the otehr two nodes using the standard `systemctl start mariadb` command. We cannot run `galera_new_cluster` on other nodes as the bootstrap has already start from a VM.

Once the other two VMs have been started, execute the `show global status` again to check

```txt
MariaDB [(none)]> show global status like '%wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
1 row in set (0.001 sec)

MariaDB [(none)]> CREATE USER 'backupuser'@'localhost' IDENTIFIED BY 'secretpassword';
0 row in set (0.001 sec)

MariaDB [(none)]> GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backupuser'@'localhost';
0 row in set (0.001 sec)
```

Once the cluster is up and running, create the `backupuser@localhost` to be used by Galera SST (System State Transfer) and grant the above mentioned privileges. This user has already been defined in the `server.cnf` file.

We now have a Galera cluster up and running! At this point, we can connect to any node and perform DDL/DML and everything we do should get synced up with the other two nodes in the cluster.

Next we will install MaxScale 2.3/2.4 and configure it connect to this Galera clustster.

### Restarting a Galera Cluster

As we have seen, starting the cluster, we need to bootstrap the first node using `galera_new_cluster` shutting must be taken care by stopping the node that was running bootstrap as the last node to shutdown. If due to some reason the order is not followed when stoping the servers. On can refer to the file `/var/lib/mysql/grastate.dat` and look for the parameter that says `safe_to_bootstrap` The server that says `safe_to_bootstrap:1` is the node that needs to run `galera_new_cluster` followed by other nodes by simply using `systemctl start mariadb`. Following is an example of the `grastate.dat`

```txt
# GALERA saved state
version: 2.1
uuid:    9acf4d34-acdb-11e6-bcc3-d3e36276629f
seqno:   15
safe_to_bootstrap: 1
```

When bootstrapping the new cluster, Galera will refuse to use as a first node a node that was marked as unsafe to bootstrap from. You will see the following message in the logs:

```txt
It may not be safe to bootstrap the cluster from this node. It was not the last one to leave the cluster and may not contain all the updates.
To force cluster bootstrap with this node, edit the grastate.dat file manually and set safe_to_bootstrap to 1
```

## MaxScale 2.3/2.4

### Install MaxScale

Download the MaxScale RPM file from the <https://mariadb.com/downloads/#mariadb_platform-mariadb_maxscale> for the specific server, we will be downloading CentOS 7 2.3.6 version which is the latest GA at this point in time.

Download the RPM and transfer the file to the MaxScale VM. Like for MariaDB, I will download the RPM directly on the MaxScale VM and run through the installation process.

```txt
[root@maxscale-60 tmp]# wget https://downloads.mariadb.com/MaxScale/2.3.6/centos/7/x86_64/maxscale-2.3.6-1.centos.7.x86_64.rpm
--2019-04-24 15:59:14--  https://downloads.mariadb.com/MaxScale/2.3.6/centos/7/x86_64/maxscale-2.3.6-1.centos.7.x86_64.rpm
Resolving downloads.mariadb.com (downloads.mariadb.com)... 51.255.85.11
Connecting to downloads.mariadb.com (downloads.mariadb.com)|51.255.85.11|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 24290292 (23M) [application/x-redhat-package-manager]
Saving to: ‘maxscale-2.3.6-1.centos.7.x86_64.rpm’

100%[=============================================================================>] 24,290,292  2.38MB/s   in 15s    

2019-04-24 15:59:30 (1.57 MB/s) - ‘maxscale-2.3.6-1.centos.7.x86_64.rpm’ saved [24290292/24290292]

[root@maxscale-60 tmp]# ls -lrt
total 23728
-rw-------. 1 root root        0 Jan 28 13:52 yum.log
-rw-r--r--  1 root root 24290292 Apr 18 04:00 maxscale-2.3.6-1.centos.7.x86_64.rpm
[root@maxscale-60 tmp]# 
```

The MaxScale 2.3.6 has been downloaded on the VM, we can now use `yum` to install this. Remember to remove the old MariaDB packages like how we did for the MariaDB server installation.

```txt
[root@maxscale-60 tmp]# rpm -qa | grep -i mariadb
mariadb-libs-5.5.60-1.el7_5.x86_64
[root@maxscale-60 tmp]# rpm -e --nodeps mariadb-libs-5.5.60-1.el7_5.x86_64
[root@maxscale-60 tmp]# 
```

Now we are ready to install MaxScale 2.3 on this new VM.

```txt
[root@maxscale-60 tmp]# yum -y install maxscale-2.3.6-1.centos.7.x86_64.rpm
Loaded plugins: fastestmirror
Examining maxscale-2.3.6-1.centos.7.x86_64.rpm: maxscale-2.3.6-1.x86_64
Marking maxscale-2.3.6-1.centos.7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package maxscale.x86_64 0:2.3.6-1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================
 Package               Arch                Version                Repository                                      Size
=======================================================================================================================
Installing:
 maxscale              x86_64              2.3.6-1                /maxscale-2.3.6-1.centos.7.x86_64               92 M

Transaction Summary
=======================================================================================================================
Install  1 Package

Total size: 92 M
Installed size: 92 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : maxscale-2.3.6-1.x86_64                                                                             1/1 
  Verifying  : maxscale-2.3.6-1.x86_64                                                                             1/1 

Installed:
  maxscale.x86_64 0:2.3.6-1                                                                                            

Complete!

[root@maxscale-60 tmp]# rpm -qa | grep maxscale
maxscale-2.3.6-1.x86_64
[root@maxscale-60 tmp]# 
```

MaxScale is now installed, we can now configure /etc/maxscale.cnf file to connect to the three Galera nodes.

This setup will do the following for the applicaiton.

- Read/Write splitting (Load Balancing)
  - Read scaling
  - Prevent Deadlocks
- Auto Failover/Failback (Even though this is internally managed by Galera, MaxScale will provide a seamless interface to the DB without any downtime for the application)
- Auto Connection Failover
- Auto Transaction Replay in case of a node failure
- Monitor the Galera cluster and provide a birdseye view the entire setup.

### MaxScale Configuration

It's time to edit the /etc/maxscale.cnf file and configure it to connect to our three 
node Galera cluster

Edit the /etc/maxscale.cnf file and delete its contents, insert the following set of configurations.

```txt
[maxscale]
threads=auto

# List of servers in the Cluster
[Galera-61]
type=server
address=192.168.56.61
port=3306
protocol=MariaDBBackend
priority=1

[Galera-62]
type=server
address=192.168.56.62
port=3306
protocol=MariaDBBackend
priority=2

[Galera-63]
type=server
address=192.168.56.63
port=3306
protocol=MariaDBBackend
priority=3

# Monitoring for the servers
[Galera-Monitor]
type=monitor
module=galeramon
servers=Galera-61,Galera-62,Galera-63
user=maxuser
passwd=secretpassword

## For MaxScale 2.4, the parameter name has changed to `password`
#password=secretpassword
##

monitor_interval=2000
use_priority=true
available_when_donor=true

# Galera Read/Write Splitter service
[Galera-RW-Service]
type=service
router=readwritesplit
servers=Galera-61,Galera-62,Galera-63
user=maxuser
passwd=secretpassword

## For MaxScale 2.4, the parameter name has changed to `password`
#password=secretpassword
##

master_reconnection=true
transaction_replay=true
transaction_replay_retry_on_deadlock=true
master_failure_mode=error_on_write
slave_selection_criteria=ADAPTIVE_ROUTING

# Galera cluster listener
[Galera-Listener]
type=listener
service=Galera-RW-Service
protocol=MariaDBClient
port=4006
```

Save and exit the `/etc/maxscale.cnf`, let's review the above configuration and what these mean.

- **`[maxscale]`**
  - This is the common section for maxscale configration and usually contains log file details and the number of threads maxscale uses. We have given _threads=auto_ to let MaxScale use the number of available cores in the CPU and spawn threads accordingly. Else we can use a static numnber like 2, 4 or 16 etc.
- Next set of sections (`[Galera-61]`) lists the servers we want MaxScale to monitor and use. Each section name is up to us what we want to call the server. I have used the following to indicate thir IP address
  - Galera-61
  - Galera-62
  - Galera-63
- Based on the above setup, Galera-61 has the highest priority=1, this will always be the Master node for MaxScale, if down a server with lower priority will be selected as Master.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-galera-monitor/#interaction-with-server-priorities>
- **`[Galera-Monitor]`**
  - This section of the configuration tells MaxScale about how to monitor the servers and what type of servers are those.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-galera-monitor/> for details on available options for a Galera Monitor
    - **`module=galeramon`**
      - This indicates that the cluster to monitor is a Galera cluster, maxscale will handle it accordingly.
    - **`servers=Galera-61,Galera-62,Galera-63`**
      - Tells which servers to monitor. The server names are coma separated, these names should be the same names we configured in the list of server section before.
      - Normally all the servers defined in the cluster area listed here unless for a very specific reason we want to ignore a specific node we can remove it from this `servers` property.
    - **`user=maxuser`**
      - This tells which DB user to use for monitoring the cluster. We will need to create this user in the database before starting the maxscale service. Limited DB access is required for this user.
    - **`passwd=secretpassword`**
      - DB password for the user, it's currently mentioned in free text, but in normal secure installations, we can encrypt it using MaxScale encryption service.
      - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-encrypting-passwords/> for details
      - If using **MaxScale 2.4**, the parameter name has changed to **`password`** instead of `passwd`
    - **`monitor_interval=2000`**
      - This is the heart beat of the interval in miliseconds. Tells MaxScale on how frequent to ping the servers for status check. Can be reduced to 1000 for faster failover and status updates.
    - **`use_priority=true`**
      - This tells MaxScale to use the `priority` setup in the server's configuration. Priority is used by MaxScale to identify the `Master` node, the node with the smallest priority number is treated as Primary node for writes while others for reads. If it's desired that MaxScale selects a random node as master, then this property can be set to **false**
    - **`available_when_donor=true`**
      - This is one of the important parameters which tells MaxScale to use Galera node even when it's playing a DONOR's role. This works together with the server configuration done earlier in the `server.cnf` file as `wsrep_sst_method=mariabackup`, without this change in the server side config, MaxScale can't use the donor node normally.
- **`[Galera-RW-Service]`**
  - This section controls the Read / Write splitting and controls how connections and ongoing transactions are handlked in case of node failures.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-readwritesplit> for details on various avilable options
    - **`router=readwritesplit`**
      - Tells that this section is a router and it's for R/W splitting
    - **`servers=Galera-61,Galera-62,Galera-63`**
      - This tells MaxScale which servers are to be used for R/W splitting. You can remove a server from the list in case you don't want Reads or Writes going to that node. But usually all the servers are mentioned here.
    - **`user=maxuser`**
      - This tells which DB user to use for monitoring the cluster. We will need to create this user in the database before starting the maxscale service. Limited DB access is required for this user.
    - **`passwd=secretpassword`**
      - DB password for the user, it's currently mentioned in free text, but in normal secure installations, we can encrypt it using MaxScale encryption service.
      - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-encrypting-passwords/> for details
      - If using **MaxScale 2.4**, the parameter name has changed to **`password`** instead of `passwd`
    - **`master_reconnection=true`**
      - Tells MaxScale to automatically reconnect to the nodes when availabe. This will provide High Availability for the applications and maintain connections open.
      - Applications will not faice a failure as long as a single node is available
    - **`transaction_replay=true`**
      - Automatically Replays the inflight transactions if the Master node goes down. With this enabled, applications will not face any transaction loss or failures in case of a lost node.
    - **`transaction_replay_retry_on_deadlock=true`**
      - MaxScale automatiacally retrys the transaction that failed due to a deadlock on the database. Can be very helpful on the Galera cluster.
      - refer to <https://mariadb.com/kb/en/mariadb-maxscale-24-readwritesplit/#transaction_replay_retry_on_deadlock> for more details.
    - **`slave_selection_criteria=ADAPTIVE_ROUTING`**
      - There are multiple ways MaxScale can select a node for READ queries. ADAPTIVE_ROUTING tells MaxScale to select a node which has the best average response time.
      - Look at <https://mariadb.com/kb/en/mariadb-maxscale-23-readwritesplit/#slave_selection_criteria> for available options
- **`[Galera-Listener]`**
  - This is the listener for the R/W splitter service `[Galera-Service]`
    - **`protocol=MariaDBClient`**
      - Tells MaxScale that this listener will listen to all MariaDB client connections.
      - **`port=4006`**
        - When application connect to MariaDB, they will connect through MaxScale using MaxScale IP and this **PORT**
- `[MaxAdmin-Service]` & `[MaxAdmin-Listener]`
  - These are internal services to MaxScale, check the MariaDB MaxSCale Knowledgbase for more details.

### Usig MaxScale

Let's start MaxScale Service and use it to connect to the Galera Cluster.

```txt
[root@maxscale-60 ~]# systemctl restart maxscale

[root@maxscale-60 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬───────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State │ GTID │
├───────────┼───────────────┼──────┼─────────────┼───────┼──────┤
│ Galera-61 │ 192.168.56.61 │ 3306 │ 0           │ Down  │      │
├───────────┼───────────────┼──────┼─────────────┼───────┼──────┤
│ Galera-62 │ 192.168.56.62 │ 3306 │ 0           │ Down  │      │
├───────────┼───────────────┼──────┼─────────────┼───────┼──────┤
│ Galera-63 │ 192.168.56.63 │ 3306 │ 0           │ Down  │      │
└───────────┴───────────────┴──────┴─────────────┴───────┴──────┘
```

`maxctrl` is an internal MaxScale interface that can tell us a lot of info about the various MaxScale services and their status. Here we have used it to list the servers.

Important thing to take note here is that Galera don't use GTID, that's why the column is empty. To see if the server nodes are in sync or not, we can rely on the MaxScale output as shown later on.

MaxScale is showing the cluster as currently down even though the servers are up and running. Let's check the Galera internal status.

```txt
[root@galera-61 ~]# mysql -uroot -p
Enter password: **********
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 321
Server version: 10.3.14-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show global status like '%wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
1 row in set (0.002 sec)
```

Indeed, Galera is running with three online nodes.

Let's review the MaxSCale log under `/var/log/maxscale/maxscale.log`

```txt
2019-04-25 00:55:28   error  : [Galera-Monitor] Failed to connect to server 'Galera-61' ([192.168.56.61]:3306) when checking monitor user credentials and permissions: Host '192.168.56.60' is not allowed to connect to this MariaDB server
2019-04-25 00:55:28   error  : [Galera-Monitor] Failed to connect to server 'Galera-62' ([192.168.56.62]:3306) when checking monitor user credentials and permissions: Host '192.168.56.60' is not allowed to connect to this MariaDB server
2019-04-25 00:55:28   error  : [Galera-Monitor] Failed to connect to server 'Galera-63' ([192.168.56.63]:3306) when checking monitor user credentials and permissions: Host 
```

We can see the above errors, it seems MaxSCale is not able to connect to the backend servers. This is because we have yet to create the user **maxuser** on the database.

Let's create these two users and restart MaxScale service.

Connect to any of the three Galera nodes and create the following users.

```txt
MariaDB [(none)]>  create user maxuser@'192.168.56.60' identified by 'secretpassword';
Query OK, 0 rows affected (0.021 sec)

MariaDB [(none)]> grant select on mysql.user to maxuser@'192.168.56.60';
Query OK, 0 rows affected (0.017 sec)

MariaDB [(none)]> grant select on mysql.tables_priv to maxuser@'192.168.56.60';
Query OK, 0 rows affected (0.015 sec)

MariaDB [(none)]> grant select on mysql.db to maxuser@'192.168.56.60';
Query OK, 0 rows affected (0.015 sec)

MariaDB [(none)]> grant show databases on *.* to maxuser@'192.168.56.60';
Query OK, 0 rows affected (0.015 sec)
```

We created the user maxmon and defined it's host as MaxSCale's IP `192.168.56.60` this will limit this user's access to only connect to the DB from the MaxScale node and from no other IP. 

Limit SELECT privilege is needed on `mysql.user`, `mysql.tables_priv`, `mysql.db` and `SHOW DATABASE` on all databases.

With this created on one Galera node, we can verify this on the other two Galera servers, this user should already exist there thanks to Galera internal replication.

Let's restart MaxScale node and retry `maxctrl list servers`

```txt
[root@maxscale-60 ~]# systemctl restart maxscale
[root@maxscale-60 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-61 │ 192.168.56.61 │ 3306 │ 0           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-62 │ 192.168.56.62 │ 3306 │ 0           │ Slave, Synced, Running  │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-63 │ 192.168.56.63 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

We have Galera now running with Galera-61 as the Master node based on our **priority** setup.

Important thing to take note that as long as one see "Synced" in the status, one can be sure that the nodes are in sync. Since Galera don't use GTID, this one of the ways to tell if the nodes are in sync or not.

Let's checl the services running on MaxScale

```txt
[root@maxscale-60 ~]# maxctrl list services
┌──────────────────┬────────────────┬─────────────┬───────────────────┬─────────────────────────────────┐
│ Service          │ Router         │ Connections │ Total Connections │ Servers                         │
├──────────────────┼────────────────┼─────────────┼───────────────────┼─────────────────────────────────┤
│ Galera-Service   │ readwritesplit │ 1           │ 1                 │ Galera-61, Galera-62, Galera-63 │
├──────────────────┼────────────────┼─────────────┼───────────────────┼─────────────────────────────────┤
│ MaxAdmin-Service │ cli            │ 1           │ 1                 │                                 │
└──────────────────┴────────────────┴─────────────┴───────────────────┴─────────────────────────────────┘
```

We can see a R/W splitter running and a MaxAdmin CLI service.

Let's Check the Monitors.

```txt
[root@maxscale-60 ~]# maxctrl list monitors
┌────────────────┬─────────┬─────────────────────────────────┐
│ Monitor        │ State   │ Servers                         │
├────────────────┼─────────┼─────────────────────────────────┤
│ Galera-Monitor │ Running │ Galera-61, Galera-62, Galera-63 │
└────────────────┴─────────┴─────────────────────────────────┘
```

We have a Galera-Monitor running which is Monitoring all three servers.

Using maxctrl commands we can monitor MaxScale and its services along with the backend servers.

### Connecting to MaxScale as a Client

We need to create an application user which the apps will use to connect to MaxScale. This user will have Read/Write access to application specific database.

Connect to any of the Galera nodes and create the application user with ncessary grants.

```txt
MariaDB [(none)]> create user app_user@'%' identified by 'secretpassword';
Query OK, 0 rows affected (0.019 sec)

MariaDB [(none)]> grant all on app_db.* to app_user@'%';
Query OK, 0 rows affected (0.014 sec)
```

In this specific test, we have created `app_user` which can connect from any host because of `'%'` as the host. We have also given full access to **app_db** and its objects.

A quick check on the grants.

```txt
MariaDB [(none)]> show grants for app_user@'%';
+---------------------------------------------------------------------------------------------------------+
| Grants for app_user@%                                                                                   |
+---------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO 'app_user'@'%' IDENTIFIED BY PASSWORD '*F89FFE84BFC48A876BC682C4C23ABA4BF64711A4' |
| GRANT ALL PRIVILEGES ON `app_db`.* TO 'app_user'@'%'                                                    |
+---------------------------------------------------------------------------------------------------------+
2 rows in set (0.000 sec)
```

Now we can connect to MaxScale R/W splitter service using the R/W listener configured at **port 4006**

From any of the Galera nodes, connect to MaxScale IP using `mysql` command line utility

```txt
[root@galera-61 ~]# mysql -uapp_user -p -h192.168.56.60 -P4006
Enter password: **********
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.3.14-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

```

- **-h** defines the host IP to connec to, **-P** specifies the port number

We have successfully connected to MasScale on its R/W splitter listener port using the app_user.

Now we can check maxscale status to see if we actually see a new user connected, on the MaxScale node execute the following

```txt
root@maxscale-60 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-61 │ 192.168.56.61 │ 3306 │ 1           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-62 │ 192.168.56.62 │ 3306 │ 1           │ Slave, Synced, Running  │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-63 │ 192.168.56.63 │ 3306 │ 1           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

We now see ONE connection on all the three nodes. Whenever a client connects to MaxScale listener port, internally MaxScale connects to all three nodes and maintains the connectivity even after a node failure.

At this point, on our MaxScale connection, we can perform a READ and WRITE operation, and MaxScale R/W service will send the qieres to the respective nodes accordingly.

```txt
MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| galera-62  |
+------------+
1 row in set (0.002 sec)

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| app_db             |
| information_schema |
+--------------------+
2 rows in set (0.003 sec)

MariaDB [(none)]> use app_db;
Database changed
MariaDB [app_db]> create table t(id serial, col varchar(100));
Query OK, 0 rows affected (0.033 sec)

MariaDB [app_db]> insert into t(col) select column_name from information_schema.columns;
Query OK, 782 rows affected (0.024 sec)
Records: 782  Duplicates: 0  Warnings: 0

MariaDB [app_db]> select count(*) from t;
+----------+
| count(*) |
+----------+
|      782 |
+----------+
1 row in set (0.003 sec)

MariaDB [app_db]> select count(*), @@hostname from t;
+----------+------------+
| count(*) | @@hostname |
+----------+------------+
|      782 | galera-63  |
+----------+------------+
1 row in set (0.003 sec)
```

The first SELECT query was sent ot Galera-62, then we created a table and inserted some dummy data (782 rows), Then selected from the same table and this time `@@hostname` returned Galera-63 as the host where the SELECT query was executed.

Let's do a test to ensure our insert statements are always done on the Galera-61 since it is the Master node as far as MaxScale is concerned.

```txt
MariaDB [app_db]> insert into t(col) values(@@hostname);
Query OK, 1 row affected (0.010 sec)

MariaDB [app_db]> insert into t(col) values(@@hostname);
Query OK, 1 row affected (0.012 sec)

MariaDB [app_db]> insert into t(col) values(@@hostname);
Query OK, 1 row affected (0.008 sec)

MariaDB [app_db]> select * from t order by id desc limit 3;
+------+-----------+
| id   | col       |
+------+-----------+
| 3078 | galera-61 |
| 3075 | galera-61 |
| 3072 | galera-61 |
+------+-----------+
3 rows in set (0.003 sec)
```

We inserted three rows and used `@@hostname` as the inmserted value, and we can see indeed it was executed on Galera-61 for all thre three inserts.

At this time, we can connect to any Galera node directly and verify that whatever we have done so far has been replicated to all three nodes.

One last test to see how the auto-failover works, on the Galera-61, shutdown the database using `systemctl stop mariadb` and then on the MaxScale node, check the list server's output

```txt
[root@maxscale-60 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-61 │ 192.168.56.61 │ 3306 │ 0           │ Down                    │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-62 │ 192.168.56.62 │ 3306 │ 0           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-63 │ 192.168.56.63 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

Galera-61 is down, and based on our priority setup, Galera-62 becomes the new master. Lets start the Galera-61 again and see what happens to the output.

We expect Galera-61 to become the master node again as it has the highest priority.

```txt
[root@maxscale-60 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-61 │ 192.168.56.61 │ 3306 │ 0           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-62 │ 192.168.56.62 │ 3306 │ 0           │ Slave, Synced, Running  │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-63 │ 192.168.56.63 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

Indeed, Galera-61 becomes the new master once more.

Things to take note:

- All connections to the database must come from MaxScale using the MaxScale Listener Port defined in the maxscale.cnf
- Reads will go to the non Master nodes
- Writes will go to the Master node
- Priority defined in the server's definition will dictate which node becomes the master.
- If a it's requred to replace a server with a new node, one can simply `rm -rf /var/lib/mysql/*` on that node and just restart the MariaDB process. Galera will automatically innitiate SST and send a fresh mariabackup copy to this new node and sync it up without any human intervention.
- Mariabackup can be taken from any node.
- Backup restore process remains the same as in standard MariaDB server.

This concludes this setup guide.

### Thank you

Faisal Saeed
_Senior Solution Engineer @ MariaDB Corporation_
