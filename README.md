# BackupIt

## Simple AutoIt program to backup Data from Windows to Linux

### About

This program is written in AutoIt and which is used to backup Data from Windows to Linux via SSH connection.

PuTTY and 7zip are the main part of this program. `pscp` and `plink` are used for data transfer and data integrity check. `7za` is used for archiving. 

### Configuration (config.ini)

[General] -> Main Section of config.ini file where Linux Server information is placed.

`user` -> Username for SSH Login

`pass` -> Password for SSH Login (PuTTY SSH Private Key File (.ppk) can be used. Need to put it in the same directory of program.)

`host` -> IP or Hostname of Linux Server

`port` -> Port number of SSH (Default: 22)

`time` -> Number of time to retry connection test (ping). Program will start the archiving and data transfer process only if the connectivity check is successful. (Default: Until ping test is successful)

`wait` -> Waiting time (minutes) for unsuccessful ping check. (Default: 1 minutes)

[Backup] -> Section for Backup Files/Directories information. Section name is your choice and which will be used as archive file name.

`path` -> Backup data location

`name` -> Explicitly defined File/Directory name. E.g. `*.jpg` `*.pdf` `IMAGE*` (Default: Everything under path - Backup data location)

`type` -> Backup data type. (0 = Both Files & Directories, 1 = Files Only, 2 = Directories Only)

`dest` -> Destination of Backup. (Directory Path of Linux Server)

`pday` -> Previous Day - Starting day of the backup. (Default: 1 - Midnight of yesterday)

`nday` -> Next Day - Ending day of the backup. (Default: 0 - Midnight of current date)

If `pday` and `nday` are not assigned. All the data modified between yesterday midnight and today midnight will be kept in archived file (7zip). 

`retn` -> Retention - Number of days to keep the data. 

`rtyp` -> Retention Type - Data to be removed (0 = Both Original Data & Archive file, 1 = Original Data Only, 2 = Archive Files Only)

`ovrw` -> Overwriting Archive File (Default = 1) 

### Example

1. Write config.ini

```ini
[General]
user=sshuser01
pass=pass-123
host=192.168.1.1
port=22
time=3

[data]
path=D:\MyData
name=Works
type=2
dest=/home/sshuser01/Backup/Data
retn=3
rtyp=2
ovrw=0
```

2. Schedule the program in Windows Task Scheduler.