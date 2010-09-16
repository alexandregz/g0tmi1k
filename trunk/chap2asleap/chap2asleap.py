#!/usr/bin/python
#----------------------------------------------------------------------------------------------#
#chap2asleap.py v0.2 (2010-09-16)                                                              #
# (C)opyright 2010 - g0tmi1k                                                                   #
#---Important----------------------------------------------------------------------------------#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#---Modules------------------------------------------------------------------------------------#
import os, re, sys, hashlib, getopt, binascii

#---Variables----------------------------------------------------------------------------------#
asleap_path   = '/pentest/wireless/asleap' # NO trailing '/'
wordlist_path = '/pentest/passwords/wordlists/darkc0de.lst'
verbose = False
run = False
wordlist = False
txtUser = ''
txtChal = ''
txtChal = ''

#----Functions---------------------------------------------------------------------------------#
def SplitList( list, chunk_size ):
	return "".join([list[offs:offs+chunk_size] + ':' for offs in range(0, len(list), chunk_size)])
def help_message():
	print '''(C)opyright 2010 g0tmi1k ~ http://g0tmi1k.blogspot.com
	
 Usage: python chap2asleap.py [options]
 
 Options:
   -u username...             -- Username
   -c 0123456789ABCDEF...     -- PPP CHAP Challenge (32 characters)
   -r 0123456789ABCDEF...     -- PPP CHAP Response  (98 characters)

   -h                         -- Displays this help message
   -v                         -- Verbosity mode (shows more detail)

   -x                         -- Runs asleap with arguments afterwards
   -w                         -- Uses "Wordlist" instead of "genkey" (Default)
   -p "/path/to/asleap"       -- Default:''' + asleap_path + '''
   -d "/path/to/wordlist.lst" -- Default:''' + wordlist_path + '''
   
   --update                   -- Downloads the latest version

 Example:
   python chap2asleap.py -u scott -c e3a5d0775370bda51e16219a06b0278f -r 84c4b33e00d9231645598acf91c384800000000000000000565fe2492fd5fb88edaec934c00d282c046227406c31609b00 -x -v

 Extra Help:
Authors Page: http://www.willhackforsushi.com/Asleap.html
   Blog Post: http://g0tmi1k.blogspot.com/2010/03/script-chap2asleappy.html
       Video: http://g0tmi1k.blogspot.com/2010/03/video-cracking-vpn-asleap-thc-pptp.html'''
	sys.exit(0)

def updateScript():
	from urllib2 import Request, urlopen, URLError, HTTPError

	print "[>] Updating..."
	url = "http://g0tmi1k.googlecode.com/svn/trunk/chap2asleap/chap2asleap.py"
	req = Request(url)
	try:
		f = urlopen(req)
		local_file = open("chap2asleappy.py", "w")
		local_file.write(f.read())
		local_file.close()
		print "[>] Updated! (="
	except HTTPError, e:
		print "[!] Failed. HTTP Error:",e.code , url
	except URLError, e:
		print "[!] Failed. URL Error:",e.reason , url
	sys.exit(0)

      
#---Main---------------------------------------------------------------------------------------#
print "[*] chap2asleap v0.2 ~ Asleap Argument Generator"

#----------------------------------------------------------------------------------------------#
try:
    opts, args = getopt.getopt(sys.argv[1:], "u:c:r:vxwp:d:h", ["user=","challenge=","response=","path=","wordlist=","help","update"])
except getopt.GetoptError, err:
    # print help information and exit:
    print str(err) # will print something like "option -a not recognized"
    sys.exit(0)

if len(opts) == 0 :
    help_message()
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
        asleap_path = a
    if o in ("-d", "--wordlist"):
        wordlist_path = a
    if o in ("-h", "--help"):
        help_message()
    if o in ("--update"):
        updateScript()

#----------------------------------------------------------------------------------------------#
if txtUser == "":
	print "Sorry, you need to input a username (-u)."
	sys.exit(0)
if txtChal == "":
	print "Sorry, you need to input a PPP CHAP Challenge (-c)."
	sys.exit(0)
if txtResp == "":
	print "Sorry, you need to input a PPP CHAP Response (-r)."
	sys.exit(0)
txtChal = txtChal.replace(':', '')
txtResp = txtResp.replace(':', '')
if len(txtChal) != 32:
	print "Sorry, PPP CHAP Challenge has to be 32 btyes in length."
	sys.exit(0)
if len(txtResp) != 98:
	print "Sorry, PPP CHAP Response has to be 98 btyes in length."
	sys.exit(0)
if not re.search("[0-f]", txtChal):
	print "Sorry, you cant input that for the CHAP Challenge. 0-9 a-f."
	sys.exit(0)
if not re.search("[0-f]", txtResp):
	print "Sorry, you cant input that for the CHAP Response. 0-9 a-f."
	sys.exit(0)
	
#----------------------------------------------------------------------------------------------#
if verbose == True: print "[>]       Username: " + txtUser
if verbose == True: print "[>] CHAP Challenge: " + txtChal
if verbose == True: print "[>]  CHAP Response: " + txtResp

#----------------------------------------------------------------------------------------------#
authChallenge = binascii.unhexlify(txtChal)
peerChallenge = binascii.unhexlify((txtResp)[0:32])

response = txtResp[48:96]

challenge = ((hashlib.sha1( peerChallenge + authChallenge + txtUser )).hexdigest())[0:16]

if verbose == True: print "[>] Auth Challenge: " + txtChal
if verbose == True: print "[>] Peer Challenge: " + (txtResp)[0:32]
if verbose == True: print "[>]  Peer Response: " + response
if verbose == True: print "[>]      Challenge: " + challenge + "\n"

challenge = (SplitList (challenge,2 ))[0:-1]
response  = (SplitList  (response,2 ))[0:-1]

#----------------------------------------------------------------------------------------------#
if verbose == True: print 'cd '+ asleap_path
if (verbose == True and wordlist == False): print './genkey -r ' + wordlist_path + ' -f words.dat -n words.idx'
if wordlist == False: print './asleap -C ' + challenge + ' -R ' + response + ' -f words.dat -n words.idx' + '\n\n'
if wordlist == True: print './asleap -C ' + challenge + ' -R ' + response + ' -W ' + wordlist_path + '\n\n'

#----------------------------------------------------------------------------------------------#
if (run == True and wordlist == False): os.system( asleap_path + '/genkeys -r ' + wordlist_path + ' -f /tmp/words.dat -n /tmp/words.idx')
if (run == True and wordlist == False): os.system( asleap_path + '/asleap -C ' + challenge + ' -R ' + response + ' -f /tmp/words.dat -n /tmp/words.idx')
if (run == True and wordlist == True): os.system( asleap_path + '/asleap -C ' + challenge + ' -R ' + response + ' -W ' + wordlist_path)

#----------------------------------------------------------------------------------------------#
if (run == True and wordlist == False): os.remove ('/tmp/words.dat')
if (run == True and wordlist == False): os.remove ('/tmp/words.idx')
