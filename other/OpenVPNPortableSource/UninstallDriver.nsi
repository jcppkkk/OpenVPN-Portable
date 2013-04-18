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
!include "InstallDriver.nsh"
!include "UAC.nsh"

!insertmacro DEFINES "UninstallDriver"

!insertmacro PROGRAM_DETAILS

!insertmacro RUNTIME_SWITCHES
WindowIcon Off
SilentInstall Silent

!insertmacro PROGRAM_ICON ${NAME}

Var INIPATH
Var PROGRAMDIRECTORY
Var DRIVERDIRECTORY
Var TAPINSTALL
Var INSTBEHAVIOUR

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

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "ProgramDirectory"
		StrCpy $PROGRAMDIRECTORY "$EXEDIR\$0"
				
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DriverDirectory"
		StrCpy $DRIVERDIRECTORY "$EXEDIR\$0"

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DriverInstBehaviour"
		StrCpy $INSTBEHAVIOUR "$0"
		
		IfErrors NoINI
		
		Goto NeedTaps
		
	NoINI:	
		IfFileExists "$EXEDIR\${DEFAULTAPPDIR}\${TAPINSTALLEXE32}" "" NoProgramEXE
			StrCpy $PROGRAMDIRECTORY "$EXEDIR\${DEFAULTAPPDIR}"
				
		IfFileExists "$EXEDIR\${DEFAULTDRVDIR}\win32\${DRIVERFILE}" "" NoDriverFile
			StrCpy $DRIVERDIRECTORY "$EXEDIR\${DEFAULTDRVDIR}"

		StrCpy $INSTBEHAVIOUR "ask"
		
		Goto NeedTaps
		
	NoProgramEXE:
		MessageBox MB_OK|MB_ICONEXCLAMATION `$EXEDIR\${DEFAULTAPPDIR}\${TAPINSTALLEXE32} was not found.  Please check your configuration`
		Abort
		
	NoDriverFile:
		MessageBox MB_OK|MB_ICONEXCLAMATION `$EXEDIR\${DEFAULTDRVDIR}\${DRIVERFILE} was not found.  Please check your configuration`
		Abort
		
		
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
SectionEnd
