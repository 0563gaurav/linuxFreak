#/* Disclamer*/
#Make sure Host is prepared for compiling the toolchain 
#partition should be mount under $LFS
# $LFS varibale must be exported and $LFS/tools and $LFS/sources directories are exist
#And all the sources are in the $LFS/sources dir (extracted)
#lfs user must have full control on $LFS/sources dir 

export LFS=/mnt/lfs
cd $LFS/sources

#/*start compiling toolchain */

echo "Welcome to this advancture"
sleep 3

#/*Binutils*/
echo "Binutils is being compiled"
sleep 3

tar -xvf binutils-2.35.tar.xz
cd binutils-2.35
mkdir -pv build
cd build
../configure --prefix=$LFS/tools \
	--with-sysroot=$LFS 	 \
	--target=$LFS_TGT	 \
	--disable-nls		\
	--disable-werror
make 
make install 
cd ../../
rm -rf binutils-2.53


#/*GCC */
echo 
echo 
echo 
echo
echo "Starting with gcc package ...."
sleep 3


tar -xvf gcc-10.2.0.tar.xz
cd gcc-10.2.0 
#? dependency resolve 
#gcc package dependes on mpc , mpfr and gmp packages 
tar -xvf ../mpc-1.1.0.tar.gz
mv mpc-1.1.0 mpc
tar -xvf ../gmp-6.2.0.tar.xz
mv gmp-6.2.0 gmp
tar -xvf ../mpfr-4.1.0.tar.xz
mv mpfr-4.1.0 mpfr
#on x84_64 hosts, set the defoult dirctory  name for 64-bit libraries to "lib"
case $(uname -m) in
	x86_64) 
		sed -e '/m64=/s/lib64/lib/' \
			-i.org gcc/config/i386/t-linux64
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
	--enable-lanuages=c,c++
make -j8
make install
#Note 
cd ../
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
	`dirname $($LFS_TGT-gcc -print-libgcc-file-name) ` /install-tools/include/limits.h

cd ../
rm -rf gcc-10.2.0




#/* linux API  headers */
echo "stating with installing linux API"
sleep 3

tar -xvf linux-5.8.3.tar.xz
cd linux-5.8.3/
make mrproper
make headers
find usr/include -name '.*' -delete
rm -rf usr/include/Makefile
cp -rv usr/include/ $LFS/usr

cd ../
rm -rf linux-5.8.3





#/*GLIBC */
echo starting with GLIBC 
sleep 3

#? creating a symbolic link for LSB compliance 
case $(uname -r) in
	i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3 ;;
	x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
		ln -svf ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so3
		;;
esac

#?patching the glibc
patch -Np1 -i ../glibc-2.32-fhs-1.patch

tar -xvf glibc-2.32.tar.xz
cd glibc-2.32
mkdir -v build
cd build
../configure   			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(./scripts/config.guess)	\
	--enable-kernel=3.2	\
	--with-headers=$LFS/usr/include		\
	lib_cv_slibdir=/lib

make -j8
make DESTDIR=$LFS install

cd ../..
rm -rf glibc-2.32

#At this point of time to stop and ensure that the basic function( compling and linking ) of the new programs are working as expected.
#To perform the sanity check , run the following commands
echo 'init main() {}' >dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep '/ld-linux'
#put put of the program should be " [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2 ]
rm  dummy.c a.out



#? Now that our toolchain is complete.
#finilize the installation of limits.h header.
#for this run the utility 
$LFS/tools/libexec/gcc/$LFS_TGT/10.2/install-tools/mkheaders


#/* libstdc++ from GCC-10.2.0, pass 1
echo " libstdc++ is being build ..."
sleep 3
tar -xvf gcc-10.2.0.tar.xz
cd gcc-10.2.0
mkdir build
cd build
../configure 			\
	--host=$LFS_TGT		\
	--build=$(../config.guess)	\
	--prefix=/usr			\
	--disable-multilib		\
	--disable-nls			\
	--disbale-libstdcxx-pch		\
	--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/10.2.0

make -j8
make DESTDIR=$LFS install

cd ../../
rm -rf gcc-10.2.0

#-------------------------------------------------------------------compiling the temporary tools ------------------------------------------------------------------
echo "Started compiling the temporary tools"
sleep 5

