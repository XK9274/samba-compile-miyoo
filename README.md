# Samba compile instructions for Miyoo Mini+

## Copy the bins to a suitable location on your SDCARD, or:

### Start a new docker image with:

1. Open a shell in the location you wish to start your project in and run: git clone https://github.com/shauninman/union-miyoomini-toolchain.git
2. Run: cd union-miyoomini-toolchain
3. Run: make shell
4. Make sure you're in the workspace directory now

Copy the sambaBuild.sh script into the workspace directory.

Start the compile with: source sambaBuild.sh

This build takes a while.

## Usage

Store your smb.conf file in /mnt/SDCARD/.tmp_update/samba/conf/

Copy the required bins from the bin folder to the SDCARD to a suitable location (example /mnt/SDCARD/.tmp_update/bin)

Copy the libs from the lib folder to the SDCARD to a suitable location (example /mnt/SDCARD/.tmp_update/lib)

### Update your env vars with the below from a terminal:

sysdir=/mnt/SDCARD/.tmp_update

miyoodir=/mnt/SDCARD/miyoo

export LD_LIBRARY_PATH="/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"



### Create an alias for the file with: 

alias smbclient='/mnt/SDCARD/.tmp_update/bin/smbclient'

Run samba with:

run: smbclient //ShareHost/Sharename

### Windows shares

You'll need to create a shared folder on windows to link to, this guide or similar guide will help you:
https://pureinfotech.com/setup-network-file-sharing-windows-10/

Take note of the "no password" section or you'll have trouble getting into your share as "Everyone"

### Built in dir info

--prefix=/mnt/SDCARD/.tmp_update/samba

--bindir=/mnt/SDCARD/.tmp_update/samba/bin  

--sbindir=/mnt/SDCARD/.tmp_update/samba/sbin  

--libexecdir=/mnt/SDCARD/.tmp_update/libexec 

--sharedstatedir=/mnt/SDCARD/.tmp_update/samba/com  

--sysconfdir=/mnt/SDCARD/.tmp_update/samba/conf 

--localstatedir=/mnt/SDCARD/.tmp_update/samba/var 

--libdir=/mnt/SDCARD/.tmp_update/lib 

--includedir=/mnt/SDCARD/.tmp_update/include 

--sharedstatedir=/mnt/SDCARD/.tmp_update/samba/var  

--datarootdir=/mnt/SDCARD/.tmp_update/samba/share  

--with-privatedir=/mnt/SDCARD/.tmp_update/samba/private 

--with-bind-dns-dir=/mnt/SDCARD/.tmp_update/samba

