# Technical Setup

## Prerequisites

- Docker with the Compose plugin — verify with `docker compose version`
- ~4 GB free RAM (model + services)
- ~4 GB free disk (model weights + database)
- `openssl` installed (for secret generation)

---

## 1. Generate secrets

```bash
./scripts/generate-secrets.sh
```

This creates `.env` from `.env.example` with random values for the PostgreSQL password and the n8n encryption key. You only need to run this once.

If you prefer to fill them in manually, copy `.env.example` to `.env` and replace the placeholder values.

---

## 2. Start the stack

```bash
docker compose up -d
```

On the first run this will:
1. Pull the Docker images for n8n, Ollama, and PostgreSQL
2. Download the `llama3.2:3b` model (~2 GB) — this takes a few minutes
3. Initialize the database schema automatically

Watch the model download finish before continuing:

```bash
docker compose logs -f ollama-pull
```

When you see `Model llama3.2:3b ready.` it is done.

---

## 3. Create your n8n account

Open [http://localhost:5678](http://localhost:5678) and create a local admin account. This account is stored in the database and is only used on this machine.

---

## 4. Import the workflow

In n8n: **Settings → Import from file** → select `workflow.json`.

The workflow will appear as a draft. Do not activate it yet.

---

## 5. Configure credentials

The workflow uses two credentials that you must set up inside n8n before activating:

**PostgreSQL**

Go to **Credentials → New → Postgres** and fill in:
- Host: `postgres`
- Port: `5432`
- Database: value of `POSTGRES_DB` in your `.env` (default: `bmc_sales`)
- User: value of `POSTGRES_USER` (default: `bmc_app`)
- Password: value of `POSTGRES_PASSWORD`

**SMTP (for approval emails)**

Go to **Credentials → New → SMTP** and fill in your email provider's details.

Once both credentials are saved, open the workflow, attach them to the email and database nodes, and activate the workflow.

---

## 6. Test with Postman

Import `postman_collection.json` into Postman. The collection has 4 requests — two with clean transcripts (should trigger approval emails) and two with vague transcripts (should trigger the error path). See [project-structure.md](project-structure.md) for details on each request.

---

## Configuration reference

All settings live in `.env`. The most common ones to change:

| Variable | Description | Default |
|---|---|---|
| `OLLAMA_MODEL` | AI model used for extraction | `llama3.2:3b` |
| `POSTGRES_USER` | Database username | `bmc_app` |
| `POSTGRES_DB` | Database name | `bmc_sales` |
| `N8N_ENCRYPTION_KEY` | Encrypts stored n8n credentials | *(generated)* |
| `WEBHOOK_URL` | URL n8n uses for webhooks | `http://localhost:5678/` |

If you expose n8n via a tunnel (e.g. cloudflare tunnel) for remote approvals, update both `N8N_HOST` and `WEBHOOK_URL` to the public URL.

---

## Useful commands

```bash
docker compose ps                  # check service status
docker compose logs -f n8n         # tail n8n logs
docker compose logs -f ollama-pull # watch model download
docker compose down                # stop (data preserved in volumes)
docker compose down -v             # stop and delete all data
```

Connect directly to the database:

```bash
docker compose exec postgres psql -U bmc_app -d bmc_sales -c \
  'SELECT id, account_name, contact_name, needs_followup FROM sales.call_records;'
```

---

## Switching the AI model

Change `OLLAMA_MODEL` in `.env` and restart:

```bash
docker compose up -d
docker compose logs -f ollama-pull
```

Available options:
- `llama3.2:3b` — default, best extraction quality (~2 GB RAM)
- `llama3.2:1b` — lighter, ~1.3 GB RAM
- `qwen2.5:0.5b` — smallest, ~400 MB RAM, less reliable JSON
