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

# Build / typecheck
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
[Authenticatable Concern] ──> resolves Organization & enforces auth
       │
       ├─► [PortfolioController]       (Aggregates balance & synced rewards)
       ├─► [RewardsController]         (Daily rollups with network & date filters)
       ├─► [StakeOperationsController] (Validates & invokes MockChainClient)
       └─► [SyncController]            (Enqueues idempotent background sync)
              │
              ▼
       [SyncRewardsJob] ──> [ChainClients::MockChainClient] ──> [RewardEvent (Idempotent Upsert)]
```

### Key Highlights

1. **Service Boundary Abstraction (`ChainClients::MockChainClient`):**
   - Controllers and jobs never execute raw blockchain interactions inline.
   - All chain communications (balance queries, rewards fetching, staking transactions) pass through `ChainClients::MockChainClient`.
   - Swapping out the mock client for real on-chain indexers or RPC providers (e.g., Figment, Infura, Solana RPC) requires no changes to controllers or business logic.

2. **Idempotent Rewards Sync (`SyncRewardsJob`):**
   - Sync job ingests daily reward rows from the mock client.
   - Leverages a unique database index on `reward_events.external_id`.
   - Uses `find_or_initialize_by(external_id:)` so re-running sync for overlapping date ranges never duplicates events or double-counts rewards.
   - Every sync creates a tracked `SyncRun` record with timestamps (`finished_at`) and status (`running`, `completed`, `failed`) for auditability.

3. **Compute-on-Read Portfolio Aggregation:**
   - Balances are derived directly from the organization's active validator positions.
   - Total rewards received are aggregated on-read from persisted `RewardEvent` records.
   - Avoids denormalized counter column drift and guarantees financial consistency.

4. **String Integer Representation for All Amounts:**
   - In accordance with institutional blockchain best practices, all token values (balances, rewards, stake amounts) are modeled and returned as integer strings (wei / lamport scales).
   - Never uses IEEE 754 floating point numbers in APIs or database calculations, completely preventing precision and rounding loss.

5. **Soft Confirmation Job (`StakeConfirmationJob`):**
   - Implemented as an asynchronous background worker simulating real-world transaction confirmation.
   - Provides clear state transitions: `pending` → `submitted` → `confirmed` (or `failed`).

---

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

## Frontend Console Features

The React console is built with Vite, TypeScript, and React Router:

1. **Portfolio Page (`/`):**
   - Displays real-time staked balance and total rewards earned per network.
   - Displays network started date and last updated date.
   - Shows the last successful sync timestamp.
   - Includes a **"Sync Rewards"** button that enqueues a background sync and auto-refreshes the portfolio balances.

2. **Rewards Page (`/rewards`):**
   - Automatically loads daily rewards rollup table on navigation.
   - Filter by network (`Ethereum`, `Solana`, or all).
   - Filter by date range (start date and end date).
   - "Reset" button to clear filters.
   - Shows daily reward totals and event counts per day.

3. **Operations Page (`/operations`):**
   - Submit stake and unstake requests through the institutional boundary.
   - Client-side validation ensuring only positive integer strings are submitted.
   - Displays operations history with status badges (`pending`, `submitted`, `confirmed`, `failed`).
   - Displays external blockchain transaction reference IDs (`external_id`).

4. **Error Handling & API Client:**
   - Intercepts and parses backend validation error responses (`422`, `401`).
   - Clean loading, empty, and error alert states across all views.

---

## Test Suite

The automated test suite covers all requirements:

```bash
cd backend
bundle exec rspec
```

### Coverage Summary (39 Specs, 0 Failures):
- **Portfolio API:**
  - Unauthorized requests rejected (missing or invalid API key).
  - Accurate balances and zero rewards when un-synced.
  - Correct aggregation of `total_rewards_received` after sync.
  - Verified string format for all balances and amounts (no floats).
  - Last synced timestamp tracking.
- **Rewards API:**
  - Daily rollups for all networks.
  - Network filter and unknown network rejection (422).
  - Date range filtering (start & end) and invalid date handling.
  - Combined filters.
  - Verified integer string representation.
- **Stake Operations API:**
  - Successful creation of stake & unstake operations via `MockChainClient`.
  - Input validations (action inclusion, positive integer amounts, reject decimals/negatives/zero).
  - Org isolation (operations from other organizations never leak).
  - Ordered by creation time descending.
- **Sync API:**
  - Enqueuing `SyncRewardsJob` with 202 Accepted.
  - Optional custom date ranges and date validation.
- **SyncRewardsJob:**
  - Pulling rewards from `MockChainClient`.
  - **Idempotency guarantee** (re-running never creates duplicate events).
  - `SyncRun` lifecycle status tracking (`running` -> `completed` / `failed`).
- **StakeConfirmationJob:**
  - Safe transition from `submitted` to `confirmed`.

---

## Assumptions & Design Decisions

1. **Precision & Integer Scale:**
   - Native blockchain amounts are stored as integer strings representing minimum base units (e.g. Wei for Ethereum, Lamports for Solana).
   - Aggregations are calculated using arbitrary-precision integers in Ruby, ensuring no overflow or floating-point rounding issues regardless of database engine.
2. **Compute-on-Read vs Denormalized Storage:**
   - Portfolio aggregates are calculated on-read from `validators` and `reward_events`. At this scale, this guarantees 100% data consistency without cache-invalidation bugs.
3. **Multi-Tenancy:**
   - Organizations are fully isolated via `ApiKey` authentication; queries are strictly scoped through `current_organization`.
4. **Timebox & Scope:**
   - Time spent: ~3 hours.
   - Kept dependencies clean and minimal without unnecessary framework sprawl.
