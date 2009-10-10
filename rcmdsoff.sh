#!/bin/ksh
#
# Takes an input file, contacts each server on the list and turns off 
# rlogin, rsh, and rexec.
# Jan 6 2009 - Bill Wilcox - Initial version


INPUT=/input/file.csv
OUTPUT=/output/file.txt

function output_check {

	# Check if the logfile already exists and rename it if it does

	if [ -f $OUTPUT ]
	then
		DATE=$(date '+%H:%M:%S')
		mv $OUTPUT $OUTPUT.$DATE
	fi
}

function logger {
 
	# Log to both screen and the log file

	echo $1 | tee -a $OUTPUT

}

function pingcheck {

	# Test to see if we can reach the box

	ping $1 2>/dev/null

	if [[ $? == 1 ]]
	then
		echo fail
	else
		echo pass
	fi

}

function get_ostype {

	# Determine the ostype of the server

	ssh -n $1 "uname -s" 2>/dev/null

}

function get_osversion {

	# Determine the osversion of the server

	ssh -n $1 "uname -r" 2>/dev/null

}

function sun510_off {

	# What to do for Solaris 5.10

	if [[ $(ssh -n $1 "svcs -a | grep rlogin | awk '{print \$1}'" 2>/dev/null) == "disabled" ]]
	then
		logger "rlogin is already off"
	else
		logger "Turning off rlogin"
		ssh -n $1 "svcadm disable /network/login:rlogin" 2>/dev/null
	fi

	if [[ $(ssh -n $1 "svcs -a | grep rexec | awk '{print \$1}'" 2>/dev/null) == "disabled" ]]
	then
		logger "rexec is already off"
	else
		logger "Turning off rexec"
		ssh -n $1 "svcadm disable /network/rexec" 2>/dev/null
	fi

	if [[ $(ssh -n $1 "svcs -a | grep shell:default | awk '{print \$1}'" 2>/dev/null) == "disabled" ]]
	then
		logger "rshell is already off"
	else
		logger "Turning off rshell"
		ssh -n $1 "svcadm disable /network/shell:default" 2>/dev/null
	fi


}

function hp1111_off {

	# What to do for HPUX 11.11
	recycle="false"

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep rexec | awk '{print \$1}'" 2>/dev/null) == "#exec" ]]
	then
		logger "rexec is already off"
	else
		logger "Turning off rexec"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^exec*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep 'rlogind -B' | awk '{print \$1}'" 2>/dev/null) == "#login" ]]
	then
		logger "rlogin is already off"
	else
		logger "Turning off rlogin"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^login*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "grep shell /etc/inetd.conf | grep -v kshell| awk '{print \$1}'" 2>/dev/null) == "#shell" ]]
	then
		logger "rshell is already off"
	else
		logger "Turning off rshell"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^shell*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	# If we've changed inetd.conf we need to recycle the daemon.

	if [[ $recycle == "true" ]]
	then
		logger "inetd.conf changed, restarting daemon."
		ssh -n $1 "/usr/sbin/inetd -c" 2>/dev/null
	fi

}

function hp1123_off {

	# What to do for HPUX 11.23
	recycle="false"

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep rexec | awk '{print \$1}'" 2>/dev/null) == "#exec" ]]
	then
		logger "rexec is already off"
	else
		logger "Turning off rexec"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^exec*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep 'lbin/rlogind' | grep -v klogin | awk '{print \$1}'" 2>/dev/null) == "#login" ]]
	then
		logger "rlogin is already off"
	else
		logger "Turning off rlogin"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^login*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "grep shell /etc/inetd.conf | grep -v kshell| awk '{print \$1}'" 2>/dev/null) == "#shell" ]]
	then
		logger "rshell is already off"
	else
		logger "Turning off rshell"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^shell*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	# If we've changed inetd.conf we need to recycle the daemon.

	if [[ $recycle == "true" ]]
	then
		logger "inetd.conf changed, restarting daemon."
		ssh -n $1 "/usr/sbin/inetd -c" 2>/dev/null
	fi

}

function hp1100_off {

	# What to do for HPUX 11.00
	recycle="false"

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep rexec | awk '{print \$1}'" 2>/dev/null) == "#exec" ]]
	then
		logger "rexec is already off"
	else
		logger "Turning off rexec"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^exec*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep 'rlogind -B' | awk '{print \$1}'" 2>/dev/null) == "#login" ]]
	then
		logger "rlogin is already off"
	else
		logger "Turning off rlogin"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^login*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "grep shell /etc/inetd.conf | grep -v kshell| awk '{print \$1}'" 2>/dev/null) == "#shell" ]]
	then
		logger "rshell is already off"
	else
		logger "Turning off rshell"
		ssh -n $1 "cp /etc/inetd.conf /etc/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^shell*/#&/' > /etc/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inetd.conf.changed /etc/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	# If we've changed inetd.conf we need to recycle the daemon.

	if [[ $recycle == "true" ]]
	then
		logger "inetd.conf changed, restarting daemon."
		ssh -n $1 "/usr/sbin/inetd -c" 2>/dev/null
	fi

}

