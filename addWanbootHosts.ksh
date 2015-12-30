# script requires input file: "hostList.dat"
# input-file format:
# [hostname] | [primary-NIC-MAC] | [primary-NIC-devName] | [ip_addr] | [subnetMask] | [gateway] | [dns1ip],[dns2ip] | [platform] | [osRel]
# Example:
# newHostname|0003bab02964|ce0|10.66.6.2|255.255.255.0|10.66.6.1|10.66.6.252,10.6.6.253|sun4u|S10_U11_0113

##############################################################################################################
##############################################################################################################
### Begin script ###
##############################################################################################################
#!/usr/bin/ksh
# FileName: addWanBootHosts.ksh
# Created By: J. Eric Stout
# Created On: 2012AUG22
#    Purpose: To speed pre-deployment configuration of Solaris WANboot hosts.
#  Changelog: 2012AUG22 - Just Born!
#             2013JAN07 - Major overhaul!

sysIDpath="/var/apache2/htdocs/config/sysidcfg"

deployHosts() {
baseMAC="01"
i=0
#set -A hostList `(awk -F"|" '{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' hostList.dat)`
set -A hostList `(cat hostList.dat)`
while [ $i -lt ${#hostList[@]} ]
        do
      hName=`(echo ${hostList[$i]} | awk -F"|" '{print $1}')`
     priMac=`(echo ${hostList[$i]} | awk -F"|" '{print $2}' | tr '[a-z]' '[A-Z]')`
     priNic=`(echo ${hostList[$i]} | awk -F"|" '{print $3}')`
      priIp=`(echo ${hostList[$i]} | awk -F"|" '{print $4}')`
      priNm=`(echo ${hostList[$i]} | awk -F"|" '{print $5}')`
      priGw=`(echo ${hostList[$i]} | awk -F"|" '{print $6}')`
nameServers=`(echo ${hostList[$i]} | awk -F"|" '{print $7}')`
    sysType=`(echo ${hostList[$i]} | awk -F"|" '{print $8}')`
    release=`(echo ${hostList[$i]} | awk -F"|" '{print $9}')`

##############################
# More Variable Declarations ###################################################
##############################
if [[ ! -d  ${sysIDpath}/${hName} ]]
  then
    mkdir ${sysIDpath}/${hName}
fi
#######################
# Build sysidcfg file ##########################################################
#######################
cat <<EOF > ${sysIDpath}/${hName}/sysidcfg
install_locale=C
system_locale=en_US
terminal=vt100
keyboard=US-English
timezone=US/Central
network_interface=${priNic} {PRIMARY hostname=${hName}
        ip_address=${priIp}
        netmask=${priNm}
        protocol_ipv6=no
        default_route=${priGw}}
security_policy=NONE
root_password=0weiurPuwe.u <-- This is fake
nfs4_domain=dynamic
timeserver=localhost
auto_reg=disable
service_profile=limited_net
name_service=DNS {domain_name=your.domain.com
                name_server=${nameServers}
                search=your.domain.com}
EOF


##########################
# Build system.conf file #######################################################
##########################
if [[ ! -d ${systemConfDir}/01${priMac} ]]
  then
    mkdir ${systemConfDir}/01${priMac}
fi
touch ${systemConfDir}/01${priMac}/.${hName}
cat <<EOF > ${systemConfDir}/01${priMac}/system.conf
SsysidCF=http://10.66.66.6/config/sysidcfg/${hName}
SjumpsCF=http://10.66.66.6/config
EOF

###########################
# Build wanboot.conf file ######################################################
###########################

cat <<EOF > /etc/netboot/${thisNetwork}/wanboot.conf
boot_file=/wanboot/wanboot_${release}.${sysType}
root_server=http://10.6.66.6/cgi-bin/wanboot-cgi
root_file=/miniroot/miniroot.${release}
signature_type=
encryption_type=
server_authentication=no
client_authentication=no
resolve_hosts=
boot_logger=http://10.66.66.6/cgi-bin/bootlog-cgi
system_conf=system.conf
EOF

###############################
# Set Permissions & Ownership ##################################################
###############################
chown -R webservd:webservd ${systemConfDir}
chmod -R 700 ${systemConfDir}
chown -R webservd:webservd ${sysIDpath}

((i=$i+1))
done
}

# End of function: deployHosts()

checkFile() {
if [ -f hostList.dat ]
  then
    echo "Processing hosts in network: ${thisNetwork}"
    deployHosts
  else
    echo "Input file missing! Please create: hostList.dat."
    exit
fi
}

checkDir() {
if [[ -d "${systemConfDir}" ]]
  then
    echo "Directory ${systemConfDir} exists."
    checkFile
  else
    printf "Directory ${systemConfDir} does not exist. Shall I create it? "; read ynVar
    case "$ynVar" in
    [yY]|[yY][eE][sS])
            mkdir ${systemConfDir}
            checkFile
            ;;
        [nN]|[nN][oO])
            echo "Exiting..."
            break
            ;;
                    *)
            echo "What?"
            checkDir
            ;;
    esac
