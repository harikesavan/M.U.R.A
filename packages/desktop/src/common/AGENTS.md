# Common layer guide

## Overview

Shared code layer imported by main process, renderer, web-host, and mobile. All code in this directory must be process-agnostic and free of unguarded process-specific APIs.

## Structure

- `adapter/`
  Bridge and transport abstractions. `httpBridge.ts` handles transport, `ipcBridge.ts` is deprecated. Domain mappers: `apiModelMapper.ts`, `searchMapper.ts`, `sidebarMapper.ts`, `teamMapper.ts`, `workspaceMapper.ts`. Utility files: `registry.ts`, `sessionRefresh.ts`, `teamTaskPath.ts`, `browser.ts`, `main.ts`, `constant.ts`.
- `api/`
  LLM provider clients and protocol converters. `ClientFactory.ts` builds clients from provider config. Per-provider rotating clients (`OpenAIRotatingClient.ts`, `GeminiRotatingClient.ts`, `AnthropicRotatingClient.ts`) extend `RotatingApiClient.ts` for API-key rotation. `ApiKeyManager.ts` manages keys. Protocol converters: `OpenAI2AnthropicConverter.ts`, `OpenAI2GeminiConverter.ts`, `ProtocolConverter.ts`.
- `chat/`
  Chat domain logic: `chatLib.ts`, `atCommandParser.ts`, `normalizeToolCall.ts`, `acpToolCallOutput.ts`, `imageGenCore.ts`, `sideQuestion.ts`, `forkConversation.ts`. Subdirectories: `approval/`, `document/`, `navigation/`, `slash/`.
- `config/`
  `i18n-config.json` (13-language / 19-module i18n manifest) and `storage.ts` (contains deprecated bits).
- `platform/`
  Runtime platform guards (`isElectron`, `isRenderer`).
- `types/`
  Shared domain types: `agent`, `channel` (deprecated bits), `office`, `platform`, `provider/authType.ts`, `team`, `project.ts`, `chatFile.ts`.
- `theme/`, `update/`, `utils/`, `electronSafe.ts`, `index.ts`
  Theme definitions, updater types, utilities, Electron safety exports, and main package index.

Path aliases:
- `@common/*` -> `packages/desktop/src/common/*` (Vite and Vitest)
- `@mcp/*` -> aliased to `common/` in Vitest

## Where to look

- Wire a new LLM provider client:
  `types/provider/authType.ts` (auth types) and `api/ClientFactory.ts` (client wiring). Also update `ModelModalContent.tsx` in renderer settings.
- Add an LLM protocol converter:
  `api/ProtocolConverter.ts` or provider-specific converters in `api/`.
- Chat parsing or tool-call normalization:
  `chat/atCommandParser.ts`, `chat/normalizeToolCall.ts`, `chat/chatLib.ts`.
- i18n module manifest:
  `config/i18n-config.json`.
- Shared type definitions:
  `types/`.
- Runtime platform guards:
  `platform/` (`isElectron`, `isRenderer`).

## Anti-patterns

- No unguarded process-specific APIs:
  Do not use Node-only (`fs`, `child_process`), DOM-only (`document`, `window`), or Electron-only (`ipcRenderer`, `app`) APIs without checking `platform/` guards (`isElectron`, `isRenderer`).
- Do not use `ipcBridge.ts`:
  It is deprecated. Prefer `httpBridge.ts` for transport.
