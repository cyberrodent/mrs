#!/bin/sh

AHOST="127.0.0.1"
BHOST="127.0.0.1"

APORT=3310
BPORT=3311

# mysqld --defaults-file=/opt/mysqlrplay/etc/mysql/my-a-side.cnf &
# mysqld --defaults-file=/opt/mysqlrplay/etc/mysql/my-b-side.cnf &

mysql -u root -h $AHOST -P $APORT -e "CHANGE MASTER TO MASTER_HOST='${BHOST}', MASTER_USER='ripley', MASTER_PASSWORD='r3p1icate', MASTER_PORT=${BPORT}"

mysql -u root -h $BHOST -P $BPORT -e "CHANGE MASTER TO MASTER_HOST='${AHOST}', MASTER_USER='ripley', MASTER_PASSWORD='r3p1icate', MASTER_PORT=${APORT}"

mysql -u root -h $AHOST -P $APORT -e "SHOW MASTER STATUS" 
mysql -u root -h $BHOST -P $BPORT -e "SHOW MASTER STATUS" 

mysqladmin -u root -h $AHOST -P $APORT start slave
mysqladmin -u root -h $BHOST -P $BPORT start slave 

mysql -u root -h $AHOST -P $APORT -e "SHOW SLAVE STATUS" 
mysql -u root -h $BHOST -P $BPORT -e "SHOW SLAVE STATUS" 

