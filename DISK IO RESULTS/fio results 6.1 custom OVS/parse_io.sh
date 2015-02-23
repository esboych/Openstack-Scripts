#!/bin/bash

#RESULTS_FILE_NAME=$1
filename="./ioresults.txt"

#awk '/^BLOCKSIZE/{print $1 $2}' $filename # print blocksize info
#awk '/^( )*bw/{print $5 $6}' $filename # print bandwith 

sed -i 's/= /=/g' $filename  #first make initial file more uniform by deleting blanks after "="
sed -i 's/=  /=/g' $filename  #first make initial file more uniform by deleting blanks after "="


awk '/^BLOCKSIZE/{print $1 $2}                  #print blocksize
	    /^(read|write|randread|randwrite|rw|randrw): \(groupid=0/{print $1}
	    /^( )*bw/{print $7 $8}' $filename   #print results for every blocksize
#awk '/^BLOCKSIZE/{print $1 $2}' $filename