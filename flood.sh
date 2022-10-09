#!/usr/bin/env bash

function drawGoal(){
    clear
echo "Goal:
* The game is won when the entire
board is flooded with a single color
within the maximum number of moves.
* The flooded area consists of all
same-color tiles connected to the
tile in the top-left corner.
* Extend the flooded area by
changing its color to absorb the 
neighbouring tiles with the new color."
    read -s -n 1
    drawField
}

function drawHelp(){
echo "flood [-ht] [-b boardsize] [-c nrcolors] [-l layout] [-s seed]

  -h,--help    display this help text
  -t,--tight   use tight board layout

  -b,--board   integer in set 4:2:26 representing the board size
  -c,--colors  integer in set 3:8 representing the nr of colors
  -l,--layout  string in the set {colors, letters, numbers} representing
               the board layout
  -s,--seed    integer seed for the pseudo-random number generator"
}

function keyBindingsBoard(){
clear
echo "Board key bindings:

 | Key               | Action                     |
 |:-----------------:|:--------------------------:|
 | r,1               | change color to red        |
 | g,2               | change color to green      |
 | y,3               | change color to yellow     |
 | b,4               | change color to dark blue  |
 | m,5               | change color to magenta    |
 | c,6               | change color to cyan       |
 | d,7               | change color to dark gray  |
 | w,8               | change color to light blue |
 | h,left            | move selection left        |
 | l,right           | move selection right       |
 | j,enter,space,tab | apply selection            |
 | u                 | undo previous change       |
 | e                 | enter seed                 |
 | a                 | replay game                |
 | n                 | new game                   |
 | q                 | quit game                  |
 | z                 | continue beyond GAME OVER  |
 | s                 | change settings            |
 | i                 | display goal               |
 | x                 | redraw screen              |
 | ?                 | display key bindings       |"
    read -s -n 1
    drawField
}

function keyBindingsMenu(){
clear
echo "Settings menu key bindings:

 | Key               | Action                         |
 |:-----------------:|:------------------------------:|
 | h,left            | move selection left            |
 | l,right           | move selection right           |
 | j,down            | move to next settings item     |
 | k,up              | move to previous settings item |
 | a,enter,space,tab | apply changes                  |
 | x                 | discard changes                |
 | ?                 | display key bindings           |
 | q                 | quit game                      |"
    read -s -n 1
}

nrColors=(3 4 5 6 7 8)
fieldSize=(4 6 8 10 12 14 16 18 20 22 24 26)
tileTypes=("colors" "letters" "numbers")
layout=("normal" "tight")

settingInd=(3 5 0 0)
settingType=("nr colors: " "field size:" "tiles:     " "layout:    ")

while [ $# -gt 0 ]; do
    case "$1" in
        '-h'|'--help') drawHelp; exit;;
        '-t'|'--tight') settingInd[3]=1; shift;;
        '-b'|'--board')
            if [[ "$2" =~ ^(4|6|8|10|12|16|18|20|22|24|26)$ ]]; then
                settingInd[1]=$(($2/2-2))
            else
                echo "invalid input for board size [4:2:26]: $2"
                exit 1
            fi
            shift 2;;
        '-c'|'--colors')
            if [[ "$2" =~ ^[3-8]$ ]]; then
                settingInd[0]=$(($2-3))
            else
                echo "invalid input for number of colors [3:8]: $2"
                exit 1
            fi
            shift 2;;
        '-l'|'--layout')
            if [ "$2" == colors ]; then
                settingInd[2]=0
            elif [ "$2" == letters ]; then
                settingInd[2]=1
            elif [ "$2" == numbers ]; then
                settingInd[2]=2
            else
                echo "invalid input for board layout: $2"
                exit 1
            fi
            shift 2;;
        '-s'|'--seed') seed="$2"; shift 2;;
        *) echo "unknown input: $1"; exit 1;;
    esac
done

