# MariaDB & The SELinux Menace

## Assumptions

- RHEL 7 or CentOS 7 with SELinux Enabled. 
- MariaDB is installed using all the default parameters.
  - As soon as we configure a component to use any non-default path such as `datadir` etc, SELinux will start to complain and block MariaDB from accessing the folder, you will see error messages like `permission denied` or `path not found` etc.
  - MariaDB is built with necessary policies to allow all the default parameters.

Easiest way to validate this is to execute `getenforce` 

```bash
$ sudo getenforce
Enforcing
```

## SELinux File Contexts

SELinux uses file context labeling to decide who gets access to which files and folders

File contexts are managed with the `semanage fcontext` and `restorecon` commands.

On many systems, the `semanage` utility is installed by the `policycoreutils-python` package, and the `restorecon` utility is installed by the `policycoreutils` package. 

If these utilities are not available on your RHEL/CentOS systems, You can install them with the following command:

```bash
$ sudo yum install policycoreutils policycoreutils-python
```

A file or directory's current context can be checked by executing `ls` with the `--context` or `--scontext` options.

Let's create a filesystem for MariaDB and a folder for it's data directory. We will set the MariaDB config later to point to this path.

```bash
$ sudo mkdir -p /mariadb/data
$ sudo chown -R mysql:mysql /mariadb/
$ sudo ls -ld /mariadb/ /mariadb/data/
drwxr-xr-x. 3 mysql mysql 18 Jun 29 07:44 /mariadb/
drwxr-xr-x. 2 mysql mysql  6 Jun 29 07:44 /mariadb/data/
```

Now that the folders are created and ownership has been changed to `mysql:mysql` we will try to check the folder's context

```bash
$ ls -ld --context /mariadb /mariadb/data/
drwxr-xr-x. mysql mysql unconfined_u:object_r:default_t:s0 /mariadb
drwxr-xr-x. mysql mysql unconfined_u:object_r:default_t:s0 /mariadb/data/
```

This means that the two folders have been granted access by SELinux to the user `unconfined_u` & the file context of `default_t`.

Let's verify the current filecontexts of `var/lib/mysql` folder which is the current default `datadir` for MariaDB. MariaDB has already set the policy at the time of installation, that is why It's working properly.

```bash
$ sudo ls -ld --context /var/lib/mysql
drwxr-xr-x. mysql mysql system_u:object_r:mysqld_db_t:s0 /var/lib/mysql
```

The last part of the context string `mysqld_db_t` is the one we want to pay attention to. This is the proper context that we want to have for the filesystem that is going to be used as the data directory. In our case it's the new folder `/mariadb/data` which has the current context of `default_t`, this means, if we set MariaDB to point to this folder as the new data directory, it will not work.

Let's try that out. First copy all the files and folders from the current `/var/lib/mysql` to the new `/mariadb/data` folder and then change ownership to `mysql:mysql`

```bash
$ sudo systemctl stop mariadb
$ sudo cp -R /var/lib/mysql/* /mariadb/data/

$ sudo chown -R mysql:mysql /mariadb
$ ls -lrt /mariadb/data/
total 176172
-rw-r-----. 1 mysql mysql    14508 Jun 29 08:02 ib_buffer_pool
-rw-r-----. 1 mysql mysql       52 Jun 29 08:02 aria_log_control
-rw-r-----. 1 mysql mysql    16384 Jun 29 08:02 aria_log.00000001
-rw-r-----. 1 mysql mysql 79691776 Jun 29 08:02 ibdata1
-rw-r-----. 1 mysql mysql 50331648 Jun 29 08:02 ib_logfile0
-rw-r-----. 1 mysql mysql        0 Jun 29 08:02 multi-master.info
-rw-r-----. 1 mysql mysql 50331648 Jun 29 08:02 ib_logfile1
drwx------. 2 mysql mysql     4096 Jun 29 08:02 mysql
drwx------. 2 mysql mysql       20 Jun 29 08:02 performance_schema
drwx------. 2 mysql mysql     4096 Jun 29 08:02 sbtest
drwx------. 2 mysql mysql       20 Jun 29 08:02 test
```

