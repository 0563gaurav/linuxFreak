#Changing Ownership
#change the ownership of the $LFS/* directories to user root by running the following commands:

chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
x86_64) chown -R root:root $LFS/lib64 ;;
esac

#Preparing Virtual Kernel File Systems
mkdir -pv $LFS/{dev,proc,sys,run}

#Creating Initial Device Nodes
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

#Mounting and Populating /dev
mount -v --bind /dev $LFS/dev

#Mounting Virtual Kernel File Systems
mount -v --bind /dev/pts $LFS/dev/pts
mount-vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

#In some host systems, /dev/shm is a symbolic link to /run/shm
if [ -h $LFS/dev/shm ]; then
mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi


#Entering the Chroot Environment
chroot "$LFS" /usr/bin/env -i \
	HOME=/root 	\
	TERM="$TERM"	\
	PS1='(lfs chroot) \u:\w\$ ' \
	PATH=/bin:/usr/bin:/sbin:/usr/sbin \
	/bin/bash --login +h


#Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

#Creating Essential Files and Symlinks
ln -sv /proc/self/mounts /etc/mtab
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

#Create the /etc/passwd file by running the following command:

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

#Create the /etc/group file by running the following command:
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

#Some tests in Chapter 8 need a regular user. We add this user here and delete this account at the end of that chapter
echo "tester:x:$(ls -n $(tty) | cut -d" " -f3):101::/home/tester:/bin/bash" >> /et
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester


#To remove the “I have no name!  prompt, start a new shell. Since the /etc/passwd and /etc/group files have
#been created, user name and group name resolution will now work
exec /bin/bash --login +h

#The login, agetty, and init programs (and others) use a number of log files to record information such as who was
#logged into the system and when. However, these programs will not write to the log files if they do not already exist.
#Initialize the log files and give them proper permissions:
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /vat/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp



#-----------------------------------------------------------------------------------------------------------------------------------------------#
#/*Libstdc++ from GCC-10.2.0, Pass 2 */

echo "Building Extra Temporary tools ..."
echo "Building Libstdc++ from GCC-10.2.0 , PASS-2"
sleep 3
tar -xvf gcc-10.2.0.tar.xz
cd gcc-10.2.0
#Create a link which exists when building libstdc++ in the gcc tree:
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir -pv build
cd build 
../libstdc++-v3/configure CXXFLAGS="-g -O2 -D_GNU_SOURCE"	\
			--prefix=/usr		\
			--disable-multilib	\
			--disable-nls		\
			--host=$(uname -m)-lfs-linux-gnu	\
			--disable-libstdcxx-pch 

make -j$(nporc)
make install

cd ../../
rm -rf gcc-10.2.0
#/*Gettext-0.21 */


echo "Building Gettext-0.21 ...."
sleep 3
tar -xvf gettext-0.21.tar.xz
cd gettext-0.21
./configure --disable-shared
make -j$(nporc)
#Install the msgfmt, msgmerge, and xgettext programs:
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd ../
rm -rf gettext-0.21


#/*Bison-3.7.1 */
echo " Building Bison-3.7.1 ..."
sleep 3
tar -xvf bison-3.7.1.tar.xz
cd bison-3.7.1
./configure --prefix=/usr \
	--docdir=/usr/share/doc/bison-3.7.1
make -j$(nproc)
make install


cd ../
rm -rf bison-3.7.1


#/* Perl-5.32.0  */
echo "Building Perl-5.32.0 ...."
sleep 3

tar -xvf perl-5.32.0.tar.xz
cd perl-5.32.0
sh Configure -des					\
	-Dprefix=/usr					\
	-Dvendorprefix=/usr				\
	-Dprivlib=/usr/lib/perl5/5.32/core_perl		\
	-Darchlib=/usr/lib/perl5/5.32/core_perl		\
	-Dsitelib=/usr/lib/perl5/5.32/site_perl		\
	-Dsitearch=/usr/lib/perl5/5.32/site_perl	\
	-Dvendorlib=/usr/lib/perl5/5.32/vendor_perl 	\
	-Dvendorarch=/usr/lib/perl5/5.32/vendor_perl

