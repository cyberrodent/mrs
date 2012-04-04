#!/bin/sh

#  start
# mysqld --defaults-file=/etc/mysql/my-b-side.cnf &

#stop
mysqladmin -u root -h 127.0.0.1 -P 3311 shutdown