Set the following in the `/etc/my.cnf.d/server.cnf` file and start MariaDB `systemctl start mariadb`

```bash
[mariadb]
datadir=/mariadb/data
```

We are greeted with the following 

```
$ sudo systemctl start mariadb
Job for mariadb.service failed because the control process exited with error code. See "systemctl status mariadb.service" and "journalctl -xe" for details.
```

Let's see why, but we already know becasue the new datadir does not have the correct context that is allowed for MariaDB to use which is `mysqld_db_t`

We can execute `journalctl -xe` to see what's going on

```bash
$ sudo journalctl -xe

-- Unit mariadb.service has begun starting up.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] /usr/sbin/mysqld (mysqld 10.2.32-7-MariaDB-enterprise) starting as process 1568 ...
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Warning] Could not increase number of max_open_files to more than 16364 (request: 32183)
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Warning] Can't create test file /mariadb/data/es-201.lower-test
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Uses event mutexes
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Compressed tables use zlib 1.2.7
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Using Linux native AIO
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Number of pools: 1
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Using SSE2 crc32 instructions
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Initializing buffer pool, total size = 128M, instances = 1, chunk size = 128M
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Completed initialization of buffer pool
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140603686799104 [Note] InnoDB: If the mysqld execution user is authorized, page cleaner thread priority can be changed. See the man page of setpriority().
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] InnoDB: Operating system error number 13 in a file operation.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] InnoDB: The error means mysqld does not have the access rights to the directory.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] InnoDB: os_file_get_status() failed on './ibdata1'. Can't determine file permissions
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] InnoDB: Plugin initialization aborted with error Generic error
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] InnoDB: Starting shutdown...
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] Plugin 'InnoDB' init function returned error.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] Plugin 'InnoDB' registration as a STORAGE ENGINE failed.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] mysqld: File '/mariadb/data/aria_log_control' not found (Errcode: 13 "Permission denied")
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] mysqld: Got error 'Can't open file' when trying to use aria control file '/mariadb/data/aria_log_control'
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] Plugin 'Aria' init function returned error.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] Plugin 'Aria' registration as a STORAGE ENGINE failed.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [Note] Plugin 'FEEDBACK' is disabled.
Jun 29 08:09:46 es-201 mysqld[1568]: 200629  8:09:46 server_audit: MariaDB Audit Plugin version 1.4.7 STARTED.
Jun 29 08:09:46 es-201 mysqld[1568]: 200629  8:09:46 server_audit: Query cache is enabled with the TABLE events. Some table reads can be veiled.2020-06-29  8:09:46 140604253509824 [ERROR] Could not open mysql.plugin table. Some plugins may be not loaded
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] Failed to initialize plugins.
Jun 29 08:09:46 es-201 mysqld[1568]: 2020-06-29  8:09:46 140604253509824 [ERROR] Aborting
Jun 29 08:09:46 es-201 mysqld[1568]: 200629  8:09:46 server_audit: STOPPED
Jun 29 08:09:46 es-201 polkitd[670]: Unregistered Authentication Agent for unix-process:1510:268574 (system bus name :1.30, object path /org/freedesktop/PolicyKit1/AuthenticationAgent, locale en_US.UTF-8) (disconnected from bus)
Jun 29 08:09:46 es-201 systemd[1]: mariadb.service: main process exited, code=exited, status=1/FAILURE
Jun 29 08:09:46 es-201 mysqld[1568]: Warning: Memory not freed: 520
Jun 29 08:09:46 es-201 systemd[1]: Failed to start MariaDB 10.2.32-7 database server.
-- Subject: Unit mariadb.service has failed
```

We are seeing all sorts of permission deniedd errors for instance `Errcode: 13 "Permission denied"`

Let's try to fix this situation.

## Setting up File Contexts

First step to set the proper filesystem context `mysqld_db_t` to the path `/mariadb/data` structure and then use `restorecon` to assign this context to all the files and folders within the structure.

