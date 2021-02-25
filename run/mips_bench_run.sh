#!/bin/bash

SW_LOC=../software/apps/mips_elf_loader

MIPS_ELF_LOADER_BIN=mips_elf_loader
MIPS_ELF_LOADER=$SW_LOC/$MIPS_ELF_LOADER_BIN

REMOTE_USER=root
REMOTE_PASSWD="111111"
REMOTE_IP=$1
REMOTE_HOME=/$REMOTE_USER
REMOTE_DIR=$REMOTE_HOME/single_cycle_cpu_wp

SSH_TARGET=$REMOTE_USER@$REMOTE_IP
SSH_RUN="sshpass -p $REMOTE_PASSWD"
SSH_FLAG="-o StrictHostKeyChecking=no"

BENCH_DIR=../benchmark/$2/bin

BENCH_LIST=$3

$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "mkdir -p $REMOTE_DIR"
		
$SSH_RUN scp $SSH_FLAG $MIPS_ELF_LOADER $SSH_TARGET:$REMOTE_DIR
	
$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "chmod 755 $REMOTE_DIR/$MIPS_ELF_LOADER_BIN"

N_PASSED=0
N_TESTED=0
for bench in $BENCH_LIST
do
	BENCH_NAME=`cat $BENCH_DIR/../list | grep "#$bench" | awk -F "," '{print $2}'`

	if [ "$BENCH_NAME" = "" ]
	then
		echo "Error: No serial number $bench in medium benchmark suite. \
	Please verify your specified serial number list of medium benchmark suite"

		# remove workspace on remote FPGA board after close GNOME terminal
		$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "rm -rf $REMOTE_DIR"

		exit
	fi

	#Launching benchmark in the list
	echo "Launching $BENCH_NAME benchmark..."
	
	$SSH_RUN scp $SSH_FLAG $BENCH_DIR/$BENCH_NAME $SSH_TARGET:$REMOTE_DIR
	$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "$REMOTE_DIR/$MIPS_ELF_LOADER_BIN $REMOTE_DIR/$BENCH_NAME $LOG_LEVEL"
    RESULT=$?

    if [ $RESULT -eq 0 ]
    then
        echo "Hit good trap"
        N_PASSED=$(expr $N_PASSED + 1)
    else
        echo "Hit bad trap"
    fi
    N_TESTED=$(expr $N_TESTED + 1)
	
	if [ "$LOG_LEVEL" = "verbose" ]
	then
		$SSH_RUN scp $SSH_FLAG $SSH_TARGET:$REMOTE_DIR/$BENCH_NAME.log ./log
	fi
done

echo "pass $N_PASSED / $N_TESTED"

# remove workspace on remote FPGA board after close GNOME terminal
$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "rm -rf $REMOTE_DIR"

