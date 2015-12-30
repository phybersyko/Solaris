#!/bin/ksh
#   Filename: parseKH.ksh
# Created by: J. Eric Stout
# Created on: 2015NOV18
#    Purpose: Parse ~/.ssh/known_hosts file for entries:
#
#  Tested on: RHEL
# BEGIN Script

awk '{print $1}' ./root_known_hosts | cut -d, -f1 | while read thisEntry ; do
if [ -z "$(echo ${thisEntry} | awk '$1 ~ /^[0-9]/')" ]
  then
    echo "${thisEntry}" | cut -d. -f1
  else
    nslookup ${thisEntry} 2>/dev/null | awk '$2 ~ /^name/ {print $NF}' | cut -d. -f1
        if [ "$?" -ne "0" ] ; then
          echo "*** Unable to find: ${thisEntry} ***"
        fi
  fi
done

# EOF
