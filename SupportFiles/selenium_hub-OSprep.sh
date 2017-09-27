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
   logger -t "${PROGNAME}" -p user.crit "${ERRSTR}"

   # Need our exit to be an integer
   if [[ ${SCRIPTEXIT} =~ ^[0-9]+$ ]]
   then
      exit "${SCRIPTEXIT}"
   else
      exit 1
   fi
}

function logit {
   local LOGSTR="${1}"

   # Our output channels
   printf "%s" "${LOGSTR}" > /dev/stdout
   logger -t "${PROGNAME}" -p user.info "${LOGSTR}"
}


#####################
## Main program logic
#####################


# Take care of firewall
if [[ $(systemctl is-active firewalld) == active ]]
then
   logit "Firewalld service already running...\n"

   # Try to restart firewall in case SEL made things interesting
   if [[ $(getenforce) == Enforcing ]]
   then
      logit "SEL enforcing: Trying to restart firewalld to flush out changes\n"
      systemctl try-restart firewalld
   fi

   logit "Adding selenium-hub exception to running firewalld config... "
   firewall-cmd --add-service=selenium-hub || \
     err_exit "Failed adding selenium-hub to running firewalld config"
   logit "Adding selenium-hub exception to persistent firewalld config... "
   firewall-cmd --add-service=selenium-hub --permanent || \
     err_exit "Failed adding selenium-hub to permanent firewalld config"
elif [[ $(systemctl is-active firewalld) == failed ]]
then
   logit "Firewalld service offline...\n"
   logit "Adding selenium-hub exception to persistent firewalld config... "
   firewall-offline-cmd --add-service=selenium-hub
     err_exit "Failed adding selenium-hub to firewalld config"
   logit 'Attempting to (re)start firewalld... '
   systemctl restart firewalld && logit 'Success\n' || \
     err_exit "Failed to restart firewalld."
fi
