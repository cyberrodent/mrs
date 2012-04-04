#!/bin/sh

#  start
mysqld --defaults-file=/etc/mysql/my-a-side.cnf &

#stop
# mysqladmin -u root -h 127.0.0.1  -P 3310 shutdown
