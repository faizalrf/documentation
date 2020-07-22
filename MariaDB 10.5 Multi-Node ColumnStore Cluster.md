# Install & Configure MariaDB 10.5 Enterprise

## Assumptions

- The setup is going to be done on RHEL 7/CentOS 7 
- Enterprise version of the 10.5 is used for the multi-node CS setup
- `root` user is used for the following setup

The three nodes in this setup are as follows

- 192.168.56.81 (cs-81)
- 192.168.56.82 (cs-82)
- 192.168.56.83 (cs-83)

## Pre Requisites

The following needs to be done on all the nodes that are going to be a part of the cluster

- yum -y install epel-release && yum -y install python2 python3 python2-PyMySQL python3-PyMySQL
- yum -y install htop jq
- yum -y install mlocate net-tools

## Download and Install ES 10.5 and additional package

Login to www.mariadb.com using the enterprise customer user credentials and download the 10.5 ES rpm package for the given required OS

- https://mariadb.com/downloads/#mariadb_platform-enterprise_server
  - https://dlm.mariadb.com/1090714/mariadb-enterprise-server/10.5.4-2/rpm/rhel/mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms.tar
- https://dlm.mariadb.com/1090353/mariadb-enterprise-server/10.5.4-2/cmapi/mariadb-columnstore-cmapi.tar.gz

The above `rpms.tar` and the `cmapi.tar.gz` are both required for this setup.

```
[root@cs-81 ~]# ls -rlt
total 383956
-rw-r--r-- 1 root root  48128557 Jul 17 12:01 mariadb-columnstore-cmapi.tar.gz
-rw-r--r-- 1 root root 345036800 Jul 17 12:02 mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms.tar
```

Add the three IP addresses and the hostnames as per the `$HOSTNAME` for each node in the `/etc/hosts` file

```
[root@cs-81 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.56.81 cs-81
192.168.56.82 cs-82 
192.168.56.83 cs-83 
```

Now that the hosts file is ready, we can install the ES 10.5 and the ColumnStore + CMAPI package

- UnTar the `mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms.tar` and install the server + columnstore on all the nodes
- Setup CMAPI server

Perform the following on all the nodes

```
shell> tar -xvf mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms.tar 
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/galera-enterprise-4-26.4.5-1.el7.8.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-backup-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-backup-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-client-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-client-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-columnstore-engine-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-columnstore-engine-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-common-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-common-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-compat-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-cracklib-password-check-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-cracklib-password-check-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-devel-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-devel-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-gssapi-server-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-gssapi-server-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-hashicorp-key-management-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-hashicorp-key-management-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-rocksdb-engine-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-rocksdb-engine-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-s3-engine-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-s3-engine-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-server-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-server-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-shared-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-shared-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-spider-engine-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-spider-engine-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-xpand-engine-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/MariaDB-xpand-engine-debuginfo-10.5.4_2-1.el7.x86_64.rpm
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/setup_repository
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/6ef137b72e68ec0d2e177bc3aa696db829f61e36aaabf63a171a50690a93acde-primary.xml.gz
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/103ae2166aca11895cdbf2a81c63ba62dc61bb1ebb0a1f2c97becd4d7d83c85d-filelists.xml.gz
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/1a7dc76c90d0906c2eca0ce7e5f4b21c4c5a6c882a55a26e541ff5bcf2d670d2-other.xml.gz
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/repomd.xml
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/d355036a2c84faf8026cee198313910739334a8f8f3bb97e479a607dcc67ef38-other.sqlite.bz2
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/a1c53bb77459afa43756d696175f3bf57873d15f0be710f74b234f71372b7341-filelists.sqlite.bz2
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/repodata/c09093db8e884e83559b84860fd7dfc147aac71d373fc7236ae6b31bacb4d6ad-primary.sqlite.bz2
mariadb-enterprise-10.5.4-2-centos-7-x86_64-rpms/README
```

Remove the conflicting mariadb-libs package from all the nodes

