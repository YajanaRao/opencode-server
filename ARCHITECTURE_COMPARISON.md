# Nanoclaw vs OpenCode-Server - Architecture Comparison

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         NANOCLAW ARCHITECTURE                            │
│                    (WhatsApp AI Assistant with Scheduling)               │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   WhatsApp User  │
│  "Sends message" │
└────────┬─────────┘
         │ @Andy schedule a daily report at 9am
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Main Node.js Process                             │
│                                                                          │
│  ┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐  │
│  │  WhatsApp I/O   │───▶│  Message Queue   │───▶│  Container Agent │  │
│  │  (Baileys)      │    │  (GroupQueue)    │    │  (Claude SDK)    │  │
│  └─────────────────┘    └──────────────────┘    └──────────────────┘  │
│                                                           │               │
│  ┌─────────────────┐    ┌──────────────────┐           │               │
│  │  SQLite DB      │◀───│ Task Scheduler   │◀──────────┘               │
│  │  - Tasks        │    │  (Polls every    │                            │
│  │  - History      │    │   60 seconds)    │                            │
│  │  - Sessions     │    └──────────────────┘                            │
│  └─────────────────┘                                                     │
│                                                                          │
│                         ┌────────────────────────┐                      │
│                         │ Container Process      │                      │
│                         │ ┌────────────────────┐ │                      │
│                         │ │ MCP Tools          │ │                      │
│                         │ │ - schedule_task    │ │                      │
│                         │ │ - list_tasks       │ │                      │
│                         │ │ - pause_task       │ │                      │
│                         │ │ - send_message     │ │                      │
│                         │ └────────────────────┘ │                      │
│                         │         │              │                      │
│                         │         ▼              │                      │
│                         │ ┌────────────────────┐ │                      │
│                         │ │ IPC Files          │ │                      │
│                         │ │ /workspace/ipc/    │ │                      │
│                         │ │ ├── messages/      │ │                      │
│                         │ │ └── tasks/         │ │                      │
│                         │ └────────────────────┘ │                      │
│                         └────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│   WhatsApp User  │
│ "Receives reply" │
└──────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                    OPENCODE-SERVER ARCHITECTURE                          │
│                 (Web-Based Coding Tool Deployment)                       │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   Web Browser    │
│  "Sends request" │
└────────┬─────────┘
         │ HTTP POST to /api/session
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Render.com                                      │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                     Docker Container                               │ │
│  │                                                                    │ │
│  │  ┌──────────────────┐                                             │ │
│  │  │  HTTP Server     │                                             │ │
│  │  │  (Port 10000)    │                                             │ │
│  │  └────────┬─────────┘                                             │ │
│  │           │                                                        │ │
│  │           ▼                                                        │ │
│  │  ┌──────────────────┐                                             │ │
│  │  │  OpenCode CLI    │                                             │ │
│  │  │  (npm package)   │                                             │ │
│  │  │                  │                                             │ │
│  │  │  - No database   │                                             │ │
│  │  │  - No scheduler  │                                             │ │
│  │  │  - No messaging  │                                             │ │
│  │  │  - Ephemeral     │                                             │ │
│  │  └──────────────────┘                                             │ │
│  │                                                                    │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  Note: Container restarts lose all state (free tier)                    │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│   Web Browser    │
│ "Receives reply" │
└──────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                          KEY DIFFERENCES                                 │
└─────────────────────────────────────────────────────────────────────────┘

┌───────────────────┬───────────────────────┬──────────────────────────┐
│     Feature       │      Nanoclaw         │    OpenCode-Server       │
├───────────────────┼───────────────────────┼──────────────────────────┤
│ Purpose           │ Chat assistant        │ Web coding tool          │
│ Interface         │ WhatsApp              │ HTTP/Web browser         │
│ Architecture      │ Custom Node.js app    │ CLI wrapper in Docker    │
│ Persistence       │ SQLite database       │ None (ephemeral)         │
│ Scheduled Tasks   │ ✅ Built-in           │ ❌ Not applicable        │
│ Messaging         │ ✅ WhatsApp           │ ❌ HTTP only             │
│ Long-running      │ ✅ Always on          │ ❌ Sleeps after 15 min   │
│ Extensibility     │ ✅ Full control       │ ❌ Limited to CLI        │
│ State Management  │ ✅ Persistent         │ ❌ Lost on restart       │
│ Proactive Actions │ ✅ Can initiate       │ ❌ Request/response only │
└───────────────────┴───────────────────────┴──────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│              HOW SCHEDULED TASKS WORK IN NANOCLAW                        │
└─────────────────────────────────────────────────────────────────────────┘

