# MariaDB Encryption (TDE)

Workiong with many of the clients, TDE is one of the most common requirement that comes up frequently. I decided to do write this blog to cover the very same topic.

MariaDB does indeed supports Transparent Data Encryption, a.k.a, TDE. There are some misconceptions about the TDE that I would like to clear up first before we move forward with implementing this thing. 

## Misconceptions

The main misconception surrounding databnase encryption, TDE, is that if someone who does not have access to the security Key will get junk/encrypted data and wont be able to read it! 

This is not true, It's important to understand what is meant by TDE, it's short for "Transparent Data Encryption", remember the word "Transparent"! This essentially means thjat the database is encryupted at the filesystem level, means the data files containing the actual data are encrypted, encryption and decryption of data is done by MariaDB with the help of a secret key, as long as MariaDB can access the secret key, all the users who have "SELECT" privilege to the tables, can read the data, and same thing goes to other DML privileges, `INSERT, UPDATE and DELETE` none of these operations are impacted by encryption of data at rest or TDE. 

This pritects the database against physical theft, means, someone tries to copy the entire database filesystem and tries to read those data files on his own MariaDB server, will indeed fail and not able to read those because his MariaDB server don't have the secret key that is required to unlock the data. 

Similarly if the thief, physically het hold of the HDD storage drive containinig the actual data directory will still not be able to start the server even if he plugs in the HDD on his computer because the HDD does not have the security key that is required to decrypt the database and start the server properly.

## Encryption of Specific Columns

This is another misconmception that I see most of the times, once implemented, TDE is applied to the entire table or the to the entire database, logs etc. It's never on partial tables or specific columns. 

However if that is somethign desired for a particular usecase, MariaDB does offer a range of encryption functions to specifically encrypt those columns as long as they are text based. These funnctions ar:

- `AES_ENCRPT(<Text to Encrypt>, <Secret password>)`
- `AES_DECRYPT(<Text to Encrypt>, <Secret password>)` 

These func can encrypt the text based on the given password, in this case, the password is stored and maintained by the application instead of the Database unlike the TDE secret key.

This does increase some complexity within the application code, as the code needs to use these functions to encrypt and decrypt the data each time.

```txt
SELECT AES_DECRYPT(customer_name, ?) from customer;
UPDATE customer SET customer_name = AES_ENCRYPT(?, ?);
```

***Note:** Here **`?`** is the binding of the prepare statement within the code*

In this case, if the user tries to access the sensitive information without using the above mentioned function and the appropriate passowrd, all they will see is junk when reading those specific columns.

Here is an example

```txt
MariaDB [testdb]> insert into customer(customer_name) values (AES_ENCRYPT('Roger Rabbit', 'SecretPassw0rd!'));
Query OK, 1 row affected (0.013 sec)

MariaDB [testdb]> insert into customer(customer_name) values (AES_ENCRYPT('Peter Pan', 'SecretPassw0rd!'));
Query OK, 1 row affected (0.012 sec)

MariaDB [testdb]> insert into customer(customer_name) values (AES_ENCRYPT('Buggs Bunny', 'SecretPassw0rd!'));
Query OK, 1 row affected (0.013 sec)
```

Three rows are inserted into the `customer` table and customer_name is specifically encrypted using `AES_ENCRYPT()` function and a secret password which is maintained by the application as discussed earlier.

Now if we try to read the table without decrypting the customer_name column with appropriate password, all we will get is junk.

```txt
MariaDB [testdb]> select * from customer;
+----+--------------------------+
| id | customer_name            |
+----+--------------------------+
|  1 | vòWÕ­d	q=oÃê}         |
|  2 | ½EEÖv%˜žõ¦3Z#‰8         |
|  3 | ÀGVk1íŠ8|>jÉ¦           |
+----+--------------------------+
3 rows in set (0.001 sec)
```

We do get three rows, ID colums is as per normal, but no name.

