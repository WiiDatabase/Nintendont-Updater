@echo off
:top
CLS
COLOR 1F
set currentversion=v1.2.1.2
set url=https://raw.githubusercontent.com/FIX94/Nintendont/master
set header=echo			Nintendont-Updater %currentversion% von WiiDatabase.de
mode con cols=85 lines=30
TITLE Nintendont-Updater %currentversion%

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
echo		FEHLER: Eine oder mehrere Support-Dateien fehlen
echo		FÅge bitte eine Ausnahme in deinem Antivirenprogramm
echo		fÅr alle Supportdateien hinzu!
echo		Bitte downloade das Programm von WiiDatabase.de neu!
echo.
echo														Der Nintendont-Updater wird mit einem Tastendruck beendet.
pause >NUL
exit

:start
CLS
%header%
echo.
if /i "%false%" EQU "1" (echo			 	%sdtemp% ist keine gÅltige Eingabe.) && (echo			 	Bitte versuche es erneut!) && (echo.)
echo.
echo			Willkommen beim Nintendont-Updater der WiiDatabase!
echo.
if /i "%false%" EQU "2" (echo.) && (echo		   %sdtemp:~0,2% existiert nicht, oder Nintendont ist nicht vorhanden)
if /i "%false%" EQU "3" (echo.) && (echo		 Gebe bitte den Lauwerksbuchstaben mit Doppelpunkt ein!)
set sdtemp=
set false=
echo.
echo		Gebe den Laufwerksbuchstaben deiner SD-Karte oder deinem USB-GerÑt an.
echo.
echo         Beispiele:
echo            F:
echo            G:
echo.
echo		[0] Beenden
echo.
set /p sdtemp=	Eingabe:	

if /i "%sdtemp%" EQU "0" exit

