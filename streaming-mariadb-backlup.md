# Parallel Streaming MariaDB Backup

Recently, quite a few clients have asked me on what is the best and fastest way to take MariaDB backup? can we improve it's performance? how much storate is required for a full backup and restore? etc. If you have had any of the above thoughts then this blog is going to be helpful. 

I was involved in a project where we had 1.6TB of MariaDB database and took more than 6 hours to take a backup and transfer that backup to other nodes in order to build a slave. Parallel mariabackup would have been a perfect solution for that scenario but it was many years ago when we did not have this option!

To begin with, so far we have been used to the traditional MariaDB backup using the following three steps

- `mariabackup --backup`
- `mariabackup --prepare`
- `mariabackup --copy-back`

Well, the steps are still the same but now, we can send parallel streams of backup into a tool called `pigz` which can catch those parallel streams and compress them in parallel. This is not really Pig Zip, rather, "**P**arallel **I**mplementation of **gz**ip". It's available through the standard linux repositories.

Refer to <https://zlib.net/pigz/> for mode details on the tool.

## Scope

The scope of this blog is to see how we can use the MariaDB Enterprise Server's streaming backup capabilities and stream that data directly to `pigz` which, by default uses all the CPUs available inthe machine for parallel compression/decompression but of course, can also be configure to use as many CPU as we wanted to. 

## What do we need

We will need a RHEL/CentOS VM running the MariaDB Enterprise server, we are using MariaDB 10.6 for this blog, however, this approach will work in 10.5 and earlier versions as well as long as `--stream` option is supported by the `mariabackup` version currently in use.

The VM are 16 CPU and 32GB RAM with 100GB local SSD storage that supports up to 5000 IOPS and an external 400GB SSD for the MariaDB backup. A dedicated mount is recommended so that there is no IO contention for reading and writing of the backup streams.

***Note:** MariaDB and mairabackup versions should always be the same, using a different version of mariabackup against a different MariaDB server might not be compatible*

To get what we need, we will need to do the following 

- RHEL/CentOS: <https://mariadb.com/docs/deploy/topologies/single-node/enterprise-server-10-6/#install-on-centos-rhel-yum>
- Ubuntu/Debian: <https://mariadb.com/docs/deploy/topologies/single-node/enterprise-server-10-6/#install-on-debian-ubuntu-apt>

Following the above enterprise documentation links, we will be able to install MariaDB Enterprise Server and MariaDB Backup on the two servers. We just need to install `pigz` as an additional component manually. 

`yum install pigz` or `apt install pigz` depending on the OS in use.

Let's generate some data on one of the servers now, we are going to be using `sysbench` for generating dummy data.

Let's connect to the MariaDB server and setup a user accounts for `sysbench` and `mariabackup`

Before we do, let's review the server.cnf file

```
[mariadb]
log_error
innodb_log_file_size=512M
innodb_buffer_pool_size=16G
innodb_io_capacity=2000
innodb_flush_log_at_trx_commit=0
innodb_flush_method=O_DIRECT
```

This base configuration is to support faster "writes". The `innodb_flush_log_at_trx_commit=0` is something in particular unsafe and should be configured as `innodb_flush_log_at_trx_commit=1` for production to be able to support ACID compliance and maximum durability. For this setup, we are setting it to 0 temporarily because it's the fastest way to perform heavy writes, that is why it's set up this way before generating `sysbench` data.

***Note:** There are many other server parameters that can impact the write and performance but for this setup we will keep it simple as that is not the scope of this blog.*

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

MariaDB [(none)]> GRANT ALL ON sbtest.* TO sbuser@localhost;
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> CREATE USER 'backup'@'localhost' IDENTIFIED BY 'SecretP@ssw0rd';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backup'@'localhost';
Query OK, 0 rows affected (0.001 sec)
```

We now have a datbase `sbtest` a user `sbuser@localhost` with full access to that database. Furthermore, we have also created a user It's time to generate some data.

To install sysbench, we need to install `yum install epel-release` package on CentOS/RHEL for Ubuntu and Debian it should be directly available from the default repositories.

`yum/apt install sysbench` to install sysbench depending on the OS.

Alternatively, sysbench can be fetched from CentOS repositories manyually as RPM files and installed.

### Generate Data

Executing sysbench directly from the MariaDB server, that's why `--mysql-host=127.0.0.1`

```
[shell] sysbench /usr/share/sysbench/oltp_read_write.lua --threads=12 --mysql-host=127.0.0.1 --mysql-user=sbuser --mysql-password=SecretP@ssw0rd --mysql-port=3306 --tables=24 --table-size=5000000 prepare

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
.
```

This will create 24 tables with 5 million rows each, we will see the size of the database once it's done.

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

The current size of the data directory is roughly 30G

```
[shell] du -h /var/lib/mysql/
3.1M	/var/lib/mysql/mysql
4.0K	/var/lib/mysql/performance_schema
616K	/var/lib/mysql/sys
41G	/var/lib/mysql/sbtest
43G	/var/lib/mysql/
```

### Standard Backup

All the prep work is done, let's see how log it takes to take a full backup of a 43GB database using the traditional way.

```
[shell] time mariabackup --backup --target-dir=/backup --datadir=/var/lib/mysql --user=backup --password=SecretP@ssw0rd
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

