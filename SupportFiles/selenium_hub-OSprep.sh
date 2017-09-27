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
   logger -t "${PROGNAME}" -p user.info -s -- "${LOGSTR}" 2> /dev/console
}


#####################
## Main program logic
#####################


# Take care of firewall
if [[ $(systemctl is-active firewalld) == active ]]
then
   SELMODE="$(getenforce)"
   logit "Firewalld service already running..."

   # Try to restart firewall in case SEL made things interesting
   if [[ ${SELMODE} == Enforcing ]]
   then
      logit "SEL enforcing: Trying to restart firewalld to flush out changes"
      systemctl try-restart firewalld
      logit "SEL enforcing: dial it back for a bit..."
      setenforce 0 && logit "Success." || \
        err_exit 'Failed resetting SEL-mode'
   fi

   logit "Adding selenium-hub exception to running firewalld config... "
   firewall-cmd --add-service=selenium-hub || \
     err_exit "Failed adding selenium-hub to running firewalld config"
   logit "Adding selenium-hub exception to persistent firewalld config... "
   firewall-cmd --add-service=selenium-hub --permanent || \
     err_exit "Failed adding selenium-hub to permanent firewalld config"

   # Return SEL to starting mode
   logit "Reset SEL-mode to initial state..." 
   setenforce "${SELMODE}" && logit "Success." || \
     err_exit 'Failed resetting SEL-mode'
elif [[ $(systemctl is-active firewalld) == failed ]]
then
   logit "Firewalld service offline..."
   logit "Adding selenium-hub exception to persistent firewalld config... "
   firewall-offline-cmd --add-service=selenium-hub
     err_exit "Failed adding selenium-hub to firewalld config"
   logit 'Attempting to (re)start firewalld... '
   systemctl restart firewalld && logit 'Success' || \
     err_exit "Failed to restart firewalld."
fi
