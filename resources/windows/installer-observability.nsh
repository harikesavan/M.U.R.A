!ifndef MURA_INSTALLER_OBSERVABILITY_NSH
!define MURA_INSTALLER_OBSERVABILITY_NSH

!define MURA_APP_EXECUTABLE_FILENAME "Mura.exe"
!define MURA_FALLBACK_LOG "mura-installer-${VERSION}-fallback-log.jsonl"

!pragma warning disable 6001
Var /GLOBAL MuraSessionId
Var /GLOBAL MuraIsUpdated
Var /GLOBAL MuraSessionLogResult
Var /GLOBAL MuraSessionLogPath

!macro MURA_SESSION_HEADER
  !insertmacro MURA_SLOG "event=header arch=${MURA_TARGET_ARCH} updated=$MuraIsUpdated instDir=$INSTDIR version=${VERSION} log=$MuraSessionLogPath detail=customHeader"
!macroend

!macro MURA_SLOG _MESSAGE
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$MuraSessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${MURA_FALLBACK_LOG}' }; \
    $$session = '$MuraSessionId'; \
    if (-not $$session) { $$session = 'uninitialized' }; \
    $$message = '${_MESSAGE}'; \
    $$event = 'log'; \
    if ($$message -match '(^|\s)event=([^\s]+)') { $$event = $$Matches[2] } else { $$first = @($$message -split '\s+', 2)[0]; if ($$first -and $$first -notmatch '=') { $$event = $$first } }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = $$session; version = '${VERSION}'; arch = '${MURA_TARGET_ARCH}'; updated = ('$MuraIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = $$event; message = $$message }; \
    $$json = $$payload | ConvertTo-Json -Compress -Depth 8; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value $$json \
  }"`
  Pop $9
  Pop $9
!macroend

!macro MURA_LOG_EVENT _MESSAGE
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$MuraSessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${MURA_FALLBACK_LOG}' }; \
    $$session = '$MuraSessionId'; \
    if (-not $$session) { $$session = 'uninitialized' }; \
    $$message = '${_MESSAGE}'; \
    $$event = 'log'; \
    if ($$message -match '(^|\s)event=([^\s]+)') { $$event = $$Matches[2] } else { $$first = @($$message -split '\s+', 2)[0]; if ($$first -and $$first -notmatch '=') { $$event = $$first } }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = $$session; version = '${VERSION}'; arch = '${MURA_TARGET_ARCH}'; updated = ('$MuraIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = $$event; message = $$message }; \
    $$json = $$payload | ConvertTo-Json -Compress -Depth 8; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value $$json \
  }"`
  Pop $9
  Pop $9
!macroend

!macro MURA_LOG_JSON_EVENT _EVENT _JSON_FIELDS
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$MuraSessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${MURA_FALLBACK_LOG}' }; \
    $$session = '$MuraSessionId'; \
    if (-not $$session) { $$session = 'uninitialized' }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = $$session; version = '${VERSION}'; arch = '${MURA_TARGET_ARCH}'; updated = ('$MuraIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = '${_EVENT}' }; \
    ${_JSON_FIELDS}; \
    $$json = $$payload | ConvertTo-Json -Compress -Depth 8; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value $$json \
  }"`
  Pop $9
  Pop $9
!macroend

!macro MURA_SESSION_BEGIN
  ${GetParameters} $R9
  ClearErrors
  ${GetOptions} $R9 "--installer-log=" $R8
  ${IfNot} ${Errors}
    StrCpy $MuraSessionLogPath $R8
  ${EndIf}
  ClearErrors
  ${GetOptions} $R9 "--installer-session=" $R8
  ${IfNot} ${Errors}
    StrCpy $MuraSessionId $R8
  ${EndIf}

  ${If} $MuraSessionLogPath == ""
    nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "$$id = '$MuraSessionId'; if (-not $$id) { $$id = [guid]::NewGuid().ToString('N').Substring(0,12) }; $$stamp = Get-Date -Format 'yyyyMMdd'; $$name = 'mura-installer-${VERSION}-' + $$stamp + '-log.jsonl'; $$log = Join-Path $$env:TEMP $$name; [Console]::Out.Write($$id + '|' + $$log)"`
    Pop $MuraSessionLogResult
    Pop $MuraSessionLogResult
    StrCpy $MuraSessionId $MuraSessionLogResult 12
    StrCpy $MuraSessionLogPath $MuraSessionLogResult 1024 13
  ${ElseIf} $MuraSessionId == ""
    nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "[Console]::Out.Write([guid]::NewGuid().ToString('N').Substring(0,12))"`
    Pop $MuraSessionLogResult
    Pop $MuraSessionLogResult
    StrCpy $MuraSessionId $MuraSessionLogResult
  ${EndIf}

  ClearErrors
  ${GetOptions} $R9 "--updated" $R8
  StrCpy $MuraIsUpdated "0"
  ${IfNot} ${Errors}
    StrCpy $MuraIsUpdated "1"
  ${EndIf}

  !insertmacro MURA_SLOG "event=session-begin detail=preInit"
!macroend

!macro MURA_LOG_EXTRACT_RESULT _METHOD
  ${IfNot} ${FileExists} "$INSTDIR\Mura.exe"
    !insertmacro MURA_FAIL_UX \
      "${MURA_E_EXTRACT_FAILED}" \
      "event=extract result=fail method=${_METHOD} missing=Mura.exe" \
      "${MURA_MSG_EXTRACT_FAILED_ZH}" \
      "${MURA_MSG_EXTRACT_FAILED_EN}" \
      "${MURA_MSG_EXTRACT_FAILED_ACTION_ZH}" \
      "${MURA_MSG_EXTRACT_FAILED_ACTION_EN}" \
      "extract result=fail method=${_METHOD} missing=Mura.exe instDir=$INSTDIR" \
      "extract result=fail method=${_METHOD} missing=Mura.exe instDir=$INSTDIR"
  ${Else}
    !insertmacro MURA_SLOG "event=extract result=ok method=${_METHOD} detail=customFiles_${MURA_TARGET_ARCH}"
  ${EndIf}
!macroend

!macro MURA_SESSION_SUCCESS
  !insertmacro MURA_SLOG "event=session-end result=success detail=customInstall"
!macroend

!endif
