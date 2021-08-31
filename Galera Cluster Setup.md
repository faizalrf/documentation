# Setting up MariaDB Enterprise Galera Cluster 10.5 with MaxScale 2.5

## Environment Setup

Our environment consists of 3 node Galera cluster and One MaxScale running CentOS 7 / RHEL 7

At the time of this documentation, the latest version of **MariaDB is 10.5.10** and **MaxScale 2.5.13**

- MaxScale-70 (172.31.38.197)
  - Galera-71 (172.31.32.37)
  - Galera-72 (172.31.41.102)
  - Galera-73 (172.31.34.254)

### Disable SELinux

We will be disabling SELinux for the RHEL/CentOS VMs, to do this we will have to edit the SELinux configuration, in the file `/etc/selinux/config`, make sure to change SELINUX=disabled, after the edit is done, the config file should look like this:

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

Download the `tar` package from <https://mariadb.com/downloads/#mariadb_platform-enterprise_server> and transfer this tar file to all the three nodes where Galera is to be installed. For this test, the latest version is `mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms.tar` and will be using the same. 

### Download MariaDB Server

Select the latest Release for CentOS/RHEL from the above mentioned download portal. We are going to select CentOS 7 MariaDB Enterprise 10.5.10-7 as its the latest GA version available as of now 19-Jul-2021.

Once the version and OS has been selected, click the _Download_ button and download the tar file in a desired folder. Once, downloaded, we can now transfer the `tar` file to all the Galera VM under /tmp folder. 

Untar the package under `/tmp` on all **three Galera nodes**, this is what it will look like.

```txt
[root@galera1 ~]# cd /tmp

[root@galera1 tmp]# ls -rlt
total 110620
-rw-r--r--. 1 root root 113274880 Jul 19 12:35 mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms.tar

[root@s1 tmp]# tar -xvf mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms.tar
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/galera-enterprise-4-26.4.8-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/mariadb-columnstore-cmapi-1.4.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/jemalloc-3.6.0-1.el7.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/jemalloc-devel-3.6.0-1.el7.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-backup-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-client-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-common-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-compat-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-cracklib-password-check-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-devel-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-gssapi-server-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-hashicorp-key-management-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-rocksdb-engine-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-s3-engine-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-server-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-shared-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-spider-engine-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-xpand-engine-10.5.10_7-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-columnstore-engine-10.5.10_7_5.6.2-1.el7_9.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/MariaDB-columnstore-cmapi-1.5.x86_64.rpm
mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms/setup_repository
```

A bunch of RPM files will be extracted including the `galera-enterprise-4-26.4.8-1.el7_9.x86_64.rpm`. We are going to install a specific set of RPMs and keep the others for later if needed, such as `cracklib password check`, `rocksdb engine` etc.

### Install The MariaDB Server

Under the extracted folder, an ececutable script is also available `setup_repository` This is used for creating a local repository based on the extracted binaries. First step is to execute this script and the remainig installation will be a breeze.

Execute the `setup_repository` script on all three Galera nodes.

```txt
[root@galera1 mariadb-enterprise-10.5.10-7-centos-7-x86_64-rpms]# ./setup_repository
Repository file successfully created! Please install MariaDB Server with this command:

   yum install MariaDB-server
```

Now we can simply install MariaDB Enterprise Server, Enterprise Backup, There is no need to specifically install Galera as it's already installed for us we will just need to enable it in the configuration. 

Keep in mind, the Enterprise subscription price does not include Galera even though it is included in the package, but to use Galera, it's subscription must be purchased. 

To install the Enterprise server, we just need to do the following on all three nodes. The current directory can be anything now since we have alraedy 

