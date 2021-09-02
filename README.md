## control Line-in on Squeezebox Radio remotely (via CLI interface)

This is a modified version of SqueezePlayAdmin plugin from Erland to control Line-in on Squeezebox Radio remotely.
	(and may be others like Squeezebox Boom but not tested)

### Information about SqueezePlayAdmin plugin :

> official topic : 
> 
> https://forums.slimdevices.com/showthread.php?77494-Announce-Applet-Plugin-for-remote-administration-of-SqueezePlay
> 
> Official Website : 
> 
> http://downloads.isaksson.info/download/do/viewapplication?name=slimserver-squeezeplayadmin
> 
> Official Github :
>> 
>> applet :
>> 
>> https://github.com/erland/squeezebox-squeezeplayadmin
>> 
>> plugin :
>> 
>> https://github.com/erland/lms-squeezeplayadmin
>> 
>> alternative for plugin :
>> 
>> https://github.com/erland/erlandplugins/tree/master/SqueezePlayAdminClient/trunk/src

---
### Information about my plugin creation :

> https://forums.slimdevices.com/showthread.php?115059-Squeezebox-Radio-Switching-to-Line-in-remotely&p=1031822#post1031822


---
### Difficulties to switch to line-in remotely : 
> https://forums.slimdevices.com/showthread.php?79483-(De-)Activate-LineIn-for-Radio-Boom-using-CLI&highlight=linein
> 
> https://forums.slimdevices.com/showthread.php?96099-Enable-Line-In-via-SSH&highlight=line-in
> 
> https://forums.slimdevices.com/showthread.php?100212-Turn-on-Line-in-via-CLI-interface



---
### Useful information :
> 
> Line-In Plugin : 
> 
> https://github.com/Logitech/slimserver/blob/public/8.3/Slim/Plugin/LineIn/Plugin.pm
> 
> Line-In Button Applet for Radio (shortcut to activate line-in quickly) :
> 
> https://forums.slimdevices.com/showthread.php?109870-ANNOUNCE-Line-In-Button-Applet-for-Radio
> 
> Have logs of the Squeezebox when executing functions :
> 
> activate remote admin on the squeezebox, SSH -> root/1234 , then to see logs : "tail -f /var/log/messages"
> 
> Path of the applet once installed on the squeezebox (use WinSCP with SCP protocol) :
> 
> /usr/share/jive/applets
> 
> Official documentation about applets :
> 
> https://wiki.slimdevices.com/index.php/SqueezePlay_Applets.html
> 
	
