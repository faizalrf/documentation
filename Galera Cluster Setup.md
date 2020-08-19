# Setting up Galera Cluster 10.4 with MaxScale 2.4

## Environment Setup

Our environment consists of 3 node Galera cluster and One MaxScale running CentOS 7 / RHEL 7

At the time of this documentation, the latest version of **MariaDB is 10.4.13** and **MaxScale 2.4.10**

- MaxScale-70 (192.168.56.70)
  - Galera-71 (192.168.56.71)
  - Galera-72 (192.168.56.72)
  - Galera-73 (192.168.56.73)

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

Go to <https://mariadb.com/downloads/> and select the desired OS / Release. We are going to select CentOS 7 MariaDB 10.4.13 as its the latest GA version available as of now 11-June-2020.

Once the version and OS has been selected, click the _Download_ button and download the tar file in a desired folder. Once, downloaded, we can transfer the file to all the Galera VM under /tmp folder. 

Alternatively we can browse the `https://downloads.mariadb.com/MariaDB` folder, this lists all the MariaDB builds since the dawn of time! Can be a confusing place, unless you know what you are doing, I would recommend just using the <https://mariadb.com> and download the version that is needed.

Once downloaded, untar the file to get all the required RPM files for installation.

```txt
[root@galera-71 ~]# ls -rlt
total 538672
-rw-r--r-- 1 root root 551598080 Jun 11 10:41 mariadb-10.4.13-rhel-7-x86_64-rpms.tar

[root@galera-71 ~]# tar -xvf mariadb-10.4.13-rhel-7-x86_64-rpms.tar 
mariadb-10.4.13-rhel-7-x86_64-rpms/
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-backup-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-backup-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/setup_repository
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-cassandra-engine-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-cassandra-engine-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-client-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-client-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-common-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-compat-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-connect-engine-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-connect-engine-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-cracklib-password-check-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-cracklib-password-check-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-devel-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-devel-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-gssapi-server-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-gssapi-server-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-oqgraph-engine-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-oqgraph-engine-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-rocksdb-engine-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-rocksdb-engine-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-server-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-server-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-shared-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-shared-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-test-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-test-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-tokudb-engine-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-tokudb-engine-debuginfo-10.4.13-1.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/galera-4-26.4.4-1.rhel7.el7.centos.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/jemalloc-3.6.0-1.el7.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/jemalloc-devel-3.6.0-1.el7.x86_64.rpm        
mariadb-10.4.13-rhel-7-x86_64-rpms/libzstd-1.3.4-1.el7.x86_64.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/MariaDB-10.4.13-1.el7.centos.src.rpm
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/267da71a9b198ba71e88c6eb7bb12cc9da29b4784034f2886c7ad2e1890a0ee9-primary.xml.gz      
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/368a5f44b987986b67ce45a531ebce26421c731525f3a2ecac8f872056c8892e-filelists.xml.gz    
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/b70c8077011f248f520c1401731d1640ca87e54e500b0bf2914f746f555c5b0a-other.xml.gz        
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/repomd.xml
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/efff565f147f88b3b5b4bd88a331a0a93f71417fb203f08ee1869c03d1ae110a-other.sqlite.bz2    
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/a4b310d5ff7eafab4eda4d09730873588e73230cd5341479170c82efcbd6def1-filelists.sqlite.bz2
mariadb-10.4.13-rhel-7-x86_64-rpms/repodata/7e9fa847e3dd7bd8b958ce6c164ddedd85dc814cc695cc91c0b82c8491b071ca-primary.sqlite.bz2  
mariadb-10.4.13-rhel-7-x86_64-rpms/README
```

A bunch of RPM files will be extracted. We are going to install a specific set of RPMs and keep the others for later if needed, such as `cracklib password check`, `rocksdb engine` etc.

### Check for Old MariaDB Libraries

Use rpm -qa to check if the old 5.x libraries are present, these must be removed before we proceed with the installation. Copy the output from the rpm -q command and use it in the next command to remove the old libraries using rpm -e --nodeps

```txt
[root@galera-71 ~]# rpm -qa | grep -i mariadb
mariadb-libs-5.5.70-1.el7_5.x86_64

[root@galera-71 ~]# rpm -qa | grep -i mariadb | xargs rpm -e --nodeps
```

### Install The MariaDB Server

