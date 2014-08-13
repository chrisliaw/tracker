#!/bin/sh
PID=$(head -n 1 "tmp/pids/server.pid")
kill -9 $PID
if [ $? -eq 0 ]; then
	rm "tmp/pids/server.pid"
fi
