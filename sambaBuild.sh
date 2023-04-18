#!/bin/bash

#Samba

#Setup env vars
mkdir /root/workspace/logs
export ROOTDIR="${PWD}"
mkdir $ROOTDIR/build
export CROSS_COMPILE="arm-linux-gnueabihf"
cd ~/workspace/
export HOST=arm-linux-gnueabihf
export BUILD=x86_64-linux-gnu
export CPPFLAGS="-I${ROOTDIR}/build/include"
export LDFLAGS="-L/opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib -L${ROOTDIR}/build/lib"
export CFLAGS="-I$ROOTDIR/build/include -O3 -ffunction-sections -fdata-sections -fPIC"
export PATH="$PATH:$ROOTDIR/build/bin"
export PATH="$PATH:$ROOTDIR/build/include"
export AR=arm-linux-gnueabihf-ar
export AS=arm-linux-gnueabihf-as
export RANLIB=arm-linux-gnueabihf-ranlib
export CC=arm-linux-gnueabihf-gcc
export NM=arm-linux-gnueabihf-nm
export CXX=arm-linux-gnueabihf-g++

#Copy these files to lib to stop test failures on bins, not really needed in most cases.
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/ld-linux-armhf.so.3 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libpthread.so.0 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libc.so.6 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libm.so.6 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libcrypt.so.1 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libdl.so.2 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libutil.so.1 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libstdc++.so.6 /lib/

# Download required files
wget https://download.samba.org/pub/samba/stable/samba-4.18.1.tar.gz
wget https://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz
wget https://ftp.gnu.org/gnu/m4/m4-latest.tar.xz
wget https://ftp.gnu.org/gnu/nettle/nettle-3.8.1.tar.gz
wget https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
wget http://zlib.net/zlib-1.2.13.tar.gz
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.16.tar.xz
wget https://ftp.gnu.org/gnu/texinfo/texinfo-7.0.3.tar.xz
wget https://www.openssl.org/source/openssl-3.1.0.tar.gz
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
wget https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz
wget https://github.com/westes/flex/releases/download/v2.6.3/flex-2.6.3.tar.gz
# wget https://github.com/libarchive/libarchive/releases/download/v3.6.2/libarchive-3.6.2.tar.xz
wget http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
# wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.4.tgz
# wget https://github.com/linux-pam/linux-pam/releases/download/v1.5.2/Linux-PAM-1.5.2.tar.xz
wget http://digip.org/jansson/releases/jansson-2.5.tar.gz
wget https://web.mit.edu/kerberos/dist/krb5/1.20/krb5-1.20.1.tar.gz
wget http://download.savannah.nongnu.org/releases/attr/attr-2.5.1.tar.xz

#PKGConfig (Required by samba to locate gnutls)
tar -xf pkg-config-0.29.2.tar.gz &
wait $!
cd pkg-config-0.29.2 
./configure CC=$CC AR=$AR RANLIB=$RANLIB LD=$LD --host=$HOST --build=$BUILD --target=$TARGET --prefix=$ROOTDIR/build --disable-shared --with-internal-glib glib_cv_stack_grows=no glib_cv_stack_grows=no glib_cv_uscore=no ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes &
wait $!
make -j8 && make install > ../logs/Pkgconfigbuildlog.txt 2>&1  &
wait $!
cp /root/workspace/pkg-config-0.29.2/pkg-config /root/workspace/build/bin/ &
wait $!
export PKG_CONFIG_PATH="/root/workspace/build/lib/pkgconfig/"
export PKG_CONFIG="/root/workspace/build/bin/pkg-config"
cd ..

# m4 (required by autoconf for the M4_GNU var)
tar -xf m4-latest.tar.xz &
wait $!
cd m4-1.4.19
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/m4buildlog.txt 2>&1 &
wait $!
cd ..

#autoconf 
tar -xf autoconf-latest.tar.gz &
wait $!
cd autoconf-2.71
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build M4=$ROOTDIR/build/bin/m4 --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/autoconfbuildlog.txt 2>&1 &
wait $!
cd ..

#Cross compile jansson json (required by samba)
tar -xf jansson-2.5.tar.gz
cd jansson-2.5
./configure CC=$CC --host=$HOST --build=$BUILD --target=$TARGET --prefix=$ROOTDIR/build &
wait $!
make clean && make -j8 && make install &&  > ../logs/jsonbuildlog.txt 2>&1 &
wait $!
cd ..

