start_time=$(date +%s)

unset urls
unset files
unset log_files

export ROOTDIR="/root/workspace"
export BIN_NAME="samba"
export SD_DIR="App"
export FIN_BIN_DIR="/mnt/SDCARD/$SD_DIR/$BIN_NAME"
export CROSS_COMPILE="arm-linux-gnueabihf"
export AR=${CROSS_COMPILE}-ar
export AS=${CROSS_COMPILE}-as
export LD=${CROSS_COMPILE}-ld
export RANLIB=${CROSS_COMPILE}-ranlib
export CC=${CROSS_COMPILE}-gcc
export NM=${CROSS_COMPILE}-nm
export HOST=arm-linux-gnueabihf
export BUILD=x86_64-linux-gnu
export CFLAGS="-Wno-undef -Os -marm -mtune=cortex-a7 -mfpu=neon-vfpv4  -march=armv7ve+simd -mfloat-abi=hard -ffunction-sections -fdata-sections"
export CXXFLAGS="-s -O3 -fPIC -pthread"
export PATH="$PATH:$FIN_BIN_DIR/bin/"

#Copy these files to lib to stop some test failures on makes, not really needed in most cases - also stops pkgconfig working - could be ldflags/PATH
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/ld-linux-armhf.so.3 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libpthread.so.0 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libc.so.6 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libm.so.6 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libcrypt.so.1 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libdl.so.2 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libutil.so.1 /lib/
cp /opt/miyoomini-toolchain/arm-linux-gnueabihf/libc/lib/libstdc++.so.6 /lib/

export LOGFILE=./logs/buildtracker.txt # set a full log file
mkdir $ROOTDIR/logs

#Script header section
echo -e "\n" 			
echo -e "-Building \033[32m"$BIN_NAME"\033[0m for: \033[32m"$CROSS_COMPILE "\033[0m"

echo -e "-Building with a prefix of \033[32m$FIN_BIN_DIR\033[0m"	

echo -e "-The build will use \033[32m"$(( $(nproc) - 2 ))"\033[0m cpu threads of the max: \033[32m"`nproc`"\033[0m"
echo  "-The script will output a list of failed makes at the end.."			
echo -e "\n"
echo "-Warning: If you're building this on WSL2 it will be incredibly slow and likely take over a day to build, create a docker image in your \\wsl$\distro\home\user\ location and run from there."
echo "For reference it takes around 10 mins to download & build everything on a 1gbps circuit with an I9-11900k."
echo -e "\n"
echo -e "-Starting shortly - a full logfile with be in: \033[32m"$LOGFILE "\033[0m"
echo -e "\n"

for i in {9..1}; do
    echo -ne "Starting in $i\r"
    sleep 1
done

echo -e "\n\n\n"

while true; do # check if a build has already been completed, it may be best to do a fresh build if you've changed anything
    if [ -d "$ROOTDIR/$BIN_NAME" ]; then
        read -p "A previously completed build of $BIN_NAME already exists. Do you want to remove this & build fresh? (y/n)" rebuildq
        case "$rebuildq" in 
            y|Y ) 
                echo "Deleting previous build..."
                rm -rf $ROOTDIR/$BIN_NAME
                rm -rf $FIN_BIN_DIR
                rm -rf */ 
				rm -f wget-log*
                mkdir $ROOTDIR/logs
                mkdir -p $FIN_BIN_DIR
                break
                ;;
            n|N ) 
                echo "Rebuilding over the top of the last build..."
                break
                ;;
            * ) 
                echo "Invalid input. Please enter 'y' or 'n'."
                ;;
        esac
    else
        echo -e "\033[32mNo previous build detected, starting...\033[0m"
        break
    fi
done

cd ~/workspace/

# Start logging and begin UNCOMMENT TO LOG FULL BUILD
# exec 3>&1 4>&2
# trap 'exec 2>&4 1>&3' 0 1 2 3
# exec 1> >(tee -a "$LOGFILE") 2>&1					

#Download everything, but check if it already exists.

