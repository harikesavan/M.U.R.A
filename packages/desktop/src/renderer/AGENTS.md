# AGENTS.md: Renderer Process (`packages/desktop/src/renderer/`)

## OVERVIEW
React 19 SPA entry point (`main.tsx`, `index.html`) routed via `react-router-dom` v7.
Runs inside Electron desktop shell, headless webui (`bun run webui`), and mobile host.

## STRUCTURE
```
api/          # HTTP REST + WebSocket client for aioncore (client.ts, index.ts, types.ts)
pages/        # Route screens: conversation/ (has child AGENTS.md), cron/, guid/, login/, settings/, team/, TestShowcase.tsx
components/   # Shared UI: agent/, base/, chat/, layout/, Markdown/, media/, settings/, workspace/, IconParkHOC.tsx, ShimmerText.tsx
hooks/        # Custom hooks: agent/, assistant/, chat/, config/, context/, file/, mcp/, system/, ui/
services/     # App services: bootstrapRenderer.ts, FileService.ts, PasteService.ts, SpeechToTextService.ts, i18n/, feedback/, runtime/, speech/
theme/        # builtinThemes.ts and color token wiring (pairs with root uno.config.ts)
styles/       # Global styles only, including arco-override.css
utils/        # Helpers: chat/, file/, model/ (agentTypes.ts, agentRuntimeCatalog.ts), theme/, ui/, workspace/, navigation.ts, platform.ts
```

## WHERE TO LOOK
- **Call the backend**: `api/` (HTTP/WS client wrappers to `aioncore`).
- **Add a page or route**: Create screen under `pages/` and register route in router.
- **Add a settings panel**: `pages/settings/` (`SettingsModal/contents`, `ModelModalContent`, `AgentSettings`, channels).
- **Add or adjust a theme**: `theme/builtinThemes.ts` paired with root `uno.config.ts` color tokens.
- **Global vs scoped styles**: `styles/arco-override.css` for global Arco overrides; CSS Modules for component scopes.
- **Agent-type catalog**: `utils/model/agentTypes.ts` and `utils/model/agentRuntimeCatalog.ts`.

## CONVENTIONS
- **Path aliases**: `@renderer/*` -> `packages/desktop/src/renderer/`, `@/*` -> `src/*`, `@common/*` -> `src/common/`.
- **Icon wrapping**: `@icon-park/react` imports auto-wrap via `electron.vite` iconParkPlugin using `components/IconParkHOC.tsx`.
- **Host portability**: Code must run in Electron, web-host, and mobile. Guard Electron-only bridge calls with `isElectron` from `utils/platform.ts`.
- **i18n validation gate**: When modifying `renderer/`, `locales/`, or i18n configs, run:
  ```bash
  bun run i18n:types
  node scripts/check-i18n.js
  ```

## ANTI-PATTERNS
- **No Node.js APIs**: Do not import `fs`, `path`, `child_process`, or Node.js modules in renderer code.
- **No IPC for business logic**: Do not route AI or backend requests through Electron IPC; use `api/` over HTTP/WS to `aioncore`.
- **Do not assume Electron runtime**: Guard desktop-only APIs using platform helpers; handle web and mobile fallback paths cleanly.
