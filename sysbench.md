# Using Sysbench to Performance Test MariaDB

## Introduction

The MariaDB server's configuration that should be changed from defaults as follows in the `/etc/my.cnf.d/server.cnf`:

```txt
max_connections  = 1000
open-files-limit = 4000
table_open_cache = 4000
query_cache_size = 0
query_cache_type = 0

innodb_buffer_pool_size = 1024M
innodb_log_buffer_size  = 1024M
innodb_file_per_table   = 1
innodb_open_files       = 400
innodb_io_capacity      = 400
innodb_flush_method     = O_DIRECT
innodb_log_file_size    = 1024M
innodb_flush_log_at_trx_commit = 1
innodb_doublewrite = 0
innodb_autoinc_lock_mode = 2
```

- `innodb_io_capacity` depends on the IOPS your server is capable of, for slow SATA/SAN drives it is normally set to 400, for SSD drives it should be 2000 or higher

- `max_connections` should be more than the number of threads you run for sysbench test.

- `innodb_buffer_pool_size` should be 70% of the total memory of the server.

## Download sysbench

Download install the latest sysbench on the server where you want to generate load from. You may need to install `curl` on your system before this as it uses curl to setup the repositories.

#### Ubuntu

```txt
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
sudo apt -y install sysbench
```

#### RHEL

```txt
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash
sudo yum -y install sysbench
```

Once sysbench is installed, verify the version. It should be 1.0.17 or higher.

```txt
root@61e409ed04e6:/# sysbench --version
sysbench 1.0.17
```

Connect to your MariaDB server using the MariaDB CLI and create a database called `sbtest`

```txt
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 5210
Server version: 10.4.8-MariaDB-1:10.4.8+maria~bionic mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database sbtest;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> 
```

#### Generate the Initial Data Volume

In this step, we will generate some tables and populate data into those tables under the `sbtest` database. These are all configurable properties. 

The `sysbench` will use the following parameters:

- --db-driver=mysql
  - Use MySQL drivers which works for MariaDB as well
- --threads=8
  - The number of concurrent connections. This should be started with a lower and increased for each test to see the peak performance/limit of the database for the given hardware
- --events=250000
  - Attempt to perform these many events per second can be kept at this
- --oltp-tables-count=12
  - How many tables to create
- --oltp-table-size=100000
  - Number of rows to insert in each table for the loadtest
- --oltp-test-mode=complex
  - Type of load generation, Complex is the toughest one for the database
- --oltp-dist-type=uniform
  - If you are using more than one nodes in the cluster, this will distribute the load equally on each node, however with MaxScale, it dosent make any differece since MaxScale will do the distribution automatically, given you have configured only one MaxScale server.
- /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua
  - You have to look for this file and make sure the path is correct after the installation.
- --mysql-host=192.168.56.1 --mysql-port=3306 --mysql-user=sb_user --mysql-password=password
  - These point to your MariaDB server or the MaxScale, if you have more than one MaxScale nodes, it can be a coma separated list for `--mysql-host` parameter
  - Make sure the user `sb_user@'%'` (as in this example) or any other user account exists on the database server that has `ALL` privileges on the `sbtest` database.
    - CREATE USER sb_user@'%' identified by 'password';
    - GRANT ALL ON sbtest.* to sb_user@'%';
- --time=60
  - The duration of the test
- --report-interval=10
  - Interval at which sysbench shuld report the performance numbers, this is in Seconds.
- prepare
  - This indicates that we are preparing the envionment before the actual test. This will create those tables and pump the initial data to for the actual performance test

Executing sysbench with above mentioned parameters, we can expect to see the following results. By the end of this, we will have our tables creted and data populated based on our `oltp-table-size=100000` parameter, in this case, 100k rows in each table.

```txt
root@61e409ed04e6:/# sysbench --db-driver=mysql --threads=8 --events=250000 --oltp-tables-count=12 --oltp-table-size=100000 --oltp-test-mode=complex --oltp-dist-type=uniform /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --mysql-host=192.168.56.1 --mysql-port=3306 --mysql-user=sb_user --mysql-password=password --time=60 --report-interval=10 prepare
sysbench 1.0.17 (using bundled LuaJIT 2.1.0-beta2)

Creating table 'sbtest1'...
Inserting 100000 records into 'sbtest1'
Creating secondary indexes on 'sbtest1'...
Creating table 'sbtest2'...
Inserting 100000 records into 'sbtest2'
Creating secondary indexes on 'sbtest2'...
Creating table 'sbtest3'...
Inserting 100000 records into 'sbtest3'
Creating secondary indexes on 'sbtest3'...
Creating table 'sbtest4'...
Inserting 100000 records into 'sbtest4'
Creating secondary indexes on 'sbtest4'...
Creating table 'sbtest5'...
Inserting 100000 records into 'sbtest5'
Creating secondary indexes on 'sbtest5'...
Creating table 'sbtest6'...
Inserting 100000 records into 'sbtest6'
Creating secondary indexes on 'sbtest6'...
Creating table 'sbtest7'...
Inserting 100000 records into 'sbtest7'
Creating secondary indexes on 'sbtest7'...
Creating table 'sbtest8'...
Inserting 100000 records into 'sbtest8'
Creating secondary indexes on 'sbtest8'...
Creating table 'sbtest9'...
Inserting 100000 records into 'sbtest9'
Creating secondary indexes on 'sbtest9'...
Creating table 'sbtest10'...
Inserting 100000 records into 'sbtest10'
Creating secondary indexes on 'sbtest10'...
Creating table 'sbtest11'...
Inserting 100000 records into 'sbtest11'
Creating secondary indexes on 'sbtest11'...
Creating table 'sbtest12'...
Inserting 100000 records into 'sbtest12'
Creating secondary indexes on 'sbtest12'...
```