# Crosscompile zlib package (required by samba)
tar zxf zlib-1.2.13.tar.gz & 
wait $!
cd zlib-1.2.13/
./configure --prefix=$ROOTDIR/build --static & 
wait $!
# sed -i 's/CC=gcc/CC=\/opt\/miyoomini-toolchain\/bin\/arm-linux-gnueabihf-gcc/' Makefile
# sed -i 's/CPP=/CPP=\/opt\/miyoomini-toolchain\/bin\/arm-linux-gnueabihf-gcc -E/' Makefile
# sed -i 's/RANLIB=ranlib/RANLIB=\/opt\/miyoomini-toolchain\/bin\/arm-linux-gnueabihf-gcc-ranlib/' Makefile
# sed -i 's/LDSHARED=gcc/LDSHARED=arm-linux-gnueabi-gcc -shared -Wl,-soname,libz.so.1,--sed version-script,zlib.map/g' Makefile
make clean && make -j8 && make install > ../logs/ZLIBbuildlog.txt 2>&1 &
wait $!
cd ..

# Compile OpenSSL (required by samba)
## You should be in openssl directory
export CROSS_COMPILE="" 
tar -xf openssl-3.1.0.tar.gz & 
wait $!
cd openssl-3.1.0
CFLAGS="-Xlinker -rpath=/mnt/SDCARD/.tmp_update/lib" ./Configure --prefix=$ROOTDIR/build --openssldir=$HOME linux-generic32 shared -DL_ENDIAN PROCESSOR=ARM &
wait $!
sed -i 's/-m64//g' Makefile
make clean && make -j8 && make install > ../logs/openssl.txt &
wait $!
cd ..
export CROSS_COMPILE="arm-linux-gnueabihf" 
export OPENSSL_INCLUDES="/root/workspace/build/include/openssl"
export OPENSSL_LIBS="/root/workspace/build/lib"
export OPENSSL_LDFLAGS="-Wl,-rpath=/root/workspace/build/lib"


# bison (required by samba)
tar -xf bison-3.8.2.tar.xz &
wait $!
cd bison-3.8.2
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/bisonbuildlog.txt 2>&1 &
wait $!
cd ..

# flex (required by samba) use flex 2.6.3 as 2.6.4 contains a segfault & dumps the core trying to make: https://lists.gnu.org/archive/html/help-octave/2017-12/msg00086.html
tar -xf flex-2.6.3.tar.gz &
wait $!
cd flex-2.6.3
CFLAGS='-g -O2 -D_GNU_SOURCE' ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/flexbuildlog.txt 2>&1 &
wait $!
cd ..

# libarchive - required by samba for smbclient tar support
# tar -xf libarchive-3.6.2.tar.xz &
# wait $!
# cd libarchive-3.6.2
# ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
# wait $!
# make clean && make -j8 && make install > ../logs/libarchbuildlog.txt 2>&1 &
# wait $!
# cd ..


# Openldap (required by samba for LDAP capability)
# tar -xf openldap-2.6.4.tgz &
# wait $!
# cd openldap-2.6.4
# ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build ac_cv_func_memcmp_working=yes --enable-shared --with-yielding_select=yes  &
# wait $!
# make depend
# make -j8 && make install > ../logs/ldapbuildlog.txt 2>&1 &
# wait $!
# cd ..

# libattr - required by libacl
tar -xf attr-2.5.1.tar.xz &
wait $!
cd attr-2.5.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/attrbuildlog.txt 2>&1 &
wait $!
cd ..

# libacl - required by samba for permissions
tar -xf acl-2.3.1.tar.xz &
wait $!
cd acl-2.3.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/aclbuildlog.txt 2>&1 &
wait $!
cd ..

# texinfo (required by gnutls for MAKEINFO)
tar -xf texinfo-7.0.3.tar.xz &
wait $!
cd texinfo-7.0.3
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/texibuildlog.txt 2>&1 &
wait $!
cd ..

#gmp/gmp-6 - required by gnutls
tar -xf gmp-6.2.1.tar.xz &
wait $!
cd gmp-6.2.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --enable-shared &
wait $!
make clean && make -j8 && make install > ../logs/gmpbuildlog.txt 2>&1 &
wait $!
cd ..

export GMP_LIBS="-L$ROOTDIR/build/lib"
export GMP_CFLAGS="-I$ROOTDIR/build/include"

#nettle/nettle-3 - required by gnutls
tar -xf nettle-3.8.1.tar.gz &
wait $!
cd nettle-3.8.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build M4_GNU=$ROOTDIR/build/bin/m4 --disable-assembler --enable-mini-gmp --enable-shared
wait $!
make clean && make -j8 && make install > ../logs/nettlebuildlog.txt 2>&1 &
wait $!
cd ..

