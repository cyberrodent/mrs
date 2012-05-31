#!/bin/bash

# Where our setup scripts and templates are
INSTALL="/Users/jkolber/development/mrs"
# Where do our mysqls get set up in
BASEDIR=/opt/mysqlrplay
# escape slashed of the BASEDIR
ESCAPEBASEDIR="\/opt\/mysqlrplay"
# replication user name
REPLUSER="ripley"
# replication user password
REPLPASS="r3p1icate"
# Where is the mysqld binary
# DBBIN=/usr/sbin/mysqld
DBBIN=/usr/local/mysql/bin/mysqld
MYBIN=/usr/local/mysql/bin/mysql
DBADMINBIN=/usr/local/mysql/bin/mysqladmin
INSTALLDBBIN=/usr/local/mysql-5.5.19-osx10.5-x86_64/scripts/mysql_install_db;
MYUSER="_mysql"
MYGROUP="_mysql"
# How many seconds to wait for mysql to start/stop
SLEEP_DELAY=3
#
# Nothing to change past here unless you
# Are really customizing this script
#


# The main my.cnf template
TEMPLATE="$INSTALL/my-x-side.cnf"
# startup script template
START_TPL="$INSTALL/start-n.sh"
# shutdown script template
STOP_TPL="$INSTALL/stop-n.sh"
# tmp file name used when making startup/shutdown scripts
TMP_INIT="$INSTALL/_tmp_init"

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
RUN_BASE=$BASEDIR/run

mkdir -p $BASEDIR $CONF_DIR $DATA_DIR $LOG_BASE \
        $SOCK_BASE $BIN_BASE $TMP_BASE \
        $RUN_BASE
chown $MYUSER:$MYGROUP $CONF_DIR $DATA_DIR $LOG_BASE \
        $SOCK_BASE $TMP_BASE $RUN_BASE \
        $BIN_BASE 
chmod 0755 $BIN_BASE $RUN_BASE $LOG_BASE

# This is the function that does all the work
function SetupReplicant {

    X=$1
    DBPORT=$2
    MASTERPORT=$3
    INCREMENT=$4
    OFFSET=$5

    DBSERVER="mysql-$1"
    DBCONF=$CONF_DIR/my-$1-side.cnf
    STARTUP=$BIN_BASE/start-$X.sh
    SHUTDOWN=$BIN_BASE/stop-$X.sh
    DBHOST="127.0.0.1"
    MASTERHOST="127.0.0.1"
    MASTERUSER=$REPLUSER
    MASTERPASS=$REPLPASS

    MYSQLCMD="${MYBIN} -u root -h $DBHOST -P $DBPORT -e"
    MYSQLADM="${DBADMINBIN} -u root -h $DBHOST -P $DBPORT"

    TMPCONF=$BASEDIR/_tmp_conf

    echo "Starting setup for $DBSERVER"
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

    # Create the startup and shutdown scripts
    cp $START_TPL $TMP_INIT
    perl -pi -e 's/%BASE%/'${ESCAPEBASEDIR}'/g' $TMP_INIT
    perl -pi -e 's/%X%/'${X}'/g' $TMP_INIT
    perl -pi -e 's/%MYUSER%/'${MYUSER}'/g' $TMP_INIT
    # slashes in this path so use alternative pattern delimiter {} 
    perl -pi -e 's{%DBBIN%}{'${DBBIN}'}g' $TMP_INIT
    cp $TMP_INIT $STARTUP 
    rm $TMP_INIT

    cp $STOP_TPL $TMP_INIT
    perl -pi -e 's/%X%/'${X}'/g' $TMP_INIT
    perl -pi -e 's/%PORT%/'${DBPORT}'/g'  $TMP_INIT;
    # perl -pi -e 's/%%/'${AA}'/g' $TMP_INIT
    cp $TMP_INIT $SHUTDOWN
    rm $TMP_INIT

    echo "Creating Server Directories"

    TMPDIR=$TMP_BASE/$DBSERVER
    rm -rf $TMPDIR
    mkdir -p $TMPDIR 

    # data directory
    DATADIR=$DATA_DIR/$DBSERVER
    rm -rf $DATADIR
    mkdir -p $DATADIR

    chown ${MYUSER}:${MYGROUP} $DBCONF $TMPDIR $DATADIR

    # Install database
    echo "Running mysql_install_db."

    ${INSTALLDBBIN} --defaults-file=$DBCONF --basedir=/usr/local/mysql --user=$MYUSER --datadir=$DATADIR 1>/dev/null




    # start the server
    echo "Starting the server."
    $DBBIN --defaults-file=$DBCONF --user=$MYUSER &

    echo "Waiting for mysql to start."
    sleep $SLEEP_DELAY

    echo "Ping? Are you awake?"
    DBPING=`${DBADMINBIN} -P $DBPORT -h 127.0.0.1 -u root ping 2>/dev/null`
    if [ "$DBPING" = "mysqld is alive" ];
        then echo "IT IS ALIVE!";
        else echo "Hmm. Mysqld ping response was this: $DBPING";
    fi
    

    echo "Creating Replication User"

    #  grant replication slave on *.* to '$REPLUSER'@127.0.0.1 identified by '$REPLPASS'
    echo "$MYSQLCMD \"GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* to '$REPLUSER'@'127.0.0.1' identified by '$REPLPASS'\""
    $MYSQLCMD "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* to '$REPLUSER'@'127.0.0.1' identified by '$REPLPASS'"
    $MYSQLCMD "FLUSH PRIVILEGES"
    # $MYSQLADM status 
    # echo
    
    echo "Shutting down mysqld."
    $MYSQLADM shutdown
    sleep $SLEEP_DELAY
    
    PING=`$MYSQLADM ping 2>/dev/null`
    if [ "$PING" = "mysqld is alive" ]; then
        echo "...still going";
    else
        echo "mysqld is dead. long live mysqld."
    fi
    
    echo "Finished with $DBSERVER."
    echo
}

SetupReplicant "a" 3310 3311 2 1; 
SetupReplicant "b" 3311 3310 2 2; 

echo "MM config complete."
exit 0
