#!/usr/bin/env bash
NEWLINE_SUBSTITUTE='`'
FUNC_REGEX='/func.*?\{(.*?)(func.*)/ms'
SELF_CLOSURE_REGEX='/('$NEWLINE_SUBSTITUTE'.*?\{[^\}]*?\sin.*?\})(.*)/ms'
HAS_SELF_REGEX='self\.'
WEAK_REGEX="\[[[:space:]]*weak[[:space:]]*self[[:space:]]*\]"
UNOWNED_REGEX="\[[[:space:]]*unowned[[:space:]]*self[[:space:]]*\]"

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
							if ! [[ $closure =~ $WEAK_REGEX || $closure =~ $UNOWNED_REGEX ]] ; then
				
							
							with_lines=`echo "$closure" | tr "$NEWLINE_SUBSTITUTE" '\n'`

							first=`echo "$with_lines"|head -n 1`
							possible_start=`grep -n "$first" $filename | cut -f1 -d:`
							

							
							number_of_lines=`echo "$with_lines" | wc -l`
							
							while read -r start; do
								found=true
								for ((i = 1 ; i < $number_of_lines-1 ; i++ ));
									do
									
									file_top=$(($i+$start-1))
									file_line=`echo "$file" | head -n "$(($file_top+1))" | tail -1 | sed -e 's/^[ \t]*//'`
									line=`echo "$with_lines" | head -n "$(($i+1))" | tail -1 | sed -e 's/^[ \t]*//'`

									
									if  [[ "$line" != "$file_line" ]] ; then
										found=false
										break
									fi
									done

									if [[ $found == true ]]; then
										filename_only="${filename##*/}"
										echo -e "\e[31m\e[4mPossible strong retain cycle in \e[1m$filename_only\e[0m\e[31m\e[4m on line $start:\e[0m"
										break
									fi

		    			done <<< "$possible_start"

							#yellow_start='\\e[33m'
							#yellow_end='\\e[0m'
							
							echo -e "$file" | head -n $(($start+$number_of_lines-1)) | tail -n $number_of_lines #|  sed "s/self/$yellow_startself$yellow_end/g"
				   		#echo -e "\n\n"
				   		fi
					fi

				done
		done

	fi
}




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