```txt
[root@galera1 ~]# yum -y install MariaDB-server MariaDB-backup pigz

Dependencies Resolved

============================================================================================================================================================================================================================================================================================
 Package                                                                     Arch                                                           Version                                                                   Repository                                                       Size
============================================================================================================================================================================================================================================================================================
Installing:
 MariaDB-backup                                                              x86_64                                                         10.5.10_7-1.el7_9                                                         MariaDB                                                         7.0 M
 MariaDB-server                                                              x86_64                                                         10.5.10_7-1.el7_9                                                         MariaDB                                                          21 M
Installing for dependencies:
 MariaDB-client                                                              x86_64                                                         10.5.10_7-1.el7_9                                                         MariaDB                                                         7.0 M
 MariaDB-common                                                              x86_64                                                         10.5.10_7-1.el7_9                                                         MariaDB                                                          82 k
 MariaDB-compat                                                              x86_64                                                         10.5.10_7-1.el7_9                                                         MariaDB                                                         2.2 M
 galera-enterprise-4                                                         x86_64                                                         26.4.8-1.el7_9                                                            MariaDB                                                         1.2 M
 pigz                                                                        x86_64                                                         2.3.3-1.el7.centos                                                        extras                                                           68 k

Transaction Summary
============================================================================================================================================================================================================================================================================================
Install  2 Packages (+4 Dependent packages)

Total download size: 38 M
Installed size: 193 M
Downloading packages:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                                       319 MB/s |  38 MB  00:00:00
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : MariaDB-common-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  1/6
  Installing : MariaDB-compat-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  2/6
  Installing : MariaDB-client-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  3/6
  Installing : galera-enterprise-4-26.4.8-1.el7_9.x86_64                                                                                                                                                                                                                                4/6
  Installing : MariaDB-server-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  5/6
  Installing : MariaDB-backup-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  6/6
  Verifying  : MariaDB-compat-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  1/6
  Verifying  : MariaDB-backup-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  2/6
  Verifying  : galera-enterprise-4-26.4.8-1.el7_9.x86_64                                                                                                                                                                                                                                3/6
  Verifying  : MariaDB-client-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  4/6
  Verifying  : MariaDB-common-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  5/6
  Verifying  : MariaDB-server-10.5.10_7-1.el7_9.x86_64                                                                                                                                                                                                                                  6/6

Installed:
  MariaDB-backup.x86_64 0:10.5.10_7-1.el7_9                                                                                                    MariaDB-server.x86_64 0:10.5.10_7-1.el7_9

Dependency Installed:
  MariaDB-client.x86_64 0:10.5.10_7-1.el7_9                             MariaDB-common.x86_64 0:10.5.10_7-1.el7_9                             MariaDB-compat.x86_64 0:10.5.10_7-1.el7_9                             galera-enterprise-4.x86_64 0:26.4.8-1.el7_9

Complete!
```

We now have The latest MariaDB Enterprise server + Galera installed on one node. Repeat the same steps on the other two MariaDB servers so that `rpm -qa | grep -i mariadb` & `rpm -qa | grep -i galera` shows the same output on all three nodes.

### Setting up Galera

To Start the Galera, we need to bootstrap the cluster from one of the nodes, but before that, we need to configure all the servers first.

Edit the /etc/my.cnf.d/server.cnf and add the following in the `[galera]`, `[mariadb]` & `[sst]` sections

***Note:** `[sst]` section needs to be defined as it does not exists by default.*

```txt
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_enterprise_smm.so
wsrep_cluster_address=gcomm://172.31.32.37,172.31.41.102,172.31.34.254
wsrep_sst_method=mariabackup
wsrep_sst_auth=mysql:

# Local node setup
wsrep_node_address=172.31.32.37
wsrep_node_name=galera1

## Data Streaming for large transactions, this will start to stream transactions effecting more than 1000 rows to the other Galera nodes! Only enable if doing one time migration or loading
## Else the server TPS will be effected of permanently added
#wsrep_trx_fragment_unit=rows
#wsrep_trx_fragment_size=1000

#Galera Cache setup for performance as 5 GB, default location is on `datadir`
wsrep_provider_options="gcache.size=5G; gcache.keep_pages_size=5G; gcache.recover=yes; gcs.fc_factor=0.8;"

[sst]
inno-backup-opts="--parallel=4"
inno-apply-opts="--use-memory=8192M"
compressor="pigz"
decompressor="pigz -d"

[mariadb]
log_error=server.log
binlog_format=row

default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_lock_schedule_algorithm=FCFS
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=16G
innodb_log_file_size=1G

character-set-server = utf8
collation-server = utf8_unicode_ci

## Allow server to accept connections on all interfaces.
bind-address=0.0.0.0
```

