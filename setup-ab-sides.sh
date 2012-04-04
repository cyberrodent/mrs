#!/bin/bash

DBCONF=/etc/mysql/my-a-side.cnf
TEMPLATE="/etc/mysql/my-x-side.cnf"
DBSERVER="mysql-a"
DBPORT=3310

REPLUSER="ripley"
REPLPASS="replicate"

DBBIN=/usr/sbin/mysqld

function SetupReplicant {

    X=$1
    DBSERVER="mysql=$1"
    DBPORT=$2
    DBCONF=/etc/mysql/my-$1-rendered.cnf
    DBHOST="127.0.0.1"

    OUT="/etc/mysql/my-$3-rendered.cnf"

    MYSQLCMD="/usr/bin/mysql -u root -h $DBHOST -P $DBPORT -e"
    MYSQLADM="/usr/bin/mysqladmin -u root -h $DBHOST -P $DBPORT"

    echo
    echo "Starting setup for $DBSERVER"
    echo

    # Create the configuratio file for this mysql
    sed -e 's/#X#/'${X}'/g' \
        -e 's/#PORT#/'${DBPORT}'/g' \
        < $TEMPLATE > $DBCONF


    # Create data directory
    DATADIR=/var/lib/$DBSERVER
    rm -rf $DATADIR
    mkdir -p /var/lib/$DATADIR
    chown mysql:mysql /var/lib/$DATADIR
    chmod 0700 /var/lib/$DATADIR
    # Install database
    echo "Running mysql_install_db."
    mysql_install_db --user=mysql --datadir=$DATADIR 1>/dev/null
    
    # start the server
    echo "Starting the server."
    exec $DBBIN --defaults-file=$DBCONF &
    # Create users and set root password
    echo "Waiting for mysql to start."
    sleep 4
    echo "Ping? Are you awake?"
    DBPING=`mysqladmin -P $DBPORT -h 127.0.0.1 -u root ping 2>/dev/null`
    
    if [ "$DBPING" =  "mysqld is alive" ];
        then echo "IT IS ALIVE!";
        else echo "Hmm. Mysqld ping response was this: $DBPING";
    fi
    
    echo "grant replication slave on *.* to '$REPLUSER'@127.0.0.1 identified by '$REPLPASS'"
    $MYSQLCMD "grant replication slave on *.* to '$REPLUSER'@'127.0.0.1' identified by '$REPLPASS'"
    $MYSQLCMD "FLUSH PRIVILEGES"


    
    
    $MYSQLADM status 
    echo
    
    echo "Shutting down mysqld."
    $MYSQLADM shutdown
    sleep 4
    
    PING=`$MYSQLADM ping 2>/dev/null`
    if [ "$PING" = "mysqld is alive" ]; then
        echo "...still going";
    else
        echo "mysqld is dead. long live mysqld."
    fi
    
    echo 
    echo "Finished."
    echo
}


SetupReplicant "a" 3310 ; 
SetupReplicant "b" 3311 ; 


