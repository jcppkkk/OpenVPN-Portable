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

!insertmacro DEFINES "InstallDriver"

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
			
			Goto End
			
	InstallTaps:
		${If} $INSTBEHAVIOUR == "ask"
		${AndIfNot} ${UAC_IsInnerInstance}
			MessageBox MB_YESNO|MB_ICONQUESTION `Install required virtual network drivers for ${NAME}?` IDNO End
		${EndIf}

		ExecDos::exec `"$PROGRAMDIRECTORY\$TAPINSTALL" install "$DRIVERDIRECTORY\${DRIVERFILE}" ${DRIVERNAME}` ""
		Pop $0
		${If} $0 == "0"
			Goto End
		${EndIf}
		
		${If} ${UAC_IsInnerInstance}
		${AndIfNot} ${UAC_IsAdmin}
			MessageBox MB_OK|MB_ICONEXCLAMATION `Error by installing virtual network drivers. Please start this app as a user with admin rights.`
			Goto End
		${EndIf}
		
		!insertmacro UAC_RunElevated
		
	End:
SectionEnd