Let's try to read it using the proper way how it was meant to be read.

```txt
MariaDB [testdb]> select id, AES_DECRYPT(customer_name, 'SecretPassw0rd!') AS customer_name from customer;
+----+---------------+
| id | customer_name |
+----+---------------+
|  1 | Roger Rabbit  |
|  2 | Peter Pan     |
|  3 | Buggs Bunny   |
+----+---------------+
3 rows in set (0.001 sec)
```

There we have it. What we see here is **not** TDE/Encryption of data at rest.

Alright, I hope this clears the misconceptions and also explains how the sencitive columns can be encrypted where the encryption/decryption key is maintained by the app itself.

# TDE

As we discussed, TDE is done and managed by MariaDB server and the clients/apps don't have to worry about the key. The purpose of TDE is not protecting the data from un authorised clients running select statements. For that you need to manage security through SELECT, INSERT, UPDATE and DELETE privileges or encrypt specic columns using the two functions we discussed above. 

TDE, requires a security key which the server uses to encrypt/decrypt the data files. This requires the use of plugins that are built by MariaDB. Currently the following three plugins are availalbe. 

- File Key Management Encryption Plugin
  - <https://mariadb.com/kb/en/file-key-management-encryption-plugin/>
  - The key file is stored within the MariaDB server itself, best to keep it in a separate mount that is not a part of the server but still it's not the most secure way of storing the key file.
- AWS Key Management Encryption Plugin
  - <https://mariadb.com/kb/en/aws-key-management-encryption-plugin/>
  - Key file is stored on AWS and managed by AWS
  - This is very secure but not all the clients can have access to internet from their priduction servers. This is fine, however, if the DB is running on AWS.
- HashiCorp Vault Encruption Plugin
  - <https://mariadb.com/kb/en/hashicorp-vault-and-mariadb/>
  - This is the best way to setup encryptionm keys if internet access is not available
  - HashiCorp (opensource) Vault can be set up within the customer environment and MariaDB plugin can access it for getting the secure keys.

In this blog, we will cover how to implement File Key Management plugin and in Part 2, we will cover the HashiCorp vault.

## Implementing TDE

Following are the highlevel steps that are required to implement database encruption at rest.

- Generate Security Key
- Encrypt the Security key using AES 256, 196 or 128 bits
- Protect the key file so that no one other than MariaDB process owner (`mysql`) user can access it.
- Configure the MariaDB config file to implement Encryption parameters
  - This will start to execute background encryption threads of the entire databsae and other objects that we configure to be encrypted
- Verify the progress of the encryption within the MariaDB using MariaDB CLI
- Verify the physical data files are actually encrypted and unreadable.

### Generating Keys

Since we are going to be implementing **File Key Management Encryption plugin** we will be generating the key that sits within the MariaDB server, but as suggested we need to protect the file so that no one other than the MariaDB process user, `mysql:mysql` can read it. Other than that it is highly recommended to mount it to an external storage so that even if someone steals the server itself, he will not be able to start the server because of the missing key. 

However for the sake of this, we will just be creating a secure folder within our MariaDB VM and protect it the best we can.

We are going to create a new folder under `/etc/mysql/encryption` to store our keys.

```txt
$ mkdir -p /etc/mysql/encryption
$ openssl rand -hex 32 >> /etc/mysql/encryption/keyfile
```

The above will generate a random 32 byte key to the `/etc/mysql/encryption/keyfile` file. 32 byte key is good for AES 256 bit encryption.

Let's verify the keys

```txt
$ cat /etc/mysql/encryption/keyfile
41c32aba5037876ae014f9a17c4bbf1f1de1266026ad77adfee502eb344dc59c
```

Edit the file and prefix a Key ID **`1;`** before the key line.

```
$ vi /etc/mysql/encryption/keyfile   # add encryption Key IDs every row in the keyfile
$ cat /etc/mysql/encryption/keyfile  # verify the Key IDs are appended properly
1;41c32aba5037876ae014f9a17c4bbf1f1de1266026ad77adfee502eb344dc59c
```

