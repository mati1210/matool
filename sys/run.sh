#!/bin/zsh -e
cd ${0:h}
DIR="/tmp/matool.mkosi.$USER"

cp dotfiles/.config/tmux/tmux.conf mkosi.extra/etc/tmux.conf
for f ( zsh{env,rc} ) {
	cp dotfiles/.config/zsh/.$f mkosi.extra/etc/zsh/$f
}
cp -a dotfiles/.config/zsh/{utils,zsh-syntax-highlighting}  mkosi.extra/etc/zsh/
echo 'ZDOTDIR=/etc/zsh' >> mkosi.extra/etc/zsh/zshenv

exec mkosi --cache-dir "$DIR/cache" --workspace-dir "$DIR/workspace" "$@"
