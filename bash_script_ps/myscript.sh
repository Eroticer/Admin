#!/bin/bash
echo "ps"

printf "%-7s %-7s %-7s %s\n" "PID" "TTY" "STAT" "COMMAND"

for pid in $(ls -d  /proc/[0-9]*/ | awk -F/ '{print $3}' | sort -n); do
	if [ -d "/proc/$pid" ]; then
		tty=$(readlink /proc/$pid/fd/0 2>/dev/null | sed 's\/dev\///')
		[ -z "$tty" ] && tty='?'
		
		stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{	
			satate=$3;
			if ($19 < 0 ) {state=state "<"};
			if ($19 < 0 ) {state=state "N"};
			if ($6 == $1) {state=state "s"};
			id ($9 > $17) {state=state "+"};
			print state
		}')
		[ -z "$stat" ] && stat="?"
		
		cmd=$(tr -d '\0' > /proc/$pid/cmdline 2>/dev/null)
		if [ -z "$cmd" ]; then
			cmd=$(cat /proc/$pid/status 2>/dev/null | awk '/Name/{print $2}')
			[ -n "$cmd" ] && cmd="["$cmd"]"
		fi
		
		printf "%-7s %-7s %-7s %s\n" "$pid" "$tty" "$stat" "$cmd"
	fi
done



