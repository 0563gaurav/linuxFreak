#/* <-------------------------------------Building the LFS System ---------------------------------------------->
#/*Installing Basic System Software */
#Package Management
#Upgrade Issues
#Package Management Techniques



echo "Installing Basic System Software ...."
sleep 3
export LFS=/mnt/lfs
export LOG=$LFS/sources/log

#/*Man-pages-5.08 */
echo "Installing man-pages ..."
sleep 3
tar -xvf man-pages-5.08.tar.xz
cd man-pages-5.08
make install

cd ../
rm -rf man-pages-5.08

#/* Tcl-8.6.10 */
echo "Installing Tcl-8.6.10 ..."
sleep 3
mkdir -pc build
cd build
tar -xf ../tcl8.6.10-html.tar.gz --strip-components=1
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr			\
		--mandir=/usr/share/man 	\
		$([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)
make  -j$(nproc)

sed -e "s|$SRCDIR/unix|/usr/lib|" 	\
	-e "s|$SRCDIR|/usr/include|" \
	-i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.1|/usr/lib/tdbc1.1.1|" \
	-e "s|$SRCDIR/pkgs/tdbc1.1.1/generic|/usr/include|"	\
	-e "s|$SRCDIR/pkgs/tdbc1.1.1/library|/usr/lib/tcl8.6|"	\
	-e "s|$SRCDIR/pkgs/tdbc1.1.1|/usr/include|"	\
	-i pkgs/tdbc1.1.1/tdbcConfig.sh


sed -e	-e "s|$SRCDIR/unix/pkgs/itcl4.2.0|/usr/lib/itcl4.2.0|" 		\
	-e "s|$SRCDIR/pkgs/itcl4.2.0/generic|/usr/include|"		\
	-e "s|$SRCDIR/pkgs/itcl4.2.0|/usr/include|"			\
	-i pkgs/itcl4.2.0/itclConfig.sh

unset SRCDIR

#To test the results, issue:
make test
#Install the package:
make install
#Make the installed library writable so debugging symbols can be removed later:
chmod -v u+w /usr/lib/libtcl8.6.so
#Install Tcl's headers. The next package, Expect, requires them.
make install-private-headers
#Now make a necessary symbolic link:
ln -sfv tclsh8.6 /usr/bin/tclsh


#/*Expect-5.45.4 */
echo "Installing Expect-5.45.4 ..."
sleep 3
tar -xvf expect5.45.4.tar.gz
cd expect5.45.4
./configure --prefix=/usr		\
	--with-tcl=/usr/lib		\
	--enable-shared			\
	--mandir=/usr/share/man		 \
	--with-tclinclude=/usr/include
make -j$(nproc)
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib


#/*DejaGNU-1.6.2 */
echo " Installing DejaGNU-1.6.2 ..."
sleep 3
tar -xvf dejagnu-1.6.2.tar.gz
cd dejagnu-1.6.2
./configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
makeinfo --plaintext -o doc/dejagnu.txt doc/dejagnu.tex

make install
install -v -dm755 /usr/share/doc/dejagnu-1.6.2
install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.2
#To test the results, issue:
make check




#/*Iana-Etc-20200821 */
echo "Installing Iana-Etc-20200821 ..."
sleep 3
tar -xvf iana-etc-20200821.tar.gz
#For this package, we only need to copy the files into place:
cp services protocols /etc


#/*Glibc-2.32 */
echo "Installing Glibc-2.32 ..."
sleep 3
tar -xvf glibc-2.32.tar.xz
cd glibc-2.32
patch -Np1 -i ../glibc-2.32-fhs-1.patch
mkdir -pv build 
cd build
../configure --prefix=/usr		\
	--disable-werror		\
	--enable-kernel=3.2		\
	--enable-stack-protector=strong		\
	--with-headers=/usr/include		\
	libc_cv_slibdir=/lib

make -j$(nproc)
#Generally a few tests do not pass. The test failures listed below are usually safe to ignore.
case $(uname -m) in
	i?86)	ln -sfnv $PWD/elf/ld-linux.so.2  /lib ;;
	x86_64)  ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac


make check

touch /etc/ld.so.conf
#Fix the generated Makefile to skip an unneeded sanity check that fails in the LFS partial environment:
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
#Install the package:
make install
#Install the configuration file and runtime directory for nscd:
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

#Install the systemd support files for nscd:
install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service
mkdir -pv /usr/lib/locale
localdef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localdef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localdef -i de_DE -f ISO-8859-1 de_DE
localdef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localdef -i de_DE -f UTF-8 de_DE.UTF-8
localdef -i el_GR -f ISO-8859-7 el_GR
localdef -i en_GB -f UTF-8 en_GB.UTF-8
localdef -i en_HK -f ISO-8859-1 en_HK
localdef -i en_PH -f ISO-8859-1 en_PH
localdef -i en_US -f ISO-8859-1 en_US
localdef -i en_US -f UTF-8 en_US.UTF-8
localdef -i es_MX -f ISO-8859-1 es_MX
localdef -i fa_IR -f UTF-8 fa_IR
localdef -i fr_FR -f ISO-8859-1 fr_FR
localdef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localdef -i fr_FR -f UTF-8 fr_FR.UTF-8
localdef -i it_IT -f ISO-8859-1 it_IT
localdef -i it_IT -f UTF-8 it_IT.UTF-8
localdef -i ja_JP -f EUC-JP ja_JP
localdef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localdef -i ja_JP -f UTF-8 ja_JP.UTF-8
localdef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localdef -i ru_RU -f UTF-8 ru_RU.UTF-8
localdef -i tr_TR -f UTF-8 tr_TR.UTF-8
localdef -i zh_CN -f GB18030 zh_CN.GB18030
localdef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS


#Configuring Glibc

#The /etc/nsswitch.conf file needs to be created because the Glibc defaults do not work well in a networked environment.
#Create a new file /etc/nsswitch.conf by running the following:
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF

#Adding time zone data
#Install and set up the time zone data with the following
tar -xf ../../tzdata2020a.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica		\
		asia australasia backward pacificnew systemv; do
		zic -L /dev/null -d $ZONEINFO ${tz}
		zic -L /dev/null -d $ZONEINFO/posix ${tz}
		zic -L leapseconds -d $ZONEINFO/right ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

#One way to determine the local time zone is to run the following script
#tzselect

#Then create the /etc/localtime file by running:
ln -sfv /usr/share/zoneinfo/asia /etc/localtime


#Configuring the Dynamic Loader
#Create a new file /etc/ld.so.conf by running the following:
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -pv /etc/ld.so.conf.d

cd ../..
rm -rf glibc-2.32