urls=(
	"https://download.samba.org/pub/samba/stable/samba-4.18.1.tar.gz"
	"https://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz"
	"https://ftp.gnu.org/gnu/m4/m4-latest.tar.xz"
	"https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.xz"
	"https://ftp.gnu.org/gnu/nettle/nettle-3.8.1.tar.gz"
	"https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz"
	"http://zlib.net/zlib-1.2.13.tar.gz"
	"https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.16.tar.xz"
	# "https://ftp.gnu.org/gnu/texinfo/texinfo-7.0.3.tar.xz"
	"https://www.openssl.org/source/openssl-3.1.0.tar.gz"
	"https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz"
	"https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
	"https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
	"https://github.com/westes/flex/releases/download/v2.6.3/flex-2.6.3.tar.gz"
	"http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz"
	"http://digip.org/jansson/releases/jansson-2.5.tar.gz"
	"https://web.mit.edu/kerberos/dist/krb5/1.20/krb5-1.20.1.tar.gz"
	"http://download.savannah.nongnu.org/releases/attr/attr-2.5.1.tar.xz"
	"https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.xz"
	# "https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz"
	# "https://github.com/heimdal/heimdal/releases/download/heimdal-7.8.0/heimdal-7.8.0.tar.gz"
	"https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz"
)

# Parallel download and wait until finished.
pids=()
for url in "${urls[@]}"; do
  file_name=$(basename "$url")
  if [ ! -f "$file_name" ]; then
    echo "Downloading $file_name..."
    wget -q "$url" &
    pids+=($!)
  else
    echo "$file_name already exists, skipping download..."
  fi
done

for pid in "${pids[@]}"; do
  wait $pid
done

echo -e "\n\n\033[32mAll downloads finished, now building..\033[0m\n\n"

# Check all files have downloaded before trying to build

files=(
	"samba-4.18.1.tar.gz"
	"automake-1.16.5.tar.xz"
	"autoconf-latest.tar.gz"
	"m4-latest.tar.xz"
	"libtool-2.4.7.tar.xz"
	"nettle-3.8.1.tar.gz"
	"gmp-6.2.1.tar.xz"
	"zlib-1.2.13.tar.gz"
	"gnutls-3.6.16.tar.xz"
	"texinfo-7.0.3.tar.xz"
	"openssl-3.1.0.tar.gz"
	"Python-3.7.3.tgz"
	"pkg-config-0.29.2.tar.gz"
	"bison-3.8.2.tar.xz"
	"flex-2.6.3.tar.gz"
	"acl-2.3.1.tar.xz"
	"jansson-2.5.tar.gz"
	"krb5-1.20.1.tar.gz"
	"attr-2.5.1.tar.xz"
	"ncurses-6.4.tar.gz"
	"pkg-config-0.29.2.tar.gz"
	# "heimdal-7.8.0.tar.gz"
)

missing_files=()
for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    echo -e "\033[32mAll files exist...\033[0m\n\n"
    sleep 1
else
    # Check if any of the downloads failed, if they did, try to redownload
    echo "Missing files: ${missing_files[@]}"
    echo "Trying to download again..."
    for file in "${missing_files[@]}"; do
        for url in "${urls[@]}"; do
            if [[ "$url" == *"$file"* ]]; then
                wget -q "$url"
                if [ $? -ne 0 ]; then
                    echo "Error downloading $file from $url, please check the URL"
                    return 1
                fi
            fi
        done
    done
fi

# Start compiling..

#Build some perl stuff, needed for Samba.
export PERL_MM_USE_DEFAULT=1 # says yes to the cpan initial config - this has to be done everytime you make shell 
export PERL_MM_FALLBACK_SILENCE_WARNING=1 
cpan CPAN 
cpan JSON
cpan Parse::Yapp::Driver
cpan Devel::CheckLib 

## pkg config 
echo -e "-Compiling \033[32mpkconfig\033[0m"
tar -xf pkg-config-0.29.2.tar.gz &
wait $!
cd pkg-config-0.29.2
./configure CC=$CC AR=$AR RANLIB=$RANLIB LD=$LD --host=$HOST --build=$BUILD --target=$TARGET --prefix=$FIN_BIN_DIR --disable-shared --with-internal-glib glib_cv_stack_grows=no glib_cv_stack_grows=no glib_cv_uscore=no ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes &
wait $!
make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/pkg-config-0.29.2.txt 2>&1  &
wait $!
export PKG_CONFIG_PATH="$FIN_BIN_DIR/lib/pkgconfig"
export PKG_CONFIG="$FIN_BIN_DIR/bin/pkg-config"
cd ~/workspace

