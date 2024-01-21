#!/bin/zsh
(( $UID != 0 )) && { echo not root; exit 1 }

set -e
cd ${0:h}
OUT=$PWD/../out
OUT=${OUT:A}

loopdev="$(losetup -fPL --show $OUT/sys)"
mountdir="$(mktemp -dt ukimnt.XXXXXXXX)"

mount ${loopdev}p1 $mountdir -o noatime

SYSROOT=$OUT/btrfsroot.zst
if [[ ! -f $SYSROOT ]] {
	pushd $mountdir
		[ ! -d @ ] && btrfs sub snap -r . @
		btrfs send --proto 2 @|zstd -T0 --long --ultra -22 -vo $SYSROOT
	popd
}

cp -av root/. $mountdir
mount --bind $OUT $mountdir/out

pacstrap -c $mountdir mkinitcpio
arch-chroot $mountdir /mkinitrd

umount -v $mountdir/out $mountdir
losetup -d $loopdev

(( $+DOAS_USER )) && chown $DOAS_USER $OUT/mow.efi
#rm $OUT/sys*
