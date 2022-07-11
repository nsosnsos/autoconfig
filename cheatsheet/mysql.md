#MYSQL INFO
```shell
mysql --version
mysql -u root -p
mysql> SHOW DATABASES;
mysql> SELECT user, host FROM mysql.user;
```

#CHANGE ROOT PASSWORD
```shell
sudo mysql -uhallelujah -p'hallelujah' -e "UPDATE mysql.user SET Password = PASSWORD('password') WHERE User = 'root'"
```

#CREATE USER
```sql
CREATE USER 'user_name'@'localhost' IDENTIFIED BY 'user_password';
```
#ALTER USER
```sql
ALTER USER 'user_name'@'localhost' IDENTIFIED BY 'new_user_password';
```
#DROP USER
```sql
DROP USER 'user_name'@'localhost' IDENTIFIED BY 'user_password';
```

#CREATE DATABASE
```sql
CREATE DATABASE IF NOT EXISTS hallelujah DEFAULT CHARSET utf8 COLLATE utf8_bin;
```
#PRIVILEGES
```sql
GRANT ALL PRIVILEGES ON database_name.* TO 'user_name'@'localhost';
REVOKE SELECT, INSERT, DELETE ON database_name.* TO 'user_name'@'localhost';
SHOW GRANTS FOR 'user_name'@'localhost';
```