Follow the sequence, use RPM commandline to install `compact and common` RPM files with a single command

Change directory to the extaracted folder and install the common & compact RPM files with the single `rpm -ivh` command

```txt
[root@galera-71 mariadb-10.4.13-rhel-7-x86_64-rpms]# rpm -ivh MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm MariaDB-compat-10.4.13-1.el7.centos.x86_64.rpm
warning: MariaDB-common-10.4.13-1.el7.centos.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 1bb943db: NOKEY
Preparing...                          ################################# [100%]
Updating / installing...
   1:MariaDB-compat-10.4.13-1.el7.cent################################# [ 50%]
   2:MariaDB-common-10.4.13-1.el7.cent################################# [100%]
[root@galera-71 mariadb-10.4.13-rhel-7-x86_64-rpms]#
```

Install the remaining using `yum -y install`

- yum -y install MariaDB-client-10.4.13-1.el7.centos.x86_64.rpm
- yum -y install MariaDB-backup-10.4.13-1.el7.centos.x86_64.rpm
- yum -y install MariaDB-shared-10.4.13-1.el7.centos.x86_64.rpm
- yum -y install galera-4-26.4.4-1.rhel7.el7.centos.x86_64.rpm
- yum -y install MariaDB-server-10.4.13-1.el7.centos.x86_64.rpm
- yum -y install socat

*Note: `socat` is a component that is needed by Galera when the SST method is set to MariaBackup.*

Once all have been installed, we can validate using `rpm -qa` query tool.

```txt
[root@galera-71 mariadb-10.4.13-rhel-7-x86_64-rpms]# rpm -qa | grep -i mariadb
MariaDB-shared-10.4.13-1.el7.centos.x86_64
MariaDB-server-10.4.13-1.el7.centos.x86_64
MariaDB-compat-10.4.13-1.el7.centos.x86_64
MariaDB-backup-10.4.13-1.el7.centos.x86_64
MariaDB-common-10.4.13-1.el7.centos.x86_64
MariaDB-client-10.4.13-1.el7.centos.x86_64

[root@galera-71 mariadb-10.4.13-rhel-7-x86_64-rpms]# rpm -qa | grep -i galera
galera-4-26.4.4-1.rhel7.el7.centos.x86_64
```

We now have The latest MariaDB server + Galera installed on one node. Repeat the same steps on the other two MariaDB servers so that `rpm -qa | grep -i mariadb` & `rpm -qa | grep -i galera` shows the same output on all three nodes.

### Start MariaDB server and Secure its Installation

Lets start MariaDB server normally and verify its status through `systemctl status` 

```txt
[root@galera-71 ~]# systemctl status mariadb
● mariadb.service - MariaDB 10.4.13 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Thu 2020-06-11 13:28:00 EDT; 31min ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 30747 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 30608 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/..; /usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 30606 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 30710 (mysqld)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─30710 /usr/sbin/mysqld --wsrep-new-cluster --wsrep_start_position=81187002-ac00-11ea-aed2-e722922ab6a4:261

Jun 11 13:27:57 galera-71 systemd[1]: Starting MariaDB 10.4.13 database server...
Jun 11 13:27:59 galera-71 sh[30608]: WSREP: Recovered position 81187002-ac00-11ea-aed2-e722922ab6a4:261
Jun 11 13:27:59 galera-71 mysqld[30710]: 2020-06-11 13:27:59 0 [Note] /usr/sbin/mysqld (mysqld 10.4.13-MariaDB) starting as process 30710 ...
Jun 11 13:27:59 galera-71 mysqld[30710]: 2020-06-11 13:27:59 0 [Warning] Could not increase number of max_open_files to more than 16364 (request: 32183)
Jun 11 13:28:00 galera-71 systemd[1]: Started MariaDB 10.4.13 database server.
```

MariaDB server has been successfully started, it's time to connect to the MariaDB server using the `mariadb` CLI

```txt
[root@galera-71 ~]# mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 10.4.13-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select version();
+-----------------+
| version()       |
+-----------------+
| 10.4.13-MariaDB |
+-----------------+
1 row in set (0.000 sec)

MariaDB [(none)]> show create user root@localhost;
+----------------------------------------------------------------------------------------------------+
| CREATE USER for root@localhost                                                                     |
+----------------------------------------------------------------------------------------------------+
| CREATE USER `root`@`localhost` IDENTIFIED VIA mysql_native_password USING 'invalid' OR unix_socket |
+----------------------------------------------------------------------------------------------------+
1 row in set (0.000 sec)
```
Something to take note here, the root user is now connected to the OS `root` user using the `unix_socket` plugin. This means, as long as the user can login to the os `root` user, he can connect to the MariaDB running on the same server without a password. 

