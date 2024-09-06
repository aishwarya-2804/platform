#!/bin/bash

UsrExist=`getent passwd  rsivakumar | cut -d":" -f1`
if [ "$UsrExist" = "rsivakumar" ]; then
usermod -c "rsivakumar@temenos.com" rsivakumar
echo  "rsivakumar:LO_hYARECB1XLir" | chpasswd
else
useradd -m  rsivakumar -c "rsivakumar@temenos.com";echo "rsivakumar:LO_hYARECB1XLir" | chpasswd
fi
if ! grep -Fxq "rsivakumar ALL = (ALL) ALL" /etc/sudoers.d/waagent; then
echo "rsivakumar ALL = (ALL) ALL" >> /etc/sudoers.d/waagent
fi