```
[root@cs-81 ~]# rpm -qa | grep -i mariadb
mariadb-libs-5.5.65-1.el7.x86_64

[root@cs-81 ~]# yum -y remove mariadb-libs
Loaded plugins: fastestmirror
Resolving Dependencies
--> Running transaction check
---> Package mariadb-libs.x86_64 1:5.5.65-1.el7 will be erased
--> Processing Dependency: libmysqlclient.so.18()(64bit) for package: 2:postfix-2.10.1-9.el7.x86_64
--> Processing Dependency: libmysqlclient.so.18(libmysqlclient_18)(64bit) for package: 2:postfix-2.10.1-9.el7.x86_64
--> Running transaction check
---> Package postfix.x86_64 2:2.10.1-9.el7 will be erased
--> Finished Dependency Resolution

Dependencies Resolved

==========================================================================================================================================================================================================================================================================================
 Package                                                                Arch                                                             Version                                                                    Repository                                                       Size
==========================================================================================================================================================================================================================================================================================
Removing:
 mariadb-libs                                                           x86_64                                                           1:5.5.65-1.el7                                                             @base                                                           4.4 M
Removing for dependencies:
 postfix                                                                x86_64                                                           2:2.10.1-9.el7                                                             @base                                                            12 M

Transaction Summary
==========================================================================================================================================================================================================================================================================================
Remove  1 Package (+1 Dependent package)

Installed size: 17 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Erasing    : 2:postfix-2.10.1-9.el7.x86_64                                                                                                                                                                                                                                          1/2 
  Erasing    : 1:mariadb-libs-5.5.65-1.el7.x86_64                                                                                                                                                                                                                                     2/2 
  Verifying  : 1:mariadb-libs-5.5.65-1.el7.x86_64                                                                                                                                                                                                                                     1/2 
  Verifying  : 2:postfix-2.10.1-9.el7.x86_64                                                                                                                                                                                                                                          2/2 

Removed:
  mariadb-libs.x86_64 1:5.5.65-1.el7                                                                                                                                                                                                                                                      

Dependency Removed:
  postfix.x86_64 2:2.10.1-9.el7                                                                                                                                                                                                                                                           

Complete!
```

### Install MariaDB 10.5 ES + CS

After the following installation, don't start the service unless the **S3 storage config** has been done properly! 

- rpm -ivh MariaDB-common-10.5.4_2-1.el7.x86_64.rpm MariaDB-compat-10.5.4_2-1.el7.x86_64.rpm
- yum -y install MariaDB-client-10.5.4_2-1.el7.x86_64.rpm MariaDB-shared-10.5.4_2-1.el7.x86_64.rpm MariaDB-backup-10.5.4_2-1.el7.x86_64.rpm
- yum -y install galera-enterprise-4-26.4.5-1.el7.8.x86_64.rpm
- yum -y install MariaDB-server-10.5.4_2-1.el7.x86_64.rpm
- yum -y install MariaDB-columnstore-engine-10.5.4_2-1.el7.x86_64.rpm

Setup S3 storage configuration as per the previous versions using the `/etc/columnstore/storagemanager.cnf`

Change the following variables before the starting up MariaDB / ColumnStore services:

- `service = S3`
- `region = your reagion`
  - leave it blank if unknown
- `bucket = your_s3_bucket_name`
- `aws_access_key_id = s3_key_id`
- `aws_secret_access_key = s3_secret_key`
- `cache_size = 30g`
  - Verify the path `path = /var/lib/columnstore/storagemanager/cache` has sufficient storage else point it to a different location.

Proceed to restart MariaDB service as per normal **`systemctl start mariadb && systemctl start mariadb-columnstore`**

### Setup the CMAPI server

Perform the following on all the 3 nodes

```
shell> mkdir /opt/cmapi
shell> chmod 755 /opt/cmapi
shell> cp mariadb-columnstore-cmapi.tar.gz /opt/cmapi
shell> cd /opt/cmapi
shell> tar -zxvf mariadb-columnstore-cmapi.tar.gz
...
...
...
cmapi_server/helpers.py
cmapi_server/failover_agent.py
cmapi_server/.__main__.py.swp
LICENSE.TXT
COPYRIGHT

shell> ls -rlt
total 47032
drwxr-xr-x  6 mariadbadm mariadbadm       56 Jan  1  2019 python
-rw-r--r--  1 root       root            211 Jul 14 14:20 service.template
-rwxr-xr-x  1 root       root           3950 Jul 14 14:20 service.sh
drwxr-xr-x  3 root       root             39 Jul 14 14:20 mcs_node_control
drwxr-xr-x  2 root       root            136 Jul 14 14:20 failover
-rw-r--r--  1 root       root           1048 Jul 14 14:20 cmapi_logger.conf
-rw-r--r--  1 root       root           4826 Jul 14 14:20 LICENSE.TXT
-rw-r--r--  1 root       root            388 Jul 14 14:20 COPYRIGHT
drwxr-xr-x 49 root       root           4096 Jul 14 14:21 deps
drwxr-xr-x  3 root       root            191 Jul 14 14:21 cmapi_server
-rw-r--r--  1 root       root       48128557 Jul 17 12:12 mariadb-columnstore-cmapi.tar.gz
```

Install the CMAPI service on all the nodes using `./service.sh install`

