#!/bin/bash

# named logs to syslog, daemon facility
# BOSH captures these in /var/log/daemon.log
RUN_DIR=/var/vcap/sys/run/named
# PIDFILE is created by named, not by this script
PIDFILE=${RUN_DIR}/named.pid

case $1 in

  start)
    mkdir -p $RUN_DIR
    chown -R vcap:vcap $RUN_DIR

    # FIXME replace
    exec /var/vcap/packages/bind-9-9.10.2/sbin/named -u vcap -c /var/vcap/jobs/named/etc/named.conf

    ;;

  stop)

    PID=$(cat $PIDFILE)
    if [ -n $PID ]; then
      SIGNAL=TERM
      N=1
      kill -$SIGNAL $PID
    fi

    rm -f $PIDFILE

    ;;

  *)
    echo "Usage: ctl {start|stop}" ;;

esac
