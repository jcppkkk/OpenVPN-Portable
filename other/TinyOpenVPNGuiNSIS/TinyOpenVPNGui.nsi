;Copyright (C) 2009 Lukas Landis
;
;
;


;---------------------
;includes
!include "MUI.nsh"
;!include "WinMessages.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "..\OpenVPNPortableSource\OpenVPNPortable.nsh"
!include "WordFunc.nsh"
!include "StrFunc.nsh"
	${StrStr}
	${StrLoc}
	;${StrRep}
	${StrIOToNSIS}
;!insertmacro WordFind

;----------------------
;Defines
!insertmacro DEFINES "OpenVPNPortableGui"
!define OPENVPNEXE "openvpn.exe"
!insertmacro PROGRAM_DETAILS
!insertmacro RUNTIME_SWITCHES
!insertmacro PROGRAM_ICON "OpenVPNPortable"

!define SYNC_TERM 0x00100001
!define TO_MS 2000

!define EM_GETSELTEXT 1086

!define CONNECTED_ICO "connected.ico"
!define CONNECTING_ICO "connecting.ico"
!define RECONNECTING_ICO "reconnecting.ico"
!define DISCONNECTED_ICO "disconnected.ico"


;----------------------
;MUI defines
;!define MUI_CUSTOMFUNCTION_GUIINIT myGuInit


;--------------------------------
;General

;Name and file
;OutFile "..\..\OpenVPNPortable\app\bin\TinyOpenVPNGui.exe"
OutFile "TinyOpenVPNGui.exe"

;Default installation folder
;InstallDir "$EXEDIR\..\..\"

CRCCheck On
;WindowIcon Off
;SilentInstall Silent
AutoCloseWindow True
SetCompressor /SOLID LZMA

;Get installation folder from registry if available

;--------------------------------
;Pages

Page custom InitPage LeavePage

;--------------------------------
;Interface Settings

;!define MUI_ABORTWARNING
!define MUI_CUSTOMFUNCTION_ABORT AbortPage


;--------------------------------
;Languages
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Reserve Files

;If you are using solid compression, files that are required before
;the actual installation should be stored first in the data block,
;because this will make your installer start faster.

ReserveFile "TinyOpenVPNGui.ini"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;--------------------------------
;Variables
Var tmp
Var tmpHnd
Var searchHnd
Var findFile
Var configFiles
Var selectedConnection
Var connected
Var tmpOVPNLine

Var configDirectory
Var programDirectory
Var autoConnect

LangString termMsg ${LANG_ENGLISH} "Installer cannot stop running Thread.$\nDo you want to terminate process?"
LangString stopMsg ${LANG_ENGLISH} "Stopping Thread"

;--------------------------------
;Installer Sections

Section "Dummy Section" SecDummy

;SetOutPath "$INSTDIR"

;ADD YOUR OWN FILES HERE...

;Store installation folder

SectionEnd

;--------------------------------
;User defined Macros
!macro ADDCONFIGFILE CFILE
	!insertmacro MUI_INSTALLOPTIONS_READ $tmp "tinyGui" "Field 1" "ListItems"
	
	${If} $tmp == ""
		!insertmacro MUI_INSTALLOPTIONS_WRITE "tinyGui" "Field 1" "ListItems" ${CFILE}
		StrCpy $configFiles ", ${CFILE}"
		;MessageBox MB_OK `Add ${CFILE} to ListItems`
	${Else}
		!insertmacro MUI_INSTALLOPTIONS_WRITE "tinyGui" "Field 1" "ListItems" "$tmp|${CFILE}"
		StrCpy $configFiles "$configFiles, ${CFILE}"
		;MessageBox MB_OK `Add "$tmp|${CFILE}" to ListItems`
	${EndIf}
!macroend

!macro ADDTEXT VALUE
	Push $R0
	Push $R1
	Push $R2

	!insertmacro MUI_INSTALLOPTIONS_READ $tmpHnd "tinyGui" "Field 3" "HWND"
	
	${StrIOToNSIS} $R0 "${VALUE}\r\n"
	;	MessageBox MB_OK `$R0`
	SendMessage $tmpHnd ${EM_SETSEL} "-1" 0
	SendMessage $tmpHnd ${EM_REPLACESEL} 0 "STR:$R0"
	
	Pop $R2
	Pop $R1
	Pop $R0
!macroend

