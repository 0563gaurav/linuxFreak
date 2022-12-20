#/* Disclamer*/
#Make sure Host is prepared for compiling the toolchain 
#partition should be mount under $LFS
# $LFS varibale must be exported and $LFS/tools and $LFS/sources directories are exist
#And all the sources are in the $LFS/sources dir (extracted)
#lfs user must have full control on $LFS/sources dir 

export LFS=/mnt/lfs
export LOG_PATH=$LFS/sources/log
cd $LFS/sources

mkdir -pv $LOG_PATH
touch $LOG_PATH/err  $LOG_PATH/current_pkg
ERROR=$LOG_PATH/err
CURR_PKG=$LOG_PATH/current_pkg

#/*start compiling toolchain */

echo "Welcome to this advancture" 1>$CURR_PKG 
sleep 3

#/*Binutils*/
echo "Binutils is being build " 1>$CURR_PKG
tar -xvf binutils-2.35.tar.xz 2>$ERROR
cd binutils-2.35 1>$ERROR
mkdir -pv build 1>$ERROR
cd build
../configure --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --disable-werror 2>$ERROR 
make  2>$ERROR
make install  2>$ERROR
cd ../../ 2>$ERROR
rm -rf binutils-2.53 2>$ERROR


#/*GCC */
echo 
echo 
echo 
echo
echo "Starting with gcc package ...." 1>$CURR_PKG
sleep 3


tar -xvf gcc-10.2.0.tar.xz 2>$ERROR
cd gcc-10.2.0 2>$ERROR
#? dependency resolve 
#gcc package dependes on mpc , mpfr and gmp packages 
tar -xvf ../mpc-1.1.0.tar.gz 2>$ERROR
mv mpc-1.1.0 mpc 2>$ERROR
tar -xvf ../gmp-6.2.0.tar.xz 2>$ERROR
mv gmp-6.2.0 gmp 2>$ERROR
tar -xvf ../mpfr-4.1.0.tar.xz 2>$ERROR
mv mpfr-4.1.0 mpfr 2>$ERROR
#on x84_64 hosts, set the defoult dirctory  name for 64-bit libraries to "lib"
case $(uname -m) in
	x86_64) 
		sed -e '/m64=/s/lib64/lib/' -i.org gcc/config/i386/t-linux64 1>$ERROR
	;;
esac
#dependency are resolved , now procceed with compilation 
mkdir build
cd build
../configure --target=$LFS_TGT	\
	--prefix=$LFS/tools	\
	--with-glibc-version=2.11 \
	--with-sysroot=$LFS	  \
	--with-newlib		  \
	--without-headers	  \
	--enable-initfini-array	  \
	--disable-nls		  \
	--disable-shared	  \
	--disable-multilib	  \
	--disable-decimal-float   \
	--disable-threads	  \
	--disable-libatomic	  \
	--disable-libgomp	  \
	--disable-libquadmath	  \
	--disable-libssp	  \
	--disable-libvtv	  \
	--disable-libstdcxx	  \
	--enable-lanuages=c,c++  2>$ERROR
make -j8 2>$ERROR
make install 2>$ERROR
#Note 
cd ../
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
	`dirname $($LFS_TGT-gcc -print-libgcc-file-name) ` /install-tools/include/limits.h 2>$ERROR

cd ../
rm -rf gcc-10.2.0


exit

#/* linux API  headers */
echo "stating with installing linux API" 1>$CURR_PKG
sleep 3

tar -xvf linux-5.8.3.tar.xz 2>$ERROR
cd linux-5.8.3/ 2>$ERROR
make mrproper 2>$ERROR
make headers 2>$ERROR
find usr/include -name '.*' -delete 2>$ERROR
rm -rf usr/include/Makefile 2>$ERROR
cp -rv usr/include/ $LFS/usr 2>$ERROR

cd ../
rm -rf linux-5.8.3





#/*GLIBC */
echo "starting with GLIBC " 1>$CURR_PKG
sleep 3

#? creating a symbolic link for LSB compliance 
case $(uname -r) in
	i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3   ;; 
	x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64 2>$ERROR
		ln -svf ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x8-64.so3 2>$ERROR
		;;
esac 




