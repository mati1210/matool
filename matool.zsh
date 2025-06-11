#!/usr/bin/zsh -xve
SCRIPTDIR=${0:h:A}
setopt globstarshort
cd $SCRIPTDIR

: ${HOSTNAME:=matool}
: ${TZ:=America/Sao_Paulo}
: ${LOCALE:=en_US.UTF-8}
: ${KEYMAP:=br-abnt2}
: ${COMPALG:=xz@9}

: ${SUBVOLDIR:=@matool}

pkgs=(
	base
	linux
	linux-firmware
	amd-ucode
	intel-ucode
	opendoas

	# using
	zsh
	zoxide
	fzf

	eza
	bat
	less
	diffutils
	usbutils
	tmux
	nano

	# docs
	man-db
	man-pages
	arch-wiki-docs

	# networking
	networkmanager
	usbmuxd
	ethtool
	openssh
	nmap
	rsync

	# gui
	sway
	foot
	xorg-xwayland

	# partition/disk stuff
	smartmontools
	ddrescue
	nvme-cli
	gparted
	dosfstools
	mtools
	exfatprogs
	bcachefs-tools
	btrfs-progs
	ntfs-3g
	udftools
	xfsprogs
	lvm2

	# installing
	arch-install-scripts
	grub
	efibootmgr
)

if [[ $+BROWSER && $BROWSER != none ]] {
	pkgs+=$BROWSER
}

btrfs sub create $SUBVOLDIR
mkdir -p $SUBVOLDIR/etc/
cp -av dotfiles/.config/zsh  $SUBVOLDIR/etc/
cp -av dotfiles/.config/tmux/tmux.conf  $SUBVOLDIR/etc/tmux.conf
cp -av root/. $SUBVOLDIR/

pacstrap -Kc $SUBVOLDIR $pkgs

pushd $SUBVOLDIR
systemd-firstboot \
	--root=. \
	--reset \
	--locale=$LOCALE \
	--keymap=$KEYMAP \
	--timezone=$TZ \
	--hostname=$HOSTNAME

arch-chroot . \
	bash -c 'chsh -s /bin/zsh root && chpasswd -e <<< root:U6aMy0wojraho'

arch-chroot . \
	systemctl enable \
		NetworkManager \
		sshd \
		pacman-init

for file (
	./boot/*linux*(N)
	./etc/machine-id
	./var/lib/dbus/machine-id
	./var/lib/systemd/random-seed
	./lib/firmware/nvidia
) {
	if [[ -e $file ]] rm -vr $file
}
unzstd --rm ./lib/modules/**.ko.zst
find -name '*.pacnew' -delete

echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' >etc/pacman.d/mirrorlist

btrfs sub snap -r . @
cp -av $SCRIPTDIR/uki/. .

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

mkdir out

btrfs send --proto 2 @|compress > out/root.${COMPALG[1]}

arch-chroot . \
	bash -c 'depmod && mkinitcpio \
		--config /etc/mkinitcpio.conf \
		--cmdline /etc/cmdline \
		--uki /out/mow.efi'