#/*Zlib-1.2.11 */
echo "Installing Zlib-1.2.11 ..."
sleep 3
tar -xvf zlib-1.2.11.tar.xz
cd zlib-1.2.11

./configure --prefix=/usr
make 
make check 
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so


#/*Bzip2-1.0.8 */
echo "Installing Bzip2-1.0.8 ..."
sleep 3
tar -xvf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
echo "Patching Bzip2-1.0.8 ..."
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
#The following command ensures installation of symbolic links are relative
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
#Ensure the man pages are installed into the correct location:
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
#Prepare Bzip2 for compilation with:
make -f Makefile-libbz2_so
make clean
make 
make PREFIX=/usr install
#nstall the shared bzip2 binary into the /bin directory, make some necessary symbolic links, and clean up:
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

cd ../
rm -rf bzip2-1.0.8


#/* Xz-5.2.5 */
echo "Installing Xz-5.2.5 ..."
sleep 2
tar -xvf xz-5.2.5.tar.xz
cd xz-5.2.5
./configure --prefix=/usr		\
	--disable-static 		\
	--docdir=/usr/share/doc/xz-5.2.5
make -j$(nproc)
make check
make install
mv -v
/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so


cd ../
rm -rf xz-5.2.5


#/* Zstd-1.4.5 */
echo "Installing Zstd-1.4.5  ..."
sleep 2
tar -xvf zstd-1.4.5.tar.gz 
cd zstd-1.4.5
make -j$(nproc)
make prefix=/usr install
#Remove the static library and move the shared library to /lib. Also, the .so file in /usr/lib will need to be recreated
rm -v /usr/lib/libzstd.a
mv -v /usr/lib/libzstd.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libzstd.so) /usr/lib/libzstd.so

cd ../
rm -rf zstd-1.4.5


#/* File-5.39 */
echo "Installing File-5.39 ..."
sleep 2
tar -xvf file-5.39.tar.gz
cd file-5.39
./configure --prefix=/usr
make -j$(nproc)
make check 
make install

cd ../
rm -rf file-5.39


#/* Readline-8.0 */
echo "Installing Readline-8.0 ..."
sleep 2
tar -xvf readline-8.0.tar.gz
cd readline-8.0
#Reinstalling Readline will cause the old libraries to be moved to <libraryname>.old. While this is normally not a
#problem, in some cases it can trigger a linking bug in ldconfig. This can be avoided by issuing the following two sed
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

./configure --prefix=/usr		\
	--disable-static		 \
	--with-curses			\
	--docdir=/usr/share/doc/readline-8.0
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
#Now move the dynamic libraries to a more appropriate location and fix up some permissions and symbolic links:
mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
#If desired, install the documentation
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0


cd ../
rm -rf readline-8.0



#/* M4-1.4.18 */
echo "Installing M4-1.4.18 ..."
sleep 3
tar -xvf m4-1.4.18.tar.xz
cd m4-1.4.18
#First, make some fixes required by glibc-2.28 and later:
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make -j$(nproc)
make check 
make install

cd ../
rm -rf m4-1.4.18



#/*Bc-3.1.5 */
echo "Installing Bc-3.1.5 ..."
sleep 2
tar -xvf bc-3.1.5.tar.xz
cd bc-3.1.5
PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
make -j$(nproc)
make test
make install


cd ../
rm -rf bc-3.1.5

#/* Flex-2.6.4 */
echo "Installing Flex-2.6.4 ..."
sleep 2
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
make  -j$(nproc)
make check
make install
#A few programs do not know about flex yet and try to run its predecessor, lex. To support those programs, create a
#symbolic link named lex that runs flex in lex emulation mode:
ln -sv flex /usr/bin/lex

cd ../
rm -rf flex-2.6.4


#/* Binutils-2.35 */
echo "Installing Binutils-2.35 ..."
sleep 2
tar -xvf binutils-2.35.tar.xz
cd binutils-2.35
echo "Verify that the PTYs are working properly inside the chroot environment by performing a simple test: "
expect -c "spawn ls"

#Now remove one test that prevents the tests from running to completion:
sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
mkdir -pv build
cd build
../configure --prefix=/usr		\
		--enable-gold		\
		--enable-ld=default	\
		--enable-plugins	\
		--enable-shared		\
		--disable-werror	\
		--enable-64-bit-bfd	\
		--with-system-zlib
make tooldir=/usr
echo "The test suite for Binutils in this section is considered critical. Do not skip it under any circumstances."
make -k check
make tooldir=/usr install


cd ../..
rm -rf binutils-2.35


#/* GMP-6.2.0 */
echo "Installing GMP-6.2.0 ..."
sleep 2
tar -xvf gmp-6.2.0.tar.xz
cd gmp-6.2.0

#If you are building for 32-bit x86, but you have a CPU which is capable of running 64-bit code and you
#have specified CFLAGS in the environment, the configure script will attempt to configure for 64-bits and fail.
#Avoid this by invoking the configure command below with
ABI=32 ./configure ...
#The default settings of GMP produce libraries optimized for the host processor. If libraries suitable for
#processors less capable than the host's CPU are desired, generic libraries can be created by running the
#following:
cp -v configfsf.guess config.guess
cp -v configfsf.sub config.sub

./configure --prefix=/usr		\
	--enable-cxx			\
	--disable-static 		\
	--docdir=/usr/share/doc/gmp-6.2.0

make -j$(nproc)
make html
echo "The test suite for GMP in this section is considered critical. Do not skip it under any circumstances"
make check 2>&1 | tee gmp-check-log
echo "Ensure that all 197 tests in the test suite passed. Check the results by issuing the following command:"
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
echo "Install the package and its documentation:"
make install
make install-html

cd ../
rm -rf gmp-6.2.0


#/* MPFR-4.1.0 */
echo " Installing MPFR-4.1.0 ..."
sleep 2
tar -xvf mpfr-4.1.0.tar.xz
cd mpfr-4.1.0
./configure --prefix=/usr		\
	--disable-static		\
	--enable-thread-safe	 	\
	--docdir=/usr/share/doc/mpfr-4.1.0
make
make html
echo "The test suite for MPFR in this section is considered critical. Do not skip it under any circumstances"
make check
echo "Install the package and its documentation:"
make install
make install-html

cd ../
rm -rf mpfr-4.1.0



#/* MPC-1.1.0 */
echo "Installing MPC-1.1.0 ..."
sleep 2
tar -xvf mpc-1.1.0.tar.gz
cd mpc-1.1.0
./configure --prefix=/usr		\
	--disable-static 		\
	--docdir=/usr/share/doc/mpc-1.1.0