```
shell> ./service.sh install

Collecting requests
  Downloading https://files.pythonhosted.org/packages/45/1e/0c169c6a5381e241ba7404532c16a21d86ab872c9bed8bdcd4c423954103/requests-2.24.0-py2.py3-none-any.whl (61kB)
    100% |################################| 71kB 1.1MB/s 
Collecting idna<3,>=2.5 (from requests)
  Downloading https://files.pythonhosted.org/packages/a2/38/928ddce2273eaa564f6f50de919327bf3a00f091b5baba8dfa9460f3a8a8/idna-2.10-py2.py3-none-any.whl (58kB)
    100% |################################| 61kB 2.1MB/s 
Collecting certifi>=2017.4.17 (from requests)
  Downloading https://files.pythonhosted.org/packages/5e/c4/6c4fe722df5343c33226f0b4e0bb042e4dc13483228b4718baf286f86d87/certifi-2020.6.20-py2.py3-none-any.whl (156kB)
    100% |################################| 163kB 1.9MB/s 
Collecting urllib3!=1.25.0,!=1.25.1,<1.26,>=1.21.1 (from requests)
  Downloading https://files.pythonhosted.org/packages/e1/e5/df302e8017440f111c11cc41a6b432838672f5a70aa29227bf58149dc72f/urllib3-1.25.9-py2.py3-none-any.whl (126kB)
    100% |################################| 133kB 2.6MB/s 
Collecting chardet<4,>=3.0.2 (from requests)
  Downloading https://files.pythonhosted.org/packages/bc/a9/01ffebfb562e4274b6487b4bb1ddec7ca55ec7510b22e4c51f14098443b8/chardet-3.0.4-py2.py3-none-any.whl (133kB)
    100% |################################| 143kB 2.7MB/s 
Installing collected packages: idna, certifi, urllib3, chardet, requests
Successfully installed certifi-2020.6.20 chardet-3.0.4 idna-2.10 requests-2.24.0 urllib3-1.25.9
Creating service in /etc/systemd/system/mariadb-columnstore-cmapi.service
Created symlink from /etc/systemd/system/multi-user.target.wants/mariadb-columnstore-cmapi.service to /etc/systemd/system/mariadb-columnstore-cmapi.service.
```

Enable the three services on all nodes

```
shell> systemctl enable mariadb 
shell> systemctl enable mariadb-columnstore
shell> systemctl enable mariadb-columnstore-cmapi
```

Start CMAPI service on all three nodes

```
shell> systemctl start mariadb-columnstore-cmapi 

shell> systemctl status mariadb-columnstore-cmapi
● mariadb-columnstore-cmapi.service - Mariadb Columnstore Cluster Manager API
   Loaded: loaded (/etc/systemd/system/mariadb-columnstore-cmapi.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2020-07-17 12:38:10 EDT; 40s ago
 Main PID: 3492 (python3)
   CGroup: /system.slice/mariadb-columnstore-cmapi.service
           └─3492 /opt/cmapi/python/bin/python3 -m cmapi_server

Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020 12:38:11] root  runner(): starting
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020 12:38:11] root  get_module_net_address Module 1 network address 127.0.0.1
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020 12:38:11] root  Failed to find myself in the list of desired nodes, will use cs-81
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020 12:38:11] root  Using cs-81 as my name
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020:12:38:11] ENGINE Bus STARTING
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020 12:38:11] root  Starting the heartbeat listener
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020 12:38:11] root  starting the monitor logic
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020:12:38:11] ENGINE Serving on https://0.0.0.0:8640
Jul 17 12:38:11 cs-81 python3[3492]: [17/Jul/2020:12:38:11] ENGINE Bus STARTED
Jul 17 12:38:12 cs-81 python3[3492]: [17/Jul/2020 12:38:12] root  Failover monitoring is inactive; requires at least 3 nodes and a shared storage system
```

### Creating System Catalog

Once MariaDB and ColumnStore and CMAPI services have been started on all the nodes we can now create the system catalog, this is a one time activity to be done from the **primary** server.