This behaviur can be changed by simply setting up a new password for the `root` user. Once logged in to the server as the root user, we can do the following to set a root password

```txt
MariaDB [(none)]> SET PASSWORD FOR root@localhost = PASSWORD('New$uperP@ssword1');
1 row in set (0.000 sec)
```

```txt
[root@galera-71 ~]# mariadb
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
```

Time to secure our MariaDB server using the `mariadb-secure-installation`

```txt
[root@galera-71 /]# mariadb-secure-installation

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

Take note here that for the prompt, `Switch to unix_socket authentication [Y/n] Y`, we answered "Y" to this question as I wanted to keep my database `root` user linked with my OS `root` user, you can specify "N" here to change this setup and specify your own root password.

If we look closely, we also specified the root password during the secure installation process. This means, if we are not logged in as the OS `root` user, we can still connect to MariaDB using this specific password else we can connect without any password if already connected to the OS `root` user.

### Create the MariaBackup user account

This is important, as Galera needs to have a special account in the database that has the privileges to run `MariaBackup` tool.

```txt
MariaDB [(none)]> CREATE USER backupuser@localhost IDENTIFIED BY 'SecretP@ssw0rd';
Query OK, 0 rows affected (0.009 sec)

MariaDB [(none)]> GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO backupuser@localhost;
Query OK, 0 rows affected (0.009 sec)
```

Perform the same setup (creating the backupuser and grants) on the other **two Galera** nodes before proceeding.

Our servers are now ready, time to stop MariaDB processes and define Galera specific configurations

Edit the /etc/my.cnf.d/server.cnf file and edit the `[mariadb]` section as follows

```txt
[mariadb]
log_error
```

This will enable error logging on the server in, always a good idea to keep this enabled to monitor the server properly.

Edit the `[galera]` section as follows, also take note the `innodb_buffer_pool_size`, `innodb_log_file_size` & `max_allowed_packet` are just values for a very small setup, These needs to be adjusted depending on your server size and application requirements.

```txt
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so
wsrep_cluster_address=gcomm://192.168.56.71,192.168.56.72,192.168.56.73
wsrep_provider_options="pc.weight=2"
wsrep_sst_method=mariabackup
wsrep_sst_auth=backupuser:SecretP@ssw0rd

binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=512M
innodb_log_file_size=512M
max_allowed_packet=256M

## Galera Node Configuration
wsrep_node_address=192.168.56.71
wsrep_node_name=galera-71

## Allow server to accept connections on all interfaces.
bind-address=0.0.0.0
```

Let's look through the above section and explain what is the purpose for each line.

- **`wsrep_on=ON`**
  - This enables Galera service on the node
- **`wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so`**
  - This tells Galera on the location of the Galera libraries. In case you have a custom path selected for installation, this should point to the specific location. Ensure that the `libgalera_smm.so` is available at the location selected.
- **`wsrep_cluster_address=gcomm://192.168.56.71,192.168.56.72,192.168.56.73`**
  - This holds the list of all the IP addresses of each node in the galera cluster. At the moment we have only one node available, but we have provided 3 different IP as we are going to setup the other two after this.
- **`wsrep_provider_options="pc.weight=2"`**
  - This is **important** for a two data center setup. Set this to `pc.weight=2` for the two nodes in one data center, and `pc.weight=1` for the two nodes on the DR data center. This will define that the primary data center will have the higher weightage and will help establish quorum.
- **`wsrep_sst_method=mariabackup`**
  - This is very important, this is used to define how the new nodes or SST is handled. Configure it as using `mariabackup` this will make sure that the node is always available even when it's playing the part of a Doner's.
    - Refer to <https://mariadb.com/kb/en/mariabackup-sst-method/> for full details on this process.
