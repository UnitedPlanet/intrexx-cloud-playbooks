#!/bin/bash

## These methods provide the ability to execute a script and create a file or script
## with variables in a temporary folder, which allows to restart the scripts without
## the need to comment some already executed scripts out.
## General procedure:
## 1. Check if the script has already been executed, by looking up the scripts name
##    the temp folder.
## 2. Either load the script, if it has already been executed or run it (this behavior
##    changes among the methods) 

## This method checks whether the given script has already been executed. If this is not
## the case, the script is executed. Otherwise the script of the temp folder is loaded
## and the script started afterwards.
##  
## Param $1 path to the script
## Param $2 (optional) additional prefix name for the script (in case of multiple calls)
checkLoadAndRun() {
    SCRIPT=$1
    if [ $# -eq 1 ]; then
        NAME=""
    else 
        NAME=$2"-"
    fi
    FILENAME="$(basename $1)"
    shift
    # Only one shift, we want the name to be passed to the script in order to create variables (in case of aws)
    if [ ! -f $TEMP_EXE_FOLDER/$NAME$FILENAME ]; then
        source ./$SCRIPT $TEMP_EXE_FOLDER/$NAME$FILENAME $@
        echo "$LOG_PREFIX $FILENAME for $NAME has been executed successfully."
    fi
    source ./$TEMP_EXE_FOLDER/$NAME$FILENAME
    source ./$SCRIPT $TEMP_EXE_FOLDER/$NAME$FILENAME $@
    echo "$LOG_PREFIX $FILENAME for $NAME has been executed successfully."
}

## This method checks whether the given script has already been executed. If this is not
## the case, the script exits. Otherwise the script of the temp folder is loaded.
##  
## Param $1 path to the script
## Param $2 (optional) additional prefix name for the script (in case of multiple calls)
loadScript() {
    SCRIPT=$1
    if [ $# -eq 1 ]; then
        NAME=""
    else 
        NAME=$2"-"
    fi
    FILENAME="$(basename $1)"
    shift
    # Only one shift, we want the name to be passed to the script in order to create variables (in case of aws)
    if [ ! -f $TEMP_EXE_FOLDER/$NAME$FILENAME ]; then
        echo "$LOG_PREFIX $FILENAME for $NAME does not exist in folder $TEMP_EXE_FOLDER"
        exit 1
    fi
    source ./$TEMP_EXE_FOLDER/$NAME$FILENAME
    echo "$LOG_PREFIX $FILENAME for $NAME has been loaded."
}

## This method checks whether the given script has already been executed. If this is not
## the case, the script is executed. 
##  
## Param $1 path to the script
checkAndRun() {
    SCRIPT=$1
    FILENAME="$(basename $1)"
    shift
    if [ ! -f $TEMP_EXE_FOLDER/$FILENAME ]; then
        source ./$SCRIPT $TEMP_EXE_FOLDER/$FILENAME $@
        touch $TEMP_EXE_FOLDER/$FILENAME       
        echo "$LOG_PREFIX $FILENAME has been executed successfully."
    else
        echo "$LOG_PREFIX $FILENAME has already been executed, execution has been skipped!"
    fi
}

## This method checks whether the given script has already been executed. If this is not
## the case, the script is executed. This method is equal to checkAndRun, but additionally
## allows to set a prefix for the file in the temp folder.
##  
## Param $1 path to the script
## Param $2 (optional) additional prefix name for the script (in case of multiple calls)
checkAndRunRenaming() {
    SCRIPT=$1
    NAME=$2
    FILENAME="$(basename $1)"
    shift
    shift
    if [ ! -f $TEMP_EXE_FOLDER/$NAME-$FILENAME ]; then
        source ./$SCRIPT $@
        touch $TEMP_EXE_FOLDER/$NAME-$FILENAME       
        echo "$LOG_PREFIX $FILENAME for $NAME has been executed successfully."
    else
        echo "$LOG_PREFIX $FILENAME for $NAME has already been executed, execution has been skipped!"
    fi
}

## This method checks whether the given script has already been executed. If this is not
## the case, the script is executed. Otherwise the script of the temp folder is loaded.
##  
## Param $1 path to the script
## Param $2 (optional) additional prefix name for the script (in case of multiple calls)
checkAndRunOrLoad() {
    SCRIPT=$1
    if [ $# -eq 1 ]; then
        NAME=""
    else 
        NAME=$2"-"
    fi
    FILENAME="$(basename $1)"
    shift
    # Only one shift, we want the name to be passed to the script in order to create variables (in case of aws)
    if [ ! -f $TEMP_EXE_FOLDER/$NAME$FILENAME ]; then
        source ./$SCRIPT $TEMP_EXE_FOLDER/$NAME$FILENAME $@
        echo "$LOG_PREFIX $FILENAME for $NAME has been executed successfully."
    fi
    source ./$TEMP_EXE_FOLDER/$NAME$FILENAME
    echo "$LOG_PREFIX $FILENAME for $NAME has already been executed, execution has been skipped!"
}