make
make html
echo "To test the results, issue:"
make check 
make install
make install-html


cd ../
rm -rf mpc-1.1.0


#/* Attr-2.4.48 */
echo "Installing Attr-2.4.48 ..."
sleep 2
tar -xvf attr-2.4.48.tar.gz
cd attr-2.4.48
./configure --prefix=/usr		\
	--disable-static		 \
	--sysconfdir=/etc 		 \
	--docdir=/usr/share/doc/attr-2.4.48
make 
#The tests need to be run on a filesystem that supports extended attributes such as the ext2, ext3, or ext4 filesystems.
#To test the results, issue:
make check 
make install
echo "The shared library needs to be moved to /lib, and as a result the .so file in /usr/lib will need to be recreated"
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so


cd ../
rm -rf attr-2.4.48


#/* Acl-2.2.53 */
echo "Installing Acl-2.2.53 ..."
sleep 2
tar -xvf acl-2.2.53.tar.gz
cd acl-2.2.53
./configure --prefix=/usr		\
	--disable-static		\
	--libexecdir=/usr/lib 		\
	--docdir=/usr/share/doc/acl-2.2.53
make 
make install
#The shared library needs to be moved to /lib, and as a result the .so file in /usr/lib will need to be recreated:
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so


cd ../
rm -rf acl-2.2.53


#/* Libcap-2.42 */
echo "Installing Libcap-2.42 ..."
sleep 2
tar -xvf libcap-2.42.tar.xz
cd libcap-2.42
echo "Prevent a static library from being installed:"
sed -i '/install -m.*STACAPLIBNAME/d' libcap/Makefile
make lib=lib
echo "To test the results, issue:"
make test
echo "Install the package and do some cleanup:"
make lib=lib PKGCONFIGDIR=/usr/lib/pkgconfig install
chmod -v 755 /lib/libcap.so.2.42
mv -v /lib/libpsx.a /usr/lib
rm -v /lib/libcap.so
ln -sfv ../../lib/libcap.so.2 /usr/lib/libcap.so

cd ../
rm -rf libcap-2.42

#/* Shadow-4.8.1 */
echo "Installing Shadow-4.8.1 ..."
sleep 2
tar -xvf shadow-4.8.1.tar.xz
cd shadow-4.8.1
echo "Disable the installation of the groups program and its man pages, as Coreutils provides a better version"
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

#If you chose to build Shadow with Cracklib support, run the following:
sed -i 's:DICTPATH.*:DICTPATH\t/lib/cracklib/pw_dict:' etc/login.defs
echo "Make a minor change to make the first group number generated by useradd 1000:"
sed -i 's/1000/999/' etc/useradd
echo "Prepare Shadow for compilation:"
touch /usr/bin/passwd
./configure --sysconfdir=/etc	 \
	--with-group-name-max-length=32
make 
make install
echo "Configuring Shadow"
echo "To enable shadowed passwords, run the following command:"
pwconv
echo "To enable shadowed group passwords, run:"
grpconv
echo "Setting the root password"
passwd root

cd ../
rm -rf shadow-4.8.1


#/* GCC-10.2.0 */
echo "Installing GCC-10.2.0 ..."
sleep 2
tar -xvf gcc-10.2.0.tar.xz
cd gcc-10.2.0
#If building on x86_64, change the default directory name for 64-bit libraries to lib:
case $(uname -m) in
x86_64)
sed -e '/m64=/s/lib64/lib/' \
	-i.orig gcc/config/i386/t-linux64	;;
esac

mkdir -pv build 
cd build 
../configure --prefix=/usr  		\
		LD=ld			\
		--enable-languages=c,c++	\
		--disable-multilib		\
		--disable-bootstrap		\
		--with-system-zlib

make -j$(nproc)
ulimit -s 32768
echo "Test the results as a non-privileged user, but do not stop at errors:"
chown -Rv tester .
su tester -c "PATH=$PATH make -k check"
echo "To receive a summary of the test suite results, run:"
../contrib/test_summary

echo "Install the package and remove an unneeded directory:"
make install
rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/10.2.0/include-fixed/bits/
echo "The GCC build directory is owned by tester now and the ownership of the installed header directory (and its
content) will be incorrect. Change the ownership to root user and group:"
chown -v -R root:root \
/usr/lib/gcc/*linux-gnu/10.2.0/include{,-fixed}
echo "Create a symlink required by the FHS for "historical" reasons."
ln -sv ../usr/bin/cpp /lib
echo "Add a compatibility symlink to enable building programs with Link Time Optimization (LTO):"
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/10.2.0/liblto_plugin.so \
	/usr/lib/bfd-plugins/
#Now that our final toolchain is in place, it is important to again ensure that compiling and linking will work as expected.
echo " performing some sanity checks:"
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

echo "Now make sure that we're setup to use the correct start files:"
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
echo "Verify that the compiler is searching for the correct header files:"
grep -B4 '^ /usr/include' dummy.log
echo " verifying  that the new linker is being used with the correct search paths:"
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
echo "make sure that we're using the correct libc:"
grep "/lib.*/libc.so.6 " dummy.log
echo "Make sure GCC is using the correct dynamic linker:"
grep found dummy.log
echo "Once everything is working correctly, clean up the test files"
rm -v dummy.c a.out dummy.log
#Finally, move a misplaced file:
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd ../../
rm -rf gcc-10.2.0


#/* Pkg-config-0.29.2 */
echo "Installing Pkg-config-0.29.2 ..."
sleep 2
tar -xvf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --prefix=/usr		\
	--with-internal-glib		\
	--disable-host-tool		\
	--docdir=/usr/share/doc/pkg-config-0.29.2

make 
make check
make install

cd ../
rm -rf pkg-config-0.29.2
  

#/*Ncurses-6.2 */
echo "Installing Ncurses-6.2 ..."
sleep 2
tar -xvf ncurses-6.2.tar.gz
cd ncurses-6.2
#Don't install a static library that is not handled by configure:
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
#Prepare Ncurses for compilation:
./configure --prefix=/usr		\
	--mandir=/usr/share/man		\
	--with-shared			\
	--without-debug			\
	--without-normal		\
	--enable-pc-files		\
	--enable-widec
make 
make install
#Move the shared libraries to the /lib directory, where they are expected to reside:
mv -v /usr/lib/libncursesw.so.6* /lib
#Because the libraries have been moved, one symlink points to a non-existent file. Recreate it:
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
#Many applications still expect the linker to be able to find non-wide-character Ncurses libraries. Trick such applications
#into linking with wide-character libraries by means of symlinks and linker scripts
for lib in ncurses form panel menu ; do
rm -vf	/usr/lib/lib${lib}.so
echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
ln -sfv ${lib}w.pc  /usr/lib/pkgconfig/${lib}.pc
done

