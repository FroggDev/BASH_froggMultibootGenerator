#!/bin/bash
#If requiered command to remove Windows line break trouble (\n\r) :
#tr -d '\r' < /home/root/multibootgenertator.sh > temp.$$ && mv temp.$$ /home/root/multibootgenertator.sh
#tr -d '\r' < /home/cecile/Bureau/Upload/atwork/automation.sh > temp.$$ && mv temp.$$ /home/cecile/Bureau/Upload/atwork/automation.sh

###################
#==[ VARIABLES ]==#
###################
# This part can be manually changed if needed
# /!\ Path information must end with /

#==Workspace

# WHERE ISO IMG TAR.GZ SOURCE ARE TAKEN TO BUILD MULTIBOOT
ISOSOURCEPATH=~/ISO/
# SYSLINUX VERSION TO BE DOWNLOADED & USED
SYSVER=6.03
# WORKSPACE FOLDER PATH
WSPATH=/var/tmp/Workspace/
# ISO CONTENT FOLDER PATH (not important)
ISOPATH=${WSPATH}ISO/
# ISO & FILE CONTENT FOLDER IN ISO GENERATED (not important)
IMGPATH=images/
# ISO RESULT FILENAME (not important)
ISOFILE=bootable.iso
# NAME OF THE GENERATED ISO & KEY
ISONAME="HAND MADE ISO"
# AUTO INSTALL REQUIRED PACKAGES 1 = yes / 0 = no
AUTOPKG=0
#WHERE THE ISO WILL BE TEMPORRARY MOUNT TO COPY FILES FROM IT  (not important)
TMPISOMOUNT=/media/tmpiso
#OPTION PASSED TO IMG WHEN BOOTED
IMGOPT="splash debian-installer/language=fr console-setup/layoutcode=fr local=fr_FR"

#==isolinux menu
#Displayed title
MENUNAME="My custom tools" 
#Displayed message
MENUTAB="Select the desired operation"
#Time out before autostart
MENUTIMEOUT="0"
#Background image
MENUBGPATH=~/ISO/frogg.png


##################
#==[ FUNCTION ]==#
##################

#ask user a choice, return 1 if user accpeted else return 0
makeachoice()
{
userChoice=0
while true; do
	read -p " [ Q ] Do you wish to $1 ?" yn
	case $yn in
		y|Y|yes|YES|Yes|O|o|oui|OUI|Oui)userChoice=1;break;;
		n|N|no|NO|No|non|NON|Non)userChoice=0;break;;
		* )warn " '$yn' isn't a correct value, Please choose yes or no";;
	esac
done
return $userChoice
}

#test if command exist, return 0 if command exist else return 1
canExec()
{
type "$1" &> /dev/null ;
}

#test if command exist, return 1 if command doesnot exist else return 0
cannotExec()
{
canExec $1
if [ $? = 1 ]; then
	return 0
else
	return 1
fi
}

#test if url exist, return 0 if command exist else return 1
urlExist()
{
#curl --output /dev/null --silent --head --fail "$1" && return 1 || return 0
wget -q --spider "$1" &&  return 1 || return 0
}

#File/Folder exist -f / -d return false if not found
# exist {file(f)orFolder(d)} {inThePath}
exist()
{
[ -$1 $2 ] && return 1 || return 0
}

#Copy file checing if file & destination exist
fileCopy()
{
hasErr=0
exist "f" $1
[ $? = 0 ] && hasErr=1
exist "d" $2
[ $? = 0 ] && hasErr=1
[ $hasErr = 0 ] && cp $1 $2 
[ $hasErr = 1 ] && return 0 || return 1
}


#########################
#==[ COLORS FUNCTION ]==#
#########################

