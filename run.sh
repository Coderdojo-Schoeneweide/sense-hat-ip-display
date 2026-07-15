#!/bin/bash

case "$1" in
	r)
		shift
		python3 sense-hat-ip-display/cli/main.py "$@"
		;;
	t)
		shift
		pytest "$@"
		;;
	*)
		shift
		echo "invalid option: $@"
esac
