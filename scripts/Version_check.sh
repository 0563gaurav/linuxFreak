#!/bin/bash
#simple script to list versions of numbers of critical development tools

#export LC_ALL=posix
bash --version | head -n1 | cut -d" " -f1-4
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh --> $MYSH"
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh is not pointing to bash"
unset MYSH
echo -n  "Binutils: " ; ld --version | head -n1 | cut -d" " -f3-
if [ -h /usr/bin/yacc ] 
then 
	echo "/usr/bin/yacc --> `readlink -f /usr/bin/yacc`"
elif [ -x /usr/bin/yacc ] 
then 
	echo $(yacc --version | head -n1)
else 
	echo " yacc was not found" 
fi 
bzip2 --version 2>&1 </dev/null | head -n1 | cut -d" " -f1,6-
echo -n " Coreutils: " ; chown --version | head -n1 | cut -d" " -f4-
diff --version | head -n1
if [ -h /usr/bin/awk ] 
then 
	echo "/usr/bin/awk --> `readlink -f /usr/bin/awk`"
elif [ -x /usr/bin/awk ]
then 
	echo -n  "awk version is " ; awk --version | head -n1 

else 
	echo " awk is not found "
fi
gcc --version | head -n1 
echo -n  "GLIBC: " ; ldd --version | head -n1 | cut -d" " -f5
grep --version | head -n1 
gzip --version | head -n1
cat /proc/version 
m4 --version | head -n1 
make -version | head -n1 
patch --version | head -n1 
perl --version 2>&1 </dev/null | head -n2 | cut -d" " -f3- #perl --version | head -n2 | cut -d" " -f3-
python3 --version 
tar --version | head -n1
sed --version | head -n1 
makeinfo --version | head -n1
xz --version | head -n1
exit 0

