!ifndef MURA_INSTALLER_REMOVE_REGISTRY_NSH
!define MURA_INSTALLER_REMOVE_REGISTRY_NSH

!macro MURA_CLEAR_INSTALL_REGISTRY _REASON
  DeleteRegKey SHCTX "${UNINSTALL_REGISTRY_KEY}"
  DeleteRegKey SHCTX "${INSTALL_REGISTRY_KEY}"
  !insertmacro MURA_LOG_EVENT "event=registry-clear reason=${_REASON} uninstallKey=${UNINSTALL_REGISTRY_KEY} installKey=${INSTALL_REGISTRY_KEY}"
!macroend

!macro MURA_LOG_ATOMIC_REMOVE_FAILURE
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$MuraSessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${MURA_FALLBACK_LOG}' }; \
    $$failed = '$MuraAtomicFailedPath'; \
    $$instDir = '$INSTDIR'; \
    $$oldInstallDir = '$MuraAtomicStagingDir'; \
    $$relative = $$failed; \
    if ($$failed.StartsWith($$instDir, [System.StringComparison]::CurrentCultureIgnoreCase)) { $$relative = $$failed.Substring($$instDir.Length).TrimStart('\') }; \
    $$tempCandidate = if ($$relative -and $$relative -ne $$failed) { Join-Path $$oldInstallDir $$relative } else { '' }; \
    $$kind = if ($$tempCandidate.Length -ge 260) { 'likely-long-path' } else { 'unknown' }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = '$MuraSessionId'; version = '${VERSION}'; arch = '${MURA_TARGET_ARCH}'; updated = ('$MuraIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = 'remove-atomic-failed'; kind = $$kind; pathLength = $$failed.Length; tempCandidateLength = $$tempCandidate.Length; atomicFailedPath = $$failed; tempCandidate = $$tempCandidate }; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value ($$payload | ConvertTo-Json -Compress -Depth 8) \
  }"`
  Pop $9
  Pop $9
!macroend

!macro MURA_LOG_REMOVE_FAILURE_JSON _PHASE _FATAL _FAILED_PATH _EXTRA_FIELDS
  !insertmacro MURA_LOG_JSON_EVENT "failure" "$$lockerText = '$MuraLockerList'; $$processes = @(); if ($$lockerText -and $$lockerText -notlike 'Windows did not identify*' -and $$lockerText -ne 'unknown process') { $$processes = @($$lockerText -split ',\s*' | Where-Object { $$_ } | ForEach-Object { if ($$_ -match '^(.*)\(([0-9]+)\)$$') { [ordered]@{ name = $$Matches[1]; pid = [int]$$Matches[2] } } else { [ordered]@{ name = $$_; pid = $$null } } }) }; $$payload.code = '${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED}'; $$payload.phase = '${_PHASE}'; $$payload.failedPath = '${_FAILED_PATH}'; $$payload.blockingProcesses = @($$processes); if ($$lockerText -like 'Mura installer(*)') { $$payload.fallbackReason = 'installer-self-lock'; $$payload.message = 'The installer process is using the install directory as its current output directory.' } elseif ($$processes.Count -eq 0) { $$payload.fallbackReason = 'restart-manager-no-process'; $$payload.message = 'Windows did not identify a specific locking process. Close terminals, editors, and file managers opened in the install folder.' } else { $$payload.fallbackReason = ''; $$payload.message = '' }; $$payload.fatal = ('${_FATAL}' -eq '1'); ${_EXTRA_FIELDS}"
!macroend

