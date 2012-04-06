#!/bin/bash

TEMPLATE="`pwd`/my-x-side.cnf"
echo "loaded template $TEMPLATE"

BASEDIR=/opt/mysqlrplay
ESCAPEBASEDIR="\/opt\/mysqlrplay"
REPLUSER="ripley"
REPLPASS="r3p1icate"
#
# Where is the mysqld binary
DBBIN=/usr/sbin/mysqld

#
# App layout
#

# BIN_BASE is where the startup scripts will be installed.
#  so you end up with
# $BASEDIR/bin/start-a.sh
# $BASEDIR/bin/start-b.sh
BIN_BASE=$BASEDIR/bin 

# CONF_DIR is where the configuration files will be installed
# $BASEDIR/etc/my-a.cnf
# $BASEDIR/etc/my-b.cnf
CONF_DIR=$BASEDIR/etc

# DATA_BASE us where the data for all databases go
#  so you end up with
# $BASEDIR/data/mysql-a/
# $BASEDIR/data/mysql-b/
DATA_DIR=$BASEDIR/data

# LOG_BASE base dir for logs from all configuration
#  so you end up with
# $BASEDIR/log/my-a.log
# $BASEDIR/log/my-a-slow.log
LOG_BASE=$BASEDIR/log

# SOCK_BASE is where sockets will be stores
#  something like
# $BASEDIR/socket/my-a.sock
# $BASEDIR/socket/my-b.sock
SOCK_BASE=$BASEDIR/socket

# each mysql sometimes needs some tmp. subdirs like:
# $BASEDIR/tmp/my-a/
# $BASEDIR/tmp/my-b/
TMP_BASE=$BASEDIR/tmp
# pid files go in here
RUN_DIR=$BASEDIR/run

mkdir -p $CONF_DIR $DATA_DIR $LOG_BASE \
        $SOCK_BASE $BIN_BASE $TMP_BASE \
        $RUN_DIR
chown mysql:mysql $CONF_DIR $DATA_DIR $LOG_BASE \
        $SOCK_BASE $TMP_BASE $RUN_DIR


function SetupReplicant {

    X=$1
    DBPORT=$2
    MASTERPORT=$3
    INCREMENT=$4
    OFFSET=$5

    DBSERVER="mysql-$1"
    DBCONF=$CONF_DIR/my-$1.cnf
    DBHOST="127.0.0.1"
    MASTERHOST="127.0.0.1"
    MASTERUSER=$REPLUSER
    MASTERPASS=$REPLPASS

    MYSQLCMD="/usr/bin/mysql -u root -h $DBHOST -P $DBPORT -e"
    MYSQLADM="/usr/bin/mysqladmin -u root -h $DBHOST -P $DBPORT"

    TMPCONF=$BASEDIR/_tmp_conf

    echo
    echo "Starting setup for $DBSERVER"
    echo
    echo "Creating config $DBCONF:"

    # Create the configuration file for this mysql
    cp $TEMPLATE $TMPCONF
    perl -pi -e 's/%X%/'${X}'/g'  $TMPCONF;
    perl -pi -e 's/%PORT%/'${DBPORT}'/g'  $TMPCONF;
    perl -pi -e 's/%BASE%/'${ESCAPEBASEDIR}'/g'  $TMPCONF;
    perl -pi -e 's/%MASTERHOST%/'${MASTERHOST}'/g'  $TMPCONF;
    perl -pi -e 's/%MASTERUSER%/'${MASTERUSER}'/g' $TMPCONF;
    perl -pi -e 's/%MASTERPASS%/'${MASTERPASS}'/g' $TMPCONF;
    perl -pi -e 's/%MASTERPORT%/'${MASTERPORT}'/g' $TMPCONF;
    perl -pi -e 's/%AIINC%/'${INCREMENT}'/g' $TMPCONF;
    perl -pi -e 's/%AIOFFS%/'${OFFSET}'/g' $TMPCONF;
    cp $TMPCONF $DBCONF
    rm $TMPCONF

    echo "Creating Server Directories"

    TMPDIR=$TMP_BASE/$DBSERVER
    rm -rf $TMPDIR
    mkdir -p $TMPDIR

    RUNDIR=$RUN_DIR/$DBSERVER
    rm -rf $RUNDIR
    mkdir -p $RUNDIR

    # data directory
    DATADIR=$DATA_DIR/$DBSERVER
    rm -rf $DATADIR
    mkdir -p $DATADIR
    # chmod 0700 $DATADIR

    chown mysql:mysql $DBCONF $TMPDIR $RUNDIR $DATADIR


    # Install database
    echo "Running mysql_install_db."
    mysql_install_db --defaults-file=$DBCONF --user=mysql --datadir=$DATADIR 1>/dev/null

    # start the server
    echo "Starting the server."
    $DBBIN --defaults-file=$DBCONF &

    echo "Waiting for mysql to start."
    sleep 4

    echo "Ping? Are you awake?"
    DBPING=`mysqladmin -P $DBPORT -h 127.0.0.1 -u root ping 2>/dev/null`
    if [ "$DBPING" = "mysqld is alive" ];
        then echo "IT IS ALIVE!";
        else echo "Hmm. Mysqld ping response was this: $DBPING";
    fi
    

    echo
    echo "Creating Replication User"
    echo 

   

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
    echo "Finished with $DBSERVER."
    echo
}


SetupReplicant "a" 3310 3311 2 1; 
SetupReplicant "b" 3311 3310 2 2; 


