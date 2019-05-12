#!/bin/bash

INSTALL_DIR=.
LOGFILE='install.log'

ICON_INCOMPLETE_COLOUR=`tput setaf 1`
ICON_COMPLETE_COLOUR=`tput setaf 2`
TEXT_COLOUR=`tput setaf 2`
BAR_COLOUR_COMPLETE=`tput setaf 6`
BAR_COLOUR_REMAINING=`tput setaf 3`
ERROR_COLOUR=`tput setaf 1`
NO_COLOUR=`tput sgr0`

ICON_INCOMPLETE="${BAR_COLOUR_REMAINING}\xc2\xa2${NO_COLOUR}"
ICON_COMPLETE="${ICON_COMPLETE_COLOUR}\xcf\xbe${NO_COLOUR}"
ICON_ERROR="${ERROR_COLOUR}\xcf\xbf${NO_COLOUR}"

BINARY_DIR=/usr/bin
SERVICE_DIR=/lib/systemd/system

RELEASE='https://github.com/garethmidwood/backbot-service/raw/master/backbot.sh'
TMP_RELEASE_FILE=$(mktemp)
TARGET_RELEASE_PATH="${BINARY_DIR}/backbot.sh"

SERVICE='https://github.com/garethmidwood/backbot-service/raw/master/backbot.service'
TMP_SERVICE_FILE=$(mktemp)
TARGET_SERVICE_PATH="${SERVICE_DIR}/backbot.service"

function err {
  log "FATAL ERROR: ${1}"
  completeLogEntry

  echo -ne "\n"
  echo -ne "- ${ERROR_COLOUR}${1}${NO_COLOUR}\r"
  echo -ne "\n"
  echo -ne "- ${ICON_ERROR} installation failed"
  echo -ne "\n"
  exit 1
} 

function log {
  echo $1 >> ${INSTALL_DIR}/${LOGFILE}
}

function initLogEntry {
  touch ${INSTALL_DIR}/${LOGFILE}
  > ${INSTALL_DIR}/${LOGFILE}
  log "============================================="
  log "Installation started at `date`"
  log "============================================="
}

function completeLogEntry {
  log "fin"
  log ""
  log ""
}

function progress {
  TOTAL=100
  COMPLETE=$1
  REMAINING=$(($TOTAL-$1))

  COMPLETE_CHAR_COUNT=$(($COMPLETE/5))
  REMAINING_CHAR_COUNT=$(($REMAINING/5))

  COMPLETE_CHARS=`eval printf "%0.sϾ" $(seq 0 $COMPLETE_CHAR_COUNT)`
  REMAINING_CHARS=`eval printf "%0.s." $(seq 0 $REMAINING_CHAR_COUNT)`

  echo -ne "- ${ICON_INCOMPLETE} ${BAR_COLOUR_COMPLETE}installing ${BAR_COLOUR_COMPLETE}${COMPLETE_CHARS:1}${BAR_COLOUR_REMAINING}${REMAINING_CHARS:1} ${TEXT_COLOUR}(${COMPLETE}%)${NO_COLOUR}\r"
}

function checkSystemRequirements {
  echo -ne "${BAR_COLOUR_REMAINING}Checking system requirements${NO_COLOUR}\r"

  if (( $EUID != 0 )); then
    err "This script must be run as root user"
  fi
}





initLogEntry

progress 5

checkSystemRequirements

progress 10




log "Downloading latest release to $TMP_RELEASE_FILE"

if curl -LsSo $TMP_RELEASE_FILE $RELEASE ; then
  progress 20

  log "Copying release to $TARGET_RELEASE_PATH"
  if cp $TMP_RELEASE_FILE $TARGET_RELEASE_PATH ; then
    progress 30
    log "Successfully downloaded release file. Making read/executable"
    chmod +rx $TARGET_RELEASE_PATH
    progress 40
    log "Script is now executable"
  else
    err "Error when copying release to ${TARGET_RELEASE_PATH}"
  fi

else
  err "Error when downloading release from ${RELEASE}"
fi





log "Downloading service to $TMP_SERVICE_FILE"

if curl -LsSo $TMP_SERVICE_FILE $SERVICE ; then
  progress 50

  log "Copying service to $TARGET_SERVICE_PATH"
  if cp $TMP_SERVICE_FILE $TARGET_SERVICE_PATH ; then
    progress 60
    log "Successfully downloaded service file"
  else
    err "Error when copying service to ${TARGET_SERVICE_PATH}"
  fi

else
  err "Error when downloading service from ${SERVICE}"
fi


log "Creating service user"
sudo useradd --system backbot

log "Enabling service"
sudo systemctl enable backbot

log "Starting service"
systemctl start backbot


progress 100

echo -ne "- ${ICON_COMPLETE} successfully installed"
echo -ne "\n"

log "Installation completed successfully"

completeLogEntry

exit 0

