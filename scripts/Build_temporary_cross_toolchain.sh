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
sleep 5

#/*Binutils*/
echo "Binutils is being compiled"
sleep 5

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
sleep 10


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
	--
with-sysroot=$LFS	  \
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
cat gcc/limitx.h gcc/glimits.h gcc/limity.h \
	`dirname $($LFS_TGT-gcc -print-libgcc-file-name) ` /install-tools/include/limits.h

cd ../
rm -rf gcc-10.2.0




#/* linux API  headers */
echo "stating with installing linux API"
sleep 10

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
sleep 10

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