Let's discuss the above variables:
- **`[galera]`**
  - **`wsrep_on=ON`**
    - This enables Galera on the server
  - **`wsrep_provider=/usr/lib64/galera/libgalera_enterprise_smm.so`**
    - This is the Enterprise Galera library, make sure the path is correct, the above is for the CentOS/RHEL envuronments using the MariaDB Enterprise server.
    - The path and filename is different for other OS and builds like community MariaDB.
    - Validate the path using `SHOW GLOBAL VARIABLES LIKE 'plugin_dir';`
  - **`wsrep_cluster_address=gcomm://192.168.56.71,192.168.56.72,192.168.56.73`**
    - This cluster address should have the list of internal IP addresses of rhe Galera nodes without spaces.
  - **`wsrep_sst_method=mariabackup`**
    - Galera will use MariaDB Backup to pefrorm full system state transfer SST when a full recovery/rebuild of a node is needed or a new node is added to the cluster.
  - **`wsrep_sst_auth=mysql:`**
    - the built-in `mysql@localhost` MariaDB & OS user will be used for MariaDB Galera SST, since `mysql@localhost` is an OS Authenticated used, there is no need to hardcode the password in the config file.
    - We do however, need to grant **BACKUP privileges to `mysql@localhost`** user once the cluster is up and running.
  - **`wsrep_node_address`** & **`wsrep_node_name`**
    - These two variables define the local node and should be unique for each node, the address is the IP address of the current node and node name, well, it's the node name, not necessarily the hostname but any text value that you want to define as the node name
  - **`wsrep_trx_fragment_unit=rows`** & **`wsrep_trx_fragment_size=1000`**
    - These two are new features in 10.5 and are used for streaming transactions as soon as the transaction size is larger than 1000 rows as defined in the variables
  - **`wsrep_provider_options`**
    - This defines some of the Galera specific properties, the most important is the `gcache.size` This must be large enough to support IST when a node is out of the cluster or down for some time. If the delta data is within the 5GB mark a FAST IST is performed to bring the node in sync with the cluster else a FULL SST is performed. 
- **`[sst]`**
  - This section defines the various MariaDB backup parameters for fastest backup/restore operation using parallel compression
  - make sure `pigz` is installed on all nodes
  - Parallel threads and memory used for `pigz` can be increased if more CPU / RAM is available on the server. The configured value is considering 32GB RAM and 8 CPU per node.
  - All these variables are not MariaDB server variables, these are just read by Galera during SST. That's why we can't see these variables using `SHOW GLOBAL VARIABLES` command.
- **`[mariadb]`**
  - **`binlog_format=row`**
    - Galera does not need binary logs in physical files, but ROW based binlog format is needed to be defined
  - **`innodb_autoinc_lock_mode=2`**
    - Fast AutoIncrement columns insertions
  - **`innodb_flush_log_at_trx_commit=0`**
    - Galera is based on fully sybchronous replication, flush logs at transaction commit = 1 is not needed, this makes it faster when it comes to write performance
  - **`innodb_buffer_pool_size`**
    - This variable MUST be configured to be 70% of the total RAM of the server, critical for best performance
  - **`innodb_log_file_size=1G`**
    - REDO Log file size, larger file means faster IO performance but longer recovery time, can be lower like 512M or so if the app is not write heavy.

Once the values are in and saved for each node according to the above explanation, we can now start the cluster.

