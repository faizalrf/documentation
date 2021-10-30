# Parallel Streaming MariaDB Backup

I have discussed this with many clients who want to make sure there MariaDB backup is faster and don't consume much space. So far we have been used to the traditional MariaDB backup using the following three steps

- `mariabackup --backup`
- `mariabackup --prepare`
- `mariabackup --copy-back`

Well, the steps are still the same but now, we can send parallel streams of backup into a tool called `pigz` which can catch those parallel streams and compress them in parallel. This is not really Pig Zip, rather, "**P**arallel **i**mplementation of **gz**ip". It's available through the standard linux repositories.

Refer to <https://zlib.net/pigz/> for mode details on the tool.

## Scope

The scope of this blog is to see how we can use the MariaDB Enterprise Server's streaming backup capabilities and stream that data directly top `pigz` which can be configure to use as many CPU/RAM as we want to. 

We are using 8 core 32GB RAM system CentOS machine for this test.

## What do we need

We will need a RHEL/CentOS running the MariaDB Enterprise server, we are using MariaDB 10.6 for this blog. 

To get what we need, we will need to do the following 

- RHEL/CentOS: <https://mariadb.com/docs/deploy/topologies/single-node/enterprise-server-10-6/#install-on-centos-rhel-yum>
- Ubuntu/Debian: <https://mariadb.com/docs/deploy/topologies/single-node/enterprise-server-10-6/#install-on-debian-ubuntu-apt>

This will MariaDB Enterprise Server and MariaDB Backup on the server. We just need to install `pigz` 

`yum install pigz` or `apt install pigz` depending on the OS 

Let's generate some data on the server now, we are going to be using `sysbench` for this blog

Let's connect to the MariaDB server and setup a user account for `sysbench`

Before we do, let's review the server.cnf file

```
[mariadb]
log_error
innodb_log_file_size=1G
innodb_buffer_pool_size=16G
innodb_flush_log_at_trx_commit=0
innodb_flush_method=O_DIRECT
```

Base configuration to support faster "writes", `innodb_flush_log_at_trx_commit=0` is something in particular should be `innodb_flush_log_at_trx_commit=1` for production for ACID compliance and maximum durability. Setting it to 0 is temporary and the fastest way to perform heavy writes, that is why it's set up this way before generating `sysbench` data.

```
[shell #] mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 10.6.4-1-MariaDB-enterprise MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select version();
+-----------------------------+
| version()                   |
+-----------------------------+
| 10.6.4-1-MariaDB-enterprise |
+-----------------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> CREATE DATABASE sbtest;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> CREATE USER sbuser@localhost identified by 'SecretP@ssw0rd';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> grant all on sbtest.* to sbuser@localhost;
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> CREATE USER 'backup'@'localhost' IDENTIFIED BY 'SecretP@ssw0rd';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backup'@'localhost';
Query OK, 0 rows affected (0.001 sec)
```

We now have a datbase `sbtest` a user `sbuser@localhost` with full access to that database. Furthermore, we have also created a user It's time to generate some data.

To download sysbench, you need to install `yum install epel-release` package on CentOS/RHEL for Ubuntu and Debian it should be directly available from the default repositories.

### Generate Data

Executing sysbench directly from the MariaDB server, that's why `--mysql-host=127.0.0.1`

```
[shell] sysbench /usr/share/sysbench/oltp_read_write.lua --threads=8 --mysql-host=127.0.0.1 --mysql-user=sbuser --mysql-password=SecretP@ssw0rd --mysql-port=3306 --tables=12 --table-size=5000000 prepare

sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)

Initializing worker threads...

Creating table 'sbtest3'...
Creating table 'sbtest4'...
.
.
Inserting 5000000 records into 'sbtest6'
Inserting 5000000 records into 'sbtest4'
.
.
Creating a secondary index on 'sbtest4'...
Creating a secondary index on 'sbtest2'...
Creating a secondary index on 'sbtest7'...
.
.
Creating table 'sbtest9'...
Creating table 'sbtest12'...
Inserting 5000000 records into 'sbtest12'
```

This will create 12 tables with 5 million rows each, we will see the size of the database once it's done.

Just for fun, we can track how many rows are being inserted per second with the help of `mariadb-admnin` with `extended-status` argument to get the following.

```
[shell] mariadb-admin extended-status -i1 | grep "Com_insert "
| Com_insert                                             | 77882                                            |
| Com_insert                                             | 77976                                            |
| Com_insert                                             | 78058                                            |
| Com_insert                                             | 78160                                            |
.
.
```

We can see, based on our optimization parameters we are able to support 8 parallel threads whoch are doing a combined 77k+ inserts per second. 

The current size of the data directory is roughly 16G

```
[shell] du -h /var/lib/mysql/
3.1M	/var/lib/mysql/mysql
4.0K	/var/lib/mysql/performance_schema
616K	/var/lib/mysql/sys
14G	/var/lib/mysql/sbtest
16G	/var/lib/mysql/
```

### Standard Backup

All the prep work is done, let's see how log it takes to take a full backup of a 16GB database using the traditional way.