tar -xvf glibc-2.32.tar.xz 2>$ERROR
cd glibc-2.322 2>$ERROR
#Patching the glibc
patch -Np1 -i ../glibc-2.32-fhs-1.patch 2>$ERROR

mkdir -v build 2>$ERROR
cd build
../configure   			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(./scripts/config.guess)	\
	--enable-kernel=3.2	\
	--with-headers=$LFS/usr/include		\
	lib_cv_slibdir=/lib 2>$ERROR 

make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR 

cd ../..
rm -rf glibc-2.32

#At this point of time to stop and ensure that the basic function( compling and linking ) of the new programs are working as expected.
#To perform the sanity check , run the following commands
echo "Perfoeming test on toolchain " 2>$ERROR
echo 'init main() {}' >dummy.c 2>$ERROR
$LFS_TGT-gcc dummy.c 2>$ERROR
readelf -l a.out | grep '/ld-linux' 2>$ERROR
#put put of the program should be " [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2 ]
rm  dummy.c a.out 2>$ERROR



#? Now that our toolchain is complete.
#finilize the installation of limits.h header.
#for this run the utility 
$LFS/tools/libexec/gcc/$LFS_TGT/10.2/install-tools/mkheaders 2>$ERROR


#/* libstdc++ from GCC-10.2.0, pass 1
echo " libstdc++ is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf gcc-10.2.0.tar.xz 2>$ERROR
cd gcc-10.2.0 2>$ERROR
mkdir build 2>$ERROR
cd build 2>$ERROR
../configure 			\
	--host=$LFS_TGT		\
	--build=$(../config.guess)	\
	--prefix=/usr			\
	--disable-multilib		\
	--disable-nls			\
	--disbale-libstdcxx-pch		\
	--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/10.2.0 2>$ERROR  

make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../../
rm -rf gcc-10.2.0

#-------------------------------------------------------------------compiling the temporary tools ------------------------------------------------------------------
echo "Started compiling the temporary tools" 1>$CURR_PKG 
sleep 5

#1. /* M4 (macro processor )*/
#first make some fixes introduces by glibc-2.28
echo "M4 Macro prodessor is being build ..." 1>$CURR_PKG
sleep 3
sed -i 's/IO-ftrylockfile/IO_EOF_SEEN/' lib/*.c  2>$ERROR
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h 2>$ERROR
#let's compile the M4
tar -xvf m4-1.4.18.tar.xz 2>$ERROR
cd m4-1.4.18 2>$ERROR
./configure 			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(build-aux/cinfig.guess) 2>$ERROR

make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../
rm -rf m4-1.4.18



#2. /*Ncurces */
echo "Ncurses is being build ..." 1>$CURR_PKG
sleep 3
#first, ensure that gawk is found first during configuration 
sed -i s/mawk// configure  2>$ERROR
#then, run the following commands to build the "tic" program on the build host
mkdir build 2>$ERROR
pushd build 2>$ERROR
../configure  2>$ERROR
make -C include 2>$ERROR
make -C progs tic 2>$ERROR
popd

#compiling the ncurses
tar -xvf ncurses-6.2.tar.gz 2>$ERROR
cd ncurses-6.2 2>$ERROR
./configure 			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(./config.guess) \
	--mandir=/usr/share/man  	\
	--with-manpage-format=normal	\
	--with-shared 		\
	--without-debug		\
	--without-debug		\
	--without-ada		\
	--without-normal	\
	--enable-widec  2>$ERROR	

make -j8 2> $ERROR
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic/ install 2>$ERROR
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so 
mv -v $LFS/usr/lib/incursesw.so.6* $LFS/lib 2>$ERROR
ln -sfv ../../lib/$(readlink $LFS/usr/lib/libncursesw.so) $LFS/usr/lib/ncursesw.so 2>$ERROR 

cd ../
rm -rf ncurses-6.2

#/*Bash */
echo " Bash is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf bash-5.0.tar.gz 2>$ERROR
cd bash-5.0 2>$ERROR
./configure 			\
	--prefix=/usr 		\
	--build=$(support/config.guess)	\
	--host=$LFS_TGT			\
	--without-bash-malloc 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install  2>$ERROR

#move the ececutable as expected 
mv $LFS/usr/bin/bash $LFS/bin/bash  2>$ERROR
ln -sv bash $LFS/bin/sh  2>$ERROR