- `sudo semanage fcontext -a -t mysqld_db_t "/mariadb/data(/.*)?"`
- `sudo restorecon -Rv /mariadb/data`

```bash
$ sudo semanage fcontext -a -t mysqld_db_t "/mariadb/data(/.*)?"
$ sudo restorecon -Rv /mariadb/data
restorecon reset /mariadb/data context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/aria_log.00000001 context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/aria_log_control context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/ib_buffer_pool context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/ibdata1 context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/ib_logfile0 context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/ib_logfile1 context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/multi-master.info context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/mysql context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
...
...
...
restorecon reset /mariadb/data/sbtest/sbtest1.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest1.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest2.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest2.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest3.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest3.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest4.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest4.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest5.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest5.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest6.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest6.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest7.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest7.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest8.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest8.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest9.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest9.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest10.frm context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/sbtest/sbtest10.ibd context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/test context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
restorecon reset /mariadb/data/test/db.opt context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_db_t:s0
```

This will list all the files and folders applying the new contexts to each and every one of those.

We will now verify the `ls --context`

```bash
$ sudo ls --context /mariadb /mariadb/*
/mariadb:
drwxr-xr-x. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 data

/mariadb/data:
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 aria_log.00000001
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 aria_log_control
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 ib_buffer_pool
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 ibdata1
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 ib_logfile0
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 ib_logfile1
-rw-r-----. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 multi-master.info
drwx------. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 mysql
drwx------. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 performance_schema
drwx------. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 sbtest
drwx------. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 test
```

This is what we want to see, the filesystem tagged with the correct context string as `mysqld_db_t`

Ket's try to restart MariaDB service and see if it works this time.

```bash
$ sudo systemctl start mariadb
$ sudo systemctl status mariadb
● mariadb.service - MariaDB 10.2.32-7 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Mon 2020-06-29 08:24:40 EDT; 5s ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 1697 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 1615 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/..; /usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 1613 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 1665 (mysqld)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─1665 /usr/sbin/mysqld --basedir=/usr

Jun 29 08:24:40 es-201 mysqld[1665]: 2020-06-29  8:24:40 139818051720960 [Note] InnoDB: Loading buffer pool(s) from /mariadb/data/ib_buffer_pool
Jun 29 08:24:40 es-201 mysqld[1665]: 2020-06-29  8:24:40 139818634361024 [Note] Plugin 'FEEDBACK' is disabled.
Jun 29 08:24:40 es-201 mysqld[1665]: 200629  8:24:40 server_audit: MariaDB Audit Plugin version 1.4.7 STARTED.
Jun 29 08:24:40 es-201 mysqld[1665]: 200629  8:24:40 server_audit: Query cache is enabled with the TABLE events. Some table reads can be veiled.2020-06-29  8:24:40 139818634361024 [Note] Server socket created on IP: '::'.
Jun 29 08:24:40 es-201 mysqld[1665]: 2020-06-29  8:24:40 139818051720960 [Note] InnoDB: Buffer pool(s) load completed at 200629  8:24:40
Jun 29 08:24:40 es-201 mysqld[1665]: 2020-06-29  8:24:40 139818634361024 [Note] Reading of all Master_info entries succeeded
Jun 29 08:24:40 es-201 mysqld[1665]: 2020-06-29  8:24:40 139818634361024 [Note] Added new Master_info '' to hash table
Jun 29 08:24:40 es-201 mysqld[1665]: 2020-06-29  8:24:40 139818634361024 [Note] /usr/sbin/mysqld: ready for connections.
Jun 29 08:24:40 es-201 mysqld[1665]: Version: '10.2.32-7-MariaDB-enterprise'  socket: '/var/lib/mysql/mysql.sock'  port: 3306  MariaDB Enterprise Server
Jun 29 08:24:40 es-201 systemd[1]: Started MariaDB 10.2.32-7 database server.
```

And ndeed, it works flawlessly.

Next step, we will setup a log folder within /mariadb and see if that works or not.

