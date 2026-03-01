# implement

A Claude Code plugin that runs a full four-phase development workflow for Jira tickets targeting the platform projects (VDC, S3, Backup).

## Phases

| Phase | Agent | What It Does |
|-------|-------|--------------|
| 1. Inspect | `ticket-inspector` | Fetches the ticket, explores the codebase, identifies affected files, and produces an implementation plan |
| 2. Implement | `ticket-implementer` | Applies the changes following project conventions |
| 3. QA | `ticket-qa` | Runs tests, writes missing tests, verifies acceptance criteria, runs linters |
| 4. Refactor Review | `ticket-refactor-reviewer` | Reviews code quality, naming, duplication, architecture fit, and gives a merge recommendation |

## Usage

```bash
# Run the full workflow
/implement VDC-1234

# Run a single phase
/implement VDC-1234 --phase inspect
/implement VDC-1234 --phase implement
/implement VDC-1234 --phase qa
/implement VDC-1234 --phase review
```

## Project Routing

Routing resolves in priority order: **component → label → key prefix**.

| Component / Label / Key Prefix | Domain | Path |
|--------------------------------|--------|------|
| component: `backup-service` / label: `Backup` | backup | `/workspace/backup-service` |
| component: `s3-key-management-service` | s3 | `/workspace/platform-s3-rest` |
| component: `provisioning-engine` | vdc | `/workspace/platform-vdc` |
| key prefix: `DEPLOY`, `PLATS3D` | s3-deploy | `/workspace/platform-s3-deployment` |

## Project Conventions Summary

| Project | Language | Build | Test | Lint |
|---------|----------|-------|------|------|
| `backup-service` | Java 25 / Spring Boot | `./mvnw clean package -DskipTests` | `./mvnw test` | `./mvnw checkstyle:check` |
| `platform-s3-rest` | Go | `go build ./...` | `go test ./...` | `gofmt`, `go vet` |
| `platform-s3-deployment` | Helm/YAML | `helm lint` | — | — |

## Requirements

- Jira MCP server running (see workspace README for setup)
- Target project must be present in `/workspace/`
