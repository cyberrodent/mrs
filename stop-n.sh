#!/bin/sh

#stop
mysqladmin -u root -h 127.0.0.1 -P %PORT% shutdown