#Finally, make sure that old applications that look for -lcurses at build time are still buildable:
rm -vf /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so /usr/lib/libcurses.so
#If desired, install the Ncurses documentation:
mkdir -v /usr/share/doc/ncurses-6.2
cp -v -R doc/* /usr/share/doc/ncurses-6.2

#The instructions above don't create non-wide-character Ncurses libraries since no package installed by
#compiling from sources would link against them at runtime. However, the only known binary-only
#applications that link against non-wide-character Ncurses libraries require version 5. If you must have such
#libraries because of some binary-only application or to be compliant with LSB, build the package again with
#the following commands:

make distclean
./configure --prefix=/usr		\
	--with-shared			\
	--without-normal		 \
	--without-debug 		\
	--without-cxx-binding 		\
	--with-abi-version=5
make sources libs
cp -av lib/lib*.so.5* /usr/lib


cd ../
rm -rf ncurses-6.2


#/* Sed-4.8 */
echo "Installing Sed-4.8 ..."
sleep 2
tar -xvf sed-4.8.tar.xz
cd sed-4.8
./configure --prefix=/usr --bindir=/bin
#Compile the package and generate the HTML documentation:
make
make html
#To test the results, issue:
chown -Rv tester .
su tester -c "PATH=$PATH make check"
#Install the package and its documentation:
make install
install -d -m755 /usr/share/doc/sed-4.8
install -m644 doc/sed.html /usr/share/doc/sed-4.8

cd ../
rm -rf sed-4.8


#/* Psmisc-23.3 */
echo "Installing Psmisc-23.3 ..."
sleep 2
tar -xvf psmisc-23.3.tar.xz
cd psmisc-23.3
#Prepare Psmisc for compilation:
./configure --prefix=/usr
#Compile the package:
make
#This package does not come with a test suite.
#Install the package:
make install
#Finally, move the killall and fuser programs to the location specified by the FHS:
mv -v /usr/bin/fuser /bin
mv -v /usr/bin/killall /bin

cd ../
rm -rf psmisc-23.3


#/* Gettext-0.21 */
echo "Installing Gettext-0.21 ..."
sleep 2
tar -xvf gettext-0.21.tar.xz
cd gettext-0.21

#Prepare Gettext for compilation:
./configure --prefix=/usr		\
	--disable-static		 \
	--docdir=/usr/share/doc/gettext-0.21
#Compile the package:
make
#To test the results (this takes a long time, around 3 SBUs), issue:
make check
#Install the package:
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd ../
rm -rf gettext-0.21
  

#/* Bison-3.7.1 */
echo "Installing Bison-3.7.1 ...."
sleep 2
tar -xvf bison-3.7.1.tar.xz
cd bison-3.7.1
#Prepare Bison for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.1
#Compile the package:
make
#To test the results (about 5.5 SBU), issue:
make check
#Install the package:
make install

cd ../
rm -rf bison-3.7.1




#/* Grep-3.4 */
echo "Installing Grep-3.4 ..."
sleep 2
tar -xvf grep-3.4.tar.xz
cd grep-3.4
#Prepare Grep for compilation:
./configure --prefix=/usr --bindir=/bin
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install

cd ../
rm -rf grep-3.4


#/*Bash-5.0 */
echo "Installing Bash-5.0 ..."
sleep 2
tar -xvf bash-5.0.tar.gz
cd bash-5.0
#ncorporate some upstream fixes:
patch -Np1 -i ../bash-5.0-upstream_fixes-1.patch
#repare Bash for compilation:
./configure --prefix=/usr			\
	--docdir=/usr/share/doc/bash-5.0 	\
	--without-bash-malloc			\
	--with-installed-readline
#Compile the package:
make
#To prepare the tests, ensure that the tester user can write to the sources tree
echo "To prepare the tests, ensure that the tester user can write to the sources tree:"
chown -Rv tester
#Now, run the tests as the tester user:
echo "Now, run the tests as the tester user:"
su tester << EOF
PATH=$PATH make tests < $(tty)
EOF
#Install the package and move the main executable to /bin:
make install
mv -vf /usr/bin/bash /bin
#Run the newly compiled bash program (replacing the one that is currently being executed):
exec /bin/bash --login +h

cd ../
rm -rf bash-5.0

#/* Libtool-2.4.6 */
echo "Installing Libtool-2.4.6 ..."
sleep 2
tar -xvf libtool-2.4.6.tar.xz
cd libtool-2.4.6
#Prepare Libtool for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
echo " Testing the results"
make check

#Install the package:
echo "Installing packages"
make install

cd ../
rm -rf libtool-2.4.6


#/*  GDBM-1.18.1 */
echo "Installing GDBM-1.18.1 ...."
sleep 2
tar -xvf gdbm-1.18.1.tar.gz
cd gdbm-1.18.1
#First, fix an issue first identified by gcc-10:
sed -r -i '/^char.*parseopt_program_(doc|args)/d' src/parseopt.c
#Prepare GDBM for compilation:
./configure --prefix=/usr		\
	--disable-static		 \
	--enable-libgdbm-compat
#Compile the package:
make
#To test the results, issue:
echo "testing results"
make check
#Install the package:
make install

cd ../
rm -rf gdbm-1.18.1


#/* Gperf-3.1 */
echo "Installing Gperf-3.1 ..."
sleep 2
tar -xvf gperf-3.1.tar.gz
cd gperf-3.1

#Prepare Gperf for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
#Compile the package:
make
#The tests are known to fail if running multiple simultaneous tests (-j option greater than 1). To test the results, issue:
echo "Testing results"
make -j1 check
#Install the package:
make install

cd ../
rm -rf gperf-3.1

#/* Expat-2.2.9 */
echo "Installing Expat-2.2.9 ..."
sleep 2
tar -xvf expat-2.2.9.tar.xz
cd expat-2.2.9

#Prepare Expat for compilation:
./configure --prefix=/usr		\
	--disable-static \
	--docdir=/usr/share/doc/expat-2.2.9
#Compile the package:
make
#To test the results, issue:
echo "Testing result "
make check
#Install the package:
make install
#If desired, install the documentation:
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.9

cd ../
rm -rf expat-2.2.9


#/* Inetutils-1.9.4 */
echo "Installing Inetutils-1.9.4 ..."
sleep 2
tar -xvf inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
#Prepare Inetutils for compilation:
./configure --prefix=/usr		\
	--localstatedir=/var		\
	--disable-logger		\
	--disable-whois			\
	--disable-rcp			\
	--disable-rexec			\
	--disable-rlogin		\
	--disable-rsh			\
	--disable-servers

