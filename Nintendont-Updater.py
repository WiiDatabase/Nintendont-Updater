import psutil
import os

currentversion = '2.0dev'
header = '			Nintendont Updater v' + currentversion + ' von WiiDatabase.de\n'

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

def start(error=None):
    cls()
    print(header)
    print('			Willkommen beim Nintendont-Updater der WiiDatabase!\n')
    print('			Gib die Ziffer deines USB-Gerätes bzw. deiner SD-Karte an.\n')
    # Show all partitions to the user
    partitions = psutil.disk_partitions()
    for c,p in enumerate(partitions):
        print('     #' + str(c+1), p.mountpoint + ' - ', str(psutil.disk_usage(p.mountpoint).free / 1024 / 1024 / 1024)[:6] + ' GB frei')
    
    if error == 'ValueError': # if input is not a number
        print('\n     Bitte eine Zahl angeben!')
    elif error == 'IndexError': # if input is not in list or <= 0
        print('\n     Ungültige Eingabe!')

    try:
        usbdevice = int(input("\n     Gerät # "))
    except (KeyboardInterrupt, SystemExit):
        print('\n     Tschüss!')
        quit()
    except ValueError:
        start(error='ValueError')
    
    if usbdevice <= 0: # no negative numbers for list!
        start(error='IndexError')

    try:
        chosendevice = psutil.disk_partitions()[usbdevice-1]
    except IndexError: # if input is too high
        start(error='IndexError')
    print(chosendevice)
    quit()

start()