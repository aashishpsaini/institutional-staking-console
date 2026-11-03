import type {
  CreateStakeOperation,
  Network,
  Portfolio,
  RewardFilters,
  RewardRollup,
  StakeOperation,
  SyncRun
} from "../types/api";
import { request } from "./client";

export { ApiError, isAbortError } from "./client";

interface Envelope<T> {
  readonly data: T;
}

function toQuery(params: Record<string, string>): string {
  const query = new URLSearchParams(Object.entries(params).filter(([, value]) => value !== ""));
  const encoded = query.toString();
  return encoded ? `?${encoded}` : "";
}

// One typed function per endpoint — pages never build URLs or headers themselves.
export const api = {
  networks: (signal?: AbortSignal) =>
    request<Envelope<Network[]>>("/api/v1/networks", { signal }).then((r) => r.data),

  portfolio: (signal?: AbortSignal) => request<Portfolio>("/api/v1/portfolio", { signal }),

  rewards: (filters: RewardFilters, signal?: AbortSignal) =>
    request<Envelope<RewardRollup[]>>(`/api/v1/rewards${toQuery({ ...filters })}`, { signal }).then((r) => r.data),

  stakeOperations: (signal?: AbortSignal) =>
    request<Envelope<StakeOperation[]>>("/api/v1/stake_operations", { signal }).then((r) => r.data),

  createStakeOperation: (params: CreateStakeOperation, idempotencyKey: string) =>
    request<Envelope<StakeOperation>>("/api/v1/stake_operations", {
      method: "POST",
      body: params,
      headers: { "Idempotency-Key": idempotencyKey }
    }).then((r) => r.data),

  syncRewards: () => request<Envelope<SyncRun>>("/api/v1/sync/rewards", { method: "POST", body: {} }).then((r) => r.data),

  syncRun: (id: number, signal?: AbortSignal) =>
    request<Envelope<SyncRun>>(`/api/v1/sync/runs/${id}`, { signal }).then((r) => r.data)
};
