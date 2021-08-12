/* lxc/lxd linux container Guide */
/* Requirments */


Hard dependecies:

   * One of glibc, musl libc, uclib or bionic as your C library
   * Linux kernel >= 2.6.32

Extra Dependency for lxc-attach:
   
   * Linux kernel >= 3.8

Extra dependencies for unprivileged containers:

  * libpam-cgfs configuring your system for unprivileged CGroups operation
  * A recent version of shadow including newuidmap and newgidmap
  * Linux kernel >= 3.12

Recommended libraries:

  * libcap (to allow for capability drops)
  * libapparmor (to set a different apparmor profile for the container)
  * libselinux (to set a different selinux context for the container)
  * libseccomp (to set a seccomp policy for the container)
  * libgnutls (for various checksumming)
  * liblua (for the LUA binding)
  * python3-dev (for the python3 binding)


/* Installation */
Command to install lxc container on Debian/ubuntu linux:
	* sudo apt-get install lxc
or
	* sudo snap install lxd
NOTE:	Your system will then have all the LXC commands available, all its templates as well as the python3 binding should you want to script LXC.


/* Getting started with lxc/lxd container */
* After done with installation of lxc and lxd , the first this you have to do is check whether the lxd daemon is running or not , if not stat it using this command:
	* sudo systemctl  enable lxd
	* sudo syatemctl start lxd
	* sudo systemctl status lxd
* After this add you user account to lxd group using command:
	* sudo gpasswd -a gaurav lxd
	#gaurav is my user account 
	#If you want to know whether the lxd group is exit or not , use this command :
	* sudo getent group lxd
* After this , lxd service needs to be initilised , it will ask some questions and According the answer the lxd will setup the daemon service , for this command is :
	* sudo lxd init

# After this you can bunch of command to get the infromation about the configuration, service, help , version ....
	* lxc version # for verion 
	* lxc help # generalized help option 
	* lxc help storage # help options for storage 
	* lxc storage list # It will list the storage 
	* lxc remote list # It will list all the repositories , where we can pull the iamges 
	* lxc image list # It will list all the images avalable on the local machine
	* lxc image list images:  # It will list all the OS images available on all the repositories included in the configuration 
	* lxc image list images:cent | less  # It will list all the images started with cent keyword at remote repositores 
	* lxc image list images:debian | less # similarly for the debian images 

* creating , deleting the containers
	
	* lxc launch ubuntu:16.04  <container-name >  # If you are runnig this command for the first time than it will pull the image from remote repository , after it 	will get stared. 
	* lxc image list # it will show the local images.
	* lxc stop <container-name> # It will stop the container.
	* lcx start <container-name> # It will start the container.
	* lxc delete <container-name> # delete the container , get container-name  from "lxc image list " command .
	* lxc delete --force <container-name> # delete the running container
	* lxc copy myubuntu myanotherubuntu # It will create the clone of myubuntu conatiner with muanotherubuntu name. After you can start myanotherubutu conatoner
	 manually
	* lxc move myubuntu myvm # It will rename the container , NOTE- first you have to stop the container than you can rename it 
	* lxc info <container-name> | less # It will list all the details regarding the specified container

* Login and logout the container 
	
	* lxc exec <container-name> bash # It will log into the container with root account
	* lcx exec <container-name> su -<username> # It will login with specified name  
	

* After login tom the container 
	
	* ping muanotherubuntu.lxd # send ping message one container  to another container .
	

* Configuration 
	
	* lxc config show <container-name> | less # It will list the complete configuration details of conatiner.
	* lxc config set <container-name > limits.memory 512MB # It will resize the memory used by container.
	* lxc config set <container-name > limits.cpu 2 # It will reset the no of cpu can be used by container .
	 
	
* profile 
	
	* lxc profile list # It will list the all the profiles.
	* lxc profile show default 	# It will show the detail about default profile.
	or
	 lxc profile shoe <profile-name>
	* lxc prfile copy default custom # It will create the new profile .
	* lxc profile edit <profile-name> # It will open profile into nano editor , and you can change the setting by editing this file. 
	
* launching the container with custom profile .
	
	* lxc launch ubuntu:16.04 <container-name> --profile <profile-name> # It will launch the container with custom profile .

* File transfer between host and container 
	
	* lxc file push <file-path on host>  <container-name>/home/gaurav # It will copy files from host to specified conatiner.
	* lxc file pull <container-name>/home/gaurav/myfile.txt /home/gaurav # It will pull file from specifies container to host.

* Take the Snapshot of a container 
	
	* lxc snapshot <container-name> <snapshot-name> # It will copy the entire file-system (snapshoting).
	* lxc list # it will also list all the snapshot taken 

* Restoring the snapshot of container 
	* lxc restore <associated-container> <snapshot-name>  # It will restore the container .





/ * Nested Containers */
* Every container already installed lxc/lxd container inside it.
NOTE: If you want to create a nested container then you have to set two configuration parameter 
	1. security.privileged ---> true
	2. security.nesting ---> true
* complete procdure to create the nested container:
	
	1. First stop the container: 
	$ sudo lxc stop <container-name>
	2. Set the parameter:
	$ sudo lxc config set <container-name> security.privileged true
	$ sudo lxc config set <container-name> security.nesting true
NOTE: Above parameter can also be set using profile command 
	$ sudo lxc profile  edit <profile-name>
	3. restart the container 
	$ lxc start <container-name >
	4. login into the container 
	$ sudo lxc ecex <container-name> bash
	5. initilize the nested container
	$ sudo lxd init
NOTE: It will ask some questions regarding the configurtion 
	6. Same as container on host machine


/* Help */
Video link for help:
https://www.youtube.com/watch?v=CWmkSj_B-wo 


	

