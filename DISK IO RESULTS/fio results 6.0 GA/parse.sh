#!/bin/bash

RESULTS_FILE_NAME=$1


convert() {
local CNV1
local CNV2
local RESULT
  if [ ! -z $1 ] && [ ! -z $2 ]; then
    CNV1=$1
    echo "ARG1: $CNV1"
    CNV2=$2
    echo "ARG2: $CNV2"
    if [ $CNV2 == "MB" ]; then
      let RESULT=$CNV1*1024*1024
    elif [ $CNV2 == "KB" ]; then
      let RESULT=$CNV1*1024
    elif [ $CNV2 == "B" ]; then
      let RESULT=$CNV1
    else
      RESULT="0"
    fi
    echo "RESULT: $RESULT"
    return $RESULT
  fi
}
# convert $1 $2

cat $RESULTS_FILE_NAME |  grep -v "^Mode QD" | grep -e iops -e iodepth | \
sed "s/^ *\([a-z]*\) *: io=\([0-9]*[\.0-9]*\)\([KM]*B\), bw=\([0-9]*[\.0-9]*\)\([KM]*B\/s\), iops=\([0-9]*\), runt= *\([0-9]*\)msec*$/$MODE $QD \1 \2 \3 \4 \5 \6 \7/g" | \
sed 's/\([a-z]\+\): .*rw=\([a-z]\+\), .*iodepth=\([0-9]\+\)$/\1 \2 \3/g'


#sed "s/^ *\([a-z]*\) *: io=\([0-9]*[\.0-9]*\)[KM]*B, bw=\([0-9]*[\.0-9]*\)KB\/s, iops=\([0-9]*\), runt= *\([0-9]*\)msec*$/$MODE $QD \1 \2 \3 \4 \5/g"
#echo "read: (g=0): rw=read, bs=4K-4K/4K-4K/4K-4K, ioengine=libaio, iodepth=1"

exit 0;