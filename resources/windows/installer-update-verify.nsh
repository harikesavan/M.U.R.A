!ifndef MURA_INSTALLER_UPDATE_VERIFY_NSH
!define MURA_INSTALLER_UPDATE_VERIFY_NSH

Var /GLOBAL MuraUninstallHadErrors
Var /GLOBAL MuraUninstallLogResult
Var /GLOBAL MuraVerifyResourceResult
Var /GLOBAL MuraUpdatedAppExitWaitResult
Var /GLOBAL MuraActiveMarkerExecResult
Var /GLOBAL MuraActiveMarkerResult

!define MURA_ACTIVE_INSTALLER_MARKER "mura-installer-active.marker"

!macro MURA_BRING_UPDATED_INSTALLER_TO_FRONT
  ${If} ${isUpdated}
    BringToFront
    !insertmacro MURA_SLOG "event=updated-installer-foreground action=bring-to-front"
  ${EndIf}
!macroend

!macro MURA_WAIT_FOR_UPDATED_APP_EXIT
  ${If} ${isUpdated}
    !insertmacro MURA_SLOG "event=updated-app-exit-wait phase=start"
    StrCpy $MuraUpdatedAppExitWaitResult "0"

    nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
      $$ErrorActionPreference = 'SilentlyContinue'; \
      $$deadline = (Get-Date).AddSeconds(10); \
      $$target = [System.IO.Path]::GetFullPath((Join-Path '$INSTDIR' '${MURA_APP_EXECUTABLE_FILENAME}')); \
      do { \
        $$hits = @(Get-CimInstance -ClassName Win32_Process | Where-Object { \
          $$path = $$_.ExecutablePath; \
          if (-not $$path) { $$path = $$_.Path } \
          $$_.Name -ieq '${MURA_APP_EXECUTABLE_FILENAME}' -and $$path -and \
          [string]::Equals([System.IO.Path]::GetFullPath($$path), $$target, [System.StringComparison]::CurrentCultureIgnoreCase) \
        }); \
        if ($$hits.Count -eq 0) { exit 0 }; \
        Start-Sleep -Milliseconds 500; \
      } while ((Get-Date) -lt $$deadline); \
      exit 1 \
    }"`
    Pop $MuraUpdatedAppExitWaitResult

    ${If} $MuraUpdatedAppExitWaitResult != 0
      !insertmacro MURA_SLOG "event=updated-app-exit-wait phase=timeout action=stop"
      !insertmacro MURA_STOP_APP_PROCESSES
    ${EndIf}

    !insertmacro MURA_SLOG "event=updated-app-exit-wait phase=done result=$MuraUpdatedAppExitWaitResult"
  ${EndIf}
!macroend

!macro MURA_RECORD_ACTIVE_INSTALLER_MARKER
  nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$marker = Join-Path $$env:TEMP '${MURA_ACTIVE_INSTALLER_MARKER}'; \
    if (-not (Test-Path -LiteralPath $$marker)) { Write-Output 'missing'; exit 0 }; \
    $$item = Get-Item -LiteralPath $$marker; \
    if ($$item.LastWriteTime -lt (Get-Date).AddHours(-2)) { Write-Output 'stale'; exit 0 }; \
    Write-Output 'active' \
  }"`
  Pop $MuraActiveMarkerExecResult
  Pop $MuraActiveMarkerResult
  ${If} $MuraActiveMarkerResult == "active"
    !insertmacro MURA_SLOG "event=installer-active-marker state=active"
  ${ElseIf} $MuraActiveMarkerResult == "stale"
    !insertmacro MURA_SLOG "event=installer-active-marker state=stale"
  ${Else}
    !insertmacro MURA_SLOG "event=installer-active-marker state=missing"
  ${EndIf}
!macroend

!macro MURA_WRITE_ACTIVE_INSTALLER_MARKER
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$marker = Join-Path $$env:TEMP '${MURA_ACTIVE_INSTALLER_MARKER}'; \
    Set-Content -LiteralPath $$marker -Encoding UTF8 -Value ('pid=' + $$PID + ';session=$MuraSessionId;started=' + (Get-Date -Format o)) \
  }"`
  Pop $MuraActiveMarkerResult
!macroend

!macro MURA_CLEAR_ACTIVE_INSTALLER_MARKER
  !ifndef BUILD_UNINSTALLER
    nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
      $$ErrorActionPreference = 'SilentlyContinue'; \
      Remove-Item -LiteralPath (Join-Path $$env:TEMP '${MURA_ACTIVE_INSTALLER_MARKER}') -Force \
    }"`
    Pop $MuraActiveMarkerResult
  !endif
!macroend

!macro MURA_OVERRIDE_SINGLE_INSTANCE
!macroend

!macro MURA_OVERRIDE_APP_CANNOT_BE_CLOSED_MESSAGE
  !pragma warning disable 6030
  LangString appCannotBeClosed 1033 "${MURA_MSG_APP_CANNOT_BE_CLOSED_ZH}$\r$\n$\r$\n${MURA_MSG_BLOCK_SEPARATOR}$\r$\n$\r$\n${MURA_MSG_APP_CANNOT_BE_CLOSED_EN}"
  LangString appCannotBeClosed 2052 "${MURA_MSG_APP_CANNOT_BE_CLOSED_ZH}$\r$\n$\r$\n${MURA_MSG_BLOCK_SEPARATOR}$\r$\n$\r$\n${MURA_MSG_APP_CANNOT_BE_CLOSED_EN}"
  !pragma warning default 6030
!macroend

!macro MURA_INSTALLER_CUSTOM_HEADER
  !insertmacro MURA_OVERRIDE_SINGLE_INSTANCE
  !insertmacro MURA_OVERRIDE_APP_CANNOT_BE_CLOSED_MESSAGE
!macroend

!macro MURA_RELEASE_INSTALL_DIR_OUTDIR
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  StrCpy $MuraCurrentOutDir "$PLUGINSDIR"
!macroend

; Resolve the machine's real native architecture (arm64 / x64 / x86) for diagnostics.
; Backed by IsWow64Process2 (via x64.nsh), so it reports the true hardware arch even when
; the installer runs under x86/x64 emulation. Replaces the old hardcoded "non-arm64" detail.
!macro MURA_DETECT_NATIVE_ARCH _OUT
  ${If} ${IsNativeARM64}
    StrCpy ${_OUT} "arm64"
  ${ElseIf} ${RunningX64}
    StrCpy ${_OUT} "x64"
  ${Else}
    StrCpy ${_OUT} "x86"
  ${EndIf}
!macroend

!macro MURA_INSTALLER_PREINIT
  !ifdef BUILD_UNINSTALLER
    StrCpy $MuraSessionId ""
    StrCpy $MuraIsUpdated "0"
    StrCpy $MuraSessionLogResult ""
    StrCpy $MuraSessionLogPath "$TEMP\${MURA_FALLBACK_LOG}"
    StrCpy $MuraUninstallHadErrors "0"
    StrCpy $MuraUninstallLogResult ""
    StrCpy $MuraVerifyResourceResult ""
    StrCpy $MuraUpdatedAppExitWaitResult ""
    StrCpy $MuraActiveMarkerExecResult ""
    StrCpy $MuraActiveMarkerResult ""
    StrCpy $MuraStopResult ""
    StrCpy $MuraLockerListZh ""
    StrCpy $MuraLockerListEn ""
  !else
    !insertmacro MURA_RELEASE_INSTALL_DIR_OUTDIR
    !insertmacro MURA_SESSION_BEGIN
    !insertmacro MURA_SLOG "event=installer-outdir-release outDir=$MuraCurrentOutDir instDir=$INSTDIR"
    ; Guard target/machine architecture as early as possible: this runs before customInit's
    ; registry heal/clear/repair, so a wrong-arch installer aborts without mutating an existing
    ; correct-arch install's registry or uninstaller state. (Sentry ELECTRON-3BX / code E1040)
    !insertmacro MURA_ASSERT_TARGET_ARCH
    !insertmacro MURA_BRING_UPDATED_INSTALLER_TO_FRONT
    !insertmacro MURA_RECORD_ACTIVE_INSTALLER_MARKER
    !insertmacro MURA_WRITE_ACTIVE_INSTALLER_MARKER
  !endif
!macroend

!macro MURA_VERIFY_REQUIRED_FILE _PATH _LABEL
  ${IfNot} ${FileExists} "${_PATH}"
    !insertmacro MURA_LOG_EVENT "verify-required-file missing label=${_LABEL} path=${_PATH}"
    !insertmacro MURA_FAIL_UX \
      "${MURA_E_CORE_APP_FILES_INCOMPLETE}" \
      "verify-required-file missing label=${_LABEL} path=${_PATH}" \
      "${MURA_MSG_VERIFY_REQUIRED_FILE_ZH} ${_LABEL}" \
      "${MURA_MSG_VERIFY_REQUIRED_FILE_EN} ${_LABEL}" \
      "${MURA_MSG_VERIFY_REQUIRED_FILE_ACTION_ZH}" \
      "${MURA_MSG_VERIFY_REQUIRED_FILE_ACTION_EN}" \
      "verify-required-file missing label=${_LABEL} path=${_PATH}" \
      "verify-required-file missing label=${_LABEL} path=${_PATH}"
  ${Else}
    !insertmacro MURA_LOG_EVENT "verify-required-file ok label=${_LABEL} path=${_PATH}"
  ${EndIf}
!macroend

!macro MURA_VERIFY_CORE_APP_FILES
  !insertmacro MURA_LOG_EVENT "verify-install start instDir=$INSTDIR"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\Mura.exe" "Mura.exe"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\ffmpeg.dll" "ffmpeg.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\libEGL.dll" "libEGL.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\libGLESv2.dll" "libGLESv2.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\d3dcompiler_47.dll" "d3dcompiler_47.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\dxcompiler.dll" "dxcompiler.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\dxil.dll" "dxil.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\vk_swiftshader.dll" "vk_swiftshader.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\vulkan-1.dll" "vulkan-1.dll"
  !insertmacro MURA_VERIFY_REQUIRED_FILE "$INSTDIR\resources\app.asar" "resources\app.asar"
!macroend

!macro MURA_VERIFY_BUNDLED_AIONCORE_RESOURCES _RUNTIME_KEY
  InitPluginsDir
  File "/oname=$PLUGINSDIR\verify-bundled-aioncore-install.ps1" "${PROJECT_DIR}\resources\windows\support\verify-bundled-aioncore-install.ps1"
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\verify-bundled-aioncore-install.ps1" -InstallDir "$INSTDIR" -RuntimeKey "${_RUNTIME_KEY}" -LogPath "$MuraSessionLogPath"`
  Pop $MuraVerifyResourceResult

  ${If} $MuraVerifyResourceResult != 0
    !insertmacro MURA_FAIL_UX \
      "${MURA_E_BUNDLED_AIONCORE_INCOMPLETE}" \
      "event=session-end result=fail code=${MURA_E_BUNDLED_AIONCORE_INCOMPLETE} detail=bundled-aioncore-incomplete runtime=${_RUNTIME_KEY} result=$MuraVerifyResourceResult" \
      "${MURA_MSG_BUNDLED_AIONCORE_INCOMPLETE_ZH}" \
      "${MURA_MSG_BUNDLED_AIONCORE_INCOMPLETE_EN}" \
      "${MURA_MSG_BUNDLED_AIONCORE_INCOMPLETE_ACTION_ZH}" \
      "${MURA_MSG_BUNDLED_AIONCORE_INCOMPLETE_ACTION_EN}" \
      "bundled-aioncore-incomplete runtime=${_RUNTIME_KEY} result=$MuraVerifyResourceResult instDir=$INSTDIR" \
      "bundled-aioncore-incomplete runtime=${_RUNTIME_KEY} result=$MuraVerifyResourceResult instDir=$INSTDIR"
  ${EndIf}
!macroend

!macro customInstall
  !insertmacro MURA_VERIFY_CORE_APP_FILES
  !insertmacro MURA_VERIFY_BUNDLED_AIONCORE_RESOURCES "${MURA_RUNTIME_KEY}"
  !insertmacro MURA_LOG_EVENT "verify-install ok instDir=$INSTDIR"
  !insertmacro MURA_CLEAR_ACTIVE_INSTALLER_MARKER
  !insertmacro MURA_SESSION_SUCCESS
!macroend

!endif