Timeline of a Scheduled Task:

T+0s: User creates task
  │
  ├──▶ "@Andy remind me about standup every weekday at 8:45am"
  │
  ▼
T+1s: Agent processes request
  │
  ├──▶ Calls schedule_task MCP tool
  │    - prompt: "Remind about standup"
  │    - schedule_type: "cron"
  │    - schedule_value: "45 8 * * 1-5"
  │
  ▼
T+2s: IPC file written
  │
  ├──▶ /workspace/ipc/tasks/1234567890-abc123.json
  │
  ▼
T+3s: Host processes IPC
  │
  ├──▶ Reads IPC file
  ├──▶ Creates database entry
  ├──▶ Calculates next_run: "2026-02-24T08:45:00"
  │
  ▼
[Time passes... scheduler polls every 60s]
  │
  ▼
Next day 8:45am: Task becomes due
  │
  ├──▶ Scheduler finds: next_run <= NOW AND status = 'active'
  ├──▶ Enqueues task in GroupQueue
  │
  ▼
8:45:30am: Task executes
  │
  ├──▶ Runs agent in container
  ├──▶ Agent executes prompt
  ├──▶ Result sent via WhatsApp
  ├──▶ Logs execution (duration, status, result)
  ├──▶ Calculates next_run: "2026-02-25T08:45:00"
  │
  ▼
Next weekday: Repeats...


┌─────────────────────────────────────────────────────────────────────────┐
│         ALTERNATIVE: SCHEDULED TASKS FOR OPENCODE (External)             │
└─────────────────────────────────────────────────────────────────────────┘

Option 1: GitHub Actions
┌──────────────────────────────────────┐
│ .github/workflows/scheduled-task.yml │
│                                      │
│ on:                                  │
│   schedule:                          │
│     - cron: '0 9 * * *'             │
│                                      │
│ jobs:                                │
│   run:                               │
│     steps:                           │
│       - run: npx opencode-ai "..."  │
└──────────────────────────────────────┘
         │
         ▼
    Runs daily at 9 AM
    (GitHub's infrastructure)


Option 2: External Cron Service
┌──────────────────┐
│  cron-job.org    │
│                  │
│  Schedule:       │
│  0 9 * * *      │
│                  │
│  URL:            │
│  POST to         │
│  OpenCode API    │
└────────┬─────────┘
         │
         ▼
┌────────────────────┐
│ OpenCode-Server    │
│ Processes request  │
└────────────────────┘


Option 3: Cloud Function
┌──────────────────┐
│ AWS Lambda /     │
│ Cloud Function   │
│                  │
│ Trigger:         │
│ EventBridge      │
│ (cron schedule)  │
│                  │
│ Action:          │
│ Call OpenCode    │
└────────┬─────────┘
         │
         ▼
┌────────────────────┐
│ OpenCode-Server    │
│ Processes request  │
└────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                           RECOMMENDATION                                 │
└─────────────────────────────────────────────────────────────────────────┘

For OpenCode Users:
  ✅ Use external schedulers (GitHub Actions recommended)
  ✅ Keep OpenCode-Server simple and stateless
  ✅ Leverage existing scheduling infrastructure

For Nanoclaw-like Functionality:
  ✅ Fork nanoclaw and customize
  ✅ Build on the existing implementation
  ✅ Benefit from production-tested code

For Building Similar Systems:
  ✅ Study nanoclaw's architecture
  ✅ Use cron-parser for flexibility
  ✅ Implement proper error handling
  ✅ Log all task executions
  ✅ Support multiple schedule types