```
[shell] time mariabackup --backup --target-dir=/root/backup/ --datadir=/var/lib/mysql --user=backup --password=SecretP@ssw0rd
.
.
.
[00] 2021-10-30 15:03:53 BACKUP STAGE END
[00] 2021-10-30 15:03:53 Executing BACKUP STAGE END
[00] 2021-10-30 15:03:53 All tables unlocked
[00] 2021-10-30 15:03:53 Copying ib_buffer_pool to /root/backup/ib_buffer_pool
[00] 2021-10-30 15:03:53         ...done
[00] 2021-10-30 15:03:53 Backup created in directory '/root/backup/'
[00] 2021-10-30 15:03:53 Writing backup-my.cnf
[00] 2021-10-30 15:03:53         ...done
[00] 2021-10-30 15:03:53 Writing xtrabackup_info
[00] 2021-10-30 15:03:53         ...done
[00] 2021-10-30 15:03:53 Redo log (from LSN 71518599223 to 71623288280) was copied.
[00] 2021-10-30 15:03:53 completed OK!

real	4m30.496s
user	0m8.436s
sys	0m18.814s
```

The backup process took roughly 4 to 5 minutes time, we can verify how much data was written to the backup folder.

```
[shell] du -h backup/
3.1M	backup/mysql
14G	backup/sbtest
616K	backup/sys
4.0K	backup/performance_schema
15G	backup/
```

### Streaming Parallel Backup

Streaming mariabackup is very simillar to traditional backup with the addition of two options

- `--stream=xbstream `
- `--parallel=n`
  - Here `'n'` is the number of parallel streams beign generated by `mariabackup`

We also need `pigz` to cath these parallel streams, this is done simply by redirecting the `mariabackup` command to `pigz` with `-p n` argument, here `'n'` is the number of parallel compression threads used by `pigz`, this should be the same as the number of `xbstream` parallel streams. 

Also take note that there is no need for a `target-dir` since it's now using backup sterams which needs to be redirected into `pigz` or another receiver.

Let's see how this all comes together.

#### Test 1

Streaming backup test with `mariabackup` and  `pigz` both allocated **8 cores**, we can see immediately it was almost half the time of normal backup

```
[shell] time mariabackup --backup --tmpdir=/tmp --stream=xbstream --parallel=8 --datadir=/var/lib/mysql --user=backup --password=SecretP@ssw0rd | pigz -p 8 > /root/backup/full_backup.gz

real	2m29.348s
user	17m54.658s
sys	0m12.358s
```

The best part is the backup size, as it's comoressed, it takes a lot less storage, 6.3GB vs 15GB for the traditional backup.

```
[shell] du -h backup/
6.3G	backup/
```

#### Test 2

Suppose we over allocate the **12 cores** for both `mariabackup` and `pigz`, we can see the laws of diminishing return in action, the backup now took longer because the total cores available are 8 in the server but we allocated much more than that, the CPUs are not fighting for `clock-time` to work which leads to delays.

```
[shell] time mariabackup --backup --tmpdir=/tmp --stream=xbstream --parallel=12 --datadir=/var/lib/mysql --user=backup --password=SecretP@ssw0rd | pigz -p 12 > /root/backup/full_backup.gz

real	3m9.443s
user	18m1.346s
sys	0m12.654s
```

It's important to time this on your environment and see what works best before you start to get diminshing returns. Having a faster disk will also help a lot, we are using the standard spinning storage which is of course not ideal for a database in this modern data driven age. 

### Restore 

The restore is very simple, let's see how.

```
[shell] systemctl stop mariadb
[shell] rm -rf /var/lib/mysql/*
[shell] time pigz full_backup.gz -dc -p 8 | mbstream --directory=/var/lib/mysql -x --parallel=8

real	1m59.549s
user	1m52.057s
sys	0m34.530s

[shell] mariabackup --prepare --use-memory=16G --target-dir=/var/lib/mysql
[shell] chown -R mysql:mysql /var/lib/mysql
[shell] systemctl start mariadb
```

The restore is also very fast, took less than 2 minutes for `pigz` to uncompress 15GB of data using 8 parallel threads and write it all to the MariaDB's data directory.

A quick look at the restore steps.

- **`systemctl stop mariadb`** and **`rm -rf /var/lib/mysql/*`**
  - Stop the MariaDB server and cleanup it's data directory
- **`pigz full_backup.gz -dc -p 8 | mbstream --directory=/var/lib/mysql -x --parallel=8`**
  - use `pigz` to unzip the comoressed backup using **8 cores** and redirect these streams to `mbstream` using `--parallel=8` threads, this should match with the `pigz` threads
  - This will unzip the compressed backup directly into the data directory.
- Execute **`--prepare`** because since backup was taken directly into a compressed zip file, it was never prepared and the data files are in an inconsistent state.
- **`chown -R mysql:mysql /var/lib/mysql`**
  - Change ownership of the restored files to `mysql:mysql` remember, this must be done according to the user:group used to run the MariaDB process, by default, however, it should be `mysql:mysql`
- **`systemctl start mariadb`**
  - Start MariaDB.

### Complete Backup & Restore (Parallel)

This stream of redirects from one to another leads to the following

MariaDB Backup -> `pigz` in parallel -> `ssh` to a new node -> uncompress in parallel -> restore using `mbstream`

```
mariabackup --backup --tmpdir=/tmp --stream=xbstream --parallel=8 --datadir=/var/lib/mysql | pigz -p 8 | ssh -q 192.168.56.200 -t "pigz -dc -p 8 | mbstream --directory=/var/lib/mysql -x --parallel=4"
```

Assuming `192.168.56.200` is the IP of the slave node where we want to stream this backup to, the above is one command that will take a streaming compressed backup, ssh to the slave node, unzip the streams and restore to the data directory in one swift set of parallel data streams from 1 node to another target node. 

Before starting the MariaDB server, we still need to do the `prepare`, and `chown -R mysql:mysql /var/lib/mysql` as per the normal restore process.

This is very efficient and performant because it's all parallel using the CPUs available, just take note that the network between the nodes must be a good 10GBps because on a slower network, the network will become the bollneck.

### Thanks