!macro CHANGETEXTFIELD ELEMENT VALUE
	Push $R0
	!insertmacro MUI_INSTALLOPTIONS_WRITE "tinyGui" "${ELEMENT}" "State" ${VALUE}
	!insertmacro MUI_INSTALLOPTIONS_READ $tmpHnd "tinyGui" "${ELEMENT}" "HWND"
	${StrIOToNSIS} $R0 ${VALUE}
	SendMessage $tmpHnd ${WM_SETTEXT} 0 "STR:$R0"
	Pop $R0
!macroend

!macro CLEARTEXTFIELD ELEMENT
	!insertmacro MUI_INSTALLOPTIONS_WRITE "tinyGui" "${ELEMENT}" "State" ""
	!insertmacro MUI_INSTALLOPTIONS_READ $tmpHnd "tinyGui" "${ELEMENT}" "HWND"
	SendMessage $tmpHnd ${WM_SETTEXT} 0 "STR:"
!macroend

!macro TERMINATEAPP HWND
 
	Push $0 ; window handle
	Push $1
	Push $2 ; process handle
	Push $3 ; event handle
	
	StrCpy $0 ${HWND}
	IntCmp $0 0 done
	
	StrCpy $connected ""

	;create and send Event
	System::Call 'kernel32.dll::CreateEvent(i .0, i 1, i 0, t "termConn") i .r3'
	System::Call 'kernel32.dll::SetEvent(i r3) i .r1'
	
	System::Call 'kernel32.dll::CloseHandle(i r3) i .r1'

	done:
	
	Sleep 200
	
	Pop $3
	Pop $2
	Pop $1
	Pop $0
 
!macroend

!macro ChangeNotifyIconState iconFile baloon
	NotifyIcon::Icon "r"

	${If} "${baloon}" != 0
		NotifyIcon::Icon /NOUNLOAD "a!zft" "$PLUGINSDIR\${iconFile}" "${baloon}"
	${Else}
		NotifyIcon::Icon /NOUNLOAD "a!zf" "$PLUGINSDIR\${iconFile}"
	${EndIf}
!macroend
	
!macro CONNECT
			
	${If} $selectedConnection == ""
		MessageBox MB_OK|MB_ICONQUESTION|MB_TOPMOST `You have to select a configuration file.`
	${Else}
		
		GetFunctionAddress $R0 "EvalOutput"
		
		StrCpy $R5 '"$programDirectory\${OPENVPNEXE}"'
		StrCpy $R5 '$R5 --service "termConn"'
		StrCpy $R5 '$R5 --config "$configDirectory\$selectedConnection"'
		ExecDos::exec /NOUNLOAD /ASYNC /TOFUNC /TOENDFUNC=$R0 $R5 "" $R0
		
		Sleep 1500

		Push "."
		Push "openvpn.exe"
		
		Call EnhancedFindWindow
		
		Pop $R1
		Pop $R0
		
		StrCpy $connected $R0
		
		;Sleep 1500
	${EndIf}		
!macroend

;--------------------------------
;Installer Functions

LangString USERPASS_TITLE ${LANG_ENGLISH} "Choice your Config file to connect."
LangString USERPASS_SUBTITLE ${LANG_ENGLISH} " "

Function .onInit
	Push $0
	Push $1

	!insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "TinyOpenVPNGui.ini" "tinyGui"
	
	IfErrors 0 +2
	Abort

	File /oname=$PLUGINSDIR\${CONNECTED_ICO} ${CONNECTED_ICO}
	File /oname=$PLUGINSDIR\${DISCONNECTED_ICO} ${DISCONNECTED_ICO}
	
	!insertmacro ChangeNotifyIconState ${DISCONNECTED_ICO} 0
	
	${GetParameters} $0
	
	#MessageBox MB_OK `parameters: $0`
	
	${GetOptions} $0 "--config_dir"  $1
	IfErrors 0 +2
	StrCpy $configDirectory "$INSTDIR\${DEFAULTCONFIGDIR}"
	StrCpy $configDirectory "$1"

	${GetOptions} $0 "--exe_path"  $1
	IfErrors 0 +2
	StrCpy $programDirectory "$INSTDIR\${DEFAULTAPPDIR}"
	StrCpy $programDirectory "$1"

	${GetOptions} $0 "--connect_to"  $1
	IfErrors 0 +2
	StrCpy $autoConnect ""
	StrCpy $autoConnect "$1"

	FindFirst $SearchHnd $findFile "$ConfigDirectory\${CONFIGFILE}"
	${While} $findFile != ""
		!insertmacro ADDCONFIGFILE $findFile
		FindNext $SearchHnd $findFile
	${EndWhile}
	FindClose $SearchHnd
	
	SetOutPath "$ConfigDirectory"
	
	Pop $1
	Pop $0

FunctionEnd

