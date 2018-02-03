vboxmanage () { VBoxManage.exe "$@"; }

#List of Declares to be used throughout this script
declare script_path="$(readlink -f $0)"
declare script_dir=$(dirname "${script_path}")
declare vm_name="alex_wp_vm2"
declare network_name="sys_net_prov"

# Create NAT Netwok
vboxmanage natnetwork add --netname ${network_name} --network "192.168.254.0/24" --enable --dhcp off
vboxmanage natnetwork modify --netname ${network_name} --port-forward-4 "HTTP:tcp:[]:50080:[192.168.254.10]:80"
vboxmanage natnetwork modify --netname ${network_name} --port-forward-4 "HTTPS:tcp:[]:50443:[192.168.254.10]:443"
vboxmanage natnetwork modify --netname ${network_name} --port-forward-4 "SSH:tcp:[]:50022:[192.168.254.10]:22"

# Create VM
vboxmanage createvm --name ${vm_name} --register

# Cludge to get the path of the directory where the vbox file is stored.    
# Used to create hard disk file in same directory as vbox file without using 
# absolute paths

# vboxmanage showvminfo displays line with the path to the config file -> grep "Config file returns it
declare vm_info="$(VBoxManage.exe showvminfo "${vm_name}")"
declare vm_conf_line="$(echo "${vm_info}" | grep "Config file")"

# Windows: the extended regex [[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox matches everything that is a path 
# i.e. C:\ followed by anything not a \ and then repetitions of that ending in a filename with .vbox extension
declare vm_conf_file="$( echo "${vm_conf_line}" | grep -oE '[[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox' )"

# strip leading text and trailing filename from config file line to leave directory of VM
declare vm_directory_win="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\\[^\]\+\.vbox$//')"

# Strip leading text from the config file line and convert from windows path to wsl linux path 
declare vm_directory_linux="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\([[:upper:]]\):/\/mnt\/\L\1/ ; s/\\/\//g')"

# Remove file part of path leaving directory
vm_directory_linux="$(dirname "$vm_directory_linux")"

# WSL commands will use the linux path, whereas Windows native commands (most
# importantly VBoxManage.exe) will use the windows style path.
echo "${vm_directory_linux}"
echo "${vm_directory_win}"

#Create Virtual Hard Disk
vboxmanage createhd --filename "${vm_directory_win}"/${vm_name}.vdi --size 10000 -variant Standard

#Add Storage Controllers
vboxmanage storagectl ${vm_name} --name DVD --add IDE --bootable on
vboxmanage storagectl ${vm_name} --name HDD --add SATA --bootable on

#Attach an installation ISO
declare iso_file_path="./CentOS-7-x86_64-Minimal-1708.iso"
declare guest_additions_path="C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"

vboxmanage storageattach ${vm_name} \
            --storagectl DVD \
            --port 0 \
            --device 0 \
            --type dvddrive \
            --medium ${iso_file_path}

# Attach the VirtualBox Guest Additions ISO file
vboxmanage storageattach ${vm_name} \
            --storagectl DVD \
            --port 1 \
            --device 0 \
            --type dvddrive \
            --medium "${guest_additions_path}"

# Attach a Hard Disk
vboxmanage storageattach ${vm_name} \
            --storagectl HDD \
            --port 0 \
            --device 0 \
            --type hdd \
            --medium "${vm_directory_win}"/${vm_name}.vdi \
            --nonrotational on

# Configure a VM
vboxmanage modifyvm ${vm_name}\
            --ostype "RedHat_64"\
            --cpus 1\
            --hwvirtex on\
            --nestedpaging on\
            --largepages on\
            --firmware bios\
            --nic1 natnetwork\
            --nat-network1 "${network_name}"\
            --cableconnected1 on\
            --audio none\
            --boot1 disk\
            --boot2 dvd\
            --boot3 none\
            --boot4 none\
            --memory "1280"


# Start VM
vboxmanage startvm ${vm_name} --type gui