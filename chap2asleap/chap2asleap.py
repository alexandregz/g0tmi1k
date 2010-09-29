#!/usr/bin/python
#----------------------------------------------------------------------------------------------#
#chap2asleap.py v0.2 (#2 2010-09-28)                                                           #
# (C)opyright 2010 - g0tmi1k                                                                   #
#---Important----------------------------------------------------------------------------------#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#              The programs are provided as is without any guarantees or warranty.             #
#---Modules------------------------------------------------------------------------------------#
import os, re, sys, hashlib, getopt, binascii

#---Defaults-----------------------------------------------------------------------------------#
# [/path/to/the/file] Use which file
wordlistPath = "/pentest/passwords/wordlists/darkc0de.lst"

# [/path/to/the/folder] Where is asleap?
asleapPath = "/pentest/wireless/asleap"

# [True/False] Shows more info
verbose = False

# [True/False] Runs asleap afterwords
run = False

# [True/False] Use the wordlist for the attack
wordlist = False

#---Variables----------------------------------------------------------------------------------#
version = "0.2 #2"
txtUser = "" # null the value
txtChal = "" # null the value
txtResp = "" # null the value
action = "\033[32m[>]\033[0m "
info = "\033[33m[i]\033[0m "
diag = "\033[34m[+]\033[0m "
error = "\033[31m[!]\033[0m "

#----Functions---------------------------------------------------------------------------------#
def SplitList( list, chunk_size ):
	return "".join([list[offs:offs+chunk_size] + ":" for offs in range(0, len(list), chunk_size)])

def help_message():
	print """(C)opyright 2010 g0tmi1k ~ http://g0tmi1k.blogspot.com

 Usage: python chap2asleap.py [options]

 Options:
   -u username...            -- Username
   -c 0123456789ABCDEF...    -- PPP CHAP Challenge (32 characters)
   -r 0123456789ABCDEF...    -- PPP CHAP Response  (98 characters)

   -x                        -- Runs asleap afterwards
   -w                        -- Uses "Wordlist" for the attack, instead of "genkey" (Default is genkey)
   -p /path/to/asleap        -- Example: """ + asleapPath + """
   -d /path/to/wordlist.lst  -- Example: """ + wordlistPath + """


   -h                        -- Displays this help message
   -v                        -- Verbosity mode (shows more detail)

   --update                  -- Downloads the latest version

 Example:
   python chap2asleap.py -u scott -c e3a5d0775370bda51e16219a06b0278f -r 84c4b33e00d9231645598acf91c384800000000000000000565fe2492fd5fb88edaec934c00d282c046227406c31609b00 -x -v

 Extra Help:
   Authors Page: http://www.willhackforsushi.com/Asleap.html
      Blog Post: http://g0tmi1k.blogspot.com/2010/03/script-chap2asleappy.html
          Video: http://g0tmi1k.blogspot.com/2010/03/video-cracking-vpn-asleap-thc-pptp.html"""
	sys.exit(0)

def updateScript():
   from urllib2 import Request, urlopen, URLError, HTTPError

   print action+"Updating..."
   url = "http://g0tmi1k.googlecode.com/svn/trunk/chap2asleap/chap2asleap.py"
   req = Request(url)
   try:
      f = urlopen(req)
      local_file = open("chap2asleap.py", "w")
      local_file.write(f.read())
      local_file.close()
      print action+"Updated! (="
   except HTTPError, e:
      print error+"Failed. HTTP Error:",e.code , url
   except URLError, e:
      print error+"Failed. URL Error:",e.reason , url
   sys.exit(0)


#---Main---------------------------------------------------------------------------------------#
print "\033[36m[*]\033[0m chap2asleap v"+version+" ~ Asleap Argument Generator"

#----------------------------------------------------------------------------------------------#
try:
    opts, args = getopt.getopt(sys.argv[1:], "u:c:r:vxwp:d:h?", ["user=","challenge=","response=","path=","wordlist=","help", "update"])
except getopt.GetoptError, err:
    # print help information and exit:
    print str(err) # will print something like "option -a not recognized"
    sys.exit(0)