To start the cluster, we need to bootstrap one node using `galera_new_cluster` command, once started, all the other nodes are started using standard `systemctl start mariadb` command. Once the cluster is started, after that nodes can be started and stopped as per normal using `systemctl start/stop mariadb` 

Let's start the cluster

```txt
[root@galera1 ~]# galera_new_cluster

[root@galera1 ~]# mariadb -uroot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 7
Server version: 10.5.10-7-MariaDB-enterprise MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show global status like 'wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+
1 row in set (0.004 sec)
```

The global status `wsrep_cluster_size` shows the number of nodes currently in the cluster, let's start the other two nodes and verify the cluster size.

```txt
MariaDB [(none)]> show global status like 'wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
1 row in set (0.001 sec)
```

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

### SST User

As we know, we have defined **`mysql@localhost`** user as the SST user who will be running Maria Backup when SST is needed, but we still need to grant the necessary privileges required by the user running Maria Backup.

Execute the following command from any of the three nodes, make suree all the  nodes are running as a 3 node cluster. 

```sql
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO mysql@localhost;
```

## MaxScale 2.5

Setup and configuration is the same for both MaxScale 2.4 and 2.5

### MaxScale Database User Setup

Connect to any of the Galera node and execute the following statements to create the `maxuser` and grants necessary for it to work with MaxScale.

```sql
CREATE USER maxuser@'%' IDENTIFIED BY 'SecretP@ssw0rd';
GRANT SELECT ON mysql.* TO maxuser@'%';
GRANT SHOW DATABASES, REPLICATION CLIENT ON *.* TO maxuser@'%';
GRANT SUPER ON *.* TO maxuser@'%';
```

### Install MaxScale

Download the MaxScale RPM file from the <https://mariadb.com/downloads/#mariadb_platform-mariadb_maxscale> for the specific OS, we will be downloading CentOS7 2.5.13 version which is the latest GA at this point in time.

Download the RPM and transfer the file to the MaxScale VM. Like we did for MariaDB, I have already downloaded the file to the MaxScale node.

```txt
[root@max1 ~]# ls -rlt
total 43440
-rw-r--r--. 1 root root 44463256 Jun  4 11:57 maxscale-2.5.13-1.rhel.7.x86_64.rpm
```

Now we are ready to install MaxScale 2.5 on this node.

```txt
[root@max1 ~]# yum -y install maxscale-2.5.13-1.rhel.7.x86_64.rpm

Dependencies Resolved

============================================================================================================================================================================================================================================================================================
 Package                                                       Arch                                                       Version                                                                Repository                                                                            Size
============================================================================================================================================================================================================================================================================================
Installing:
 maxscale                                                      x86_64                                                     2.5.13-1.rhel.7                                                        /maxscale-2.5.13-1.rhel.7.x86_64                                                     167 M
Installing for dependencies:
 gnutls                                                        x86_64                                                     3.3.29-9.el7_6                                                         base                                                                                 680 k
 libatomic                                                     x86_64                                                     4.8.5-44.el7                                                           base                                                                                  51 k
 nettle                                                        x86_64                                                     2.7.1-9.el7_9                                                          updates                                                                              328 k
 trousers                                                      x86_64                                                     0.3.14-2.el7                                                           base                                                                                 289 k

Transaction Summary
============================================================================================================================================================================================================================================================================================
Install  1 Package (+4 Dependent packages)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                                       9.6 
...
...
...

Installed:
  maxscale.x86_64 0:2.5.13-1.rhel.7

Dependency Installed:
  gnutls.x86_64 0:3.3.29-9.el7_6                                        libatomic.x86_64 0:4.8.5-44.el7                                        nettle.x86_64 0:2.7.1-9.el7_9                                        trousers.x86_64 0:0.3.14-2.el7

Complete!
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
- Sticky setting for Master failover
- Make the Galera cluster available even while SST is being performed

### MaxScale Configuration

It's time to edit the /etc/maxscale.cnf file and configure it to connect to our three 
node Galera cluster

Edit the **`/etc/maxscale.cnf`** file and delete all of it's contents and then insert the following set of configurations.

```txt
[maxscale]
threads=auto

