# Parallel Streaming MariaDB Backup

Recently, quite a few clients have asked me about the best and fastest way to take MariaDB backup? Can we improve its performance? How much storage is required for a full backup and restore? Etc. If you have had any of the above thoughts, then this blog is going to be helpful. 

I was involved in a project where we had 1.6TB of the MariaDB database and took more than 6 hours to take a backup and transfer that backup to other nodes to build a slave. Parallel `mariabackup` would have been a perfect solution for that scenario, but it was many years ago when we did not have this option!

To begin with, we have been used to the traditional MariaDB backup using the following three steps.

- `mariabackup --backup`
- `mariabackup --prepare`
- `mariabackup --copy-back`

The steps are still the same, but now, we can send parallel streams of backup into a tool called `pigz` which can catch those parallel streams and compress them in parallel. This is not Pig Zip. Instead, "**P**arallel **I**mplementation of **gz**ip". It's available through the standard Linux repositories.

Refer to <https://zlib.net/pigz/> for more details on the tool.

## Scope

The scope of this blog is to see how we can use the MariaDB Enterprise Server's streaming backup capabilities. Stream data directly to `pigz` which, by default, uses all the CPUs available in the machine for parallel compression/decompression but of course, can also be configured to use as many CPU as we wanted to. 

## What do we need

We will need an RHEL/CentOS VM running the MariaDB Enterprise server. We are using MariaDB 10.6 for this blog. However, this approach will work in 10.5 and earlier versions as well as long as the`--stream` option is supported by the `mariabackup` version currently in use.

The two VMs are 16 CPU and 32GB RAM with 100GB local SSD storage that supports up to 5000 IOPS. A dedicated mount is recommended so that there is no IO contention for reading and writing of the backup streams.

***Note:** MariaDB and `mariabackup` versions should always be the same. Using a different version of `mariabackup` against a different MariaDB server might not be compatible*

To get what we need, we will need to do the following. 

- RHEL/CentOS: <https://mariadb.com/docs/deploy/topologies/single-node/enterprise-server-10-6/#install-on-centos-rhel-yum>
- Ubuntu/Debian: <https://mariadb.com/docs/deploy/topologies/single-node/enterprise-server-10-6/#install-on-debian-ubuntu-apt>

Following the above enterprise documentation links, we will install MariaDB Enterprise Server and MariaDB Backup on the two servers. We just need to install `pigz` as an additional component manually. 

`yum install pigz` or `apt install pigz` depending on the OS in use.

Let's generate some data on one of the servers now. We are going to be using `sysbench` for generating dummy data.

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

This base configuration is to support faster "writes". The `innodb_flush_log_at_trx_commit=0` is something in particular unsafe and should be configured as `innodb_flush_log_at_trx_commit=1` for production to be able to support ACID compliance and maximum durability. We are setting it to 0 temporarily because it's the fastest way to perform heavy writes. That is why it's set up this way before generating `sysbench` data.

***Note:** many other server parameters can impact the write and performance, but we will keep it simple for this setup as server optimization is not the scope of this blog.*

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

We now have a database `sbtest` a user `sbuser@localhost` with full access to that database. Furthermore, we have also created a user for `mariabackup` with appropriate privileges. It's time to generate some data.

To install sysbench, we need to install `yum install epel-release` package on CentOS/RHEL for Ubuntu and Debian it should be directly available from the default repositories.

`yum/apt install sysbench` to install sysbench depending on the OS.

Alternatively, sysbench can be fetched from CentOS repositories manually as RPM files and installed.

### Generate Data

Executing sysbench directly from the MariaDB server, that's why `--mysql-host=127.0.0.1`

```
[shell] sysbench /usr/share/sysbench/oltp_read_write.lua --threads=12 --mysql-host=127.0.0.1 --mysql-user=sbuser --mysql-password=SecretP@ssw0rd --mysql-port=3306 --tables=30 --table-size=5000000 prepare

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

This will create 30 tables with 5 million rows each, we will see the size of the database once it's done.

Just for fun, we can track various MariaDB stats with the help of `mariadb-admin` using `extended-status` to get detailed stats. Combibed together with some Linux magic we get a nicely formatted output.

`-i1` in the `mariadb-admin` argument stands for interval of 1 second where as `-r` is to get relative status numbers since the last execution. This in return gives us per second stats. 

```
[shell] mariadb-admin --no-defaults -r -i1 extended-status |\
gawk -F"|" \
"BEGIN{ count=0; }"\
'{ if($2 ~ /Variable_name/ && ++count == 1){\
    print "+----------+----------+-- MariaDB Command Status ---+----- Innodb row operation ------+--- Buffer Pool Read ---+";\
    print "|   Time   |      QPS | select insert update delete |   read inserted updated deleted |    logical    physical |";\
    print "+----------+----------+-----------------------------+---------------------------------+------------------------+";\
}\
else if ($2 ~ /Queries/){queries=$3;}\
else if ($2 ~ /Com_select /){com_select=$3;}\
else if ($2 ~ /Com_insert /){com_insert=$3;}\
else if ($2 ~ /Com_update /){com_update=$3;}\
else if ($2 ~ /Com_delete /){com_delete=$3;}\
else if ($2 ~ /Innodb_rows_read/){innodb_rows_read=$3;}\
else if ($2 ~ /Innodb_rows_deleted/){innodb_rows_deleted=$3;}\
else if ($2 ~ /Innodb_rows_inserted/){innodb_rows_inserted=$3;}\
else if ($2 ~ /Innodb_rows_updated/){innodb_rows_updated=$3;}\
else if ($2 ~ /Innodb_buffer_pool_read_requests/){innodb_lor=$3;}\
else if ($2 ~ /Innodb_buffer_pool_reads/){innodb_phr=$3;}\
else if ($2 ~ /Uptime / && count >= 2){\
  printf("| %s |%9d ",strftime("%H:%M:%S"),queries);\
  printf("| %6d %6d %6d %6d ",com_select,com_insert,com_update,com_delete);\
  printf("| %6d %8d %7d %7d ",innodb_rows_read,innodb_rows_inserted,innodb_rows_updated,innodb_rows_deleted);\
  printf("| %10d %11d |\n",innodb_lor,innodb_phr);\
}}'

