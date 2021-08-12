/* lxc/lxd linux container Guide */
**Getting started with lxc container ------->
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