cd ../
rm -rf bash-5.0

#/*Coreutils */
echo "Coreutils is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf coreutils-8.32.tar.xz 2>$ERROR
cd coreutils-8.32 2>$ERROR
./configure 			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)	\
	--enable-install-program=hostname 	\
	--enable-no-install-program=kill,uptime  2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS  install 2>$ERROR
#move programs in final expected location

mv -v $LFS/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} $LFS/bin 2>$ERROR
mv -v $LFS/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} $LFS/bin  2>$ERROR
mv -v $LFS/usr/bin/{rmdir,stty,sync,true,uname}  $LFS/bin  2>$ERROR
mv -v $LFS/usr/bin/{head,nice,sleep,touch}  $LFS/bin 2>$ERROR
mv -v $LFS/usr/bin/chroot   $LFS/usr/sbin  2>$ERROR
mkdir -pv $LFS/usr/share/man/man8  2>$ERROR
mv -v $LFS/usr/share/man/man1/chroot.1   $LFS/usr/share/man/man8 2>$ERROR
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8 2>$ERROR

cd ../ 2>$ERROR
rm -rf coreutils-8.32 2>$ERROR

#/*Diffutils */
echo "Diffutils is being build..." 1>$CURR_PKG
sleep 3
tar -xvf diffutils-3.7.tar.xz 2>$ERROR
cd diffutils-3.7 2>$ERROR
./configure --prefix=/usr --host=$LFS_TGT 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf diffutils-3.7 2>$ERROR


#/*File */
echo "File is being build ...." 1>$CURR_PKG
sleep 3
tar -xvf file-5.39.tar.gz 2>$ERROR
cd file-5.39 2>$ERROR
./configure --prefix=/usr \
	--host=$LFS_TGT 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR
cd ../ 2>$ERROR
rm -rf file-5.39 2>$ERROR


#/*Findutils */
echo "Findutils is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf findutils-4.7.0.tar.xz 2>$ERROR
cd findutils-4.7.0 2>$ERROR
./configure --prefix=/usr \
	--host=$LFS_TGT  \
	--build=$(build-aux/config.guess) 2>$ERROR
make -j8  2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

#Move the executable to its final expected location:
mv -v $LFS/usr/bin/find $LFS/bin 2>$ERROR
sed -i 's|find:=${BINDIR}|find:=/bin|' $LFS/usr/bin/updatedb 2>$ERROR

cd ../ 2>$ERROR
rm -rf findutils-4.7.0 2>$ERROR


#/*Gawk */
echo "Gawk is being build ...." 1>$CURR_PKG 
sleep 3
tar -xvf gawk-5.1.0.tar.xz 2>$ERROR
cd gawk-5.1.0 2>$ERROR
./configure --prefix=/usr  \
	--host=$LFS_TGT	\
	--build=$(./config.guess) 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf gawk-5.1.0  2>$ERROR


#/*Grep */
echo "Grep is being build ..." 1>$CURR_PKG
sleep 3 
tar -xvf grep-3.4.tar.xz 2>$ERROR
cd grep-3.4
./configure --prefix=/usr  	\
	--host=$LFS_TGT		\
	--bindir=/bin 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf grep-3.4 2>$ERROR


#/*Gzip */
echo "Gzip is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf gzip-1.10.tar.xz 2>$ERROR
cd gzip-1.10 2>$ERROR
./configure --prefix=/usr 	\
	--host=$LFS_TGT	 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

#Move the executable to its final expected location:
mv -v $LFS/usr/bin/gzip $LFS/bin 2>$ERROR

cd ../ 2>$ERROR
rm -rf gzip-1.10 2>$ERROR


#/* Make */
echo "Make is being buils ..." 1>$CURR_PKG
sleep 3
tar -xvf make-4.3.tar.gz 2>$ERROR
cd make-4.3 2>$ERROR
./configure --prefix=/usr 	\
	--without-guile		\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess) 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf make-4.3 2>$ERROR


#/*Patch  */
echo "Patch is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf patch-2.7.6.tar.xz 2>$ERROR
cd patch-2.7.6
./configure --prefix=/usr  	\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess) 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf patch-2.7.6 2>$ERROR


