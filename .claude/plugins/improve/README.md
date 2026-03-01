# Improvement Team - Agent Pipeline

> **Mission: Make Deployments Boring** 🚀

## Architecture

```
                         ┌─────────────┐
                         │ TEAM LEAD   │  ◄── Orchestrates everything
                         └──────┬──────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
          ▼                     ▼                     ▼
    ┌──────────┐          ┌──────────┐          ┌──────────┐
    │INSPECTOR │          │INSPECTOR │          │INSPECTOR │
    │  (Bugs)  │          │  (Perf)  │          │(Security)│
    └────┬─────┘          └────┬─────┘          └────┬─────┘
         └─────────────────────┼─────────────────────┘
                               │ Issues
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
    ┌──────────┐          ┌──────────┐          ┌──────────┐
    │  FIXER   │          │  FIXER   │          │  FIXER   │
    └────┬─────┘          └────┬─────┘          └────┬─────┘
         └─────────────────────┼─────────────────────┘
                               │ Fixes
                               ▼
                         ┌──────────┐
                         │    QA    │
                         └────┬─────┘
                               │ Approved
                               ▼
                         ┌──────────┐
                         │ SHIPPER  │
                         └──────────┘
```

## Team Members

| Agent | Role | Parallel | Output |
|-------|------|----------|--------|
| **Team Lead** | Orchestrate pipeline, coordinate agents | N/A | Progress & Reports |
| **Inspector** | Find bugs, security, perf issues | ✅ Yes | Issue reports |
| **Fixer** | Implement fixes with tests | ✅ Yes | Fixed code |
| **QA** | Verify fixes are correct | ✅ Yes | APPROVED/REJECTED |
| **Shipper** | Create branch, commits, PR | ⚠️ Sequential | Ready-to-merge PR |

## Pipeline Phases

1. **Discovery** (Parallel) - Multiple inspectors scan code simultaneously
2. **Implementation** (Parallel) - Multiple fixers work on different issues
3. **Verification** (Parallel) - QA reviews multiple fixes
4. **Deployment** (Sequential) - Shipper creates PRs one at a time

## Files

```
agents/improvement_team/
├── README.md
├── team_lead.md       # 🎯 Orchestrator - Coordinates all agents
├── go_inspector.md    # 🔍 Inspector - Finds bugs, security, perf issues
├── fixer.md           # 🔧 Fixer - Implements fixes with tests
├── qa.md              # ✅ QA - Verifies and approves fixes
└── shipper.md         # 🚀 Shipper - Creates branches, PRs, deploys
```

## Quick Start

```bash
# Run the full pipeline
agent run team_lead --target ./internal/ --config pipeline.yaml
```

## Severity Priority

| Severity | Response | Resources |
|----------|----------|-----------|
| 🔴 CRITICAL | Immediate | All available |
| 🟠 HIGH | Same day | 3 parallel fixers |
| 🟡 MEDIUM | This sprint | 2 parallel fixers |
| 🟢 LOW | Backlog | 1 fixer |

