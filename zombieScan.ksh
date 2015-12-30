# This script runs as root via cron to remotely execute SQL requests and evaluate results and send warning messages based on returned values

### BEGIN script ###
#!/usr/bin/ksh
# Filename: ZombieScan.ksh
# Created by: J. Eric Stout
# Created on: 2014APR25


targetHost="someHostname"
# defines host we want to remote to
thisHost=`(uname -n)`
# Defines for oracle to work
ORACLE_SID=<SID_NAME>
ORACLE_HOME=/orabase/app/oracle/product/9.2.0.6
export ORACLE_SID ORACLE_HOME

# Query all ${sourceHost} 'procName' processes attached to <SID_Name> DB on ${targetHost}

/orabase/app/oracle/product/9.2.0.6/bin/sqlplus -s <<_EOF_ >/root/scripts/bin3/session.log
<user>/<password>@<SID_NAME>
set echo off
set wrap off lin 200
set space 0
set tab off
set colsep ','
select s.sid, s.serial#, s.username,s.osuser,p.spid "OS PID",s.program from
v\$session s,v\$process p where s.paddr = p.addr AND s.program LIKE '<procName>@<hostname>%' order by to_number(p.spid);
exit
_EOF_

for line in `(sed -e 's/  //g' /path/to/logs/session.log | sed -e 's/ ,/,/g' | nawk -F"," -v OFS=";" '$0 !~ /^--|^$/ {print $1,$2,$3,$4,$5,$6}' | tr -d ' ' | tail +2)`
do
oldIFS=$IFS
IFS=";"
set -- $line
   SID=$1
SERIAL=$2
 OUSER=$3
 UUSER=$4
  UPID=$5
#  PROG=$6
## // bits below were just for testing.
  PROG=`echo $6 | sed -e 's/_/ /g'`
## StatLine=`(printf "${SID} ${SERIAL} ${OUSER} ${UUSER} ${UPID} ${PROG}\n")`

set -A procStat `(ssh -o BatchMode=yes -n -o connectTimeout=5 ${targetHost} "/usr/local/bin/lsof -p ${UPID} | /usr/bin/nawk '\\$8 ~ /^TCP\$/ {print \\$9,\\$10}' | xargs | sed -e 's/ /;/g' -e 's/\*/\\*/g' ")`
# // Lots of escapements here for remote-execution via SSH.

#printf "${#procStat[*]}\n" ; # display number of array objects.
#printf "${PROG} ${procStat[1]} ${procStat[3]}\n" ; # display only the connection status fields
# example:
# 0   1      2                              3            <- procStat array field numbers
# *:* (IDLE) [targetHost]:1528->[sourceHost]:60080 (ESTABLISHED)

showProc(){
printf "<tr class="cen"><td>${SID}</td><td>${SERIAL}</td><td>${OUSER}</td><td>${UUSER}</td><td>${UPID}</td><td>${PROG}</td></tr>\n"
}

if [ "${procStat[3]}" = "(IDLE)" ]
 then

# Mailer function
mailDrop="name1@domain.com,name2@domain.com"
/usr/lib/sendmail ${mailDrop} <<_EOM_
MIME-Version: 1.0
From: root@${thisHost}
To: ${mailDrop}
Subject: Zombie Alert on ${thisHost} for `/usr/bin/date`
Content-Type: text/html; charset='ISO-8859-1';
<html>
<head>
<style type="text/css">
body {font-family:Arial, Helvetica;font-size:12px;}
.cenb {text-align:center; font-weight:bold; background-color:#EEEEEE;}
.cen {text-align:center;}
table.table1 {border-width:1px;border-style:solid;border-color:#000000;display:block;width:600px;}
td {border-width:0px;border-style:solid;border-color:#000000;padding:2px;margin:1px;}
</style>
</head>
<body>
<b>${thisHost}</b> has spotted a zombie on ${targetHost}!<br/>
<br/>
<br/>
<table class="table1" border="0" cellpadding="0" cellspacing="0">
<tr class="cenb"><td>SID</td><td>Serial #</td><td>DB User</td><td>Unix User</td><td>Unix PID</td><td>Program</td></tr>
`showProc`
</table>
<p/>
Thank you,<br/>
*IT C&CC Unix STL
<br/>
`/usr/bin/date`.<br/>
<br/>
</body>
</html>
_EOM_

fi

##if [ "${procStat[1]}" = "(IDLE)" ]
## then
#### Old stuff for testing locally
####   printf "Zombie spotted on ${targetHost}!\nUnix Process ID:  ${UPID}\n"
####   printf "%-5s | %-10s | %-8s | %-12s | %-8s | %-s\n" 'SID' 'Serial #' 'DB User' 'Unix User' 'Unix PID' 'Program'
####   nawk 'BEGIN{for(c=0;c<80;c++) printf "-"; printf "\n"}'
####   printf "%-8s  %8s  %-10s  %-13s  %8s  %s\n\n" ${SID} ${SERIAL} ${OUSER} ${UUSER} ${UPID} ${PROG}
##fi
##done

  IFS=$oldIFS
 done

#EOF

###########################################
###########################################
###########################################
