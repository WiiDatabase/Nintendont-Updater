@echo off
:top
CLS
COLOR 1F
set currentversion=v1.0
set url=https://raw.githubusercontent.com/FIX94/Nintendont/master
set header=echo			Nintendont-Updater %currentversion% von WiiDatabase.de
mode con cols=85 lines=30
TITLE Nintendont-Updater %currentversion%

::<---- šberprfen, ob die Supportdateien existieren ---->
:check
if not exist 7za.exe goto:fehlt
if not exist sed.exe goto:fehlt
if not exist sfk.exe goto:fehlt
if not exist wget.exe goto:fehlt
goto:start

:fehlt
CLS
%header%
echo.
echo.
echo.
echo		FEHLER: Eine oder mehrere Support-Dateien fehlen
echo		Fge bitte eine Ausnahme in deinem Antivirenprogramm
echo		fr alle Supportdateien hinzu!
echo		Bitte downloade das Programm von WiiDatabase.de neu!
echo.
echo														Der Nintendont-Updater wird mit einem Tastendruck beendet.
pause >NUL
exit

:start
CLS
%header%
echo.
if /i "%false%" EQU "1" (echo.) && (echo		 %start% ist keine gltige Eingabe.) && (echo		 Bitte versuche es erneut!)
echo.
echo			Willkommen beim Nintendont-Updater der WiiDatabase!
echo.
if /i "%false%" EQU "2" (echo.) && (echo		   %sdtemp:~0,2% existiert nicht, oder Nintendont ist nicht vorhanden)
if /i "%false%" EQU "3" (echo.) && (echo		 Gebe bitte den Lauwerksbuchstaben mit Doppelpunkt ein!)
set menu=
set sdtemp=
set false=
echo.
echo		Gebe den Laufwerksbuchstaben deiner SD-Karte oder deinem USB-Ger„t an.
echo.
echo         Beispiele:
echo            F:
echo            G:
echo.
echo		[0] Beenden
echo.
set /p sdtemp=	Eingabe:	

if /i "%sdtemp%" EQU "0" exit

::Anfhrungszeichen von der Variable entfernen
echo "set SDTEMP=%sdtemp%">temp.txt
sfk filter -quiet temp.txt -rep _""""__>temp.bat
call temp.bat
del temp.bat>nul
del temp.txt>nul


:doublecheck
set fixslash=
if /i "%sdtemp:~-1%" EQU "\" set fixslash=ja
if /i "%sdtemp:~-1%" EQU "/" set fixslash=ja
if /i "%fixslash%" EQU "ja" set sdtemp=%sdtemp:~0,-1%
if /i "%fixslash%" EQU "ja" goto:doublecheck

::<!-- Wenn der zweite Buchstabe ein : ist, checke nach, ob das Ger„t existiert -->
if /i "%sdtemp:~1,1%" NEQ ":" (set false=3) && (goto:start)
:skipcheck

set PFAD=%sdtemp%
if exist "%PFAD%\apps\nintendont" (goto:checkver) else (set false=2) && (goto:start)

set false=1
goto:start

:checkver
CLS
%header%
echo.
echo			Checke aktuelle Nintendont-Version...
start /min/wait wget -t 3 --no-check-certificate "%url%/common/include/NintendontVersion.h"
if not exist NintendontVersion.h goto:error

sfk filter "NintendontVersion.h"  -+"#define NIN_MAJOR_VERSION" -rep ."#define NIN_MAJOR_VERSION			"."set majorver=".>availablever.bat
sfk filter "NintendontVersion.h"  -+"#define NIN_MINOR_VERSION" -rep ."#define NIN_MINOR_VERSION			"."set minorver=".>>availablever.bat
call availablever.bat
set availablever=%majorver%.%minorver%
del NintendontVersion.h
if exist availablever.bat del availablever.bat

if not exist %PFAD%\apps\nintendont\meta.xml set goto:miniskip
sfk filter -quiet "%PFAD%\apps\nintendont\meta.xml" -+"/version" -rep _"*<version>"_"set existingver="_ -rep _"</version*"__ >existingver.bat
call existingver.bat
if exist existingver.bat del existingver.bat
:miniskip

echo.
echo			Deine Version: %existingver%
echo			Aktuelle Version: %availablever%
echo.
if /i "%existingver:.=%" EQU "%availablever:.=%" goto:aktuell
if /i "%existingver:.=%" LEQ "%availablever:.=%" goto:update
if /i "%existingver:.=%" GEQ "%availablever:.=%" goto:zuneu
pause
goto:error

:update
echo.
echo		    Deine Version ist veraltet und wird aktualisiert!
if exist download rmdir /s /q download\
mkdir download
start /min/wait wget --no-check-certificate -P download\ %url%/controllerconfigs/controllers.zip %url%/loader/loader.dol %url%/nintendont/titles.txt %url%/nintendont/meta.xml %url%/nintendont/icon.png https://raw.githubusercontent.com/dolphin-emu/dolphin/master/Data/Sys/GC/font_ansi.bin https://raw.githubusercontent.com/dolphin-emu/dolphin/master/Data/Sys/GC/font_sjis.bin
start /min/wait 7za x -y -o%PFAD%\controllers\ download\controllers.zip
move /Y download\loader.dol %PFAD%\apps\nintendont\boot.dol >NUL
move /Y download\icon.png %PFAD%\apps\nintendont\ >NUL
move /Y download\meta.xml %PFAD%\apps\nintendont\ >NUL
move /Y download\titles.txt %PFAD%\apps\nintendont\ >NUL
move /Y download\font_*.bin %PFAD% >NUL
rmdir /s /q download\
echo.
echo		    Update Version in meta.xml...
sed "s/<version>.*<\/version>/<version>%availablever%<\/version>/"  %PFAD%\apps\nintendont\meta.xml >meta.xml
move /Y meta.xml %PFAD%\apps\nintendont\ >NUL
echo.
echo		    Nintendont wurde erfolgreich aktualisiert!
echo.
echo		    Drcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
exit

:aktuell
echo.
echo		      Deine Version ist aktuell!
echo.
echo		      Drcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
exit

:zuneu
echo.
echo		      Deine Version ist zu neu!?
echo		      Bitte downloade Nintendont erneut.
echo.
echo		      Drcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
exit

:error
CLS
%header%
echo.
echo		Ein Fehler ist aufgetreten (Keine Netzverbindung?).
echo 		Drcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
exit