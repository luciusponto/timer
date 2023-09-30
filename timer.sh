#!/bin/bash
TIMER_APP_PATH=~/dev/projects/Godot4/timer/.build/Win64/Timer.exe
arg1=""
arg2=""
if [ "$1" != "" ]; then
	arg1="--time=$1"
fi
if [ "$2" != "" ]; then
	arg2="--timer-title=$2"
fi
#echo "$args"
$TIMER_APP_PATH --quiet $arg1 $arg2 &
disown