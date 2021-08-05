host-conf:
	bash ./scripts/Host_preperation.sh

version-check:
	bash ./scripts/Version_check.sh

tmp_toolchain:
	bash ./scripts/Build_temporary_cross_toolchain.sh 

enter-chroot-env:
	bash ./scripts/Entering_chroot_env.sh 

basic-install:
	bash ./scripts/Installing_Basic_system_software.sh

sys-conf:
	bash ./scripts/System_Configuration.sh

mk-bootable:
	bash ./scripts/Making_lfs_Bootable.sh

end:
	bash ./scripts/The_end_and_beyond.sh

