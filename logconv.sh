#!/bin/sh
ye=`basename $1 | awk '{print substr($1,6,4)}'`
mo=`basename $1 | awk '{print substr($1,1,2)}'`
da=`basename $1 | awk '{print substr($1,3,2)}'`
sed "s/^/$ye-$mo-$da /g" $1 > temp.txt
mv temp.txt $1
