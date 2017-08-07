#!/usr/bin/env bash

#######################################################################
## File         : inp_rename.sh
## 
## Description  : The script responsible for renaming files sent from
##		  an input channel according to the inp_rename.cfg file.
##
## Authors		: Ploumakis Thanos
##
## Release      : 22 March 2017
##
#######################################################################

#######################################################################
####################### global variables ##############################
config_path="${HOME}/config/inp_rename.cfg"
inp_path="${HOME}/channels/inp_rename"
tar_path="${HOME}/pool"
system_log="${HOME}/log"

## current time
now_day=$(date +"%d") 	# current date
now_mon=$(date +"%m") 	# current month
now_year=$(date +"%Y") 	# current year 
now_sec=$(date +"%S") 	# current seconds
now_min=$(date +"%M") 	# current minute
now_hour=$(date +"%H") 	# current hour
now_time="${now_hour}:${now_min}:${now_sec}"
now_date="${now_day}.${now_mon}.${now_year}"

declare -A assoc_list
##################### END global variables ############################
#######################################################################


#######################################################################
## function clear_screen(void)
##
## Clears terminal.
#######################################################################
function clear_screen {
	/usr/bin/env clear
}
#######################################################################


#######################################################################
## function print_intro_msg(void)
##
## Prints the introduction message to the inp_rename compontent.
#######################################################################
function print_intro_msg {
	echo -e " \ninp_rename Component"
	echo -e " System Date-Time: ${now_date} - ${now_time}"
}
#######################################################################


#######################################################################
## function print_version(void)
##
## Prints current script version.
#######################################################################
function print_version {
	clear_screen
	print_intro_msg
	echo -e " Current version : 1.1"
	echo -e " Executable Type : Bash Shell Script"
	echo -e " Release Date    : 22 March 2017\n"
}
#######################################################################


#######################################################################
## function print_usage(void)
##
## Prints the help message.
#######################################################################
function print_usage {
	clear_screen
	print_intro_msg
	echo -e " --- NAME ---\n"
	echo -e "  inp_rename - System Script of inp_rename Component\n"
	echo -e " --- SYNOPSIS ---\n"
	echo -e "  inp_rename [OPTION] ...\n"
	echo -e " --- DESCRIPTION ---\n"
	echo -e "  '-v' or '--version'\n"
	echo -e "     Prints the current version information. This option"
	echo -e "     can not be combined.\n"
	echo -e "  '-h' or '--help'\n"
	echo -e "     Prints the help message. This option can not be"
	echo -e "     combined.\n"
	echo -e "  ' <filename> \n"
	echo -e "     Renames the file given and moves it to the"
	echo -e "     appropriate directory. This option cannot be "
	echo -e "     combined. Using this option in conjuction with"
	echo -e "     incron's command 'IN_CLOSE_WRITE' is suggested."
	echo -e "     \n"
}
#######################################################################


#######################################################################
## function print_invalid_args(void)
##
## This function prints error message of invalid given command-line
## arguments.
#######################################################################
function print_invalid_args {
	print_intro_msg
	echo -e " (X) Invalid input argument or argument combination"
	echo -e " (!) Please type -h or --help to view the help message\n"
}
#######################################################################


