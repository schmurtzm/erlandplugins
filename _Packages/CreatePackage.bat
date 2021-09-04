:: Quick and dirty package creator
:: The good way to do it : https://github.com/Logitech/slimserver-tools/tree/master/PluginBuilder

@echo off

del /Q /F SqueezePlayAdminClient-0.1.3018.zip
del /Q /F SqueezePlayAdmin-0.1.39.zip


tools\7za.exe a -tzip SqueezePlayAdminClient-0.1.3018.zip ..\SqueezePlayAdminClient > NUL
call tools\sha1.bat  "SqueezePlayAdminClient-0.1.3018.zip" sha1_var
echo sha1 of the SqueezePlayAdminClient Applet : 
echo %sha1_var%
powershell -Command "(gc tools\RepoTemplate.xml) -replace 'YYYYYYYYY', '%sha1_var%' | Out-File -encoding ASCII tools\myFile.txt"

echo.

tools\7za.exe a -tzip SqueezePlayAdmin-0.1.39.zip ..\squeezebox-squeezeplayadmin\* > NUL
call tools\sha1.bat  "SqueezePlayAdmin-0.1.39.zip" sha1_var
echo sha1 of the SqueezePlayAdmin Plugin : 
echo %sha1_var%
powershell -Command "(gc tools\myFile.txt) -replace 'xxxxxxxxx', '%sha1_var%' | Out-File -encoding ASCII ..\repository\trunk\testing.xml"

del /Q /F tools\myFile.txt


echo. & echo the repo file has been updated
echo (repository\trunk\testing.xml)
echo.






pause