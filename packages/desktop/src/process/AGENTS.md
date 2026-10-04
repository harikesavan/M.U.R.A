# Process Directory (Electron Main Process)

## OVERVIEW
Electron main process managing native OS APIs, window lifecycle, SQLite storage, and launching the native `aioncore` backend. Node.js APIs allowed, DOM APIs forbidden.

## STRUCTURE
```
packages/desktop/src/process/
├── backend/          # Binary resolution and spawning of external aioncore process
├── bridge/           # Native OS IPC bridges (window, dialog, updater, settings)
├── feedback/         # User feedback capture and submission
├── pet/              # Desktop pet widget main-process lifecycle
├── resources/        # Builtin MCP servers and CDP in-app browser control
├── services/         # Main-process services (auto-updater, SQLite DB, skills)
│   └── database/     # SQLite conversation storage, drivers, and schema migrations
├── startup/          # Main-process boot sequence tasks
└── utils/            # Main-process helper utilities (24 misc utilities)
```

Entry points:
- `index.ts`: Process module entry point for internal initialization.
- `../index.ts`: Parent app entry (`src/index.ts`) owning app lifecycle, single-instance lock, backend startup, window management, and `--webui`.

Path aliases:
- `@process/*` -> `src/process/*`
- `@/*` -> `src/*`
- `@common/*` -> `src/common/*`
- `@worker/*` -> `src/process/worker/*`

## WHERE TO LOOK
| Task | Location |
| --- | --- |
| Spawn or resolve `aioncore` backend | `backend/binaryResolver.ts` |
| Add or modify a native IPC bridge | `bridge/` |
| Database schema, migrations, and repositories | `services/database/` |
| Auto-update configuration and feed | `services/autoUpdaterService.ts` |
| In-app browser CDP control | `resources/configureChromium.ts` |

## ANTI-PATTERNS
- Do not use DOM APIs (`window`, `document`) in `src/process/`.
- Do not put business logic or heavy AI tasks in IPC bridges. Bridges handle native OS operations only, while AI work routes via HTTP or WebSocket to `aioncore`.
- Do not add `lead_agent_id` column to `services/database/schema.ts` (see file comments).
- Do not enable `allowPrerelease` in `services/autoUpdaterService.ts`.
- Do not pass `--headless` in `resources/configureChromium.ts`.
- Do not import `drivers/BunSqliteDriver.ts` in production code; it is excluded from `tsconfig` and tested separately via `bun run test:bun`.
