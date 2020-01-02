#!/bin/bash
# GrepSuzette
progName="$( basename "$0" )"
version=0.1

warn() { local fmt="$1"; shift; printf "$progName: $fmt\n" "$@" >&2; }
die () { local st="$?"; warn "$@"; exit "$st"; } 
define(){ IFS='\n' read -r -d '' ${1} || true; }

define helpString <<EOF
$progName v$version - Generate ctags for vim help files (doc/xxx.txt)
This allows showing a table of contents in tagbar.
Will output the tags for a help file to stdout
Public domain, 2016 GrepSuzette
Syntax: $progName inputfile
EOF

if [[ $# != 1 || $1 = -* ]]; then
    echo "$helpString"
    exit
else
    inputfile="$1"
    [[ -f $inputfile ]]   || die "'$inputfile' is not a file"
    [[ ! -d $inputfile ]] || die "'$inputfile' is a directory"
    [[ -r $inputfile ]]   || die "'$inputfile' is not readable"
fi

# turn case detection ON in regex
shopt -u nocasematch

# big title being preceded by =======
hasBigTitle=0
echo -e "!_TAG_FILE_FORMAT\t2"

# had problems with bkank lines
# IFS=$'\n' read -d '' -r -a filelines < "$inputfile"

# Bash, ksh93, mksh
unset -v arr i
while IFS= read -r; do
    filelines[i++]=$REPLY
done <"$inputfile"
[[ $REPLY ]] && filelines[i++]=$REPLY # Append unterminated data line, if there was one.

# If before 12% of the file there happens to be a ===== line,
# then start on this line, to ignore any weirdly formatted TOC
where=$( grep ^===\* "$inputfile" --line-number | head -n1 | cut -f1 -d':' )
if [ -n "$where" ]; then
    total=$(wc "$inputfile" -l | cut -f1 -d' ')
    if (( $where * 100 / $total <= 12 )); then
        echo OUCH: $where " / $total "
        filelines=("${filelines[@]:$(( $where - 1 ))}")
        # echo "${filelines[@]}"
    else 
        where=0
    fi
else
    where=0
fi
ln=$(( $where + 1 ))

# while IFS='' read -r nextline; do
for currentline in "${filelines[@]}"; do
    # || [[  "$previousline" =~ ^\<?$ && "$currentline" =~ ^([A-Z][A-Z][A-Z_ -]+)$  ]] \
    if [[ -n $passedonce ]] \
    && [[  "$previousline" =~ ^\<?$ && "$currentline" =~ ^([A-Z][A-Z][A-Z_ -]+)(	+)(.+)$ ]] \
    || [[  "$previousline" =~ ^\<?$ && "$currentline" =~ ^([A-Z][A-Z][A-Z_ :-]+)([^a-z]{4,}.{,28})?$  ]] \
    || [[  "$previousline" =~ ^\<?$ && $nextline =~ ^\<?$ && "$currentline" =~ ^([A-Z][A-Z][A-Z_ -]+)([	 ]+)(.+)  ]] \
    || [[  "$previousline" =~ ^\<?$ && $nextline =~ ^\<?$ && "$currentline" =~ ^([0-9]+\. [A-Z][a-zA-Z _-]+)(	+)(.+)  ]] \
    || [[ ( "$previousline" =~ ^====+$ || "$previousline" =~ ^-----+$ ) \
            &&   "$currentline" =~ ^( *[A-Z0-9][a-zA-Z0-9.][0-9]?[^	]+)((	+)([^	]+))? ]] \
    || [[ ( "$previousline" =~ ^====+$ || "$previousline" =~ ^-----+$ ) \
            &&   "$currentline" =~ ^(\*[0-9][0-9]?\.[0-9][0-9]?\*	+.*)$ \
    ]]; then
            offset=""
            found="${BASH_REMATCH[1]}"
    echo "PL $(($ln - 1)) ::: $previousline"
     echo "CL $ln ::: $currentline"
     echo "NL $(($ln+1)) ::: $nextline"
            if [[ "$previousline" == ===* ]]; then hasBigTitle=1; fi
            if [[ "$previousline" == ---* ]] || [[ -n $hasBigTitle && ! "$previousline" == ===* ]]; then 
                offset=" * "
            fi
            if [[ $found =~ ^([0-9]+\. *)(.*) ]]; then
                # Remove any numbered list item
                found="${BASH_REMATCH[2]}"
            elif [[ $found =~ ^(\*[0-9][0-9]?\.[0-9][0-9]?\*	+)(.*)$ ]]; then
                found="${BASH_REMATCH[2]}"
            fi
            found=${found,,}
            found=${found^}
            found=${found%:}
            echo -e "$offset$found\t$inputfile\t:$ln<CR>;\"\ts\tline:$ln\tsection:TOC"
    fi
    previousline="$currentline"
    currentline="$nextline"
    passedonce=1
    let ln+=1
done
# done < "$inputfile"
