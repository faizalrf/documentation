# MariaDB 10.3 Installation Guide

## Linux settings

There are just a few things that we are to adjust in the standard Linux installation before we commence, and this is to disable **SELinux** and the Linux firewall (which is **firewalld** in CentOS and RedHat 7.0 and up)

These steps are to be carried out on all the servers involved in the setup.

#### Assumptions

- Use `root` user
- All the Latest *GA* MadiaDB/MaxScale RPMs have been already downloaded on the MariaDB and MaxScale servers
- MariaDB Platform Downloads
  - <https://mariadb.com/downloads/#mariadb_platform-enterprise_server>
  - <https://mariadb.com/downloads/#mariadb_platform-mariadb_maxscale>

#### Disable SELinux

For this make sure that your SELinux configuration, in the file /etc/selinux/config,  looks something like this:

```bash
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

The change here is the SELinux setting of course.

After a reboot of the server, check if the SELinux has actually been disabled, use either of the two commands (sestatus/getenforce) to confirm

```bash
[root@localhost ~] sestatus
SELinux status:                 disabled

[root@localhost ~] getenforce
Disabled
```

#### Disable firewalld

Firewalld is a standard service that is disabled using the systemctl command on the REHL 7/CETOS 7. After disabling double check using the *systemctl status firewalld*:

```bash
[root@localhost ~] systemctl stop firewalld

[root@localhost ~] systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.

[root@localhost ~] systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

```

#### Setup up the mysql account

The following will add the mysql user and group followed by granting `sudo` privilege to the mysql user. Following this, all steps will be done using mysql user with the help of `sudo`

Remember to also set `mysql` user's password

```bash
[root@localhost ~] groupadd mysql
[root@localhost ~] useradd -g mysql mysql

[root@localhost ~] echo "mysql ALL=(ALL) ALL" >> /etc/sudoers

[root@localhost ~] passwd mysql
Changing password for user mysql.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
```

### Installing MariaDB

Untar the downloaded `mariadb-10.X.X-rhel-7-x86_64-rpms.tar` file in the /tmp/mariadb folder using `mysql` user

** *X.X will be the version number that was downloaded*

#### 1. Check for Old MariaDB

Use `rpm -qa` to check if the old 5.x libraries are present, these must be removed before we proceed with the installation. Copy the output from the `rpm -q` command and use it in the next command to remove the old libraries using `rpm -e --nodeps`  

```bash
[root@localhost ~] rpm -qa | grep -i mariadb
mariadb-libs-5.5.56-2.el7.x86_64

[root@localhost ~] rpm -e --nodeps mariadb-libs-5.5.56-2.el7.x86_64
[root@localhost ~]
```

#### 2. Install the Common and Compact RPMs

```bash
[root@localhost ~] su - mysql
[mysql@localhost ~]$ cd /tmp/mariadb
[mysql@localhost /tmp/mariadb]$ sudo rpm -ivh MariaDB-10.3.7-centos73-x86_64-compat.rpm MariaDB-10.3.7-centos73-x86_64-common.rpm

Preparing... ################################# [100%]
Updating / installing...
1:MariaDB-common-10.3.7-1.el7.cento################################# [ 50%]
2:MariaDB-compat-10.3.7-1.el7.cento################################# [100%]
[mysql@localhost /tmp/mariadb]$
```

#### 3. Install the remaining RPMs

Use the `yum` repository manager to install the remaining rpms in the following order, `yum` will ensure that all the required dependencies are automatically installed

***Note:** From the following, only MariaDB-10.3.7-centos73-x86_64-client.rpm will be installed on the MaxScale server, otherwise all the RPMs should be installed on the MariaDB servers.*

```bash
[mysql@localhost /tmp/mariadb]$ sudo yum -y install galera-25.3.23-1.rhel7.el7.centos.x86_64.rpm
[mysql@localhost /tmp/mariadb]$ sudo yum -y install MariaDB-10.3.7-centos73-x86_64-client.rpm
[mysql@localhost /tmp/mariadb]$ sudo yum -y install MariaDB-10.3.7-centos73-x86_64-backup.rpm
[mysql@localhost /tmp/mariadb]$ sudo yum -y install MariaDB-10.3.7-centos73-x86_64-shared.rpm
[mysql@localhost /tmp/mariadb]$ sudo yum -y install MariaDB-10.3.7-centos73-x86_64-server.rpm
```

##### Securing MariaDB Installation

After all the RPMs have been installed, start the `mariadb` service and secure the installation as follows. 

Pay attention to the prompts

```bash
[mysql@localhost /tmp/mariadb]$ sudo systemctl start mariadb
[mysql@localhost /tmp/mariadb]$ mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorization.

