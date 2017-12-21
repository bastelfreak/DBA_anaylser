# DBA - BigData Analyser in SQL

## Table of contents

* Setup


---

## Setup

### Basics
This section explains the installation of the server + data generation. We
start with the setup of the actual SQL server. We will use percona here, it is
binary-compatible with MySQL but has a license that fits better into open
source projects (GPL). The following statements as root user on Archlinux will
prepare the database-(server):

```bash
pacman -S community/percona-toolkit community/percona-server-clients community/percona-server
mysqld --initialize --user=mysql
systemctl start mysqld
mysql_secure_installation
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```

### Enhancements

A few things should be configured before we actually use the server. The
following settings should be part of the `/etc/mysql/my.cnf`:

```ini
[client]
default-character-set = utf8mb4

[mysqld]
collation_server = utf8mb4_unicode_ci
character_set_server = utf8mb4
innodb_file_per_table = 1
innodb_large_prefix = 1
innodb_buffer_pool_size=1G

[mysql]
default-character-set = utf8mb4
auto-rehash
thread_handling=pool-of-threads
```

This enforces the correct encoding for all upcoming datasets in the database
and connections to the database. It also enabled auto-completion in the CLI
tool. We will probably have big databases, so we tell mysqld to store not a
single file per database, but per table. Afterwards the service needs to be
restarted:

```bash
systemctl restart mysqld
```

### Datasets

We have one tables, called datasets, which holds all of our data. Since this is
is a big data application, we get the data not in the third normal form, that
would not scale. Instead we have datasets, a single dataset is a collection of
key-value information, represented as a JSON object. An example is:

```json
{"Gender": "Female", "Birthday": "1995-03-17 11:49:30.000000", "federate_state": "Bayern", "car_manufacturer": "Porsche"}
```

Each dataset contains the same attributes. They are:

* Gender (Male or Female)
* Birthday (all people are 20 to 45 years old)
* Federate state (one of our 16 federate states)
* Car manufacturer (Full list of values is stored in the table

```
$ mysql --database bigdata --execute "SELECT name FROM car_manufacturers"
+---------------+
| name          |
+---------------+
| Aston Martin  |
| Audi          |
| BMW           |
| Ford          |
| Mercedes-Benz |
| Opel          |
| Porsche       |
| Toyota        |
+---------------+
```

## BigData basics

The amount of data is always quite high in such an environment. In this case
we have more than one million datasets. An analyser gets always tested with
only 10%-20% of the data. If the analyser looks right, it will be executed on
all datasets. At the end the results will be compared. The analyser is working
and the data has a good quality if the results match









## MySQL Cheat Sheet

Changing the password of a user

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '234567uiukjyhtgYUGJHK^*';
```

Generate a random datetime that is 20-45 years in the past (explanation at https://dev.mysql.com/doc/refman/5.7/en/mathematical-functions.html#function_rand)

```sql
SELECT DATE_SUB(NOW(), INTERVAL FLOOR(20 + (RAND() * 25)) YEAR);
```

Generate a random datetime that is 20-45 years in the past and where the month varies

```sql
SELECT DATE_SUB(DATE_SUB(NOW(), INTERVAL FLOOR(20 + (RAND() * 25)) YEAR), INTERVAL FLOOR(1 + (RAND() * 11)) MONTH);
```

random yyyy-mm-dd

```sql
SELECT DATE_SUB(DATE_SUB(DATE_SUB(NOW(), INTERVAL FLOOR(20 + (RAND() * 25)) YEAR), INTERVAL FLOOR(1 + (RAND() * 11)) MONTH), INTERVAL FLOOR(1 + (RAND() * 28)) DAY) AS Birthday;
```

random yyyy-mm-dd in efficient

```sql
SELECT FROM_UNIXTIME(FLOOR(
    UNIX_TIMESTAMP(NOW() - INTERVAL 45 YEAR)
    + RAND() * (
        UNIX_TIMESTAMP(NOW() - INTERVAL 20 YEAR)
        - UNIX_TIMESTAMP(NOW() - INTERVAL 45 YEAR)
    )
));
```

Create a random dataset

```sql
SELECT (SELECT DATE_SUB(DATE_SUB(DATE_SUB(NOW(), INTERVAL FLOOR(20 + (RAND() * 25)) YEAR), INTERVAL FLOOR(1 + (RAND() * 11)) MONTH), INTERVAL FLOOR(1 + (RAND() * 28)) DAY)) AS Birthday, (SELECT name FROM genders ORDER BY RAND() LIMIT 1) AS Gender, (SELECT name FROM car_manufacturers ORDER BY RAND() LIMIT 1) AS car_manufacturer, (SELECT name FROM federate_states ORDER BY RAND() LIMIT 1) AS federate_state;
```

Create a random dataset in readable form

```sql
SELECT
    (SELECT
            DATE_SUB(DATE_SUB(DATE_SUB(NOW(),
                            INTERVAL FLOOR(20 + (RAND() * 25)) YEAR),
                        INTERVAL FLOOR(1 + (RAND() * 11)) MONTH),
                    INTERVAL FLOOR(1 + (RAND() * 28)) DAY)
        ) AS Birthday,
    (SELECT
            name
        FROM
            genders
        ORDER BY RAND()
        LIMIT 1) AS Gender,
    (SELECT
            name
        FROM
            car_manufacturers
        ORDER BY RAND()
        LIMIT 1) AS car_manufacturer,
    (SELECT
            name
        FROM
            federate_states
        ORDER BY RAND()
        LIMIT 1) AS federate_state;
```

Get the correct size for innodb\_buffer\_pool\_size

```sql
SELECT CEILING(Total_InnoDB_Bytes*1.6/POWER(1024,3)) RIBPS FROM
(SELECT SUM(data_length+index_length) Total_InnoDB_Bytes
FROM information_schema.tables WHERE engine='InnoDB') A;
```
