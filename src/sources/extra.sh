#! /bin/bash

aux="check.sh extra.sh md5sums wget-list"

for f in $(ls); do
   base="$base `basename $f`"

   xxx=`grep $f wget-list`
   yyy=`echo $aux | grep $f`

#echo xxx=$xxx 
#echo yyy=$yyy

   if [ -z "$xxx" ] && [ -z "$yyy" ]; then
      echo $f extra
   fi
done

