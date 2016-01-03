#!/usr/bin/env bash
NEWLINE_SUBSTITUTE='`'
nl=$NEWLINE_SUBSTITUTE
FUNC_REGEX='/func.*?\{(.*?)(func.*)/ms'
SELF_CLOSURE_REGEX='/\`([^\`]*?\{[^\}]*?\sin[\s\`].*?\})(.*)/ms'
HAS_SELF_REGEX='self\.'
WEAK_REGEX="\[[[:space:]]*weak[[:space:]]*self[[:space:]]*\]"
UNOWNED_REGEX="\[[[:space:]]*unowned[[:space:]]*self[[:space:]]*\]"
FOR_REGEX="[[:space:]]+for[[[:space:]]*"
RETURN_REGEX="[[:space:]]+return[[[:space:]]*"

function match_all {
    MATCHES=() 
    local STR=$1 RE=$2
    while [[ -n $STR ]]; do
				PRINT_MATCH='print $1 if '$RE
				PRINT_REST='print $2 if '$RE

				#echo -e "$STR" | perl -ne "$PRINT_MATCH"


				match=`echo -e "$STR" | perl -ne "$PRINT_MATCH"`
				
				size=${#match} 
				
				if [[ $size > 0 ]]; then
					MATCHES+=("$match")
				fi

        STR=`echo -e $STR | perl -ne "$PRINT_REST"` 

    done

}

function find_occurence_line_position {
	local LINES=$1
	local FIRST_LINE=`echo "$LINES"|head -n 1`	

	local possible_start=`grep -n "$FIRST_LINE" $filename | cut -f1 -d:`
	local LINES_NUMBER=`echo "$LINES" | wc -l`
	


	while read -r start; do

		found=true
		for ((i = 1 ; i < $LINES_NUMBER-1 ; i++ ));
			do
			
			file_top=$(($i+$start-1))
			file_line=`echo "$file" | head -n "$(($file_top+1))" | tail -1 | sed -e 's/^[ \t]*//'`
			line=`echo "$LINES" | head -n "$(($i+1))" | tail -1 | sed -e 's/^[ \t]*//'`
			
			
			if  [[ "$line" != "$file_line" ]] ; then
				found=false
				break
			fi
			done

			if [[ $found == true ]]; then
				
				break
			fi

	done <<< "$possible_start"

	LINE_POSITION=$start
}

function check_for_retain_cycles {
	 filename=$1


    extension="${filename##*.}"
	if [[ $extension == "swift" ]]; then

	
		file=`cat "$filename"`
		

		contents=$(cat "$filename" | tr '\n' "$NEWLINE_SUBSTITUTE")

		match_all "$contents" "$FUNC_REGEX"
		functions=( "${MATCHES[@]}" )

		for match in "${functions[@]}"
		do
				

		   	match_all "$match" "$SELF_CLOSURE_REGEX"
				closures=( "${MATCHES[@]}" )

				for closure in "${closures[@]}"
				do


					if [[ $closure =~ $HAS_SELF_REGEX ]]; then

							closure_newlines=`echo "$closure" | tr "$NEWLINE_SUBSTITUTE" '\n'`
							first=`echo "$closure_newlines"|head -n 1`
							number_of_lines=`echo "$closure_newlines" | wc -l`

							if ! [[ $closure =~ $WEAK_REGEX || $closure =~ $UNOWNED_REGEX || $first =~ $FOR_REGEX || $first =~ $RETURN_REGEX ]] ; then
							
							find_occurence_line_position "$closure_newlines"

		    			filename_only="${filename##*/}"
		    			echo -e "\e[31m\e[4mPossible strong retain cycle in \e[1m$filename_only\e[0m\e[31m\e[4m on line $LINE_POSITION:\e[0m"

		    			if [[ -n $LINE_POSITION ]]; then

							
							echo -e "$file" | head -n $(($start+$number_of_lines-1)) | tail -n $number_of_lines 

							#Temporary bug fix
				   	else
				   			echo "$closure_newlines"
				   	fi
				   		fi
					fi

				done
		done

	fi
}


#Program
directory="."

if [[ $1 ]]; then
	directory=$1;
else
	exit 1;
fi


if [ -d "$directory" ]; then
	for name in $directory/*
		do
			check_for_retain_cycles "$name"
		done
else
		check_for_retain_cycles "$directory"
fi	