#/*Sed */
echo "Sed is being build " 1>$CURR_PKG
sleep 3
tar -xvf sed-4.8.tar.xz 2>$ERROR
cd sed-4.8 2>$ERROR
./configure --prefix=/usr 	\
	--host=$LFS_TGT 	\
	--bindir=/bin 2>$ERROR	
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf sed-4.8 2>$ERROR


#/*Tar */
echo " Tar is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf tar-1.32.tar.xz 2>$ERROR
cd tar-1.32 2>$ERROR
./configure --prefix=/usr 	\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)	\
	--bindir=/bin 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

cd ../ 2>$ERROR
rm -rf tar-1.32 2>$ERROR


#/*XZ */
echo "XZ is being build ..." 1>$CURR_PKG
sleep 3
tar -xvf xz-5.2.5.tar.xz 2>$ERROR
cd xz-5.2.5 2>$ERROR
./configure --prefix=/usr 	\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)	\
	--disable-static 		\
	--docdir=/usr/share/doc/xz-5.2.5  2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

#Make sure that all essential files are in the correct directory:
mv -v $LFS/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} $LFS/bin 2>$ERROR
mv -v $LFS/usr/lib/liblzma.so.*  $LFS/lib 2>$ERROR
ln -svf ../../lib/$(readlink $LFS/usr/lib/liblzma.so) $LFS/usr/lib/liblzma.s 2>$ERROR

cd ../ 2>$ERROR
rm -rf xz-5.2.5 2>$ERROR

#/*Binutils PASS 2  */
echo "Binutils , PASS-2 , is being build ...." 1>$CURR_PKG
sleep 5
tar -xvf binutils-2.35.tar.xz 2>$ERROR
cd binutils-2.35  2>$ERROR
mkdir -pv  build 2>$ERROR
cd  build
../configure  --prefix=/usr  \
	--build=$(../config.guess)	\
	--host=$LFS_TGT		\
	--disable-nls	\
	--enable-shared		\
	--disable-werror	\
	--enable-64-bit-bfd	2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR


#/* Gcc PASS-2 */
echo " GCC , PASS-2 , is being build ...." 1>$CURR_PKG
sleep 5 
tar -xvf gcc-10.2.0.tar.xz  2>$ERROR
cd gcc-10.2.0
#As in the first build of GCC, the GMP, MPFR, and MPC packages are required. Unpack the tarballs and move them into the required directory names:

tar -xvf ../mpfr-4.1.0.tar.xz  2>$ERROR
mv -v mpfr-4.1.0 mpfr 2>$ERROR
tar -xvf ../gmp-6.2.0.tar.xz 2>$ERROR
mv -v gmp-6.2.0 gmp 2>$ERROR
tar -xvf ../mpc-1.1.0.tar.gz 2>$ERROR 
mv -v mpc-1.1.0 mpc 2>$ERROR

#If building on x86_64, change the default directory name for 64-bit libraries to lib

case $(uname -m) in
x86_64)
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 2>$ERROR
;;
esac

mkdir -pv build 2>$ERROR
cd build 2>$ERROR

mkdir -pv $LFS_TGT/libgcc  2>$ERROR
ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h 2>$ERROR
../configure  --build=$(../config.guess) \
	--host=$LFS_TGT 	\
	--prefix=/usr	\
	CC_FOR_TARGET=$LFS_TGT-gcc	\
	--with-build-sysroot=$LFS	\
	--enable-initfini-array		\
	--disable-nls			\
	--disable-multilib		\
	--disable-decimal-float		\
	--disable-libatomic		\
	--disable-libgomp		\
	--disable-libquadmath		\
	--disable-libssp		\
	--disable-libvtv		\
	--disable-libstdcxx		\
	--enable-languages=c,c++ 2>$ERROR
make -j8 2>$ERROR
make DESTDIR=$LFS install 2>$ERROR

#As a finishing touch, create a utility symlink
ln -sv gcc $LFS/usr/bin/cc 2>$ERROR





echo "Congratulation... You did it ..." 
echo " Your Toolchain and required temporary tools are ready "
echo " Let's move next script, the  Entering_chroot_env.sh and run this script " :

#/*Author */
#Gaurav Gautam Shakya
#Electrical Engineer 
#Linux Administartor
#-EMAIL<hkrgs1234@gmail.com>








