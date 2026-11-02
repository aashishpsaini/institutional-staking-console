export interface PortfolioItem {
  readonly protocol: string;
  readonly balance: string;
  readonly total_rewards_received: string;
  readonly updated_at?: string | null;
  readonly started_at?: string | null;
}

export interface PortfolioResponse {
  readonly data: readonly PortfolioItem[];
  readonly last_synced_at?: string | null;
}

export interface SyncResponse {
  readonly message: string;
  readonly from: string;
  readonly to: string;
}