;--------------------------------
;CUSTOM PAGE Functions
Function InitPage
	!insertmacro MUI_HEADER_TEXT "$(USERPASS_TITLE)" "$(USERPASS_SUBTITLE)"

	#MessageBox MB_OK `Display Page`
	Call EnterPage
	
	# Display the page.
	!insertmacro MUI_INSTALLOPTIONS_DISPLAY "tinyGui"
	
FunctionEnd

Function EnterPage
;Function myGuInit   
	${If} $autoConnect != ""
		;Sleep 1000
		StrCpy $selectedConnection $autoConnect
		!insertmacro CONNECT
	${EndIf}	
 FunctionEnd

Function LeavePage
	; handle notify event of element
	!insertmacro MUI_INSTALLOPTIONS_READ $tmp "tinyGui" "Settings" "State"

	${Switch} $tmp
	${Case} 2
		${If} $connected == ""
		
			!insertmacro CLEARTEXTFIELD "Field 3"
			!insertmacro CONNECT
			!insertmacro CHANGETEXTFIELD "Field 2" "Disconnect"
			
		${Else}
				
			!insertmacro TERMINATEAPP $connected
			
			!insertmacro CHANGETEXTFIELD "Field 2" "Connect"
			
			!insertmacro CLEARTEXTFIELD "Field 3"
			
		${EndIf}
		
		${Break}
	${Case} 1
		
		Call GetSelectedCFile
		Pop $selectedConnection
		
		${Break}
	${Case} 0
	
		ShowWindow $HWNDPARENT ${SW_MINIMIZE}
		${Break}
	${Default}
	
		 MessageBox MB_OK|MB_ICONQUESTION|MB_TOPMOST `State: $tmp.`
	${EndSwitch}

	${If} $connected == ""
		!insertmacro ChangeNotifyIconState ${DISCONNECTED_ICO} 0
	${EndIf}

	Abort
FunctionEnd

;--------------------------------
;User Defined Functions
Function GetSelectedCFile
	Push $R0
	Push $R1
	
	!insertmacro MUI_INSTALLOPTIONS_READ $tmp "tinyGui" "Field 1" "HWND"
	SendMessage $tmp ${LB_GETCURSEL} 0 0 $R1
	
	${If} $R1 == "-1"
		StrCpy $R0 ""
	${Else}
		IntOp $R1 $R1 + 1
		${WordFind} $configFiles ", " "+0$R1" $R0
	${EndIf}
	

	Pop $R1
	Exch $R0
FunctionEnd

Function EvalOutput
	Pop $tmpOVPNLine
	Push $0
	
	${If} $autoConnect != ""
		Sleep 2000
		StrCpy $autoConnect ""
		!insertmacro CHANGETEXTFIELD "Field 2" "Disconnect"
	${EndIf}
	
	${If} $connected != ""
	
		!insertmacro ADDTEXT $tmpOVPNLine
		
		${StrLoc} $0 $tmpOVPNLine "Initialization Sequence Completed" "<"
		${If} $0 != ""
			!insertmacro ChangeNotifyIconState ${CONNECTED_ICO} "Connected to $selectedConnection"
			ShowWindow $HWNDPARENT ${SW_MINIMIZE}
		${EndIf}
		
	${EndIf}
	
	Sleep 10
	
	Pop $0
FunctionEnd

Function AbortPage

	!insertmacro TERMINATEAPP $connected
	
FunctionEnd

Function  EnhancedFindWindow
	; input, save variables
	Exch  $0   # part of the class name to search for
	Exch
	Exch  $1   # starting offset
	Push  $2   # length of $0
	Push  $3   # window handle
	Push  $4   # class name
	Push  $5   # temp
	Push  $6   # temp2
	
	; set up the variables
	StrCpy  $4  0
	StrCpy  $5  ""
	
	${Do}
		FindWindow $3 "" "" 0 $3
		IsWindow  $3  +2  0
			${Continue}
			
		${If}  $3 == 0  
			${Break}
		${EndIf}
		
		System::Call 'user32.dll::GetWindowText(i r3, t .r4, i ${NSIS_MAX_STRLEN}) i .n'
		System::Call 'kernel32.dll::GetProcessId(i r3) i r6'
		${If}  $4 == ""  
			${Continue}
		${Else}
			${StrStr} $5 $4 $0
			
			${If} $5 != ""
				${Break}
			${EndIf}
		${EndIf}
	${Loop}
	
	StrCpy  $1  $3
	StrCpy  $0  $4
	
	Pop  $6
	Pop  $5
	Pop  $4
	Pop  $3
	Pop  $2
	Exch  $1
	Exch
	Exch  $0
FunctionEnd