Set root password? [Y/n] Y
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
access.  This is also intended only for testing and should be removed
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

MariaDB installation is secure now, repeat the above steps on all the MariaDB nodes to complete the setup.

#### Important Folders to Take note of

- Server Config: `/etc/my.cnf.d/server.cnf`
- Data Directory: `/var/lib/mysql/` can be changed in the `server.cnf`
  - <https://mariadb.com/kb/en/library/server-system-variables/#datadir>  
- Temp Directory: important to set to a separate mount file system with at least **50Gb** of space to start with. Define the path under `server.cnf`
  - <https://mariadb.com/kb/en/library/server-system-variables/#tmpdir>
- Error Log Directory: `/var/lib/mysql/` can be changed in the `server.cnf`
  - <https://mariadb.com/kb/en/library/server-system-variables/#log_error>
- Redo Log Files
  - <https://mariadb.com/kb/en/library/xtradbinnodb-server-system-variables/#innodb_log_group_home_dir>
- Socket
  - <https://mariadb.com/kb/en/library/server-system-variables/#socket>

The full list of MariaDB variables: <https://mariadb.com/kb/en/library/server-system-variables/>

#### Setting Up Custom Folders

Use `root` user to perform the following steps.

- Check the current 'datadir' value

    ```sql
    [root@mariadb-201 etc]# mysql -uroot
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 8
    Server version: 10.3.8-MariaDB MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> show global variables like 'datadir';
    +---------------+-----------------+
    | Variable_name | Value           |
    +---------------+-----------------+
    | datadir       | /var/lib/mysql/ |
    +---------------+-----------------+
    1 row in set (0.001 sec)
    ```

- Stop mariadb with `systemctl stop mariadb`

- Create new filesystem on **different mounts points** for best performance, for this setup, I will be just making new folders for this test.

    ```bash
    [root@mariadb-201 /] mkdir -p /mariadb/data
    [root@mariadb-201 /] mkdir -p /mariadb/logs
    [root@mariadb-201 /] mkdir -p /mariadb/tmp
    [root@mariadb-201 /] mkdir -p /mariadb/redo_logs

    # Change the ownership of this new folder structure using CHOWN
    [root@mariadb-201 /] chown -R mysql:mysql /mariadb
    ```

- Now copy the default `/var/lib/mysql` folder to the new `/mariadb/data` folder and rename the old `/var/lib/mysql` folder to something else so that its no longer being referenced from anywhere.

    ```bash
    [root@mariadb-201 /] su - mysql
    [mysql@mariadb-201 ~]$ cp -R /var/lib/mysql/* /mariadb/data
    [mysql@mariadb-201 ~]$ mv /var/lib/mysql /var/lib/mysql.old
    ```

- Finally change the ownership of `/etc/my.cnf.d` folder to `mysql` user instead of `root`, after this the MariaDB configuration will be owned by `mysql` user.

    ```bash
    [root@mariadb-201 etc] chown -R mysql:mysql /etc/my.cnf.d
    [root@mariadb-201 etc]
    ```

- Edit the `/etc/my.cnf.d/server.cnf` and add the following parameters under the `[mysqld]` section

    ```bash
    [mysqld]
    datadir=/mariadb/data
    log_error=/mariadb/logs/mariadb.err
    tmpdir=/mariadb/tmp
    innodb_log_group_home_dir=/mariadb/redo_logs
    socket=/tmp/mariadb.sock
    ```

- Edit the `/etc/my.cnf.d/mysql-client.cnf` and add the `socket` parameters under the `[mysql]` section

    ```bash
    [mysql]
    socket=/tmp/mariadb.sock
    ```