```
shell> dbbuilder 7
Jul 22 00:33:12 cs105-1 IDBFile[15090]: 12.094072 |0|0|0| D 35 CAL0002: IDBFactory::installPlugin: installed filesystem plugin libcloudio.so
Creating System Catalog...

Creating SYSTABLE
---------------------------------------
  Creating TableName column OID: 1001
  Creating TableName column dictionary
  Creating Schema column OID: 1002
  Creating Schema column dictionary
  Creating ObjectId column OID: 1003
  Creating CreateDate column OID: 1004
  Creating LastUpdate column OID: 1005
  Creating INIT column OID: 1006
  Creating NEXT column OID: 1007
  Creating NUMOFROWS column OID: 1008
  Creating AVGROWLEN column OID: 1009
  Creating NUMOFBLOCKS column OID: 1010
  Creating AUTOINCREMENT column OID: 1011

Creating SYSCOLUMN
---------------------------------------
  Creating Schema column OID: 1021
  Creating Schema column dictionary...
  Creating TableName column OID: 1022
  Creating TableName column dictionary...
  Creating ColumnName column OID: 1023
  Creating ColumnName column dictionary...
  Creating ObjectID column OID: 1024
  Creating DictOID column OID: 1025
  Creating ListOID column OID: 1026
  Creating TreeOID column OID: 1027
  Creating DataType column OID: 1028
  Creating ColumnLength column OID: 1029
  Creating ColumnPos column OID: 1030
  Creating LastUpdate column OID: 1031
  Creating DefaultValue column OID: 1032
  Creating DefaultValue column dictionary...
  Creating Nullable column OID: 1033
  Creating Scale column OID: 1034
  Creating Precision column OID: 1035
  Creating AutoInc column OID: 1036
  Creating DISTCOUNT column OID: 1037
  Creating NULLCOUNT column OID: 1038
  Creating MINVALUE column OID: 1039
  Creating MINVALUE column dictionary...
  Creating MAXVALUE column OID: 1040
  Creating MAXVALUE column dictionary...
  Creating CompressionType column OID: 1041
  Creating NEXTVALUE column OID: 1042
System Catalog creation took: 0.729475 seconds to complete.

System Catalog created
```

### Setting up the Cluster

Now that the system catalog has been created, we can proceed to setup the cluster.

ColumnStore does not use SSH to control the cluster anymore instead it uses the CMAPI which we have already installed. 

The API URLs have the following available endpoint options, all these are pointing to the primary node, refer to the IP address:

- `https://192.168.56.81:8640/cmapi/0.4.0/cluster/status`
  - Check the Status of the ColumnStore cluster
- `https://192.168.56.81:8640/cmapi/0.4.0/cluster/start`
  - Start the ColumnStore cluster
- `https://192.168.56.81:8640/cmapi/0.4.0/cluster/shutdown`
  - Shutdown the ColumnStore cluster
- `https://192.168.56.81:8640/cmapi/0.4.0/cluster/add-node`
  - Add a new node the existing ColumnStore cluster
- `https://192.168.56.81:8640/cmapi/0.4.0/cluster/remove-node`
  - Remote a node from the ColumnStore cluster

The Request Headers Needed the following additional items:
- 'x-api-key': 'MyAPIKey123'
- 'Content-Type': 'application/json'

***Note:** x-api-key can be set to any value of your choice during the first call to the server. Subsequent connections will require this same key for all future calls*

#### Various commands through CMAPI

Take note, the following will only effect the `mariadb-columnstore` service and not the MariaDB server's service.

- **Get Status:**
  - `curl -s https://192.168.56.81:8640/cmapi/0.4.0/cluster/status --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' -k | jq .`
- **Start The Cluster:**
  - `curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/start --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20}' -k | jq .`
- **Stop The Cluster:**
  - `curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/shutdown --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20}' -k | jq .`
- **Add a Node:**
  - `curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/add-node --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20, "node": "10.10.10.12"}' -k | jq .`
- **Remove a Node:**
  - `curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/remove-node --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20, "node": "10.10.10.12"}' -k | jq .`

All the Communication to the cluster is done by the above commands. It's a good idea to create simple shell scripts for all of the above with necessary command line parameters to make the maintenance jobs simpler.

_**Note:** The last commands in the URLs above **`| jq .`** is just to format the JSON output from service and more readable, this is not required however but good to have for easy reading of the command output._


#### First API Call

Let's initiate the CMAPI with the `status` command, this will also set the API-Key to `MyAPIKey` permanently.

```
shell> curl -s https://192.168.56.81:8640/cmapi/0.4.0/cluster/status --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' -k | jq .
{
  "timestamp": "2020-07-17 12:51:30.999645",
  "127.0.0.1": {
    "timestamp": "2020-07-17 12:51:31.005688",
    "uptime": 4155,
    "dbrm_mode": "master",
    "cluster_mode": "readwrite",
    "dbroots": [
      "1"
    ],
    "module_id": 1,
    "services": [
      {
        "name": "workernode",
        "pid": 3162
      },
      {
        "name": "controllernode",
        "pid": 3164
      },
      {
        "name": "PrimProc",
        "pid": 3166
      },
      {
        "name": "WriteEngine",
        "pid": 3195
      },
      {
        "name": "ExeMgr",
        "pid": 3198
      },
      {
        "name": "DMLProc",
        "pid": 3241
      },
      {
        "name": "DDLProc",
        "pid": 3242
      }
    ]
  }
}
```