The key is ready now which will be used for encrypting. But before we can use this, to make it secure, we need to encrypt the key itself :)

Generate another key, we can either generate the key randomly or key in a password, it's up to us.

Let's generate a random key and then encrypt our original 32 byte `/etc/mysql/encryption/keyfile` with using this new key

```txt
$ openssl rand -hex 128 > /etc/mysql/encryption/keyfile.key
$ openssl enc -aes-256-cbc -md sha1 -pass file:/etc/mysql/encryption/keyfile.key -in /etc/mysql/encryption/keyfile -out /etc/mysql/encryption/keyfile.enc
```

The above has generated an encrypted key file with the help of our original key and the new secret key, the output file containing the final key is `/etc/mysql/encryption/keyfile.enc`

We can now remove the original unencrypted key file

```txt
$ rm -f /etc/mysql/encryption/keyfile

$ ls -lrt /etc/mysql/encryption/
total 8
-rw-r--r--. 1 root root 257 Mar 22 17:43 keyfile.key
-rw-r--r--. 1 root root  96 Mar 22 17:43 keyfile.enc
```

Finally we need to change the ownership of the /etc/mysql folder and all the files within to be owned by `mysql:mysql` user and group and set permission to read only and no permission for group / global.

```txt
$ chown -R mysql:mysql /etc/mysql
$ chmod -R 500 /etc/mysql
$ ls -lRt /etc/mysql
/etc/mysql:
total 0
dr-x------. 2 mysql mysql 44 Mar 22 17:45 encryption

/etc/mysql/encryption:
total 8
-r-x------. 1 mysql mysql  96 Mar 22 17:43 keyfile.enc
-r-x------. 1 mysql mysql 257 Mar 22 17:43 keyfile.key
```

Key files are now secure with proper ownership and permissions. We are ready for Encryption of database at rest.

### Enable Encryption within MariaDB

Before we encrypt the database, let's do a few quick tests, simple SELECT statement retrieves the data as per normal

```
MariaDB [testdb]> select * from employee;
+----+--------------+
| id | c1           |
+----+--------------+
|  1 | Roger Rabbit |
|  2 | Peter Pan    |
|  3 | Buggs Bunny  |
+----+--------------+
3 rows in set (0.002 sec)
```

Let's view the data stored within the raw file `/var/lib/mysql/testdb/employee.ibd`

```
$ cat /var/lib/mysql/testdb/employee.ibd | strings | head -20
infimum
supremum
Roger Rabbit	
Peter Pan
Buggs Bunny
```

The data is clearly visible in open text as expected. Now we can proceed to implement the encryption configuration and restart the MariaDB server.

Edit the **`/etc/my.cnf.d/server.cnf`** file and add the following in the **`[mariadb]`** section as follows

```
[mariadb]
plugin_load_add = file_key_management
file_key_management_filename = /etc/mysql/encryption/keyfile.enc
file_key_management_filekey = FILE:/etc/mysql/encryption/keyfile.key
file_key_management_encryption_algorithm = AES_CTR

innodb_encrypt_tables = FORCE
innodb_encrypt_log = ON
innodb_encrypt_temporary_tables = ON
innodb_tablespaces_encryption = ON
encrypt_tmp_disk_tables = ON
encrypt_tmp_files = ON
encrypt_binlog = ON
aria_encrypt_tables = ON

innodb_encryption_threads = 4
innodb_encryption_rotation_iops = 2000

innodb_encryption_rotate_key_age = 1024
```

The first section of the config loads the `file_key_management` plugin and defines the path to the key and encrypted key file. Followed by the encryption algorith to be used `file_key_management_encryption_algorithm = AES_CTR`

