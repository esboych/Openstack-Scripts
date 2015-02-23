#!/bin/bash

apt-get install bc  # not installed by default

filename="./results.txt"

#sed -i 's/- /-/g' "./results.txt"
sed -i 's/- /-/g' $filename

awk '/SUM/{print $1 $2 $3 " " $6 " " $7}' $filename  # print only SUMs

#arr=( $(awk '/SUM/{print $6}' ./results.txt))
arr=( $(awk '/SUM/{print int($6)}' $filename ))

#sum all array elements:
echo "Calculating sum.."
sum=0
for i in ${arr[*]}; do
    #echo $i "SUM: " $i
    sum=$(($sum + $i))
done
echo "sum=" $sum

#count the median
med=$(($sum/${#arr[*]}))
echo "med: " $med

#calculate the sum of diff squares
sqsum=0
array_size=$arr[*]-1
for i in ${arr[*]}; do
#for i in $array_size; do
    sqsum=$((sqsum +  (i-$med)**2 ))
    #echo "i - med, result: " $i $med $(($i-$med)) $sqsum
done

echo "final sqsum" $sqsum

# finally: calc the std deviation
sqsum=$((sqsum/${#arr[*]})) #sum of diff squares divided by array size
echo "sqsum=" $sqsum


# Take square root from diff sum
var1=$(echo "scale=10;" sqrt "($sqsum)" | bc)
echo "Standard deviation: " $var1