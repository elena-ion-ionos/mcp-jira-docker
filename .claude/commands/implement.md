---
description: Run the full ticket workflow (inspect → implement → QA → refactor-review) for a Jira ticket
argument-hint: <TICKET-ID> [--phase inspect|implement|qa|review]
---

# Implement

You are orchestrating a full development workflow for a Jira ticket. You will fetch the ticket, route it to the correct project, then sequentially run four specialized agents: **Inspect → Implement → QA → Refactor Review**.

Ticket ID (and optional phase flag): $ARGUMENTS

---

## Step 1: Parse Arguments

Extract the ticket ID from `$ARGUMENTS`. If a `--phase` flag is present (e.g., `VDC-123 --phase qa`), note which single phase to run; otherwise run all four phases.

---

## Step 2: Fetch the Jira Ticket

Use the `mcp__atlassian-local__jira_get_issue` tool with the ticket ID. Retrieve:
- Summary, description, acceptance criteria
- Labels, components, fix versions
- Issue type (Bug, Story, Task, Story, etc.)
- Status and assignee

If the ticket cannot be fetched, report the error clearly and stop.

---

## Step 3: Route to the Correct Project

Routing is based on the ticket's **components** field first, then **labels** as fallback, then the **project key prefix** as a last resort.

### Primary routing — by component

| Component value           | Domain    | Project Path                         |
|---------------------------|-----------|--------------------------------------|
| `backup-service`          | backup    | `/workspace/backup-service`          |
| `s3-key-management-service` | s3      | `/workspace/platform-s3-rest`        |
| `provisioning-engine`     | vdc       | `/workspace/platform-vdc`            |

### Secondary routing — by label

| Label                     | Domain    | Project Path                         |
|---------------------------|-----------|--------------------------------------|
| `Backup`                  | backup    | `/workspace/backup-service`          |
| `s3-key-management-service` | s3      | `/workspace/platform-s3-rest`        |

### Fallback routing — by project key prefix

| Key prefix                        | Domain    | Project Path                         |
|-----------------------------------|-----------|--------------------------------------|
| `VDC`, `PLATDC`                   | vdc       | `/workspace/platform-vdc`            |
| `S3`, `PLATS3`, `OBJSTG`, `S3REST`| s3        | `/workspace/platform-s3-rest`        |
| `DEPLOY`, `PLATS3D`               | s3-deploy | `/workspace/platform-s3-deployment`  |
| `BKP`, `BACKUP`, `PLATBKP`        | backup    | `/workspace/backup-service`          |

If routing is still ambiguous, run `ls /workspace` and ask the user to confirm the target directory before proceeding.

Verify the resolved project path exists. If it doesn't, warn the user and ask if they want to continue with a different path.

Store this as `PROJECT_PATH` and `DOMAIN` for the rest of the workflow.

---

## Step 4: Create a Todo List

Use `TodoWrite` to create a checklist for all phases:
- [ ] Phase 1 - Inspect: Analyze ticket and codebase
- [ ] Phase 2 - Implement: Apply changes to `PROJECT_PATH`
- [ ] Phase 3 - QA: Write and run tests, verify acceptance criteria
- [ ] Phase 4 - Refactor Review: Code quality and consistency check

---

## Phase 1: Inspect

**Goal**: Deep-dive into the ticket requirements and the relevant codebase.

Use the Task tool to launch the `ticket-inspector` agent with this prompt:

```
Ticket ID: {TICKET_ID}
Project path: {PROJECT_PATH}
Domain: {DOMAIN}

Ticket summary: {TICKET_SUMMARY}

Full ticket details:
{FULL_TICKET_JSON}

Analyze this ticket and the codebase at {PROJECT_PATH}. Produce a structured inspection report covering:
1. Requirement breakdown and acceptance criteria
2. Relevant files and entry points identified
3. Suggested implementation approach with specific file changes
4. Risks, edge cases, and open questions
```

After the agent returns, **read all key files it identifies** to build your own understanding before implementing.

Mark "Phase 1 - Inspect" as complete in the todo list.

---

## Phase 2: Implement

**Goal**: Apply the changes described in the inspection report.

Wait for Phase 1 to complete. Then use the Task tool to launch the `ticket-implementer` agent with this prompt:

```
Ticket ID: {TICKET_ID}
Project path: {PROJECT_PATH}
Domain: {DOMAIN}

Inspection report from Phase 1:
{INSPECTOR_OUTPUT}

Implement the changes for this ticket in the project at {PROJECT_PATH}. Follow the project's existing conventions and patterns strictly. Make only changes required by the ticket.
```

After the agent returns, review its summary of changed files.

Mark "Phase 2 - Implement" as complete in the todo list.

---

## Phase 3: QA

**Goal**: Verify the implementation against the acceptance criteria with tests.

Wait for Phase 2 to complete. Then use the Task tool to launch the `ticket-qa` agent with this prompt:

```
Ticket ID: {TICKET_ID}
Project path: {PROJECT_PATH}
Domain: {DOMAIN}

Ticket acceptance criteria:
{ACCEPTANCE_CRITERIA}

Implementation summary from Phase 2:
{IMPLEMENTER_OUTPUT}

Verify the implementation:
1. Run the existing test suite and report results
2. Write new tests for the changed code
3. Verify each acceptance criterion is met
4. Run linters/formatters
```

After the agent returns, review its QA report.

Mark "Phase 3 - QA" as complete in the todo list.

---

## Phase 4: Refactor Review

**Goal**: Code quality, consistency, and refactoring suggestions.

Wait for Phase 3 to complete. Then use the Task tool to launch the `ticket-refactor-reviewer` agent with this prompt:

```
Ticket ID: {TICKET_ID}
Project path: {PROJECT_PATH}
Domain: {DOMAIN}

Inspection report:
{INSPECTOR_OUTPUT}

Implementation summary:
{IMPLEMENTER_OUTPUT}

QA report:
{QA_OUTPUT}

Review all changes made for this ticket. Focus on: code duplication, naming consistency, architectural fit, simplification opportunities, and adherence to project conventions.
```

Mark "Phase 4 - Refactor Review" as complete in the todo list.

---

## Final Summary

After all phases complete (or after a single phase if `--phase` was specified), present a consolidated summary:

```
## Implement Complete: {TICKET_ID}

**Project**: {PROJECT_PATH}
**Domain**: {DOMAIN}

### Inspection Findings
{KEY_FINDINGS}

### Changes Implemented
{CHANGED_FILES}

### QA Results
{TEST_RESULTS}

### Refactor Recommendations
{REVIEW_FINDINGS}

### Next Steps
{SUGGESTED_NEXT_STEPS}
```

If any phase produced critical issues (failing tests, blockers from the review), highlight them prominently and ask the user how to proceed.

---

## Changed Files

After the final summary, run:

```bash
git -C {PROJECT_PATH} diff HEAD
```

If the output is empty (changes are staged or committed), try:

```bash
git -C {PROJECT_PATH} diff
git -C {PROJECT_PATH} diff --cached
```

Display the full diff output exactly as returned, formatted in a code block with `diff` syntax highlighting. This gives the user a "committed changes" view of every line added or removed across all modified files.
