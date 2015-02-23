#!/bin/bash

TEST_FILE_NAME="./fio_image_BIG.dat"
RUNTIME=10
FSYNC=0
MODE_ALL="read write randread randwrite rw randrw"
BLOCKSIZE_ALL="512 1k 2k 4k 64k 256k 512k 1m"
QD_ALL="1"


echo "================================="
echo "Mode QD blocksize io bw iops runt"

for BLOCKSIZE in $BLOCKSIZE_ALL
do
  echo "BLOCKSIZE: $BLOCKSIZE"
  echo "BLOCKSIZE: $BLOCKSIZE" >&2
  for MODE in $MODE_ALL
  do
    echo "<---->MODE: $MODE"
    echo "<---->MODE: $MODE" >&2
    for QD in $QD_ALL
    do
      echo "<--><------>QD: $QD"
      echo "<--><------>QD: $QD" >&2
      fio --name=$MODE --blocksize=$BLOCKSIZE --rw=$MODE --direct=1 --buffered=0 --ioengine=libaio --iodepth=$QD --fsync=$FSYNC --filename=./fio_image_BIG.dat --timeout=$RUNTIME --runtime=$RUNTIME \
#<----->| grep iops \
#<----->| sed "s/^ *\([a-z]*\) *: io=\([0-9]*[\.0-9]*\)[KM]*B, bw=\([0-9]*[\.0-9]*\)KB\/s, iops=\([0-9]*\), runt= *\([0-9]*\)msec*$/$MODE $QD \1 \2 \3 \4 \5/g"
      sync
      sleep 1
      echo
    done
    echo
  done
  echo
  echo
done


#  echo "  read : io=1508.0KB, bw=508627B/s, iops=124, runt=  3036msec" | sed 's/^.*, bw=\([.0-9]*[KM]*B\/s\), .*$/\1/g'

echo
echo
echo

exit 0;