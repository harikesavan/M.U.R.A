; ARM64 architecture entry for the NSIS installer.

!include "x64.nsh"

!define MURA_TARGET_ARCH "arm64"
!define MURA_RUNTIME_KEY "win32-arm64"
!define MURA_EXTRACT_METHOD "zip"

!addincludedir "${PROJECT_DIR}\resources\windows"
!include "installer-common.nsh"

!macro customHeader
  !insertmacro MURA_INSTALLER_CUSTOM_HEADER
!macroend

!macro preInit
  !insertmacro MURA_INSTALLER_PREINIT
!macroend

!macro customFiles_arm64
  !insertmacro MURA_LOG_EXTRACT_RESULT "zip"
!macroend

; Architecture guard. Inserted from MURA_INSTALLER_PREINIT (preInit) so it runs before any
; registry mutation, replacing the old .onVerifyInstDir placement which fired after customInit
; had already healed/cleared/repaired an existing install's registry. (Sentry ELECTRON-3BX)
!macro MURA_ASSERT_TARGET_ARCH
  Var /GLOBAL MuraActualArch
  ${IfNot} ${IsNativeARM64}
    !insertmacro MURA_DETECT_NATIVE_ARCH $MuraActualArch
    !insertmacro MURA_FAIL_UX \
      "${MURA_E_ARCH_MISMATCH}" \
      "target=arm64 actual=$MuraActualArch" \
      "${MURA_MSG_ARCH_MISMATCH_ZH}" \
      "${MURA_MSG_ARCH_MISMATCH_EN}" \
      "${MURA_MSG_ARCH_MISMATCH_ACTION_ZH}" \
      "${MURA_MSG_ARCH_MISMATCH_ACTION_EN}" \
      "target=arm64 actual=$MuraActualArch" \
      "target=arm64 actual=$MuraActualArch"
  ${EndIf}
!macroend
