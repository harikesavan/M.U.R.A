# Repository Guidelines

All contributors (human and AI) must follow [CONTRIBUTING.md](CONTRIBUTING.md) ([中文](CONTRIBUTING.zh.md)). Per-area rules: [process](packages/desktop/src/process/AGENTS.md), [renderer](packages/desktop/src/renderer/AGENTS.md), [common](packages/desktop/src/common/AGENTS.md), [mobile](mobile/AGENTS.md). Skills in `.claude/skills/` (`architecture`, `i18n`, `testing`, `bump-version`) are mandatory when their triggers apply.

## Project Overview

Mura is a desktop AI agent workspace: conversations, teams, cron, assistants, MCP, extensions, and a desktop pet. The Electron shell is thin. The AI work runs in **aioncore**, an external Rust binary (repo `iOfficeAI/AionCore`, version pinned by `aioncoreVersion` in the root `package.json`) that runs as a localhost backend. The same renderer SPA ships in three ways: in Electron, as a headless WebUI (`@mura/web-host`, `mura-web` CLI), and as the backend for a separate Expo mobile client (`mobile/`).

## Architecture & Data Flow

```
Renderer (React 19 SPA) ──HTTP/WS──▶ aioncore (127.0.0.1:<port>)
        │  native OS ops only
        ▼
Electron IPC (single channel ADAPTER_BRIDGE_EVENT_KEY) ──▶ process/bridge/*
WebUI: browser ──▶ web-host static server (proxies /api, /ws) ──▶ aioncore
```

- **Backend startup:** `packages/desktop/src/index.ts`
  1. `resolveBinaryPath()` (`process/backend/binaryResolver.ts`) finds the binary: `MURA_BACKEND_BIN`, then `resources/bundled-aioncore/<platform>-<arch>/aioncore`, then PATH.
  2. `BackendLifecycleManager` (`packages/web-host/src/backend-launcher.ts`) spawns it and reads the port from the `AIONCORE_LISTENING{json}` stdout line. Readiness is signalled by `AIONCORE_READY` or by polling `/health`, and the backend is restarted if it crashes.
  3. The preload publishes the port as `window.__backendPort`.
  4. In WebUI `__backendPort` is not set, so `getBaseUrl()` returns `''` (same origin) and web-host proxies the requests.
- **Backend API surface:** `ipcBridge`, exported from `@/common` (`common/adapter/ipcBridge.ts`, ~2500 lines of typed namespaces). Its HTTP endpoints are built with the `httpGet/httpPost/...` and `wsEmitter` factories from `common/adapter/httpBridge.ts`. Usage: `ipcBridge.x.y.invoke(params)`.
  - `common/AGENTS.md` calls `ipcBridge.ts` deprecated, but it is the live surface (77+ importers). Extend it; do not use `renderer/api/createApiClient`, which has no callers.
  - `httpRequest` unwraps the `{success, data}` envelope and retries once after a 401 refresh. Other failures throw `BackendHttpError`; branch with `isBackendHttpError(e) && e.code === '...'`. Use `silentStatuses: [404]` for expected misses.
  - WebSocket: one `/ws` connection with exponential backoff, which emits `realtime.reconnected` after reconnecting.
  - Endpoints the backend doesn't implement yet use `stubProvider` / `stubEmitter`.
- **Native IPC:** declare the call in `ipcBridge.ts`, for example `bridge.buildProvider<Res, Req>('window-controls:minimize')`. Keys are kebab-case, namespaced with `.` or `:`. Implement it in `process/bridge/<domain>Bridge.ts` as `initXBridge()` and register it in `process/bridge/index.ts` → `initAllBridges()`. Never route business logic or AI work through IPC.
- **Extensions:** loaded by aioncore, not by Electron main. The desktop app only calls `/api/extensions/*` (`ipcBridge.extensions`) and listens for the WS event `extensions.state-changed`. Manifest format: `examples/*/aion-extension.json`. For dev and e2e, set `MURA_EXTENSIONS_PATH=examples/`.
- **Settings:** stored in the backend (`/api/settings`, and `/api/settings/client` via `common/config/configService.ts`). Main-process SQLite lives in `process/services/database/`.

## Key Directories

| Path                             | Purpose                                                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `packages/desktop/src/process/`  | Electron main: backend spawn, native bridges, startup, SQLite, pet, updater. No DOM.                                      |
| `packages/desktop/src/preload/`  | `contextBridge` → `window.electronAPI`, plus pet window preloads                                                          |
| `packages/desktop/src/renderer/` | SPA: `pages/{conversation,guid,settings,team,cron,login}`, `components/`, `hooks/`, `services/`, `styles/`. No Node APIs. |
| `packages/desktop/src/common/`   | Process-agnostic: `adapter/` (ipcBridge, httpBridge), `platform/` (bridge, DI), `config/`, `types/`                       |
| `packages/web-host/`             | Headless WebUI host: Node `http`/`net` only, no Express, no Electron. Owns WebUI auth.                                    |
| `packages/web-cli/`              | `mura-web` npm CLI (default port 25808)                                                                                   |
| `packages/shared-scripts/`       | `prepare-aioncore.js`: downloads the backend into `resources/bundled-aioncore/`                                           |
| `mobile/`                        | Expo 55 / RN 0.83 remote client with its own `bun.lock`. Never imports `packages/desktop`.                                |
| `tests/`                         | Vitest `unit/`, `integration/`, Playwright `e2e/`, `fixtures/`                                                            |
| `scripts/`                       | Build, release, WebUI, i18n, smoke, and benchmark scripts. `scripts/README.md` is stale.                                  |
| `examples/`                      | Sample extensions (also used as e2e fixtures)                                                                             |

