#! /bin/bash

DAYS=${1:-1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}
YEARS=${2:-2018,2019,2020}
DEFINITIONS="-D test"
IFS=',' read -ra SPLIT_DAYS <<< "$DAYS"
for day in "${SPLIT_DAYS[@]}"; do
    DEFINITIONS="$DEFINITIONS -D day$day"
done
IFS=',' read -ra SPLIT_YEARS <<< "$YEARS"
for year in "${SPLIT_YEARS[@]}"; do
    DEFINITIONS="$DEFINITIONS -D year$year"
done
echo $DEFINITIONS
haxe -D test -D days=$DAYS -D years=$YEARS $DEFINITIONS build.hxml