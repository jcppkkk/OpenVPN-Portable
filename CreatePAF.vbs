
Option Explicit

Dim WSHShell, fso, oArgs
Dim root, target, version, nversion, upx, reshack, directory, fileList, file
Dim line, FileIn, FileOut, vsettings, ges_file, tempdir, temp, sevenzip, nsis
'Dim Datei, Text, Txt, i, arrSort, arrTest(), oArgs

Set WSHShell = WScript.CreateObject("WScript.Shell") 
Set fso      = WScript.CreateObject("Scripting.FileSystemObject") 
set oArgs    = Wscript.Arguments
'Set WSHShell = WScript.CreateObject("WScript.Shell")
'Set fso      = WScript.CreateObject("Scripting.FileSystemObject")

'root="c:\vss\projektmappe_landis\scr_firmware"
root=fso.GetFolder(".")
'target="K:\ET\SCR1\SCR_FIRMWARE"
'version="0.2.0"
sevenzip="c:\Program Files\7-Zip\7z.exe"
reshack="c:\ResHacker\ResHacker.exe"
directory="OpenVPNPortable"
nsis="c:\Program Files\nsis\makensis.exe"

'Load settings
If fso.FileExists( root & "\settings" ) then
	Set FileIn   = fso.OpenTextFile( root & "\settings" , 1, true)
	Do While Not ( FileIn.atEndOfStream )
	    ' wenn Datei nicht zu Ende ist, weiter machen
		line = FileIn.Readline
		
		vsettings = Split( line, "=" )
		
		'If vsettings(0) = "version" then version=vsettings(1)
		If vsettings(0) = "sevenzip" then sevenzip=vsettings(1)
		If vsettings(0) = "reshack" then reshack=vsettings(1)
		If vsettings(0) = "nsis" then nsis=vsettings(1)
		If vsettings(0) = "directory" then directory=vsettings(1)
	Loop

FileIn.Close
Set FileIn = nothing
End If

If not fso.FileExists(sevenzip) then sevenzip = InputBox("7z.exe (Please full path incl. file)?")
'If not fso.FileExists(reshack) then reshack = InputBox("reshack.exe (Please full path incl. file)?")
If not fso.FileExists(nsis) then nsis = InputBox("makensis.exe (Please full path incl. file)?")

'*******************************************************************************************************
'nversion = InputBox("Version (Nothing is equal to " & version & ").")
'If not nversion = "" then version = nversion

'ges_file=directory & "_" & version & ".paf.exe"
'*******************************************************************************************************

'WSHShell.Run "mkdir %TEMP%\" & directory, , true
temp=WshShell.ExpandEnvironmentStrings("%TEMP%")
tempdir= temp & "\" & directory

delFolderIfExists tempdir
fso.CreateFolder tempdir
fso.CreateFolder tempdir & "\app"
fso.CreateFolder tempdir & "\app\AppInfo"
fso.CreateFolder tempdir & "\app\bin"
'fso.CreateFolder tempdir & "\app\driver"
'fso.CreateFolder tempdir & "\app\driver\win32"
'fso.CreateFolder tempdir & "\app\driver\win64"
fso.CreateFolder tempdir & "\data"
fso.CreateFolder tempdir & "\data\config"
fso.CreateFolder tempdir & "\data\log"
fso.CreateFolder tempdir & "\other"
fso.CreateFolder tempdir & "\other\openvpn-gui-source"
fso.CreateFolder tempdir & "\other\OpenVPNPortableSource"
fso.CreateFolder tempdir & "\other\TinyOpenVPNGuiNSIS"

fso.CopyFile root & "\app\AppInfo\*.*", tempdir & "\app\AppInfo\", true

