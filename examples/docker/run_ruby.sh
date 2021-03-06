#!/bin/bash

ping_url="https://api.rosette.com/rest/v1"
retcode=0
errors=( "Exception" "processingFailure" "badRequest" "ParseError" "ValueError" "SyntaxError" "AttributeError" "ImportError" )

#------------ Start Functions --------------------------

#Gets called when the user doesn't provide any args
function HELP {
    echo -e "\nusage: source_file.rb API_KEY [ALT_URL]"
    echo "  API_KEY      - Rosette API key (required)"
    echo "  FILENAME     - Ruby source file (optional)"
    echo "  ALT_URL      - Alternate service URL (optional)"
    exit 1
}

if [ ! -z ${ALT_URL} ]; then
    ping_url=${ALT_URL}
fi

#Checks if Rosette API key is valid
function checkAPI {
    match=$(curl "${ping_url}/ping" -H "X-RosetteAPI-Key: ${API_KEY}" |  grep -o "forbidden")
    if [ ! -z $match ]; then
        echo -e "\nInvalid Rosette API Key"
        exit 1
    fi
}

#Checks for valid url
function validateURL() {
    match=$(curl "${ping_url}/ping" -H "X-RosetteAPI-Key: ${API_KEY}" |  grep -o "Rosette API")
    if [ "${match}" = "" ]; then
        echo -e "\n${ping_url} server not responding\n"
        exit 1
    fi
}

function runExample() {
    echo -e "\n---------- ${1} start -------------"
    result=""
    if [ -z ${ALT_URL} ]; then
        result="$(ruby ${1} ${API_KEY} 2>&1 )"
    else
        result="$(ruby ${1} ${API_KEY} ${ALT_URL} 2>&1 )"
    fi
    echo "${result}"
    echo -e "\n---------- ${1} end -------------"
    for err in "${errors[@]}"; do
        if [[ ${result} == *"${err}"* ]]; then
            retcode=1
        fi
    done
}

#------------ End Functions ----------------------------

#Gets API_KEY, FILENAME and ALT_URL if present
while getopts ":API_KEY:FILENAME:ALT_URL" arg; do
    case "${arg}" in
        API_KEY)
            API_KEY=${OPTARG}
            ;;
        ALT_URL)
            ALT_URL=${OPTARG}
            ;;
        FILENAME)
            FILENAME=${OPTARG}
            ;;
    esac
done

validateURL

#Intall rosette_api from RubyGems
gem install rosette_api

#Copy the mounted content in /source to current WORKDIR
cp /source/examples/*.* .

#Run the examples
if [ ! -z ${API_KEY} ]; then
    checkAPI
    if [ ! -z ${FILENAME} ]; then
        echo -e "\nRunning example against: ${ping_url}\n"
        runExample ${FILENAME}
    else
        echo -e "\nRunning examples against: ${ping_url}\n"
        for file in *.rb; do
            runExample ${file}
        done
    fi
else
    HELP
fi

exit ${retcode}