function createField(){

    status=1
    nrColumns=${fieldSize[settingInd[1]]}
    nrRows=${fieldSize[settingInd[1]]}
    nc=${nrColors[settingInd[0]]}
    [ ${layout[settingInd[3]]} == normal ] && tile=" " || tile=""
    case ${tileTypes[settingInd[2]]} in
        colors)
            elements=( "\\e[41m" "\\e[42m" "\\e[103m" "\\e[44m" "\\e[45m" "\\e[106m" "\\e[100m" "\\e[104m" )
            tile+=" "
            selectionText="${elements[@]::nc}"
            selectionText="  ${selectionText//m/m \\e[0m}";;
        letters)
            elements=( "R" "G" "Y" "B" "M" "C" "D" "W" )
            selectionText="${elements[@]::nc}"
            selectionText="  \e[1m${selectionText// /\\e[0m \\e[1m}\e[0m";;
        numbers)
            elements=( "1" "2" "3" "4" "5" "6" "7" "8" )
            selectionText="${elements[@]::nc}"
            selectionText="  \e[1m${selectionText// /\\e[0m \\e[1m}\e[0m";;
    esac
    infoText=()
    #nrMoves=$((54*nc*(nrColumns+nrRows)/(7*(26+26))))
    nrMoves=$((25*nc*(nrColumns+nrRows)/(6*(14+14))))
    [ $# -gt 0 ] && seed=$1 || seed=$((RANDOM))
    RANDOM=$seed
    field=()
    undoHistory=()
    local length=$((nrColumns*nrRows))
    local i=0
    while [ $i -lt $length ]; do
        field+=($((RANDOM%nc)))
        ((i++))
    done
    border=(1 $nrColumns)
    color=${field[0]}
    [ $color -ne 0 ] && selection=0 || selection=1
    field[0]=9
    updateField $color
}