- **`wsrep_sst_auth=backupuser:SecretP@ssw0rd`**
  - This is also very **important**, it let's Galera know the user **name** and **password** to be used for the internal SST events. For this we have already created the `backupuser@localhost` account and granted the necessary priviliges to be able to run mariabackup on all the ndoes already.
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
- **`wsrep_node_address=192.168.56.71`**
  - This is important, this parameter tells galera the IP of this particular node. Each node will have their respective IP addresses mentioned for this property, take note!
- **`wsrep_node_name=galera-71`**
  - The name of this Galera Node, its up to us to chose what we want and should be in reference to individual node, the above config is for the node 71, for node 72 and 73, we will have to chose a different node name.
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
[root@galera-71 ~]# galera_new_cluster
```

Connect to mariadb client and check Galera cluster status

```txt
MariaDB [(none)]> show global status like 'wsrep_cluster_size';
+-----------------------+-------+
| Variable_name         | Value |
+-----------------------+-------+
| wsrep_cluster_size    | 1     |
+-----------------------+-------+
1 rows in set (0.000 sec)
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
```

We now have a Galera cluster up and running! At this point, we can connect to any node and perform DDL/DML and everything we do should get synced up with the other two nodes in the cluster.

Next we will install MaxScale 2.3/2.4 and configure it connect to this Galera clustster.

### Restarting a Galera Cluster

As we have seen, starting the cluster, we need to bootstrap the first node using `galera_new_cluster` shutting must be taken care by stopping the node that was running bootstrap as the last node to shutdown. If due to some reason the order is not followed when stoping the servers. On can refer to the file `/var/lib/mysql/grastate.dat` and look for the parameter that says `safe_to_bootstrap` The server that says `safe_to_bootstrap:1` is the node that needs to run `galera_new_cluster` followed by other nodes by simply using `systemctl start mariadb`. Following is an example of the `grastate.dat`

```txt
# GALERA saved state
version: 2.1
uuid:    9acf4d34-acdb-11e6-bcc3-d3e37276729f
seqno:   15
safe_to_bootstrap: 1
```

When bootstrapping the new cluster, Galera will refuse to use as a first node a node that was marked as unsafe to bootstrap from. You will see the following message in the logs:

```txt
It may not be safe to bootstrap the cluster from this node. It was not the last one to leave the cluster and may not contain all the updates.
To force cluster bootstrap with this node, edit the grastate.dat file manually and set safe_to_bootstrap to 1
```

## MaxScale 2.3/2.4

Setup and config is the same for 2.3 or 2.4

### Install MaxScale

Download the MaxScale RPM file from the <https://mariadb.com/downloads/#mariadb_platform-mariadb_maxscale> for the specific server, we will be downloading CentOS 7 2.4.10 version which is the latest GA at this point in time.

Download the RPM and transfer the file to the MaxScale VM. Like for MariaDB, I will download the RPM directly on the MaxScale VM and run through the installation process.

```txt
[root@maxscale-70 tmp]# wget https://downloads.mariadb.com/MaxScale/2.4.10/centos/7/x86_64/maxscale-2.4.10-1.centos.7.x86_64.rpm
--2019-04-24 15:59:14--  https://downloads.mariadb.com/MaxScale/2.4.10/centos/7/x86_64/maxscale-2.4.10-1.centos.7.x86_64.rpm
Resolving downloads.mariadb.com (downloads.mariadb.com)... 51.255.85.11
Connecting to downloads.mariadb.com (downloads.mariadb.com)|51.255.85.11|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 24290292 (23M) [application/x-redhat-package-manager]
Saving to: ‘maxscale-2.4.10-1.centos.7.x86_64.rpm’

100%[=============================================================================>] 24,290,292  2.38MB/s   in 15s    

2019-04-24 15:59:30 (1.57 MB/s) - ‘maxscale-2.4.10-1.centos.7.x86_64.rpm’ saved [24290292/24290292]

