#!/bin/bash
FULLSCRIPTPATH="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
USB_ROOT=$(dirname ${FULLSCRIPTPATH})

RFS_PATH=${USB_ROOT}/rfs
RFS_TAR=${USB_ROOT}/rfs.tar
LOGFILE=$USB_ROOT/_log_$(date +%Y%m%d).txt
LOG() {
    echo $(date +"%T : ") $1 >> $LOGFILE
    cat /proc/mounts >> $LOGFILE
}



function stopall() {
    kill -9 ${DROPBEARPID}
    umount ${RFS_PATH}
}

trap "stopall" SIGINT SIGTERM SIGHUP SIGINT SIGTERM





mkdir -p ${RFS_PATH}

LOG "[start]"
cat /proc/filesystems >> $LOGFILE

mount -t tmpfs none ${RFS_PATH}
LOG "[tmpfs]"

tar xf ${RFS_TAR} -C ${RFS_PATH}
LOG "[extract]"

chroot ${RFS_PATH} mount -t devpts none /dev/pts
LOG "[devpts]"

chroot ${RFS_PATH} mount -t proc none /proc
LOG "[proc]"

chroot ${RFS_PATH} /usr/bin/dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
chroot ${RFS_PATH} /usr/bin/dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
chroot ${RFS_PATH} /usr/sbin/dropbear -p 4567 -g -F
DROPBEARPID=$(echo $!)
LOG "[dropbear]"

exit 0