#1. /* M4 (macro processor )*/
#first make some fixes introduces by glibc-2.28
echo "M4 Macro prodessor is being build ..."
sleep 3
sed -i 's/IO-ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
#let's compile the M4
tar -xvf m4-1.4.18.tar.xz
cd m4-1.4.18
./configure 			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(build-aux/cinfig.guess)

make -j8 
make DESTDIR=$LFS install

cd ../
rm -rf m4-1.4.18



#2. /*Ncurces */
echo "Ncurses is being build ..."
sleep 3
#first, ensure that gawk is found first during configuration 
sed -i s/mawk// configure 
#then, run the following commands to build the "tic" program on the build host
mkdir build 
pushd build
../configure 
make -C include
make -C progs tic
popd

#compiling the ncurses
tar -xvf ncurses-6.2.tar.gz
cd ncurses-6.2
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
	--enable-widec		

make -j8
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic/ install
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
mv -v $LFS/usr/lib/incursesw.so.6* $LFS/lib
ln -sfv ../../lib/$(readlink $LFS/usr/lib/libncursesw.so) $LFS/usr/lib/ncursesw.so

cd ../
rm -rf ncurses-6.2

#/*Bash */
echo " Bash is being build ..."
sleep 3
tar -xvf bash-5.0.tar.gz
cd bash-5.0
./configure 			\
	--prefix=/usr 		\
	--build=$(support/config.guess)	\
	--host=$LFS_TGT			\
	--without-bash-malloc
make -j8
make DESTDIR=$LFS install

#move the ececutable as expected 
mv $LFS/usr/bin/bash $LFS/bin/bash
ln -sv bash $LFS/bin/sh

cd ../
rm -rf bash-5.0

#/*Coreutils */
echo "Coreutils is being build ..."
sleep 3
tar -xvf coreutils-8.32.tar.xz
cd coreutils-8.32
./configure 			\
	--prefix=/usr		\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)	\
	--enable-install-program=hostname 	\
	--enable-no-install-program=kill,uptime
make -j8
make DESTDIR=$LFS install
#move programs in final expected location

mv -v $LFS/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} $LFS/bin
mv -v $LFS/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} $LFS/bin
mv -v $LFS/usr/bin/{rmdir,stty,sync,true,uname}  $LFS/bin
mv -v $LFS/usr/bin/{head,nice,sleep,touch}  $LFS/bin
mv -v $LFS/usr/bin/chroot   $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8 
mv -v $LFS/usr/share/man/man1/chroot.1   $LFS/usr/share/man/man8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8

cd ../
rm -rf coreutils-8.32

#/*Diffutils */
echo "Diffutils is being build..."
sleep 3
tar -xvf diffutils-3.7.tar.xz
cd diffutils-3.7
./configure --prefix=/usr --host=$LFS_TGT
make -j8
make DESTDIR=$LFS install

cd ../
rm -rf diffutils-3.7


#/*File */
echo "File is being build ...."
sleep 3
tar -xvf file-5.39.tar.gz
cd file-5.39
./configure --prefix=/usr \
	--host=$LFS_TGT
make -j8
make DESTDIR=$LFS install
cd ../
rm -rf file-5.39


#/*Findutils */
echo "Findutils is being build ..."
sleep 3
tar -xvf findutils-4.7.0.tar.xz
cd findutils-4.7.0
./configure --prefix=/usr \
	--host=$LFS_TGT  \
	--build=$(build-aux/config.guess)
make -j8 
make DESTDIR=$LFS install

#Move the executable to its final expected location:
mv -v $LFS/usr/bin/find $LFS/bin
sed -i 's|find:=${BINDIR}|find:=/bin|' $LFS/usr/bin/updatedb

cd ../
rm -rf findutils-4.7.0


#/*Gawk */
echo "Gawk is being build ...."
sleep 3
tar -xvf gawk-5.1.0.tar.xz
cd gawk-5.1.0
./configure --prefix=/usr  \
	--host=$LFS_TGT	\
	--build=$(./config.guess)
make -j8
make DESTDIR=$LFS install

cd ../
rm -rf gawk-5.1.0


