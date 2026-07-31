#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Root required."
    exit 1
fi

WINDOWS_USERNAME=$(powershell.exe -Command "whoami" | sed 's/.*\\//' | tr -d '\r')
HOME_DIR="/mnt/c/Users/${WINDOWS_USERNAME}"

useradd -M -d "${HOME_DIR}" -s /sbin/nologin windows

echo "User 'windows' created with home directory: ${HOME_DIR} and no login shell."
