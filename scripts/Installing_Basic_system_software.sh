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

