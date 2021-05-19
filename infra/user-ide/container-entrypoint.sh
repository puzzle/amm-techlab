#!/bin/bash
set -e

# copy back prepared files
cp -an /tmp/coder/.bashrc /home/coder/.bashrc \
    && cp -an /tmp/coder/.profile /home/coder/.profile \
    && cp -an /tmp/coder/.bash_logout /home/coder/.bash_logout

# copy initial settings if not already exising
if [ ! -f /home/coder/.local/share/code-server/User/settings.json ]; then
    mkdir -p /home/coder/.local/share/code-server/User
    cp -an /tmp/coder/settings.json /home/coder/.local/share/code-server/User/settings.json
fi

exec dumb-init fixuid -q /usr/bin/code-server "$@"
