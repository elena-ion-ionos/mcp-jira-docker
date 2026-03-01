Create a Jira ticket based on this description: `$ARGUMENTS`

## Step 1 — Read the templates

Read these three files to understand the available templates:
- `/workspace/.claude/templates/VDC-ticket`
- `/workspace/.claude/templates/S3-ticket`
- `/workspace/.claude/templates/Backup-ticket`

## Step 2 — Select the right template

Choose based on keywords in the phrase:

- **VDC-ticket**: provisioning engine, pStorage, volume, snapshot, DCM, restdcm, VDC, physical storage, virtual data center, cServer, parallel job, migration, placement, GPU, image, contract toggle
- **S3-ticket**: S3, object storage, S3 key, Cloudian, bucket, CORS, s3-mgmt, key management, reseller, object
- **Backup-ticket**: backup, restore, disaster recovery, backup service, backup policy

If unclear, prefer VDC-ticket (it is the most common).

## Step 3 — Infer priority

Analyze the phrase and pick one:

- **Critical (Blocker)**: production outage, data loss, security breach, complete service down, customers cannot provision
- **Major**: performance degradation, provisioning delays, throughput issues, parallel limits, significant bugs, wrong behavior under load
- **Minor**: small improvements, cosmetic changes, nice-to-haves, low-impact cleanup

## Step 4 — Estimate story points

Use the Fibonacci scale:
- **1**: trivial, < half a day
- **2**: small, well-understood, ~1 day
- **3**: moderate complexity, 2–3 days
- **5**: cross-component, ~1 week
- **8**: complex, multiple teams/services, 1–2 weeks
- **13**: major feature, high uncertainty, 2+ weeks

## Step 5 — Generate the ticket content

Using the selected template as structure, generate:
- A concise **Summary** in the format defined by the template
- A **User Story** (As a / I want / so that)
- **Context**: background, current behavior, why the problem exists
- **Acceptance Criteria (SMART)**: Specific, Measurable, Achievable, Relevant, Time-bound

Keep all content factual and grounded in the phrase. Do not invent details.

## Step 6 — Show a preview and ask for confirmation

Print a clear preview of all fields and the generated description. Ask the user:
> "Shall I create this ticket in Jira? (yes / edit first)"

Wait for confirmation before proceeding.

## Step 7 — Create the ticket in Jira

Use the Jira MCP tool `jira_create_issue` with:
- `project_key`: VDC (or S3 / BACKUP depending on selected template)
- `summary`: the generated summary
- `issue_type`: from the template
- `description`: the generated description in Markdown
- `additional_fields` as JSON:
  ```json
  {
    "priority": { "name": "<Critical|Major|Minor>" },
    "labels": ["pre-refined"],
    "customfield_12096": { "value": "Storage Provisioning Development RO" },
    "components": [{ "name": "provisioning-engine" }],
    "story_points": <number>
  }
  ```

After creation, print the ticket key and URL.
