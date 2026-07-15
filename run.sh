#!/bin/bash

case "$1" in
	r)
		shift
		python3 src/sense-hat-ip-display.py "$@"
		;;
	t)
		shift
		pytest "$@"
		;;
	*)
		shift
		echo "invalid option: $@"
esac
