#!/bin/bash

REPO_SRC=$1
GIT_DIR=${2:-"/home/$USER/github"}
REPO_NAME=$(basename $REPO_SRC | cut -d '.' -f 1)
LOCAL_VC_DIR="$GIT_DIR/$REPO_NAME"

if [ -d $LOCAL_VC_DIR ]
then
    echo -e "\x1b[1;32m Pulling $REPO_NAME repository...\e[0m"
    cd $GIT_DIR/$REPO_NAME
    git pull $REPO_SRC
else
    echo -e "\x1b[1;32m Cloning $REPO_NAME repository...\e[0m"
    mkdir -p $GIT_DIR
    cd $GIT_DIR
    git clone $REPO_SRC
fi