# Crosscompile zlib package (This is needed for Glib)
echo -e "-Compiling \033[32mzlib\033[0m"
tar zxf zlib-1.2.13.tar.gz & 
wait $!
cd zlib-1.2.13/
./configure --prefix=$FIN_BIN_DIR --static & 
wait $!
sed -i 's/CC=gcc/CC=\/opt\/miyoomini-toolchain\/bin\/arm-linux-gnueabihf-gcc/' Makefile
sed -i 's/CPP=/CPP=\/opt\/miyoomini-toolchain\/bin\/arm-linux-gnueabihf-gcc -E/' Makefile
sed -i 's/RANLIB=ranlib/RANLIB=\/opt\/miyoomini-toolchain\/bin\/arm-linux-gnueabihf-gcc-ranlib/' Makefile
sed -i 's/LDSHARED=gcc/LDSHARED=arm-linux-gnueabi-gcc -shared -Wl,-soname,libz.so.1,--sed version-script,zlib.map/g' Makefile
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/zlib-1.2.13.txt 2>&1 &
wait $!
cd ~/workspace

#M4
echo -e "-Compiling \033[32mm4\033[0m"
tar -xf m4-latest.tar.xz &
wait $!
cd m4-1.4.19
./configure CC=$CC LD=$LD --host=$HOST --build=$BUILD --target=$TARGET  --prefix=$FIN_BIN_DIR &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/m4-1.4.19.txt 2>&1 &
wait $!
cd ~/workspace

# Autoconf
echo -e "-Compiling \033[32mautoconf\033[0m"
tar -xf autoconf-latest.tar.gz &
wait $!
cd autoconf-2.71/
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR M4=$FIN_BIN_DIR/bin/m4 &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/autoconf-2.71.txt 2>&1 &
wait $!
cd ~/workspace

# Automake
echo -e "-Compiling \033[32mautomake\033[0m"
tar -xf automake-1.16.5.tar.xz &
wait $!
cd automake-1.16.5
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR AUTOCONF=$FIN_BIN_DIR/bin/autoconf &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/automake-1.16.5.txt 2>&1 &
wait $!
cd ~/workspace

#Cross Compile Libtool
echo -e "-Compiling \033[32mlibtool\033[0m"
tar -xf libtool-2.4.7.tar.xz &
wait $!
cd libtool-2.4.7
./configure CC=$CC --host=$HOST --build=$BUILD --target=$TARGET --prefix=$FIN_BIN_DIR M4=$FIN_BIN_DIR/bin/m4 &
wait $!
make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/libtool-2.4.7.txt 2>&1 &
wait $!
$FIN_BIN_DIR/bin/libtool --finish $FIN_BIN_DIR/lib
cd ~/workspace

# Cross compile ncurses
echo -e "-Compiling \033[32mncurses\033[0m"
tar -xf ncurses-6.4.tar.gz &
wait $!
cd ncurses-6.4
./configure CC=$CC --build=$BUILD --host=$HOST --prefix=$FIN_BIN_DIR --with-fallbacks=vt100,vt102 --disable-stripping --with-shared --with-termlib --with-ticlib   
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/ncurses-6.4.txt 2>&1 &
wait $!
cd ~/workspace

#Cross compile jansson json (required by samba)
echo -e "-Compiling \033[32mjannson\033[0m"
tar -xf jansson-2.5.tar.gz
cd jansson-2.5
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR  &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/jsonbuildlog.txt 2>&1 &
cd ~/workspace

# bison
echo -e "-Compiling \033[32mbison\033[0m"
tar -xf bison-3.8.2.tar.xz &
wait $!
cd bison-3.8.2
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR  &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/bisonbuildlog.txt 2>&1 &
wait $!
cd ~/workspace

# flex (required by samba) use flex 2.6.3 as 2.6.4 contains a segfault & dumps the core trying to make: https://lists.gnu.org/archive/html/help-octave/2017-12/msg00086.html
echo -e "-Compiling \033[32mflex\033[0m"
tar -xf flex-2.6.3.tar.gz &
wait $!
cd flex-2.6.3
CFLAGS='-g -O2 -D_GNU_SOURCE' ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --enable-shared &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/flexbuildlog.txt 2>&1 &
wait $!
cd ~/workspace

#Cross compile OpenSSL 
echo -e "-Compiling \033[32mopenssl\033[0m"
export CROSS_COMPILE="" #  set this or it gets confused as $CROSS_COMPILE appears on the cc lines already
tar -xf openssl-3.1.0.tar.gz
cd openssl-3.1.0
./Configure --prefix=$FIN_BIN_DIR --openssldir=$FIN_BIN_DIR linux-generic32 shared -DL_ENDIAN PROCESSOR=ARM &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/openssl-3.1.0.txt &
wait $!
cd ~/workspace
export CROSS_COMPILE="arm-linux-gnueabihf" #  set back

