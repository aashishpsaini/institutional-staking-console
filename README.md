# Institutional Staking Console — Boilerplate

**Branch:** `boiler-plate`  
**Expected duration:** This is a **4-hour task**  
**Stack:** Ruby on Rails (API) + React (TypeScript)

Starter monorepo aligned to institutional staking product work (portfolio, rewards reporting, stake operations, chain-abstraction services).

---

## What's included

| Path | Purpose |
|------|---------|
| `backend/` | Rails API skeleton: models, routes, mock chain client, sync job stub |
| `frontend/` | Vite + React + TS console shell: portfolio / rewards / operations pages |
| `backend/db/seeds.rb` | Demo org, API key, networks, validators |

---

## What's already done

You do **not** need to rebuild these from scratch:

- Rails app skeleton + routes for the required endpoints
- Core ActiveRecord models and migrations
- `MockChainClient` stub returning deterministic balances/rewards
- API key middleware/concern (basic)
- React app shell with routing and API client placeholder
- Seed data for one organization (`demo-key`)

---

## Your job (what we expect you to finish)

### 1. Backend — complete the product slice (required · main focus)

1. **Portfolio aggregation** (`GET /api/v1/portfolio`)
   - Return per-network `balance` and `total_rewards_received` as **strings**
   - Base balances on validators/delegations; rewards on synced `RewardEvent` rows (or documented equivalent)

2. **Rewards reporting** (`GET /api/v1/rewards`)
   - Daily rollup
   - Support filters: `network`, `start`, `end`
   - Stable JSON shape suitable for the React table

3. **Stake operations**
   - `POST /api/v1/stake_operations` — validate params, create `pending` operation, call `ChainClient#submit_stake`
   - `GET /api/v1/stake_operations` — list for the authenticated org
   - Status transitions at least through `pending` → `submitted` (optional job to `confirmed`)

4. **Rewards sync job** (`POST /api/v1/sync/rewards` + job class)
   - Pull from `MockChainClient#fetch_rewards`
   - Upsert idempotently (re-sync must not double-count)
   - Keep chain details behind `ChainClient` — not in controllers

5. **Hardening**
   - Reject bad/missing `X-Api-Key` with 401
   - 422 on invalid stake params
   - No floats for token amounts in API JSON

### 2. Backend tests (required)

Cover at least:

- Portfolio totals for seeded org
- Rewards filters/rollups
- Stake operation create success + validation failure
- Sync idempotency
- Unauthorized requests

### 3. Frontend — wire the console (required)

In `frontend/`, make these flows work against your API:

1. **Portfolio page** — show network balances, total rewards, last sync time
2. **Rewards page** — table + network/date filters
3. **Operations page** — create stake/unstake request; list with status badges
4. Shared loading / empty / error states
5. API client sending `X-Api-Key` from env (default seed key OK for local demo)

### 4. README polish (required)

Update root or package READMEs with:

- How to run backend + frontend
- How to seed and which API key to use
- Formulas / aggregation rules you chose
- Assumptions and time spent

---

## Out of scope for this 4-hour task

Unless the required slice is done early, skip:

- Real RPC / wallet signing / custody
- Multi-org admin UI
- GraphQL
- Production deploy, K8s, observability stacks
- Pixel-perfect design system

---

## Definition of done

- [ ] Required API endpoints work with seeded data
- [ ] Sync job is idempotent
- [ ] React console covers portfolio, rewards, operations
- [ ] Backend tests for the cases above pass
- [ ] Chain access goes through `ChainClient` / `MockChainClient`
- [ ] Run instructions + assumptions documented

---

## Quick start

```bash
# Backend
cd backend
bundle install
bin/rails db:setup
bin/rails s -p 3000

# Frontend (separate terminal)
cd frontend
npm install
npm run dev
```

Use header `X-Api-Key: demo-key` (from seeds).

For full product context, also read the `scratch` branch README.
