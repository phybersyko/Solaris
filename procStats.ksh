
#!/usr/bin/ksh
# Filename: procStats.ksh
# Created By: J. Eric Stout
# Created On: 2014JAN14
# Purpose: run cprocs_status script, send mail alert for down processes.

checkStatus(){
/program_path/cprocs_status.sh | sed -e s'/\[BAD!\]/\[\<span class=\"r\"\>BAD!\<\/span\>\]/g' -e s'/\[GOOD\]/\[\<span class=\"g\"\>GOOD\<\/span\>\]/g' -e 's/$/\<br\/\>/g'
}

zfsStat() {
set -A fsList `zfs list | sort -r -k 1.1b | awk '$NF ~ /\// {print $NF}'`
fsstat zfs ${fsList[*]} 2 5
#fsstat zfs; nawk 'BEGIN{for(c=0;c<80;c++) printf "-"; printf "\n"}' ; for fs in `(zfs list | awk '$NF ~ /\// {print $NF}' | sort )`
# do
# fsstat ${fs} | tail -1
# done
}
sendAlert(){
mailDrop="name1@domain.com,name2@domain.com"
#mailDrop="name1@amdocs.com"
/usr/lib/sendmail ${mailDrop} <<_EOM_
From: root@`uname -n`
To: ${mailDrop}
Subject: `uname -n` Service(s) are down
Content-Type: text/html; charset='ISO-8859-1';
<html>
  <head>
    <style type="text/css">
      body {font-family:Arial, Helvetica;font-size:12px;}
      div.TERM {color:#FFFFFF;
                display:block;width:50em;
                padding:10px;font-size:11px;
                font-family:Courier New;
                white-space:pre-wrap;}
        span.g {color:#00FF00;font-weight:bold;}
        span.r {color:#FF0000;font-weight:bold;}
table.one {width:50em;border:0px solid black;background-color:#000000;}
td.two {background-color:#000000;padding:4px;}
hr.three {width:50em;height:1px;color:#000000;text-align:left;}
    </style>
  </head>
<body>
Please check host `uname -n`. AppName Application(s) appear to be offline:
<br/><br/>
<table class="one">
  <tr><td class="two"><div class="TERM">`checkStatus`</div></td></tr>
  <tr><td class="two"><div class="TERM"><pre>`zfsStat`</pre></div></td></tr>
</table>
<p/>Thank you,
<p/>*Maintenance robot Automated ProcStats script on `uname -n`
<hr class="three" />
<p/>System time: `date`
</body>
</html>
_EOM_
}
if [ -n "$(checkStatus | grep BAD)" ]
  then
    sendAlert
fi

#EOF
