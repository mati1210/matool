#!/bin/zsh
# args:
#	COMPALG: the compression algorithm to use, in 'algorithm@level' syntax
#			 supported algorithms: zstd (1..22), xz (0..9), lz4 (1..12)
#			 default: zstd@22
(( $UID != 0 )) && { echo not root; exit 1 }

: ${COMPALG:=zstd@22}
COMPALG=( ${(s:@:)COMPALG} )
compress() {
	alg=$COMPALG[1]
	level=$COMPALG[2]
	case $alg in
		zstd) zstd -v -T0 --long --ultra -$level;;
		xz) xz -T0 -ve -$level;;
		lz4) lz4 -v -$level;;
	esac
}

set -e
cd ${0:h}
OUT=$PWD/../out
OUT=${OUT:A}

loopdev="$(losetup -fPL --show $OUT/sys)"
mountdir="$(mktemp -dt ukimnt.XXXXXXXX)"

mount ${loopdev}p1 $mountdir -o noatime
mount --mkdir --bind $OUT $mountdir/out

if (( DEBUG )) {
    printf 'mountdir=%s\n' $mountdir
    echo any key to continue
    read
}

SYSROOT=$OUT/root${COMPALG[2]}.${COMPALG[1]}
if [[ ! -f $SYSROOT ]] {
	pushd $mountdir
		[ ! -d @ ] && btrfs sub snap -r . @
		btrfs send --proto 2 @|compress > $SYSROOT
	popd
}

cp -av root/. $mountdir

pacstrap -c $mountdir mkinitcpio
arch-chroot $mountdir \
	mkinitcpio \
		--config /etc/mkinitcpio.conf \
		--cmdline /etc/cmdline \
		--uki /out/mow.efi

umount -v $mountdir/out $mountdir
losetup -d $loopdev

(( $+DOAS_USER )) && chown $DOAS_USER $OUT/mow.efi