fi
}

case $1 in
      *.0|*.30)
         thisNetwork=$1
         systemConfDir="/etc/netboot/${thisNetwork}"
         checkDir
        ;;
        *)
         echo "Missing Network ID!\nSyntax: `basename $0` ###.###.###.0"
        ;;
esac
#EOF

# End of Script
##############################################################################################################
##############################################################################################################
##############################################################################################################

# Notes: The script depends on following structures/symlinks, and creates files/directories:
# /etc/netboot -> /wanboot/netboot
#   /wanboot/netboot
#     /wanboot/netboot/10.66.6.0
#     /wanboot/netboot/10.66.6.0/0003bab02964
#     /wanboot/netboot/10.66.6.0/0003bab02964/.newHostName
#     /wanboot/netboot/10.66.6.0/0003bab02964/system.conf
#     /wanboot/netboot/10.66.6.0/0003bab02964/wanboot.conf
#       (The files/structres above are uniquely generated for each hostList.dat entry)
###
# /var/apache2/htdocs
#   config -> /wanboot/config
#     /wanboot/config
#       /wanboot/config/check ; # executable config-syntax validator
#       /wanboot/config/postinstall.ksh ; # post-installation script
#       /wanboot/config/prof_initial_Sol10U11_ZFS.profile ; # Configuration Deployment profile
#       /wanboot/config/rules ; # Boot/install instructions
#       /wanboot/config/rules.ok ; # Chksum validated config file.
#       /wanboot/config/script_pre_initial.sh ; # Pre-Installation env-config script
#       /wanboot/config/sysidcfg
#       /wanboot/config/sysidcfg/newHostName ; # auto-gen'd client definition structure
#       /wanboot/config/sysidcfg/newHostName/sysidcfg ; # auto-gen'd client definition file
###
# /var/apache2/htdocs
#   flash -> /wanboot/flash
#   /wanboot/flash
#     /wanboot/flash/Sol10_U11_0113_nopatch_sun4u_gold.flar
#       ('gold' operating system image flash-archive)
###
# /var/apache2/htdocs
#   install -> /wanboot/install
#     /wanboot/install
#     (Installation resources extracted via 'setup_install_server' script on disc-media)
#   iso ->/wanboot/iso
#     /wanboot/iso
#       (CD/DVD ISO Images stored here)
###
# /var/apache2/htdocs
#   miniroot -> /wanboot/miniroot
#   /wanboot/miniroot/miniroot.S10_U11_0113
#     (Minimum network-boot enviroment for desired OS release)
###
# /var/apache2/htdocs
#   wanboot -> /wanboot/wanboot
#   /wanboot/wanboot/wanboot_S10U11_0113.sun4u
#     (boostrap platform release for 'sun4u' Architecture)
#   /wanboot/wanboot/wanboot_S10U11_0113.sun4v
#     (boostrap platform release for 'sun4v' Architecture)