export NETTLE_LIBS="-L$ROOTDIR/build/lib -lnettle"
export NETTLE_CFLAGS="-I$ROOTDIR/build/include/nettle"
export HOGWEED_LIBS="-L$ROOTDIR/build/lib -lhogweed"
export HOGWEED_CFLAGS="-I$ROOTDIR/build/include/nettle"

#gnutls - required by samba
tar -xf gnutls-3.6.16.tar.xz &
wait $!
cd gnutls-3.6.16
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --with-included-libtasn1 --with-included-unistring --enable-shared --without-p11-kit MAKEINFO=/root/workspace/build/bin/makeinfo &
wait $!
make clean && make -j8 && make install > ../logs/gnutlsbuildlog.txt 2>&1 &
wait $!
cd ..

export CFLAGS="$CFLAGS -I$OPENSSL_INCLUDES"
export LDFLAGS="$LDFLAGS -L$OPENSSL_LIBS $OPENSSL_LDFLAGS"

#Python3.7.3 - compiles a basic version which is required by samba - uses system level python 3.7.3 as interpreter to cross compile
tar -xf Python-3.7.3.tgz &
wait $!
cd Python-3.7.3
echo ac_cv_file__dev_ptmx=no >> config.cross
echo ac_cv_file__dev_ptc=no >> config.cross
CONFIG_SITE=config.cross ./configure CC=$CC CXX=$CXX --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build --disable-ipv6 --without-pydebug --without-doc-strings --without-dtrace --with-openssl=$ROOTDIR/build/lib
make clean && make -j8 && make install > ../logs/Pythoncrossbuildlog.txt

export PYTHONDIR=$ROOTDIR/build/lib/python3.7/site-packages #set sitepackages loc to new python install
export CPPFLAGS="$CPPFLAGS -I$ROOTDIR/build/include/gnutls"
export LDFLAGS="$LDFLAGS -L$ROOTDIR/build/lib"

export PERL_MM_USE_DEFAULT=1 # says yes to the cpan initial config - this has to be done everytime you make shell
cpan Parse::Yapp::Driver #rebuild the yapp driver - may require input - this has to be done everytime you make shell
cpan install Parse::Yapp::Driver #rebuild the yapp driver - may require input - this has to be done everytime you make shell
cpan JSON # cpan json install - this has to be done everytime you make shell
cd ..

#MITKRB5
tar -xf krb5-1.20.1.tar.gz &
wait $!
cd krb5-1.20.1/src
export krb5_cv_attr_constructor_destructor=yes,yes
export ac_cv_func_regcomp=yes
export ac_cv_printf_positional=yes
LDFLAGS="$LDFLAGS -L$ROOTDIR/build/lib" ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$ROOTDIR/build  &
wait $!
make clean && make -j8 && make install > $ROOTDIR/logs/mitkrb5buildlog.txt 2>&1 &
wait $!
cd ..
cd ..

#Sambabuild - runs the configure command a few times to build the cross.txt answers file and edit it to auto the build. 
tar -xzf samba-4.18.1.tar.gz &
wait $!
cd samba-4.18.1