# libattr - required by libacl
echo -e "-Compiling \033[32mlibattr\033[0m"
tar -xf attr-2.5.1.tar.xz &
wait $!
cd attr-2.5.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --enable-shared &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/attrbuildlog.txt 2>&1 &
wait $!
cd ~/workspace

# libacl - required by samba for permissions
echo -e "-Compiling \033[32macl\033[0m"
tar -xf acl-2.3.1.tar.xz &
wait $!
cd acl-2.3.1
CFLAGS="$CFLAGS -I/mnt/SDCARD/App/samba/include/" LDFLAGS="-L$FIN_BIN_DIR/lib/ -lattr" ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --enable-shared &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/aclbuildlog.txt 2>&1 &
wait $!
cd ~/workspace

# texinfo (required by gnutls for MAKEINFO)
echo -e "-Compiling \033[32mtexinfo\033[0m"
tar -xf texinfo-7.0.3.tar.xz &
wait $!
cd texinfo-7.0.3
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --enable-shared &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/texibuildlog.txt 2>&1 &
wait $!
cd ~/workspace

#nettle/nettle-3 - required by gnutls
echo -e "-Compiling \033[32mnettle3\033[0m"
tar -xf nettle-3.8.1.tar.gz &
wait $!
cd nettle-3.8.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --disable-assembler --enable-mini-gmp --enable-shared
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/nettlebuildlog.txt 2>&1 &
wait $!
cd ~/workspace

# Heimdal
# echo -e "-Compiling \033[32mheimdal\033[0m"
# tar -xf heimdal-7.8.0.tar.gz &
# wait $!
# cd heimdal-7.8.0
# ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR &
# wait $!
# make install exec -j$(( $(nproc) - 2 )) > ../logs/heimdalbuildlog.txt 2>&1 &
# wait $!
# cd ~/workspace

# Python3 create a cross compiled version 
echo -e "-Compiling \033[32mpython3\033[0m"
tar -xf Python-3.7.3.tgz &
wait $!
cd Python-3.7.3
echo ac_cv_file__dev_ptmx=no >> config.cross
echo ac_cv_file__dev_ptc=no >> config.cross
CFLAGS="-I$FIN_BIN_DIR/include/ncurses" CONFIG_SITE=config.cross ./configure CC=$CC CXX=$CXX --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --disable-ipv6 --without-pydebug --without-doc-strings --without-dtrace --with-openssl=$FIN_BIN_DIR/include
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/Python-3.7.3.txt
export PYTHONDIR=$FIN_BIN_DIR/lib/python3.7/site-packages #set sitepackages loc to new python install
export LDFLAGS="$LDFLAGS -L$FIN_BIN_DIR/lib"
cd ~/workspace

mkdir /usr/include/arm-linux-gnueabihf/
mkdir /usr/include/arm-linux-gnueabihf/python3.7m/
cp /usr/include/python3.7m/pyconfig.h /usr/include/arm-linux-gnueabihf/python3.7m/ # wont include for some reason, copy it to where the script looks for it.

#MITKRB5
echo -e "-Compiling \033[32mmitkrb\033[0m"
tar -xf krb5-1.20.1.tar.gz &
wait $!
cd krb5-1.20.1/src
export krb5_cv_attr_constructor_destructor=yes,yes
export ac_cv_func_regcomp=yes
export ac_cv_printf_positional=yes
LDFLAGS="$LDFLAGS -L$FIN_BIN_DIR/lib" CFLAGS="$CFLAGS -I$FIN_BIN_DIR/include/" ./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR  &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > $ROOTDIR/logs/mitkrb5buildlog.txt 2>&1 &
wait $!
cd ~/workspace
cd ~/workspace

#gmp/gmp-6 - required by gnutls
echo -e "-Compiling \033[32mgmp6\033[0m"
tar -xf gmp-6.2.1.tar.xz &
wait $!
cd gmp-6.2.1
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --enable-shared &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/gmpbuildlog.txt 2>&1 &
wait $!
cd ~/workspace

