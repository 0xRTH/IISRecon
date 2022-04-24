#! bash

# IISRecon
# Recon script to bruteforce IIS shortname to full name and find parameter

tmp="./.tmp"
wordlists="/Users/user/Documents/WordLists"
ext=(".asp" ".aspx" ".ash" ".ashx" ".config" ".html" ".wsdl" ".wadl" ".asmx" ".xml" ".zip" ".txt" ".asar" ".asax" ".mas")
LC_CTYPE=C && LANG=C
output="result.json"

mkdir $tmp

while getopts u:o: flag
do
    case "${flag}" in
        u) url=${OPTARG};;
        o) output=${OPTARG};;
    esac
done

domain="$(echo $url | cut -d "/" -f 3)"
jq --null-input \
--arg domain "$domain" \
'{"domain":{}}' > $output

##########FUNCTIONS##########

extractSn(){
    echo $1 | cut -d "~" -f 1 
}

dirBruteForce(){
    echo "bruteforcing "$shortName 
    grep -e "^"$shortName -r $wordlists | cut -d ":" -f 2| cut -d "." -f 1 | cut -d "/" -f 1| sort -uf > $tmp/$shortName"_list".txt
    echo $shortName >> $tmp/$shortName"_list".txt
    ffufResult="$(ffuf -u $url"/FUZZ/" -w $tmp/$shortName"_list".txt -s -fc 302)"
    if [[ ! -z $ffufResult ]]; then
        echo $ffufResult | tr " " "\n"| while read l; do
        echo "$(jq --arg ffufResult "$ffufResult" '.domain += {($ffufResult):{}}' $output)" > $output
        done
    else
        echo "$(jq --arg shortName "$1" '.domain += {($shortName):{}}' $output)" > $output
    fi
}

fileBruteForce(){
    extToUse=""
    echo "bruteforcing "$shortName 
    grep -e "^"$shortName -r $wordlists | cut -d ":" -f 2| cut -d "." -f 1 | cut -d "/" -f 1| sort -uf > $tmp/$shortName"_list".txt
    echo $shortName >> $tmp/$shortName"_list".txt
    shortExt="$(echo "$1" | cut -d "." -f 2 | cut -d "*" -f 1)"
    for e in "${ext[@]}"; do
        if [[ $e == ".""$shortExt" || $e == ".""$shortExt"* ]]; then
            if [[ -z "$extToUse" ]]; then
                extToUse=$e
            else
                extToUse=$extToUse","$e
            fi
        fi
    done
    if [[ -z $extToUse ]]; then
        extToUse=".""$shortExt"
    fi
    ffufResult="$(ffuf -u $url"/FUZZ/" -w $tmp/$shortName"_list".txt -s -e "$extToUse" -fc 302| sort -u)"
    if [[ ! -z $ffufResult ]]; then
        echo $ffufResult | tr " " "\n"| while read l; do
        echo "$(jq --arg ffufResult "$l" '.domain += {($ffufResult):[]}' $output)" > $output
        done
    else
        echo "$(jq --arg shortName "$1" '.domain += {($shortName):[]}' $output)" > $output
    fi
}

paramDiscovery(){
    echo "Bruteforcing parameter on "$url"/"$1
    arjun -u $url/$1 -oJ $tmp/arjun_$1.txt -q
    arjunResult="$(cat $tmp/arjun_$1.txt | jq --arg url "$url/$1" '.[($url)].params[]' | tr -d "\"")"
    if [[ ! -z $arjunResult ]]; then
        echo $arjunResult | tr " " "\n"| while read l; do
            echo "$(jq --arg arjunResult "$l" --arg file "$1" '.["domain"][($file)] += [($arjunResult)]' $output)" > $output
        done
    fi
    #echo "test"
}

##########PROGRAM##########

echo "Running Shortname Scan"
sns -u $url -s > $tmp/sub_sns.txt

cat $tmp/sub_sns.txt | while read l; do
    shortName="$(extractSn $l)"
    if [[ $l == *"Directory"* ]]; then
        dirBruteForce $l
        #echo "A"
    fi
    if [[ $l == *"File"* ]]; then
        file=""
        fileBruteForce $l
        #echo "A"
    fi
done

cat $output| jq '.domain' | grep "." | grep -v "~"| tr -d "\"{}\ :[],"| while read l; do
    if [[ ! -z $l ]]; then
        paramDiscovery $l
    fi
done

cat $output
rm -r $tmp/