#if len(opts) == 0 :
#    help_message()
for o, a in opts:
    if o in ("-u", "--user"):
        txtUser = a
    if o in ("-c", "--challenge"):
        txtChal = a
    if o in ("-r", "--response"):
        txtResp = a
    if o == "-v":
        verbose = True
    if o == "-x":
        run = True
    if o == "-w":
        wordlist = True
    if o in ("-p", "--path"):
        asleapPath = a
    if o in ("-d", "--wordlist"):
        wordlistPath = a
    if o in ("-h", "--help", "-?"):
        help_message()
    if o  == "--update":
        updateScript()

#----------------------------------------------------------------------------------------------#
mainLoop = True
while mainLoop:
   if txtUser == "" : txtUser = raw_input("[~] Please enter the username: ")
   else : mainLoop = False

mainLoop = True
while mainLoop:
   if txtChal == "" : txtChal = raw_input("[~] Please enter the PPP CHAP Challenge: ")
   txtChal = txtChal.replace(":", "")
   if not re.search("[0-f]", txtChal) :
	  txtChal = ""
	  print error+"Sorry, you can't input that for the CHAP Challenge. Only 0-9 a-f."
   elif len(txtChal) != 32 :
	  txtChal = ""
	  print error+"Sorry, PPP CHAP Challenge has to be 32 bytes in length."
   else :
      mainLoop = False

mainLoop = True
while mainLoop:
   if txtResp == "" : txtResp = raw_input("[~] Please enter the PPP CHAP Response: ")
   txtResp = txtResp.replace(":", "")
   if not re.search("[0-f]", txtResp) :
	  print error+"Sorry, you can't input that for the CHAP Response. Only 0-9 a-f."
	  txtResp = ""
   elif len(txtResp) != 98 :
	  print error+"Sorry, PPP CHAP Response has to be 32 bytes in length."
	  txtResp = ""
   else :
      mainLoop = False

if asleapPath[-1:] == "/" : asleapPath = asleapPath[0:-1]

#----------------------------------------------------------------------------------------------#
if verbose == True: print info+"      Username: " + txtUser
if verbose == True: print info+"CHAP Challenge: " + txtChal
if verbose == True: print info+" CHAP Response: " + txtResp

#----------------------------------------------------------------------------------------------#
authChallenge = binascii.unhexlify(txtChal)
peerChallenge = binascii.unhexlify((txtResp)[0:32])

response = txtResp[48:96]

challenge = ((hashlib.sha1( peerChallenge + authChallenge + txtUser )).hexdigest())[0:16]

if verbose == True: print info+"Auth Challenge: " + txtChal
if verbose == True: print info+"Peer Challenge: " + (txtResp)[0:32]
if verbose == True: print info+" Peer Response: " + response
if verbose == True: print info+"     Challenge: " + challenge

challenge = (SplitList (challenge,2 ))[0:-1]
response  = (SplitList (response,2 ))[0:-1]

#----------------------------------------------------------------------------------------------#
print action+"Result:"

print "cd " + asleapPath
if wordlist == False :
   print "./genkey -r " + wordlistPath + " -f words.dat -n words.idx"
   print "./asleap -C " + challenge + " -R " + response + " -f words.dat -n words.idx"
else :
   print "./asleap -C " + challenge + " -R " + response + " -W " + wordlistPath

#----------------------------------------------------------------------------------------------#
if (os.path.isfile(asleapPath + "/genkeys") and run == True) :
   if wordlist == False :
      os.system( asleapPath + "/genkeys -r " + wordlistPath + " -f /tmp/words.dat -n /tmp/words.idx")
      os.system( asleapPath + "/asleap -C " + challenge + " -R " + response + " -f /tmp/words.dat -n /tmp/words.idx")
      os.remove ("/tmp/words.dat")
      os.remove ("/tmp/words.idx")
   if wordlist == True :
      os.system( asleapPath + "/asleap -C " + challenge + " -R " + response + " -W " + wordlistPath)
elif run == True :
   print "alseap isn't located: " + asleapPath

#----------------------------------------------------------------------------------------------#
print "\033[36m[*]\033[0m Done! (= Have you... g0tmi1k?"