+----------+----------+-- MariaDB Command Status ---+----- Innodb row operation ------+--- Buffer Pool Read ---+
|   Time   |      QPS | select insert update delete |   read inserted updated deleted |    logical    physical |
+----------+----------+-----------------------------+---------------------------------+------------------------+
| 13:08:58 |      119 |      0    118      0      0 |      0   312708       0       0 |    2367607           0 |
| 13:09:00 |      118 |      0    116      0      0 |      0   313371       0       0 |    2703427           0 |
| 13:09:00 |      100 |      0     97      0      0 |      0   262277       0       0 |    1868223           0 |
| 13:09:01 |      133 |      0    134      0      0 |      0   360241       0       0 |    2948243           0 |
| 13:09:03 |      116 |      0    116      0      0 |      0   303584       0       0 |    2311904           0 |
| 13:09:03 |      122 |      0    121      0      0 |      0   315199       0       0 |    2751877           0 |
...
...
...
```

Based on the optimization parameters, we can see that 12 parallel threads can achieve a combined average of 25k+ inserts per second. 

The current size of the data directory is roughly 37GB

```
[shell] du -h /var/lib/mysql/
3.2M	/var/lib/mysql/mysql
4.0K	/var/lib/mysql/performance_schema
616K	/var/lib/mysql/sys
35G	/var/lib/mysql/sbtest
37G	/var/lib/mysql/
```

### Standard Backup

We have done All the prep work. Let’s see how long it takes to make a full backup of a 37GB database using the traditional way.

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

real	2m22.235s
user	0m4.340s
sys	0m21.735s
```

The backup process took roughly 2m22s to complete the full backup. We can verify how much data was written to the backup folder.

```
[shell] du -h backup/
3.2M	backup/mysql
35G	backup/sbtest
616K	backup/sys
4.0K	backup/performance_schema
36G	backup/
```


### Streaming Parallel Backup

Streaming mariabackup is very similar to traditional backup with the addition of two options

- `--stream=xbstream `
- `--parallel=n`
  - Here `'n'` is the number of parallel streams beign generated by `mariabackup`

We also need `pigz` to cath these parallel streams. This is done simply by redirecting the `mariabackup` command to `pigz` with `-p n` argument, here `'n'` is the number of parallel compression threads used by `pigz`. This should be the same as the number of `xbstream` parallel streams. 

***Note:** that there is no need for a `--target-dir` since it's now using backup streams that will be redirected into `pigz` or another receiver.*

Let's see how this all comes together.

#### Streaming Backup Test 1

Streaming backup test with `mariabackup` and  `pigz` both allocated **16 cores**, we can see immediately it was almost half the time of regular backup

```
[shell] time mariabackup --backup --tmpdir=/tmp --stream=xbstream --parallel=16 --datadir=/var/lib/mysql --user=backup --password=SecretP@ssw0rd 2>backup/backup.log | pigz --fast -p 16 > backup/full_backup.gz

real	1m40.627s
user	12m48.086s
sys	0m35.985s
```

The compressed backup faster by 1 minute! The important parameters for `pigz` are `--fast` and `-p 16` to use the fastest compression algorithm, it compresses slightly less but is much faster than the default. Finally the `-p 16` to use 16 parallel threads, the threads must be according to the total CPUs/vCPUs available in the server.

The performance can be further enhanced by having a dedicated backup storage mount. The best part is the backup size. As it's compressed, it takes a lot less storage, 17GB vs. 37GB for the full uncompressed backup.

```
[shell] du -h /backup
17G	/backup
```

### Restore 

The restore is straightforward. Let’s see how.

```
[shell] systemctl stop mariadb
[shell] rm -rf /var/lib/mysql/*
[shell] time pigz backup/full_backup.gz -dc -p 16 | mbstream --directory=/var/lib/mysql -x --parallel=16

real	2m29.132s
user	3m10.598s
sys	1m2.910s

[shell] mariabackup --prepare --use-memory=16G --target-dir=/var/lib/mysql
[shell] chown -R mysql:mysql /var/lib/mysql
[shell] systemctl start mariadb
```