function drawField(){
    row=
    local i=0
    while [ $i -lt $nrRows ]; do
        row+="indent${field[@]:i*nrColumns:nrColumns} \e[0m\n"
        ((i++))
    done
    local i=$((nc-1))
    while [ $i -ge 0 ]; do
        row=${row//$i /${elements[i]} }
        ((i--))
    done
    [ ${tileTypes[settingInd[2]]} == colors ] && flooded=${elements[color]} || flooded="\e[7m${elements[color]}\e[0m"
    row=${row//9 /$flooded }; row=${row// /$tile}; row=${row//\\e[0m \\e[7m/ \\e[7m}
    clear
    printf "$selectionText\n${row//indent/ } moves:%d seed:%d\n\e[2m ?: display key bindings\e[0m\n" $nrMoves $seed
    [ ${#infoText[@]} -gt 0 ] && showInfo
}

function updateField(){
    changed=1
    while [ ${#border[@]} -gt 0 ] && [ $changed -eq 1 ]; do
        changed=0
        declare -A newborder
        for i in ${border[@]}; do
            if [ ${field[i]} -eq $1 ]; then
                field[i]=9
                # check tile above, below, left and right, respectively
                ((i>=nrColumns && field[i-nrColumns]!=9)) && newborder[$((i-nrColumns))]=1 && changed=1
                ((i<nrColumns*(nrRows-1) && field[i+nrColumns]!=9)) && newborder[$((i+nrColumns))]=1 && changed=1
                ((i%nrColumns && field[i-1]!=9)) && newborder[$((i-1))]=1 && changed=1
                ((i%nrColumns!=nrColumns-1 && field[i+1]!=9)) && newborder[$((i+1))]=1 && changed=1
            else
                newborder[$i]=1
            fi
        done
        border=(${!newborder[@]})
        unset newborder
    done
    color=$1
    local fld="${field[@]}" brdr="${border[@]}"
    undoHistory+=($color ${fld// /;} ${brdr// /;})
    if [ $color -eq $selection ]; then
        [ $selection -eq 0 ] && selection=$((selection+1)) || selection=$((selection-1))
    fi
    [ $nrMoves -eq 0 ] && [[ "${field[@]//9}" =~ [^\ ] ]] && status=0 && infoText=("GAME OVER")
    if [[ ! "${field[@]//9}" =~ [^\ ] ]]; then
        if [ $nrMoves -ge 0 ]; then
            status=0 && infoText=`printf "  in %d moves" $((7*nc*nrRows/24-nrMoves))` && infoText=("CONGRATULATIONS" " board flooded" "$infoText")
        else
            status=0 && infoText=`printf "  in %d moves" $((7*nc*nrRows/24-nrMoves))` && infoText=("  FINALLY ;)" " board flooded" "$infoText")
        fi
    fi
    drawField
}

function showInfo(){
    IFSOLD="$IFS"
    IFS=$'\n'
    width=0
    for i in ${infoText[@]}; do
        [ $width -lt ${#i} ] && width=${#i}
    done
    locy=$((nrRows/2-${#infoText[@]}/2))
    locx=$((1+(nrColumns*${#tile}-$width-2)/2))
    #locx=$((locx%2?locx:locx+1))
    locx=$((locx>0?locx:0))
    local textbox="\e[0;1;40m %-${width}s \e[0m"
    i=0
    while [ $i -lt ${#infoText[@]} ]; do
        tput 'cup' $((locy+i)) $locx
        printf "$textbox" "${infoText[i]}"
        ((i++))
    done
    IFS="$IFSOLD"
}

function drawSettings(){
    clear
    local orig=$settingNr
    nrSettings=${#settingInd[@]}
    settingNr=$((nrSettings-1))
    while [ $settingNr -ge 0 ]; do
        drawSettingLine 'off'
        ((settingNr--))
    done
    [ -z "$orig" ] || settingNr=$orig
    tput 'cup' $nrSettings 0; printf "\\e[2ma: apply changes\nx: discard changes\nq: quit\n?: display key bindings\\e[0m"
}

function changeSettings(){

    settingIndOrig=(${settingInd[@]})
    drawSettings
    settingNrNew=0
    
    while :;do

        settingNr=$settingNrNew
        drawSettingLine
        
        read -s -n 1 action
        
        case $action in
            'l'|'C') ((settingInd[settingNr]++)); settingInd[settingNr]=$((settingInd[settingNr]%${#settingItems[@]}));;
            'h'|'D') ((settingInd[settingNr]--)); settingInd[settingNr]=$((settingInd[settingNr]<0?${#settingItems[@]}-1:settingInd[settingNr]));;
            'j'|'B') drawSettingLine 'off'; settingNrNew=$(((settingNr+1)%nrSettings));;
            'k'|'A') drawSettingLine 'off'; settingNrNew=$((settingNr==0?nrSettings-1:settingNr-1));;
            'x') settingInd=(${settingIndOrig[@]}); break;;
            'a'|'') createField; break;;
            'q') nrRows=5; exit;;
            '?') keyBindingsMenu; drawSettings;;
        esac
        
    done
    
    drawField
    
}

function drawSettingLine(){
    
    if [ $settingNr -eq 0 ]; then
        settingItems=(${nrColors[@]})
    elif [ $settingNr -eq 1 ]; then
        settingItems=(${fieldSize[@]})
    elif [ $settingNr -eq 2 ]; then
        settingItems=(${tileTypes[@]})
    elif [ $settingNr -eq 3 ]; then
        settingItems=(${layout[@]})
    fi
    
    local settingText=" ${settingItems[@]} "
    tput 'cup' $settingNr 0
    if [ $# -gt 0 ]; then
        printf "\\e[1m${settingType[settingNr]}${settingText/ ${settingItems[${settingInd[settingNr]}]} / \\e[4m${settingItems[${settingInd[settingNr]}]}\\e[24m }\\e[0m"
    else
        printf "\\e[1m${settingType[settingNr]}${settingText/ ${settingItems[${settingInd[settingNr]}]} /[\\e[4m${settingItems[${settingInd[settingNr]}]}\\e[24m]}\\e[0m"
    fi
    
}

trap 'tput "cup" $((nrRows+2)) 0; echo -e "\e[0m"; stty echo; tput cnorm; exit' EXIT INT

#[ `tput lines` -lt 27 ] && clear && printf "terminal to small: `tput lines` lines (required: 27)" && exit 1
#[ `tput cols` -lt 27 ] && clear && printf "terminal to small: `tput cols` columns (required: 55)" && exit 1

stty -echo
tput civis

[ -z "$seed" ] && createField || createField "$seed"
while :; do

    tput 'cup' 0 $((1+2*selection)); printf "\e[1m["
    tput 'cup' 0 $((3+2*selection)); printf "]\e[0m"
    read -s -n 1 action
    tput 'cup' 0 $((1+2*selection)); printf " "
    tput 'cup' 0 $((3+2*selection)); printf " "

    case "$action" in
        'r'|'1') if [ $status -ne 0 ] && [ $color -ne 0 ] && [ $nc -ge 1 ]; then ((nrMoves--)); updateField 0; fi;;
        'g'|'2') if [ $status -ne 0 ] && [ $color -ne 1 ] && [ $nc -ge 2 ]; then ((nrMoves--)); updateField 1; fi;;
        'y'|'3') if [ $status -ne 0 ] && [ $color -ne 2 ] && [ $nc -ge 3 ]; then ((nrMoves--)); updateField 2; fi;;
        'b'|'4') if [ $status -ne 0 ] && [ $color -ne 3 ] && [ $nc -ge 4 ]; then ((nrMoves--)); updateField 3; fi;;
        'm'|'5') if [ $status -ne 0 ] && [ $color -ne 4 ] && [ $nc -ge 5 ]; then ((nrMoves--)); updateField 4; fi;;
        'c'|'6') if [ $status -ne 0 ] && [ $color -ne 5 ] && [ $nc -ge 6 ]; then ((nrMoves--)); updateField 5; fi;;
        'd'|'7') if [ $status -ne 0 ] && [ $color -ne 6 ] && [ $nc -ge 7 ]; then ((nrMoves--)); updateField 6; fi;;
        'w'|'8') if [ $status -ne 0 ] && [ $color -ne 7 ] && [ $nc -ge 8 ]; then ((nrMoves--)); updateField 7; fi;;
        'l'|'C') [ $status -ne 1 ] && continue; ((selection++)); ((selection%nc==color%nc)) && ((selection++)); selection=$((selection%nc));;
        'h'|'D') [ $status -ne 1 ] && continue; ((selection--)); (((selection+nc)%nc==color%nc)) && ((selection--)); selection=$((selection<0?selection+nc:selection));;
        'j'|'') if [ $status -ne 0 ]; then ((nrMoves--)); updateField $selection; fi;;
        'n'|'N') createField;;
        'a') createField "$seed";;
        's') changeSettings;;
        'e') clear; stty echo; tput cnorm; read -p "seed: " seed; stty -echo; tput civis; createField "$seed";;
        '?') keyBindingsBoard;;
        'x'|'X') drawField;;
        'i'|'I') drawGoal;;
        'z'|'Z') if [ "${infoText[0]}" == "GAME OVER" ]; then status=1; unset infoText; drawField; fi;;
        'q'|'Q') break ;;
        'u')
            if [ ${#undoHistory[@]} -gt 3 ]; then
                ((nrMoves++))
                color=${undoHistory[-6]}; field=(${undoHistory[-5]//;/ }); border=(${undoHistory[-4]//;/ });
                for i in {1..3}; do unset undoHistory[-1]; done
                if [ $selection -eq $color ]; then [ $selection -eq 0 ] && selection=$((selection+1)) || selection=$((selection-1)); fi
                status=1; unset infoText; drawField
            fi;;
    esac

done

