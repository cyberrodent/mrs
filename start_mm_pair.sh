#!/bin/sh

AHOST="127.0.0.1"
BHOST="127.0.0.1"

APORT=3310
BPORT=3311

# mysqld --defaults-file=/opt/mysqlrplay/etc/mysql/my-a-side.cnf &
# mysqld --defaults-file=/opt/mysqlrplay/etc/mysql/my-b-side.cnf &


/usr/bin/mysql -u root -h $AHOST -P $APORT -e "SHOW MASTER STATUS" 
/usr/bin/mysql -u root -h $BHOST -P $BPORT -e "SHOW MASTER STATUS" 

/usr/bin/mysqladmin -u root -h $AHOST -P $APORT start slave
/usr/bin/mysqladmin -u root -h $BHOST -P $BPORT start slave 

/usr/bin/mysql -u root -h $AHOST -P $APORT -e "SHOW SLAVE STATUS" 
/usr/bin/mysql -u root -h $BHOST -P $BPORT -e "SHOW SLAVE STATUS" 

