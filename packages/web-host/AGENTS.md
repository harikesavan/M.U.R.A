# @mura/web-host

## OVERVIEW
Headless host package that serves the M.U.R.A renderer SPA over HTTP without Electron.
Proxies API and WebSocket calls to the native aioncore backend for WebUI and remote access.
Invoked by root `bun run webui` (scripts/webui.ts) and wrapped by `packages/web-cli`.
Also owns WebUI auth (bcrypt password reset/change/verify + session). Entry: `startWebHost()`.
Status: M3 skeleton — some implementations are placeholders that throw `not implemented yet`; check before assuming a path is wired.

## STRUCTURE
- `src/static-server.ts`: Serves compiled SPA static assets and reverse-proxies `/api`, `/ws`, and `/api/stt/stream` to backend.
- `src/backend-launcher.ts`: Spawns the aioncore native binary shared with the desktop application.
- `src/agent-process-registry.ts`: Tracks spawned agent process PIDs, process lifecycles, and orphan cleanup.
- `src/index.ts`: Main entry point for web-host initialization and server startup routines.
- `src/types.ts`: TypeScript type definitions for host configuration, launcher options, and process state.

## WHERE TO LOOK
- SPA static asset serving or reverse proxying (`/api`, `/ws`, `/api/stt/stream`):
  `src/static-server.ts`
- Spawning and managing aioncore native backend process:
  `src/backend-launcher.ts`
- Agent PID tracking, process lifecycle monitoring, and orphan process cleanup:
  `src/agent-process-registry.ts`
- Server startup and package exports:
  `src/index.ts`
- Server options and registry types:
  `src/types.ts`

## ANTI-PATTERNS
- No Express: use Node native `http` and `net` modules exclusively.
- No Electron APIs: this package is the headless host runner without desktop process bindings.
- Do not duplicate renderer code: web-host strictly serves the build output from `packages/desktop`.
