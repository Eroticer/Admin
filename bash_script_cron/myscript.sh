#!/bin/bash

EMAIL="root@gmail.com"
LOG_FILES="access-4560-644067.log"
REPORT_FILE="message.txt"

HOUR_AGO=$(date -d '1 hour ago' '+[%d/%b/%Y:%H:%M:%S')
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')


{
	echo "Отчёт за последний час с $HOUR_AGO по $CURRENT_TIME"
	echo ""

	echo "top ip"
	awk -v h="$HOUR_AGO" '$4 >= h' "$LOG_FILE" | grep -oP "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | uniq -c | sort -nr | head -20
	echo ""

	echo "top url"
	awk -v h="$HOUR_AGO" '$4 >= h {print $7}' "$LOG_FILE" | cut -d'?' -f1 | sort | uniq -c | sort -nr | head -20
	echo ""

	echo "ERRORS"
	awk -v h="$HOUR_AGO" '$4 >= h && $9 ~ /^[45][0-9]{2}/$' "$LOG_FILE" 
	echo ""

	echo "HTTP codes"
	awk -v h="$HOUR_AGO" '$4 >= h {print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -20
	echo ""
} > "$REPORT_FILE"

if [ -s "$REPORT_FILE" ]; then
	mailx -s "$EMAIL" < "$REPORT_FILE"
    	echo "Отчёт отправлен на $EMAIL в $CURRENT_TIME"
else
    	echo "Нет данных для отчёта за последний час"
fi

rm -f "$REPORT_FILE"
