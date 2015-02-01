#!/bin/bash

set -x

case "$1" in
    main)
	echo 'liquidsoap -v --debug /config/main.liq' > /run.sh
	;;
    broadcast)
	echo 'liquidsoap /config/broadcast.liq' > /run.sh
	;;
esac

chmod +x /run.sh
supervisord -c /etc/supervisord.conf
sleep 1
touch /tmp/harbor.log

tail -n 100 -f /tmp/*.log


