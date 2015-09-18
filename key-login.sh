#!/bin/bash
#
# This file will make a ssh key login and optionally create a nickname for the remote machine in your ssh config 
echo -e "Please enter the ssh command that you would normally use to access the desired remote machine:"
read  -p "> " ssh_cmd
ssh_cmd=$(echo $ssh_cmd | sed "s/ssh //" | tr "@" " ")
read -a arr <<< $ssh_cmd

echo -e "username: \033[1m${arr[0]}\033[0m"
echo -e "machine:  \033[1m${arr[1]}\033[0m"

read -p "Is this correct? [y/N] " yn
case $yn in
    [Nn]* ) echo "Please try again."; exit;;
esac

if [ ! -f ~/.ssh/id_rsa ]; then
    read -p "Your public rsa key has not been generated, would you like to do so now? [y/N] " yn
    case $yn in
        [Yy]* ) echo -e "\033[1mPlease use the default settings below\033[0m"; ssh-keygen;;
        * ) exit;;
    esac
fi

echo -e "\033[1mTransfering your public key to the remote machine.\nPlease use default settings and type your password if neccesary.\033[0m"
cat ~/.ssh/id_rsa.pub | ssh ${arr[0]}@${arr[1]} 'cat >> .ssh/authorized_keys'

read -p "Would you like to create a ssh shortcut for this computer (eg. ssh cluster)? [y/N] " yn
case $yn in
    [Yy]* )
        while true
        do
            read -p "Please give this computer a nickname: " nick;
            echo -e "You entered \033[1m${nick}\033[0m. Is this correct? [y/N/c] \c";
            read ync
            case $ync in
                [Yy]* ) echo -e "Host ${nick}\n\tUser\t\t${arr[0]}\n\tHostName\t${arr[1]}\n" >> ~/.ssh/config; break;;
                [Cc]* ) echo -e "A ssh alias was not created."; break;;
                * ) echo "Sorry, please try again";;
            esac
        done
esac

echo -e "All finished. Enjoy!"