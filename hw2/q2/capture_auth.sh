#!/bin/bash

# In case we need to restart after sudo
_my_name=`basename $0`
if [ "`echo $0 | cut -c1`" = "/" ]; then
  _my_path=`dirname $0`
else
  _my_path=`pwd`/`echo $0 | sed -e s/$_my_name//`
fi

if [[ `whoami` != 'root' ]]; then
  echo "Not running as root."
  exit 1
fi

# File settings
TCP_RAW_CAP='auth_packets'
FORMATTED_CAP='auth_formatted'

# Check if there is already a raw capture file
DO_CAPTURE=1
if [[ -e $TCP_RAW_CAP && $1 != "-f" ]]; then
  echo -n "CAPTURE FILE $TCP_RAW_CAP already exists, skip capture? "
  read ANS

  if [[ ANS == 'y' || ANS='yes' ]]; then
    # Skip the capture
    DO_CAPTURE=0
  fi
fi

if [[ DO_CAPTURE -eq 1 ]]; then
  echo "starting tcpdump"
  tcpdump -w $TCP_RAW_CAP -i eth1&
  if [[ $? -ne "0" ]]; then
    echo "Failed to start tcpdump"
    exit -1
  fi

  # Save the pid to kill it later
  TCPD_PID=$!

  # Intiate the client to auth
  telnet 192.169.1.2 5151

  echo "Stopping tcpdump at PID $TCPD_PID}"
  # Killing it will cause you to lose any captured packets
  #kill -9 ${TCPD_PID}
  kill -2 ${TCPD_PID}
fi

echo -e "\n\nDisplay of packet data from tcpdump"
tcpdump -A -r $TCP_RAW_CAP >> $FORMATTED_CAP
cat ${FORMATTED_CAP}

#./find_auth_pair.py $FORMATTED_CAP
