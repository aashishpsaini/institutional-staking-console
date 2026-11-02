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
   - Balances are derived directly from the organization's active validator positions (`Organization#staked_balance_for`).
   - Total rewards received are aggregated on-read from persisted `RewardEvent` records (`Organization#total_rewards_for`).
   - Avoids denormalized counter column drift and guarantees financial consistency.

4. **Clean Ruby / Rails Codebase:**
   - Introduced `Current < ActiveSupport::CurrentAttributes` for tenant and auth context.
   - Ultra-slim controllers (20-30 lines) with single-responsibility private helper methods.
   - Rich domain models where business computations naturally belong.

5. **String Integer Representation for All Amounts:**
   - In accordance with institutional blockchain best practices, all token values (balances, rewards, stake amounts) are modeled and returned as integer strings (wei / lamport scales).
   - Never uses IEEE 754 floating point numbers in APIs or database calculations, completely preventing precision and rounding loss.

6. **Soft Confirmation Job (`StakeConfirmationJob`):**
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

## Institutional React UX & Operations Features

The frontend is built with **Vite, React 18, and TypeScript**, configured with modern best practices (`noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`, discriminated unions, inferred component return types, and interfaces for props):

1. **Portfolio Page (`/`):**
   - **Executive KPI Cards:** Displays active network count, rewards sync status, and the latest sync timestamp.
   - **Dual Value Formatting:** Displays human-readable token amounts (e.g. `32.0000 ETH`, `100.000 SOL`) alongside the precise base unit raw integer string (`32000000000000000000 wei`).
   - **Direct Sync Trigger:** Includes a **"Sync Rewards"** button that kicks off background ingestion and re-aggregates balances without manual reload.

2. **Rewards Page (`/rewards`):**
   - **Quick Range Presets:** One-click filter buttons ("All Time", "Last 7 Days", "Last 30 Days").
   - **Pagination Controls:** Responsive pagination bar with customizable rows per page (10, 25, 50).
   - **Network & Custom Date Range Filtering:** Fully interactive with instant reset.

3. **Operations Page (`/operations`):**
   - **Ops Workflow Presets:** Quick deposit buttons ("32 ETH Validator", "1 ETH", "100 SOL").
   - **Real-Time Polling:** When operations are in `pending` or `submitted` status, the console automatically polls in the background every 3.5 seconds until operations transition to `confirmed`!
   - **Transaction Reference Copy:** One-click `CopyButton` with instant "✓ Copied" visual feedback for blockchain external IDs.
   - **Pulsing Status Badges:** Visual indicator pills differentiating active transitions from finalized states.

4. **Error Handling & State Architecture:**
   - Unifies asynchronous data fetching using `AsyncState<T>` **discriminated unions** (`idle` | `loading` | `success` | `error`).
   - Clean, typed `ApiError` class that parses server validation errors into actionable UI alerts.

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
   - Organizations are fully isolated via `ApiKey` authentication; queries are strictly scoped through `Current.organization`.
4. **Timebox & Scope:**
   - Time spent: ~3.5 hours.
   - Zero framework sprawl: focused purely on standard Rails conventions and React/TypeScript best practices.
