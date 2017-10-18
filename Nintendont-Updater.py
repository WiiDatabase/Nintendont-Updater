#!/usr/bin/env python3
import os
import re
import sys
import tempfile
import zipfile
from shutil import copy, rmtree
from urllib.parse import urlparse

import psutil
from requests import get

currentversion = '2.0'
header = '			Nintendont Updater v' + currentversion + ' von WiiDatabase.de\n'
base = 'https://raw.githubusercontent.com/FIX94/Nintendont/master'
working_dir = os.path.join(tempfile.gettempdir(), 'Nintendont-Updater')


def cls():
    os.system('cls' if os.name == 'nt' else 'clear')


def clean_up_tempdir():
    if os.path.exists(working_dir):
        rmtree(working_dir)


def download_file(url):
    if not os.path.exists(working_dir):
        os.makedirs(working_dir)

    url_info = urlparse(url)
    filename = os.path.join(working_dir, os.path.basename(url_info.path))
    try:
        response = get(url)
    except:
        return None
    if response.status_code != 200:
        return None

    # Write to file
    with open(filename, "wb") as file:
        file.write(response.content)
        return file.name


def fat32_req():
    error = None
    while True:
        cls()
        print(header)
        print('			Das gewählte Gerät ist nicht in FAT32 formatiert!\n')
        print('			Nintendont kann nur von einem FAT32-Gerät geladen werden.\n')
        if error == 'AnswerError':
            print('\n     Ungültige Eingabe!')
        try:
            answer = input("\n     Trotzdem benutzen? (J/N): ")
        except (KeyboardInterrupt, SystemExit):
            print('\n     Tschüss!')
            sys.exit(0)

        if answer == "J" or answer == "j":
            return True
        elif answer == "N" or answer == "n":
            return False
        else:
            error = "AnswerError"
            continue


def choose_device():
    error = None
    while True:
        cls()
        print(header)
        print('			Willkommen beim Nintendont-Updater der WiiDatabase!\n')
        print('			Gib die Ziffer deines USB-Gerätes bzw. deiner SD-Karte an.\n')
        # Show all partitions to the user
        partitions = psutil.disk_partitions()
        all_devices = []
        for num, partition in enumerate(partitions):
            if partition.fstype != '':
                free_space = round(psutil.disk_usage(partition.mountpoint).free / 1024 / 1024 / 1024, 2)
                print('     #{0} - {1}, {2}'.format(
                    str(num + 1),
                    partition.mountpoint,
                    str(free_space).replace('.', ',') + ' GB frei')
                )
                all_devices.append(partition)

        if error == 'ValueError':  # if input is not a number
            print('\n     Bitte eine Zahl angeben!')
        elif error == 'IndexError':  # if input is not in list or <= 0
            print('\n     Ungültige Eingabe!')

        try:
            usbdevice = int(input("\n     Gerät # "))
        except (KeyboardInterrupt, SystemExit):
            print('\n     Tschüss!')
            sys.exit(0)
        except ValueError:
            error = 'ValueError'
            continue

        if usbdevice <= 0:  # no negative numbers for list!
            error = 'IndexError'
            continue

        try:
            device = all_devices[usbdevice - 1]
        except IndexError:  # if input is too high
            error = 'IndexError'
            continue

        if device.fstype != 'FAT32':
            use_it = fat32_req()
            if use_it:
                break
            else:
                continue
        else:
            break
    return device


def get_nintendont_version():
    cls()
    print(header)
    print('			Prüfe aktuelle Nintendont-Version...')
    version_file = download_file(url=base + '/common/include/NintendontVersion.h')
    if not version_file:
        clean_up_tempdir()
        print('			Die aktuelle Version konnte nicht geholt werden :(')
        input('			Drücke ENTER, um zu beenden')
        sys.exit(1)

    major = None
    minor = None
    with open(version_file) as file:
        for line in file:
            if "#define NIN_MAJOR_VERSION" in line:
                try:
                    major = re.search('(\d+)', line).group(1)
                except AttributeError:
                    return None
            if "#define NIN_MINOR_VERSION" in line:
                try:
                    minor = re.search('(\d+)', line).group(1)
                except AttributeError:
                    return None

    if not major or not minor:
        return None
    return str(major) + '.' + str(minor)


