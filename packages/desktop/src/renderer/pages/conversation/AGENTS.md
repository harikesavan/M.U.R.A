# Conversation agent guide

## Overview

Main chat screen and entry point for M.U.R.A (`index.tsx`). Manages chat UI, runtime dispatching, side panels, and message rendering.

## Structure

```
conversation/
├── index.tsx              Entry point for conversation page
├── components/            Shared conversation UI components
├── explorer/              File explorer panel for session workspace
├── GroupedHistory/        Chat history grouping by date or session
├── hooks/                 Conversation state and session hooks
├── Messages/              Message list container and message renderers
│   └── components/        Per-message-type renderers
├── PlanBar/               Agent execution plan progress bar
├── platforms/             Runtime-specific chat view routing
│   ├── acp/               AcpChat.tsx for external CLI agents via ACP
│   └── aionrs/            AionrsChat.tsx for built-in aioncore agent
├── Preview/               Multi-format file preview panel
├── runtime/               Runtime context and session connection logic
├── SourceControl/         Git-style workspace source control panel
└── utils/                 Conversation formatting and helper utilities
```

Key concept: platform split in `platforms/` routes chat rendering based on agent runtime. External CLI agents (Claude Code, Gemini CLI, Codex, Qwen, OpenCode, OpenClaw) connect via ACP in `acp/AcpChat.tsx`. The built-in agent running inside `aioncore` renders through `aionrs/AionrsChat.tsx`.

`Preview/` supports live preview for PDF, Word, Excel, PPT, code, Markdown, images, HTML, and git diffs alongside active chat sessions.

## Where to look

| Task | Location |
|---|---|
| Add a message-type renderer | `Messages/components/` |
| Support a new agent chat runtime | `platforms/` |
| File preview panel features | `Preview/` |
| Plan bar visualization | `PlanBar/` |
| Chat history grouping | `GroupedHistory/` |
| Workspace source control view | `SourceControl/` |
| Session workspace file tree | `explorer/` |
