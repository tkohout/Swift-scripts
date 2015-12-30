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
		
					echo "$closure" | tr "$NEWLINE_SUBSTITUTE" '\n'
		   		echo "-----------------"
		   		fi
			fi

		done
done
