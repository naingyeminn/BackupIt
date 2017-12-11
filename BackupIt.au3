#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Naing Ye Minn

 Script Function:
	Simple Program to backup Data from Windows to Linux

#ce ----------------------------------------------------------------------------

#include <FileConstants.au3>
#include <Crypt.au3>
#include <Date.au3>
#include <File.au3>
#include <Array.au3>

Opt("TrayIconHide", 1)

$pscp = @ScriptDir & "\pscp.exe"
$plink = @ScriptDir & "\plink.exe"
$7za = @ScriptDir & "\7za.exe"
$config = @ScriptDir & "\config.ini"

If Not FileExists($pscp) Or Not FileExists($plink) Or Not FileExists($7za) Then
   MsgBox(0, "Error", "'pscp.exe' or 'plink.exe' or '7za.exe' is missing!")
   Exit
EndIf

If Not FileExists($config) Then
   MsgBox(0, "Error", "'config.ini' is missing!")
   Exit
EndIf


$user = IniRead($config, "General", "user", "")
$pass = IniRead($config, "General", "pass", "")
$host = IniRead($config, "General", "host", "")
$port = IniRead($config, "General", "port", "22")
$time = IniRead($config, "General", "time", "")
$wait = IniRead($config, "General", "wait", "1")



If FileExists(@ScriptDir & "\" & $pass) Then
   $pass = " -i " & $pass
Else
   $pass = " -pw " & $pass
EndIf

$iniSections = IniReadSectionNames($config)
For $i = 1 to $iniSections[0]
   If $iniSections[$i] <> "General" Then
	  ConsoleWrite("Config Section : " & $iniSections[$i] & @CRLF)
	  $path = IniRead($config, $iniSections[$i], "path", "")
	  $name = IniRead($config, $iniSections[$i], "name", "*")
	  $type = IniRead($config, $iniSections[$i], "type", "")
	  $dest = IniRead($config, $iniSections[$i], "dest", "")
	  $pday = IniRead($config, $iniSections[$i], "pday", "1")
	  $nday = IniRead($config, $iniSections[$i], "nday", "0")
	  $retn = IniRead($config, $iniSections[$i], "retn", "")
	  $rtyp = IniRead($config, $iniSections[$i], "rtyp", "0")
	  $ovrw = IniRead($config, $iniSections[$i], "ovrw", "1")

	  If $type > 2 Or $type < 0 Then
		 ConsoleWrite("Incorrect Backup Type for " & $iniSections[$i] & @CRLF)
		 $type = ""
	  EndIf

	  If $path And $type And $dest Then
		 $date = @YEAR&"/"&@MON&"/"&@MDAY
		 $prevdate = _DateAdd("D", -$pday, $date)
		 $formatdate = StringSplit($prevdate,"/")
		 $prevdate = $formatdate[1] & $formatdate[2] & $formatdate[3] & "000000"
		 ConsoleWrite("Start Date : " & $prevdate & @CRLF)
		 $nextdate = _DateAdd("D", $nday, $date)
		 $formatdate = StringSplit($nextdate,"/")
		 $nextdate = $formatdate[1] & $formatdate[2] & $formatdate[3] & "000000"
		 ConsoleWrite("End Date : " & $nextdate & @CRLF)

		 $lastdate = ""
		 If $retn Then
			$lastdate = _DateAdd("D",-$retn,$date)
			$formatdate = StringSplit($lastdate,"/")
			$lastdate = $formatdate[1] & $formatdate[2] & $formatdate[3] & "000000"
		 EndIf

		 $backupdata = _FileListToArray($path, $name, $type, 1)
		 $cleanupdata = _FileListToArray($path, $iniSections[$i] & "_*.7z", 1, 1)

		 $wait = $wait * 60000

		 Local $hash

		 If $time Then
			For $t = 1 to $time
			   If $t < $time Then
				  If Not Ping($host) Then
					 ConsoleWrite($host & " cannot be reached." & @CRLF)
					 Sleep($wait)
				  Else
					 ExitLoop
				  EndIf
			   Else
				  If Not Ping($host) Then
					 ConsoleWrite($host & " cannot be reached." & @CRLF)
					 Exit
				  Else
					 ExitLoop
				  EndIf
			   EndIf
			Next
		 Else
			While Not Ping($host)
			   ConsoleWrite($host & " cannot be reached." & @CRLF)
			   Sleep($wait)
			WEnd
		 EndIf

		 If IsArray($backupdata) Then
			If $ovrw = 0 Then
			   $zipfile = $iniSections[$i] & "_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & ".7z"
			Else
			   $zipfile = $iniSections[$i] & ".7z"
			EndIf

			For $j = 1 To $backupdata[0]
			   $filedate = FileGetTime($backupdata[$j], 0, 1)
			   ConsoleWrite($backupdata[$j] & " - " & $filedate & @CRLF)

			   If $filedate > $prevdate And $filedate < $nextdate Then
				  $zipPath = StringLeft($backupdata[$j],StringInStr($backupdata[$j],"\",0,-1)-1)
				  $zipFullPath = $zipPath & "\" & $zipfile
				  ConsoleWrite("Creating " & $zipfile & @CRLF)
				  $zipping = Run($7za & ' u "' & $zipFullPath & '" "' & $backupdata[$j] & '"', "", @SW_HIDE)
				  ProcessWaitClose($zipping)
			   EndIf

			   If $lastdate Then
				  If $rtyp = 0 Or $rtyp = 1 Then
					 ConsoleWrite("Checking Date of Original Data..." & @CRLF)
					 If $filedate < $lastdate Then
						If StringInStr(FileGetAttrib($backupdata[$j]), "D") Then
						   ConsoleWrite("Deleting Directory : " & $backupdata[$j] & @CRLF)
						   DirRemove($backupdata[$j], 1)
						Else
						   ConsoleWrite("Deleting File : " & $backupdata[$j] & @CRLF)
						   FileDelete($backupdata[$j])
						EndIf
					 EndIf
				  EndIf
			   EndIf
			Next

			Do
			   ConsoleWrite($zipfile & " is uploading..." & @CRLF)
			   $uploading = Run($pscp & $pass & " -P " & $port & ' "' & $zipFullPath & '" ' & $user & "@" & $host & ":" & $dest, "", @SW_HIDE)
			   ProcessWaitClose($uploading)
			   ConsoleWrite($zipfile & " is uploaded." & @CRLF)
			   If Not $hash Then
				  $hash = _Crypt_HashFile($zipFullPath, $CALG_MD5)
			   EndIf
			   $getHash = Run(@ComSpec & ' /c ' & $plink & $pass & ' -P ' & $port & ' ' & $user & '@' & $host & ' echo "0x$(md5sum ' & "'" & $dest & "/" & $zipfile & "'" & ' | cut -d' & "' ' -f1 | tr '[:lower:]' '[:upper:]')" & '"' & " > hash.log", "", @SW_HIDE)
			   ProcessWaitClose($getHash)
			   $hashFileOpen = FileOpen(@ScriptDir & "\hash.log")
			   $hashFileRead = FileReadLine($hashFileOpen)
			   FileClose($hashFileOpen)
			   ConsoleWrite("Remote Hash : " & $hashFileRead & @CRLF)
			   ConsoleWrite("Local Hash : " & $hash & @CRLF)
			   If $hash <> $hashFileRead Then
				  ConsoleWrite("Hash of " & $zipfile & " is Incorrect!" & @CRLF)
				  Sleep(5000)
			   EndIf
			Until $hash == $hashFileRead

			ConsoleWrite("Hash of " & $zipfile & " is Correct!" & @CRLF)
			$hash = ""
		 EndIf

		 If IsArray($cleanupdata) Then
			If $rtyp = 0 Or $rtyp = 2 Then
			ConsoleWrite("Checking Date of Archived Data..." & @CRLF)
			   For $j = 1 To $cleanupdata[0]
				  If $lastdate Then
					 If $filedate < $lastdate Then
						ConsoleWrite("Deleting Archive : " & $cleanupdata[$j] & @CRLF)
						FileDelete($cleanupdata[$j])
					 EndIf
				  EndIf
			   Next
			EndIf
		 EndIf
	  EndIf
   EndIf
Next