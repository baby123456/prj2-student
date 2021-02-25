#!/bin/bash

VIVADO_TOOL=$1
HW_DBG=$2

ROOT_PASSWD="111111"

VPN_USER_SET=/opt/.vpn_user
VPN_ROUTE=172.16.15.0

VPN_XL2T_CONF=/etc/xl2tpd/xl2tpd.conf
VPN_DIAL_CONF=/etc/ppp/peers/testvpn.l2tpd

LOCAL_DIAL_CONF=testvpn.l2tpd

XL2TPD_BIN=/etc/init.d/xl2tpd
XL2TPD_CTRL=/var/run/xl2tpd/l2tp-control

BIT_FILE_BIN=system.bit.bin
BIT_FILE=../hw_plat/$BIT_FILE_BIN
BIT_TARGET_LOC=/lib/firmware

FPGA_CFG_LOC=/sys/class/fpga_manager/fpga0/firmware

XVC_SERVER_BIN=xvc_server
XVC_SERVER=../software/apps/$XVC_SERVER_BIN/$XVC_SERVER_BIN

HW_DBG_RUN=`pwd`/hw_dbg.tcl

# check if .bit.bin file is ready in this repository
if [ ! -e $BIT_FILE ]
then
	echo "Error: No binary bitstream file is ready"
	exit
fi

# remove known hosts for ssh to FPGA board
rm ~/.ssh/known_hosts

#=======================
# Step 1: Obtain target board IP address
#=======================
if [ "$3" = "cloud" ]
then
	VPN_USER=$4

	# obtain VPN passwd according to user name
	VPN_PASSWD=`cat $VPN_USER_SET | grep $VPN_USER | awk -F "," '{print $2}'`

	if [ -z "$VPN_PASSWD" ]
	then
		echo "Error: $VPN_USER is not allowed to connect FPGA cloud"
		echo "Please contact your system administrator for help"
		exit
	fi

	# check if VPN configuration file exists
	if [ ! -e $VPN_DIAL_CONF ]
	then
		# generate dialing configuration file
		touch $LOCAL_DIAL_CONF
		echo "remotename testvpn" > $LOCAL_DIAL_CONF
		echo "user \"$VPN_USER\"" >> $LOCAL_DIAL_CONF
		echo "password \"$VPN_PASSWD\"" >> $LOCAL_DIAL_CONF
		echo -e "unit 0\nlock\nnodeflate\nnobsdcomp\nnoauth\npersist" >> $LOCAL_DIAL_CONF
		echo -e "nopcomp\nnoaccomp\nmaxfail 5\ndebug" >> $LOCAL_DIAL_CONF

		echo $ROOT_PASSWD | sudo -S mv $LOCAL_DIAL_CONF $VPN_DIAL_CONF
	else
		USER_IN_CONF=`cat $VPN_DIAL_CONF | grep "user" | awk '{print $2}'`
		if [ "\"$VPN_USER\"" != "$USER_IN_CONF" ]
		then
			echo "Error: The input VPN user name is not the owner of this virtual machine"
			exit
		fi
	fi

	# ring off VPN first
	VPN_RUN=`ps -ef | grep xl2tpd | grep sbin`
	if [ -n "$VPN_RUN" ]
	then
		echo $ROOT_PASSWD | sudo -S bash -c "echo 'd testvpn' > $XL2TPD_CTRL"
		echo $ROOT_PASSWD | sudo -S $XL2TPD_BIN stop
		echo $ROOT_PASSWD | sudo -S poff -a
		sleep 3
	fi

	# dial up VPN
	echo $ROOT_PASSWD | sudo -S $XL2TPD_BIN start
	sleep 3
	echo $ROOT_PASSWD | sudo -S bash -c "echo 'c testvpn' > $XL2TPD_CTRL"
	sleep 5

	# check if ppp is created
	PPP_EXIST=`cat /proc/net/dev | grep ppp0`
	
	if [ -z "$PPP_EXIST" ]
	then
		echo "Error: No ppp device generated. Please try again"
		exit
	fi
	
	# obtain target board IP
	REMOTE_IP=`ifconfig ppp0 | grep inet | awk '{print $2}' | awk -F ":" '{print $2}' | sed 's/14/15/'`

	if [ -z "$REMOTE_IP" ]
	then
		echo "Error: No allocated IP address. Please try again"
		exit
	fi
	
	# add routing information
	echo $ROOT_PASSWD | sudo -S ip route add $VPN_ROUTE/24 dev ppp0