We can see the formatted output nicely telling us the process IDs for individual ColumnStore processes and also the cluster mode "readwrite"


##### Add New Nodes to the cluster

Next step is to add the remaining two nodes to the cluster

```
shell> curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/add-node --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20, "node": "cs-82"}' -k | jq .
{
  "timestamp": "2020-07-17 12:54:42.525710",
  "node_id": "cs-82"
}

shell> curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/add-node --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20, "node": "cs-83"}' -k | jq .
{
  "timestamp": "2020-07-17 12:55:02.965825",
  "node_id": "cs-83"
}
```

The two nodes have been added, we used the hostname which is defined int he /etc/hosts but can also use physical IP addresses instead.

Let's check the cluster status using the `status` API call.

```
[root@cs-81 ~]# curl -s https://192.168.56.81:8640/cmapi/0.4.0/cluster/status --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' -k | jq .
{
  "timestamp": "2020-07-17 12:56:28.179601",
  "cs-81": {
    "timestamp": "2020-07-17 12:56:28.183118",
    "uptime": 4452,
    "dbrm_mode": "master",
    "cluster_mode": "readwrite",
    "dbroots": [
      "1"
    ],
    "module_id": 1,
    "services": [
      {
        "name": "workernode",
        "pid": 14821
      },
      {
        "name": "controllernode",
        "pid": 14832
      },
      {
        "name": "PrimProc",
        "pid": 14837
      },
      {
        "name": "ExeMgr",
        "pid": 14864
      },
      {
        "name": "WriteEngine",
        "pid": 14874
      },
      {
        "name": "DDLProc",
        "pid": 14921
      },
      {
        "name": "DMLProc",
        "pid": 14925
      }
    ]
  },
  "cs-82": {
    "timestamp": "2020-07-17 12:56:28.204909",
    "uptime": 4442,
    "dbrm_mode": "slave",
    "cluster_mode": "readwrite",
    "dbroots": [
      "2"
    ],
    "module_id": 2,
    "services": [
      {
        "name": "workernode",
        "pid": 14819
      },
      {
        "name": "PrimProc",
        "pid": 14828
      },
      {
        "name": "ExeMgr",
        "pid": 14853
      },
      {
        "name": "WriteEngine",
        "pid": 14861
      },
      {
        "name": "DDLProc",
        "pid": 14895
      },
      {
        "name": "DMLProc",
        "pid": 14897
      }
    ]
  },
  "cs-83": {
    "timestamp": "2020-07-17 12:56:28.225614",
    "uptime": 4431,
    "dbrm_mode": "slave",
    "cluster_mode": "readwrite",
    "dbroots": [
      "3"
    ],
    "module_id": 3,
    "services": [
      {
        "name": "workernode",
        "pid": 11217
      },
      {
        "name": "PrimProc",
        "pid": 11221
      },
      {
        "name": "ExeMgr",
        "pid": 11253
      },
      {
        "name": "WriteEngine",
        "pid": 11261
      },
      {
        "name": "DDLProc",
        "pid": 11296
      },
      {
        "name": "DMLProc",
        "pid": 11300
      }
    ]
  }
}
```

The cluster seems to be looking good with proper DBroots assigned automatically to all nodes. Before we connect to the `mariadb` client, we need to setup the basic replication between the Primary and the two Replica nodes

Edit the `/etc/my.cnf.d/columnstore.cnf` file and define the server_id, enable the binary logs on all three nodes

- `cs-81` `/etc/my.cnf.d/columnstore.cnf`

    ```
    # Required for Schema Sync
    server-id = 1000
    log_bin
    ```

- `cs-82` `/etc/my.cnf.d/columnstore.cnf`

    ```
    # Required for Schema Sync
    server-id = 2000
    log_bin
    ```

- `cs-83` `/etc/my.cnf.d/columnstore.cnf`

    ```
    # Required for Schema Sync
    server-id = 3000
    log_bin
    ```

Once all the files have been saved, we can now stop/start the MariaDB server using the standard `systemctl restart mariadb` on all the nodes.

#### Verify Binary Logs and Server ID on all three nodes

- `cs-81`
    ```
    [root@cs-81 ~]# mariadb
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 4
    Server version: 10.5.4-2-MariaDB-enterprise-log MariaDB Enterprise Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> show global variables like 'log_bin';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | log_bin       | ON    |
    +---------------+-------+
    1 row in set (0.000 sec)

    MariaDB [(none)]> show global variables like 'server_id';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | server_id     | 1000  |
    +---------------+-------+
    1 row in set (0.000 sec)
    ```