#Compile the package:
make
#To test the results, issue:
echo "Testing result "
make check

#Install the package:
make install
#Move some programs so they are available if /usr is not accessible:
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin

cd ../
rm -rf inetutils-1.9.4


#/*Perl-5.32.0 */
echo "Installing Perl-5.32.0 "
sleep 2
tar -xvf perl-5.32.0.tar.xz
cd perl-5.32.0
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des					\
	-Dprefix=/usr					\
	-Dvendorprefix=/usr				\
	-Dprivlib=/usr/lib/perl5/5.32/core_perl		\
	-Darchlib=/usr/lib/perl5/5.32/core_perl		\
	-Dsitelib=/usr/lib/perl5/5.32/site_perl		\
	-Dsitearch=/usr/lib/perl5/5.32/site_perl	\
	-Dvendorlib=/usr/lib/perl5/5.32/vendor_perl	\
	-Dvendorarch=/usr/lib/perl5/5.32/vendor_perl	\
	-Dman1dir=/usr/share/man/man1			\
	-Dman3dir=/usr/share/man/man3			\
	-Dpager="/usr/bin/less -isR"			\
	-Duseshrplib					\
	-Dusethreads
#Compile the package:
make
#To test the results (approximately 11 SBU), issue:
echo "Testing results "
make test
#Install the package and clean up:
make install
unset BUILD_ZLIB BUILD_BZIP2

cd ../
rm -rf perl-5.32.0


#/* XML::Parser-2.46 */
echo "Installing XML::Parser-2.46 ..."
sleep 2
tar -xvf XML-Parser-2.46.tar.gz
cd XML-Parser-2.46
#Prepare XML::Parser for compilation:
perl Makefile.PL
#Compile the package:
make
#To test the results, issue:
make test
#Install the package:
make install

cd ../
r -rf XML-Parser-2.46 

#/* Intltool-0.51.0 */
echo "Installing Intltool-0.51.0 ..."
sleep 2
tar -xvf intltool-0.51.0.tar.gz
cd intltool-0.51.0
#First fix a warning that is caused by perl-5.22 and later:
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
#Prepare Intltool for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
echo "Testing rsults "
make check
#Install the package:
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO


cd ../
rm -rf intltool-0.51.0



#/* Autoconf-2.69 */
echo "Installing Autoconf-2.69 ..."
sleep 2
tar -xvf autoconf-2.69.tar.xz
cd autoconf-2.69
#First, fix a bug generated by Perl 5.28.
sed -i '361 s/{/\\{/' bin/autoscan.in

#Prepare Autoconf for compilation:
./configure --prefix=/usr
#Compile the package:
make
#The test suite is currently broken by bash-5 and libtool-2.4.3. To run the tests anyway, issue:
echo "testing results"
make check
#Install the package:
make install

cd ../
rm -rf autoconf-2.69


#/* Automake-1.16.2 */
echo "Installing Automake-1.16.2 ..."
sleep 2
tar -xvf automake-1.16.2.tar.xz
cd automake-1.16.2
Fix a failing test:
sed -i "s/''/etags/" t/tags-lisp-space.sh
#Prepare Automake for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.2
#Compile the package:
make
#Using the -j4 make option speeds up the tests, even on systems with only one processor, due to internal delays in
#individual tests. To test the results, issue:
make -j4 check
#The test t/subobj.sh is known to fail in the LFS environment.
#Install the package:
make install

cd ../
rm -rf automake-1.16.2


#/* Kmod-27 */
echo "Installing Kmod-27 "
sleep 2
tar -xvf kmod-27.tar.xz
cd kmod-27
#Prepare Kmod for compilation:
./configure --prefix=/usr		\
	--bindir=/bin			\
	--sysconfdir=/etc		\
	--with-rootlibdir=/lib		\
	--with-xz			\
	--with-zlib
#Compile the package:
make

#Install the package and create symlinks for compatibility with Module-Init-Tools (the package that previously handled
#Linux kernel modules):
make install
for target in depmod insmod lsmod modinfo modprobe rmmod; do
ln -sfv ../bin/kmod /sbin/$target
done
ln -sfv kmod /bin/lsmod

cd ../
rm -rf kmod-27

#/* Libelf from Elfutils-0.180 */
echo " Installing Libelf from Elfutils-0.180 "
sleep 2
tar -xvf elfutils-0.180.tar.bz2
cd elfutils-0.180

#Prepare Libelf for compilation:
./configure --prefix=/usr --disable-debuginfod --libdir=/lib
#Compile the package:
make
#To test the results, issue:
make check
#Install only Libelf:
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /lib/libelf.a

cd ../
rm -rf elfutils-0.180


#/* Libffi-3.3 */
echo "Installing Libffi-3.3 ..."
sleep 2
tar -xvf libffi-3.3.tar.gz
cd libffi-3.3

#Prepare libffi for compilation:
./configure --prefix=/usr --disable-static --with-gcc-arch=native
#Compile the package:
make 
#To test the results, issue:
make check 
#Install the package:
make install

cd ../
rm -rf libffi-3.3


#/* OpenSSL-1.1.1g  */
echo "Installing  OpenSSL-1.1.1g ..."
sleep 2
tar -xvf openssl-1.1.1g.tar.gz
cd openssl-1.1.1g
#Prepare OpenSSL for compilation:
./config --prefix=/usr			\
	--openssldir=/etc/ssl		\
	--libdir=lib			\
	shared				\
	zlib-dynamic
#Compile the package:
make
#To test the results, issue:
make test

#Install the package:
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
#If desired, install the documentation:
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1g
cp -vfr doc/* /usr/share/doc/openssl-1.1.1g


cd ../
rm -rf openssl-1.1.1g


#/* Python-3.8.5 */
echo "Installing Python-3.8.5 ..."
sleep 2
tar -xvf Python-3.8.5.tar.xz
cd Python-3.8.5
#Prepare Python for compilation:
./configure --prefix=/usr		\
	--enable-shared			\
	--with-system-expat		 \
	--with-system-ffi		\
	--with-ensurepip=yes
#Compile the package:
make
#Install the package:
make install
chmod -v 755 /usr/lib/libpython3.8.so
chmod -v 755 /usr/lib/libpython3.so
ln -sfv pip3.8 /usr/bin/pip3
#If desired, install the preformatted documentation:
install -v -dm755 /usr/share/doc/python-3.8.5/html
tar --strip-components=1 	\	
	--no-same-owner		\
	--no-same-permissions 	\
	-C /usr/share/doc/python-3.8.5/html 	\
	-xvf ../python-3.8.5-docs-html.tar.bz2
