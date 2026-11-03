# Institutional Staking Console

**Branch:** `solution`
**Stack:** Ruby on Rails 7.1 (API-only) + React 18 + TypeScript (Vite)

A scoped institutional staking console: a Rails API that hides chain complexity behind a
`ChainClients` service boundary, background jobs that ingest rewards idempotently, and a React
console for portfolio, rewards reporting and stake-operation workflows.

---

## Quick start

### Backend (Rails API, port 3000)

```bash
cd backend
bundle install
bin/rails db:setup        # create, migrate, seed (demo org, validators, 30 days of rewards)
bundle exec rspec         # 77 examples
bundle exec rubocop       # rubocop-rails-omakase
bin/rails s -p 3000
```

### Frontend (Vite, port 5173)

```bash
cd frontend
npm install
npm test                  # vitest: token-amount math
npm run build             # strict type-check + production build
npm run dev
```

Open http://localhost:5173. The dev server proxies `/api` to `localhost:3000`
(override with `API_PROXY_TARGET=http://localhost:3001 npm run dev`) and sends
`X-Api-Key: demo-key` by default (see `frontend/.env.example`).

```bash
curl -H "X-Api-Key: demo-key" localhost:3000/api/v1/portfolio
```

---

## Architecture

```
React console ──(REST + X-Api-Key, Idempotency-Key)──► Rails API
                                                        │
  Authenticatable ── ApiKey.authenticate(digest) ──► Current.organization (tenant scope)
                                                        │
  Controllers (thin) ──► Portfolio / RewardEvent.daily_rollup / StakeOperations::Request
                                                        │
  Jobs: SyncRewardsJob, StakeConfirmationJob            │
                                                        ▼
                         ChainClients.current  (config.x.chain_client)
                           └── ChainClients::Base  ◄── MockChainClient (deterministic)
```

Nothing outside `app/services/chain_clients/` knows how chain data is fetched. Swapping in a
real adapter is `CHAIN_CLIENT=ChainClients::FigmentClient` once a class implementing
`ChainClients::Base` exists.

## API

All endpoints require `X-Api-Key`. Amounts are **base-unit integer strings** (wei, lamports).

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `/api/v1/portfolio` | Per-network `balance`, `total_rewards_received`, validator count; `meta.last_synced_at` |
| `GET` | `/api/v1/rewards` | Daily rollup per network; filters `network`, `start`, `end` (ISO-8601, inclusive) |
| `GET` | `/api/v1/networks` | Slug, symbol, decimals — clients never hardcode token math |
| `GET` | `/api/v1/stake_operations` | Latest 100 operations for the org |
| `GET` | `/api/v1/stake_operations/:id` | 404 for other tenants' operations |
| `POST` | `/api/v1/stake_operations` | `{ network, action: stake\|unstake, amount }`; optional `Idempotency-Key` header |
| `POST` | `/api/v1/sync/rewards` | `{ from?, to? }` → `202` with a `SyncRun` (dedupes an in-progress run) |
| `GET` | `/api/v1/sync/runs/:id` | Poll sync progress |

Errors always use one envelope:

```json
{ "error": { "code": "validation_failed", "message": "Validation failed", "details": ["Amount must be a positive integer string in base units"] } }
```

| Status | Codes |
|--------|-------|
| 400 | `bad_request` (malformed JSON) |
| 401 | `unauthorized` (missing / unknown / revoked key) |
| 404 | `not_found` (unknown route or another tenant's record) |
| 409 | `idempotency_conflict` (key reused with a different body) |
| 422 | `validation_failed`, `unknown_network`, `invalid_date_format`, `invalid_date_range` |

## Design decisions & assumptions

1. **Integer-string amounts.** Stored as strings, summed with Ruby's arbitrary-precision `Integer`
   (`AmountMath`). 32 ETH = 3.2×10¹⁹ wei overflows SQLite's 64-bit `INTEGER`, so SQL `SUM()` is unsafe
   here. On Postgres the next step is `NUMERIC(78,0)` columns with SQL aggregation. The UI formats with
   `BigInt` only — never `Number`.
2. **Portfolio is computed on read** from validators (balance) and reward events (rewards). No
   denormalized totals means nothing to invalidate; it's a fixed number of grouped queries.
3. **Idempotent sync.** The adapter returns a stable `external_id` per (validator, day) and the job
   `upsert_all`s on the unique index `(organization_id, external_id)`. Re-running any window —
   overlapping or not — converges to the same rows; a corrected amount from the chain overwrites rather
   than adds. Adapter output is validated before upsert because `upsert_all` skips model validations.
4. **Stake lifecycle** `pending → submitted → confirmed | failed`, enforced by an explicit transition
   table. Submission is synchronous through the boundary; `StakeConfirmationJob` polls
   `fetch_operation_status` and re-enqueues itself (bounded attempts). Chain errors mark the operation
   `failed` with `error_message`.
5. **Idempotency-Key** on stake creation (scoped per org, unique index) prevents double submits from
   retries or double clicks — essential when the side effect moves funds.
6. **Unstake guard:** an unstake larger than the org's staked balance on that network is rejected (422).
7. **API keys** are stored as SHA-256 digests (tokens are high-entropy, so a fast hash is enough and
   keeps lookup indexable); keys can be revoked; `last_used_at` is throttled to one write per minute.
   Logs are tagged with `request_id` and `org=<id>`; tokens/digests are filtered.
8. **SQLite** for local MVP (allowed by the brief); production config uses `DATABASE_URL` (Postgres).
9. **ActiveJob `:async` adapter** keeps the demo dependency-free. Jobs are plain ActiveJob with
   `retry_on`, so moving to Sidekiq/Solid Queue is a config change.
10. **Mock rewards** are `balance × APR / 365` with a small deterministic daily variation (ETH 3.2%, SOL 7%).

## Out of scope / next steps

- Server-side pagination for operations and rewards (currently capped/client-side).
- Postgres `NUMERIC` + SQL aggregation; materialized daily rollups if reward volume grows.
- Scheduled sync (e.g. Solid Queue recurring task) instead of manual trigger only.
- Rate limiting (Rails 7.2 `rate_limit` / rack-attack); browser sessions via a BFF rather than shipping an API key in the bundle.
- Updating validator balances from `fetch_balances` and reflecting confirmed operations in balances.

## Time spent

~3.5 hours for the initial implementation and review.
