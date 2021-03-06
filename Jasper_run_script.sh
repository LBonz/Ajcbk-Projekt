#! /bin/sh

PREFIX="/usr/local"
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin
DESC="Jasper voice control"
NAME="jasper"
DAEMON="$PREFIX/lib/jasper/jasper.py"
DAEMON_ARGS=""
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

export LD_LIBRARY_PATH="$PREFIX/lib"
export JASPER_CONFIG="$PREFIX/lib/jasper"


[ -x "$DAEMON" ] || exit 0


[ -r /etc/default/$NAME ] && . /etc/default/$NAME


. /lib/init/vars.sh


. /lib/lsb/init-functions


do_start()
{
	
	start-stop-daemon --start --chuid "$NAME" --verbose --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
		|| return 1
	start-stop-daemon --start --nicelevel -19 \
                          --background --chuid "$NAME" --verbose \
	                  --make-pidfile --pidfile $PIDFILE --exec $DAEMON -- \
		$DAEMON_ARGS \
		|| return 2
	
}


#
do_stop()
{

	start-stop-daemon --stop --verbose --retry=TERM/30/KILL/5 --pidfile $PIDFILE 
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2

	start-stop-daemon --stop --verbose --oknodo --retry=0/30/KILL/5 --exec $DAEMON
	[ "$?" = 2 ] && return 
	rm -f $PIDFILE
	return "$RETVAL"
}



do_reload() {

	start-stop-daemon --stop --signal 1 --verbose --pidfile $PIDFILE
	return 0
}

case "$1" in
  start)
	[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
	do_start
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  status)
	status_of_proc -p $PIDFILE "$DAEMON" "$NAME" && exit 0 || exit $?
	;;

  restart|force-reload)

	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; 
			*) log_end_msg 1 ;; 
		esac
		;;
	  *)
		# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	#echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac

:
