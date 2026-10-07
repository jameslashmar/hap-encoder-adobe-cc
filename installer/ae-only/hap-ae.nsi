; Windows installer for the HAP After Effects output module only (no Premiere / AME exporter).
; Build:  makensis /DVERSION=1.3.0 /DPLUGIN=<path to HAPPlugin.aex> installer\ae-only\hap-ae.nsi

!ifndef VERSION
  !error "pass /DVERSION=x.y.z"
!endif
!ifndef PLUGIN
  !error "pass /DPLUGIN=<path to HAPPlugin.aex>"
!endif

Unicode true
!include "MUI2.nsh"
!include "x64.nsh"

!define PRODUCT "HAP for After Effects"
!define REGKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\HAPAfterEffects"
!define MEDIACORE "$PROGRAMFILES64\Adobe\Common\Plug-ins\7.0\MediaCore"

Name "${PRODUCT} ${VERSION}"
OutFile "HAP-AfterEffects-${VERSION}-win64.exe"
InstallDir "${MEDIACORE}\HAP"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_FINISHPAGE_TEXT "Restart After Effects, then choose HAP Movie under Format in the Render Queue's Output Module."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\license.txt"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "${PRODUCT} needs 64-bit Windows."
    Abort
  ${EndIf}
  SetRegView 64
FunctionEnd

Section "Install"
  ; the install dir is fixed: After Effects only scans the MediaCore folder
  SetOutPath "${MEDIACORE}\HAP"
  File "/oname=HAPPlugin.aex" "${PLUGIN}"
  WriteUninstaller "${MEDIACORE}\HAP\Uninstall HAP for After Effects.exe"

  WriteRegStr HKLM "${REGKEY}" "DisplayName" "${PRODUCT}"
  WriteRegStr HKLM "${REGKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "${REGKEY}" "Publisher" "HAP community"
  WriteRegStr HKLM "${REGKEY}" "URLInfoAbout" "https://github.com/jameslashmar/hap-encoder-adobe-cc"
  WriteRegStr HKLM "${REGKEY}" "InstallLocation" "${MEDIACORE}\HAP"
  WriteRegStr HKLM "${REGKEY}" "UninstallString" '"${MEDIACORE}\HAP\Uninstall HAP for After Effects.exe"'
  WriteRegDWORD HKLM "${REGKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${REGKEY}" "NoRepair" 1
SectionEnd

Function un.onInit
  SetRegView 64
FunctionEnd

Section "Uninstall"
  Delete "${MEDIACORE}\HAP\HAPPlugin.aex"
  Delete "${MEDIACORE}\HAP\Uninstall HAP for After Effects.exe"
  ; only removes the folder if nothing else (e.g. the older Premiere exporter) is in it
  RMDir "${MEDIACORE}\HAP"
  DeleteRegKey HKLM "${REGKEY}"
SectionEnd
