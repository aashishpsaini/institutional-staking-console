// Mirrors the Rails API contract. All token amounts are base-unit integer strings.

export interface Network {
  readonly slug: string;
  readonly display_name: string;
  readonly symbol: string;
  readonly decimals: number;
}

export interface PortfolioPosition {
  readonly network: string;
  readonly network_details: Network;
  readonly balance: string;
  readonly total_rewards_received: string;
  readonly validator_count: number;
  readonly started_at: string | null;
  readonly updated_at: string | null;
}

export interface Portfolio {
  readonly data: readonly PortfolioPosition[];
  readonly meta: { readonly last_synced_at: string | null };
}

export interface RewardRollup {
  readonly network: string;
  readonly date: string;
  readonly amount: string;
  readonly event_count: number;
}

export interface RewardFilters {
  readonly network: string;
  readonly start: string;
  readonly end: string;
}

export type SyncRunStatus = "queued" | "running" | "completed" | "failed";

export interface SyncRun {
  readonly id: number;
  readonly kind: "rewards";
  readonly status: SyncRunStatus;
  readonly from: string;
  readonly to: string;
  readonly records_upserted: number;
  readonly error_message: string | null;
  readonly created_at: string;
  readonly started_at: string | null;
  readonly finished_at: string | null;
}

export type OperationAction = "stake" | "unstake";
export type OperationStatus = "pending" | "submitted" | "confirmed" | "failed";

export const IN_FLIGHT_STATUSES: readonly OperationStatus[] = ["pending", "submitted"];

export interface StakeOperation {
  readonly id: number;
  readonly network: string;
  readonly action: OperationAction;
  readonly amount: string;
  readonly status: OperationStatus;
  readonly external_id: string | null;
  readonly error_message: string | null;
  readonly created_at: string;
  readonly updated_at: string;
}

export interface CreateStakeOperation {
  readonly network: string;
  readonly action: OperationAction;
  readonly amount: string;
}

export interface ApiErrorBody {
  readonly error: {
    readonly code: string;
    readonly message: string;
    readonly details: readonly string[];
  };
}