The restore is also speedy. It took around 2m30s for `pigz` to uncompress 37GB of data using 16 parallel threads and write it all to the MariaDB's data directory. Writes are always slow particularly when writing huge amounts of data like in this case.

A quick look at the restore steps.

- **`systemctl stop mariadb`** and **`rm -rf /var/lib/mysql/*`**
  - Stop the MariaDB server and clean up the data directory
- **`pigz full_backup.gz -dc -p 16 | mbstream --directory=/var/lib/mysql -x --parallel=16`**
  - use `pigz` to unzip the compressed backup using **16 cores** and redirect these streams to `mbstream` using `--parallel=16` threads. This should match with the `pigz` threads
  - This will unzip the compressed backup directly into the data directory.
- Execute **`--prepare`** because since the backup was taken directly into a compressed zip file, it was never prepared, and the data files are in an inconsistent state.
- **`chown -R mysql:mysql /var/lib/mysql`**
  - Change ownership of the restored files to `mysql:mysql`. Remember, this must be according to the user:group used to run the MariaDB process, by default. However, it should be `mysql:mysql`
- **`systemctl start mariadb`**
  - Start MariaDB.

### Complete Backup & Restore (Parallel)

Probably is the most beneficial usage of streaming parallel backup/restore. It can streamline the process of taking live backup and transferring it to another node, maybe for rebuilding a replica node or just adding a new replica. It will be much faster than taking a backup, transferring it to the other node, doing a restore, and so on.  

This stream of redirects from one node to another leads to the following.

MariaDB Backup -> `pigz` in parallel -> `ssh` to a new node -> uncompress in parallel -> restore using `mbstream`

```
[shell] time mariabackup --backup \
                --stream=xbstream \
                --parallel=16 \
                --datadir=/var/lib/mysql \
                --user=backup \
                --password=SecretP@ssw0rd 2>/tmp/backup.log \
              | pigz -p 16 \
              | ssh -i ssh_key.pem user@172.31.32.26 -q -t \
                  "pigz --fast -dc -p 16 \
                    | sudo mbstream \
                      --directory=/var/lib/mysql -x \
                      --parallel=16"

real	3m26.264s
user	44m43.579s
sys	0m47.138s
```

***Note:** `--target-dir` is not required as the backup is not written anywhere on the local server*

The great thing about streaming a highly compressed backup directly to a different node is that it is swift and efficient that consumes much less IO and network bandwidth while taking away a lot of manual steps such as

- take a local full backup (this is going to take time as the local IO will come into play)
- tar/zip the backup so that a smaller backup will be transferred over the network, maybe even to another data center that does not have the fastest network. A smaller compressed backup is desirable.
- untar/unzip the backup on the remote node
- Run mariabackup to restore that backup.

All the above, if done manually, will take a very long time, depending on the backup size.

Assuming `172.31.21.72` is the IP of the replica node where we want to stream this backup to and restore, the above is one command that will take streaming compressed backup, ssh to the slave node, unzip the streams and restore to the data directory in one swift set of parallel data streams from 1 node to another target node.

All the above is done in a single step of parallel streams where backup and compression from local node does not even use any IO locally as the compressed stream is sent to `ssh` which triggers `pigz -dc -p 16` dc = De Compress using 16 CPUs and then send the streams to `mbstream which handles it using 16 parallel threads and restores it onto the node directly. Very smooth and efficient. I wish I had this at my disposal years back when I spent days rebuilding those replica nodes within and across the multiple data centers.

Before starting the MariaDB server on this node, we still need to do the `prepare`, and `chown -R mysql:mysql /var/lib/mysql` as per the standard restore process.

This is very efficient and performant because it's all parallel using the CPUs available. Note that the network between the nodes must be a good 10GBps because, on a slower network, the network will become the bottleneck.

#### Time that backup

Let's time the approach as discussed above if we were to do all of this backup/transfer manually.

- Full backup of 37GB took **2m24s**
- tar/zip metod - **42 miutes**
  - `tar -czvf backup.tar.gz backup/` took **34m56s**
  - Transfer the tar to slave node took **1m10s**
  - Untar on remote slave took **4m7s**
- Direct copy without tar took **3m2s**
  - `scp -r backup/* user@remnote:/tmp`

Full Backup + tar compression + Transfer -> **45 minutes**
Full Backup + Direct transfer without tar compression -> **5 minutes 30 seconds**
Full streaming parallel backup with pigz parallel compression and transfer -> **3 minutes 26 seconds** "Winner :)~"

Clearly the streaming backup with parallel compression and transfer is the best way.

### Conclusion

Streaming backup taken locally or used for rebuilding a replica node is the fast approach. It helps with saving storage and network load while rebuilding replica nodes directly from a node by streaming compressed backup to a remote machine where. On the remote MariaDB receives the incoming streams using parallel threads and restores them directly onto the database data directory.

It leads to great automation, performant and straightforward at the same time.

### Thanks