[root@maxscale-70 tmp]# ls -lrt
total 23728
-rw-------. 1 root root        0 Jan 28 13:52 yum.log
-rw-r--r--  1 root root 24290292 Apr 18 04:00 maxscale-2.4.10-1.centos.7.x86_64.rpm
[root@maxscale-70 tmp]# 
```

The MaxScale 2.4.10 has been downloaded on the VM, we can now use `yum` to install this. Remember to remove the old MariaDB packages like how we did for the MariaDB server installation.

```txt
[root@maxscale-70 tmp]# rpm -qa | grep -i mariadb
mariadb-libs-5.5.70-1.el7_5.x86_64
[root@maxscale-70 tmp]# rpm -e --nodeps mariadb-libs-5.5.70-1.el7_5.x86_64
```

Now we are ready to install MaxScale 2.3 on this new VM.

```txt
[root@maxscale-70 tmp]# yum -y install maxscale-2.4.10-1.centos.7.x86_64.rpm
Loaded plugins: fastestmirror
Examining maxscale-2.4.10-1.centos.7.x86_64.rpm: maxscale-2.4.10-1.x86_64
Marking maxscale-2.4.10-1.centos.7.x86_64.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package maxscale.x86_64 0:2.4.10-1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=======================================================================================================================
 Package               Arch                Version                Repository                                      Size
=======================================================================================================================
Installing:
 maxscale              x86_64              2.4.10-1                /maxscale-2.4.10-1.centos.7.x86_64               92 M

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
  Installing : maxscale-2.4.10-1.x86_64                                                                             1/1 
  Verifying  : maxscale-2.4.10-1.x86_64                                                                             1/1 

Installed:
  maxscale.x86_64 0:2.4.10-1                                                                                            

Complete!

[root@maxscale-70 tmp]# rpm -qa | grep maxscale
maxscale-2.4.10-1.x86_64
[root@maxscale-70 tmp]# 
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

Edit the /etc/maxscale.cnf file and delete all of it's contents and then insert the following set of configurations.

```txt
[maxscale]
threads=auto

# List of servers in the Cluster
[Galera-71]
type=server
address=192.168.56.71
port=3306
protocol=MariaDBBackend
priority=1

[Galera-72]
type=server
address=192.168.56.72
port=3306
protocol=MariaDBBackend
priority=2

[Galera-73]
type=server
address=192.168.56.73
port=3306
protocol=MariaDBBackend
priority=3

# Monitoring for the Galera server nodes
[Galera-Monitor]
type=monitor
module=galeramon
servers=Galera-71,Galera-72,Galera-73
user=maxuser
password=SecretP@ssw0rd

monitor_interval=2500
use_priority=true
available_when_donor=true

# Galera Read/Write Splitter service
[Galera-RW-Service]
type=service
router=readwritesplit
servers=Galera-71,Galera-72,Galera-73
user=maxuser
password=SecretP@ssw0rd


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
- Next set of sections (`[Galera-71]`) lists the servers we want MaxScale to monitor and use. Each section name is up to us what we want to call the server. I have used the following to indicate thir IP address
  - Galera-71
  - Galera-72
  - Galera-73
- Based on the above setup, Galera-71 has the highest priority=1, this will always be the Master node for MaxScale, if down a server with lower priority will be selected as Master.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-galera-monitor/#interaction-with-server-priorities>
- **`[Galera-Monitor]`**
  - This section of the configuration tells MaxScale about how to monitor the servers and what type of servers are those.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-galera-monitor/> for details on available options for a Galera Monitor
    - **`module=galeramon`**
      - This indicates that the cluster to monitor is a Galera cluster, maxscale will handle it accordingly.
    - **`servers=Galera-71,Galera-72,Galera-73`**
      - Tells which servers to monitor. The server names are coma separated, these names should be the same names we configured in the list of server section before.
      - Normally all the servers defined in the cluster area listed here unless for a very specific reason we want to ignore a specific node we can remove it from this `servers` property.
    - **`user=maxuser`**
      - This tells which DB user to use for monitoring the cluster. We will need to create this user in the database before starting the maxscale service. Limited DB access is required for this user.
    - **`password=secretpassword`**
      - DB password for the user, it's currently mentioned in free text, but in normal secure installations, we can encrypt it using MaxScale encryption service.
      - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-encrypting-passwords/> for details
      - If using **MaxScale 2.3**, the parameter name has changed to **`passwd`** instead of `password`
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
    - **`servers=Galera-71,Galera-72,Galera-73`**
      - This tells MaxScale which servers are to be used for R/W splitting. You can remove a server from the list in case you don't want Reads or Writes going to that node. But usually all the servers are mentioned here.
    - **`user=maxuser`**
      - This tells which DB user to use for monitoring the cluster. We will need to create this user in the database before starting the maxscale service. Limited DB access is required for this user.
    - **`password=secretpassword`**
      - DB password for the user, it's currently mentioned in free text, but in normal secure installations, we can encrypt it using MaxScale encryption service.
      - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-23-encrypting-passwords/> for details
      - If using **MaxScale 2.3**, the parameter name has changed to **`passwd`** instead of `password`
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
[root@maxscale-70 ~]# systemctl restart maxscale

[root@maxscale-70 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬───────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State │ GTID │
├───────────┼───────────────┼──────┼─────────────┼───────┼──────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Down  │      │
├───────────┼───────────────┼──────┼─────────────┼───────┼──────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 0           │ Down  │      │
├───────────┼───────────────┼──────┼─────────────┼───────┼──────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 0           │ Down  │      │
└───────────┴───────────────┴──────┴─────────────┴───────┴──────┘
```

