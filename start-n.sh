#!/bin/sh

#  start
%DBBIN% --defaults-file=%BASE%/etc/my-%X%-side.cnf --user=%MYUSER% &