# Build the cross.txt file, OK all of these we only want smbclient. If your configure fails on cross.txt incomplete, find any entries that say "UNKNOWN" and change to "OK" then re-run configure
echo Checking uname sysname type: OK >> cross.txt
echo Checking uname machine type: OK >> cross.txt
echo Checking uname release type: OK >> cross.txt
echo Checking uname version type: OK >> cross.txt
echo rpath library support: OK >> cross.txt
echo -Wl,--version-script support: OK >> cross.txt
echo Checking getconf LFS_CFLAGS: OK >> cross.txt
echo Checking for large file support without additional flags: OK >> cross.txt
echo Checking correct behavior of strtoll: OK >> cross.txt
echo Checking for working strptime: OK >> cross.txt
echo Checking for C99 vsnprintf: OK >> cross.txt
echo Checking for HAVE_SHARED_MMAP: OK >> cross.txt
echo Checking for HAVE_MREMAP: OK >> cross.txt
echo Checking for HAVE_INCOHERENT_MMAP: OK >> cross.txt
echo Checking value of GNUTLS_CIPHER_AES_128_CFB8: OK >> cross.txt
echo Checking value of GNUTLS_MAC_AES_CMAC_128: OK >> cross.txt
echo Checking value of NSIG: OK >> cross.txt
echo Checking value of _NSIG: OK >> cross.txt
echo Checking value of SIGRTMAX: OK >> cross.txt
echo Checking value of SIGRTMIN: OK >> cross.txt
echo Checking for a 64-bit host to support lmdb: OK >> cross.txt
echo Checking errno of iconv for illegal multibyte sequence: OK >> cross.txt
echo Checking if can we convert from CP850 to UCS-2LE: OK >> cross.txt
echo Checking if can we convert from IBM850 to UCS-2LE: OK >> cross.txt
echo Checking if can we convert from UTF-8 to UCS-2LE: OK >> cross.txt
echo Checking if can we convert from UTF8 to UCS-2LE: OK >> cross.txt
echo vfs_fileid checking for statfs() and struct statfs.f_fsid: OK >> cross.txt
echo Checking whether we can use Linux thread-specific credentials with 32-bit system calls: OK >> cross.txt
echo Checking whether setreuid is available: OK >> cross.txt
echo Checking whether setresuid is available: OK >> cross.txt
echo Checking whether fcntl locking is available: OK >> cross.txt
echo Checking whether fcntl lock supports open file description locks: OK >> cross.txt
echo Checking whether fcntl supports flags to send direct I/O availability signals: OK >> cross.txt
echo Checking whether fcntl supports setting/geting hints: OK >> cross.txt
echo Checking for the maximum value of the 'time_t' type: OK >> cross.txt
echo Checking whether the realpath function allows a NULL argument: OK >> cross.txt
echo Checking for ftruncate extend: OK >> cross.txt
echo Checking for readlink breakage: OK >> cross.txt
echo getcwd takes a NULL argument: OK >> cross.txt
echo checking for clnt_create(): OK >> cross.txt
echo Checking simple C program: OK >> cross.txt
echo Checking getconf large file support flags work: OK >> cross.txt
echo Checking for HAVE_SECURE_MKSTEMP: OK >> cross.txt
echo vfs_fileid checking for statfs() and struct statfs.f_fsid: OK >> cross.txt
echo Checking for the maximum value of the 'time_t' type: OK >> cross.txt
echo checking for clnt_create(): OK >> cross.txt
echo Checking for gnutls fips mode support: OK >> cross.txt
echo Checking whether the WRFILE -keytab is supported: OK >> cross.txt
echo vfs_fileid checking for statfs() and struct statfs.f_fsid: OK >> cross.txt
echo Checking for the maximum value of the 'time_t' type: OK >> cross.txt
echo checking for clnt_create(): OK 

# Edit summary.c and remove/comment out line 7 8 and 9 if you get errors configuring on LOCKING- This removes some tests that fail the configure with a locking error (unsafe to run samba without locking.. etc etc etc) 
# sed -i '/#if !defined(HAVE_FCNTL_LOCK)/,/#endif/d' /root/workspace/samba-4.18.1/tests/summary.c

LDFLAGS="$LDFLAGS -Wl,-rpath-link,$ROOTDIR/build/lib" ./configure --cross-compile --cross-answers=./cross.txt --build=$BUILD --hostcc=$HOST --prefix=/mnt/SDCARD/.tmp_update/samba --bindir=/mnt/SDCARD/.tmp_update/samba/bin  --sbindir=/mnt/SDCARD/.tmp_update/samba/sbin  --libexecdir=/mnt/SDCARD/.tmp_update/libexec --sharedstatedir=/mnt/SDCARD/.tmp_update/samba/com  --sysconfdir=/mnt/SDCARD/.tmp_update/samba/conf --localstatedir=/mnt/SDCARD/.tmp_update/samba/var --libdir=/mnt/SDCARD/.tmp_update/lib --includedir=/mnt/SDCARD/.tmp_update/include --sharedstatedir=/mnt/SDCARD/.tmp_update/samba/var  --datarootdir=/mnt/SDCARD/.tmp_update/samba/share  --with-privatedir=/mnt/SDCARD/.tmp_update/samba/private --with-bind-dns-dir=/mnt/SDCARD/.tmp_update/samba --without-ads --without-pie --tests=none samba_cv_CC_NEGATIVE_ENUM_VALUES=yes libreplace_cv_HAVE_GETADDRINFO=no ac_cv_file__proc_sys_kernel_core_pattern=yes --without-gpgme --without-ad-dc --without-acl-support --without-libarchive --without-ldap --without-systemd --without-pam --with-shared-modules='!vfs_snapper'  --quick --perf-test --with-system-mitkrb5

wait $!

# Dont run make install before make for samba, it breaks the make.
make clean && make -j8 && make -j8 install > ../logs/smbbuildlog.txt 2>&1 &

