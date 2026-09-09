-- RevGuard Database Foundation Migration
-- PostgreSQL 16 extensions and baseline setup

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Comment on database setup
COMMENT ON DATABASE revguard IS 'RevGuard Revenue Recovery Database';
