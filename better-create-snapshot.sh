#!/bin/bash
# How to use:
# specify a script working directory e.g. /root/mnt_btrfs
# All btrfs partitions to snapshot need a filesystem label like "HOME".
# If /home is a separate volume on "ROOT" filesystem, specify "ROOT" as the
# HOME_LABEL and the subvol-name of /home for HOME_SUBVOL. Same for /boot.
# This script will create a snapshot called snap_of_<subvol>_<date> where
# <subvol> is the btrfs subvolume that is snapped and  <date> is the output 
# of `date +%Y%m%e%H%M%S` at script runtime.

## User changable area
BTRFS_WORKDIR="/root/mnt_btrfs"
BTRFS_LINUX_ROOT_LABEL="ROOT"
BTRFS_LINUX_ROOT_SUBVOL="@"
BTRFS_LINUX_ROOT_KEEP_COUNT="10"

BTRFS_LINUX_HOME_LABEL="HOME"
BTRFS_LINUX_HOME_SUBVOL="@"
BTRFS_LINUX_HOME_KEEP_COUNT="10"

BTRFS_LINUX_BOOT_LABEL="BOOT"
BTRFS_LINUX_BOOT_SUBVOL="@"
BTRFS_LINUX_BOOT_KEEP_COUNT="10"


## Script acea - do not change, except you know what you're doing!
DATE=$(date +%Y%m%d%H%M%S)
START_WD=$(pwd)

# normalize btrfs mount directory to no trailing slash
BTRFS_WORKDIR=$(echo ${BTRFS_WORKDIR} | sed -r "s/\/$//")

