#!/usr/bin/env bash
#
# UI for eqb.
#
# MOD_NAME: mod_ui
# MOD_AUTHOR: JaredAllard

export HISTFILE_OLD=$HISTFILE
export HISTFILE=$basedir/home/$username/history
export LOGFILE=$basedir/tmp/output.txt
export RRPG_PROMPT="> "
export RRPG_HEADER="eqb"
export RRPG_HEADER_2="v1.2"

export Invert="\033[7m"
export Reset="\033[0m"
export Bold="\033[1m"


SIDEBAR_LENGTH=20

echo "" > ${LOGFILE}

draw_header() {
	local cols=`tput cols`

	# set to beginning
	tput cup 0 0
	echo -ne "${Bold}$RRPG_HEADER"

	# set version spot
	tput cup 0 $(($(($cols-$SIDEBAR_LENGTH))-${#RRPG_HEADER_2}))
	echo -ne "${Bold}$RRPG_HEADER_2${Reset}"
}

clean_exit() {
	export HISTFILE=$HISTFILE_OLD
	history -c
	history -n
	clear
}

draw_from_to() {
	local y=$1
	local start_x=$2
	local end_x=$3
	local text=$4

	local i=$start_x

	until [[ $i == $end_x ]]; do
		tput cup $y $i
		echo -ne "$text"

		let i=$i+1
	done
}

# Center Text on Y between X1 and X2.
center_between_pos() {
	local y=$1
	local from_x=$2
	local too_x=$3
	local text=$4

	# calculate distance between two points
	local distance=$(($too_x-$from_x))
	local string_length=${#text}

	# subtract total distance by length of the string, then divide by two for close
	local padding_left=$(($distance-$string_length))
	local padding=$(($padding_left/2))

	tput cup $y $(($from_x+$padding))
	echo -ne "$text"
}

clear_output() {
	local lines=$(tput lines)
	local x=0
	until [[ $x == $lines ]]; do
		let x=$x+1
		line[$x]="false"
	done
}

to_bottom() {
	local lines=`tput lines`
	tput cup $lines 0
}

clear_line() {
	clear_lines $*
}

print_chars() {
	if [ "$1" == "" ]; then
		echo "err: needs a char"
		return
	fi
	if [ "$2" == "" ]; then
		echo "err: needs a num"
		return
	fi

	for a in `seq $2`; do echo -ne "$1"; done
}

draw_prompt() {
	local cols=`tput cols`
	local lines=`tput lines`
	to_bottom
	tput cuu 4
	tput cup $(($lines-4)) 0
	history -n

	if [ ! "$1" == "--no-read" ]; then
		read -ep "${RRPG_PROMPT}" choice

		 # save the choice
		export choice=$choice
		echo "$choice" >> ${HISTFILE}
	else

		# we're just drawing the prompt, it's not an actual real one.
		echo -ne "${RRPG_PROMPT}"
	fi
}

draw_tip() {
	to_bottom
	tput cuu 3
	echo "$1"
}

to_top() {
	tput cup 0 0
	if [ ! "$1" == "" ]; then
		echo -e "$1"
	fi
}

clear_lines() {
	local line_number=$1
	local lines=`tput lines`
	local cols=`tput cols`

	local x=0
	until [ $x == $line_number ]
	do
		local n=0
		local y=0

		let x=$x+1

		# Move up a cert amount of lines, first save cursor pos (bottom)
		tput sc
		tput cuu $x


		while [ $n -lt $cols ]
		do
			echo -n ' '
			let n=$n+1
		done
		tput rc
	done

	echo
}

echo_to_end() {
	local lines=`tput lines`
	local n=0
	local v=""

	if [[ -z "$2" ]]; then
		local 2=0
	fi

	while [[ $n -lt $(($cols-$2)) ]]; do
		local v="$v$1"
		let n=$n+1
	done

	echo -n $v
}

echo_amount() {
	local number=$2
	local n=0
	local v=""
	while [ $n -lt $number ]
	do
		local v="$v$1"
		let n=$n+1
	done
	echo -n "$v"
}

send_output() {
	# Handles all output, as it should.

	local lines=`tput lines`
	local cols=`tput cols`
	local lines=$(($lines-8))
	local message=$1
	local message_chars=${#message}
	local n=1
	local num=0
	local final=""
	to_top

	# hide the cursor
	tput civis


	# until i is equal to message chars
	for (( i=0; i<${message_chars}; i++ )); do

		# if $i is greater or equal to amount of colums
		if [[ $i -ge $cols ]]; then
			local crw=$cols

			# until $i is less than the amount of colums.
			until [ $i -lt $cols ]
			do
				local cols=$(($cols+$cols))
				let n=$n+1

				local final="${final}${message:$i:1}"
				line[$n]="true"
			done

		else
			local final="${final}${message:$i:1}"
		fi
	done
	local message=$final

	# Tracks scrolling of text
	while :; do
		let num=$num+1
		if [[ "${num}" == "$lines" ]]; then
			local d=2

			line[$lines]="false"
			to_top
			tput cud $d

			local m=0

			# clear the bg to prevent overflow.
			until [[ $m == $(($lines)) ]]; do
				printf "%0.s " `seq 1 $(($cols))`
				let m=$m+1
			done

			to_top
			tput cud $d
			tail -n $(($lines-1)) ${LOGFILE}
			break
		elif [ ! "${line[$num]}" == "true" ]; then
			to_top
			tput cud $(($num+1))
			break
		fi
	done

	tput cnorm

	line[$num]="true"
	echo -e "$message"
	echo -e "$message" >> ${LOGFILE}
}

draw_box() {
	local lines=`tput lines`
	local cols=`tput cols`

	to_bottom
	tput cuu 2
	echo_to_end "=" $SIDEBAR_LENGTH

	# Section 2
	tput cup $(($lines-2)) 0 && echo -n "="
	tput cup $(($lines-2)) 2
	echo -ne "Health: ${Green}$(cat $basedir/home/$username/hp.pwd)${NC} / XP: ${Cyan}$(cat $basedir/db/xp.txt)${NC}"
	tput cup $(($lines-2)) $cols && echo -n "="

	# Section 1
	tput cup $(($lines-1)) 0 && echo -n "="
	tput cup $(($lines-1)) 2
	echo -ne "A: ${Red}$(cat $basedir/home/$username/attack.txt) ${NC}/ D: ${Blue}$(cat $basedir/home/$username/defense.txt)${NC}"

	to_bottom

	# Draw the prompt
	draw_prompt --no-read
}

draw_sidebar() {
	# sidebar is 10 chars from the RIGHT
	local lines=`tput lines`
	local cols=`tput cols`
	local sidebar_border_left_pos=$(($cols-$SIDEBAR_LENGTH))

	# draw side border to the left.
	local i=0
	until [[ $i == $(($lines+1)) ]]; do
		echo -ne "|"
		tput cup $i $sidebar_border_left_pos
		let i=$i+1
	done

	# draw inventory header
	center_between_pos 0 $sidebar_border_left_pos $cols "Inventory"

	# plus 1 so we don't accidently draw on the border
	draw_from_to 1 $(($sidebar_border_left_pos+1)) $cols "="
	draw_from_to $(($lines-3)) $(($sidebar_border_left_pos+1)) $cols "="
}

draw_main() {
	trap "clear; draw_main; draw_prompt --no-read" SIGWINCH

	# RM cls file
	rm -rf $basedir/tmp/cls

	# Load User history file.
	if [[ ! -e $HISTFILE ]]; then
		touch "$HISTFILE"
	fi

	# Clear old history.
	history -c

	# "Initialize" the display.
	# i.e draw_main && prompt
	clear

	clear_output
	to_top
	draw_header
	draw_box
	draw_sidebar
	to_bottom
}

echo "OK"