#### Execute the benchmark

Once the database is ready with tables and dummy data, we can now run the test.

The following is exactly the same as the previous, just the last parameter, instead of `prepare` we will use `run`

```txt
root@61e409ed04e6:/# sysbench --db-driver=mysql --threads=8 --events=250000 --oltp-tables-count=12 --oltp-table-size=100000 --oltp-test-mode=complex --oltp-dist-type=uniform /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --mysql-host=192.168.56.1 --mysql-port=3306 --mysql-user=sb_user --mysql-password=password --time=60 --report-interval=10 run
sysbench 1.0.17 (using bundled LuaJIT 2.1.0-beta2)

Running the test with following options:
Number of threads: 8
Report intermediate results every 10 second(s)
Initializing random number generator from current time


Initializing worker threads...

Threads started!

[ 10s ] thds: 8 tps: 803.21 qps: 16075.09 (r/w/o: 11254.60/3213.26/1607.23) lat (ms,95%): 15.00 err/s: 0.00 reconn/s: 0.00
[ 20s ] thds: 8 tps: 825.98 qps: 16522.47 (r/w/o: 11564.17/3306.33/1651.97) lat (ms,95%): 14.46 err/s: 0.00 reconn/s: 0.00
[ 30s ] thds: 8 tps: 884.87 qps: 17697.28 (r/w/o: 12388.57/3538.98/1769.74) lat (ms,95%): 13.95 err/s: 0.00 reconn/s: 0.00
[ 40s ] thds: 8 tps: 825.28 qps: 16507.08 (r/w/o: 11554.71/3301.82/1650.56) lat (ms,95%): 14.21 err/s: 0.00 reconn/s: 0.00
[ 50s ] thds: 8 tps: 811.71 qps: 16234.42 (r/w/o: 11363.96/3247.04/1623.42) lat (ms,95%): 14.73 err/s: 0.00 reconn/s: 0.00
[ 60s ] thds: 8 tps: 819.49 qps: 16388.88 (r/w/o: 11472.35/3277.56/1638.98) lat (ms,95%): 13.95 err/s: 0.00 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            696024
        write:                           198864
        other:                           99432
        total:                           994320
    transactions:                        49716  (828.45 per sec.)
    queries:                             994320 (16569.03 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0080s
    total number of events:              49716

Latency (ms):
         min:                                    3.96
         avg:                                    9.65
         max:                                   31.18
         95th percentile:                       14.46
         sum:                               479830.97

Threads fairness:
    events (avg/stddev):           6214.5000/16.76
    execution time (avg/stddev):   59.9789/0.00
```

The PREPARE is to be done only once, but the RUN can be performed multiple times, this will reuse the originally prepared data and generate a complex SELECT, INSERT, UPDATE, DELETE load while maintaining transactions. A transaction will have multiple statements executuins within but the total number of queries per second will be much higher.

Generally, after PREPARE, we can tune the server parameters like buffer_pool_size, tmp_table_size, encryption etc and rerun sysbench using `RUN` argument multiple times to see the impact of those parameters. 

For instance, the output above says `transactions:                        49716  (828.45 per sec.)` but the `queries:                             994320 (16569.03 per sec.)` is much higher since each transaction has many smaller events being generated.

Repeat the above and increase the threads to 8, 16, 32, 64, 128 and so on just to see when the performance stops to drop. That will be the peak capacity of your server.

#### Cleanup

Finally, once done, you can run the same command with `CLEANUP` parameter to destroy the test data generated for this test. Once cleanup is done, you will have to `PREPARE` once again before re-running the test.

```txt
root@61e409ed04e6:/# sysbench --db-driver=mysql --threads=8 --events=250000 --oltp-tables-count=12 --oltp-table-size=100000 --oltp-test-mode=complex --oltp-dist-type=uniform /usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --mysql-host=localhost --mysql-port=3306 --mysql-user=dba --mysql-password=password --time=60 --report-interval=10 cleanup 
sysbench 1.0.17 (using bundled LuaJIT 2.1.0-beta2)

Dropping table 'sbtest1'...
Dropping table 'sbtest2'...
Dropping table 'sbtest3'...
Dropping table 'sbtest4'...
Dropping table 'sbtest5'...
Dropping table 'sbtest6'...
Dropping table 'sbtest7'...
Dropping table 'sbtest8'...
Dropping table 'sbtest9'...
Dropping table 'sbtest10'...
Dropping table 'sbtest11'...
Dropping table 'sbtest12'...
```

Thank you.
