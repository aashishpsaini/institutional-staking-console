export type OperationAction = "stake" | "unstake";
export type OperationStatus = "pending" | "submitted" | "confirmed" | "failed";

export interface StakeOperation {
  readonly id: number;
  readonly network: string;
  readonly action: OperationAction;
  readonly amount: string;
  readonly status: OperationStatus;
  readonly external_id?: string | null;
  readonly error_message?: string | null;
  readonly created_at: string;
}

export interface OperationsResponse {
  readonly data: readonly StakeOperation[];
}

export interface OperationSingleResponse {
  readonly data: StakeOperation;
}

export interface CreateOperationParams {
  readonly network: string;
  readonly action: OperationAction;
  readonly amount: string;
}