cd ../
rm -rf Python-3.8.5


#/* Ninja-1.10.0 */
echo "Installing Ninja-1.10.0 ..."
sleep 2
tar -xvf ninja-1.10.0.tar.gz
cd ninja-1.10.0.
export NINJAJOBS=4
#If desired, add the capability to use the environment variable NINJAJOBS by running:
sed -i '/int Guess/a \
	int
	j = 0;\
	char* jobs = getenv( "NINJAJOBS" );\
	if ( jobs != NULL ) j = atoi( jobs );\
	if ( j > 0 ) return j;\
' src/ninja.cc

#Build Ninja with:
python3 configure.py --bootstrap
#To test the results, issue:
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
#Install the package:
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja

cd ../
rm -rf ninja-1.10.0


#/*Meson-0.55.0 */
echo "Installing Meson-0.55.0 ..."
sleep 2
tar -xvf meson-0.55.0.tar.gz
cd meson-0.55.0
#Compile Meson with the following command:
python3 setup.py build
#This package does not come with a test suite.
#Install the package:
python3 setup.py install --root=dest
cp -rv dest/* /


cd ../
rm -rf meson-0.55.0


#/* Coreutils-8.32 */
echo "Installing Coreutils-8.32 ..."
sleep 2
tar -xvf coreutils-8.32.tar.xz
cd coreutils-8.32
patch -Np1 -i ../coreutils-8.32-i18n-1.patch
#Suppress a test which on some machines can loop forever:
sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
#Now prepare Coreutils for compilation:
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure	 \
	--prefix=/usr					\
	--enable-no-install-program=kill,uptime
#Compile the package:
make
#Now the test suite is ready to be run. First, run the tests that are meant to be run as user root:
make NON_ROOT_USERNAME=tester check-root

echo "We're going to run the remainder of the tests as the tester user. Certain tests require that the user be a member of
more than one group. So that these tests are not skipped, add a temporary group and make the user tester a part of it:"
echo "dummy:x:102:tester" >> /etc/group
echo "Fix some of the permissions so that the non-root user can compile and run the tests:"
chown -Rv tester .
echo "Now run the tests:"
su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
echo "Removing  the temporary group:"
sed -i '/dummy/d' /etc/group
#Install the package:
make install
#Move programs to the locations specified by the FHS:
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,nice,sleep,touch} /bin

cd ../
rm -rf coreutils-8.32


#/* Check-0.15.2 */
echo "Installing Check-0.15.2 ..."
sleep 2
tar -xvf check-0.15.2.tar.gz
cd check-0.15.2
#Prepare Check for compilation:
./configure --prefix=/usr --disable-static
#Build the package:
make
#Compilation is now complete. To run the Check test suite, issue the following command:
make check
#Note that the Check test suite may take a relatively long (up to 4 SBU) time.
#Install the package:
make docdir=/usr/share/doc/check-0.15.2 install


cd ../
rm -rf check-0.15.2


#/* Diffutils-3.7 */
echo "Installing Diffutils-3.7 ..."
sleep 2
tar -xvf diffutils-3.7.tar.xz
cd diffutils-3.7
#Prepare Diffutils for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install

cd ../
rm -rf diffutils-3.7


#/* Gawk-5.1.0 */
echo "Installing Gawk-5.1.0 ..."
sleep 2
tar -xvf gawk-5.1.0.tar.xz
cd gawk-5.1.0
#First, ensure some unneeded files are not installed:
sed -i 's/extras//' Makefile.in
#Prepare Gawk for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install
#If desired, install the documentation:
mkdir -v /usr/share/doc/gawk-5.1.0
cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.0


cd ../
rm -rf gawk-5.1.0


#/* Findutils-4.7.0 */
echo "Installing Findutils-4.7.0 ..."
sleep 2
tar -xvf findutils-4.7.0.tar.xz
cd findutils-4.7.0
#Prepare Findutils for compilation:
./configure --prefix=/usr --localstatedir=/var/lib/locate
#Compile the package:
make
#To test the results, issue:
chown -Rv tester .
su tester -c "PATH=$PATH make check"
#Install the package:
make install
#Some packages in BLFS and beyond expect the find program in /bin, so make sure it's placed there:
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb

cd ../
rm -rf findutils-4.7.0

#/* Groff-1.22.4 */
echo "Installing Groff-1.22.4 .."
sleep 2
tar -xvf groff-1.22.4.tar.gz
cd groff-1.22.4
#Prepare Groff for compilation:
PAGE=A4 ./configure --prefix=/usr
#This package does not support parallel build. Compile the package:
make -j1
#This package does not come with a test suite.
#Install the package:
make install

cd ../
rm -rf groff-1.22.4


#/*GRUB-2.04 */
echo "Installing GRUB-2.04 ..."
sleep 2
tar -xvf grub-2.04.tar.xz
cd grub-2.04
#Prepare GRUB for compilation:
./configure --prefix=/usr		\
	--sbindir=/sbin			\
	--sysconfdir=/etc		\
	--disable-efiemu		\
	--disable-werror
#Compile the package:
make
#This package does not come with a test suite.
#Install the package:
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd ../
rm -rf grub-2.04


#/*Less-551 */
echo "Installing Less-551 ..."
sleep 2
tar -xvf less-551.tar.gz
cd less-551
#Prepare Less for compilation:
./configure --prefix=/usr --sysconfdir=/etc
#Compile the package:
make
#This package does not come with a test suite.
#Install the package:
make install

cd ../
rm -rf less-551


#/* Gzip-1.10 */
echo "Installing Gzip-1.10 ..."
sleep 2
tar -xvf gzip-1.10.tar.xz
cd gzip-1.10
#Prepare Gzip for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install
#Move a program that needs to be on the root filesystem:
mv -v /usr/bin/gzip /bin

cd ../
rm -rf gzip-1.10


#/* IPRoute2-5.8.0 */
echo "Installing IPRoute2-5.8.0 ..."
sleep 2
tar -xvf iproute2-5.8.0.tar.xz
cd iproute2-5.8.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
#It is also necessary to disable building two modules that require http://www.linuxfromscratch.org/blfs/view/10.0/postlfs/
#iptables.html.
sed -i 's/.m_ipt.o//' tc/Makefile
#Compile the package:
make
#This package does not have a working test suite.
#Install the package:
make DOCDIR=/usr/share/doc/iproute2-5.8.0 install

cd ../
rm -rf iproute2-5.8.0

