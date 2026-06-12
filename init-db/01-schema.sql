-- ============================================================================
-- bellandmccoy-trial — System-of-record schema
-- ----------------------------------------------------------------------------
-- Runs automatically on the FIRST initialization of the Postgres volume
-- (docker-entrypoint-initdb.d). It is idempotent so re-runs are harmless.
--
-- This table is the destination the n8n workflow writes to AFTER human
-- approval. It is intentionally separate from n8n's own internal tables.
-- ============================================================================

-- Dedicated schema keeps business data out of the public namespace that n8n
-- shares for its own bookkeeping.
CREATE SCHEMA IF NOT EXISTS sales;

-- Enums make the approval lifecycle explicit and queryable.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'review_status') THEN
        CREATE TYPE sales.review_status AS ENUM ('approved', 'rejected');
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS sales.call_records (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Extracted business fields -------------------------------------------
    account_name      TEXT        NOT NULL,
    contact_name      TEXT        NOT NULL,
    summary           TEXT,
    action_items      JSONB        NOT NULL DEFAULT '[]'::jsonb,
    order_intent      JSONB,                       -- null when no order/quote

    -- Data-quality signals for the "messy transcript" path ----------------
    -- The workflow flags low-confidence / missing-field extractions so a
    -- human can see WHY something needed attention.
    missing_fields    JSONB        NOT NULL DEFAULT '[]'::jsonb,
    needs_followup    BOOLEAN      NOT NULL DEFAULT FALSE,

    -- Approval + provenance ------------------------------------------------
    review_status     sales.review_status NOT NULL,
    reviewed_by       TEXT,
    raw_transcript    TEXT         NOT NULL,
    extraction_model  TEXT,                        -- e.g. 'llama3.2:1b'

    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Common access patterns: by account, and by records still needing follow-up.
CREATE INDEX idx_call_records_account   ON sales.call_records (account_name);
CREATE INDEX idx_call_records_followup  ON sales.call_records (needs_followup)
    WHERE needs_followup = TRUE;
CREATE INDEX idx_call_records_created   ON sales.call_records (created_at DESC);

COMMENT ON TABLE  sales.call_records IS
    'Approved sales-call extractions written by the n8n workflow.';
COMMENT ON COLUMN sales.call_records.missing_fields IS
    'Array of field names the LLM could not confidently extract.';
COMMENT ON COLUMN sales.call_records.needs_followup IS
    'TRUE when the call was ambiguous/incomplete and requires human follow-up.';