# List of servers in the Cluster
[Galera-1]
type=server
address=172.31.32.37
port=3306
protocol=MariaDBBackend
priority=1

[Galera-2]
type=server
address=172.31.41.102
port=3306
protocol=MariaDBBackend
priority=2

[Galera-3]
type=server
address=172.31.34.254
port=3306
protocol=MariaDBBackend
priority=3

# Monitoring for the Galera server nodes
[Galera-Monitor]
type=monitor
module=galeramon
servers=Galera-1,Galera-2,Galera-3
user=maxuser
password=SecretP@ssw0rd

monitor_interval=2000
use_priority=true
available_when_donor=true

# This will ensure that the current master remains the master as long as it's up and dunning
disable_master_failback=true
backend_connect_timeout=3s
backend_write_timeout=3s
backend_read_timeout=3s

# Galera Read/Write Splitter service
[Galera-RW-Service]
type=service
router=readwritesplit
servers=Galera-1,Galera-2,Galera-3
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
- Next set of sections (`[Galera-1]`) lists the servers we want MaxScale to monitor and use. Each section name is up to us what we want to call the server. I have used the following to indicate thir IP address
  - Galera-1
  - Galera-2
  - Galera-3
- Based on the above setup, Galera-1 has the highest priority=1, this will always be the Master node for MaxScale, if down a server with lower priority will be selected as Master.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-25-galera-monitor/#use_priority> for Galera monitor configuration parameters.
- **`[Galera-Monitor]`**
  - This section of the configuration tells MaxScale about how to monitor the servers and what type of servers are those.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-25-galera-monitor/#galera-monitor> for details on available options for a Galera Monitor
    - **`module=galeramon`**
      - This indicates that the cluster to monitor is a Galera cluster, maxscale will handle it accordingly.
    - **`servers=Galera-1,Galera-2,Galera-3`**
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
    - **`disable_master_failback=true`** 
      - This makes sure that the current Master remains the Master as long as the node is up and running. This will increase the stability of the transaction with minimum disaturbance to the application.
- **`[Galera-RW-Service]`**
  - This section controls the Read / Write splitting and controls how connections and ongoing transactions are handlked in case of node failures.
  - Refer to <https://mariadb.com/kb/en/mariadb-maxscale-25-readwritesplit/> for details on various avilable options
    - **`router=readwritesplit`**
      - Tells that this section is a router and it's for R/W splitting
    - **`servers=Galera-1,Galera-2,Galera-3`**
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
      - refer to <https://mariadb.com/kb/en/mariadb-maxscale-25-readwritesplit/#transaction_replay_retry_on_deadlock> for more details.
    - **`slave_selection_criteria=ADAPTIVE_ROUTING`**
      - There are multiple ways MaxScale can select a node for READ queries. ADAPTIVE_ROUTING tells MaxScale to select a node which has the best average response time.
      - Look at <https://mariadb.com/kb/en/mariadb-maxscale-25-readwritesplit/#slave_selection_criteria> for available options
- **`[Galera-Listener]`**
  - This is the listener for the R/W splitter service `[Galera-Service]`
    - **`protocol=MariaDBClient`**
      - Tells MaxScale that this listener will listen to all MariaDB client connections.
      - **`port=4006`**
        - When application connect to MariaDB, they will connect through MaxScale using MaxScale IP and this **PORT**
- `[MaxAdmin-Service]` & `[MaxAdmin-Listener]`
  - These are internal services to MaxScale, check the MariaDB MaxSCale Knowledgbase for more details.
-
### Usig MaxScale

Let's start MaxScale Service and use it to connect to the Galera Cluster. We need to make sure that the IP addresses defined in the `[Galera-1], [Galera-2] & [Galera-3]` are correct. Furthermore, the USER `maxuser` is already created with the defined password and required GRANT as defined in the **`MaxScale Database User Setup`** section

