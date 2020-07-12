#!/bin/bash
if [ "$#" -ne 1 ]
then
        # set default user
        USER_NAME="user"
else
        USER_NAME=$2
fi

export DISPLAY=:0
su $USER_NAME -c onboard
