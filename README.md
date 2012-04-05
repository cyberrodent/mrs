MySql Replication Setup Scripts MRSS
====================================
The purpose of this project is to create a set of shell scripts that can aid in quickly setting up a master-master pair of mysql servers
on the same machine to aid in development and test environment setups.

Sooner or later this may be converted to a chef recipe.  

Overview
--------
The idea is to run 2 (or more) instances of MySql on one machine. The servers will share resources like CPU and RAM and IO. We will do this by having sets of configuration that utelize different TCP ports, unix sockets, data directories users, log files etc. 

If you use apparmour then make sure to update the mysqld profile. This is appropriate for the default settings:
  /opt/mysqlrplay/** rwk

setup-ab-sides.sh
-----------------
This script will create a mysql server config file (my-x.cnf for any x)

It will then
 1. create a data directory and 
 2. run mysql_install_db that that directory as a datadir.  
 3. Then it will start up that mysql server and 
 4. create a replication user with the appropriate grants. 
 5. Optionally it can set the root user password as well.

Default is to setup each mysql under /opt/mysqlrplay with a simple layout: folders for
each of
 bin etc data log socket tmp

Start and stop scripts
-----------------------
Each configuration will require its own start and stop scripts to make it easy to start and stop that service. These will be called
start-a.sh, stop-a.sh, start-b.sh etc.

start_mm_pair.sh
--
Assumes 2 running mysql services (a and b) connect to both, show the master status, start the slaves and show the slave status.