#/*Grep */
echo "Grep is being build ..."
sleep 3 
tar -xvf grep-3.4.tar.xz
cd grep-3.4
./configure --prefix=/usr  	\
	--host=$LFS_TGT		\
	--bindir=/bin
make -j8
make DESTDIR=$LFS install

cd ../
rm -rf grep-3.4


#/*Gzip */
echo "Gzip is being build ..."
sleep 3
tar -xvf gzip-1.10.tar.xz
cd gzip-1.10
./configure --prefix=/usr 	\
	--host=$LFS_TGT		
make -j8 
make DESTDIR=$LFS install

#Move the executable to its final expected location:
mv -v $LFS/usr/bin/gzip $LFS/bin

cd ../
rm -rf gzip-1.10


#/* Make */
echo "Make is being buils ..."
sleep 3
tar -xvf make-4.3.tar.gz
cd make-4.3
./configure --prefix=/usr 	\
	--without-guile		\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)
make -j8 
make DESTDIR=$LFS install

cd ../
rm -rf make-4.3


#/*Patch  */
echo "Patch is being build ..."
sleep 3
tar -xvf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr  	\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)
make -j8
make DESTDIR=$LFS install

cd ../
rm -rf patch-2.7.6


#/*Sed */
echo "Sed is being build "
sleep 3
tar -xvf sed-4.8.tar.xz
cd sed-4.8
./configure --prefix=/usr 	\
	--host=$LFS_TGT 	\
	--bindir=/bin	
make -j8
make DESTDIR=$LFS install

cd ../
rm -rf sed-4.8


#/*Tar */
echo " Tar is being build ..."
sleep 3
tar -xvf tar-1.32.tar.xz
cd tar-1.32
./configure --prefix=/usr 	\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)	\
	--bindir=/bin
make -j8
make DESTDIR=$LFS install

cd ../
rm -rf tar-1.32


#/*XZ */
echo "XZ is being build ..."
sleep 3
tar -xvf xz-5.2.5.tar.xz
cd xz-5.2.5
./configure --prefix=/usr 	\
	--host=$LFS_TGT		\
	--build=$(build-aux/config.guess)	\
	--disable-static 		\
	--docdir=/usr/share/doc/xz-5.2.5
make -j8
make DESTDIR=$LFS install

#Make sure that all essential files are in the correct directory:
mv -v $LFS/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} $LFS/bin
mv -v $LFS/usr/lib/liblzma.so.*  $LFS/lib
ln -svf ../../lib/$(readlink $LFS/usr/lib/liblzma.so) $LFS/usr/lib/liblzma.s

cd ../
rm -rf xz-5.2.5

#/*Binutils PASS 2  */
echo "Binutils , PASS-2 , is being build ...."
sleep 5
tar -xvf binutils-2.35.tar.xz
cd binutils-2.35 
mkdir -pv  build
cd  build
../configure  --prefix=/usr  \
	--build=$(../config.guess)	\
	--host=$LFS_TGT		\
	--disable-nls	\
	--enable-shared		\
	--disable-werror	\
	--enable-64-bit-bfd	
make -j8
make DESTDIR=$LFS install


#/* Gcc PASS-2 */
echo " GCC , PASS-2 , is being build ...."
sleep 5 
tar -xvf gcc-10.2.0.tar.xz
cd gcc-10.2.0
#As in the first build of GCC, the GMP, MPFR, and MPC packages are required. Unpack the tarballs and move them into the required directory names:

tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.0.tar.xz
mv -v gmp-6.2.0 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

#If building on x86_64, change the default directory name for 64-bit libraries to lib

case $(uname -m) in
x86_64)
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
;;
esac

mkdir -pv build
cd build 

mkdir -pv $LFS_TGT/libgcc
ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h

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
	--enable-languages=c,c++
make -j8
make DESTDIR=$LFS install

#As a finishing touch, create a utility symlink
ln -sv gcc $LFS/usr/bin/cc






echo "Congratulation..."
echo " Your Toolchain and required temporary tools are ready "
echo " Let's move next script, the  Entering_chroot_env.sh and run this script "

#/*Author */
#Gaurav Gautam Shakya
#Electrical Engineer 
#Linux Administartor
#-EMAIL<hkrgs1234@gmail.com>








