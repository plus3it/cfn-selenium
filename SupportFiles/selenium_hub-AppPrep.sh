#!/bin/bash
# shellcheck disable=
#
# Install and enable/start Selenium-hub
#
#################################################################
PROGNAME="$(basename ${0})"
SELENIUMUSER="${1:UNDEF}"
SELENIUMURI="${2:UNDEF}"

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

# Check service-user
if [[ ${SELENIUMUSER} = UNDEF ]]
then
   err_exit 'Selenium user-account not defined'
elif [[ $(getent passwd ${SELENIUMUSER} > /dev/null)$? -ne 0 ]]
   err_exit "No such user, ${SELENIUMUSER}"
else
   SELENIUMHOME="$(getent passwd ${SELENIUMUSER} | cut -d: -f 6)"
   SELENIUMJAR="${SELENIUMHOME}/Selenium.jar"
fi

# Did we pass a source-url for the JAR
if [[ ${SELENIUMURI} = UNDEF ]]
then
   err_exit 'Selenium source-URL not defined'
fi

# Install Selenium
su - "${SELENIUMUSER}" -s /bin/bash -c \
  "curl -o ${SELENIUMJAR} -kL ${SELENIUMURI}"

# Make sure Selenium.jar exists and is valid
if [[ ! -e ${SELENIUMJAR} ]]
then
   err_exit 'Failed to create Selenium.jar'
elif [[ $(file ${SELENIUMJAR} | grep -q 'Zip archive data')$? -ne 0 ]]
   err_exit 'Created Selenium.jar is not valid'
fi

# Take care of selenium-hub service
if [[ $(systemctl is-enabled selenium-hub) = enabled ]]
then
   echo "Selenium-hub service already enabled."
else
   printf "Selenium-hub service is disabled. Attempting to enable... "
   systemctl -q enable selenium-hub && echo 'Success.' || \
     err_exit "Failed to enable selenium-hub"
fi

if [[ $(systemctl is-active selenium-hub) = active ]]
then
   echo "Selenium-hub service already enabled."
else
   printf "Selenium-hub service is active. Attempting to start... "
   systemctl -q start selenium-hub && echo 'Success.' || \
     err_exit "Failed to start selenium-hub"
fi


