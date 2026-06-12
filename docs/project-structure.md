# Project Structure

A quick reference for what every file in this repo does.

---

## Root

| File / Folder | Purpose |
|---|---|
| `docker-compose.yml` | Defines and wires all services: n8n, Ollama, and PostgreSQL. Run `docker compose up -d` to start everything. |
| `workflow.json` | The n8n workflow. Import this into n8n after the stack is running. It contains the full automation logic. |
| `postman_collection.json` | Ready-to-use test requests for the workflow. See below. |
| `.env.example` | Template with all required environment variables and explanations. Copy to `.env` and fill in your values. |
| `.env` | Your actual secrets and config. Not committed to git. |
| `.gitignore` | Tells git to ignore `.env`, local data folders, and OS files. |

## init-db/

| File | Purpose |
|---|---|
| `01-schema.sql` | SQL script that creates the `sales.call_records` table inside PostgreSQL. Runs automatically the first time the database container starts. |

## scripts/

| File | Purpose |
|---|---|
| `generate-secrets.sh` | Generates a random PostgreSQL password and n8n encryption key, then writes them to `.env`. Run this instead of filling in the secrets manually. |

## docs/

| File | Purpose |
|---|---|
| `technical.md` | Step-by-step setup guide: prerequisites, how to start the stack, how to import the workflow, and how to configure credentials. |
| `project-structure.md` | This file. |

---

## Postman collection

`postman_collection.json` contains 4 test requests that cover the two main paths of the workflow:

**Happy path — complete transcripts**
- `Clean transcript - Brightline Electric` — a clear call with a company name, contact, and a specific order (40 wireless dimmers + wall stations). Should extract cleanly and trigger the approval email.
- `Clean transcript - Apex Construction` — similar clean case with a different company and order details.

**Error path — incomplete transcripts**
- `Messy transcript - Danny (no company)` — a vague call where the caller only gives a first name and no company. Should trigger the "insufficient data" email instead of the approval flow.
- `Messy transcript - no name, no company` — an extremely vague call with no identifiable information. Also triggers the error path.

To use: import the file into Postman (or any API client) and send requests after the stack is running and the workflow is active.
