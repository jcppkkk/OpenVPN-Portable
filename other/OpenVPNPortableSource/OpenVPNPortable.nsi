;Copyright (C) 2004-2005 John T. Haller
;Portions Copyright 2007 Lukas Landis

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

!include "LogicLib.nsh"
!include "StrFunc.nsh"
!include "OpenVPNPortable.nsh"
!include "UAC.nsh"

!insertmacro DEFINES "OpenVPNPortable"

!insertmacro PROGRAM_DETAILS

!insertmacro RUNTIME_SWITCHES
WindowIcon Off
SilentInstall Silent

!insertmacro PROGRAM_ICON ${NAME}

Var INIPATH
Var PROGRAMDIRECTORY
Var DRIVERDIRECTORY
Var TAPINSTALL
Var CONFIGDIRECTORY
Var LOGDIRECTORY
Var EXECSTRING
Var EXECBINARY
Var SHOWSPLASH
Var INSTBEHAVIOUR
Var UNINSTBEHAVIOUR
Var AUTOCONNECT

# Call to initialize
${StrLoc}

Section "Main"
	${If} ${UAC_IsInnerInstance}
		# Don't test mutex in inner instance
		Goto Begin
	${EndIf}

    System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${NAME}Mutex") i .r1 ?e'
    Pop $R5
    StrCmp $R5 0 +3
    MessageBox MB_OK|MB_ICONQUESTION|MB_TOPMOST `It appears that ${NAME} is already running.`
    Quit

	Begin:
		IfFileExists "$EXEDIR\${NAME}.ini" "" NoINI
			StrCpy "$INIPATH" "$EXEDIR"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "${APP}Directory"
		StrCpy $PROGRAMDIRECTORY "$EXEDIR\$0"
				
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DriverDirectory"
		StrCpy $DRIVERDIRECTORY "$EXEDIR\$0"
				
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "ConfigDirectory"
		StrCpy $CONFIGDIRECTORY "$EXEDIR\$0"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "LogDirectory"
		StrCpy $LOGDIRECTORY "$EXEDIR\$0"
		
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "ShowSplash"
		StrCpy $SHOWSPLASH "$0"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DriverInstBehaviour"
		StrCpy $INSTBEHAVIOUR "$0"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DriverUnInstBehaviour"
		StrCpy $UNINSTBEHAVIOUR "$0"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "AutoConnect"
		StrCpy $AUTOCONNECT "$0"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "ShowGUI"
		StrCpy $EXECBINARY "$0"
		
		IfErrors NoINI

		IfFileExists "$LOGDIRECTORY\*.*" LogDirExists ""
			CreateDirectory "$LOGDIRECTORY"
			Goto LogDirExists
		
	NoINI:	
		IfFileExists "$EXEDIR\${DEFAULTAPPDIR}\${DEFAULTEXE}" "" NoProgramEXE
			StrCpy $PROGRAMDIRECTORY "$EXEDIR\${DEFAULTAPPDIR}"
			StrCpy $EXECBINARY ${DEFAULTEXE}
				
		IfFileExists "$EXEDIR\${DEFAULTDRVDIR}\win32\${DRIVERFILE}" "" NoDriverFile
			StrCpy $DRIVERDIRECTORY "$EXEDIR\${DEFAULTDRVDIR}"
				
		IfFileExists "$EXEDIR\${DEFAULTCONFIGDIR}\${CONFIGFILE}" "" NoConfigFile
			StrCpy $CONFIGDIRECTORY "$EXEDIR\${DEFAULTCONFIGDIR}"
			
		StrCpy $SHOWSPLASH "true"

		StrCpy $INSTBEHAVIOUR "ask"

		StrCpy $UNINSTBEHAVIOUR "ask"

		StrCpy $AUTOCONNECT "false"
	
		StrCpy $LOGDIRECTORY "$EXEDIR\${DEFAULTLOGDIR}"
		IfFileExists "$EXEDIR\${DEFAULTLOGDIR}\*.*" LogDirExists ""
			CreateDirectory "$EXEDIR\${DEFAULTLOGDIR}"
		
	LogDirExists:
		Call GetParameters
		Pop $0
		StrCmp "'$0'" "''" "" LaunchProgramParameters
		Goto FoundProgramEXE
		
	NoProgramEXE:
		MessageBox MB_OK|MB_ICONEXCLAMATION `$EXEDIR\${DEFAULTAPPDIR}\${DEFAULTEXE} was not found.  Please check your configuration`
		Abort
		
	NoDriverFile:
		MessageBox MB_OK|MB_ICONEXCLAMATION `$EXEDIR\${DEFAULTDRVDIR}\${DRIVERFILE} was not found.  Please check your configuration`
		Abort
		
	NoConfigFile:
		MessageBox MB_OK|MB_ICONEXCLAMATION `You need at least one ${CONFIGFILE} file on $EXEDIR\${DEFAULTCONFIGDIR}\ for a working VPN.  Please check your configuration`
		Abort
		
	FoundProgramEXE:
		${If} $EXECBINARY == ${DEFAULTEXE}
			StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\${DEFAULTEXE}" --config_dir "$CONFIGDIRECTORY" --ext_string "ovpn" --exe_path "$PROGRAMDIRECTORY\openvpn.exe" --log_dir "$LOGDIRECTORY" --priority_string "NORMAL_PRIORITY_CLASS" --append_string "0"`
		${Else}
			StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\${TINYEXE}" --config_dir "$CONFIGDIRECTORY" --exe_path "$PROGRAMDIRECTORY"`
		${EndIf}
		
		Goto AutoConnect
		
	LaunchProgramParameters:
		${If} $EXECBINARY == ${DEFAULTEXE}
			StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\${DEFAULTEXE}" --config_dir "$CONFIGDIRECTORY" --ext_string "ovpn" --exe_path "$PROGRAMDIRECTORY\openvpn.exe" --log_dir "$LOGDIRECTORY" --priority_string "NORMAL_PRIORITY_CLASS" --append_string "0" $0`
		${Else}
			StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\${TINYEXE}" --config_dir "$CONFIGDIRECTORY" --exe_path "$PROGRAMDIRECTORY"`
		${EndIf}
		
	AutoConnect:
		StrCmp $AUTOCONNECT "false" NeedTaps
			; StrCpy $EXECSTRING `$EXECSTRING --connect_to $AUTOCONNECT`
			;MessageBox MB_OK|MB_ICONQUESTION|MB_TOPMOST `$EXECSTRING $AUTOCONNECT`
		${If} $EXECBINARY == ${DEFAULTEXE}
			StrCpy $EXECSTRING `$EXECSTRING --connect $AUTOCONNECT`
		${Else}
			StrCpy $EXECSTRING `$EXECSTRING --connect_to $AUTOCONNECT`
		${EndIf}
		
	NeedTaps:
        
            ; Check if we are running on a 64 bit system.
            System::Call "kernel32::GetCurrentProcess() i .s"
            System::Call "kernel32::IsWow64Process(i s, *i .r0)"
            IntCmp $0 0 Tap-32bit

            StrCpy $TAPINSTALL `${TAPINSTALLEXE64}`
            StrCpy $DRIVERDIRECTORY `$DRIVERDIRECTORY\win64`

            goto SystemcheckEnd

        Tap-32bit:

            StrCpy $TAPINSTALL `${TAPINSTALLEXE32}`
            StrCpy $DRIVERDIRECTORY `$DRIVERDIRECTORY\win32`

        SystemcheckEnd:    
        
            InstDrv::InitDriverSetup /NOUNLOAD "${DRIVERID}" "${DRIVERNAME}"
            InstDrv::CountDevices
            Pop $0
            StrCmp "$0" "0" InstallTaps
			
			${If} ${UAC_IsInnerInstance}
				Goto UninstallTaps
			${Else}
				Goto Launch
			${EndIf}
			
	InstallTaps:
		${If} $INSTBEHAVIOUR == "ask"
		${AndIfNot} ${UAC_IsInnerInstance}
			MessageBox MB_YESNO|MB_ICONQUESTION `Install required virtual network drivers for ${NAME}?` IDNO End
		${EndIf}

		ExecDos::exec `"$PROGRAMDIRECTORY\$TAPINSTALL" install "$DRIVERDIRECTORY\${DRIVERFILE}" ${DRIVERNAME}` ""
		Pop $0
		${If} $0 == "0"
			${If} ${UAC_IsInnerInstance}
			${AndIf} ${UAC_IsAdmin}
				!insertmacro UAC_AsUser_Call Label Launch ${UAC_SYNCREGISTERS}|${UAC_SYNCOUTDIR}|${UAC_SYNCINSTDIR}
				Goto End
			${Else}
				Goto Launch
			${EndIf}
		${EndIf}
		
		${If} ${UAC_IsInnerInstance}
		${AndIfNot} ${UAC_IsAdmin}
			MessageBox MB_OK|MB_ICONEXCLAMATION `Error by installing virtual network drivers. Please start this app as a user with admin rights.`
			Goto End
		${EndIf}
		
		!insertmacro UAC_RunElevated
		Goto End
		
	Launch:
		${If} $SHOWSPLASH == "true"
			File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"
			newadvsplash::show /NOUNLOAD 2000 400 400 -1 /NOCANCEL $PLUGINSDIR\splash.jpg
		${EndIf}
	
		ExecWait $EXECSTRING
		;INSERT HERE new command
		
		${If} $UNINSTBEHAVIOUR == "ask"
			MessageBox MB_YESNO|MB_ICONQUESTION `Uninstall ${NAME} virtual network drivers?` IDNO End
		${ElseIf} $UNINSTBEHAVIOUR == "false"
			Goto End
		${EndIf}
		
	UninstallTaps:
		Push "ExecDos::End" # Add a marker for the loop to test for.
		ExecDos::exec /TOSTACK `"$PROGRAMDIRECTORY\$TAPINSTALL" remove ${DRIVERNAME}` ""  ;uninstall
		Pop $0
		${If} $0 != "0" ;If we got an error...
			Goto UninstallFailed
		${ElseIF} $0 == "0" ;If it was successfully uninstalled...## Loop through stack.
			Loop:
				Pop $1
				StrCmp $1 "ExecDos::End" ExitLoop
				${StrLoc} $0 "$1" "failed" "<"
				${IfNotThen} $0 == "" ${|} Goto UninstallFailed ${|}
				Goto Loop
			ExitLoop:
			
			MessageBox MB_OK `${NAME} virtual network drivers were successfully uninstalled`
			Goto End
		${EndIf}
		
	UninstallFailed:
		${If} ${UAC_IsInnerInstance}
		${AndIfNot} ${UAC_IsAdmin}
			MessageBox MB_OK|MB_ICONEXCLAMATION `Error by uninstalling virtual network drivers. Please start this app as a user with admin rights.`
			Goto End
		${EndIf}
	
		!insertmacro UAC_RunElevated
		Goto End
		
	End:
		newadvsplash::stop /WAIT
		Sleep 2000
SectionEnd

Function GetParameters
	; GetParameters
	; input, none
	; output, top of stack (replaces, with e.g. whatever)
	; modifies no other variables. 

	Push $R0
	Push $R1
	Push $R2
	Push $R3

	StrCpy $R2 1
	StrLen $R3 $CMDLINE

	;Check for quote or space
	StrCpy $R0 $CMDLINE $R2
	StrCmp $R0 '"' 0 +3
		StrCpy $R1 '"'
		Goto loop
	StrCpy $R1 " "

	loop:
		IntOp $R2 $R2 + 1
		StrCpy $R0 $CMDLINE 1 $R2
		StrCmp $R0 $R1 get
		StrCmp $R2 $R3 get
		Goto loop
  
	get:
		IntOp $R2 $R2 + 1
		StrCpy $R0 $CMDLINE 1 $R2
		StrCmp $R0 " " get
		StrCpy $R0 $CMDLINE "" $R2

	Pop $R3
	Pop $R2
	Pop $R1
	Exch $R0
FunctionEnd
