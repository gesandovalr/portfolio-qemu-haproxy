#!/bin/zsh
tofu destroy
ssh-keygen -f '/home/gesora/.ssh/known_hosts' -R '10.20.10.10'
ssh-keygen -f '/home/gesora/.ssh/known_hosts' -R '10.20.10.11'
echo "instance destroyed ssh know hosts removed"