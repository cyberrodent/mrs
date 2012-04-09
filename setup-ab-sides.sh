#!/bin/bash

# Where our setup scripts and templates are
INSTALL="/home/jkolber/Project/mysql_repl"
# Where do our mysqls get set up in
BASEDIR=/opt/mysqlrplay
# escape slashed of the BASEDIR
ESCAPEBASEDIR="\/opt\/mysqlrplay"
# replication user name
REPLUSER="ripley"
# replication user password
REPLPASS="r3p1icate"
# Where is the mysqld binary
DBBIN=/usr/sbin/mysqld

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
RUN_DIR=$BASEDIR/run

mkdir -p $CONF_DIR $DATA_DIR $LOG_BASE \
        $SOCK_BASE $BIN_BASE $TMP_BASE \
        $RUN_DIR
chown mysql:mysql $CONF_DIR $DATA_DIR $LOG_BASE \
        $SOCK_BASE $TMP_BASE $RUN_DIR \
        $BIN_BASE 
chmod 0755 $BIN_BASE $RUN_DIR $LOG_BASE

# This is the function that does all the work
function SetupReplicant {

    X=$1
    DBPORT=$2
    MASTERPORT=$3
    INCREMENT=$4
    OFFSET=$5

    DBSERVER="mysql-$1"
    DBCONF=$CONF_DIR/my-$1.cnf
    STARTUP=$BIN_BASE/start-$X.sh
    SHUTDOWN=$BIN_BASE/stop-$X.sh
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

    # Create the startup and shutdown scripts
    cp $START_TPL $TMP_INIT
    perl -pi -e 's/%BASE%/'${ESCAPEBASEDIR}'/g' $TMP_INIT
    perl -pi -e 's/%X%/'${X}'/g' $TMP_INIT
    cp $TMP_INIT $STARTUP 
    rm $TMP_INIT

    cp $STOP_TPL $TMP_INIT
    perl -pi -e 's/%X%/'${X}'/g' $TMP_INIT
    # perl -pi -e 's/%%/'${AA}'/g' $TMP_INIT
    cp $TMP_INIT $SHUTDOWN
    rm $TMP_INIT

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
    sleep 3

    echo "Ping? Are you awake?"
    DBPING=`mysqladmin -P $DBPORT -h 127.0.0.1 -u root ping 2>/dev/null`
    if [ "$DBPING" = "mysqld is alive" ];
        then echo "IT IS ALIVE!";
        else echo "Hmm. Mysqld ping response was this: $DBPING";
    fi
    

    echo "Creating Replication User"

    #  grant replication slave on *.* to '$REPLUSER'@127.0.0.1 identified by '$REPLPASS'
    $MYSQLCMD "grant replication slave on *.* to '$REPLUSER'@'127.0.0.1' identified by '$REPLPASS'"
    $MYSQLCMD "FLUSH PRIVILEGES"
    # $MYSQLADM status 
    # echo
    
    echo "Shutting down mysqld."
    $MYSQLADM shutdown
    sleep 3
    
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

echo "Create the A side"
SetupReplicant "a" 3310 3311 2 1; 
echo
echo "and then the B side"
SetupReplicant "b" 3311 3310 2 2; 
echo "MM config complete."