- `cs-82`
    ```
    [root@cs-81 ~]# mariadb
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 4
    Server version: 10.5.4-2-MariaDB-enterprise-log MariaDB Enterprise Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> show global variables like 'log_bin';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | log_bin       | ON    |
    +---------------+-------+
    1 row in set (0.000 sec)

    MariaDB [(none)]> show global variables like 'server_id';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | server_id     | 2000  |
    +---------------+-------+
    1 row in set (0.000 sec)
    ```

- `cs-83`
    ```
    [root@cs-83 ~]# mariadb
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 4
    Server version: 10.5.4-2-MariaDB-enterprise-log MariaDB Enterprise Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> show global variables like 'log_bin';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | log_bin       | ON    |
    +---------------+-------+
    1 row in set (0.000 sec)

    MariaDB [(none)]> show global variables like 'server_id';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | server_id     | 3000  |
    +---------------+-------+
    1 row in set (0.000 sec)
    ```

#### Schema Replication Setup

Create a user account to control replication just as per normal on the primary node and then execute `CHANGE MASTER` command on the two replica nodes to set them up.

On the primary node, create a user account and grant `REPLICAION SLAVE` privileges   

- `cs-81`
    ```
    MariaDB [(none)]> create user repl_user@'%' identified by 'P@ssw0rd'; 
    Query OK, 0 rows affected (0.010 sec)

    MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO repl_user@'%';
    Query OK, 0 rows affected (0.008 sec)
    ```

- `cs-82` & `cs-83`
    ```
    MariaDB [(none)]> SET GLOBAL GTID_SLAVE_POS='';
    Query OK, 0 rows affected (0.017 sec)

    MariaDB [(none)]> CHANGE MASTER TO MASTER_HOST='192.168.56.81', MASTER_USER='repl_user', MASTER_PASSWORD='P@ssw0rd', MASTER_USE_GTID=current_pos;
    Query OK, 0 rows affected (0.015 sec)

    MariaDB [(none)]> START SLAVE;
    Query OK, 0 rows affected (0.014 sec)

    MariaDB [(none)]> SHOW SLAVE STATUS\G
    *************************** 1. row ***************************
                    Slave_IO_State: Waiting for master to send event
                    Master_Host: 192.168.56.81
                    Master_User: repl_user
                    Master_Port: 3306
                    Connect_Retry: 60
                Master_Log_File: cs-81-bin.000001
            Read_Master_Log_Pos: 651
                    Relay_Log_File: cs-82-relay-bin.000002
                    Relay_Log_Pos: 950
            Relay_Master_Log_File: cs-81-bin.000001
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
            Exec_Master_Log_Pos: 651
                Relay_Log_Space: 1259
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
                    Gtid_IO_Pos: 0-1000-2
        Replicate_Do_Domain_Ids: 
    Replicate_Ignore_Domain_Ids: 
                    Parallel_Mode: optimistic
                        SQL_Delay: 0
            SQL_Remaining_Delay: NULL
        Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
                Slave_DDL_Groups: 2
    Slave_Non_Transactional_Groups: 0
        Slave_Transactional_Groups: 0
    1 row in set (0.000 sec)
    ```

Basic replication has been setup between the nodes. Let's test it out.

Create a database and two tables, one using InnoDB and the other one using ColumnStore as the storage engine;

- `cs-81`
    ```
    MariaDB [(none)]> create database testdb;
    Query OK, 1 row affected (0.000 sec)

    MariaDB [(none)]> use testdb;
    Database changed

    MariaDB [testdb]> select @@hostname;
    +------------+
    | @@hostname |
    +------------+
    | cs-81      |
    +------------+
    1 row in set (0.000 sec)

    MariaDB [testdb]> create table tab_i(id serial, c1 varchar(100)) engine=InnoDB;
    Query OK, 0 rows affected (0.013 sec)

    MariaDB [testdb]> create table tab_cs(id bigint, c1 varchar(100)) engine=ColumnStore;
    Query OK, 0 rows affected (0.275 sec)

    MariaDB [testdb]> show tables;
    +------------------+
    | Tables_in_testdb |
    +------------------+
    | tab_cs           |
    | tab_i            |
    +------------------+
    2 rows in set (0.000 sec)
    ```

Verify the two tables can be accessed from the other two nodes

- `cs-82`
    ```
    MariaDB [(none)]> show databases;
    +---------------------+
    | Database            |
    +---------------------+
    | calpontsys          |
    | columnstore_info    |
    | infinidb_querystats |
    | information_schema  |
    | mysql               |
    | performance_schema  |
    | testdb              |
    +---------------------+
    7 rows in set (0.009 sec)

    MariaDB [(none)]> use testdb;
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed
    MariaDB [testdb]> select @@hostname;
    +------------+
    | @@hostname |
    +------------+
    | cs-82      |
    +------------+
    1 row in set (0.000 sec)

    MariaDB [testdb]> show tables;
    +------------------+
    | Tables_in_testdb |
    +------------------+
    | tab_cs           |
    | tab_i            |
    +------------------+
    2 rows in set (0.000 sec)
    ```