## Development Commands

```bash
bun install                      # also runs scripts/postinstall.js (electron-builder install-app-deps)
bun run start                    # electron-vite dev (renderer on :5173)
bun run webui                    # headless WebUI on :25809; builds first unless --no-build / MURA_NO_BUILD=1
bun run package                  # electron-vite build → out/{main,preload,renderer}
bun run dist:mac                 # full installer via scripts/build-with-builder.js (also dist:win, dist:linux, build-mac:arm64, …)
bun run lint:fix && bun run format
bunx tsc --noEmit                # there is no typecheck script
bun run i18n:types && node scripts/check-i18n.js   # run in this order
just check                       # lint + fmt-check + typecheck + i18n-check
just push                        # pre-push gate, then git push (the only allowed way to push)
```

Builds use `NODE_OPTIONS=--max-old-space-size=8192`. The aioncore version is resolved as `MURA_BACKEND_RUN_ID` > `MURA_BACKEND_VERSION` > `package.json` `aioncoreVersion` > latest. When running from source, aioncore must be on PATH or provided through `MURA_BACKEND_BIN`.

## Code Conventions & Common Patterns

- **Formatting (oxfmt, same as `.prettierrc.json`):** single quotes (JSX too), semicolons, 2 spaces, width 120, `trailingComma: es5`, LF. Short single-element arrays stay inline.
- **Lint (oxlint)** errors: `consistent-type-imports` (use `import type`), `no-floating-promises`, `no-await-thenable`. For fire-and-forget calls write `void promise.catch(...)`. Prefix unused params with `_`. Prefer `type` over `interface`. Strict TypeScript, no `any`.
- **Naming:** components PascalCase (`Button.tsx`); hooks `useX.ts`; utils, types and constants camelCase files, with UPPER_SNAKE_CASE values. Main-process files: `<domain>Bridge.ts`, `<Name>Service.ts`, `I<Name>Service.ts`, `<Name>Repository.ts`. Renderer feature directories are PascalCase; categorical and route directories are lowercase.
- **Structure:**
  - At most 10 direct children per directory, and no single-file directories.
  - A component becomes `Name/index.tsx` once it has private parts.
  - Code starts page-private under `pages/<Page>/` and moves to shared once a second consumer exists. See `docs/contributing/file-structure.md`, which uses stale `src/` paths: the real root is `packages/desktop/src/`.
- **Path aliases:** `@/*` → `packages/desktop/src/*`, `@process/*`, `@renderer/*`, `@worker/*`. `@common` is defined only in the vite config; prefer `@/common/...`.
- **UI:**
  - Components: `@arco-design/web-react` only, never raw `<button>`, `<input>`, `<select>` and similar.
  - Icons: `@icon-park/react`.
  - Styling: UnoCSS utilities with semantic tokens from `uno.config.ts`, or CSS variables. No hex/rgb outside the theme presets, and no inline `style` unless the value is computed.
  - Complex styles go in `Name.module.css`; component-level Arco overrides use `:global()` inside it. Global Arco overrides go in `renderer/styles/arco-override.css`.
- **State and data:** React Context lives in `renderer/hooks/context/` (Auth, Theme, Conversation, Layout, …). There is no zustand. Fetch with SWR, e.g. `useSWR(key, () => ipcBridge.mode.listProviders.invoke())`. Cross-component events use the typed eventemitter3 bus in `renderer/utils/emitter.ts`. Guard Electron-only code with `isElectronDesktop()` (`renderer/utils/platform.ts`).
- **DI:** platform services are registered with `registerPlatformServices` and read with `getPlatformServices()` (`common/platform/index.ts`, `IPlatformServices`). In services, keep pure logic separate from IO and inject dependencies.
- **Logging:** tag messages, e.g. `console.debug('[httpBridge] …')`. In main, `console` is redirected to electron-log. Sentry runs in both main and renderer.
- **i18n:** all user-facing text uses `useTranslation()` → `t('module.key')`.
  - Locales: `renderer/services/i18n/locales/<lang>/<module>.json`. There are 13 languages; the reference language is `en-US`.
  - Languages and modules are defined in `common/config/i18n-config.json`.
  - Add every key to every locale. Never hand-edit the generated `i18n-keys.d.ts`.
  - A new module needs a config entry, a JSON file in each locale, and an export in each locale's `index.ts`.