`maxctrl` is an internal MaxScale interface that can tell us a lot of info about the various MaxScale services and their status. Here we have used it to list the servers.

Important thing to take note here is that Galera don't use GTID, that's why the column is empty. To see if the server nodes are in sync or not, we can rely on the MaxScale output as shown later on.

MaxScale is showing the cluster as currently down even though the servers are up and running. Let's check the Galera internal status.

```txt
[root@galera-71 ~]# mariadb -uroot -p
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
2019-04-25 00:55:28   error  : [Galera-Monitor] Failed to connect to server 'Galera-71' ([192.168.56.71]:3306) when checking monitor user credentials and permissions: Host '192.168.56.70' is not allowed to connect to this MariaDB server
2019-04-25 00:55:28   error  : [Galera-Monitor] Failed to connect to server 'Galera-72' ([192.168.56.72]:3306) when checking monitor user credentials and permissions: Host '192.168.56.70' is not allowed to connect to this MariaDB server
2019-04-25 00:55:28   error  : [Galera-Monitor] Failed to connect to server 'Galera-73' ([192.168.56.73]:3306) when checking monitor user credentials and permissions: Host '192.168.56.70' is not allowed to connect to this MariaDB server
```

We can see the above errors, it seems MaxSCale is not able to connect to the backend servers. This is because we have yet to create the user **maxuser** on the database.

Let's create these two users and restart MaxScale service.

Connect to any of the three Galera nodes and create the following users.

```txt
MariaDB [(none)]>  create user maxuser@'%' identified by 'secretpassword';
Query OK, 0 rows affected (0.021 sec)

MariaDB [(none)]> grant select on mysql.user to maxuser@'%';
Query OK, 0 rows affected (0.017 sec)

MariaDB [(none)]> grant select on mysql.tables_priv to maxuser@'%';
Query OK, 0 rows affected (0.015 sec)

MariaDB [(none)]> grant select on mysql.db to maxuser@'%';
Query OK, 0 rows affected (0.015 sec)

MariaDB [(none)]> grant show databases on *.* to maxuser@'%';
Query OK, 0 rows affected (0.015 sec)
```

Limited SELECT privilege is needed on `mysql.user`, `mysql.tables_priv`, `mysql.db` and `SHOW DATABASE` on all databases.

With user creation and grants done, we should be able to verify this user from any of the Galera nodes, this user should already exist there thanks to Galera's internal replication.

Now restart the MaxScale service `systemctl restart maxscale` and verify the MaxScale logs, there shold be no errors there.

Let's restart MaxScale node and retry `maxctrl list servers` and `services`

```txt
[root@mx-70 ~]# maxctrl list servers;
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 0           │ Slave, Synced, Running  │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘

[root@mx-70 ~]# maxctrl list services;
┌───────────────────┬────────────────┬─────────────┬───────────────────┬─────────────────────────────────┐
│ Service           │ Router         │ Connections │ Total Connections │ Servers                         │
├───────────────────┼────────────────┼─────────────┼───────────────────┼─────────────────────────────────┤
│ Galera-RW-Service │ readwritesplit │ 0           │ 0                 │ Galera-71, Galera-72, Galera-73 │
└───────────────────┴────────────────┴─────────────┴───────────────────┴─────────────────────────────────┘
```

We have Galera now running with Galera-71 as the Master node based on our **priority** setup.

Important thing to take note that as long as one see "Synced" in the status, one can be sure that the nodes are in sync. Since Galera don't use GTID, this one of the ways to tell if the nodes are in sync or not.s