def install_nintendont(device):
    files = [
        "/loader/loader.dol",
        "/nintendont/titles.txt",
        "/nintendont/meta.xml",
        "/nintendont/icon.png",
        "/controllerconfigs/controllers.zip",
    ]
    full_file_path = []
    print('')
    for file in files:
        print('			Downloade ' + os.path.basename(file) + '...')
        downloaded_file = download_file(base + file)
        if not downloaded_file:
            clean_up_tempdir()
            print('\n			Fehler beim Herunterladen, prüfe deine Internetverbindung,')
            print('			und prüfe, ob die URL erreichbar ist:')
            print(base + file)
            input('\n			Drücke ENTER, um zu beenden')
            sys.exit(1)
        full_file_path.append(downloaded_file)
    print('')

    nintendont_path = os.path.join(device.mountpoint, 'apps', 'nintendont')
    controllers_path = os.path.join(device.mountpoint, 'controllers')
    if not os.path.exists(nintendont_path):
        try:
            os.makedirs(nintendont_path)
        except (FileNotFoundError, PermissionError) as exception:
            clean_up_tempdir()
            print('\n	Ein Fehler ist aufgetreten: ' + str(exception))
            input('\n			Drücke ENTER, um zu beenden')
            sys.exit(1)
    if not os.path.exists(controllers_path):
        try:
            os.makedirs(controllers_path)
        except (FileNotFoundError, PermissionError) as exception:
            clean_up_tempdir()
            print('\n	Ein Fehler ist aufgetreten: ' + str(exception))
            input('\n			Drücke ENTER, um zu beenden')
            sys.exit(1)

    for file in full_file_path:
        basefile = os.path.basename(file)
        print('			Verschiebe ' + basefile + '...')
        if basefile == 'loader.dol':
            try:
                copy(file, os.path.join(nintendont_path, 'boot.dol'))
            except (FileNotFoundError, PermissionError) as exception:
                clean_up_tempdir()
                print('\n	Ein Fehler ist aufgetreten: ' + str(exception))
                input('\n			Drücke ENTER, um zu beenden')
                sys.exit(1)
        elif basefile == 'controllers.zip':
            print('			Entpacke...')
            with zipfile.ZipFile(file, "r") as zip_ref:
                try:
                    zip_ref.extractall(controllers_path)
                except (FileNotFoundError, PermissionError) as exception:
                    clean_up_tempdir()
                    print('\n	Ein Fehler ist aufgetreten: ' + str(exception))
                    input('\n			Drücke ENTER, um zu beenden')
                    sys.exit(1)
        else:
            try:
                copy(file, nintendont_path)
            except (FileNotFoundError, PermissionError) as exception:
                clean_up_tempdir()
                print('\n	Ein Fehler ist aufgetreten: ' + str(exception))
                input('\n			Drücke ENTER, um zu beenden')
                sys.exit(1)


def update_meta_xml(path, nintendont_ver):
    print('\n			Aktualisiere Version in der meta.xml...')
    with open(path, "r") as file:
        lines = file.readlines()
    with open(path, "w") as file:
        for line in lines:
            file.write(re.sub(r'<version>.+</version>', '<version>' + nintendont_ver + '</version>', line))


def main():
    # Let the user choose a device
    device = choose_device()

    # Clean up working directory, if exist
    clean_up_tempdir()

    # Get current Nintendont version
    nintendont_ver = get_nintendont_version()
    if not nintendont_ver:
        print('			Die aktuelle Version konnte nicht geholt werden :(')
        input('			Drücke ENTER, um zu beenden')
        clean_up_tempdir()
        sys.exit(1)

    new_install = True
    meta_xml_path = os.path.join(device.mountpoint, 'apps', 'nintendont', 'meta.xml')
    if os.path.exists(meta_xml_path):
        with open(meta_xml_path) as file:
            for line in file:
                if "<version>" in line:
                    try:
                        installed_ver = re.search('<version>(\d+\.\d+)</version>', line).group(1)
                        new_install = False
                    except AttributeError:
                        pass

    if new_install:
        print('\n			Installiere Nintendont...')
    else:
        nintendont_ver_int = int(nintendont_ver.replace('.', ''))
        installed_ver_int = int(installed_ver.replace('.', ''))
        print('\n			Deine Version: ' + installed_ver)
        print('			Aktuelle Version: ' + nintendont_ver)
        if nintendont_ver_int > installed_ver_int:
            print('\n			Deine Version ist veraltet und wird aktualisiert.')
        elif nintendont_ver_int == installed_ver_int:
            clean_up_tempdir()
            print('\n			Deine Version ist aktuell!')
            input('\n			Drücke ENTER, um zu beenden')
            sys.exit(0)
        elif nintendont_ver_int < installed_ver_int:
            clean_up_tempdir()
            print('\n			Deine Version ist zu neu!?')
            print('			Bitte downloade Nintendont erneut.')
            input('\n			Drücke ENTER, um zu beenden')
            sys.exit(1)

    install_nintendont(device)
    update_meta_xml(meta_xml_path, nintendont_ver)
    clean_up_tempdir()

    if new_install:
        print('\n			Nintendont wurde erfolgreich installiert!')
    else:
        print('\n			Nintendont wurde erfolgreich aktualisiert!')
    input('\n			Drücke ENTER, um zu beenden')
    sys.exit(0)


if __name__ == '__main__':
    main()
