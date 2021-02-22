#MYSQL INFO
```shell
mysql --version
mysql -u root -p
mysql> SHOW DATABASES;
mysql> SELECT user, host FROM mysql.user;
```

#CREATE USER
```shell
mysql> CREATE USER 'user_name'@'localhost' IDENTIFIED BY 'user_password';
```
#ALTER USER
```shell
mysql> ALTER USER 'user_name'@'localhost' IDENTIFIED BY 'new_user_password';
```
#DROP USER
```shell
mysql> DROP USER 'user_name'@'localhost' IDENTIFIED BY 'user_password';
```
#PRIVILEGES
```shell
mysql> GRANT ALL PRIVILEGES ON database_name.* TO 'user_name'@'localhost';
mysql> REVOKE SELECT, INSERT, DELETE ON database_name.* TO 'user_name'@'localhost';
mysql> SHOW GRANTS FOR 'user_name'@'localhost';
```