```
[root@max1 ~]# systemctl start maxscale
[root@max1 ~]# systemctl status maxscale
● maxscale.service - MariaDB MaxScale Database Proxy
   Loaded: loaded (/usr/lib/systemd/system/maxscale.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-07-19 17:28:30 UTC; 5min ago
  Process: 21260 ExecStart=/usr/bin/maxscale (code=exited, status=0/SUCCESS)
  Process: 21257 ExecStartPre=/usr/bin/install -d /var/lib/maxscale -o maxscale -g maxscale (code=exited, status=0/SUCCESS)
  Process: 21255 ExecStartPre=/usr/bin/install -d /var/run/maxscale -o maxscale -g maxscale (code=exited, status=0/SUCCESS)
 Main PID: 21262 (maxscale)
   CGroup: /system.slice/maxscale.service
           └─21262 /usr/bin/maxscale

Jul 19 17:28:30 max1 maxscale[21262]: 'Galera-3' sent version string '10.5.10-7-MariaDB-enterprise'. Detected type: 'MariaDB', version: 10.5.10.
Jul 19 17:28:30 max1 maxscale[21262]: Server 'Galera-3' charset: utf8
Jul 19 17:28:30 max1 maxscale[21262]: Server changed state: Galera-1[172.31.32.37:3306]: master_up. [Down] -> [Master, Synced, Running]
Jul 19 17:28:30 max1 maxscale[21262]: Server changed state: Galera-2[172.31.41.102:3306]: slave_up. [Down] -> [Slave, Synced, Running]
Jul 19 17:28:30 max1 maxscale[21262]: Server changed state: Galera-3[172.31.34.254:3306]: slave_up. [Down] -> [Slave, Synced, Running]
Jul 19 17:28:30 max1 maxscale[21262]: Starting a total of 1 services...
Jul 19 17:28:30 max1 maxscale[21262]: (Galera-Listener) Listening for connections at [::]:4006
Jul 19 17:28:30 max1 maxscale[21262]: Service 'Galera-RW-Service' started (1/1)
Jul 19 17:28:30 max1 systemd[1]: Started MariaDB MaxScale Database Proxy.
Jul 19 17:28:31 max1 maxscale[21262]: Read 4 user@host entries from 'Galera-1' for service 'Galera-RW-Service'.
```

***Note:** MaxScale service is up and running, if service failed to start or any other issues, make sure the IP addresses and the username/passwords are correct.*

Let's varify the MaxScale and Galera servers through MaxScale monitoring

```
[root@max1 ~]# maxctrl list servers
┌──────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server   │ Address       │ Port │ Connections │ State                   │ GTID │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-1 │ 172.31.32.37  │ 3306 │ 0           │ Master, Synced, Running │      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-2 │ 172.31.41.102 │ 3306 │ 0           │ Slave, Synced, Running  │      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-3 │ 172.31.34.254 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└──────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘

[root@max1 ~]# maxctrl list services
┌───────────────────┬────────────────┬─────────────┬───────────────────┬──────────────────────────────┐
│ Service           │ Router         │ Connections │ Total Connections │ Servers                      │
├───────────────────┼────────────────┼─────────────┼───────────────────┼──────────────────────────────┤
│ Galera-RW-Service │ readwritesplit │ 0           │ 0                 │ Galera-1, Galera-2, Galera-3 │
└───────────────────┴────────────────┴─────────────┴───────────────────┴──────────────────────────────┘
```

We can see the servers are up and running and the read/write service is accessing all three nodes.

Let's test some failover scenarios.

We will now shutdown Galera Node 1 and see what MaxScale does to the servers.

