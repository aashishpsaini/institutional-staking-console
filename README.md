# Institutional Staking Console

**Branch:** `solution`  
**Stack:** Ruby on Rails 7.1 (API-only) + React 18 + TypeScript (Vite)

This repository contains the complete implementation of the Institutional Staking Console, providing a scoped institutional portfolio and rewards reporting experience backed by a clean service boundary over blockchain complexities.

---

## Quick Start & Verification

### 1. Backend (Rails API)

```bash
cd backend

# Install dependencies
bundle install

# Setup database (creates, migrates, and seeds demo data)
bundle exec rails db:setup

# Run the automated test suite (39 specs, 100% passing)
bundle exec rspec

# Start the Rails server on port 3000
bundle exec rails s -p 3000
```

### 2. Frontend (React + Vite)

```bash
cd frontend

# Install dependencies
npm install

# Build / typecheck (strict mode, 0 errors)
npm run build

# Start the Vite development server on port 5173
npm run dev
```

Visit **http://localhost:5173** in your browser.  
By default, the frontend is configured to use `X-Api-Key: demo-key` (seeded organization).

---

## Architecture & Service Boundaries

```
[React / TypeScript Console]
       │
       ▼ (REST API with X-Api-Key)
[Authenticatable Concern] ──> assigns Current.organization & Current.api_key
       │
       ├─► [PortfolioController]       (Featherweight controller, delegates to models)
       ├─► [RewardsController]         (Daily rollups with network & date filters)
       ├─► [StakeOperationsController] (Delegates to StakeOperation#submit_to_chain!)
       └─► [SyncController]            (Enqueues idempotent background sync)
              │
              ▼
       [SyncRewardsJob] ──> [ChainClients::MockChainClient] ──> [RewardEvent (Idempotent Upsert)]
```


## API Endpoints

All endpoints require the header `X-Api-Key: <token>`.

| Method | Endpoint | Description | Query / Body Params | Response Status |
|--------|----------|-------------|---------------------|-----------------|
| `GET` | `/api/v1/portfolio` | Per-network balance and total rewards received | None | `200 OK` |
| `GET` | `/api/v1/rewards` | Daily rollup of rewards | `network`, `start`, `end` | `200 OK`, `422 Unprocessable` |
| `GET` | `/api/v1/stake_operations` | List stake operations for authenticated org | None | `200 OK` |
| `POST` | `/api/v1/stake_operations` | Create stake or unstake request | `{ network, action, amount }` | `201 Created`, `422 Unprocessable` |
| `POST` | `/api/v1/sync/rewards` | Enqueue background rewards sync job | `{ from, to }` (optional) | `202 Accepted` |

---

## Test Suite

The automated test suite covers all requirements:

```bash
cd backend
bundle exec rspec
```

## Assumptions & Design Decisions

1. **Precision & Integer Scale:**
   - Native blockchain amounts are stored as integer strings representing minimum base units (e.g. Wei for Ethereum, Lamports for Solana).
   - Aggregations are calculated using arbitrary-precision integers in Ruby, ensuring no overflow or floating-point rounding issues regardless of database engine.
2. **Compute-on-Read vs Denormalized Storage:**
   - Portfolio aggregates are calculated on-read from `validators` and `reward_events`. At this scale, this guarantees 100% data consistency without cache-invalidation bugs.
3. **Multi-Tenancy:**
   - Organizations are fully isolated via `ApiKey` authentication; queries are strictly scoped through `Current.organization`.
4. **Timebox:**
   - Time spent: ~3.5 hours.