Second part enables forced encrytion of all tables with `innodb_encrypt_tables = FORCE`, Encrypt the redo logs with the help of `innodb_encrypt_log = ON`, Temporary tables encrption `innodb_encrypt_temporary_tables = ON`, Tablespaces encryption `innodb_tablespaces_encryption = ON`, encrypt temporary files `encrypt_tmp_files = ON`, encrypt the binary logs `encrypt_binlog = ON` and finally  encrypt the ARIA tables `aria_encrypt_tables = ON`

Next section sets the number of background threads that will encrypt/decrypt the data `innodb_encryption_threads = 4` and the IOPS setup to speed up the process with the help of `innodb_encryption_rotation_iops = 2000` 

Finally we have a special parameter that will start the background encryption of the existing tables, this is currently set to `1024` which means it's enabled. We need any non-zero value set for this variable to let MariaDB know that we want to start the encryotion of all the existing tables. For a new database, we can keep it at `0` as all the new tables will automatically be encrypted but if we have any existing tables with or without data, we need to set it to a value greater than ZERO.

If we restart the server now, we can see the tables encrpting in the background.

Let's restart the MariaDB server using `systemctl restart mariadb`.

***Note:** remember to disable SELinux as this might create problems, this is only for this tutorial's sake, SELinux needs to be configured and set up properly for any produciton environment.*

We can monitor the progress of the background encryption by executing the following

```txt
MariaDB [none]> SELECT CURRENT_TIMESTAMP() AT, A.SPACE, A.NAME, B.ENCRYPTION_SCHEME, B.ROTATING_OR_FLUSHING
	FROM information_schema.INNODB_TABLESPACES_ENCRYPTION B 
	JOIN information_schema.INNODB_SYS_TABLES A ON A.SPACE = B.SPACE
	WHERE ROTATING_OR_FLUSHING != 0
        ORDER BY B.ROTATING_OR_FLUSHING;

+---------------------+-------+------------------+-------------------+----------------------+
| AT                  | SPACE | NAME             | ENCRYPTION_SCHEME | ROTATING_OR_FLUSHING |
+---------------------+-------+------------------+-------------------+----------------------+
| 2021-03-22 19:02:19 |     0 | SYS_TABLESPACES  |                 1 |                    1 |
| 2021-03-22 19:02:19 |     0 | SYS_FOREIGN_COLS |                 1 |                    1 |
| 2021-03-22 19:02:19 |     0 | SYS_FOREIGN      |                 1 |                    1 |
| 2021-03-22 19:02:19 |     0 | SYS_VIRTUAL      |                 1 |                    1 |
| 2021-03-22 19:02:19 |     0 | SYS_DATAFILES    |                 1 |                    1 |
| 2021-03-22 19:02:19 |    17 | sbtest/sbtest1   |                 1 |                    1 |
+---------------------+-------+------------------+-------------------+----------------------+
6 rows in set (6.544 sec)
```

The above output shows that the tables / tablespaces are being encrypted. Wait till the output shows no rows, then we can be sure all the objects have been encrypted successfully.

The column `ROTATING_OR_FLUSHING` indicates that the table is being encrypted in the background. This is a background process and does not impact the normal usage of the database. At this time, clients can conenct and start using MariaDB.

Once completed the above SQL will not return any output, we can now see which of the tables are encrypted 

