export interface RewardRollup {
  readonly network: string;
  readonly date: string;
  readonly amount: string;
  readonly event_count?: number;
}

export interface RewardsResponse {
  readonly data: readonly RewardRollup[];
}

export interface RewardFilters {
  readonly network: string;
  readonly start: string;
  readonly end: string;
}
