# DBA - BigData Analyser in SQL

## Table of contents

* [Setup](#setup)
* [Datasets](#datasets)
* [Situation](#situation)
* [MySQL Cheat Sheet](#mysql-cheat-sheet)
* [References](#references)
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

Now you can import the SQL files:

```
cat *.sql | mysql --user root -p
```

## Datasets

We have one tables, called datasets, which holds all of our data. Since this is
is a big data application, we get the data not in the third normal form, that
would not scale. Instead we have datasets, a single dataset is a collection of
key-value information, represented as a JSON object. An example is:

```json
{"Gender": "Female", "Birthday": "1995-03-17 11:49:30.000000", "federate_state": "Bayern", "car_manufacturer": "Porsche", "Relationship": "Single"}
```

Each dataset contains the same attributes. They are:

* Gender (Male or Female)
* Birthday (all people are 20 to 45 years old)
* Federate state (one of our 16 federate states)
* Car manufacturer (Full list of values is stored in the table)
* Relationship (Single, Married)

```
$ mysql --database bigdata --execute "SELECT name FROM car\_manufacturers"
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

There is often some metadata attached to a dataset. For example:

* id (uniq id for the dataset)
* created\_at (timestamp when the dataset was created)
* updated\_at (timestamp wehn the data was updated the last time, defaults to created\_at)

### BigData basics

The amount of data is always quite high in such an environment. In this case
we have more than one million datasets. An analyser gets always tested with
only 10%-20% of the data. If the analyser looks right, it will be executed on
all datasets. At the end the results will be compared. The analyser is working
and the data has a good quality if the results match. Often the datasets
contain more information than needed.

## Situation

Our company has many million customers. For a new business case we need to
determine the yearly income of our customers. We want to launch a regional
product (limited to a federate state) for people with a low income. We bought
some data from car manufacturers and we now know the prices for their cars and
the state of the relationship frmo the buyer. Each of our customers with a
Porsche or Aston Martin has an income that is too high for our product, we need
to filter those people out. People that are single and drive an Audi tend to
drive one of the more expensive modells, so we need to filter them out. It is
the opposite on Mercedes-Benz.

We want to launch our product 3 times (in three federal states). We want to
know which four federate states contain the most potential customers in
absolute numbers on the one side, and on the other side the four states
with the most potential customers in it in relation the the amount of current
customers in it.

### Implementation

We will start with 100.000 datasets. First of we will filter all the really
expensive cars out. Each step will be saved in a temporary table. Those tables
only contain the result set from the previous query and are stored in memory.
They are automatically deleted after our session terminates. We don't need to
care of garbadge collection. To keep the memory footprint low it is still a
good idea to drop temporary tables when we know we do not need them again.

```sql
CREATE TEMPORARY TABLE filtered AS SELECT dataset FROM datasets LIMIT 100000;
CREATE TEMPORARY TABLE filtered_expensive_cars AS SELECT dataset FROM filtered WHERE dataset->'$.car_manufacturer' != 'Aston Martin';
CREATE TEMPORARY TABLE filtered_more_expensive_cars AS SELECT dataset from filtered_expensive_cars WHERE dataset->'$.car_manufacturer' != 'Porsche';
DROP TABLE filtered_expensive_cars;
CREATE TEMPORARY TABLE filtered_even_more_expensive_cars AS SELECT dataset FROM filtered_more_expensive_cars WHERE NOT (dataset->'$.relationship' = 'Single' and dataset->'$.car_manufacturer' = 'Audi');
DROP TABLE filtered_more_expensive_cars;
CREATE TEMPORARY TABLE final_cars_filtered AS SELECT dataset FROM filtered_even_more_expensive_cars WHERE NOT (dataset->'$.relationship' = 'Married' and dataset->'$.car_manufacturer' = 'Mercedes-Benz');
DROP TABLE filtered_even_more_expensive_cars;
SELECT COUNT(dataset) as customer, dataset->'$.federate_state' as federate_state FROM final_cars_filtered GROUP BY dataset->'$.federate_state' ORDER BY customer DESC LIMIT 4;
SELECT COUNT(dataset) as customer, dataset->'$.federate_state' as federate_state FROM filtered GROUP BY dataset->'$.federate_state' ORDER BY customer DESC;
CREATE TEMPORARY TABLE potential_customers_by_federate_state AS SELECT COUNT(dataset) as customer, dataset->'$.federate_state' as federate_state FROM final_cars_filtered GROUP BY dataset->'$.federate_state' ORDER BY customer DESC;
CREATE TEMPORARY TABLE all_customers_by_federate_state SELECT COUNT(dataset) as customer, dataset->'$.federate_state' as federate_state FROM filtered GROUP BY dataset->'$.federate_state' ORDER BY customer DESC;
SELECT potential_customers, all_customers, federate_state, 100 / all_customers * potential_customers as potential_customer_in_percent FROM (SELECT potential_customers_by_federate_state.federate_state, potential_customers_by_federate_state.customer as potential_customers, all_customers_by_federate_state.customer as all_customers FROM potential_customers_by_federate_state INNER JOIN all_customers_by_federate_state ON all_customers_by_federate_state.federate_state = potential_customers_by_federate_state.federate_state) AS derieved_table ORDER BY potential_customers DESC;
```




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

Show temporary tables

```sql
SELECT * FROM INFORMATION_SCHEMA.TEMPORARY_TABLES;
```

## References

* [MySQL and Unicode](https://mathiasbynens.be/notes/mysql-utf8mb4)