make -j$(nporc)
make install

cd ../
rm -rf perl-5.32.0


#/*Python-3.8.5 */
echo "Building Python-3.8.5 ..."
sleep 3
tar -xvf   Python-3.8.5.tar.xz 
cd   Python-3.8.5.
./configure --prefix=/usr	\
	--enable-shared		 \
	--without-ensurepip

make -j$(nproc)
make install

cd ../
rm -rf python-3.8.5-docs-html

#/* Texinfo-6.7 */
echo " Building Texinfo-6.7 ..."
sleep 3
tar -xvf texinfo-6.7.tar.xz
cd texinfo-6.7
./configure --prefix=/usr
make -j(nproc)
make install


cd ../
rm -rf texinfo-6.7

#/*Util-linux-2.36 */
echo "Building Util-linux-2.36 ..."
sleep 3

#First create a directory to enable storage for the hwclock program:
mkdir -pv /var/lib/hwclock

#Prepare Util-linux for compilation:

tar -xvf util-linux-2.36.tar.xz
cd util-linux-2.36

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime	\
		--docdir=/usr/share/doc/util-linux-2.36 \
		--disable-chfn-chsh 			\
		--disable-login				\
		--disable-nologin			\
		--disable-su				\
		--disable-setpriv			\
		--disable-runuser			\
		--disable-pylibmount 			\
		--disable-static			\
		--without-python

make -j$(nproc)
make install

cd ../
rm -rf util-linux-2.36


#/* Cleaning up and Saving the Temporary System  */

echo "Cleaning up and Saving the Temporary System ..."
sleep 3

#The libtool .la files are only useful when linking with static libraries. They are unneeded, and potentially harmful, when
#using dynamic shared libraries, specially when using non-autotools build systems. While still in chroot, remove those
#files now:
find /usr/{lib,libexec} -name \*.la -delete#

#Remove the documentation of the temporary tools, to prevent them from ending up in the final system, and save about 35 MB:
rm -rf /usr/share/{info,man,doc}/*


#All of the following instructions are executed by root. Take extra care about the commands you're going to
#run as mistakes here can modify your host system. Be aware that the environment variable LFS is set for user
#lfs by default but it might not be set for root. Whenever commands are to be executed by root, make
#sure you have set LFS accordingly. This has been discussed in Section 2.6, "Setting The $LFS Variable"
exit
umount $LFS/dev{/pts,}
umount $LFS/{sys,proc,run}


#/*Stripping */
#Strip off debugging symbols from binaries:
echo "Strip off debugging symbols from binaries: ..."
trip --strip-debug $LFS/usr/lib/*
strip --strip-unneeded $LFS/usr/{,s}bin/*
strip --strip-unneeded $LFS/tools/bin/*
#------------------------------------------------backup and restore the system instruction -----------------------------------------------------------#

#NOTE---> If you want to backup or restore system uncomment the appropriate commands .

#/*Backup */
#Make sure you have at least 600 MB free disk space (the source tarballs will be included in the backup archive) in the
#home directory of user root.
#Create the backup archive by running the following command:


#cd $LFS &&
#tar -cJpf $HOME/lfs-temp-tools-10.0-systemd.tar.xz .

#/* Restore */
#In case some mistakes have been made and you need to start over, you can use this backup to restore the temporary
#tools and save some recovery time. Since the sources are located under $LFS, they are included in the backup archive
#as well, so they do not need to be downloaded again. After checking that $LFS is set properly, restore the backup by
#executing the following commands




#echo "Restoring the system ..."
#sleep 3
#cd $LFS &&
#rm -rf ./* &&
#tar -xpf $HOME/lfs-temp-tools-10.0-systemd.tar.xz
