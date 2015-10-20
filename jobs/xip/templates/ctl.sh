#!/bin/bash
# chkconfig: - 80 75
# description: PDNS is a versatile high performance authoritative nameserver

### BEGIN INIT INFO
# Provides:          pdns
# Required-Start:    $remote_fs $network $syslog
# Required-Stop:     $remote_fs $network $syslog
# Should-Start:
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: PowerDNS authoritative server
# Description:       PowerDNS authoritative server
### END INIT INFO

set -e

#prefix=/usr/local
prefix=/var/vcap/jobs/xip/packages/powerdns
exec_prefix=${prefix}
BINARYPATH=${exec_prefix}/bin
SBINARYPATH=${exec_prefix}/sbin
SOCKETPATH=/var/run
DAEMON_ARGS=""
PIDFILE="/var/vcap/sys/run/xip.pid"
LOGDIR="/var/vcap/sys/log/xip"

[ -f "$SBINARYPATH/pdns_server" ] || exit 0

[ -r /etc/default/pdns ] && . /etc/default/pdns

[ "$START" = "no" ] && exit 0

# Make sure that /var/run exists
mkdir -p $SOCKETPATH
cd $SOCKETPATH
suffix=$(basename $0 | cut -d- -f2- -s)
if [ -n "$suffix" ]
then
	EXTRAOPTS=--config-name=$suffix
	PROGNAME=pdns-$suffix
else
	PROGNAME=pdns
fi

# make sure LOG dir exists
mkdir -p $LOGDIR

pdns_server="$SBINARYPATH/pdns_server $DAEMON_ARGS $EXTRAOPTS"

doPC()
{
	ret=$($BINARYPATH/pdns_control $EXTRAOPTS $1 $2 2> /dev/null)
}

NOTRUNNING=0
doPC ping || NOTRUNNING=$?

case "$1" in
	status)
		if test "$NOTRUNNING" = "0"
		then
			doPC status
			echo $ret
		else
			echo "not running"
			exit 3
		fi
	;;

	stop)
		echo -n "Stopping PowerDNS authoritative nameserver: "
		# The monit way of stopping
		kill $(cat $PIDFILE)
	;;


	force-stop)
		echo -n "Stopping PowerDNS authoritative nameserver: "
		killall -v -9 pdns_server
		echo "killed"
	;;

	start)
		echo -n "Starting PowerDNS authoritative nameserver: "
		# The monit way of starting up
		( echo $BASHPID > $PIDFILE; exec \
                        > $LOGDIR/pdns_server.stdout.log \
                        2> $LOGDIR/pdns_server.stderr.log \
                        $pdns_server --daemon=no --guardian=yes --config-dir=/var/vcap/jobs/xip/etc ) &
	;;

	force-reload | restart)
		echo -n "Restarting PowerDNS authoritative nameserver: "
		if test "$NOTRUNNING" = "1"
		then
			echo "not running, starting"
		else

			echo -n stopping and waiting..
			doPC quit
			sleep 3
			echo done
		fi
		$0 start
	;;

	reload)
		echo -n "Reloading PowerDNS authoritative nameserver: "
		if test "$NOTRUNNING" = "0"
		then
			doPC cycle
			echo requested reload
		else
			echo not running yet
			$0 start
		fi
	;;

	monitor)
		if test "$NOTRUNNING" = "0"
		then
			echo "already running"
		else
			$pdns_server --daemon=no --guardian=no --control-console --loglevel=9
		fi
	;;

	dump)
		if test "$NOTRUNNING" = "0"
		then
			doPC list
			echo $ret
		else
			echo "not running"
		fi
	;;

	show)
		if [ $# -lt 2 ]
		then
			echo Insufficient parameters
			exit
		fi
		if test "$NOTRUNNING" = "0"
		then
			echo -n "$2="
			doPC show $2 ; echo $ret
		else
			echo "not running"
		fi
	;;

	mrtg)
		if [ $# -lt 2 ]
		then
			echo Insufficient parameters
			exit
		fi
		if test "$NOTRUNNING" = "0"
		then
			doPC show $2 ; echo $ret
			if [ "$3x" != "x" ]
			then
				doPC show $3 ; echo $ret
			else
				echo 0
			fi
			doPC uptime ; echo $ret
			echo PowerDNS daemon
		else
			echo "not running"
		fi

	;;

	cricket)
		if [ $# -lt 2 ]
		then
			echo Insufficient parameters
			exit
		fi
		if test "$NOTRUNNING" = "0"
		then
			doPC show $2 ; echo $ret
		else
			echo "not running"
		fi

	;;



	*)
	echo pdns [start\|stop\|force-reload\|reload\|restart\|status\|dump\|show\|mrtg\|cricket\|monitor]

	;;
esac


