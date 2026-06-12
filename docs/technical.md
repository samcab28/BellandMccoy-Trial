# Bell & McCoy — Sales Call Automation (Trial)

An n8n workflow that receives a sales call transcript, extracts key information using a local AI model, and saves the record to a database after human approval.

Everything runs locally in Docker — no external APIs or paid services required.

## What the workflow does

1. Receives a transcript via a POST webhook
2. Sends it to a local AI model (`llama3.2:3b`) for structured extraction
3. Extracts: company name, contact name, summary, action items, order intent
4. If key data is missing → sends a notification email and stops
5. If data is complete → sends an approval email with **Approve / Reject** buttons
6. On approval → saves the record to PostgreSQL
7. On rejection → discards the record

## Stack

| Service    | Purpose                        |
|------------|--------------------------------|
| n8n        | Workflow engine (port 5678)    |
| Ollama     | Local AI model runner          |
| PostgreSQL | Stores approved call records   |

## Setup

**Prerequisites:** Docker with the Compose plugin, ~4 GB RAM, ~4 GB disk.

```bash
# 1. Generate secrets
./scripts/generate-secrets.sh

# 2. Start everything
docker compose up -d

# 3. Wait for the AI model to download (first run only)
docker compose logs -f ollama-pull

# 4. Open n8n and create your account
open http://localhost:5678
```

On first launch n8n will ask you to create a local admin account. Then import `workflow.json` to load the workflow.

## Import the workflow

In n8n: **Settings → Import from file** → select `workflow.json`.

You will need to configure two credentials inside n8n:
- **Postgres** — use the same credentials as in your `.env`
- **SMTP** — your email account for sending approval emails

## Configuration

All settings are in `.env` (copied from `.env.example`).

| Variable             | Description                                  |
|----------------------|----------------------------------------------|
| `POSTGRES_*`         | Database credentials                         |
| `OLLAMA_MODEL`       | AI model to use (default: `llama3.2:3b`)     |
| `N8N_ENCRYPTION_KEY` | Key used to encrypt n8n credentials          |
| `WEBHOOK_URL`        | URL n8n uses for webhooks (change if tunneling) |

## Useful commands

```bash
docker compose ps               # check service status
docker compose logs -f n8n      # view n8n logs
docker compose down             # stop (data is preserved)
docker compose down -v          # stop and delete all data
```
