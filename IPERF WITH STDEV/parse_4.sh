#!/bin/bash

apt-get install bc # not installed by default by Fuel

filename="./results.txt" # just a convention of input file name

sed -i 's/- /-/g' $filename # clean all broken indentation left by iperf

awk '/SUM/{print $1 $2 $3 " " $6 " " $7}' $filename # print only SUMs to archive them further

arr=( $(awk '/SUM/{print int($6)}' $filename )) # fill in array of intermediate SUMs

unset arr[${#arr[@]}-1] # delete last element containing Total SUM by iperf as the script calculate it by itself.

#sum all array elements:
sum=0
for i in ${arr[*]}; do
#echo $i "SUM: " $i
sum=$(($sum + $i))
done

#count the expected value
expv=$(($sum/${#arr[*]}))
echo "Expected value: " $expv

#calculate the sum of diff squares
sqsum=0
array_size=$arr[*]-1
for i in ${arr[*]}; do
sqsum=$((sqsum + (i-$expv)**2 ))
done

# finally: calc the std deviation
sqsum=$((sqsum/${#arr[*]})) #sum of diff squares divided by array size

# Take square root from diff sum
stdev=$(echo "scale=1;" sqrt "($sqsum)" | bc)
echo "Standard deviation: " $stdev