::AnfÅhrungszeichen von der Variable entfernen
if exist "%TEMP%\Nintendont-Updater" rmdir /s /q "%TEMP%\Nintendont-Updater"
if not exist "%TEMP%\Nintendont-Updater" mkdir "%TEMP%\Nintendont-Updater"
echo "set SDTEMP=%sdtemp%">"%TEMP%\Nintendont-Updater\temp.txt"
sfk filter -quiet "%TEMP%\Nintendont-Updater\temp.txt" -rep _""""__>"%TEMP%\Nintendont-Updater\temp.bat"
call "%TEMP%\Nintendont-Updater\temp.bat"
del "%TEMP%\Nintendont-Updater\temp.txt">nul
del "%TEMP%\Nintendont-Updater\temp.bat">nul

:doublecheck
set fixslash=
if /i "%sdtemp:~-1%" EQU "\" set fixslash=ja
if /i "%sdtemp:~-1%" EQU "/" set fixslash=ja
if /i "%fixslash%" EQU "ja" set sdtemp=%sdtemp:~0,-1%
if /i "%fixslash%" EQU "ja" goto:doublecheck

::<!-- Wenn der zweite Buchstabe ein : ist, checke nach, ob das GerÑt existiert -->
if /i "%sdtemp:~1,1%" NEQ ":" (set false=3) && (goto:start)
:skipcheck

set PFAD=%sdtemp%
if exist "%PFAD%\apps\nintendont" goto:checkver
if exist "%PFAD%" goto:newinstall

set false=1
goto:start

:checkver
CLS
%header%
echo.
echo			Checke aktuelle Nintendont-Version...
start /min/wait wget -t 3 --no-check-certificate -P "%TEMP%\Nintendont-Updater" "%url%/common/include/NintendontVersion.h"
if not exist "%TEMP%\Nintendont-Updater\NintendontVersion.h" goto:error
sfk filter "%TEMP%\Nintendont-Updater\NintendontVersion.h"  -+"#define NIN_MAJOR_VERSION" -rep ."#define NIN_MAJOR_VERSION			"."set majorver=".>"%TEMP%\Nintendont-Updater\availablever.bat"
sfk filter "%TEMP%\Nintendont-Updater\NintendontVersion.h"  -+"#define NIN_MINOR_VERSION" -rep ."#define NIN_MINOR_VERSION			"."set minorver=".>>"%TEMP%\Nintendont-Updater\availablever.bat"
call "%TEMP%\Nintendont-Updater\availablever.bat"
set availablever=%majorver%.%minorver%
del "%TEMP%\Nintendont-Updater\NintendontVersion.h"
if exist "%TEMP%\Nintendont-Updater\availablever.bat" del "%TEMP%\Nintendont-Updater\availablever.bat"

if not exist %PFAD%\apps\nintendont\meta.xml (set existingver=0) && (goto:miniskip)
sfk filter -quiet "%PFAD%\apps\nintendont\meta.xml" -+"/version" -rep _"*<version>"_"set existingver="_ -rep _"</version*"__ >"%TEMP%\Nintendont-Updater\existingver.bat"
call "%TEMP%\Nintendont-Updater\existingver.bat"
if exist "%TEMP%\Nintendont-Updater\existingver.bat" del "%TEMP%\Nintendont-Updater\existingver.bat"
if "%existingver%" EQU "" goto:error

:miniskip
echo.
if /i "%newinstall%" NEQ "J" echo			Deine Version: %existingver%
echo			Aktuelle Version: %availablever%
echo.
if /i "%existingver:.=%" EQU "%availablever:.=%" goto:aktuell
if /i "%existingver:.=%" LEQ "%availablever:.=%" goto:update
if /i "%existingver:.=%" GEQ "%availablever:.=%" goto:zuneu
goto:error

:update
echo.
if /i "%newinstall%" EQU "J" (echo		    	Nintendont wird installiert...) else (echo		    Deine Version ist veraltet und wird aktualisiert!)
start /min/wait wget --no-check-certificate -P "%TEMP%\Nintendont-Updater" %url%/controllerconfigs/controllers.zip %url%/loader/loader.dol %url%/nintendont/titles.txt %url%/nintendont/meta.xml %url%/nintendont/icon.png
start /min/wait 7za x -y -o%PFAD%\controllers\ "%TEMP%\Nintendont-Updater\controllers.zip"
move /Y "%TEMP%\Nintendont-Updater\loader.dol" %PFAD%\apps\nintendont\boot.dol >NUL
move /Y "%TEMP%\Nintendont-Updater\icon.png" %PFAD%\apps\nintendont\ >NUL
move /Y "%TEMP%\Nintendont-Updater\meta.xml" %PFAD%\apps\nintendont\ >NUL
move /Y "%TEMP%\Nintendont-Updater\titles.txt" %PFAD%\apps\nintendont\ >NUL
echo.
echo		    	Update Version in meta.xml...
sed "s/<version>.*<\/version>/<version>%availablever%<\/version>/"  %PFAD%\apps\nintendont\meta.xml >"%TEMP%\Nintendont-Updater\meta.xml"
move /Y "%TEMP%\Nintendont-Updater\meta.xml" %PFAD%\apps\nintendont\ >NUL
echo.
if /i "%newinstall%" EQU "J" (echo		    	Nintendont wurde erfolgreich installiert!) else (echo		    	Nintendont wurde erfolgreich aktualisiert!)
echo.
echo		    	DrÅcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
rmdir /s /q "%TEMP%\Nintendont-Updater"
exit

:aktuell
echo.
echo		    	Deine Version ist aktuell!
echo.
echo		    	DrÅcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
rmdir /s /q "%TEMP%\Nintendont-Updater"
exit

:zuneu
echo.
echo		    	Deine Version ist zu neu!?
echo		    	Bitte downloade Nintendont erneut.
echo.
echo		    	DrÅcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
rmdir /s /q "%TEMP%\Nintendont-Updater"
exit

:error
CLS
%header%
echo.
echo		    	Ein Fehler ist aufgetreten:
echo			Keine Netzverbindung oder die Version ist leer.
echo.
echo		    	Bitte melde diesen Fehler an WiiDatabase.de.
echo.
echo		    	DrÅcke eine beliebige Taste zum Beenden.
echo.
pause >NUL
exit

:newinstall
CLS
%header%
echo.
if /i "%false%" EQU "1" (echo		 	%newinstall% ist keine gÅltige Eingabe.) && (echo		 	Bitte versuche es erneut!) && (echo.)
set false=
set newinstall=
echo			Nintendont existiert auf %PFAD% nicht.
echo			Mîchtest du Nintendont nun auf dieses GerÑt herunterladen?
echo.
echo			[J] = Ja
echo			[N] = Nein - ZurÅck zur Laufwerksauswahl
echo			[B] = Beenden
echo.
set /p newinstall=	Eingabe:	

if /i "%newinstall%" EQU "J" (mkdir "%PFAD%\apps\nintendont") && (goto:checkver)
if /i "%newinstall%" EQU "N" goto:start
if /i "%newinstall%" EQU "B" exit

set false=1
goto:newinstall