#gnutls - required by samba
echo -e "-Compiling \033[32mgnutils\033[0m"
tar -xf gnutls-3.6.16.tar.xz &
wait $!
cd gnutls-3.6.16
./configure CC=$CC --host=$HOST --build=$BUILD --prefix=$FIN_BIN_DIR --with-included-libtasn1 --with-included-unistring --enable-shared --without-p11-kit --disable-gtk-doc --disable-doc &
wait $!
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/gnutlsbuildlog.txt 2>&1 &
wait $!
cd ~/workspace

#Sambabuild - runs the configure command a few times to build the cross.txt answers file and edit it to auto the build. 
echo -e "-Compiling \033[32msamba\033[0m"
tar -xzf samba-4.18.1.tar.gz &
wait $!
cd samba-4.18.1

# Build the cross.txt file, OK all of these we only want smbclient. If your configure fails on cross.txt incomplete, find any entries that say "UNKNOWN" and change to "OK" then re-run configure
cat > cross.txt << EOF
Checking uname sysname type: OK
Checking uname machine type: OK
Checking uname release type: OK
Checking uname version type: OK
rpath library support: OK
-Wl,--version-script support: OK
Checking getconf LFS_CFLAGS: OK
Checking for large file support without additional flags: OK
Checking correct behavior of strtoll: OK
Checking for working strptime: OK
Checking for C99 vsnprintf: OK
Checking for HAVE_SHARED_MMAP: OK
Checking for HAVE_MREMAP: OK
Checking for HAVE_INCOHERENT_MMAP: OK
Checking value of GNUTLS_CIPHER_AES_128_CFB8: OK
Checking value of GNUTLS_MAC_AES_CMAC_128: OK
Checking value of NSIG: OK
Checking value of _NSIG: OK
Checking value of SIGRTMAX: OK
Checking value of SIGRTMIN: OK
Checking for a 64-bit host to support lmdb: OK
Checking errno of iconv for illegal multibyte sequence: OK
Checking if can we convert from CP850 to UCS-2LE: OK
Checking if can we convert from IBM850 to UCS-2LE: OK
Checking if can we convert from UTF-8 to UCS-2LE: OK
Checking if can we convert from UTF8 to UCS-2LE: OK
vfs_fileid checking for statfs() and struct statfs.f_fsid: OK
Checking whether we can use Linux thread-specific credentials with 32-bit system calls: OK
Checking whether setreuid is available: OK
Checking whether setresuid is available: OK
Checking whether fcntl locking is available: OK
Checking whether fcntl lock supports open file description locks: OK
Checking whether fcntl supports flags to send direct I/O availability signals: OK
Checking whether fcntl supports setting/geting hints: OK
Checking for the maximum value of the 'time_t' type: OK
Checking whether the realpath function allows a NULL argument: OK
Checking for ftruncate extend: OK
Checking for readlink breakage: OK
getcwd takes a NULL argument: OK
checking for clnt_create(): OK
Checking simple C program: OK
Checking getconf large file support flags work: OK
Checking for HAVE_SECURE_MKSTEMP: OK
vfs_fileid checking for statfs() and struct statfs.f_fsid: OK
Checking for the maximum value of the 'time_t' type: OK
checking for clnt_create(): OK
Checking for gnutls fips mode support: OK
Checking whether the WRFILE -keytab is supported: OK
vfs_fileid checking for statfs() and struct statfs.f_fsid: OK
Checking for the maximum value of the 'time_t' type: OK
checking for clnt_create(): OK

EOF

# Edit summary.c and remove/comment out line 7 8 and 9 if you get errors configuring on LOCKING- This removes some tests that fail the configure with a locking error (unsafe to run samba without locking.. etc etc etc) 
# sed -i '/#if !defined(HAVE_FCNTL_LOCK)/,/#endif/d' /root/workspace/samba-4.18.1/tests/summary.c

LDFLAGS="$LDFLAGS -Wl,-rpath-link,$FIN_BIN_DIR/lib" ./configure --cross-compile --cross-answers=./cross.txt --build=$BUILD --hostcc=$HOST --prefix=$FIN_BIN_DIR/ --with-bind-dns-dir=$FIN_BIN_DIR/ --without-ads --without-pie --tests=none samba_cv_CC_NEGATIVE_ENUM_VALUES=yes libreplace_cv_HAVE_GETADDRINFO=no ac_cv_file__proc_sys_kernel_core_pattern=yes --without-gpgme --without-ad-dc --without-acl-support --without-libarchive --without-ldap --without-systemd --without-pam --with-shared-modules='!vfs_snapper'  --quick --perf-test --with-system-mitkrb5 &
wait $!

