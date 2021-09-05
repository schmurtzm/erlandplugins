## control Line-in on Squeezebox Radio remotely (via CLI interface)

This is a modified version of SqueezePlayAdmin plugin from Erland to control Line-in on Squeezebox Radio remotely.
	(and may be others like Squeezebox Boom but not tested)


### How to install :
On LMS server :
---------------
add this plugin repository :

https://raw.githubusercontent.com/schmurtzm/erlandplugins/master/repository/trunk/testing.xml

Then activate the plugin "SqueezePlay Admin Client + Line-In control *Beta*"

On Squeezebox Boom :
--------------------
Settings -> Advanced -> Applet Installer -> unselect "Recommanded Applets Only" and then install "SqueezePlay Admin + Line-In control *Beta*"

### How to use :

Then You can switch to line in with CLI with these commands (00:xx:xx:xx:xx:xx is the mac address of the Squeezebox Boom) :

Reminder for the CLI : telnet IP_LMS_Server 9090
```bash
squeezeplayadmin enable_linein 00:xx:xx:xx:xx:xx
squeezeplayadmin disable_linein 00:xx:xx:xx:xx:xx
```

OR
```url
http://IP_LMS_Server:9000/status.html?p0=squeezeplayadmin&p1=enable_linein&p2=00:xx:xx:xx:xx:xx
```
For Home Assistant :
(switch to line-in on the squeezebox when Google Home is playing spotify)

```yaml
alias: Spotify_GoogleHome_To_Squeezebox_Automation
description: Enable Squeezebox Boom input when Google Home Mini is playing Spotify
trigger:
  - platform: state
    entity_id: media_player.MyGoogleHome
    attribute: app_name
    to: Spotify
condition: []
action:
  - service: squeezebox.call_query
    data:
      parameters:
        - enable_linein
        - 00:xx:xx:xx:xx:xx
      command: squeezeplayadmin
    target:
      entity_id: media_player.MySqueezebox
mode: single
```



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
> Have Squeezebox logs when executing applets functions :
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
> Modify and test an applet : use Winscp to edit then to test it is faster to restart squeezeplay process than restarting the Squeezebox :
> 
> ```bash/etc/init.d/squeezeplay stopwdog && /etc/init.d/squeezeplay restart```