elif [ "$3" = "local" ]
then
	REMOTE_IP=$4
else
	echo "Error: Invalid parameter setting for eval_mode"
	exit
fi

REMOTE_USER=root
REMOTE_HOME=/$REMOTE_USER

SSH_TARGET=$REMOTE_USER@$REMOTE_IP
SSH_RUN="sshpass -p $ROOT_PASSWD"
SSH_FLAG="-o StrictHostKeyChecking=no"

echo "Remote target: $SSH_TARGET"

#=======================
# Step 2: FPGA configuration
#=======================
# Step 2.1: Copy .bit.bin file to target board
$SSH_RUN scp $SSH_FLAG $BIT_FILE $SSH_TARGET:$BIT_TARGET_LOC

# Step 2.2 configuration of FPGA logic
$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "echo $BIT_FILE_BIN > $FPGA_CFG_LOC" 

echo "Completed FPGA configuration"

#=======================
# Step 3: Setup remote hardware debugging environment via XVC
#=======================
if [ "$2" = "y" ]
then
	# Step 3.1: Copy XVC Server to remote board
	$SSH_RUN scp $SSH_FLAG $XVC_SERVER $SSH_TARGET:$REMOTE_HOME

	# Step 3.2: Start XVC server on target board 
	$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "$REMOTE_HOME/$XVC_SERVER_BIN > /dev/null &"

	# Step 3.3: Start local Vivado hw_server and connect to XVC
	VIVADO_FLAG="-nojournal -nolog -mode gui -source $HW_DBG_RUN -tclargs $REMOTE_IP"
	mkdir -p vivado_run
	cd vivado_run
	$VIVADO_TOOL $VIVADO_FLAG > /dev/null &
	cd -
fi

#=======================
# Step 4: Launch specified interactive shell script 
#=======================
if [ "$5" = "basic" ]
then
	echo "Evaluating basic benchmark suite..."
	BENCH=01
elif [ "$5" = "medium" ]
then
	echo "Evaluating medium benchmark suite..."
	if [ "$6" = "all" ]
	then
		BENCH="01 02 03 04 05 06 07 08 09 10 11 12"
	else
		BENCH=$6
	fi
elif [ "$5" = "advanced" ]
then
	echo "Evaluating advanced benchmark suite..."
	if [ "$6" = "all" ]
	then
		BENCH="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17"
	else
		BENCH=$6
	fi
fi
bash mips_bench_run.sh $REMOTE_IP $5 "$BENCH"

#=======================
# Step 5: Clean environment of local VM and target board
#=======================
if [ "$2" = "y" ]
then
	# Step 5.1: Waiting for user to close Vivado hw_server GUI
	VIVADO_PID=`ps -ef | grep "$HW_DBG_RUN" | grep "vivado" | awk '{print $2}'`
	while [ -n "$VIVADO_PID" ]
	do
		sleep 1

		VIVADO_PID=`ps -ef | grep "$HW_DBG_RUN" | grep "vivado" | awk '{print $2}'`
	done

	# Step 5.2: Kill XVC server running on target board
	XVC_SERVER_PID=`$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "pidof $XVC_SERVER_BIN"`
	$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "kill -9 $XVC_SERVER_PID && rm -f $REMOTE_HOME/$XVC_SERVER_BIN"
fi
$SSH_RUN ssh $SSH_FLAG $SSH_TARGET "rm -f $BIT_TARGET_LOC/$BIT_FILE_BIN"

#=======================
# Step 6: VPN dialing off if necessary
#=======================
if [ "$3" = "cloud" ]
then
	echo $ROOT_PASSWD | sudo -S bash -c "echo 'd testvpn' > $XL2TPD_CTRL"
	echo $ROOT_PASSWD | sudo -S $XL2TPD_BIN stop
	echo $ROOT_PASSWD | sudo -S poff -a
fi