- `cs-83`
    ```
    MariaDB [(none)]> show databases;
    +---------------------+
    | Database            |
    +---------------------+
    | calpontsys          |
    | columnstore_info    |
    | infinidb_querystats |
    | information_schema  |
    | mysql               |
    | performance_schema  |
    | testdb              |
    +---------------------+
    7 rows in set (0.009 sec)

    MariaDB [(none)]> use testdb;
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed
    MariaDB [testdb]> select @@hostname;
    +------------+
    | @@hostname |
    +------------+
    | cs-83      |
    +------------+
    1 row in set (0.000 sec)

    MariaDB [testdb]> show tables;
    +------------------+
    | Tables_in_testdb |
    +------------------+
    | tab_cs           |
    | tab_i            |
    +------------------+
    2 rows in set (0.000 sec)
    ```

#### Cross Engine Join User

Login to the `mariadb` CLI on the Primary node and create a new user to be used for for Cross Engine Joins, lets say **`cej_user@localhost`** This user needs SELECT privilege on the specific databases that are needed by the user.

```
MariaDB [testdb]> create user cej_user@'%' identified by 'P@ssw0rd';
Query OK, 0 rows affected (0.008 sec)

MariaDB [testdb]> grant select on *.* to cej_user@'%';
Query OK, 0 rows affected (0.009 sec)
```

Note: Since the replication is already set-up, this Cross Engine user will auto replicate to all the other nodes.

Also create an **`app_user@'%'`** that we will use to connect to the databases and test ColumnStore / Cross Engine queries.

```
MariaDB [testdb]> create user app_user@'%' identified by 'P@ssw0rd';
Query OK, 0 rows affected (0.007 sec)

MariaDB [testdb]> grant all on testdb.* to app_user@'%';
Query OK, 0 rows affected (0.005 sec)
```


Now on the primary node, add this user to the ColumnStore configuration using the 

```
shell> export LC_ALL=C
shell> mcsSetConfig CrossEngineSupport User cej_user
shell> mcsSetConfig CrossEngineSupport Password P@ssw0rd
```

Now restart the ColumnStore service using the API call, this will restart the complete ColumnStore cluster.

On the primary node, execute:

```
shell> curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/shutdown --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20}' -k | jq .
{
  "timestamp": "2020-07-17 13:04:19.994966",
  "cs-81": {
    "timestamp": "2020-07-17 13:04:22.593958"
  },
  "cs-82": {
    "timestamp": "2020-07-17 13:04:23.092356"
  },
  "cs-83": {
    "timestamp": "2020-07-17 13:04:23.618378"
  }
}

shell> curl -s -X PUT https://192.168.56.81:8640/cmapi/0.4.0/cluster/start --header 'Content-Type:application/json' --header 'x-api-key:MyAPIKey123' --data '{"timeout":20}' -k | jq .
{
  "timestamp": "2020-07-17 13:04:38.063470"
}
```

#### Cross Engine Queries

Connect to Primary Node using the `app_user`, this user will only have access to the `testdb` database;

```
[root@cs-81 ~]# mariadb -uapp_user -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 10.5.4-2-MariaDB-enterprise-log MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| testdb             |
+--------------------+
2 rows in set (0.000 sec)

MariaDB [(none)]> use testdb;

MariaDB [testdb]> show tables;
+------------------+
| Tables_in_testdb |
+------------------+
| tab_cs           |
| tab_i            |
+------------------+
2 rows in set (0.000 sec)

MariaDB [testdb]> insert into tab_i (c1) select column_name from information_schema.columns;
Query OK, 855 rows affected (0.020 sec)
Records: 855  Duplicates: 0  Warnings: 0

MariaDB [testdb]> insert into tab_cs select * from tab_i;
Query OK, 855 rows affected (1.261 sec)
Records: 855  Duplicates: 0  Warnings: 0
```

Let's see if cross engine queries work :)

```
MariaDB [testdb]> select a.id, b.c1 from tab_i a inner join tab_cs b on b.id=a.id order by b.c1 desc limit 10;
+-----+------------------------------+
| id  | c1                           |
+-----+------------------------------+
| 704 | ZIP_PAGE_SIZE                |
| 744 | ZIP_PAGE_SIZE                |
| 675 | YOUNG_MAKE_PER_THOUSAND_GETS |
|  69 | XA                           |
| 147 | WRITE_REQUESTS               |
| 148 | WRITES                       |
| 771 | WRITER_THREAD                |
| 647 | WORD                         |
| 842 | WORD                         |
| 610 | WIDTH                        |
+-----+------------------------------+
10 rows in set (0.039 sec)
```