- Restart the mariadb service and login to the mysql to verify.

    ```bash
    [root@mariadb-201 ~] systemctl restart mariadb
    [root@mariadb-201 ~] su - mysql
    Last login: Fri Jul  6 05:06:26 EDT 2018 on pts/0
    [mysql@mariadb-201 ~]$ mysql -uroot
    ```

    ```sql
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 8
    Server version: 10.3.8-MariaDB MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> show global variables like 'datadir';
    +---------------+----------------+
    | Variable_name | Value          |
    +---------------+----------------+
    | datadir       | /mariadb/data/ |
    +---------------+----------------+
    1 row in set (0.001 sec)

    MariaDB [(none)]> show global variables like 'tmpdir';
    +---------------+--------------+
    | Variable_name | Value        |
    +---------------+--------------+
    | tmpdir        | /mariadb/tmp |
    +---------------+--------------+
    1 row in set (0.001 sec)

    MariaDB [(none)]>
    ```

### Setting up Primary/Replica Nodes

##### Assumptions

We have a two nodes MariaDB server setup, all the above setup has been done on both nodes.

- 192.168.56.102:3306 – Server-1
  - 192.168.56.103:3306 - Server-2

Log in to `mysql` on both nodes and create the two users `repl_user` (control replication) and `app_user` (to connect to the database for normal DML operations as the application Functional ID) The name can be anything, but in this guide, we are using these names.

##### Bin-Logs and Server ID 

Before we do anything on the database servers i.e. create database accounts etc. We need to enable binary logging and other important configuration that will be needed later on.

Edit the `/etc/my.cnf.d/server.cnf` file and add the following confgurations on both nodes.

Only the server_id will change on each node, it should be a unique numebr identifying the server in the cluster. We will use 1000 on Serve-1 and 2000 on Server-2 

```bash
[mysqld]
server_id=1000
log_bin = mariadb-bin
log_bin_index = mariadb-bin.index
binlog_format = ROW
gtid_strict_mode = 1
bind_address = 0.0.0.0
log_slave_updates=1
log_error

[mysql]
prompt=\H [\d]>\_
```

Restart all the MariaDB processes `systemctl restart mariadb` before continuing with the next tasks.

##### Setup DB Users

Now that the binary logging and other configuration is in place, we can proceed with the user accounts setup.

```sql
MariaDB [(none)]> CREATE USER repl_user@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO repl_user@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> CREATE USER app_user@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO app_user@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

##### Primary DB

Restart the two database services using `systemctl restart mariadb` and log in to the  Primary DB and check the SERVER STATUS

```sql
server1 [(none)]> show master status;
+--------------------+----------+--------------+------------------+
| File               | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+--------------------+----------+--------------+------------------+
| mariadb-bin.000001 |   129955 |              |                  |
+--------------------+----------+--------------+------------------+
1 row in set (0.000 sec)

server1 [(none)]> select binlog_gtid_pos('mariadb-bin.000001', 129955);
+-----------------------------------------------+
| binlog_gtid_pos('mariadb-bin.000001', 129955) |
+-----------------------------------------------+
| 0-1000-10                                     |
+-----------------------------------------------+
1 row in set (0.000 sec)
```

This tells us that the Primary database has already moved on to 0-1000-10 transaction ID, when we set up the replica (slave) node, these transaction should automatically get pushed over to the replica node.

##### Replica Nodes

Since we are setting this up as a new setup, we don't need to take a backup from the Primary node and restore it on the Replica to setup replication. We don't even need to worry about the GTID, we will let the Replica start with an "EMPTY" GTID and the Primary should push all the transactions over.

First step is to tell the Replica node to start with an empty `GTID_SLAVE_POS`

```sql
server2 [(none)]> set global gtid_slave_pos="";
Query OK, 0 rows affected (0.098 sec)

server2 [(none)]> connect;
Connection id:    10
Current database: *** NONE ***

server2 [(none)]> show global variables like 'gtid_slave_pos';
+----------------+-------+
| Variable_name  | Value |
+----------------+-------+
| gtid_slave_pos |       |
+----------------+-------+
1 row in set (0.001 sec)

server2 [(none)]> CHANGE MASTER TO MASTER_HOST='192.168.56.61', MASTER_PORT=3306, MASTER_USER='repl_user', MASTER_PASSWORD='P@ssw0rd', MASTER_USE_GTID=current_pos;
Query OK, 0 rows affected (0.088 sec)

server2 [(none)]> start slave;
Query OK, 0 rows affected (0.063 sec)