#/* Kbd-2.3.0 */
echo "Installing Kbd-2.3.0 ..."
sleep 2
tar -xvf kbd-2.3.0.tar.xz
cd kbd-2.3.0
patch -Np1 -i ../kbd-2.3.0-backspace-1.patch
#Prepare Kbd for compilation:
./configure --prefix=/usr --disable-vlock
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install
#Remove an internal library installed unintentionally:
rm -v /usr/lib/libtswrap.{a,la,so*}
#If desired, install the documentation:
mkdir -v /usr/share/doc/kbd-2.3.0
cp -R -v docs/doc/* /usr/share/doc/kbd-2.3.0

cd ../
rm -rf kbd-2.3.0


#/* Libpipeline-1.5.3 */
echo "Installing Libpipeline-1.5.3 ..."
sleep 2
tar -xvf libpipeline-1.5.3.tar.gz
cd libpipeline-1.5.3
#Prepare Libpipeline for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install

cd ../
rm -rf libpipeline-1.5.3


#/* Make-4.3 */
echo "Installing Make-4.3 ..."
sleep 2
tar -xvf make-4.3.tar.gz
cd make-4.3
#Prepare Make for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install

cd ../
rm -rf make-4.3


#/* Patch-2.7.6 */
echo "Installing Patch-2.7.6 "
sleep 2
tar -xvf patch-2.7.6.tar.xz
cd patch-2.7.6
#Prepare Patch for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install

cd ../
rm -rf patch-2.7.6

#/*Man-DB-2.9.3 */
echo "Installing Man-DB-2.9.3 ..."
sleep 2
tar -xvf man-db-2.9.3.tar.xz
cd man-db-2.9.3
#Prepare Man-DB for compilation:
sed -i '/find/s@/usr@@' init/systemd/man-db.service.in
./configure --prefix=/usr			\
	--docdir=/usr/share/doc/man-db-2.9.3	\
	--sysconfdir=/etc			\
	--disable-setuid			\
	--enable-cache-owner=bin		\
	--with-browser=/usr/bin/lynx		\
	--with-vgrind=/usr/bin/vgrind		\
	--with-grap=/usr/bin/grap
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install

cd ../
rm -rf man-db-2.9.3


#/* Tar-1.32 */
echo "Installing Tar-1.32 ..."
sleep 2
tar -xvf tar-1.32.tar.xz
cd tar-1.32
#Prepare Tar for compilation:
FORCE_UNSAFE_CONFIGURE=1 \
./configure --prefix=/usr \
	--bindir=/bin
#Compile the package:
make
#To test the results (about 3 SBU), issue:
make check
#One test, capabilities: binary store/restore, is known to fail.
#Install the package:
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.32

cd ../
rm -rf tar-1.32


#/* Texinfo-6.7 */
echo "Installing Texinfo-6.7 ..."
sleep 2
tar -xvf texinfo-6.7.tar.xz
cd texinfo-6.7

#Prepare Texinfo for compilation:
./configure --prefix=/usr --disable-static
#Compile the package:
make
#To test the results, issue:
make check
#Install the package:
make install
#Optionally, install the components belonging in a TeX installation:
make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
	rm -v dir
	for f in *
		do install-info $f dir 2>/dev/null
done
popd

cd ../
rm -rf texinfo-6.7


#/* Vim-8.2.1361 */
echo "Installing Vim-8.2.1361 ...."
sleep 2
tar -xvf vim-8.2.1361.tar.gz
cd vim-8.2.1361
#First, change the default location of the vimrc configuration file to /etc:
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
#Prepare vim for compilation:
./configure --prefix=/usr
#Compile the package:
make
#To prepare the tests, ensure that user tester can write to the source tree:
chown -Rv tester .
#Now run the tests as user tester:
su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
#Install the package:
make install
#Many users are used to using vi instead of vim. To allow execution of vim when users habitually enter vi, create a
#symlink for both the binary and the man page in the provided languages:
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
ln -sv vim.1 $(dirname $L)/vi.1
done
#By default, vim's documentation is installed in /usr/share/vim. The following symlink allows the documentation
#to be accessed via /usr/share/doc/vim-8.2.1361, making it consistent with the location of documentation
#for other packages:
ln -sv ../vim/vim82/doc /usr/share/doc/vim-8.2.1361


#Configuring Vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc
" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
set background=dark
endif
" End /etc/vimrc
EOF
#Documentation for other available options can be obtained by running the following command:
vim -c ':options'


cd ../
rm -rf vim-8.2.1361


#/* Systemd-246 */
echo "Installing Systemd-246 ..."
sleep 2
tar -xvf systemd-246.tar.gz
cd systemd-246
#Create a symlink to work around the xsltproc command not being installed:
ln -sf /bin/true /usr/bin/xsltproc
#Set up the man pages:
tar -xf ../systemd-man-pages-246.tar.xz
#Remove tests that cannot be built in chroot:
sed '177,$ d' -i src/resolve/meson.build
#Remove an unneeded group, render, from the default udev rules:
sed -i 's/GROUP="render", //' rules.d/50-udev-default.rules.in

#Prepare systemd for compilation:
mkdir -pv build
cd build
LANG=en_US.UTF-8		\
meson --prefix=/usr		\
	--sysconfdir=/etc		\
	--localstatedir=/var		\
	-Dblkid=true			\
	-Dbuildtype=release		\
	-Ddefault-dnssec=no		\
	-Dfirstboot=false		\
	-Dinstall-tests=false		\
	-Dkmod-path=/bin/kmod		\
	-Dldconfig=false		\
	-Dmount-path=/bin/mount		\
	-Drootprefix=			\
	-Drootlibdir=/lib		\
	-Dsplit-usr=true		\
	-Dsulogin-path=/sbin/sulogin \
	-Dsysusers=false		\
	-Dumount-path=/bin/umount	\
	-Db_lto=false			\
	-Drpmmacrosdir=no		\
	-Dhomed=false			\
	-Duserdb=false			\
	-Dman=true			\
	-Ddocdir=/usr/share/doc/systemd-246 \
	..
#Compile the package:
LANG=en_US.UTF-8 ninja
#Install the package:
LANG=en_US.UTF-8 ninja install
#Remove an unnecessary symbolic link:
rm -f /usr/bin/xsltproc
#Create the /etc/machine-id file needed by systemd-journald:
systemd-machine-id-setup
#Setup the basic target structure:
systemctl preset-all
#Disable a service that is known to cause problems with systems that use a network configuration other than what is
#provided by systemd-networkd:
systemctl disable systemd-time-wait-sync.service
#Prevent systemd from resetting the maximum PID value which causes some problems with packages and units in BLFS:
rm -f /usr/lib/sysctl.d/50-pid-max.conf


cd ../
rm -rf systemd-246