#######################################################################
## function read_config(void)
##
## Gets settings from the appropriate configuration file.
#######################################################################
function read_config {
	while IFS='' read -r line || [[ -n $line ]]; do
		[[ "${line}" =~ ^#.*$ ]] && continue
		[[ -z "${line}" ]] && continue
		temp_arr=($(echo ${line}))
		if [ "${#temp_arr[@]}" -eq "2" ]; then assoc_list["${temp_arr[0]}"]="${temp_arr[1]}"			
		else echo "  line problem"; continue; fi
	done < "${config_path}"
}
#######################################################################


#######################################################################
## function print_missing(void)
##
## Prints in stderr when the directory $HOME cannot be found.
#######################################################################
function print_missing {
	>&2 echo -e "$HOME directory not found."
}
#######################################################################


#######################################################################
## function write_log_msg(string log_msg)
##
## This function takes as argument a string and write it to log file
## The default log file is in variable ${system_log}/[date].log.
## The output format is "[ time ] log_message".
## As a caller the only obligation is to pass the message, function
## does the appropriate checks.
#######################################################################
function write_log_msg {
    lock_file="${HOME}/tmp/.inp_rename.pid"
    until (umask 222; echo $$ > ${lock_file}) 2>/dev/null   # try to set lock
    do
        sleep 2 # wait 2 seconds until next try
    done
    echo -e "[$(date +'%H'):$(date +'%M'):$(date +'%S')] ${1}" >> "${system_log}/inp_rename/$(date +'%Y')$(date +'%m')$(date +'%d').log"
    rm -f ${lock_file}      # unlock file
}
#######################################################################


#######################################################################
## function contains_str(string str, string substr)
##
## Returns 0 if the specified string contains the specified substring,
## otherwise returns 1.
#######################################################################
function contains_str {
    local string="${1}"
    local substring="${2}"
    if test "${string#*$substring}" != "$string"; then 
    	return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}
#######################################################################


#######################################################################
## function find_assoc_key(string assoc_string_key)
##
## Find in global variable assoc_list the relative key according to the
## argument assoc_string_key. If it exists returns 0 else returns 1.
## This function must called after the successfull reading of inp_rename.cfg file.
#######################################################################
function find_assoc_key {
	for i in "${!assoc_list[@]}"
	do
  		if contains_str ${1} ${i}; then return 0
  		else continue; fi 
	done
	return 1
}
#######################################################################


#######################################################################
## function get_assoc_key(string assoc_string_key)
##
## Find in global variable assoc_list the relative key according to the
## argument assoc_string_key. If exists returns the key. 
## This function must called after the successfull reading of inp_rename.cfg file.
#######################################################################
function get_assoc_key {
	for i in "${!assoc_list[@]}"
	do
  		if contains_str ${1} ${i}; then echo ${i}
  		else continue; fi 
	done
}
#######################################################################


#######################################################################
## function rename_file (string absolute_filename)
##
## Renames given file using the new naming standard.
#######################################################################
function rename_file {
	if read_config; then
		base_file_name=$(basename ${1})
		if [[ $base_file_name == x* ]]; then return 0
		elif [[ $base_file_name == X* ]]; then return 0
		elif [[ ${base_file_name: (-4)} == ".tmp" ]]; then return 0
		elif find_assoc_key ${base_file_name}; then
			assoc_key=$(get_assoc_key ${base_file_name})
			/usr/bin/rename ${inp_path}/${assoc_key} ${tar_path}/${assoc_list["${assoc_key}"]} ${inp_path}/${base_file_name}
			if [ "$?" -eq 0 ]; then
				write_log_msg "INFO: Renamed ${assoc_key} -> ${assoc_list[${assoc_key}]}"
			else
				write_log_msg "ERROR: Rename not successfull for ${1}."
			fi
		else
			mv "${1}" "${HOME}/channels/unrouted/${base_file_name}" && write_log_msg "INFO: Missing rename value. File ${base_file_name} moved to unrouted directory."
		fi
	else
		write_log_msg "ERROR: Could not read inp_rename.cfg configuration file."
		exit -1
	fi 
}
#########################################################################


##########################################################################
########################## MAIN PROCEDURE ################################
##########################################################################

if [ "$#" -eq 1 ]; then
	if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then print_usage
	elif [ "$1" = "--version" ] || [ "$1" = "-v" ]; then print_version
	elif [ -f "${1}" ]; then
		if [ -d "${HOME}" ]; then
			rename_file ${1}
		else
			print_missing
		fi	
	else 
		print_invalid_args
	fi
else
	print_invalid_args
fi

##########################################################################
######################## END MAIN PROCEDURE ##############################
##########################################################################