```txt
MariaDB [none]> SELECT A.NAME, B.ENCRYPTION_SCHEME FROM information_schema.INNODB_TABLESPACES_ENCRYPTION B 
      JOIN information_schema.INNODB_SYS_TABLES A ON A.SPACE = B.SPACE;

+----------------------------+-------------------+
| NAME                       | ENCRYPTION_SCHEME |
+----------------------------+-------------------+
| SYS_DATAFILES              |                 1 |
| SYS_FOREIGN                |                 1 |
| SYS_FOREIGN_COLS           |                 1 |
| SYS_TABLESPACES            |                 1 |
| SYS_VIRTUAL                |                 1 |
| mysql/gtid_slave_pos       |                 1 |
| mysql/innodb_index_stats   |                 1 |
| mysql/innodb_table_stats   |                 1 |
| mysql/transaction_registry |                 1 |
| sbtest/sbtest1             |                 1 |
| sbtest/sbtest2             |                 1 |
| sbtest/sbtest3             |                 1 |
| sbtest/sbtest4             |                 1 |
| sbtest/sbtest5             |                 1 |
| sbtest/sbtest6             |                 1 |
| sbtest/sbtest7             |                 1 |
| sbtest/sbtest8             |                 1 |
| sbtest/sbtest10            |                 1 |
| sbtest/sbtest11            |                 1 |
| sbtest/sbtest12            |                 1 |
| sbtest/sbtest13            |                 1 |
| sbtest/sbtest14            |                 1 |
| sbtest/sbtest15            |                 1 |
| sbtest/sbtest16            |                 1 |
| sbtest/sbtest17            |                 1 |
| sbtest/sbtest18            |                 1 |
| sbtest/sbtest19            |                 1 |
| sbtest/sbtest20            |                 1 |
| sbtest/sbtest9             |                 1 |
| testdb/customer            |                 1 |
| testdb/employee            |                 1 |
+----------------------------+-------------------+
30 rows in set (0.002 sec)
```

As long as `ENCRYPTION_SCHEME` is > 0 it's encrypted. All the above tables under `mysql.*` and `sbtest.*` tables have been successfully encrypted.

Let's repeat out test once more

```
MariaDB [testdb]> SELECT * FROM employee;
+----+--------------+
| id | c1           |
+----+--------------+
|  1 | Roger Rabbit |
|  2 | Peter Pan    |
|  3 | Buggs Bunny  |
+----+--------------+
3 rows in set (0.002 sec)
```

The data is still accessible without any special techinque, as long the user has access grants to the table, the data is accessible. Let's view the data stored inside the raw InnoDB IBD file `/var/lib/mysql/testdb/employee.ibd`

```
[root@mariadb-201 testdb]# cat employee.ibd | strings | head -20
.*0/
X<!J
Go7V
yKYxz
`5al
)(x5*
"%Lwb
-^#c
Z4}8vh
rO>$p
xw&}Q
~^>$$
gMxa
>zy_\
NY]d
`WTF
VO}Iw)
 !Y9j
o<$b
\nsP
```

We can see that even though the user can query the table using SELECT, the data in the data files is indeed encrypted and unreadable. Now if someone wants to use these data files within his own server, he can't use them because these files are now encrypted using a secret key.

### Removing TDE

Easiest way to remove encryption is by simply setting those parameter values to `NO`

```
innodb_encrypt_tables = NO
innodb_encrypt_log = NO
aria_encrypt_tables = NO
encrypt_tmp_disk_tables = NO
innodb_encrypt_temporary_tables = NO
encrypt_tmp_files = NO
encrypt_binlog = NO

innodb_encryption_rotation_iops = 2000
innodb_encryption_threads = 4
innodb_encryption_rotate_key_age = 1024
```

Restart the MariaDB server and monitor the progress using the same SQL as previously 

```
SELECT A.NAME, B.ENCRYPTION_SCHEME FROM information_schema.INNODB_TABLESPACES_ENCRYPTION B 
      JOIN information_schema.INNODB_SYS_TABLES A ON A.SPACE = B.SPACE WHERE B.ENCRYPTION_SCHEME = 0;
```

Once all the tables report `ENCRYPTION_SCHEME=0` the database has been decrypted, mow remove all the Encryption related configuration from the `server.cnf` file, shutdown the MariaDB service using `systemctl stop mariadb` and remove the redo log files **`ib_logfile0`**, this is usually located under the default data directory unless until defined to a different location. Once done, restart the server `systemctl restart mariadb` and the encryption is gone.

Part two of this blog, we will be looking at implementing this using the Hashicorp Vault for best possible security and protection of the encryption keys.

Thank you!