```
[root@max1 ~]# maxctrl list servers
┌──────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server   │ Address       │ Port │ Connections │ State                   │ GTID │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-1 │ 172.31.32.37  │ 3306 │ 0           │ Down                    │      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-2 │ 172.31.41.102 │ 3306 │ 0           │ Master, Synced, Running │      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-3 │ 172.31.34.254 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└──────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

MaxScale identifies the failure and quickly moves the Master responsibilities to the second highest priority node, which is Galera-2. If the Galera 1 was to come back on line, Galera-2 will remain the Master. This is controlled by the MaxScale configuration `disable_master_failback=true` We want this behaviour so that the Master remains consistent as much as possible to avoid any disturbance to the application.

```
[root@max1 ~]# maxctrl list servers
┌──────────┬───────────────┬──────┬─────────────┬────────────────────────────────────────────┬──────┐
│ Server   │ Address       │ Port │ Connections │ State                                      │ GTID │
├──────────┼───────────────┼──────┼─────────────┼────────────────────────────────────────────┼──────┤
│ Galera-1 │ 172.31.32.37  │ 3306 │ 0           │ Slave, Synced, Running                     │      │
├──────────┼───────────────┼──────┼─────────────┼────────────────────────────────────────────┼──────┤
│ Galera-2 │ 172.31.41.102 │ 3306 │ 0           │ Master, Synced, Master Stickiness, Running │      │
├──────────┼───────────────┼──────┼─────────────┼────────────────────────────────────────────┼──────┤
│ Galera-3 │ 172.31.34.254 │ 3306 │ 0           │ Slave, Synced, Running                     │      │
└──────────┴───────────────┴──────┴─────────────┴────────────────────────────────────────────┴──────┘
```

We can see that the Sticky behaviour for the Master, but if the Galera-2 node is to go down, Master will move to Galera-1. Let's test that.

```
[root@max1 ~]# maxctrl list servers
┌──────────┬───────────────┬──────┬─────────────┬─────────────────────────┬──────┐
│ Server   │ Address       │ Port │ Connections │ State                   │ GTID │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-1 │ 172.31.32.37  │ 3306 │ 0           │ Master, Synced, Running │      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-2 │ 172.31.41.102 │ 3306 │ 0           │ Down                    │      │
├──────────┼───────────────┼──────┼─────────────┼─────────────────────────┼──────┤
│ Galera-3 │ 172.31.34.254 │ 3306 │ 0           │ Slave, Synced, Running  │      │
└──────────┴───────────────┴──────┴─────────────┴─────────────────────────┴──────┘
```

As expected, Master is not designated to Galera-1.

Things to take note:

- All connections to the database must come from MaxScale using the MaxScale Read/Write Listener Port `4006` defined in the maxscale.cnf
- Galera does not have standard Replicated GTID but it can be enabled if we want to set up a standalone slave to replicate off the Galera cluster or even replicate to a different cluster using asynchronous replication. 
  - https://github.com/mariadb-faisalsaeed/documentation/blob/master/MariaDB-10.5-ES-Galera%20ActiveActive.md
- Writes will go to the Master node
- Reads will go to the other nodes
- All the ndoes are Master (Read/Write) if we were to connect to the backend nodes directly, but writing from all the nodes can create dead/locks which is prevented by connecting through MaxScale. 
- Writing from all Master nodes does not scale writes but Read scaling is provided.
- Priority defined in the server's definition will dictate which node becomes the master.
- If a it's requred to replace a server with a new node, one can simply `rm -rf /var/lib/mysql/*` on that node and just restart the MariaDB process. Galera will automatically innitiate SST (full system state transfer) and send a fresh mariabackup copy to this new node and sync it up without any human intervention.
- Mariabackup can be taken from any node.
- Backup restore process remains the same as in standard MariaDB server.
- A dedicated user needs to be created for `mariabackup` other than the `mysql@localhost` which is used by Galera SST.
  ```sql
  CREATE USER backupuser@localhost identified by 'SecretP@ssw0rd';
  GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO backupuser@localhost;
  ```

This concludes this setup guide.

### Thank you

Faisal Saeed
_Senior Solution Engineer @ MariaDB Corporation_