Without properly configured Cross Engine user account we would get the following error!

```
MariaDB [testdb]> select a.id, b.c1 from tab_i a inner join tab_cs b on b.id=a.id order by b.c1 desc limit 10;
ERROR 1815 (HY000): Internal error: fatal error running mysql_real_connect() in libmysql_client lib (1045) (Access denied for user 'cej_user'@'cs-81' (using password: YES))
```

### Non root Adjustments

This is an **optional** section if running ColumnStore services as a non-root user `mysql` is reqiured.

##### Stop Service
systemctl stop mariadb && systemctl stop mariadb-columnstore && systemctl stop mariadb-columnstore-cmapi

##### Setting UTF8 Character Set

Edit the `/etc/my.cnf.d/columnstore.cnf` and add the following.

```
character_set_server = utf8
collation_server = utf8_general_ci
```

##### Creating Non Root Policy

Edit the `/etc/polkit-1/rules.d/51-columnstore.rules` file with the root user and add the following block

```
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units") {
        if (subject.isInGroup("mysql")) {
            return polkit.Result.YES;
        } else {
            return polkit.Result.AUTH_ADMIN;
        }
    }
});
```

##### Adjust ColumnStore Unit Files 1/3

Edit the following service files and add the contents under the `[Service]` section

- `/usr/lib/systemd/system/mcs-primproc.service`
- `/usr/lib/systemd/system/mcs-writeengineserver.service`
- `/usr/lib/systemd/system/mcs-exemgr.service`
- `/usr/lib/systemd/system/mcs-storagemanager.service`

```
[Service]
LimitNOFILE=1048576
LimitNPROC=1048576
User=mysql
Group=mysql
```

##### Adjust ColumnStore Unit Files 2/3

Edit the followig service files and add the User/Group under `[Service]` section.

- `/usr/lib/systemd/system/mariadb-columnstore.service`
- `/usr/lib/systemd/system/mcs-loadbrm.service`
- `/usr/lib/systemd/system/mcs-workernode.service`
- `/usr/lib/systemd/system/mcs-controllernode.service`
- `/usr/lib/systemd/system/mcs-ddlproc.service`
- `/usr/lib/systemd/system/mcs-dmlproc.service`

```
[Service]
User=mysql
Group=mysql
```

##### Adjust ColumnStore Unit Files 3/3

Edit the `/etc/systemd/system/mariadb-columnstore-cmapi.service` file and change the **`User=root`** to **`User=mysql`**

##### daemon reload

Once all the above 3 stages are completed, execute `systemctl daemon-reload` to activate the changed configurations.

##### Changing Ownership of Folders for Non-Root Installs

Finally, change the ColumnStore related file ownership and permissions as per follows

```
shell> chown -R mysql:mysql /var/lib/columnstore
shell> chown -R mysql:mysql /tmp/columnstore_tmp_files
shell> chown -R mysql:mysql /opt/cmapi
shell> chown -R mysql:mysql /etc/columnstore
shell> chown -R mysql:mysql /var/log/mariadb

shell> chmod -R 0777 /dev/shm
shell> chmod -R 0777 /tmp/columnstore_tmp_files

```

##### Setup /etc/sudoers

Setup the sudo permission for the `mysql` user so that it has priviliges to `start`, `stop`, `restart` and `status` of the following three services

- mariadb.service
- mariadb-columnstore
- mariadb-columnstore-cmapi

```
shell> echo "mysql     ALL=(root)     NOPASSWD: /usr/bin/systemctl start mariadb, /usr/bin/systemctl start mariadb-columnstore, /usr/bin/systemctl start mariadb-columnstore-cmapi, /usr/bin/systemctl stop mariadb, /usr/bin/systemctl stop mariadb-columnstore, /usr/bin/systemctl stop mariadb-columnstore-cmapi, /usr/bin/systemctl restart mariadb, /usr/bin/systemctl restart mariadb-columnstore, /usr/bin/systemctl restart mariadb-columnstore-cmapi, /usr/bin/systemctl status mariadb, /usr/bin/systemctl status mariadb-columnstore, /usr/bin/systemctl status mariadb-columnstore-cmapi" >> /etc/sudoers
```

##### Enabling Services

sudo systemctl stop mariadb && sudo systemctl stop mariadb-columnstore && sudo systemctl stop mariadb-columnstore-cmapi
sudo systemctl start mariadb && sudo systemctl start mariadb-columnstore && sudo systemctl start mariadb-columnstore-cmapi

#### Thank You
