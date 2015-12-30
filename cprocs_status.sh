#!/usr/bin/ksh
#############################################################
# Shell Script to show the status of the appName Process's
# No passed paramaters needed. Just shows all the process's
# Running for the database
############################################################

##---------------------------------------------------
#First tell the user what they are doing
#--------------------------------------------------

printf "Script name is                    [$0]\n\n"

tuxChk(){
ps -fu [someUser] -o user,pid,args | awk '$3 ~ /^'${tParam}'/ && $_ ~ /program_pathname/'
}

printf "#########################\n"
printf "# Tuxedo process checks ########################################################\n"
printf "#########################\n\n"

for tParam in BBL WSL cleard clearad
do
if [ -n "$(tuxChk)" ] ; then
        set -A tuxArr `tuxChk | awk '{print $2}'`
    printf "[GOOD] - Tuxedo ${tParam} is up and running for appName. PID(s):  ${tuxArr[*]}\n\n"
  else
    printf "[BAD!] - The Tuxedo ${tParam} service is NOT up and running against appName.\n\n"
fi
done

clarChk(){
ps -fu [someUser] -o user,pid,args | awk '$3 ~ /^'${cParam}'$/'
}

printf "\n\n##########################\n"
printf "# Clarify process checks #######################################################\n"
printf "##########################\n\n"

for cParam in notifier rulemansvc ftserver
do
if [ -n "$(clarChk)" ] ; then
        set -A clarArr `clarChk | awk '{print $2}'`
   printf "[GOOD] - The ${cParam} service is running. PID(s): ${clarArr[*]}\n\n"
  else
        printf "[BAD!] - The ${cParam} service is NOT Running!\n\n"
        if [ "${cParam}" = "rulemansvc" ]
          then
            set -A rmwArr `ps -fu focusprd -o user,pid,args | awk '$3 ~ /^rmworkerprocess$/ {print $2}'`
            if [ "${#rmwArr[*]}" -gt "0" ]
              then
                printf "\tBefore restarting Rulemanager, kill active rmworkerprocess PID(s): ${rmwArr[*]}\n"
              else
                printf "\tRmworkerprocess are deactivated.\n"
            fi
        fi
fi
done
printf "\n\n"