# Dont run make install before make for samba, it breaks the make.
make clean && make -j$(( $(nproc) - 2 )) && make install -j$(( $(nproc) - 2 )) > ../logs/smbbuildlog.txt 2>&1 &
wait $!

#Main compile done if you get a success message, if not check the below output in the logfile
#Check if the logfiles appear, these are only created at the install stage which rarely fails - could be checked better but this works:

cd ~/workspace

echo -e "\n\n\n"

log_files=(
    "pkg-config-0.29.2.txt"
    "mitkrb5buildlog.txt"
    "smbbuildlog.txt"
    "Python-3.7.3.txt"
    "gnutlsbuildlog.txt"
    "nettlebuildlog.txt"
    "gmpbuildlog.txt"
    "aclbuildlog.txt"
    "attrbuildlog.txt"
    "openssl-3.1.0.txt"
    "bisonbuildlog.txt"
    "libtool-2.4.7.txt"
    "automake-1.16.5.txt"
    "autoconf-2.71.txt"
    "m4-1.4.19.txt"
    "zlib-1.2.13.txt"
    # "heimdal-7.8.0.txt"
	# "ncurses-6.4.txt"
)

failed_logs=()
for log_file in "${log_files[@]}"; do
  if [ ! -f "logs/$log_file" ]; then
    echo "$log_file FAILED"
    failed_logs+=("$log_file")
  else
    echo "$log_file built OK"
  fi
done

echo "Failed logs: ${failed_logs[@]}"

# Prep the samba folder
# Cleanup
# Edit some files
# All this is done if the smbclient bin was installed to the bin folder.

if [ -f "$FIN_BIN_DIR/bin/smbclient" ]; then # Check if the bin file for BINNAME exists. $FIN_BIN_DIR changes to $ROOTDIR here as it gets copied to the workspace.
	echo -e "\n\n"
	echo "Preparing export folder"
	echo -e "\n\n"
	echo "Moving built files to workspace area"
	mkdir -v $ROOTDIR/$BIN_NAME
	cp -r "$FIN_BIN_DIR/"* "$ROOTDIR/$BIN_NAME" &
	wait $!
	
	# Fix some libraries
	
	# remove some excess fat from the end product dir ( this is a generic list pulled from other builds, it tidies up some of the files)
	rm -rf $BIN_NAME/aclocal/
	rm -rf $BIN_NAME/docs/
	rm -rf $BIN_NAME/doc/
	rm -rf $BIN_NAME/certs/
	rm -rf $BIN_NAME/include/
	rm -rf $BIN_NAME/bin/{gio,glib-compile-resources,gdbus,gsettings,gapplication,gresource,pytho,gio-querymodules,gobject-query,glib-compile-schemas}
	rm -rf $BIN_NAME/share/{doc,autoconf,man,gdb,glib-2.0,automake-1.16,aclocal-1.16,aclocal,bash-completion,gtk-doc,glib2-0,info,libtool,pkgconfig,readline,tabset,util-macros,vala,xcb,zcb}
	rm -rf $BIN_NAME/lib/{python3.7/test,pkgconfig,cmake}
	rm -rf $BIN_NAME/xml
	rm -rf $BIN_NAME/misc
	rm -rf $BIN_NAME/GConf
	rm -rf $BIN_NAME/man
	rm -rf $BIN_NAME/cargo

echo -e "\n\n"
fi 
end_time=$(date +%s)
duration=$((end_time - start_time))

# checks if the final product dir was moved to the /workspace/ folder, indicating it built OK
if [ -z "$failed_logs" ]; then
  if [ -d "$ROOTDIR/$BIN_NAME" ]; then
    echo -e "\033[32mComplete - your finished build is in /workspace/$BIN_NAME, this will contain all build products... "
	echo -e "Build duration: $duration seconds\033[0m"
  else
    echo -e "Build failed, check ~/workspace/logs/buildtracker.txt for more info"
  fi
else
  if [ -d "$ROOTDIR/$BIN_NAME" ]; then
    echo -e "\033[32mComplete - your finished build is in /workspace/$BIN_NAME, this will contain all build products... "
	echo "Build duration: $duration seconds"
    echo -e "These packages did not complete \033[31m$failed_logs\033[32m but it has not affected the $BIN_NAME bin being built\033[0m."
  else
    echo -e "Build failed, these packages did not complete \033[31m$failed_logs\033[0m check ~/workspace/logs/buildtracker.txt for more info"
  fi
fi	
