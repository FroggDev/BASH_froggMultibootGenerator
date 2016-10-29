# BASH_froggMultibootGenerator
Multi boot generator ISO and/or USB Key in BASH

Can be configurated at the start of the file :


#Workspace

### WHERE ISO IMG TAR.GZ SOURCE ARE TAKEN TO BUILD MULTIBOOT
ISOSOURCEPATH=~/ISO/
### SYSLINUX VERSION TO BE DOWNLOADED & USED
SYSVER=6.03
### WORKSPACE FOLDER PATH
WSPATH=/var/tmp/Workspace/
### ISO CONTENT FOLDER PATH (not important)
ISOPATH=${WSPATH}ISO/
### ISO & FILE CONTENT FOLDER IN ISO GENERATED (not important)
IMGPATH=images/
### ISO RESULT FILENAME (not important)
ISOFILE=bootable.iso
### NAME OF THE GENERATED ISO & KEY
ISONAME="HAND MADE ISO"
### AUTO INSTALL REQUIRED PACKAGES 1 = yes / 0 = no
AUTOPKG=0
### WHERE THE ISO WILL BE TEMPORRARY MOUNT TO COPY FILES FROM IT  (not important)
TMPISOMOUNT=/media/tmpiso
### OPTION PASSED TO IMG WHEN BOOTED
IMGOPT="splash debian-installer/language=fr console-setup/layoutcode=fr local=fr_FR"

#isolinux menu
### Displayed title
MENUNAME="My custom tools" 
### Displayed message
MENUTAB="Select the desired operation"
### Time out before autostart
MENUTIMEOUT="0"
### Background image
MENUBGPATH=~/ISO/frogg.png


<img src="https://tool.frogg.fr/inc/img/article/syslinux/Multiboot_generator.png"/>
