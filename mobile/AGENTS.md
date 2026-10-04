# M.U.R.A Mobile - Project Guide

## OVERVIEW

Standalone Expo / React Native remote client for iOS and Android. Connects to a running M.U.R.A server (desktop or web-host) over WebSocket + HTTP; does NOT run aioncore or Electron locally.

## STACK

- **Framework**: Expo SDK 55 (`expo`), React Native 0.83.2, React 19
- **Routing**: Expo Router (file-based routing)
- **UI & Lists**: React Native components/styles, `@shopify/flash-list`
- **Networking & Transport**: WebSocket (`src/services/websocket.ts`) + HTTP (`src/services/api.ts`)
- **State & i18n**: React Context, `i18next` / `react-i18next`
- **Explicit exclusions**: NO Electron, NO Arco Design (`@arco-design/web-react`), NO UnoCSS.

## STRUCTURE

```
mobile/
├── app/                  # Expo Router routes (file-based navigation)
│   ├── (tabs)/          # Main tab screens (chat, conversations, files, settings)
│   ├── connect.tsx      # Server connection setup screen
│   └── file-preview.tsx # Remote file preview screen
└── src/
    ├── components/       # UI components (chat/, conversation/, files/, ui/)
    ├── context/          # React contexts (ChatContext, ConversationContext, ConnectionContext, WebSocketContext, WorkspaceContext, FilesTabContext)
    ├── hooks/            # Custom React hooks
    ├── i18n/             # Translation configs and locale dictionaries
    ├── services/         # Network transport (websocket.ts, bridge.ts, api.ts)
    └── utils/            # Helpers (jwt, messageAdapter for server payload transformation)
```

## WHERE TO LOOK

- **Add or modify a screen / route**: `app/` (or `app/(tabs)/`)
- **Server transport / WebSocket messaging**: `src/services/websocket.ts` or `src/services/api.ts`
- **App-wide state management**: `src/context/` (`ChatContext`, `ConnectionContext`, `WebSocketContext`, etc.)
- **Adapt server message shapes for React Native**: `src/utils/messageAdapter.ts`
- **Reusable UI widgets**: `src/components/ui/` or specialized feature folders in `src/components/`

## MOST-EDITED PATHS

- `app/` — Screen navigation and route definitions
- `src/components/` — Screen layout and interaction elements
- `src/services/` — WS/HTTP server communications
- `src/context/` — Global state providers and hooks

## ANTI-PATTERNS

- **Do NOT import desktop code**: Never import from `packages/desktop/` or use Node.js / Electron APIs.
- **Do NOT use desktop UI libraries**: No `@arco-design/web-react`, no UnoCSS utility classes. Use React Native native elements and `StyleSheet`.
- **Do NOT spawn local backends**: This app is strictly a remote client; never attempt to spawn `aioncore` or execute local native binaries.