#===Colors
INFOun="\e[4m"							#underline
INFObo="\e[1m"							#bold
INFb="\e[34m"							#blue
INFr="\e[31m"							#red
INFOb="\e[107m${INFb}"					#blue (+white bg)
INFObb="\e[107m${INFObo}${INFb}"		#bold blue (+white bg)
INFOr="\e[107m${INFr}"					#red (+white bg)
INFOrb="\e[107m${INFObo}${INFr}"		#bold red (+white bg)

NORM="\e[0m"
GOOD="\e[1m\e[97m\e[42m"
OLD="\e[1m\e[97m\e[45m"
CHECK="\e[1m\e[97m\e[43m"
WARN="\e[1m\e[97m\e[48;5;208m"
ERR="\e[1m\e[97m\e[41m"

#==COLOR STYLE TYPE

#echo with "good" result color
good()
{
echo -e "${GOOD}$1${NORM}"
}

#echo with "warn" result color
warn()
{
echo -e "${WARN}$1${NORM}"
}

#echo with "check" result color
check()
{
echo -e "${CHECK}$1${NORM}"
}

#echo with "old" result color
old()
{
echo -e "${OLD}$1${NORM}"
}

#echo with "err" result color
err()
{
echo -e "${ERR}$1${NORM}"
}

# echo an title format
title()
{
case $2 in
	"0")echo -e "\n${INFObb}${INFOun}$1${NORM}";;
	"1")
		x=0 	#reset lvl 3
		y=0		#reset lvl 2
		((z++))	#increase lvl 1
		echo -e "\n${INFObb}${INFOun}${z}] $1${NORM}"
	;;
	"2")
		x=0 	#reset lvl 3
		((y++))	#increase lvl 2
		echo -e "\n${INFOb}${INFOun}${z}.${y}] $1${NORM}"
	;;
	"3")
		((x++)) #increase lvl 3
		echo -e "\n${INFOb}${INFOun}${z}.${y}.${x}] $1${NORM}"
	;;
	*)echo -e "\n$1";;
esac
}


##################
#==[START MENU]==#
##################
SCRIPTNAME=${0##*/}
echo -e "\n*******************************"
echo -e "# Multiboot ISO & USB Key creator"
echo -e "# tested on Linux Debian Jessie"
echo -e "# v1.000, Powered By admin@frogg.fr - Copyright 2016"
echo ""
echo "# call : ${SCRIPTNAME}"
echo "# require wget dialog mkdosfs genisoimage isohybrid"
echo "# Optional Parameters"
echo "# -config   => Only create the config file isolinux.cfg"
echo "# -makeiso  => Only make the iso from config file"
echo "# -isotousb => Only send iso to usb"
echo -e "*******************************"

#Pre-init all
DOCNF=0
DOISO=0
DOUSB=0

for params in $*
do
	IFS=: val=($params)
	case ${val[0]} in
		"-config")
			DOCNF=1
		;;
		"-makeiso")
			DOISO=1
		;;
		"-isotousb")
			DOUSB=1
		;;
	esac
done

# if not option passed, do all
[ DOCNF = 0 ] && [ DOISO = 0 ] && [ DOUSB = 0 ] && DOCNF=1 && DOISO=1 && DOUSB=1

