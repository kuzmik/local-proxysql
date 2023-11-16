# Testing the cluster

## TL;DR LET ME TESSTTTTTTTT

Just run [`./bin/tests.sh`](./bin/tests.sh) for a real simple, simple, almost too simple, "test suite."

## Connect to a Database Through ProxySQL

```bash
# us1
$ > mysql -h$(kubectl get service proxysql-cluster -n proxysql --output jsonpath='{.spec.clusterIP}') -P6033 -upersona-web-us1 -ppersona-web-us1 -e 'select @@hostname'
+---------------------+
| @@hostname          |
+---------------------+
| mysql-us1-primary-0 |
+---------------------+

$ > mysql -h$(kubectl get service proxysql-cluster -n proxysql --output jsonpath='{.spec.clusterIP}') -P6033 -upersona-web-us1 -ppersona-web-us1 persona-web-us1 -e 'select * from users'
+----+----------------------+------------+-------------+-----------+-------------------------------------+
| id | email                | first_name | middle_name | last_name | password                            |
+----+----------------------+------------+-------------+-----------+-------------------------------------+
|  1 | rick@persona-us1.com | Rick       | US1         | Song      | this-should-be-hashed-but-who-cares |
|  2 | nick@persona-us1.com | Nick       | US1         | Kuzmik    | this-should-be-hashed-but-who-cares |
+----+----------------------+------------+-------------+-----------+-------------------------------------+

# us2
$ > mysql -h$(kubectl get service proxysql-cluster -n proxysql --output jsonpath='{.spec.clusterIP}') -P6033 -upersona-web-us2 -ppersona-web-us2 -e 'select @@hostname'
+---------------------+
| @@hostname          |
+---------------------+
| mysql-us2-primary-0 |
+---------------------+

$ > mysql -h$(kubectl get service proxysql-cluster -n proxysql --output jsonpath='{.spec.clusterIP}') -P6033 -upersona-web-us2 -ppersona-web-us2 persona-web-us2 -e 'select * from users'
+----+-------------------------+------------+-------------+-----------+-------------------------------------+
| id | email                   | first_name | middle_name | last_name | password                            |
+----+-------------------------+------------+-------------+-----------+-------------------------------------+
|  1 | charles@persona-us2.com | Charles    | US2         | Yeh       | this-should-be-hashed-but-who-cares |
|  2 | ian@persona-us2.com     | Ian        | US2         | Chesal    | this-should-be-hashed-but-who-cares |
+----+-------------------------+------------+-------------+-----------+-------------------------------------+
```