!macro MURA_REMOVE_INSTALL_DIR
  StrCpy $MuraRemoveResidueCount "0"
  ${If} $MuraRemoveResidueRoot == ""
    StrCpy $MuraRemoveResidueRoot "$INSTDIR"
  ${EndIf}
  StrCpy $MuraRemoveFirstFailedPath ""
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'Continue'; \
    $$log = '$MuraSessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${MURA_FALLBACK_LOG}' }; \
    $$path = [System.IO.Path]::GetFullPath('$MuraRemoveResidueRoot'); \
    $$firstFailedFile = '$PLUGINSDIR\mura-remove-first-failed.txt'; \
    Set-Content -LiteralPath $$firstFailedFile -Encoding UTF8 -NoNewline -Value ''; \
    function Write-InstallerLog($$message) { $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = '$MuraSessionId'; version = '${VERSION}'; arch = '${MURA_TARGET_ARCH}'; updated = ('$MuraIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = 'remove-log'; message = $$message }; if ($$message -match '(^|\s)event=([^\s]+)') { $$payload.event = $$Matches[2] }; Add-Content -LiteralPath $$log -Encoding UTF8 -Value ($$payload | ConvertTo-Json -Compress -Depth 8) } \
    function Convert-LongPath($$itemPath) { if ($$itemPath.StartsWith('\\')) { return '\\?\UNC\' + $$itemPath.TrimStart('\') } return '\\?\' + $$itemPath } \
    function Remove-WithRetries($$item, $$isDir) { \
      $$delays = @(200,500,1000); \
      for ($$i = 0; $$i -lt $$delays.Count; $$i++) { \
        try { \
          if ($$isDir) { [System.IO.Directory]::Delete((Convert-LongPath $$item), $$false) } else { [System.IO.File]::Delete((Convert-LongPath $$item)) } \
          return $$true \
        } catch { \
          if ($$i -lt $$delays.Count - 1) { Start-Sleep -Milliseconds $$delays[$$i] } else { Write-InstallerLog ('event=remove-resilient-leftover path=' + $$item + ' attempts=3 error=' + $$_.Exception.GetType().FullName + ': ' + $$_.Exception.Message); return $$false } \
        } \
      } \
      return $$false \
    } \
    try { \
      if (-not (Test-Path -LiteralPath $$path)) { Write-InstallerLog ('remove-longpath result=0 instDir=' + $$path); exit 0 } \
      $$failed = New-Object System.Collections.Generic.List[string]; \
      foreach ($$file in @(Get-ChildItem -LiteralPath $$path -Force -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)) { if (-not (Remove-WithRetries $$file.FullName $$false)) { $$failed.Add($$file.FullName) } } \
      foreach ($$dir in @(Get-ChildItem -LiteralPath $$path -Force -Recurse -Directory -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)) { if (-not (Remove-WithRetries $$dir.FullName $$true)) { $$failed.Add($$dir.FullName) } } \
      if (-not (Remove-WithRetries $$path $$true)) { $$failed.Add($$path) } \
      Write-InstallerLog ('event=remove-resilient-summary failedCount=' + $$failed.Count + ' root=' + $$path); \
      if ($$failed.Count -gt 0) { Set-Content -LiteralPath $$firstFailedFile -Encoding UTF8 -NoNewline -Value $$failed[0]; exit $$failed.Count } \
      Write-InstallerLog ('remove-longpath result=0 instDir=' + $$path); \
      exit 0 \
    } catch { \
      Write-InstallerLog ('remove-longpath result=1 instDir=' + $$path + ' error=' + $$_.Exception.GetType().FullName + ': ' + $$_.Exception.Message); \
      exit 1 \
    } \
  }"`
  Pop $MuraRemoveDirResult

  ClearErrors
  SetDetailsPrint none
  FileOpen $MuraRemoveFirstFailedFile "$PLUGINSDIR\mura-remove-first-failed.txt" r
  ${IfNot} ${Errors}
    FileRead $MuraRemoveFirstFailedFile $MuraRemoveFirstFailedPath
    FileClose $MuraRemoveFirstFailedFile
  ${EndIf}
  SetDetailsPrint lastused

  ${If} $MuraRemoveDirResult == "error"
    !insertmacro MURA_LOG_EVENT "event=remove-longpath fallback=RMDir reason=no-powershell root=$INSTDIR"
    RMDir /r "$MuraRemoveResidueRoot"
    ${If} ${FileExists} "$MuraRemoveResidueRoot\*.*"
      StrCpy $MuraRemoveDirResult "1"
    ${Else}
      StrCpy $MuraRemoveDirResult "0"
    ${EndIf}
  ${EndIf}

  ${If} $MuraRemoveDirResult != 0
    StrCpy $MuraRemoveResidueCount $MuraRemoveDirResult
  ${EndIf}
!macroend

!macro customRemoveFiles
  !insertmacro MURA_LOG_EVENT "remove-start instDir=$INSTDIR"
  Var /GLOBAL MuraRemoveDirResult
  Var /GLOBAL MuraAtomicFailedPath
  Var /GLOBAL MuraAtomicRemoveSucceeded
  Var /GLOBAL MuraAtomicStagingDir
  Var /GLOBAL MuraRemoveResidueCount
  Var /GLOBAL MuraRemoveResidueRoot
  Var /GLOBAL MuraRemoveFirstFailedPath
  Var /GLOBAL MuraRemoveFirstFailedFile
  StrCpy $MuraAtomicFailedPath ""
  StrCpy $MuraAtomicRemoveSucceeded "0"
  StrCpy $MuraAtomicStagingDir ""
  StrCpy $MuraRemoveResidueCount "0"
  StrCpy $MuraRemoveResidueRoot "$INSTDIR"
  StrCpy $MuraRemoveFirstFailedPath ""

  SetOutPath $TEMP
  StrCpy $MuraCurrentOutDir "$TEMP"

  ${if} ${isUpdated}
    StrCpy $MuraAtomicStagingDir "$INSTDIR.__old"
    ${If} ${FileExists} "$MuraAtomicStagingDir\*.*"
      StrCpy $MuraRemoveResidueRoot "$MuraAtomicStagingDir"
      !insertmacro MURA_LOG_EVENT "remove-stale-staging start root=$MuraRemoveResidueRoot"
      !insertmacro MURA_REMOVE_INSTALL_DIR
      StrCpy $MuraRemoveResidueRoot "$INSTDIR"
    ${EndIf}

    mura_retry_atomic_rename:
      ClearErrors
      Rename "$INSTDIR" "$MuraAtomicStagingDir"
    ${if} ${Errors}
      DetailPrint "Atomic update cleanup failed before replacing previous installation: $INSTDIR"
      StrCpy $MuraAtomicFailedPath "$INSTDIR"
      !insertmacro MURA_LOG_ATOMIC_REMOVE_FAILURE
      !insertmacro MURA_CAPTURE_FAILED_PATH_LOCKERS "$MuraAtomicFailedPath"
      ${IfNot} ${Silent}
        !insertmacro MURA_PROMPT_FAILED_PATH_LOCKERS "$MuraAtomicFailedPath" "atomic-failed" mura_retry_atomic_rename mura_cancel_atomic_rename mura_continue_atomic_failed
        mura_cancel_atomic_rename:
      ${EndIf}
      mura_continue_atomic_failed:
      !insertmacro MURA_LOG_REMOVE_FAILURE_JSON "atomic-failed" "1" "$MuraAtomicFailedPath" "$$payload.atomicFailedPath = '$MuraAtomicFailedPath'"
      !insertmacro MURA_LOG_EVENT "code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=atomic-failed fatal=1 degraded=none firstFailed=$MuraAtomicFailedPath atomicFailedPath=$MuraAtomicFailedPath"
      !insertmacro MURA_CLEAR_INSTALL_REGISTRY "remove-failed-before-quit"
      !insertmacro MURA_FAIL_REPORTABLE_BILINGUAL ${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} "event=session-end result=fail code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=atomic-failed fatal=1 firstFailed=$MuraAtomicFailedPath lockers=$MuraLockerList" "${MURA_MSG_REPLACE_LOCKED_EN}" "${MURA_MSG_REPLACE_LOCKED_ZH}" "${MURA_MSG_CLOSE_SHOWN_FILE_ACTION_EN}" "${MURA_MSG_CLOSE_SHOWN_FILE_ACTION_ZH}"
    ${else}
      !insertmacro MURA_LOG_EVENT "remove-atomic result=0 staging=$MuraAtomicStagingDir"
      StrCpy $MuraAtomicRemoveSucceeded "1"
      StrCpy $MuraRemoveResidueRoot "$MuraAtomicStagingDir"
    ${endif}
  ${endif}

  mura_retry_remove_install_dir:
    !insertmacro MURA_REMOVE_INSTALL_DIR
  ${if} $MuraRemoveDirResult != 0
    !insertmacro MURA_CAPTURE_FAILED_PATH_LOCKERS "$MuraRemoveFirstFailedPath"
    ${if} $MuraAtomicRemoveSucceeded == "1"
      ${IfNot} ${Silent}
        !insertmacro MURA_PROMPT_FAILED_PATH_LOCKERS "$MuraRemoveFirstFailedPath" "residual-delete-failed" mura_retry_remove_install_dir mura_cancel_remove_after_rm mura_continue_after_rm
        mura_cancel_remove_after_rm:
          !insertmacro MURA_LOG_REMOVE_FAILURE_JSON "residual-delete-failed" "1" "$MuraRemoveFirstFailedPath" "$$payload.residueRoot = '$MuraRemoveResidueRoot'; $$payload.failedCount = '$MuraRemoveResidueCount'; $$payload.removeDirResult = '$MuraRemoveDirResult'; $$payload.atomicSucceeded = ('$MuraAtomicRemoveSucceeded' -eq '1')"
          !insertmacro MURA_LOG_EVENT "code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed userAction=cancel fatal=1 residueRoot=$MuraRemoveResidueRoot failedCount=$MuraRemoveResidueCount firstFailed=$MuraRemoveFirstFailedPath removeDirResult=$MuraRemoveDirResult removeResidueCount=$MuraRemoveResidueCount atomicFailedPath=$MuraAtomicFailedPath atomicSucceeded=$MuraAtomicRemoveSucceeded"
          !insertmacro MURA_FAIL_REPORTABLE_BILINGUAL ${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} "event=session-end result=fail code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed userAction=cancel fatal=1 firstFailed=$MuraRemoveFirstFailedPath lockers=$MuraLockerList" "${MURA_MSG_PREVIOUS_FILE_OPEN_EN}" "${MURA_MSG_PREVIOUS_FILE_OPEN_ZH}" "${MURA_MSG_CLOSE_SHOWN_FILE_ACTION_EN}" "${MURA_MSG_CLOSE_SHOWN_FILE_ACTION_ZH}"
      ${EndIf}
      mura_continue_after_rm:
      DetailPrint `Mura previous installation had locked residual files; continuing after atomic cleanup succeeded: $INSTDIR`
      !insertmacro MURA_LOG_EVENT "code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed degraded=continue fatal=0 residueRoot=$MuraRemoveResidueRoot failedCount=$MuraRemoveResidueCount firstFailed=$MuraRemoveFirstFailedPath removeDirResult=$MuraRemoveDirResult removeResidueCount=$MuraRemoveResidueCount atomicFailedPath=$MuraAtomicFailedPath atomicSucceeded=$MuraAtomicRemoveSucceeded"
    ${else}
      DetailPrint `Can't safely remove previous installation without atomic cleanup proof: $INSTDIR`
      ${IfNot} ${Silent}
        !insertmacro MURA_PROMPT_FAILED_PATH_LOCKERS "$MuraRemoveFirstFailedPath" "residual-delete-failed-no-atomic-proof" mura_retry_remove_install_dir mura_cancel_remove_no_atomic mura_continue_remove_no_atomic
        mura_cancel_remove_no_atomic:
      ${EndIf}
      mura_continue_remove_no_atomic:
      !insertmacro MURA_LOG_REMOVE_FAILURE_JSON "residual-delete-failed-no-atomic-proof" "1" "$MuraRemoveFirstFailedPath" "$$payload.residueRoot = '$MuraRemoveResidueRoot'; $$payload.failedCount = '$MuraRemoveResidueCount'; $$payload.removeDirResult = '$MuraRemoveDirResult'; $$payload.atomicSucceeded = ('$MuraAtomicRemoveSucceeded' -eq '1')"
      !insertmacro MURA_LOG_EVENT "code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed-no-atomic-proof degraded=none fatal=1 residueRoot=$MuraRemoveResidueRoot failedCount=$MuraRemoveResidueCount firstFailed=$MuraRemoveFirstFailedPath removeDirResult=$MuraRemoveDirResult removeResidueCount=$MuraRemoveResidueCount atomicFailedPath=$MuraAtomicFailedPath atomicSucceeded=$MuraAtomicRemoveSucceeded"
      !insertmacro MURA_CLEAR_INSTALL_REGISTRY "remove-failed-before-quit"
      !insertmacro MURA_FAIL_REPORTABLE_BILINGUAL ${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} "event=session-end result=fail code=${MURA_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed-no-atomic-proof fatal=1 firstFailed=$MuraRemoveFirstFailedPath removeDirResult=$MuraRemoveDirResult lockers=$MuraLockerList" "${MURA_MSG_REMOVE_PREVIOUS_DIR_EN}" "${MURA_MSG_REMOVE_PREVIOUS_DIR_ZH}" "${MURA_MSG_CLOSE_INSTALL_DIR_ACTION_EN}" "${MURA_MSG_CLOSE_INSTALL_DIR_ACTION_ZH}"
    ${endif}
  ${else}
    !insertmacro MURA_LOG_EVENT "remove-final errors=0 instDir=$INSTDIR removeDirResult=$MuraRemoveDirResult removeResidueCount=$MuraRemoveResidueCount removeResidueRoot=$MuraRemoveResidueRoot atomicFailedPath=$MuraAtomicFailedPath atomicSucceeded=$MuraAtomicRemoveSucceeded"
  ${endif}
!macroend

!macro customUnInit
  !insertmacro MURA_LOG_EVENT "uninit instDir=$INSTDIR"
!macroend

!macro customUnInstall
  !insertmacro MURA_LOG_EVENT "uninstall-section start instDir=$INSTDIR"
!macroend

!endif