#Getting USB Key list 
USBKEYS=($(                         		# Declaration of *array* 'USBKEYS'
	grep -Hv ^0$ /sys/block/*/removable | 	# search for *not 0* in `removable` flag of all devices
	sed s/removable:.*$/device\\/uevent/ |	# replace `removable` by `device/uevent` on each line of previous answer
	xargs grep -H ^DRIVER=sd |            	# search for devices drived by `SD`
	sed s/device.uevent.*$/size/ |        	# replace `device/uevent` by 'size'
	xargs grep -Hv ^0$ |                  	# search for devices having NOT 0 size
	cut -d / -f 4                         	# return only 4th part `/` separated
))

###################
#==[REQUIREMENT]==#
###################

title "Checking requirement" "1"

#set auto install if set as param
PKGPARAM=""
[ AUTOPKG = 1 ] && PKGPARAM=" -y"

#Check linux package installer
PKGCMD=""
canExec apt-get && PKGCMD="apt-get install${PKGPARAM}"
[ PKGCMD = "" ] && canExec yum && PKGCMD="yum install${PKGPARAM}"
[ PKGCMD = "" ] && canExec zypper && PKGCMD="zypper install${PKGPARAM}"
[ PKGCMD = "" ] && err "Sorry but this script cannot find package installer tool,  exiting from script..." && exit

#Check linux package existence
cannotExec wget && eval ${PKGCMD} wget
cannotExec dialog && eval ${PKGCMD} dialog
cannotExec mkdosfs && eval ${PKGCMD} mkdosfs
cannotExec genisoimage && eval ${PKGCMD} mkdosfs 
cannotExec isohybrid && eval ${PKGCMD} syslinux-utils

#Check if error occured with packages
cannotExec wget && err "an error occured while installing wget, try to add it manually, aborting script..." && exit
cannotExec dialog && err "an error occured while installing dialog, try to add it manually, aborting script..." && exit
cannotExec mkdosfs && err "an error occured while installing mkdosfs, try to add it manually, aborting script..." && exit
cannotExec genisoimage && err "an error occured while installing genisoimage, try to add it manually, aborting script..." && exit
cannotExec isohybrid && err "an error occured while installing syslinux-utils, try to add it manually, aborting script..." && exit

good "All requirement are installed"


################################
#==[ PREPARE ISOLINUX FILES ]==#
################################

title "Setting Syslinux files" "1"

#set vars
SYSPATH=syslinux-${SYSVER}
SYSFILE=${SYSPATH}.tar.gz
SYSURL=https://www.kernel.org/pub/linux/utils/boot/syslinux/${SYSFILE}
SYSCONFIG=${ISOPATH}isolinux/isolinux.cfg
ACPIURL=https://launchpadlibrarian.net/187530745/acpioff.c32

#test if already exist
exist d ${WSPATH}${SYSPATH}
if [ $? = 1 ]; then
	#all is ok nothing to do, folder is already there
	good "${WSPATH}${SYSPATH} already exist, no extra download required"
else
	#test url
	urlExist ${SYSURL};
	if [ $? = 1 ]; then
		#Create the Workspace folder
		mkdir -p ${ISOPATH}isolinux
		#Get the files
		title "Downloading Syslinux files" "2"
		wget ${SYSURL} -P ${WSPATH}
		good "Syslinux has been downloaded to ${WSPATH}${SYSFILE}"
		#Extract the files
		title "Extracting Syslinux files" "2"
		tar -C ${WSPATH} -xzf ${WSPATH}${SYSFILE}
		rm ${WSPATH}${SYSFILE}
		good "Syslinux has been extracted to ${WSPATH}${SYSPATH}"
	else
		#error cannot find download file
		err "Unable to access to ${SYSURL}, aborting script..." && exit
	fi
fi

#Copying require files
title "Copying Syslinux files" "2"
fileCopy ${WSPATH}${SYSPATH}/bios/core/isolinux.bin ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/core/isolinux.bin to ${ISOPATH}isolinux/, aborting script..." && exit
fileCopy ${WSPATH}${SYSPATH}/bios/com32/menu/menu.c32 ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/menu/menu.c32 to ${ISOPATH}isolinux/, aborting script..." && exit
fileCopy ${WSPATH}${SYSPATH}/bios/com32/menu/vesamenu.c32 ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/menu/vesamenu.c32 to ${ISOPATH}isolinux/, aborting script..." && exit
fileCopy ${WSPATH}${SYSPATH}/bios/com32/libutil/libutil.c32 ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/libutil/libutil.c32 to ${ISOPATH}isolinux/, aborting script..." && exit
fileCopy ${WSPATH}${SYSPATH}/bios/com32/elflink/ldlinux/ldlinux.c32 ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/elflink/ldlinux/ldlinux.c32 to ${ISOPATH}isolinux/, aborting script..." && exit
#Create empty configuration file
touch ${SYSCONFIG}
good "Syslinux files has been copied"

#############################
#==[ PREPARE TOOLS FILES ]==#
#############################

title "Setting Tools files" "1"

#Create tools folder
mkdir -p ${ISOPATH}tools/
#Cp reboot & poweroff files
fileCopy ${WSPATH}${SYSPATH}/bios/com32/modules/reboot.c32 ${ISOPATH}tools/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/modules/reboot.c32 to ${ISOPATH}tools/, aborting script..." && exit
fileCopy ${WSPATH}${SYSPATH}/bios/com32/modules/poweroff.c32 ${ISOPATH}tools/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/modules/poweroff.c32 to ${ISOPATH}tools/, aborting script..." && exit
#requirement to have reboot & poweroff works
fileCopy ${WSPATH}${SYSPATH}/bios/com32/lib/libcom32.c32 ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/lib/libcom32.c32 to ${ISOPATH}isolinux/, aborting script..." && exit
#for alternative local boot option
fileCopy ${WSPATH}${SYSPATH}/bios/com32/chain/chain.c32 ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/com32/chain/chain.c32 to ${ISOPATH}isolinux/, aborting script..." && exit
#for iso boot
fileCopy ${WSPATH}${SYSPATH}/bios/memdisk/memdisk ${ISOPATH}isolinux/ && err "cannot copy ${WSPATH}${SYSPATH}/bios/memdisk/memdisk to ${ISOPATH}isolinux/, aborting script..." && exit

makeachoice "use ACPI shutdown (recommended) instead of APM shutdown (old bios)"
if [ $? = 1 ]; then
	exist "f" ${WSPATH}${SYSPATH}/acpioff.c32
	if [ $? = 0 ]; then
		urlExist ${ACPIURL};
		if [ $? = 1 ]; then
			wget ${ACPIURL} -P ${WSPATH}${SYSPATH}/
		else
			err "cannot acces to ${ACPIURL}, you may have to copy it to ${WSPATH}${SYSPATH}/acpioff.c32 manually, aborting script..."
			exit
		fi
	fi	
	cp ${WSPATH}${SYSPATH}/acpioff.c32 ${ISOPATH}tools/poweroff.c32
fi

good "Tools files are ready"


###################################
#==[ CREATE CONFIGURATION FILE ]==#
###################################

title "Setting configuration files" "1"

makeachoice "copy iso source file from ${ISOSOURCEPATH}"
if [ $? = 1 ]; then

	good "The following iso files has been found : "

	cd ${ISOSOURCEPATH}
	shopt -s nullglob
	for ext in iso img gz; do 
		files=( *."${ext}" )
		# now we can loop over all the files having the current extension
		for f in "${files[@]}"; do
			good "=> ${f}"
		done 
	done	

	makeachoice "continue"
	if [ $? = 1 ]; then

#Copy background menu
fileCopy ${MENUBGPATH} ${ISOPATH}isolinux/ && err "cannot copy ${MENUBGPATH} to ${ISOPATH}isolinux/, background image will not be displayed, you can copy it manually in ${ISOPATH}isolinux/ before generating ${ISOFILE}..."
MENUBGFILENAME=${MENUBGPATH##*/}
	
#Set basis file content
cat <<EOF > ${SYSCONFIG}
#Enable advanced display
DEFAULT menu.c32
UI vesamenu.c32

###[ Text ]###
MENU TITLE "${MENUNAME}"
MENU TABMSG "${MENUTAB}"

###[ Configuration ]###
#no prompt (value = 0/1)
PROMPT 0
#0 = no timeout (not required)
TIMEOUT ${MENUTIMEOUT}
#disable ESC from the keybord (value = 0/1)
NOESCAPE 1
#display TAB options (not required value = 0/1)
ALLOWOPTIONS 1

###[ Display ]###
MENU BACKGROUND /isolinux/${MENUBGFILENAME}
MENU RESOLUTION 800 600
MENU MARGIN 20

# Text position
#MENU WIDTH 200 (replace the 100% width with fixed width ... not that good)
#MENU ROWS 28 (doing nothing ?)
#MENU ENDROW 15 (doing nothing ?)
MENU CMDLINEROW 34
MENU HELPMSGROW 29
MENU TABMSGROW 28
MENU PASSWORDROW 8

# Color
MENU COLOR BORDER		0 #00000000 #00000000 none
MENU COLOR TITLE		0 #FFFF9900 * *
MENU COLOR SEL			0 #FFFFFFFF #85000000 *
MENU COLOR UNSEL		0 #FFFFFFFF * *
MENU COLOR HOTKEY		0 #FFFF9900 * *
MENU COLOR HOTSEL		0 #FFFFFFFF #85000000 *
MENU COLOR TABMSG		0 #FFFF9900 * *
MENU COLOR HELP 		0 #FFFFFFFF * *
MENU COLOR PWDHEADER		0 #FFFF9900 #FF006400 std
MENU COLOR PWDBORDER		0 #AAFF9900 #AA006400 std
MENU COLOR PWDENTRY		0 * * *

#I don't know what this could be, but i tried
MENU COLOR CMDLINE		0 #FF006400 * *
MENU COLOR CMDMARK		0 #FF006400 * *
MENU COLOR MSG07		0 #FF006400 * *
MENU MSGCOLOR 			  #FF006400 #80ffffff std
EOF

#Set tools file content
cat <<EOF >> ${SYSCONFIG}
###[ Local boot ]###		
LABEL Localboot
    MENU LABEL ^Exit and continue boot process
    MENU DEFAULT
    LOCALBOOT -1
    TEXT HELP
        Exit and continue normal boot
    ENDTEXT

###[ Reboot ]###
LABEL Reboot
    MENU LABEL ^Reboot computer
    KERNEL /tools/reboot.c32
    TEXT HELP
        Reboot the computer (you can use CTRL+ALT+SUPPR too)
    ENDTEXT
	
###[ Shutdown ]###	
LABEL Shutdown
    MENU LABEL ^Shutdown computer
    KERNEL /tools/poweroff.c32
    TEXT HELP
        Shutdown the computer
    ENDTEXT

###[ blank spacer ]###	
MENU SEPARATOR

EOF
	
		cd ${ISOSOURCEPATH}
		shopt -s nullglob
		for ext in iso img gz; do 
			files=( *."${ext}" )		
			#Extracting iso/img content & Add new entries to menu
			for f in "${files[@]}"; do
				
				#Create a directory to serve as the mount location
				mkdir -p ${TMPISOMOUNT}
				
				check "Processing $f files ... please wait..."
				ISTAR=0
				
				#Getting the content files
				if [ ${f##*\.} = "gz" ];then					
					# extracting tar.gz					
					tar -C ${TMPISOMOUNT} -xzf ${f}
					TMPTARFOLD=${f##*/}
					TMPTARFOLD=${TMPTARFOLD%%\.*}
					ISTAR=1
				else
					# Mount the ISO in the target directory
					mount -o ro,loop,silent ${f} ${TMPISOMOUNT}
				fi

				#==Checking iso content file
				TMPISONAME=${f##*/}
				TMPISOFOLD=${TMPISONAME%%\.*}			
				#create desitnation folder 
				mkdir -p ${ISOPATH}${IMGPATH}${TMPISOFOLD}
				#trying to find initrd file
				TMPFINDRESULT=$( find ${TMPISOMOUNT} -name "initrd.*" )
				
				#==Checking case operation
				# > Case copy iso cause no initrd found
				if [ -z $TMPFINDRESULT ];then
#Copy iso file
cp $f ${ISOPATH}${IMGPATH}${TMPISOFOLD}
#Case copy iso
cat <<EOF >> ${SYSCONFIG}
LABEL $TMPISOFOLD
    MENU LABEL ^$TMPISOFOLD
    KERNEL /isolinux/memdisk
    INITRD /${IMGPATH}$TMPISOFOLD/$TMPISONAME
    APPEND iso raw 
    TEXT HELP
		launch $TMPISOFOLD
    ENDTEXT	
EOF

				else
				
					#Getting INITRD file
					for w in $TMPFINDRESULT;do
						TMPINITRDFULLPATH=$w
						TMPINITRD=${w##*/}
						TMPINITRDFOLD=${w%/*}
						TMPINITRDFOLD=${TMPINITRDFOLD##*/}
					done
					#Copy initrd file
					cp $TMPINITRDFULLPATH ${ISOPATH}${IMGPATH}$TMPISOFOLD/

					#Getting linux or vmlinuz file
					TMPFINDRESULT=$( find ${TMPISOMOUNT} -name "linux" -o -name "vmlinuz.*" )
					for w in $TMPFINDRESULT;do
						TMPLINUXFULLPATH=$w
						TMPLINUX=${w##*/}
					done
					#Copy initrd file
					cp $TMPLINUXFULLPATH ${ISOPATH}${IMGPATH}$TMPISOFOLD/

					#trying to find initrd file
					TMPFINDRESULT=$( find ${TMPISOMOUNT} -name "filesystem.squashfs" )
					
					# > Case copy only linux & initrd cause no squashfs file found
					if [ -z $TMPFINDRESULT ];then
					
cat <<EOF >> ${SYSCONFIG}
LABEL $TMPISOFOLD
	MENU LABEL ^$TMPISOFOLD
	KERNEL /${IMGPATH}$TMPISOFOLD/${TMPLINUX}
	INITRD /${IMGPATH}$TMPISOFOLD/${TMPINITRD}
	APPEND ${IMGOPT}
	TEXT HELP
		launch $TMPISOFOLD
	ENDTEXT	
EOF
					else
					# > Case squashfs file found
#Getting squashfs 
for w in $TMPFINDRESULT;do
	cp $w  ${ISOPATH}${IMGPATH}$TMPISOFOLD/
done			
					
cat <<EOF >> ${SYSCONFIG}
LABEL $TMPISOFOLD
    MENU LABEL ^$TMPISOFOLD
    KERNEL /${IMGPATH}$TMPISOFOLD/${TMPLINUX}
    INITRD /${IMGPATH}$TMPISOFOLD/${TMPINITRD}
    APPEND boot=${TMPINITRDFOLD} live-media-path=/${IMGPATH}$TMPISOFOLD ignore_uuid ${IMGOPT}
    TEXT HELP
		launch $TMPISOFOLD
    ENDTEXT
EOF
					fi
				fi
				#To Unmount the ISO:
				[ ${ISTAR} = 0 ] && umount ${TMPISOMOUNT}
				#remove tempt iso mount folder
				rm ${TMPISOMOUNT} -r
				#result message
				good "$TMPISONAME bas been configurated"
			done
		done 

	#Extra option to manually edit isoconfig file
	makeachoice "manually edit the config file ${SYSCONFIG} for extra customization"	
	if [ $? = 1 ]; then
		canExec nano
		if [ $? = 0 ]; then
			nano ${SYSCONFIG}
		else
			canExec vim
			if [ $? = 0 ]; then
				vim ${SYSCONFIG}
			else			
				canExec vi
				if [ $? = 0 ]; then
					vi ${SYSCONFIG}
				else			
					err "cannot find nano, vim and vi, you will have to manually edit ${SYSCONFIG}"
				fi
			fi
		fi
	fi
		
	else
		#exit if dont want to continue
		check "script aborted by user"
		exit
	fi
fi


########################
#==[ ISO GENERATION ]==#
########################

title "${ISOFILE} generation" "1"

makeachoice "create ${ISOFILE} to ${WSPATH}"
if [ $? = 1 ]; then
	# Create ${ISOFILE} from ISO folder to Workspace
	genisoimage -rational-rock -volid "${ISONAME}" -cache-inodes -joliet -full-iso9660-filenames \
	-b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table -input-charset UTF8 \
	-output ${WSPATH}${ISOFILE} ${ISOPATH}
fi


#####################
#==[ COPY TO USB ]==#
#####################

title "USB Key generation" "1"

makeachoice "copy ${ISOFILE} to USB Key (which USB Key will be asked later)"
if [ $? = 1 ]; then

	#Check if iso file exist
	exist "f" ${WSPATH}${ISOFILE}
	[ $? = 0 ] && err "${WSPATH}${ISOFILE} doesn't exist, you need to create it before" && exit
	
	#==Find USB Key 
	# from http://unix.stackexchange.com/questions/60299/how-to-determine-which-sd-is-usb
	STICK=""
	while true; do

		#User selection from USB Key list
		case ${#USBKEYS[@]} in
			0 ) warn "No USB Stick found";;
			1 ) STICK=$USBKEYS;break;;
			* )
			STICK=$(
			bash -c "$(
				echo -n  dialog --menu \"Choose the USB Key to install the iso file\" 22 76 17;
				for dev in ${USBKEYS[@]} ;do
					echo -n \ $dev \"$( sed -e s/\ *$//g </sys/block/$dev/device/model )\" ;
				done
				)" 2>&1 >/dev/tty
			);[ ! $STICK = "" ] && break;;
		esac
		
		# no USB found ask for retry
		makeachoice "retry USB Key selection"
		[ $? = 0 ] && check "script aborted by user" && exit
		#set USB Key list
		USBKEYS=($(                         		# Declaration of *array* 'USBKEYS'
			grep -Hv ^0$ /sys/block/*/removable | 	# search for *not 0* in `removable` flag of all devices
			sed s/removable:.*$/device\\/uevent/ |	# replace `removable` by `device/uevent` on each line of previous answer
			xargs grep -H ^DRIVER=sd |            	# search for devices drived by `SD`
			sed s/device.uevent.*$/size/ |        	# replace `device/uevent` by 'size'
			xargs grep -Hv ^0$ |                  	# search for devices having NOT 0 size
			cut -d / -f 4                         	# return only 4th part `/` separated
		))
	done

	#==Copying ISO to USB
	makeachoice "continue iso install on '${STICK}', /!\ $STICK datas will erased during the process /!\ "
	if [ $? = 1 ]; then
		title "formating ${STICK}, please wait... this can take really long time... (I didn't find quick format option for mkdosfs)" "2"
		umount /dev/${STICK}1
		mkdosfs -n "${ISONAME}" -I /dev/${STICK} -F 32
		isohybrid ${WSPATH}${ISOFILE}
		title "Sending ${ISOFILE} to ${STICK}, please wait..." "2"
		dd if=${WSPATH}${ISOFILE} of=/dev/${STICK}
	else
		check "script aborted by user"	
		exit
	fi
fi


#########################
#==[ CLEAN WORKSPACE ]==#
#########################

title "Cleanning" "1"

makeachoice "remove folder '${ISOPATH}'"
[ $? = 1 ] && rm ${ISOPATH} -r

makeachoice "remove folder '${WSPATH}' (it can be kept for regenerating iso without re-downloading and copying some files)"
[ $? = 1 ] && rm ${WSPATH} -r


####################
#==[ SCRIPT END ]==#
####################

good "***********************************************"
good "Script process is now over, i hope all was ok !"
good "***********************************************"

#message if workspace has not be removed
exist "d" ${WSPATH} 
if [ $? = 1 ];then
	exist "d" ${ISOPATH} 
	[ $? = 1 ] && warn "${ISOPATH} path still exist with ${ISOFILE} uncompressed content in it, don't forget to delete them once you no more need them"
	warn "${WSPATH} path still exist with ${ISOFILE} and Syslinux file in it, don't forget to delete them once you no more need them"
fi