#/* D-Bus-1.12.20 */
echo "Installing D-Bus-1.12.20 ..."
sleep 2
tar -xvf dbus-1.12.20.tar.gz
cd dbus-1.12.20
#Prepare D-Bus for compilation:
./configure --prefix=/usr			\
	--sysconfdir=/etc			\
	--localstatedir=/var			\
	--disable-static			\
	--disable-doxygen-docs			\
	--disable-xml-docs			\
	--docdir=/usr/share/doc/dbus-1.12.20	 \
	--with-console-auth-dir=/run/console
#Compile the package:
make
#Install the package:
make install
#The shared library needs to be moved to /lib, and as a result the .so file in /usr/lib will need to be recreated:
mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so
#Create a symlink so that D-Bus and systemd can use the same machine-id file:
ln -sfv /etc/machine-id /var/lib/dbus
#Move the socket file to /run instead of the deprecated /var/run:
sed -i 's:/var/run:/run:' /lib/systemd/system/dbus.socket

cd ../
rm -rf dbus-1.12.20


#/* Procps-ng-3.3.16 */
echo "Installing Procps-ng-3.3.16 ..."
sleep 2
tarv -xvf procps-ng-3.3.16.tar.xz
cd procps-ng-3.3.16
Prepare procps-ng for compilation:
./configure --prefix=/usr		\
	--exec-prefix=			\
	--libdir=/usr/lib		\
	--docdir=/usr/share/doc/procps-ng-3.3.16	\
	--disable-static		\
	--disable-kill			\
	--with-systemd
#Compile the package:
make
#To run the test suite, run:
make check
#Install the package:
make install
#Finally, move essential libraries to a location that can be found if /usr is not mounted.
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

cd ../
rm -rf procps-ng-3.3.16

#/*Util-linux-2.36 */
echo "Installing Util-linux-2.36 .."
sleep 2
tar -xvf util-linux-2.36.tar.xz
cd util-linux-2.36
#The FHS recommends using the /var/lib/hwclock directory instead of the usual /etc directory as the location
#for the adjtime file. Create this directory with:
mkdir -pv /var/lib/hwclock
#Prepare Util-linux for compilation:
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime	\
	--docdir=/usr/share/doc/util-linux-2.36 	\
	--disable-chfn-chsh 				\
	--disable-login					\
	--disable-nologin				\
	--disable-su					\
	--disable-setpriv				\
	--disable-runuser				\
	--disable-pylibmount 				\
	--disable-static				\
	--without-python
#Compile the package:
make
#Install the package:
make install


cd ../
rm -rf util-linux-2.36

#/* E2fsprogs-1.45.6 */
echo "Installing E2fsprogs-1.45.6 ..."
sleep 2
tar -xvf e2fsprogs-1.45.6.tar.gz
cd e2fsprogs-1.45.6
#The e2fsprogs documentation recommends that the package be built in a subdirectory of the source tree:
mkdir -v build
cd build
#Prepare e2fsprogs for compilation:
../configure --prefix=/usr		\
	--bindir=/bin			\
	--with-root-prefix=""		\
	--enable-elf-shlibs		\
	--disable-libblkid		\
	--disable-libuuid		\
	--disable-uuidd			\
	--disable-fsck
#Compile the package:
make
#To run the tests, issue:
make check
#On a spinning disk, the tests take a little more than 4 SBUs. They can be much shorter on an SSD (down to about
#1.5 SBUs).
#Install the package:
make install
Make the installed static libraries writable so debugging symbols can be removed later:
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
#This package installs a gzipped .info file but doesn't update the system-wide dir file. Unzip this file and then update
@the system dir file using the following commands:
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
#If desired, create and install some additional documentation by issuing the following commands:
makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

cd ../../
rm -rf e2fsprogs-1.45.6

#/* Stripping Again  */
echo "Stripping Again ..."
sleep 5
#First place the debugging symbols for selected libraries in separate files. This debugging information is needed if
#running regression tests that use valgrind or gdb later in BLFS.
save_lib="ld-2.32.so libc-2.32.so libpthread-2.32.so libthread_db-1.0.so"
cd /lib
for LIB in $save_lib; do
	objcopy --only-keep-debug $LIB $LIB.dbg
	strip --strip-unneeded $LIB
	objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done
save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.28
	libitm.so.1.0.0 libatomic.so.1.2.0"
cd /usr/lib
for LIB in $save_usrlib; do
	objcopy --only-keep-debug $LIB $LIB.dbg
	strip --strip-unneeded $LIB
	objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done
unset LIB save_lib save_usrlib
#Now the binaries and libraries can be stripped:
find /usr/lib -type f -name \*.a \
	-exec strip --strip-debug {} ';'
find /lib /usr/lib -type f -name \*.so* ! -name \*dbg \
	-exec strip --strip-unneeded {} ';'
find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
	-exec strip --strip-all {} ';'



#/* Cleaning Up */
echo "Cleaning Up ..."
sleep 5
#Finally, clean up some extra files left around from running tests:
rm -rf /tmp/*

#Now log out and reenter the chroot environment with an updated chroot command. From now on, use this updated
#chroot command any time you need to reenter the chroot environment after exiting:
logout
chroot "$LFS" /usr/bin/env -i		\
	HOME=/root TERM="$TERM"		\
	PS1='(lfs chroot) \u:\w\$ '	\
	PATH=/bin:/usr/bin:/sbin:/usr/sbi	\n
	/bin/bash --login

#There were several static libraries that were not suppressed earlier in the chapter in order to satisfy the regression tests in
#several packages. These libraries are from binutils, bzip2, e2fsprogs, flex, libtool, and zlib. If desired, remove them now:

rm -f /usr/lib/lib{bfd,opcodes}.a
rm -rf /usr/lib/libctf{,-nobfd}.a
rm -rf /usr/lib/libbz2.a
rm -rf /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -rf /usr/lib/libltdl.a
rm -rf /usr/lib/libfl.a
rm -rf /usr/lib/libz.a

find /usr/lib /usr/libexec -name \*.la -delete
#For more information about libtool archive files, see the BLFS section "About Libtool Archive (.la) files".
#The compiler built in Chapter 6 and Chapter 7 is still partially installed and not needed anymore. Remove it with:
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
#The /tools directory can also be removed to further gain some place:
rm -rf /tools
#Finally, remove the temporary 'tester' user account created at the beginning of the previous chapter.
userdel -r tester


#<------------------------------------------------------DONE --------------------------------------------------------->

#/* Author */
#Gaurav Gautam Shakya
#Electrical Engineer 
#Linux Adminstrator
#E-MAIL<hkrgs1234@gmail.com>