real	2m49.329s
user	0m4.805s
sys	0m24.971s
```

The backup process took roughly 2m49s to complete the full backup, we can verify how much data was written to the backup folder.

```
[shell] du -h backup/
3.1M	/backup/mysql
41G	/backup/sbtest
616K	/backup/sys
4.0K	/backup/performance_schema
43G	/backup/
```


### Streaming Parallel Backup

Streaming mariabackup is very simillar to traditional backup with the addition of two options

- `--stream=xbstream `
- `--parallel=n`
  - Here `'n'` is the number of parallel streams beign generated by `mariabackup`

We also need `pigz` to cath these parallel streams, this is done simply by redirecting the `mariabackup` command to `pigz` with `-p n` argument, here `'n'` is the number of parallel compression threads used by `pigz`, this should be the same as the number of `xbstream` parallel streams. 

Also take note that there is no need for a `target-dir` since it's now using backup sterams which needs to be redirected into `pigz` or another receiver.

Let's see how this all comes together.

#### Streaming Backup Test 1

Streaming backup test with `mariabackup` and  `pigz` both allocated **16 cores**, we can see immediately it was almost half the time of normal backup

```
[shell] time mariabackup --backup --tmpdir=/tmp --stream=xbstream --parallel=16 --datadir=/var/lib/mysql --user=backup --password=SecretP@ssw0rd 2>/backup/backup.log | pigz -p 16 > /backup/full_backup.gz

real	3m57.896s
user	53m22.399s
sys	0m37.987s
```

The compressed backup took slightly longer to complete vs the full uncomoressed backup, the main reason is multiple streams writing reading from and writing to the same storage. This can be helped greatly if we have a dedicated backup storage. The best part is the backup size, as it's comoressed, it takes a lot less storage, 19GB vs 43GB for the uncompressed backup.

```
[shell] du -h /backup
19G	/backup
```

### Restore 

The restore is very simple, let's see how.

```
[shell] systemctl stop mariadb
[shell] rm -rf /var/lib/mysql/*
[shell] time pigz full_backup.gz -dc -p 16 | mbstream --directory=/var/lib/mysql -x --parallel=16

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

This probably is the most useful usage of streaming parallel backup/restore, it can steramline the process of taking live backup and transferring it to another node, maybe for rebuilding a replica node or just adding a new replica. This will be much faster than taking a backup, transferring it to the other node, doing a restore and so on.  

This stream of redirects from one node to another leads to the following

MariaDB Backup -> `pigz` in parallel -> `ssh` to a new node -> uncompress in parallel -> restore using `mbstream`

```
[shell] time mariabackup --backup \
                --stream=xbstream \
                --parallel=16 \
                --datadir=/var/lib/mysql \
                --user=backup \
                --password=SecretP@ssw0rd 2>/tmp/backup.log \
              | pigz -p 16 \
              | ssh -i ssh_key.pem user@172.31.21.72 -q -t \
                  "pigz -dc -p 16 \
                    | sudo mbstream \
                      --directory=/var/lib/mysql -x \
                      --parallel=16"

real	4m7.282s
user	53m21.791s
sys	0m58.784s
```

***Note:** `--target-dir` is not required as the backup is not really written anywhere on local server*

The great thing about streaming a highly compressed backup directly to a different node is that it is very fast and efficient that consumes much less IO and network bandwidth while taking away a lot of manual steps such as

- take a local full backup (this is going to take time as the local IO will come into play)
- tar/zip the backup so that a smaller backup can be transferred over the network, maybe even to another data center which does not have the fastest network. Smaller compressed backup is desirable.
- untar/unzip the backup on the remote node
- Run mariabackup to restore that backup.

All the above if done manually will take a very long time, depending on the backup size.

Assuming `172.31.21.72` is the IP of the replica node where we want to stream this backup to and restore, the above is one command that will take a streaming compressed backup, ssh to the slave node, unzip the streams and restore to the data directory in one swift set of parallel data streams from 1 node to another target node.

All the above is done in a single step of parallel streams where backup and compression from local node does not even use any IO locally as the comoressed stream is sent to `ssh` which triggers `pigz -dc -p 16` dc = De Compress using 16 CPUs and then send the streams to `mbstream which handles it using 16 parallel threads and restores it onto the node directly. Very smooth and efficient. I wish I had this at my disposal years back when I spent days rebuilding those replica nodes within and across the multiple data centers.

Before starting the MariaDB server on this node, we still need to do the `prepare`, and `chown -R mysql:mysql /var/lib/mysql` as per the normal restore process.

This is very efficient and performant because it's all parallel using the CPUs available, just take note that the network between the nodes must be a good 10GBps because on a slower network, the network will become the bollneck.

### Thanks
