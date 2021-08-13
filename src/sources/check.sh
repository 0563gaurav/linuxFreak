#! /bin/bash

while read line; do
   base=`basename $line`

   if [ ! -s $base ]; then
      echo $base misssing
   fi
done < "wget-list"