## Important Files

- Entry points:
  - Main: `packages/desktop/src/index.ts` → `process/index.ts` (`initializeProcess`)
  - Preload: `preload/main.ts`
  - Renderer: `renderer/main.tsx`; routing in `renderer/components/layout/Router.tsx` (HashRouter with lazy routes)
  - WebUI: `scripts/webui.ts` → `packages/web-host/src/index.ts` (`startWebHost`)
- Build:
  - `packages/desktop/electron.vite.config.ts`: keep all React-coupled vendors in the single `vendor` chunk, because splitting them caused a white screen. Don't add `@lezer/common` to `dedupe`.
  - `packages/desktop/electron-builder.yml`: builtin MCP servers must stay in `asarUnpack`.
  - `scripts/build-with-builder.js`
- Config: `package.json` (the only real app version; `packages/desktop/package.json` is a 0.0.0 placeholder), `tsconfig.json`, `vitest.config.ts`, `playwright.config.ts`, `uno.config.ts`, `.oxlintrc.json`, `.oxfmtrc.json`, `.pre-commit-config.yaml`, `justfile`.
- Stale files, don't trust them: `Dockerfile`, `docs/contributing/development.md` (both reference build scripts that don't exist), `scripts/README.md`, `.gemini/styleguide.md`.

## Runtime/Tooling Preferences

- **Bun** is the package manager and script runner (`bun install`, `bun run`, `bunx`). Use Node 22 (`engines`: `>=22 <25`). Never use npm or yarn lockfiles.
- Electron ^37, electron-vite 5 / Vite 6, electron-builder 26, Vitest 4, Playwright, oxlint/oxfmt, and prek for the CI-equivalent hooks (`prek run --from-ref origin/main --to-ref HEAD`).
- `better-sqlite3` must be rebuilt for Electron (`just setup` / `just rebuild-native`, which need pwsh). `BunSqliteDriver.ts` is test-only (`bun run test:bun`); never import it in production code.
- Don't set `ELECTRON_MIRROR` in `.npmrc`. `patches/7zip-bin@5.2.0.patch` is applied through Bun `patchedDependencies`.

## Testing & QA

- **Vitest projects** (`vitest.config.ts`):
  - `node`: `tests/{unit,integration}/**/*.test.ts` and `packages/web-host/src/**/*.test.ts`. Setup: `tests/vitest.setup.ts`.
  - `dom` (jsdom): only files with the `.dom.test.ts(x)` infix under `tests/unit/`. Setup: `tests/vitest.dom.setup.ts`.
  - Tests colocated under `packages/desktop/src` **don't run**. Put them in `tests/unit/<area>/<name>.test.ts`.
- **Commands:**
  - All tests: `bun run test`.
  - One file: `bunx vitest run tests/unit/chat/turnCopy.test.ts`.
  - One project: `--project dom`.
  - Coverage: `bun run test:coverage`.
  - web-host's own tests: `cd packages/web-host && bun run test`.
  - Mobile (Jest): `cd mobile && bun run test`.
- **Mocking:**
  - Backend: `vi.mock('@/common/adapter/httpBridge', () => mock.asModule())`, with `mock = createMockHttpBridge()` from `tests/unit/_helpers/mockHttpBridge.ts` (`onGet`, `emit`, `calls`, `reset`). Its API is frozen; don't change its signatures.
  - i18n: `vi.mock('react-i18next', …)` returning `t: (k) => k`.
  - Electron: `window.electronAPI` is already stubbed in the setup files.
- **E2E** (`bun run test:e2e`, specs `tests/e2e/**/*.e2e.ts`):
  - Runs against the built Electron app only, so run `bun run package` first, and `aioncore` must be on PATH.
  - Single worker; import `test` and `expect` from `tests/e2e/fixtures`.
- **Expectations:**
  - Coverage target is ≥80%, but the thresholds in config are 0 and Codecov is informational.
  - Every behavior change or bug fix needs a behavior-named test, and every `describe` needs a failure path.
  - CI runs `prek` plus vitest on Linux, macOS and Windows, and builds for 3 platforms.

## Workflow Rules

- **Hard blockers:** process-boundary violations, TypeScript errors, failing tests, unsafe IPC, missing i18n, and raw interactive HTML in new UI.
- **Ratchet rule:** don't make existing directory-size violations worse. No scope expansion into cleanup unless asked.
- **Commits:** `<type>(<scope>): <subject>`. The hook runs with `--force-scope`, so **a scope is required**. Types: `feat`, `fix`, `perf`, `refactor`, `docs`, `style`, `chore`, `test`, `ci`, `build`, `revert`. One feature or fix per PR. Fill in `.github/pull_request_template.md` honestly.
- **Never:** add AI signatures (Co-Authored-By, …); push unless explicitly asked; push with plain `git push` (use `just push`, and judge lint by exit code since warnings are expected); commit anything under `docs/superpowers/` (gitignored).
