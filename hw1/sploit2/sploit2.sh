#!/bin/bash

## ------------------ Description -------------------- ##
## This sploit inserts shellcode into the log buffer in
## main and then uses the printf vulnerability in writeLog
## to overwite the return pointer to go to this code.
## --------------------------------------------------- ##

## Note: Since this exploit and sploit1 don't depend on faking the block.list
## they should be removed eventually. This is just to allow us to execute them
## from the repo
mkdir -p sploit2_dir
cd sploit2_dir
mkdir -p .bcvs
touch .bcvs/block.list

