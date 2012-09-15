#!/bin/bash

# Run this on a new vm to setup some git stuff

# When you push try to use gpush and give your own username
git config --global user.name "5271 Student"
git config --global user.email "student@nosite.com"

git config alias.st status
git config alias.co checkout
git config alias.cm commit
git config alias.br branch

# Sets up the pretty version of the 'git lg' command
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
