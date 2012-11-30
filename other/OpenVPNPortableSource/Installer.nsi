;Copyright 2007 John T. Haller

;Website: http://PortableApps.com/

;This software is OSI Certified Open Source Software.
;OSI Certified is a certification mark of the Open Source Initiative.

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

;EXCEPTION: Can be used with non-GPLed open source apps distributed by PortableApps.com

!define NAME "OpenVPN Portable"
!define SHORTNAME "OpenVPNPortable"
!define VERSION "1.8.2.0"
!define FILENAME "OpenVPNPortable_1.8.2"
!define CHECKRUNNING "openvpn-gui.exe"
!define CLOSENAME "OpenVPN"

;=== Program Details
Name "${NAME}"
OutFile "${FILENAME}.paf.exe"
InstallDir "\${SHORTNAME}"
Caption "${NAME} | PortableApps.com Installer"
VIProductVersion "${VERSION}"
VIAddVersionKey ProductName "${NAME}"
VIAddVersionKey Comments "For additional details, visit PortableApps.com"
;VIAddVersionKey CompanyName "PortableApps.com"
VIAddVersionKey LegalCopyright "Lukas Landis and contributors"
VIAddVersionKey FileDescription "${NAME}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey InternalName "${NAME}"
;VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${FILENAME}.paf.exe"
;VIAddVersionKey PrivateBuild ""
;VIAddVersionKey SpecialBuild ""
BrandingText "OpenVPN Portable - Your private network, Anywhere™"

;=== Runtime Switches
;SetDatablockOptimize on
;SetCompress off
SetCompressor /SOLID lzma
CRCCheck on
AutoCloseWindow True
RequestExecutionLevel user

;=== Include
!include MUI.nsh
!include FileFunc.nsh
!include ZipDLL.nsh

!insertmacro GetOptions
!insertmacro GetDrives

;=== Program Icon
Icon "${SHORTNAME}.ico"

# MUI defines
!define MUI_ICON "${SHORTNAME}.ico"
!define MUI_WELCOMEPAGE_TITLE "${NAME}"
!define MUI_WELCOMEPAGE_TEXT "$(welcome)"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE CheckForRunningApp
;!define MUI_LICENSEPAGE_RADIOBUTTONS
!define MUI_FINISHPAGE_TEXT "$(finish)"

;=== Pages and their order
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

;=== Languages
!insertmacro MUI_LANGUAGE "English"

LangString welcome ${LANG_ENGLISH} "This wizard will guide you through the installation of ${NAME}.\r\n\r\nIf you are upgrading an existing installation of ${NAME}, please close it before proceeding.\r\n\r\nClick Next to continue."
LangString finish ${LANG_ENGLISH} "${NAME} has been installed on your device.\r\n\r\nClick Finish to close this wizard."
LangString runwarning ${LANG_ENGLISH} "Please close all instances of ${CLOSENAME} and then click OK.  The portable app can not be upgraded while it is running."

;=== Variables
Var FOUNDPORTABLEAPPSPATH
Var BINPACKURL

Function .onInit
	;StrCpy $FOUNDPORTABLEAPPSPATH ''

	${GetOptions} "$CMDLINE" "/DESTINATION=" $R0

	IfErrors CheckLegacyDestination
		StrCpy $INSTDIR "$R0${SHORTNAME}"
		Goto CheckUrlOption

	CheckLegacyDestination:
		ClearErrors
		${GetOptions} "$CMDLINE" "-o" $R0
		IfErrors NoDestination
			StrCpy $INSTDIR "$R0${SHORTNAME}"
			Goto CheckUrlOption

	NoDestination:
		ClearErrors
		${GetDrives} "HDD+FDD" GetDrivesCallBack
		StrCmp $FOUNDPORTABLEAPPSPATH "" DefaultDestination
			StrCpy $INSTDIR "$FOUNDPORTABLEAPPSPATH\${SHORTNAME}"
			Goto CheckUrlOption
		
	DefaultDestination:
		StrCpy $INSTDIR "$EXEDIR\${SHORTNAME}"

	CheckUrlOption:
		${GetOptions} "$CMDLINE" "/BINPACKURL=" $R0

	IfErrors CheckSecondUrlOption
		StrCpy $BINPACKURL "$R0"
		Goto InitDone
		
	CheckSecondUrlOption:
		ClearErrors
		${GetOptions} "$CMDLINE" "url" $R0

	IfErrors DefaultUrl
		StrCpy $BINPACKURL "$R0"
		Goto InitDone
		
	DefaultUrl:
		ClearErrors
		StrCpy $BINPACKURL "http://iweb.dl.sourceforge.net/project/ovpnp/binpack"
	
	InitDone:
