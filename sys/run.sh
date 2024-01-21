#!/bin/zsh -e
cd ${0:h}
DIR="/tmp/matool.mkosi.$USER"

exec mkosi --cache-dir "$DIR/cache" --workspace-dir "$DIR/workspace" "$@"