```bash
$ sudo mkdir /mariadb/log
$ sudo chown -R mysql:mysql /mariadb/log/
$ sudo ls --context /mariadb /mariadb/log/
/mariadb:
drwxr-xr-x. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 data
drwxr-xr-x. mysql mysql unconfined_u:object_r:default_t:s0 log
```

We can see the `data` folder has the correct context but the newly created folder does not. Starting up the service with `log_error=/mariadb/log/server.log` will fail for sure. Let's try

My `server.cnf` looks like this

```bash
[mariadb]
datadir=/mariadb/data
log_error/mariadb/log/server.log
```

```bash
$ sudo systemctl restart mariadb
Job for mariadb.service failed because the control process exited with error code. See "systemctl status mariadb.service" and "journalctl -xe" for details.
```

As expected it did not work.

Let's see what are all the contexts that have been set by MariaDB's default installation using `sudo semanage fcontext --list | grep mysqld`

```bash
$ sudo semanage fcontext --list | grep mysqld
/etc/mysql(/.*)?                                   all files          system_u:object_r:mysqld_etc_t:s0
/etc/my\.cnf\.d(/.*)?                              all files          system_u:object_r:mysqld_etc_t:s0
/var/log/mysql.*                                   regular file       system_u:object_r:mysqld_log_t:s0
/var/lib/mysql(-files|-keyring)?(/.*)?             all files          system_u:object_r:mysqld_db_t:s0
/var/run/mysqld(/.*)?                              all files          system_u:object_r:mysqld_var_run_t:s0
/var/log/mariadb(/.*)?                             all files          system_u:object_r:mysqld_log_t:s0
/var/run/mariadb(/.*)?                             all files          system_u:object_r:mysqld_var_run_t:s0
/usr/sbin/mysqld(-max)?                            regular file       system_u:object_r:mysqld_exec_t:s0
/var/run/mysqld/mysqlmanager.*                     regular file       system_u:object_r:mysqlmanagerd_var_run_t:s0
/usr/lib/systemd/system/mysqld.*                   regular file       system_u:object_r:mysqld_unit_file_t:s0
/usr/lib/systemd/system/mariadb.*                  regular file       system_u:object_r:mysqld_unit_file_t:s0
/etc/my\.cnf                                       regular file       system_u:object_r:mysqld_etc_t:s0
/root/\.my\.cnf                                    regular file       system_u:object_r:mysqld_home_t:s0
/usr/sbin/ndbd                                     regular file       system_u:object_r:mysqld_exec_t:s0
/usr/libexec/mysqld                                regular file       system_u:object_r:mysqld_exec_t:s0
/usr/bin/mysqld_safe                               regular file       system_u:object_r:mysqld_safe_exec_t:s0
/usr/bin/mysql_upgrade                             regular file       system_u:object_r:mysqld_exec_t:s0
/etc/rc\.d/init\.d/mysqld                          regular file       system_u:object_r:mysqld_initrc_exec_t:s0
/var/lib/mysql/mysql\.sock                         socket             system_u:object_r:mysqld_var_run_t:s0
/usr/bin/mysqld_safe_helper                        regular file       system_u:object_r:mysqld_exec_t:s0
/usr/libexec/mysqld_safe-scl-helper                regular file       system_u:object_r:mysqld_safe_exec_t:s0
/home/[^/]+/\.my\.cnf                              regular file       unconfined_u:object_r:mysqld_home_t:s0
/mariadb/data(/.*)?                                all files          system_u:object_r:mysqld_db_t:s0
```

We can see at the end, the newly added context to `/mariadb/data/*`

Looking at the begining of the list we can see `/var/log/mysql.*  regular  file  system_u:object_r:mysqld_log_t:s0`, We would need to follow the same step that we did earlier while setting up context for `/mariadb/data` but this time use a different context `mysqld_log_t`

Let's do this