function sun59_off {

	# What to do for Solaris 5.9
	recycle="false"

	if [[ $(ssh -n $1 "cat /etc/inet/inetd.conf | grep rexecd | awk '{print \$1}' | uniq" 2>/dev/null) == "#exec" ]]
	then
		logger "rexec is already off"
	else
		logger "Turning off rexec"
		ssh -n $1 "cp /etc/inet/inetd.conf /etc/inet/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^exec*/#&/' > /etc/inet/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inet/inetd.conf.changed /etc/inet/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep 'rlogind' | awk '{print \$1}'" 2>/dev/null) == "#login" ]]
	then
		logger "rlogin is already off"
	else
		logger "Turning off rlogin"
		ssh -n $1 "cp /etc/inet/inetd.conf /etc/inet/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inet/inetd.conf | sed 's/^login*/#&/' > /etc/inet/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inet/inetd.conf.changed /etc/inet/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "grep rshd /etc/inet/inetd.conf | awk '{print \$1}' | uniq" 2>/dev/null) == "#shell" ]]
	then
		logger "rshell is already off"
	else
		logger "Turning off rshell"
		ssh -n $1 "cp /etc/inet/inetd.conf /etc/inet/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inet/inetd.conf | sed 's/^shell*/#&/' > /etc/inet/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inet/inetd.conf.changed /etc/inet/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	# If we've changed inetd.conf we need to recycle the daemon.

	if [[ $recycle == "true" ]]
	then
		logger "inetd.conf changed, restarting daemon."
		ssh -n $1 "/usr/bin/pkill -HUP inetd" 2>/dev/null
	fi

}

function sun58_off {

	# What to do for Solaris 5.8
	recycle="false"

	if [[ $(ssh -n $1 "cat /etc/inet/inetd.conf | grep rexecd | awk '{print \$1}' | uniq" 2>/dev/null) == "#exec" ]]
	then
		logger "rexec is already off"
	else
		logger "Turning off rexec"
		ssh -n $1 "cp /etc/inet/inetd.conf /etc/inet/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inetd.conf | sed 's/^exec*/#&/' > /etc/inet/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inet/inetd.conf.changed /etc/inet/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "cat /etc/inetd.conf | grep 'rlogind' | awk '{print \$1}'" 2>/dev/null) == "#login" ]]
	then
		logger "rlogin is already off"
	else
		logger "Turning off rlogin"
		ssh -n $1 "cp /etc/inet/inetd.conf /etc/inet/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inet/inetd.conf | sed 's/^login*/#&/' > /etc/inet/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inet/inetd.conf.changed /etc/inet/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	if [[ $(ssh -n $1 "grep rshd /etc/inet/inetd.conf | awk '{print \$1}' | uniq" 2>/dev/null) == "#shell" ]]
	then
		logger "rshell is already off"
	else
		logger "Turning off rshell"
		ssh -n $1 "cp /etc/inet/inetd.conf /etc/inet/inetd.bckup" 2>/dev/null
		ssh -n $1 "cat /etc/inet/inetd.conf | sed 's/^shell*/#&/' > /etc/inet/inetd.conf.changed " 2>/dev/null
		ssh -n $1 "cp /etc/inet/inetd.conf.changed /etc/inet/inetd.conf " 2>/dev/null
		recycle="true"
	fi

	# If we've changed inetd.conf we need to recycle the daemon.

	if [[ $recycle == "true" ]]
	then
		logger "inetd.conf changed, restarting daemon."
		ssh -n $1 "/usr/bin/pkill -HUP inetd" 2>/dev/null
	fi

}

##############
# MAIN
##############

output_check

cat $INPUT | grep -v "#" | while read line
do
	DATE=$(date '+%H:%M:%S')
	HOST=$(echo $line | awk -F"," '{print $1}')

	if [[ $(pingcheck $HOST) = "fail" ]]
	then
		logger "$DATE - $HOST FAILED ping check."
	else
		OSTYPE=$(get_ostype $HOST)
		OSVERSION=$(get_osversion $HOST)
		logger "$DATE - Acting on $HOST - $OSTYPE - $OSVERSION"

		#  Here's where things get ugly, what to do...

		case $OSTYPE in
			SunOS* )
				case $OSVERSION in
					5.10*)
						sun510_off $HOST ;;
					5.9*)
						sun59_off $HOST ;;
					5.8*)
						sun58_off $HOST ;;
					*)
						logger "I don't know this OS version." ;;
				esac ;;
			HP-UX* )
				case $OSVERSION in
					B.11.11*)
						hp1111_off $HOST ;;
					B.11.23*)
						hp1123_off $HOST ;;
					B.11.00*)
						hp1100_off $HOST ;;
					*)
						logger "I don't know this OS version." ;;
				esac ;;
			* )
				logger "Don't know what to do" ;;
		esac
	fi
done
