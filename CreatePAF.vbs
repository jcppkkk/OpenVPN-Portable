
Option Explicit

Dim WSHShell, fso, oArgs
Dim root, target, directory, fileList, file
Dim line, FileIn, FileOut, vsettings, tempdir, temp, nsis

Set WSHShell = WScript.CreateObject("WScript.Shell") 
Set fso      = WScript.CreateObject("Scripting.FileSystemObject") 
set oArgs    = Wscript.Arguments

root=fso.GetFolder(".")
reshack="c:\ResHacker\ResHacker.exe"
directory="OpenVPNPortable"
nsis="C:\Program Files (x86)\NSIS\Unicode\makensis.exe"

'Load settings
If fso.FileExists( root & "\settings" ) then
	Set FileIn   = fso.OpenTextFile( root & "\settings" , 1, true)
	Do While Not ( FileIn.atEndOfStream )
	    ' wenn Datei nicht zu Ende ist, weiter machen
		line = FileIn.Readline
		
		vsettings = Split( line, "=" )
		
		If vsettings(0) = "reshack" then reshack=vsettings(1)
		If vsettings(0) = "nsis" then nsis=vsettings(1)
		If vsettings(0) = "directory" then directory=vsettings(1)
	Loop

FileIn.Close
Set FileIn = nothing
End If

If not fso.FileExists(nsis) then nsis = InputBox("makensis.exe (Please full path incl. file)?")

'Save settings
Set FileOut = fso.CreateTextFile(root & "\settings", true)
FileOut.WriteLine( "nsis=" & nsis )
FileOut.WriteLine( "directory=" & directory )
FileOut.Close
Set FileOut = nothing


temp=WshShell.ExpandEnvironmentStrings("%TEMP%")
tempdir= temp & "\" & directory

delFolderIfExists tempdir
fso.CreateFolder tempdir
fso.CreateFolder tempdir & "\app"
fso.CreateFolder tempdir & "\app\AppInfo"
fso.CreateFolder tempdir & "\app\bin"
fso.CreateFolder tempdir & "\data"
fso.CreateFolder tempdir & "\data\config"
fso.CreateFolder tempdir & "\data\log"
fso.CreateFolder tempdir & "\other"
fso.CreateFolder tempdir & "\other\openvpn-gui-source"
fso.CreateFolder tempdir & "\other\OpenVPNPortableSource"
fso.CreateFolder tempdir & "\other\TinyOpenVPNGuiNSIS"

fso.CopyFile root & "\app\AppInfo\*.*", tempdir & "\app\AppInfo\", true

fso.CopyFile root & "\app\bin\*.*", tempdir & "\app\bin\", true
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
