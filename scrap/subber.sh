#!/bin/bash

TEMPLATE="/etc/mysql/my-x-side.cnf"
OUT="/etc/mysql/my-rendered.cnf"
X="-a-"


sed -e 's/#X#/'${X}'/g' < $TEMPLATE > $OUT



