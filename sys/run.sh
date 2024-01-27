#!/bin/zsh -e
#
# args:
# 	WORKDIR: set cache/workspace. might be nice to set it to a tmpfs (needs ~10Gi free)
# 			 by default, it's set matool.workdir
#
# 	CACHEBIND: if set, sets up overlay mount on $WORKDIR/cache to /var/cache/pacman/pkg. requires root
#
# 	BROWSER: choose installed browser, or "none". by default it's set to chromium
cd ${0:h}

cp dotfiles/.config/tmux/tmux.conf mkosi.extra/etc/tmux.conf
for f ( zsh{env,rc} ) {
	cp dotfiles/.config/zsh/.$f mkosi.extra/etc/zsh/$f
}
cp -a dotfiles/.config/zsh/{utils,zsh-syntax-highlighting}  mkosi.extra/etc/zsh/
echo 'ZDOTDIR=/etc/zsh' >> mkosi.extra/etc/zsh/zshenv

args=()
: ${WORKDIR:=$PWD/matool.workdir}
: ${BROWSER:=chromium}

args+=(
	--cache-dir "$WORKDIR/cache"
	--workspace-dir "$WORKDIR/workspace"
)

if (( $+CACHEBIND )) {
	mkdir -p $WORKDIR/cache/cache/pacman/{pkg,rw,work}
	pushd $WORKDIR/cache/cache/pacman
		mountpoint -q pkg && umount pkg
		mount -t overlay overlay \
			-o lowerdir=/var/cache/pacman/pkg \
			-o upperdir=rw \
			-o workdir=work \
			pkg
	popd
}

if [[ $BROWSER != none ]] {
	args+=(
		-p $BROWSER
	)
}

mkosi $args $@