server2 [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 192.168.56.61
                   Master_User: repl_user
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mariadb-bin.000001
           Read_Master_Log_Pos: 129955
                Relay_Log_File: server2-relay-bin.000002
                 Relay_Log_Pos: 130256
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
           Exec_Master_Log_Pos: 129955
               Relay_Log_Space: 130565
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
                    Using_Gtid: Current_Pos
                   Gtid_IO_Pos: 0-1000-10
       Replicate_Do_Domain_Ids: 
   Replicate_Ignore_Domain_Ids: 
                 Parallel_Mode: conservative
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for the slave I/O thread to update it
              Slave_DDL_Groups: 7
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 3
1 row in set (0.000 sec)
```

`MASTER_USE_GTID=current_pos` tells the MariaDB replica node to start with the current position which was set as empty string.

From the `show slave status\G` output we can also see the replica is using `Using_Gtid: Current_Pos` and it is already synced up to `Gtid_IO_Pos: 0-1000-10`

This confims that MariaDB is using GTID based replication which is required by MaxScale and is more efficient vs the traditional BINLOG position based replication.

##### Enable GTID based Replication

If you chose to go with BINLOG based replicaiton to begin with, it is quite easy to switch to GTID based replication.

Stop SLAVE, CHANGE MASTER to use GTID and START SLAVE, remember to check SLAVE STATUS to ensure GTID is being used and no errors

_**Note:** This is only applicable if the current setup is not using GTID based replication_

```sql
server2 [(none)]> STOP SLAVE;
Query OK, 0 rows affected (0.009 sec)

server2 [(none)]> CHANGE MASTER TO MASTER_USE_GTID=slave_pos;
Query OK, 0 rows affected (0.013 sec)

server2 [(none)]> START SLAVE;
Query OK, 0 rows affected (0.009 sec

server2 [(none)]> SHOW SLAVE STATUS\G;
...
...
```

Primary/Replica replication setup is done, test using the `app_user` on the Primary node!

Remember that currently we are not using MaxScale and both Primary and Replica are writeable based on the `server.cnf` setup. If there is no MaxScale in the picture, one must edit the Replica DB's `server.cnf` and add `read_only=1` under `mysqld` tag and restart the DB

- <https://mariadb.com/kb/en/library/server-system-variables/#read_only>

### Setting up MaxScale 2.3.x

#### Assumptions

- Latest MaxScale Binaries from <https://mariadb.com/downloads/mariadb-tx/maxscale> have been downloaded and the RPM transferred to MaxScale server

- Selinux and Firewalld has been disabled  

#### Setup up the maxscale account

The following will add the mysql user and group followed by granting `sudo` privilege to the mysql user. Following this, all steps will be done using mysql user with the help of `sudo`

Remember to also set `maxscale` user's password

```bash
[root@localhost ~] groupadd maxscale
[root@localhost ~] useradd -g maxscale maxscale

[root@localhost ~] echo "maxscale ALL=(ALL) ALL" >> /etc/sudoers

[root@localhost ~] passwd maxscale
Changing password for user maxscale.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
```

#### Install MaxScale 2.3.x

Switch user to `maxscale`, `cd` to the folder which contains maxscale RPM `/tmp/maxscale/` and use yum repository manager to install MaxScale

After installation, enable its service and start it. Remember to check the maxscale service status using `systemctl status maxscale` to ensure it has started successfully

```bash
[root@localhost ~] su - maxscale
[maxscale@localhost ~]$ cd /tmp/maxscale
[maxscale@localhost /tmp/maxscale]$ sudo yum install maxscal*.rpm
...
...
```

#### Setup MaxScale Cluster

MaxScale configuration is at `/etc/maxscale.cnf`. We are now ready to add MaxScale on top of our two node Primary/Replica setup

- 192.168.56.101 - MaxScale
  - 192.168.56.102:3306 – Server1
    - 192.168.56.103:3306 - Server2

Login to **Primary DB** MariaDB CLI and create two users, one to control MaxScale Monitoring and the other to control MariaDB Replication, following set of privileges are the minimum required to ensure smooth operation of all the MaxScale operations including auto failover and auto-rejoin.  

***Note:** Since we already have a running replication between Server-1 and Server-2, these two users will automatically be created on the Server-2 node.*

```sql
# USER (maxuser): ReadWrite-Splitter user, this user is going to be a
# part of the basic configuration

MariaDB [(none)]> CREATE USER 'maxuser'@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.user TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.db TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.tables_priv TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.roles_mapping TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SHOW DATABASES ON *.* TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

# USER (maxmon): MariaDBMon user
# user created for the monitor MariaDBMon, to pull state,
# do the failover, switchover and rejoin servers part of existing clusters

MariaDB [(none)]> CREATE USER maxmon@'%' IDENTIFIED BY 'secretpassword';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SUPER, RELOAD, REPLICATION CLIENT ON *.* TO maxmon@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

If using MariaDB from **10.2.2 to 10.2.10** extra grants are required.

```sql
GRANT SELECT ON mysql.* TO 'maxuser'@'%';
```

If using **MariaDB 10.5 with MaxScale 2.5**, additional grants 2 additional grants are needed for `maxuser` and `REPLICATION SLAVE` is needed for `maxmon` user.

```
MariaDB [(none)]> GRANT SELECT ON mysql.proxies_priv TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SELECT ON mysql.columns_priv TO 'maxuser'@'%';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT SUPER, RELOAD, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO maxmon@'%';
Query OK, 0 rows affected (0.001 sec)
```

#### MaxScale config

Edit the MaxScale config `/etc/maxscale.cnf`, delete all the existing contents of the file and add the following base configuration. Take note that the `user` and `password` are as per the ones we created earlier.

```bash
[maxscale]
threads=auto

[server1]
type=server
address=192.168.56.102
port=3306
protocol=MariaDBBackend

[server2]
type=server
address=192.168.56.103
port=3306
protocol=MariaDBBackend

# This is the replication-cluster-monitor, the servers_no_promotion will ensure node names mentioned there are never promoted as Primary nodes
[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=server1, server2
#servers_no_promotion=<ServerName for no promotion candidate>
user=maxmon
password=secretpassword
monitor_interval=2500
enforce_read_only_slaves=true
auto_failover=true
auto_rejoin=true

# This is the replication-rwsplit-service
[Read-Write-Service]
type=service
router=readwritesplit
servers=server1, server2
user=maxuser
password=secretpassword
master_reconnection=true
transaction_replay=true
master_failure_mode=error_on_write
slave_selection_criteria=ADAPTIVE_ROUTING

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=4006
```

The following are important for high avialability setup to ensure auto failover and transaction replay is enabled. Works with MaxScale 2.3 and higher

- auto_failover=true
- auto_rejoin=true
- master_reconnection=true
- transaction_replay=true

_**Note:** Refer to <https://mariadb.com/kb/en/maxscale-23-getting-started/> for complete configuration documentations._

Restart MaxScale service using `sudo systemctl restart maxscale`.

As MaxScale is now running, make sure to enable the service for it to auto-restart next time the server reboots

```bash
[maxscale@localhost ~]$ sudo systemctl enable maxscale
Created symlink from /etc/systemd/system/multi-user.target.wants/maxscale.service to /usr/lib/systemd/system/maxscale.service.

[maxscale@localhost ~]$ sudo systemctl is-enabled maxscale
enabled
```

##### MaxScale logs

Since MaxScale service has been enabled and its currently running, we can now `tail -f` the logs

```bash
[maxscale@localhost ~]$ tail -100f /var/log/maxscale/maxscale.log
MariaDB MaxScale /var/log/maxscale/maxscale.log Sun Jun 3 12:48:36 2018

----------------------------------------------------------------------------
2018-06-03 12:48:36 notice : Working directory: /var/log/maxscale
2018-06-03 12:48:36 notice : The collection of SQLite memory allocation statistics turned off.
2018-06-03 12:48:36 notice : Threading mode of SQLite set to Multi-thread.
2018-06-03 12:48:36 notice : MariaDB MaxScale 2.2.8 started
2018-06-03 12:48:36 notice : MaxScale is running in process 10664
2018-06-03 12:48:36 notice : Configuration file: /etc/maxscale.cnf
2018-06-03 12:48:36 notice : Log directory: /var/log/maxscale
2018-06-03 12:48:36 notice : Data directory: /var/lib/maxscale
2018-06-03 12:48:36 notice : Module directory: /usr/lib64/maxscale
2018-06-03 12:48:36 notice : Service cache: /var/cache/maxscale
2018-06-03 12:48:36 notice : Loading /etc/maxscale.cnf.
2018-06-03 12:48:36 notice : /etc/maxscale.cnf.d does not exist, not reading.
2018-06-03 12:48:36 notice : [cli] Initialise CLI router module
2018-06-03 12:48:36 notice : Loaded module cli: V1.0.0 from /usr/lib64/maxscale/libcli.so
2018-06-03 12:48:36 notice : [readwritesplit] Initializing statement-based read/write split router module.
2018-06-03 12:48:36 notice : Loaded module readwritesplit: V1.1.0 from /usr/lib64/maxscale/libreadwritesplit.so
2018-06-03 12:48:36 notice : [readconnroute] Initialise readconnroute router module.
2018-06-03 12:48:36 notice : Loaded module readconnroute: V1.1.0 from /usr/lib64/maxscale/libreadconnroute.so
2018-06-03 12:48:36 notice : [mariadbmon] Initialise the MariaDB Monitor module.
2018-06-03 12:48:36 notice : Loaded module mariadbmon: V1.5.0 from /usr/lib64/maxscale/libmariadbmon.so
2018-06-03 12:48:36 notice : Loaded module MariaDBBackend: V2.0.0 from /usr/lib64/maxscale/libmariadbbackend.so
2018-06-03 12:48:36 notice : Loaded module MySQLBackendAuth: V1.0.0 from /usr/lib64/maxscale/libmysqlbackendauth.so
2018-06-03 12:48:36 notice : Loaded module maxscaled: V2.0.0 from /usr/lib64/maxscale/libmaxscaled.so
2018-06-03 12:48:36 notice : Loaded module MaxAdminAuth: V2.1.0 from /usr/lib64/maxscale/libmaxadminauth.so
2018-06-03 12:48:36 notice : Loaded module MariaDBClient: V1.1.0 from /usr/lib64/maxscale/libmariadbclient.so
2018-06-03 12:48:36 notice : Loaded module MySQLAuth: V1.1.0 from /usr/lib64/maxscale/libmysqlauth.so
```

#### Check the cluster after MaxScale restart

```txt
[maxscale@localhost ~]$ maxctrl list servers

┌─────────┬────────────────┬──────┬─────────────┬──────────────────────┬────────────┐
│ Server  │ Address        │ Port │ Connections │ State                │ GTID       │
├─────────┼────────────────┼──────┼─────────────┼──────────────────────┼────────────┤
│ server1 │ 192.168.56.102 │ 3306 │ 0           │ Master, Running      │ 0-1000-70  │
├─────────┼────────────────┼──────┼─────────────┼──────────────────────┼────────────┤
│ server2 │ 192.168.56.103 │ 3306 │ 0           │ Slave, Running       │ 0-1000-70  │
└─────────┴────────────────┴──────┴─────────────┴──────────────────────┴────────────┘
```

everything is self explainatory, Connections column shows the number of connections to the backend servers through MaxScale server.

The last column displays the Global Transaction ID of each node, all the nodes should follow the GTID of the Primary node and are an indicator of the replica nodes to be in sync with the Primary nodes.

This concludes the MaxScale setup.

#### Testing Failover / Auto Rejoin Scenarios

- Make sure to use app_user account and not “root” or any user with “ALL” privileges as those users can still write to the replica which will break the replication.
- Install MariaDB-client on any server and connect to MaxScale server
- In case of both servers down, follow the proper sequence to start the servers
  - Start the DB Server with the **highest GTID** first.
  - Restart maxscale.
  - Start the DB server with the **lower GTID** in the cluster.
  - The startup sequence should always be the **highest GTID** followed by the **lower** ones in descending order.
    - If not followed, the servers will not be able to join the cluster properly as the transaction sequences will be out of sync.

#### Password/Security

The passwords in the example were all free text, as a test this works but for SIT/UAT/PROD environments the passwords should always be encrypted

- Generate the keys with the `maxkeys` command line by passing it the “.secrets” file and path

    ```bash
    shell> maxkeys /var/lib/maxscale/ .secrets
    ```

- Encrypted passwords are created by executing the `maxpasswd` command with the location of the “.secrets” file and the password you require to encrypt as an argument.

    ```bash
    shell> maxpasswd /var/lib/maxscale/ secretpassword
    61DD955512C39A4A8BC4BB1E5F116705
    ```

- The output of the maxpasswd command is a hexadecimal string, this should be inserted into the `/etc/maxscale.cnf` file in place of the ordinary, plain text, password. MaxScale will determine this as an encrypted password and automatically decrypt it before sending it the database server.

    ```bash
    [replication-rwsplit-service]
    type=service
    router=readwritesplit
    user=maxuser
    password=61DD955512C39A4A8BC4BB1E5F116705
    ```