fso.CopyFile root & "\app\bin\*.*", tempdir & "\app\bin\", true
'fso.CopyFile root & "\app\driver\win32\*.*", tempdir & "\app\driver\win32\", true
'fso.CopyFile root & "\app\driver\win64\*.*", tempdir & "\app\driver\win64\", true
'fso.CopyFile root & "\data\config\*.*", tempdir & "\data\config\", true
fso.CopyFile root & "\other\openvpn-gui-source\*.*", tempdir & "\other\openvpn-gui-source\", true
fso.CopyFile root & "\other\OpenVPNPortableSource\*.*", tempdir & "\other\OpenVPNPortableSource\", true
fso.CopyFile root & "\other\TinyOpenVPNGuiNSIS\*.*", tempdir & "\other\TinyOpenVPNGuiNSIS\", true
fso.CopyFile root & "\other\OpenVPNPortableSource\OpenVPNPortable.ini", tempdir & "\", true
fso.CopyFile root & "\README.md", tempdir & "\", true

delFileIfExists tempdir & "\other\openvpn-gui-source\*.o"
delFileIfExists tempdir & "\other\openvpn-gui-source\*.exe"
delFileIfExists tempdir & "\other\openvpn-gui-source\*.res"
delFileIfExists tempdir & "\other\OpenVPNPortableSource\*.exe"
delFileIfExists tempdir & "\other\TinyOpenVPNGuiNSIS\*.exe"

'*******************************************************************************************************
'delFileIfExists temp & "\" & ges_file

'If fso.FileExists(sevenzip) then
'	WSHShell.Run """" & sevenzip & """ a -aoa -sfx7z.sfx -r """ & temp & "\" & ges_file & """ """ & tempdir & """", , true
'Else
'	MsgBox "File """ & sevenzip & """ does not exist. Script ends"
'	WScript.Quit
'End If

'If fso.FileExists(reshack) then
'	WSHShell.Run """" & reshack & """ -addoverwrite """ & temp & "\" & ges_file & """, """ & root & "\" & ges_file & """, """ & root & "\other\OpenVPNPortableSource\OpenVPNPortable.ico"", icon, 1, 1033", , true
'Else
'	MsgBox("File """ & reshack & """ does not exist. Script ends")
'	WScript.Quit
'End If
'*******************************************************************************************************

If fso.FileExists(nsis) then
'	MsgBox """" & nsis & """ /NOCD """ & tempdir & "\other\OpenVPNPortableSource\Installer.nsi"""
	WSHShell.Run """" & nsis & """ """ & tempdir & "\other\OpenVPNPortableSource\OpenVPNPortable.nsi""", , true
	fso.CopyFile tempdir & "\other\OpenVPNPortableSource\OpenVPNPortable.exe", tempdir & "\", true
    fso.DeleteFile tempdir & "\other\OpenVPNPortableSource\*.exe", true
    
	WSHShell.Run """" & nsis & """ """ & tempdir & "\other\TinyOpenVPNGuiNSIS\TinyOpenVPNGui.nsi""", , true
	fso.CopyFile tempdir & "\other\TinyOpenVPNGuiNSIS\TinyOpenVPNGui.exe", tempdir & "\app\bin\", true
    fso.DeleteFile tempdir & "\other\TinyOpenVPNGuiNSIS\*.exe", true

	WSHShell.Run """" & nsis & """ """ & tempdir & "\other\OpenVPNPortableSource\Installer.nsi""", , true
	fso.CopyFile tempdir & "\other\OpenVPNPortableSource\*.paf.exe", root & "\", true
    fso.DeleteFile tempdir & "\other\OpenVPNPortableSource\*.exe", true
Else
	MsgBox("File """ & nsis & """ does not exist. Script ends")
	WScript.Quit
End If

'Save settings
Set FileOut = fso.CreateTextFile(root & "\settings", true)
'FileOut.WriteLine( "version=" & version )
FileOut.WriteLine( "sevenzip=" & sevenzip )
FileOut.WriteLine( "reshack=" & reshack )
FileOut.WriteLine( "nsis=" & nsis )
FileOut.WriteLine( "directory=" & directory )
FileOut.Close
Set FileOut = nothing

MsgBox "Script successful finished"

WScript.Quit

Sub delFolderIfExists(folder)
	If fso.FolderExists(folder) then 
        fso.DeleteFolder folder, true
    End If
End Sub

Sub delFileIfExists(file)
	If fso.FileExists(file) then
        MsgBox(file & "exists -> delete file")
        fso.DeleteFile file, true
    End If
End Sub