Let's Check the Monitors.

```txt
[root@maxscale-70 ~]# maxctrl list monitors
┌────────────────┬─────────┬─────────────────────────────────┐
│ Monitor        │ State   │ Servers                         │
├────────────────┼─────────┼─────────────────────────────────┤
│ Galera-Monitor │ Running │ Galera-71, Galera-72, Galera-73 │
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

MariaDB [(none)]> create database app_db;
Query OK, 1 row affected (0.011 sec)

MariaDB [(none)]> grant all on app_db.* to app_user@'%';
Query OK, 0 rows affected (0.014 sec)
```

In this specific test, we have created a new user `app_user` which can connect from any host because of `'%'` as the host, and created a new database `app_db`. We have also given full access on **app_db** and all its objects to the new user `app_user`.

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

From any of the Galera nodes, connect to MaxScale IP using `mariadb` CLI.

*Note: This can also be done by installing MariaDB-client on the MaxScale node and connecting to it using that client instead of using one of the Galera nodes to connect to MaxScale*

```txt
[root@galera-71 ~]# mariadb -uapp_user -p -h192.168.56.70 -P4006
Enter password: **********
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.3.14-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

```

- **-h** defines the host IP to connec to, **-P** (Capital "P") specifies the port number

We have successfully connected to MasScale on its R/W splitter listener port using the app_user.

Now we can check maxscale status to see if we actually see a new user connected, on the MaxScale node execute the following

```txt
root@maxscale-70 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 1           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 1           │ Slave, Synced, Running  │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 1           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

We now see **ONE** connection on all the three nodes. Whenever a client connects to MaxScale listener port, internally MaxScale connects to all three nodes and maintains the connectivity even after a node failure.

At this point, on our MaxScale connection, we can perform a READ and WRITE operation, and MaxScale R/W service will send the qieres to the respective nodes accordingly.

```txt
MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| galera-72  |
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
|      782 | galera-73  |
+----------+------------+
1 row in set (0.003 sec)
```

The first SELECT query was sent ot Galera-72, then we created a table and inserted some dummy data (782 rows), Then selected from the same table and this time `@@hostname` returned Galera-73 as the host where the SELECT query was executed.

Let's do a test to ensure our insert statements are always done on the Galera-71 since it is the Master node as far as MaxScale is concerned.

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
| 3078 | galera-71 |
| 3075 | galera-71 |
| 3072 | galera-71 |
+------+-----------+
3 rows in set (0.003 sec)
```

We inserted three rows and used `@@hostname` as the inmserted value, and we can see indeed it was executed on Galera-71 for all thre three inserts.

At this time, we can connect to any Galera node directly and verify that whatever we have done so far has been replicated to all three nodes.

One last test to see how the auto-failover works, on the Galera-71, shutdown the database using `systemctl stop mariadb` and then on the MaxScale node, check the list server's output

```txt
[root@maxscale-70 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Down                    │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 0           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

Galera-71 is down, and based on our priority setup, Galera-72 becomes the new master. Lets start the Galera-71 again and see what happens to the output.

We expect Galera-71 to become the master node again as it has the highest priority.

```txt
[root@maxscale-70 ~]# maxctrl list servers
┌───────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server    │ Address       │ Port │ Connections │ State                   │ GTID │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-71 │ 192.168.56.71 │ 3306 │ 0           │ Master, Synced, Running │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-72 │ 192.168.56.72 │ 3306 │ 0           │ Slave, Synced, Running  │      │
├───────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-73 │ 192.168.56.73 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└───────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

Indeed, Galera-71 becomes the new master once more.

Things to take note:

- All connections to the database must come from MaxScale using the MaxScale Listener Port defined in the maxscale.cnf
- Reads will go to the non Master nodes
- Writes will go to the Master node
- Priority defined in the server's definition will dictate which node becomes the master.
- If a it's requred to replace a server with a new node, one can simply `rm -rf /var/lib/mysql/*` on that node and just restart the MariaDB process. Galera will automatically innitiate SST (full system state transfer) and send a fresh mariabackup copy to this new node and sync it up without any human intervention.
- Mariabackup can be taken from any node.
- Backup restore process remains the same as in standard MariaDB server.

This concludes this setup guide.

### Thank you

Faisal Saeed
_Senior Solution Engineer @ MariaDB Corporation_
