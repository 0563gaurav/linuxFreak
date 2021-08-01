DISCLAMER: /* You should have root privilages to follow this guide */

#satisfying host requirments

#install all the required software manually


# partitioning the hard-disk(using fdisk or gparted )  
#commands
	sudo fdisk /dev/sd<xxx>
	#replace the actual device name 
	#to know the device name run commnd 
	lsblk 
	#press n and proceed with approriate information

#formatting the hard disk ( mkfs or mkfs.ext4)
	sudo mkfs -v -t ext4 /dev/sd<xxx>


#mount the partition (using mount command)

	sudo mount /dev/sd<xxx> /mnt
	#make sure that /mnt dir does not contaions important information(files,directories)


#creating directory structure in the $LFS dir
	export LFS=/mnt/lfs
	mkdir -pv $LFS/{tools,sources,lib,usr,bin,sbin}

	case $(uname -r) in 
		x86_64) mkdir -pv $LFS/lib64
			;;
	esac
#provide full permission to sources dir for lfs
	chmod a+wt $LFS/sources

#adding user (empty user )on the host machine 
	groupadd lfs
	useradd -s /bin/bash -g lfs -m -k /dev/null lfs

#Handover the full control to $LFS dir to lfs user 

	sudo chown lfs $LFS/{tools,sources,lib,usr,bin,sbin}
	sudo chgrp lfs $LFS/{tools,sources,lib,usr,bin,sbin}

	
# setting up environment ( creating .bashrc and .profile file in lfs home dir)
#creating .profile file in lfs user home dir 
	cat >~/.profile <<"EOF"
	exec env -i HOME=$HOEM 
	TERM=$TERM 
	PS1='\u:\w\$ ' /bin/bash 
	EOF

#creating .bashrc file in user's home dir 
	cat >~/,bashrc <<"EOF"
	set +h
	umask 022
	LFS=/mnt/lfs
	LC_ALL=POSIX
	LFS_TGT=$(uname -r)-lfs-linux-gnu
	PATH=$LFS/tools:$PATH
	export LFS LC_ALL LFS_TGT PATH
	EOF