FunctionEnd

Function GetDrivesCallBack
	;=== Skip usual floppy letters
	StrCmp $8 "FDD" "" CheckForPortableAppsPath
	StrCmp $9 "A:\" End
	StrCmp $9 "B:\" End
	
	CheckForPortableAppsPath:
		IfFileExists "$9PortableApps" "" End
			StrCpy $FOUNDPORTABLEAPPSPATH "$9PortableApps"

	End:
		Push $0
FunctionEnd

Function CheckForRunningApp
	;=== Does it already exist? (upgrade)
	IfFileExists "$INSTDIR" "" End
		;=== Check if app is running?
		StrCmp ${CHECKRUNNING} "" End
			;=== Is it running?
			CheckRunning:
				FindProcDLL::FindProc "${CHECKRUNNING}"
				StrCmp $R0 "1" "" End
					MessageBox MB_OK|MB_ICONINFORMATION `$(runwarning)`
					Goto CheckRunning
	
	End:
FunctionEnd

Section "!App Portable (required)"
	SetOutPath $INSTDIR
	File /r "..\..\*.*"
	
	StrCmp "$BINPACKURL" "." CopyCurrent
		StrCpy $2 "$BINPACKURL/current.txt"
		
		;get the latest version of the package.
		inetc::get /SILENT "$2" "$TEMP\new.txt" /END
		Pop $R0 ;Get the return value
			StrCmp $R0 "OK" 0 DownloadFailed
			Goto ReadFile
	
	CopyCurrent:
		StrCpy $2 "$EXEDIR/current.txt"
		CopyFiles "$2" "$TEMP/new.txt"
		IfErrors DownloadFailed
			
	ReadFile:
		FileOpen $0 "$TEMP\new.txt" r
		FileRead $0 $1
		FileClose $0
		Delete /REBOOTOK "$TEMP\new.txt"
	
	StrCpy $2 "0.0.0"
	
	IfFileExists "$INSTDIR\current.txt" 0 Compare
		FileOpen $0 "$INSTDIR\current.txt" r
		FileRead $0 $2
		FileClose $0
	
	Compare:
		StrCmp "$1" "$2" End 0
	
	StrCmp "$BINPACKURL" "." CopyBinpack
		StrCpy $2 "$BINPACKURL/$1.zip"
		
		;Download the package.
		inetc::get /POPUP "" /CAPTION "Get latest openvpn binaries..." $2 "$TEMP\current.zip" /END
		Pop $R0 ;Get the return value
			StrCmp $R0 "OK" Extract DownloadFailed
				
	CopyBinpack:
		StrCpy $2 "$EXEDIR/$1.zip"
		CopyFiles "$2" "$TEMP\current.zip"
		IfErrors DownloadFailed
		
	Extract:
		nsUnzip::Extract "/d=$INSTDIR" /u "$TEMP\current.zip" /END
		Delete /REBOOTOK "$TEMP\current.zip"
		
		FileOpen $0 $INSTDIR\current.txt w
		FileWrite $0 $1
		FileClose $0
		
		Goto End
	
	DownloadFailed:
		MessageBox MB_OK|MB_ICONSTOP "Unable to download file $2 ($R0)"
	
	End:
SectionEnd