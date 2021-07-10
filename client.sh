#!/bin/bash
sudo apt -y update 
sudo apt -y install xfce4 
sudo apt-get -y install xrdp 
sudo systemctl enable xrdp 
sudo echo xfce4-session >~/.xsession 
sudo service xrdp restart
sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt -y install ./google-chrome-stable_current_amd64.deb