#!/bin/sh

#  start
mysqld --defaults-file=%BASE%/etc/my-%X%-side.cnf &