```bash
$ sudo semanage fcontext -a -t mysqld_log_t "/mariadb/log(/.*)?"
$ sudo restorecon -Rv /mariadb/log
restorecon reset /mariadb/log context unconfined_u:object_r:default_t:s0->unconfined_u:object_r:mysqld_log_t:s0
```

Now that the context of /mariadb/log has been set, we should be able to restart MariaDB service without errors.

```bash
$ sudo systemctl restart mariadb
$ sudo systemctl status mariadb
● mariadb.service - MariaDB 10.2.32-7 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Mon 2020-06-29 08:38:40 EDT; 8s ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 5730 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 5645 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/..; /usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 5643 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 5698 (mysqld)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─5698 /usr/sbin/mysqld --basedir=/usr

Jun 29 08:38:39 es-201 systemd[1]: Starting MariaDB 10.2.32-7 database server...
Jun 29 08:38:39 es-201 mysqld[5698]: 2020-06-29  8:38:39 139866564004032 [Note] /usr/sbin/mysqld (mysqld 10.2.32-7-MariaDB-enterprise) starting as process 5698 ...
Jun 29 08:38:39 es-201 mysqld[5698]: 2020-06-29  8:38:39 139866564004032 [Warning] Could not increase number of max_open_files to more than 16364 (request: 32183)
Jun 29 08:38:40 es-201 systemd[1]: Started MariaDB 10.2.32-7 database server.
```

Let's connect to MariaDB CLI and verify the paths.

```bash
MariaDB [(none)]> show global variables like 'datadir'; show global variables like 'log_error';
+---------------+----------------+
| Variable_name | Value          |
+---------------+----------------+
| datadir       | /mariadb/data/ |
+---------------+----------------+
1 row in set (0.00 sec)

+---------------+-------------------------+
| Variable_name | Value                   |
+---------------+-------------------------+
| log_error     | /mariadb/log/server.log |
+---------------+-------------------------+
1 row in set (0.00 sec
```

If we create a new database and a new table, those will get created in the `datadir` and the appropriate context will be assigned automatically based on the parent. Let's see.

```bash
MariaDB [(none)]> create database tmp;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> use tmp;
Database changed
MariaDB [tmp]> create table t(id serial, c1 varchar(100)) engine=InnoDB;
Query OK, 0 rows affected (0.01 sec)

MariaDB [tmp]> desc t;
+-------+---------------------+------+-----+---------+----------------+
| Field | Type                | Null | Key | Default | Extra          |
+-------+---------------------+------+-----+---------+----------------+
| id    | bigint(20) unsigned | NO   | PRI | NULL    | auto_increment |
| c1    | varchar(100)        | YES  |     | NULL    |                |
+-------+---------------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

MariaDB [tmp]> quit
Bye

$ sudo ls --context /mariadb /mariadb/data/tmp

/mariadb:
drwxr-xr-x. mysql mysql unconfined_u:object_r:mysqld_db_t:s0 data
drwxr-xr-x. mysql mysql unconfined_u:object_r:mysqld_log_t:s0 log

/mariadb/data/tmp:
-rw-rw----. mysql mysql system_u:object_r:mysqld_db_t:s0 db.opt
-rw-rw----. mysql mysql system_u:object_r:mysqld_db_t:s0 t.frm
-rw-rw----. mysql mysql system_u:object_r:mysqld_db_t:s0 t.ibd
```

The new directory for the database `tmp` and the new table `t` all have inherited the context from `/mariadb/data` folder.

What if we want to create new folder for binary logs (`/mariadb/binlog`) and redo logs (`/mariadb/redo_log`) etc. We can assign both of the folders the `mysqld_log_t` context and it will work fine.

```bash
$ sudo semanage fcontext -a -t mysqld_log_t "/mariadb/binlog(/.*)?"
$ sudo restorecon -Rv /mariadb/binlog
...
...

$ sudo semanage fcontext -a -t mysqld_log_t "/mariadb/redo_log(/.*)?"
$ sudo restorecon -Rv /mariadb/redo_log
...
...
```

Hope this was helpful! Thank you.
Faisal@MariaDB.