function do_snapshot {
  WORKDIR=$1
  FSLABEL=$2
  SUBVOL=$3
  # Check for btrfs work directory
  if [ ! -d "${WORKDIR}" ]
    then
      echo "INFO: btrfs workdir ${WORKDIR} doesn't exist - creating"
      mkdir ${WORKDIR} || echo "ERROR: creation of ${WORKDIR} failed!" 1>&2 && exit 1
  fi
  if [ ! -d "${WORKDIR}/${FSLABEL}" ]
    then
      echo "INFO: mountpoint ${WORKDIR}/${FSLABEL} doesn't exist - creating"
      mkdir ${WORKDIR}/${FSLABEL} || echo "ERROR: creation of ${WORKDIR} failed!" 1>&2 && exit 1
  fi
  if mount | grep -q ${WORKDIR}/${FSLABEL}
    then 
      echo "INFO: btrfs subvol=/ already mounted to ${WORKDIR}/${FSLABEL}"
    else
      echo "INFO: mounting btrfs subvol=/ to ${WORKDIR}"
      mount -o subvol=/ /dev/disk/by-label/${FSLABEL} ${WORKDIR}/${FSLABEL} || echo "ERROR: mount of ${WORKDIR}/${FSLABEL} failed!" 1>&2 && exit 1
  fi
  cd ${WORKDIR}/${FSLABEL}
  echo "INFO: creating btrfs subvol snap_of${SUBVOL}_${DATE} ... "
  /usr/bin/btrfs subvolume snapshot ${SUBVOL} snap_of_${SUBVOL}_${DATE}
  if mount | grep -q ${WORKDIR}/${FSLABEL}
    then 
      echo "INFO: umounting ${WORKDIR}/${FSLABEL}"
      umount ${WORKDIR}/${FSLABEL} || echo "ERROR: umount of ${WORKDIR}/${FSLABEL} failed" 1>&2 && exit 1
      rmdir ${WORKDIR}/${FSLABEL} || echo "ERROR: rmdir of ${WORKDIR}/${FSLABEL} failed" 1>&2 && exit 1
    else
      echo "ERROR: ${WORKDIR}/${FSLABEL} was not mounted propperly!" 1>&2 && exit 1
  fi
  echo "INFO: done snapshot of ${WORKDIR}/${FSLABEL}"
}
function cleanup_snapshots {
  WORKDIR=$1
  FSLABEL=$2
  SUBVOL=$3
  KEEP_COUNT=$4
  if [ ${KEEP_COUNT} -eq "0" ]
  then
    echo "infinite keep count \"0\", not doint any cleanup of ${WORKDIR}/${FSLABEL}"
    return 
  fi
  echo "INFO: Starting cleanup of ${WORKDIR}/${FSLABEL}"
  # Check for btrfs work directory
  if [ ! -d "${WORKDIR}" ]
    then
      echo "INFO: btrfs workdir ${WORKDIR} doesn't exist - creating"
      mkdir ${WORKDIR} || echo "ERROR: creation of ${WORKDIR} failed!" 1>&2 && exit 1
  fi
  if [ ! -d "${WORKDIR}/${FSLABEL}" ]
    then
      echo "INFO: mountpoint ${WORKDIR}/${FSLABEL} doesn't exist - creating"
      mkdir ${WORKDIR}/${FSLABEL} || echo "ERROR: creation of ${WORKDIR} failed!" 1>&2 && exit 1
  fi
  if mount | grep -q ${WORKDIR}/${FSLABEL}
    then 
      echo "INFO: btrfs subvol=/ already mounted to ${WORKDIR}/${FSLABEL}"
    else
      echo "INFO: mounting btrfs subvol=/ to ${WORKDIR}"
      mount -o subvol=/ /dev/disk/by-label/${FSLABEL} ${WORKDIR}/${FSLABEL} || echo "ERROR: mount of ${WORKDIR}/${FSLABEL} failed!" 1>&2 && exit 1
  fi
  cd ${WORKDIR}/${FSLABEL}
  if [ ${keep_count} -lt $(ls snap_of_${SUBVOL}_* | wc -l) ]
  then
    count=$(($(ls snap_of_${SUBVOL}_* | wc -l)-${keep_count}))
    echo "INFO: found ${count} old snapshots."
    for snap in $(ls | sort | head -n ${count}); do
      echo "INFO: deleting snapshot ${snap}"
      btrfs subvolume delete ${snap} 
    done
  fi
  if mount | grep -q ${WORKDIR}/${FSLABEL}
    then 
      echo "INFO: umounting ${WORKDIR}/${FSLABEL}"
      umount ${WORKDIR}/${FSLABEL} || echo "ERROR: umount of ${WORKDIR}/${FSLABEL} failed" 1>&2 && exit 1
      rmdir ${WORKDIR}/${FSLABEL} || echo "ERROR: rmdir of ${WORKDIR}/${FSLABEL} failed" 1>&2 && exit 1
    else
      echo "ERROR: ${WORKDIR}/${FSLABEL} was not mounted propperly!" 1>&2 && exit 1
  fi
  echo "INFO: done cleanup of ${WORKDIR}/${FSLABEL}"
}


# Do ROOT snapshot
do_snapshot ${BTRFS_WORKDIR} ${BTRFS_LINUX_ROOT_LABEL} ${BTRFS_LINUX_ROOT_SUBVOL}
cleanup_snapshots ${BTRFS_WORKDIR} ${BTRFS_LINUX_ROOT_LABEL} ${BTRFS_LINUX_ROOT_SUBVOL} ${BTRFS_LINUX_ROOT_KEEP_COUNT}
# Is home separately mounted, then do snap of HOME
if mount | grep "btrfs" | grep -q "/home" 
then
  do_snapshot ${BTRFS_WORKDIR} ${BTRFS_LINUX_HOME_LABEL} ${BTRFS_LINUX_HOME_SUBVOL}
  cleanup_snapshots ${BTRFS_WORKDIR} ${BTRFS_LINUX_ROOT_LABEL} ${BTRFS_LINUX_ROOT_SUBVOL} ${BTRFS_LINUX_ROOT_KEEP_COUNT}
fi
# Is boot separately mounted, then do snap of BOOT
if mount | grep "btrfs" | grep -q "/boot" 
then
  do_snapshot ${BTRFS_WORKDIR} ${BTRFS_LINUX_BOOT_LABEL} ${BTRFS_LINUX_BOOT_SUBVOL}
  cleanup_snapshots ${BTRFS_WORKDIR} ${BTRFS_LINUX_ROOT_LABEL} ${BTRFS_LINUX_ROOT_SUBVOL} ${BTRFS_LINUX_ROOT_KEEP_COUNT}
fi





cd $START_WD
