#!/bin/bash
# shellcheck disable=SC2015,SC2086
#
#################################################################
PROGNAME="$(basename ${0})"

# Error handler function
function err_exit {
   local ERRSTR="${1}"
   local SCRIPTEXIT=${2:-1}

   # Our output channels
   echo "${ERRSTR}" > /dev/stderr
   logger -t "${PROGNAME}" -p kern.crit "${ERRSTR}"

   # Need our exit to be an integer
   if [[ ${SCRIPTEXIT} =~ ^[0-9]+$ ]]
   then
      exit "${SCRIPTEXIT}"
   else
      exit 1
   fi
}


#####################
## Main program logic
#####################

# Take care of firewall
if [[ $(systemctl is-active firewalld) == active ]]
then
   echo "Firewalld service already running..."
   printf "Adding selenium-hub exception to running firewalld config... "
   firewall-cmd --add-service=selenium-hub || \
     err_exit "Failed adding selenium-hub to running firewalld config"
   printf "Adding selenium-hub exception to persistent firewalld config... "
   firewall-cmd --add-service=selenium-hub --permanent || \
     err_exit "Failed adding selenium-hub to permanent firewalld config"
elif [[ $(systemctl is-active firewalld) == failed ]]
then
   echo "Firewalld service offline..."
   printf "Adding selenium-hub exception to persistent firewalld config... "
   firewall-offline-cmd --add-service=selenium-hub
     err_exit "Failed adding selenium-hub to firewalld config"
   printf 'Attempting to (re)start firewalld... '
   systemctl restart firewalld && echo 'Success' || \
     err_exit "Failed to restart firewalld."
fi
