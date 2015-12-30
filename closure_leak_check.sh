#!/bin/bash  

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


filename=""
NEWLINE_SUBSTITUTE='`'

if [[ $1 ]]; then
	filename=$1;
else
	exit 1;
fi

contents=$(cat "$filename" | tr '\n' "$NEWLINE_SUBSTITUTE")


FUNC_REGEX='/func.*?\{(.*?)(func.*)/ms'
SELF_CLOSURE_REGEX='/(\{[^\}]*?\sin.*?\})(.*)/ms'
HAS_SELF_REGEX='self\.'


WEAK_REGEX="\[[[:space:]]*weak[[:space:]]*self[[:space:]]*\]"
UNOWNED_REGEX="\[[[:space:]]*unowned[[:space:]]*self[[:space:]]*\]"


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
					

					file=`cat "$filename"`
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
								echo "Possible strong retain cycle on line $start:"
								break
							fi

    			done <<< "$possible_start"

					
					echo "$file" | head -n $(($start+$number_of_lines-1)) | tail -n $number_of_lines
		   		#echo -e "\n\n"
		   		fi
			fi

		done
done
